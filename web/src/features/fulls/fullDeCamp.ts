// Hojas de una partida en PDF, generadas en el navegador. Dos tipos:
//
// · Full de camp: hoja de trabajo en blanco. La partida lo más grande posible (A4
//   vertical o apaisado según su forma) sobre la ortofoto o el topográfico, con los
//   recintos SIGPAC sobreimpresos. Sin los elementos ya inventariados: es para anotar.
// · Full de revisió: el plano con los elementos numerados y una cuadrícula (A1, B2…);
//   si los números no se leen, una página de detalle ampliada por cada cuadro con
//   elementos; y la lista para marcar «igual / canviat / no el trobe». La numeración es
//   la misma en el plano general, en los detalles y en la lista.
//
// El plano se dibuja a mano en un canvas (teselas del IGN + vectores): MapLibre fuera de
// pantalla no garantiza que las teselas estén cargadas al exportar. jsPDF se carga solo
// cuando alguien pide una hoja.

import type { Geometry, Polygon, Position } from 'geojson';
import { supabase } from '../../lib/supabase';
import { urlTesela, ZOOM_MAX_FONS } from '../mapa/estil';
import type { Fons } from '../mapa/tipus';

interface ElementFull {
  id: string;
  /** Número y cuadro calculados en la base de datos (full_de_camp): los mismos que en la app. */
  numero?: number;
  quadre?: string;
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

export type TipusFull = 'camp' | 'revisio';
export type Pas = 'dades' | 'sigpac' | 'mapa' | 'pdf';

const PPMM = 7.5;                  // píxeles del plano por mm de papel (~190 ppp)
const CEL_MM = 40;                 // lado aproximado de cada cuadro de la cuadrícula
const SEPARACIO_MIN_MM = 6;        // números más juntos que esto en el general → detalles
const VERD = '#215c00';
const TEXT = '#3b352f';
const GRIS = '#6b6258';
const SIGPAC_OGC = 'https://sigpac-hubcloud.es/ogcapi/collections/recintos/items';
const SIGPAC_MAX_PAGINES = 16;     // 250 recintos por página

// ─── Mercator ──────────────────────────────────────────────────────────────
const mx = (lon: number) => (lon + 180) / 360;
const my = (lat: number) => {
  const r = (lat * Math.PI) / 180;
  return (1 - Math.log(Math.tan(r) + 1 / Math.cos(r)) / Math.PI) / 2;
};
const lonDe = (x: number) => x * 360 - 180;
const latDe = (y: number) => (Math.atan(Math.sinh(Math.PI * (1 - 2 * y))) * 180) / Math.PI;

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

// ─── Maquetación ───────────────────────────────────────────────────────────
interface Caixa { x: number; y: number; w: number; h: number }
interface Pagina { w: number; h: number; apaisat: boolean; mapa: Caixa }

/** Página A4 en la orientación pedida. El recuadro deja sitio a los rótulos de la cuadrícula. */
function maquetar(apaisat: boolean): Pagina {
  const w = apaisat ? 297 : 210;
  const h = apaisat ? 210 : 297;
  const marge = 8;
  const rotols = 5;
  const dalt = 27;
  const peu = 17;
  return { w, h, apaisat, mapa: { x: marge + rotols, y: dalt + rotols, w: w - 2 * marge - rotols, h: h - dalt - rotols - peu } };
}

/** Encuadre en coordenadas Mercator 0..1, ajustado al recuadro de su página. */
interface Vista { ox: number; oy: number; w: number; h: number; pagina: Pagina; cols: number; files: number }

/** La partida, con un margen mínimo, ocupando todo el recuadro; orientación según su forma. */
function calcularVista(dades: DadesFull): Vista {
  let [x0, x1, y0, y1] = [Infinity, -Infinity, Infinity, -Infinity];
  for (const [lon, lat] of coordenades(dades.partida!.geometria)) {
    x0 = Math.min(x0, mx(lon)); x1 = Math.max(x1, mx(lon));
    y0 = Math.min(y0, my(lat)); y1 = Math.max(y1, my(lat));
  }
  const pagina = maquetar((x1 - x0) >= (y1 - y0));
  const { mapa } = pagina;
  const marge = 0.03;
  let w = (x1 - x0) * (1 + 2 * marge) || 1e-6;
  let h = (y1 - y0) * (1 + 2 * marge) || 1e-6;
  if (w / h > mapa.w / mapa.h) h = (w * mapa.h) / mapa.w;
  else w = (h * mapa.w) / mapa.h;
  return {
    ox: (x0 + x1) / 2 - w / 2, oy: (y0 + y1) / 2 - h / 2, w, h, pagina,
    cols: Math.max(2, Math.round(mapa.w / CEL_MM)),
    files: Math.max(2, Math.round(mapa.h / CEL_MM)),
  };
}

/** Encuadre ampliado de un cuadro de la cuadrícula, con un poco de margen, en su propia página. */
function vistaDetall(v: Vista, c: number, f: number): Vista {
  const cw = v.w / v.cols;
  const ch = v.h / v.files;
  const marge = 0.08;
  let x0 = v.ox + c * cw - cw * marge;
  let y0 = v.oy + f * ch - ch * marge;
  let w = cw * (1 + 2 * marge);
  let h = ch * (1 + 2 * marge);
  const pagina = maquetar(w >= h);
  const { mapa } = pagina;
  if (w / h > mapa.w / mapa.h) {
    const nh = (w * mapa.h) / mapa.w;
    y0 -= (nh - h) / 2;
    h = nh;
  } else {
    const nw = (h * mapa.w) / mapa.h;
    x0 -= (nw - w) / 2;
    w = nw;
  }
  return { ox: x0, oy: y0, w, h, pagina, cols: v.cols, files: v.files };
}

/** Posición relativa (0..1) dentro del recuadro. */
const relativa = (v: Vista, [lon, lat]: Position): [number, number] => [(mx(lon) - v.ox) / v.w, (my(lat) - v.oy) / v.h];

function cela(v: Vista, [u, t]: [number, number]) {
  const c = Math.min(v.cols - 1, Math.max(0, Math.floor(u * v.cols)));
  const f = Math.min(v.files - 1, Math.max(0, Math.floor(t * v.files)));
  return { c, f, nom: `${lletra(c)}${f + 1}` };
}

interface Numerat { e: ElementFull; n: number; cela: string; c: number; f: number; pos: [number, number] }

/**
 * Por cuadros (fila a fila, de izquierda a derecha) y dentro de cada cuadro de arriba abajo.
 * Si la base de datos ya los trae numerados (full_de_camp), manda ella: así coinciden con la app.
 */
function numerar(v: Vista, elements: ElementFull[]): Numerat[] {
  if (elements.length && elements.every((e) => e.numero && e.quadre)) {
    return elements
      .map((e) => ({ e, n: e.numero!, cela: e.quadre!, c: e.quadre!.charCodeAt(0) - 65, f: Number(e.quadre!.slice(1)) - 1, pos: relativa(v, e.etiqueta) }))
      .sort((a, b) => a.n - b.n);
  }
  return elements
    .map((e) => ({ e, pos: relativa(v, e.etiqueta) }))
    .map((x) => ({ ...x, cela: cela(v, x.pos) }))
    .sort((a, b) => a.cela.f - b.cela.f || a.cela.c - b.cela.c || a.pos[1] - b.pos[1] || a.pos[0] - b.pos[0])
    .map(({ e, pos, cela: c }, i) => ({ e, n: i + 1, cela: c.nom, c: c.c, f: c.f, pos }));
}

/** ¿Hay números demasiado juntos en el plano general para leerlos? */
function calenDetalls(v: Vista, ordre: Numerat[]) {
  const { mapa } = v.pagina;
  const mm = ordre.map((x) => [x.pos[0] * mapa.w, x.pos[1] * mapa.h]);
  for (let i = 0; i < mm.length; i++) {
    for (let j = i + 1; j < mm.length; j++) {
      if (Math.hypot(mm[i][0] - mm[j][0], mm[i][1] - mm[j][1]) < SEPARACIO_MIN_MM) return true;
    }
  }
  return false;
}

// ─── SIGPAC ────────────────────────────────────────────────────────────────
interface RecinteSigpac { geometria: Polygon; parcela: number; recinto: number }

/** Recintos SIGPAC (FEGA, campaña vigente) del encuadre. Si el servicio falla, el plano sale sin ellos. */
async function recintesSigpac(v: Vista): Promise<RecinteSigpac[] | null> {
  const bbox = [lonDe(v.ox), latDe(v.oy + v.h), lonDe(v.ox + v.w), latDe(v.oy)].map((n) => n.toFixed(6)).join(',');
  let url: string | undefined = `${SIGPAC_OGC}?f=json&limit=250&bbox=${bbox}`;
  const recintes: RecinteSigpac[] = [];
  try {
    for (let i = 0; url && i < SIGPAC_MAX_PAGINES; i++) {
      const res: Response = await fetch(url, { signal: AbortSignal.timeout(25000) });
      if (!res.ok) throw new Error(`SIGPAC HTTP ${res.status}`);
      const j = (await res.json()) as {
        features: { geometry: Polygon | null; properties: { parcela: number; recinto: number } }[];
        links?: { rel: string; href: string }[];
      };
      for (const f of j.features) {
        if (f.geometry?.type === 'Polygon') recintes.push({ geometria: f.geometry, parcela: f.properties.parcela, recinto: f.properties.recinto });
      }
      url = j.links?.find((l) => l.rel === 'next')?.href;
    }
    return recintes;
  } catch (e) {
    console.warn('SIGPAC no disponible:', e);
    return null;
  }
}

// ─── Plano ─────────────────────────────────────────────────────────────────
interface Pla { imatge: string; metresPerMm: number }

async function dibuixarPla(v: Vista, ordre: Numerat[], partida: Geometry, fons: Fons, sigpac: RecinteSigpac[] | null): Promise<Pla> {
  const { mapa } = v.pagina;
  const objectiu = mapa.w * PPMM;
  const z = Math.max(10, Math.min(ZOOM_MAX_FONS[fons], Math.round(Math.log2(objectiu / (v.w * 256)))));
  const mon = 256 * 2 ** z;
  const canvasW = Math.round(objectiu);
  const canvasH = Math.round((objectiu * mapa.h) / mapa.w);
  const escala = canvasW / (v.w * mon);       // píxeles de canvas por píxel de tesela

  const canvas = document.createElement('canvas');
  canvas.width = canvasW;
  canvas.height = canvasH;
  const ctx = canvas.getContext('2d')!;
  ctx.fillStyle = '#ffffff';
  ctx.fillRect(0, 0, canvasW, canvasH);

  // Teselas
  const tx0 = Math.floor((v.ox * mon) / 256);
  const tx1 = Math.floor(((v.ox + v.w) * mon) / 256);
  const ty0 = Math.floor((v.oy * mon) / 256);
  const ty1 = Math.floor(((v.oy + v.h) * mon) / 256);
  const tesseles: Promise<void>[] = [];
  for (let tx = tx0; tx <= tx1; tx++) {
    for (let ty = ty0; ty <= ty1; ty++) {
      tesseles.push(carregarImatge(urlTesela(fons, z, tx, ty)).then((img) => {
        if (!img) return;
        ctx.drawImage(img, (tx * 256 - v.ox * mon) * escala, (ty * 256 - v.oy * mon) * escala, 256 * escala + 1, 256 * escala + 1);
      }));
    }
  }
  await Promise.all(tesseles);

  const aCanvas = (p: Position): [number, number] => {
    const [u, t] = relativa(v, p);
    return [u * canvasW, t * canvasH];
  };
  const u = canvasW / 2400;                    // grosores proporcionales al tamaño
  const traçar = (anell: Position[]) => {
    anell.forEach((p, i) => {
      const [px, py] = aCanvas(p);
      if (i === 0) ctx.moveTo(px, py);
      else ctx.lineTo(px, py);
    });
    ctx.closePath();
  };
  const orto = fons === 'pnoa';
  ctx.lineJoin = 'round';

  // Recintos SIGPAC: amarillo sobre la ortofoto (como el visor del FEGA), ocre sobre el topográfico
  if (sigpac) {
    ctx.beginPath();
    sigpac.forEach((r) => r.geometria.coordinates.forEach(traçar));
    if (orto) {
      ctx.strokeStyle = 'rgba(0,0,0,0.45)';
      ctx.lineWidth = 3.4 * u;
      ctx.stroke();
    }
    ctx.strokeStyle = orto ? '#ffd400' : '#b86e00';
    ctx.lineWidth = 1.6 * u;
    ctx.stroke();

    // Número de parcela en los recintos que tienen sitio
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.font = `600 ${Math.round(11 * u)}px Helvetica, Arial, sans-serif`;
    for (const r of sigpac) {
      const ext = r.geometria.coordinates[0].map(aCanvas);
      let area = 0; let cx = 0; let cy = 0;
      for (let i = 0, j = ext.length - 1; i < ext.length; j = i++) {
        const f = ext[j][0] * ext[i][1] - ext[i][0] * ext[j][1];
        area += f; cx += (ext[j][0] + ext[i][0]) * f; cy += (ext[j][1] + ext[i][1]) * f;
      }
      area /= 2;
      if (Math.abs(area) < 3000 * u * u) continue;
      cx /= 6 * area; cy /= 6 * area;
      if (cx < 0 || cy < 0 || cx > canvasW || cy > canvasH) continue;
      const text = r.recinto > 1 ? `${r.parcela}·${r.recinto}` : String(r.parcela);
      if (orto) {
        ctx.lineWidth = 3 * u;
        ctx.strokeStyle = 'rgba(0,0,0,0.7)';
        ctx.strokeText(text, cx, cy);
        ctx.fillStyle = '#fff3a0';
      } else {
        ctx.fillStyle = '#8a5200';
      }
      ctx.fillText(text, cx, cy);
    }
  }

  // Fuera de la partida, velado: la vista va a lo que toca
  ctx.beginPath();
  ctx.rect(0, 0, canvasW, canvasH);
  anells(partida).forEach(traçar);
  ctx.fillStyle = 'rgba(255,255,255,0.5)';
  ctx.fill('evenodd');

  // Elementos (lo de 2018 sin revisar, con borde discontinuo, como en el mapa web)
  for (const { e } of ordre) {
    ctx.setLineDash(e.per_revisar ? [10 * u, 6 * u] : []);
    ctx.strokeStyle = e.color;
    if (e.geometria.type === 'Polygon' || e.geometria.type === 'MultiPolygon') {
      ctx.beginPath();
      anells(e.geometria).forEach(traçar);
      ctx.globalAlpha = 0.16;
      ctx.fillStyle = e.color;
      ctx.fill('evenodd');
      ctx.globalAlpha = 1;
      ctx.lineWidth = 2.6 * u;
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
  anells(partida).forEach(traçar);
  ctx.strokeStyle = '#ffffff';
  ctx.lineWidth = 10 * u;
  ctx.stroke();
  ctx.strokeStyle = VERD;
  ctx.lineWidth = 5 * u;
  ctx.stroke();

  // Números (los de toda la partida: en un detalle salen los mismos que en el general)
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';
  ctx.font = `bold ${Math.round(15 * u)}px Helvetica, Arial, sans-serif`;
  for (const { e, n } of ordre) {
    const [px, py] = aCanvas(e.etiqueta);
    if (px < -20 || py < -20 || px > canvasW + 20 || py > canvasH + 20) continue;
    const r = (n >= 100 ? 15 : 12) * u;
    ctx.beginPath();
    ctx.arc(px, py, r, 0, Math.PI * 2);
    ctx.fillStyle = '#ffffff';
    ctx.fill();
    ctx.lineWidth = 3 * u;
    ctx.strokeStyle = e.color;
    ctx.stroke();
    ctx.fillStyle = TEXT;
    ctx.fillText(String(n), px, py + 0.5 * u);
  }

  const latCentre = latDe(v.oy + v.h / 2);
  const metresPerPixelCanvas = (40075016.686 * Math.cos((latCentre * Math.PI) / 180)) / (mon * escala);
  return { imatge: canvas.toDataURL('image/jpeg', 0.78), metresPerMm: metresPerPixelCanvas * (canvasW / mapa.w) };
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
export async function generarFull(partidaId: number, tipus: TipusFull, fons: Fons, onPas: (p: Pas) => void, idioma = 'ca-ES') {
  onPas('dades');
  const { data, error } = await supabase.rpc('full_de_camp', { p_partida_id: partidaId });
  if (error) throw error;
  return construirFull(data as DadesFull, tipus, fons, onPas, idioma);
}

/** El PDF a partir de los datos ya cargados. Devuelve el fichero; descargarlo es cosa de quien llama. */
export async function construirFull(dades: DadesFull, tipus: TipusFull, fons: Fons, onPas: (p: Pas) => void = () => {}, idioma = 'ca-ES') {
  if (!dades.partida) throw new Error('Partida inexistent');
  const p = dades.partida;
  const revisio = tipus === 'revisio';
  const v = calcularVista(dades);
  const ordre = revisio ? numerar(v, dades.elements) : [];

  onPas('sigpac');
  const [sigpac, { jsPDF }, { default: autoTable }, logo] = await Promise.all([
    recintesSigpac(v), import('jspdf'), import('jspdf-autotable'), logoComDataUrl(),
  ]);

  onPas('mapa');
  const general = await dibuixarPla(v, ordre, p.geometria, fons, sigpac);
  // Detalles: un cuadro por página, solo los que tienen elementos y solo si en el general no se leen
  const detalls: { v: Vista; nom: string; pla: Pla; ns: number[] }[] = [];
  if (revisio && calenDetalls(v, ordre)) {
    const celes = new Map<string, Numerat[]>();
    for (const x of ordre) celes.set(x.cela, [...(celes.get(x.cela) ?? []), x]);
    for (const [nom, elems] of celes) {
      const vd = vistaDetall(v, elems[0].c, elems[0].f);
      detalls.push({ v: vd, nom, pla: await dibuixarPla(vd, ordre, p.geometria, fons, sigpac), ns: elems.map((x) => x.n) });
    }
  }

  onPas('pdf');
  const avui = new Date().toLocaleDateString(idioma);
  const doc = new jsPDF({ orientation: v.pagina.apaisat ? 'landscape' : 'portrait', unit: 'mm', format: 'a4' });
  const titol = revisio ? 'FULL DE REVISIÓ' : 'FULL DE CAMP';
  doc.setProperties({ title: `${titol} · ${net(p.nom)}`, author: "Observatori Ciutadà de l'Horta", creator: "Observatori Ciutadà de l'Horta" });
  const nomFons = fons === 'pnoa' ? 'ortofoto PNOA' : 'mapa topogràfic';
  const area = `${new Intl.NumberFormat(idioma).format(p.area_ha)} ha`;

  const capcalera = (amplePagina: number, subtitol: string) => {
    if (logo) doc.addImage(logo, 'PNG', 8, 8, 39.5, 11);
    doc.setTextColor(VERD);
    doc.setFont('helvetica', 'bold');
    doc.setFontSize(8);
    doc.text(titol, 52, 11.5);
    doc.setTextColor(TEXT);
    doc.setFontSize(14);
    doc.text(net(p.nom), 52, 17.5);
    doc.setFont('helvetica', 'normal');
    doc.setFontSize(8);
    doc.text(net(subtitol), 52, 22.3, { maxWidth: amplePagina - 60 });
    doc.setDrawColor('#9ed100');
    doc.setLineWidth(1.1);
    doc.line(8, 25, amplePagina - 8, 25);
  };

  /** Plano en su recuadro: imagen, cuadrícula opcional, norte, escala, leyenda y créditos. */
  const pagPla = (vp: Vista, pla: Pla, ambQuadricula: boolean, ambElements: boolean, nota?: string) => {
    const { pagina } = vp;
    const { mapa } = pagina;
    doc.addImage(pla.imatge, 'JPEG', mapa.x, mapa.y, mapa.w, mapa.h);
    if (ambQuadricula) {
      doc.setLineWidth(0.3);
      doc.setDrawColor('#ffffff');
      for (let c = 1; c < vp.cols; c++) {
        const x = mapa.x + (mapa.w * c) / vp.cols;
        doc.line(x, mapa.y, x, mapa.y + mapa.h);
      }
      for (let f = 1; f < vp.files; f++) {
        const y = mapa.y + (mapa.h * f) / vp.files;
        doc.line(mapa.x, y, mapa.x + mapa.w, y);
      }
      doc.setFont('helvetica', 'bold');
      doc.setFontSize(9);
      doc.setTextColor(TEXT);
      for (let c = 0; c < vp.cols; c++) doc.text(lletra(c), mapa.x + (mapa.w * (c + 0.5)) / vp.cols, mapa.y - 1.6, { align: 'center' });
      for (let f = 0; f < vp.files; f++) doc.text(String(f + 1), mapa.x - 2.8, mapa.y + (mapa.h * (f + 0.5)) / vp.files + 1.2, { align: 'center' });
    }
    doc.setDrawColor(TEXT);
    doc.setLineWidth(0.3);
    doc.rect(mapa.x, mapa.y, mapa.w, mapa.h);

    // Norte
    const nx = mapa.x + mapa.w - 7;
    const ny = mapa.y + 7;
    doc.setFillColor('#ffffff');
    doc.circle(nx, ny, 4.2, 'F');
    doc.setFont('helvetica', 'bold');
    doc.setFontSize(9);
    doc.setTextColor(TEXT);
    doc.text('N', nx, ny - 0.8, { align: 'center' });
    doc.setLineWidth(0.5);
    doc.line(nx, ny + 0.3, nx, ny + 3);

    // Escala y leyenda (con salto de línea si no cabe)
    const esc = escalaBonica(pla.metresPerMm);
    let ly = mapa.y + mapa.h + 5.5;
    doc.setLineWidth(0.6);
    doc.line(mapa.x, ly, mapa.x + esc.mm, ly);
    doc.line(mapa.x, ly - 1.2, mapa.x, ly + 1.2);
    doc.line(mapa.x + esc.mm, ly - 1.2, mapa.x + esc.mm, ly + 1.2);
    doc.setFont('helvetica', 'normal');
    doc.setFontSize(7.5);
    const textEscala = esc.metres >= 1000 ? `${esc.metres / 1000} km` : `${esc.metres} m`;
    doc.text(textEscala, mapa.x + esc.mm + 2, ly + 1);
    let lx = mapa.x + esc.mm + 4 + doc.getTextWidth(textEscala) + 6;
    const dreta = pagina.w - 8;
    const entrada = (ample: number, dibuix: (x: number, y: number) => void, text: string) => {
      if (lx + ample + 1.2 + doc.getTextWidth(text) > dreta) { lx = mapa.x; ly += 4.5; }
      dibuix(lx, ly);
      doc.setTextColor(TEXT);
      doc.text(text, lx + ample + 1.2, ly + 0.7);
      lx += ample + 1.2 + doc.getTextWidth(text) + 5;
    };
    entrada(5, (x, y) => { doc.setDrawColor(VERD); doc.setLineWidth(1); doc.line(x, y - 0.5, x + 5, y - 0.5); }, 'Partida');
    if (sigpac) entrada(5, (x, y) => { doc.setDrawColor(fons === 'pnoa' ? '#e0b800' : '#b86e00'); doc.setLineWidth(0.6); doc.line(x, y - 0.5, x + 5, y - 0.5); }, 'Recinte SIGPAC (núm. de parcel·la)');
    if (ambElements) {
      for (const t of new Map(dades.elements.map((e) => [e.tema_id, e])).values()) {
        entrada(3, (x, y) => { doc.setFillColor(t.color); doc.rect(x, y - 2, 3, 3, 'F'); }, net(t.tema));
      }
      entrada(3, (x, y) => { doc.setDrawColor(TEXT); doc.setLineWidth(0.3); doc.setLineDashPattern([0.8, 0.6], 0); doc.rect(x, y - 2, 3, 3); doc.setLineDashPattern([], 0); }, 'Discontinu: inventari 2017-2018 per revisar');
    }
    if (nota) {
      doc.setFont('helvetica', 'normal');
      doc.setFontSize(7.5);
      doc.setTextColor(TEXT);
      doc.text(net(nota), mapa.x, ly + 5, { maxWidth: pagina.w - 30 });
    }

    doc.setFont('helvetica', 'normal');
    doc.setFontSize(6.5);
    doc.setTextColor(GRIS);
    doc.text(
      net(`Fons: ${fons === 'pnoa' ? 'PNOA' : 'MTN'} © Instituto Geográfico Nacional${sigpac ? ' · Recintes SIGPAC © FEGA' : ''}${ambElements ? " · Parcel·les 2018: D. G. del Cadastre · Dades: Observatori Ciutadà de l'Horta — Per l'Horta (CC BY 4.0)" : ''}`),
      8, pagina.h - 4, { maxWidth: pagina.w - 30 },
    );
    if (!sigpac) {
      doc.setTextColor('#8f1f1a');
      doc.text('No s\'ha pogut consultar el SIGPAC: el plànol va sense recintes.', 8, pagina.h - 7.5);
    }
  };

  // ── Plano general
  capcalera(v.pagina.w, revisio
    ? `${p.municipi} · ${area} · ${dades.elements.length} elements · sobre ${nomFons} · ${avui}`
    : `${p.municipi} · ${area} · full de treball en blanc sobre ${nomFons}${sigpac ? ' amb recintes SIGPAC' : ''} · ${avui}`);
  pagPla(v, general, revisio, revisio,
    detalls.length ? `Detalls ampliats a les pàgines següents: ${detalls.map((d) => d.nom).join(', ')}.` : undefined);

  // ── Detalles
  for (const d of detalls) {
    doc.addPage('a4', d.v.pagina.apaisat ? 'landscape' : 'portrait');
    const rang = d.ns.length > 1 ? `elements ${d.ns[0]} a ${d.ns[d.ns.length - 1]}` : `element ${d.ns[0]}`;
    capcalera(d.v.pagina.w, `Detall del quadre ${d.nom} · ${rang} · ${p.municipi}`);
    pagPla(d.v, d.pla, false, true);
  }

  // ── Lista (solo en la hoja de revisión)
  if (revisio) {
    doc.addPage('a4', 'landscape');
    capcalera(297, `${p.municipi} · llista per a marcar al camp · ${avui}`);
    doc.setFont('helvetica', 'normal');
    doc.setFontSize(8.5);
    doc.setTextColor(TEXT);
    doc.text(
      net("Per a cada element, marca una casella i apunta el que calga. El número i el quadre són els del plànol i dels detalls. Després, a la web o a l'app, obri l'element i respon «És encara així?»: si ha canviat, fes una aportació nova."),
      8, 31, { maxWidth: 281 },
    );
    const caselles = new Set([6, 7, 8]);
    autoTable(doc, {
      startY: 38,
      margin: { left: 8, right: 8, top: 30, bottom: 12 },
      head: [['Núm.', 'Quadre', 'Element', 'Tema', 'Dada', 'Codi', 'Igual', 'Canviat', 'No el trobe', 'Notes']],
      body: ordre.map(({ e, n, cela: c }) => [
        String(n), c,
        net(e.categoria && e.categoria !== 'Sense categoria' ? `${e.variable} · ${e.categoria}` : e.variable),
        net(e.tema), estatDada(e, idioma), e.id.slice(0, 8), '', '', '', '',
      ]),
      theme: 'grid',
      styles: { font: 'helvetica', fontSize: 8, cellPadding: 1.6, textColor: TEXT, lineColor: '#cfc8bd', lineWidth: 0.2, minCellHeight: 8, valign: 'middle' },
      headStyles: { fillColor: '#f3f1ea', textColor: TEXT, fontStyle: 'bold' },
      columnStyles: {
        0: { cellWidth: 11, halign: 'center', fontStyle: 'bold' },
        1: { cellWidth: 14, halign: 'center' },
        2: { cellWidth: 64 },
        3: { cellWidth: 26 },
        4: { cellWidth: 28 },
        5: { cellWidth: 17, font: 'courier', fontSize: 7.5 },
        6: { cellWidth: 13 }, 7: { cellWidth: 14 }, 8: { cellWidth: 17 },
        9: { cellWidth: 'auto' },
      },
      didDrawCell: (c) => {
        if (c.section === 'body' && caselles.has(c.column.index)) {
          const mida = 3.6;
          doc.setDrawColor(TEXT);
          doc.setLineWidth(0.3);
          doc.rect(c.cell.x + (c.cell.width - mida) / 2, c.cell.y + (c.cell.height - mida) / 2, mida, mida);
        }
      },
      didDrawPage: (d) => {
        if (d.pageNumber > 1) capcalera(297, `${p.municipi} · llista per a marcar al camp (continuació)`);
      },
    });
  }

  // Número de página
  const total = doc.getNumberOfPages();
  for (let i = 1; i <= total; i++) {
    doc.setPage(i);
    const { width, height } = doc.internal.pageSize;
    doc.setFont('helvetica', 'normal');
    doc.setFontSize(7.5);
    doc.setTextColor(GRIS);
    doc.text(`${i} / ${total}`, width - 8, height - 4, { align: 'right' });
  }

  const prefix = revisio ? 'full-de-revisio' : 'full-de-camp';
  return { pdf: doc.output('blob'), nom: `${prefix}-${slug(p.nom)}-${new Date().toISOString().slice(0, 10)}.pdf` };
}
