// Hoja de campo de una partida en PDF, generada en el navegador.
//
// Página 1: plano A4 apaisado de la partida sobre la ortofoto o el topográfico, con los
// elementos numerados y una cuadrícula (A1, B2…) para orientarse.
// Páginas siguientes: lista para marcar en el campo «continua igual / ha canviat / no el
// trobe», con el código de cada elemento para pasarlo después a la web o a la app.
//
// El plano se dibuja a mano en un canvas (teselas del IGN + vectores): MapLibre fuera de
// pantalla no garantiza que las teselas estén cargadas al exportar. jsPDF se carga solo
// cuando alguien pide una hoja.

import type { Geometry, Position } from 'geojson';
import { supabase } from '../../lib/supabase';
import { urlTesela, ZOOM_MAX_FONS } from '../mapa/estil';
import type { Fons } from '../mapa/tipus';

interface ElementFull {
  id: string;
  tema_id: number;
  tema: string;
  color: string;
  variable: string;
  categoria: string | null;
  estat: 'pendent' | 'validat' | 'rebutjat';
  origen: string;
  revisat_at: string | null;
  per_revisar: boolean;
  geometria: Geometry;
  etiqueta: [number, number];
}

export interface DadesFull {
  partida: { id: number; nom: string; municipi: string; area_ha: number; geometria: Geometry } | null;
  elements: ElementFull[];
}

export type Pas = 'dades' | 'mapa' | 'pdf';

// ─── Maquetación (mm, A4 apaisado) ─────────────────────────────────────────
const PAG = { w: 297, h: 210 };
const MAPA = { x: 16, y: 36, w: 271, h: 152 };
const CEL_MM = 45;                 // lado aproximado de cada cuadro de la cuadrícula
const PPMM = 9;                    // píxeles del plano por mm de papel (~230 ppp)
const VERD = '#215c00';
const TEXT = '#3b352f';

// ─── Mercator ──────────────────────────────────────────────────────────────
const mx = (lon: number) => (lon + 180) / 360;
const my = (lat: number) => {
  const r = (lat * Math.PI) / 180;
  return (1 - Math.log(Math.tan(r) + 1 / Math.cos(r)) / Math.PI) / 2;
};

function coordenades(g: Geometry): Position[] {
  switch (g.type) {
    case 'Point': return [g.coordinates];
    case 'MultiPoint':
    case 'LineString': return g.coordinates;
    case 'MultiLineString':
    case 'Polygon': return g.coordinates.flat();
    case 'MultiPolygon': return g.coordinates.flat(2);
    default: return [];
  }
}

function anells(g: Geometry): Position[][] {
  if (g.type === 'Polygon') return g.coordinates;
  if (g.type === 'MultiPolygon') return g.coordinates.flat();
  return [];
}

function carregarImatge(src: string): Promise<HTMLImageElement | null> {
  return new Promise((resol) => {
    const img = new Image();
    img.crossOrigin = 'anonymous';           // sin esto el canvas no se puede exportar
    img.onload = () => resol(img);
    img.onerror = () => resol(null);         // una tesela que falla queda en blanco
    img.src = src;
  });
}

const lletra = (i: number) => String.fromCharCode(65 + i);

// jsPDF con las fuentes estándar solo admite Latin-1: «’» y similares fuera
const net = (s: string) => s.replace(/[’‘]/g, "'").replace(/[“”]/g, '"').replace(/[–—]/g, '-');

/** Celda de la cuadrícula (A1, B3…) de un punto, en mm de página. */
function cela([x, y]: [number, number], cols: number, files: number) {
  const c = Math.min(cols - 1, Math.max(0, Math.floor(((x - MAPA.x) / MAPA.w) * cols)));
  const f = Math.min(files - 1, Math.max(0, Math.floor(((y - MAPA.y) / MAPA.h) * files)));
  return { c, f, nom: `${lletra(c)}${f + 1}` };
}

/** Numeración por cuadros (fila a fila, de izquierda a derecha) y dentro de cada cuadro de arriba abajo. */
function numerar(elements: ElementFull[], aPagina: (p: Position) => [number, number], cols: number, files: number) {
  return elements
    .map((e) => ({ e, pos: aPagina(e.etiqueta) }))
    .map((x) => ({ ...x, cela: cela(x.pos, cols, files) }))
    .sort((a, b) => a.cela.f - b.cela.f || a.cela.c - b.cela.c || a.pos[1] - b.pos[1] || a.pos[0] - b.pos[0]);
}

// ─── Plano ─────────────────────────────────────────────────────────────────
interface Plano {
  imatge: string;
  /** Elementos en el orden de su número (1, 2, 3…) con su cuadro. */
  ordre: { e: ElementFull; cela: string }[];
  /** Posición en mm sobre la página de un punto lon/lat. */
  aPagina: (p: Position) => [number, number];
  metresPerMm: number;
  cols: number;
  files: number;
}

async function dibuixarPla(dades: DadesFull, fons: Fons): Promise<Plano> {
  const partida = dades.partida!;
  const punts = [...coordenades(partida.geometria), ...dades.elements.flatMap((e) => coordenades(e.geometria))];
  let [x0, x1] = [Infinity, -Infinity];
  let [y0, y1] = [Infinity, -Infinity];
  for (const [lon, lat] of punts) {
    x0 = Math.min(x0, mx(lon)); x1 = Math.max(x1, mx(lon));
    y0 = Math.min(y0, my(lat)); y1 = Math.max(y1, my(lat));
  }
  // Margen y misma proporción que el recuadro del plano
  const marge = 0.06;
  let w = (x1 - x0) * (1 + 2 * marge) || 1e-6;
  let h = (y1 - y0) * (1 + 2 * marge) || 1e-6;
  const cx = (x0 + x1) / 2;
  const cy = (y0 + y1) / 2;
  if (w / h > MAPA.w / MAPA.h) h = (w * MAPA.h) / MAPA.w;
  else w = (h * MAPA.w) / MAPA.h;
  const ox = cx - w / 2;
  const oy = cy - h / 2;

  // Zoom de teselas: el que da ~PPMM píxeles por mm, sin pasar del máximo del fondo
  const objectiu = MAPA.w * PPMM;
  const z = Math.max(10, Math.min(ZOOM_MAX_FONS[fons], Math.round(Math.log2(objectiu / (w * 256)))));
  const mon = 256 * 2 ** z;
  const canvasW = Math.round(objectiu);
  const canvasH = Math.round((objectiu * MAPA.h) / MAPA.w);
  const escala = canvasW / (w * mon);         // píxeles de canvas por píxel de tesela

  const canvas = document.createElement('canvas');
  canvas.width = canvasW;
  canvas.height = canvasH;
  const ctx = canvas.getContext('2d')!;
  ctx.fillStyle = '#ffffff';
  ctx.fillRect(0, 0, canvasW, canvasH);

  // Teselas
  const tx0 = Math.floor((ox * mon) / 256);
  const tx1 = Math.floor(((ox + w) * mon) / 256);
  const ty0 = Math.floor((oy * mon) / 256);
  const ty1 = Math.floor(((oy + h) * mon) / 256);
  const tesseles: Promise<void>[] = [];
  for (let tx = tx0; tx <= tx1; tx++) {
    for (let ty = ty0; ty <= ty1; ty++) {
      tesseles.push(carregarImatge(urlTesela(fons, z, tx, ty)).then((img) => {
        if (!img) return;
        const px = (tx * 256 - ox * mon) * escala;
        const py = (ty * 256 - oy * mon) * escala;
        ctx.drawImage(img, px, py, 256 * escala + 1, 256 * escala + 1);
      }));
    }
  }
  await Promise.all(tesseles);

  const aCanvas = ([lon, lat]: Position): [number, number] => [
    (mx(lon) - ox) * w ** -1 * canvasW,
    (my(lat) - oy) * h ** -1 * canvasH,
  ];
  const u = canvasW / 2400;                    // grosores proporcionales al tamaño
  const traçar = (anell: Position[]) => {
    anell.forEach((p, i) => {
      const [px, py] = aCanvas(p);
      if (i === 0) ctx.moveTo(px, py);
      else ctx.lineTo(px, py);
    });
    ctx.closePath();
  };

  // Fuera de la partida, velado: la vista va a lo que toca revisar
  ctx.beginPath();
  ctx.rect(0, 0, canvasW, canvasH);
  anells(partida.geometria).forEach(traçar);
  ctx.fillStyle = 'rgba(255,255,255,0.45)';
  ctx.fill('evenodd');

  // Elementos (lo de 2018 sin revisar, con borde discontinuo, como en el mapa web)
  for (const e of dades.elements) {
    ctx.setLineDash(e.per_revisar ? [10 * u, 6 * u] : []);
    ctx.strokeStyle = e.color;
    if (e.geometria.type === 'Polygon' || e.geometria.type === 'MultiPolygon') {
      ctx.beginPath();
      anells(e.geometria).forEach(traçar);
      ctx.globalAlpha = 0.18;
      ctx.fillStyle = e.color;
      ctx.fill('evenodd');
      ctx.globalAlpha = 1;
      ctx.lineWidth = 2.5 * u;
      ctx.stroke();
    } else if (e.geometria.type === 'LineString' || e.geometria.type === 'MultiLineString') {
      const linies = e.geometria.type === 'LineString' ? [e.geometria.coordinates] : e.geometria.coordinates;
      ctx.lineWidth = 4 * u;
      for (const l of linies) {
        ctx.beginPath();
        l.forEach((p, i) => { const [px, py] = aCanvas(p); if (i) ctx.lineTo(px, py); else ctx.moveTo(px, py); });
        ctx.stroke();
      }
    }
  }
  ctx.setLineDash([]);

  // Contorno de la partida
  ctx.beginPath();
  anells(partida.geometria).forEach(traçar);
  ctx.lineJoin = 'round';
  ctx.strokeStyle = '#ffffff';
  ctx.lineWidth = 9 * u;
  ctx.stroke();
  ctx.strokeStyle = VERD;
  ctx.lineWidth = 4.5 * u;
  ctx.stroke();

  const aPagina = (p: Position): [number, number] => {
    const [px, py] = aCanvas(p);
    return [MAPA.x + (px / canvasW) * MAPA.w, MAPA.y + (py / canvasH) * MAPA.h];
  };
  const cols = Math.max(2, Math.round(MAPA.w / CEL_MM));
  const files = Math.max(2, Math.round(MAPA.h / CEL_MM));
  const ordre = numerar(dades.elements, aPagina, cols, files);

  // Números
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';
  ctx.font = `bold ${Math.round(15 * u)}px Helvetica, Arial, sans-serif`;
  ordre.forEach(({ e }, i) => {
    const [px, py] = aCanvas(e.etiqueta);
    const r = (i + 1 >= 100 ? 15 : 12) * u;
    ctx.beginPath();
    ctx.arc(px, py, r, 0, Math.PI * 2);
    ctx.fillStyle = '#ffffff';
    ctx.fill();
    ctx.lineWidth = 3 * u;
    ctx.strokeStyle = e.color;
    ctx.stroke();
    ctx.fillStyle = TEXT;
    ctx.fillText(String(i + 1), px, py + 0.5 * u);
  });

  const latCentre = (Math.atan(Math.sinh(Math.PI * (1 - 2 * cy))) * 180) / Math.PI;
  const metresPerPixelCanvas = (40075016.686 * Math.cos((latCentre * Math.PI) / 180)) / (mon * escala);
  return {
    imatge: canvas.toDataURL('image/jpeg', 0.86),
    ordre: ordre.map(({ e, cela }) => ({ e, cela: cela.nom })),
    aPagina,
    metresPerMm: metresPerPixelCanvas * (canvasW / MAPA.w),
    cols,
    files,
  };
}


function escalaBonica(metresPerMm: number) {
  for (const m of [10, 20, 25, 50, 100, 200, 250, 500, 1000, 2000]) {
    if (m / metresPerMm >= 25) return { metres: m, mm: m / metresPerMm };
  }
  return { metres: 5000, mm: 5000 / metresPerMm };
}

async function logoComDataUrl(): Promise<string | null> {
  const img = await carregarImatge('/logo.png');
  if (!img) return null;
  const c = document.createElement('canvas');
  c.width = img.naturalWidth;
  c.height = img.naturalHeight;
  c.getContext('2d')!.drawImage(img, 0, 0);
  return c.toDataURL('image/png');
}

function estatDada(e: ElementFull, idioma: string) {
  if (e.estat === 'pendent') return 'Pendent de validar';
  if (e.estat === 'rebutjat') return 'Rebutjat';
  if (e.per_revisar) return '2018 · per revisar';
  if (e.revisat_at) return `Revisat ${new Date(e.revisat_at).toLocaleDateString(idioma)}`;
  return 'Nova';
}

const slug = (s: string) => s.normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');

// ─── PDF ───────────────────────────────────────────────────────────────────
export async function generarFullDeCamp(partidaId: number, fons: Fons, onPas: (p: Pas) => void, idioma = 'ca-ES') {
  onPas('dades');
  const { data, error } = await supabase.rpc('full_de_camp', { p_partida_id: partidaId });
  if (error) throw error;
  return construirFullDeCamp(data as DadesFull, fons, onPas, idioma);
}

/** El PDF a partir de los datos ya cargados. Devuelve el fichero; descargarlo es cosa de quien llama. */
export async function construirFullDeCamp(dades: DadesFull, fons: Fons, onPas: (p: Pas) => void = () => {}, idioma = 'ca-ES') {
  if (!dades.partida) throw new Error('Partida inexistent');
  onPas('mapa');
  const [{ jsPDF }, { default: autoTable }, logo] = await Promise.all([
    import('jspdf'), import('jspdf-autotable'), logoComDataUrl(),
  ]);
  const pla = await dibuixarPla(dades, fons);
  const { ordre } = pla;

  onPas('pdf');
  const p = dades.partida;
  const avui = new Date().toLocaleDateString(idioma);
  const doc = new jsPDF({ orientation: 'landscape', unit: 'mm', format: 'a4' });
  doc.setProperties({ title: `Full de camp · ${net(p.nom)}`, author: "Observatori Ciutadà de l'Horta", creator: "Observatori Ciutadà de l'Horta" });

  const capcalera = (subtitol: string) => {
    if (logo) doc.addImage(logo, 'PNG', 10, 9, 46, 12.8);
    doc.setTextColor(VERD);
    doc.setFont('helvetica', 'bold');
    doc.setFontSize(8.5);
    doc.text('FULL DE CAMP', 62, 12.5);
    doc.setTextColor(TEXT);
    doc.setFontSize(15);
    doc.text(net(`${p.nom}`), 62, 19);
    doc.setFont('helvetica', 'normal');
    doc.setFontSize(8.5);
    doc.text(net(subtitol), 62, 24);
    doc.setDrawColor('#9ed100');
    doc.setLineWidth(1.2);
    doc.line(10, 28, PAG.w - 10, 28);
  };

  // ── Página 1: plano
  const nomFons = fons === 'pnoa' ? 'Ortofoto PNOA màxima actualitat' : 'Mapa topogràfic';
  capcalera(`${p.municipi} · ${new Intl.NumberFormat(idioma).format(p.area_ha)} ha · ${dades.elements.length} elements · ${nomFons} · generat el ${avui}`);
  doc.addImage(pla.imatge, 'JPEG', MAPA.x, MAPA.y, MAPA.w, MAPA.h);

  // Cuadrícula y sus rótulos
  doc.setLineWidth(0.25);
  doc.setDrawColor('#ffffff');
  for (let c = 1; c < pla.cols; c++) {
    const x = MAPA.x + (MAPA.w * c) / pla.cols;
    doc.line(x, MAPA.y, x, MAPA.y + MAPA.h);
  }
  for (let f = 1; f < pla.files; f++) {
    const y = MAPA.y + (MAPA.h * f) / pla.files;
    doc.line(MAPA.x, y, MAPA.x + MAPA.w, y);
  }
  doc.setDrawColor(TEXT);
  doc.setLineWidth(0.3);
  doc.rect(MAPA.x, MAPA.y, MAPA.w, MAPA.h);
  doc.setFont('helvetica', 'bold');
  doc.setFontSize(9);
  doc.setTextColor(TEXT);
  for (let c = 0; c < pla.cols; c++) {
    doc.text(lletra(c), MAPA.x + (MAPA.w * (c + 0.5)) / pla.cols, MAPA.y - 1.8, { align: 'center' });
  }
  for (let f = 0; f < pla.files; f++) {
    doc.text(String(f + 1), MAPA.x - 3, MAPA.y + (MAPA.h * (f + 0.5)) / pla.files + 1.2, { align: 'center' });
  }

  // Norte
  doc.setFillColor('#ffffff');
  doc.circle(MAPA.x + MAPA.w - 7, MAPA.y + 7, 4.2, 'F');
  doc.setFontSize(9);
  doc.text('N', MAPA.x + MAPA.w - 7, MAPA.y + 6, { align: 'center' });
  doc.setLineWidth(0.5);
  doc.line(MAPA.x + MAPA.w - 7, MAPA.y + 7, MAPA.x + MAPA.w - 7, MAPA.y + 9.8);

  // Escala
  const esc = escalaBonica(pla.metresPerMm);
  const ey = MAPA.y + MAPA.h + 6;
  doc.setLineWidth(0.6);
  doc.setDrawColor(TEXT);
  doc.line(MAPA.x, ey, MAPA.x + esc.mm, ey);
  doc.line(MAPA.x, ey - 1.2, MAPA.x, ey + 1.2);
  doc.line(MAPA.x + esc.mm, ey - 1.2, MAPA.x + esc.mm, ey + 1.2);
  doc.setFont('helvetica', 'normal');
  doc.setFontSize(8);
  doc.text(esc.metres >= 1000 ? `${esc.metres / 1000} km` : `${esc.metres} m`, MAPA.x + esc.mm + 2, ey + 1);

  // Leyenda: temas presentes + 2018
  let lx = MAPA.x + esc.mm + 22;
  const temes = [...new Map(dades.elements.map((e) => [e.tema_id, e])).values()];
  doc.setFontSize(7.5);
  for (const t of temes) {
    doc.setFillColor(t.color);
    doc.rect(lx, ey - 2, 3, 3, 'F');
    doc.text(net(t.tema), lx + 4.2, ey + 0.6);
    lx += doc.getTextWidth(net(t.tema)) + 9;
  }
  doc.setDrawColor(TEXT);
  doc.setLineDashPattern([0.8, 0.6], 0);
  doc.rect(lx, ey - 2, 3, 3);
  doc.setLineDashPattern([], 0);
  doc.text('Vora discontínua: inventari 2017-2018 per revisar', lx + 4.2, ey + 0.6);

  doc.setFontSize(6.8);
  doc.setTextColor('#6b6258');
  doc.text(
    net(`Fons: ${fons === 'pnoa' ? 'PNOA' : 'MTN'} © Instituto Geográfico Nacional · Parcel·les 2018: D. G. del Cadastre · Dades: Observatori Ciutadà de l'Horta — Per l'Horta (CC BY 4.0)`),
    MAPA.x, PAG.h - 7,
  );

  // ── Páginas siguientes: lista
  doc.addPage('a4', 'landscape');
  capcalera(`${p.municipi} · llista per a marcar al camp · generat el ${avui}`);
  doc.setFont('helvetica', 'normal');
  doc.setFontSize(8.5);
  doc.setTextColor(TEXT);
  doc.text(
    net("Per a cada element, marca una casella i apunta el que calga. Després, a la web o a l'app, obri l'element (busca'l pel número al plànol) i respon «És encara així?»: si ha canviat, fes una aportació nova."),
    10, 34, { maxWidth: PAG.w - 20 },
  );

  const caselles = new Set([6, 7, 8]);
  autoTable(doc, {
    startY: 41,
    margin: { left: 10, right: 10, top: 34, bottom: 14 },
    head: [['Núm.', 'Quadre', 'Element', 'Tema', 'Dada', 'Codi', 'Igual', 'Canviat', 'No el trobe', 'Notes']],
    body: ordre.map(({ e, cela: c }, i) => [
      String(i + 1), c,
      net(e.categoria && e.categoria !== 'Sense categoria' ? `${e.variable} · ${e.categoria}` : e.variable),
      net(e.tema), estatDada(e, idioma), e.id.slice(0, 8), '', '', '', '',
    ]),
    theme: 'grid',
    styles: { font: 'helvetica', fontSize: 8, cellPadding: 1.6, textColor: TEXT, lineColor: '#cfc8bd', lineWidth: 0.2, minCellHeight: 8, valign: 'middle' },
    headStyles: { fillColor: '#f3f1ea', textColor: TEXT, fontStyle: 'bold' },
    columnStyles: {
      0: { cellWidth: 11, halign: 'center', fontStyle: 'bold' },
      1: { cellWidth: 14, halign: 'center' },
      2: { cellWidth: 62 },
      3: { cellWidth: 26 },
      4: { cellWidth: 28 },
      5: { cellWidth: 17, font: 'courier', fontSize: 7.5 },
      6: { cellWidth: 13 }, 7: { cellWidth: 14 }, 8: { cellWidth: 17 },
      9: { cellWidth: 'auto' },
    },
    didDrawCell: (c) => {
      if (c.section === 'body' && caselles.has(c.column.index)) {
        const s = 3.6;
        doc.setDrawColor(TEXT);
        doc.setLineWidth(0.3);
        doc.rect(c.cell.x + (c.cell.width - s) / 2, c.cell.y + (c.cell.height - s) / 2, s, s);
      }
    },
    didDrawPage: (d) => {
      if (d.pageNumber > 1) capcalera(`${p.municipi} · llista per a marcar al camp (continuació)`);
    },
  });

  // Pie con número de página en todas
  const total = doc.getNumberOfPages();
  for (let i = 1; i <= total; i++) {
    doc.setPage(i);
    doc.setFont('helvetica', 'normal');
    doc.setFontSize(7.5);
    doc.setTextColor('#6b6258');
    doc.text(`${i} / ${total}`, PAG.w - 10, PAG.h - 7, { align: 'right' });
  }

  return { pdf: doc.output('blob'), nom: `full-de-camp-${slug(p.nom)}-${new Date().toISOString().slice(0, 10)}.pdf` };
}
