import type { Feature, FeatureCollection } from 'geojson';
import type { Map as MapaGL } from 'maplibre-gl';
import guia from './simbologia.json';
import type { Tema } from './tipus';

// Simbologia de la guia de disseny (docs/simbologia). simbologia.json el genera
// docs/simbologia/generar.py, que també en fa la còpia de l'app: no editar a mà.

type Regla = { variable: string; categoria?: string; icona?: string; familia?: string; estil?: string };
type Familia = { nom: string; color: string; contorn: string; icona: string };
export type Patro = 'continua' | 'discontinua' | 'puntejada' | 'punt_ratlla' | 'doble' | 'cap';
export type Glif = 'fletxa' | 'quadrat' | 'travesser' | 'mur' | 'x' | 'ziga' | 'ona';
type EstilLinia = { nom: string; color: string; amplada: number; patro: Patro; glif?: Glif };
export type Trama = 'ratlles' | 'punts';
type EstilParcela = { nom: string; color: string; contorn: string; trama: Trama | null };

const FAMILIES = guia.families as Record<string, Familia>;
const ESTILS_LINIA = guia.estilsLinia as Record<string, EstilLinia>;
const ESTILS_PARCELA = guia.estilsParcela as Record<string, EstilParcela>;
const FAMILIA_TEMA = guia.familiaTema as Record<string, string>;

export const PALETA: string[] = guia.paleta;

export type Simbol =
  | { tipus: 'punt'; nom: string; icona: string; color: string; contorn: string }
  | ({ tipus: 'linia'; estil: string } & EstilLinia)
  | ({ tipus: 'parcela'; estil: string } & EstilParcela);

/** Glifs que es dibuixen com a trama contínua de la línia (line-pattern): ja porten la línia base. */
export const GLIFS_TRAMA: Glif[] = ['quadrat', 'travesser', 'mur', 'x', 'ziga', 'ona'];

function perVariable(regles: Regla[]) {
  type Entrada = { general?: Regla; cats: Map<string, Regla> };
  const m = new Map<string, Entrada>();
  for (const r of regles) {
    const e: Entrada = m.get(r.variable) ?? { cats: new Map() };
    if (r.categoria) e.cats.set(r.categoria, r);
    else e.general = r;
    m.set(r.variable, e);
  }
  return m;
}
const PUNTS = perVariable(guia.punts);
const LINIES = perVariable(guia.linies);
const PARCELES = perVariable(guia.parceles);

const puntDe = (familia: string, icona?: string): Simbol => {
  const f = FAMILIES[familia] ?? FAMILIES.serveis;
  return { tipus: 'punt', nom: f.nom, icona: icona ?? f.icona, color: f.color, contorn: f.contorn };
};

export interface IndexSimbols {
  /** El símbol d'un element (la categoria és opcional). */
  simbol: (variableId: number, categoriaId?: number | null) => Simbol;
}

/** Del catàleg (ids i noms) a una funció id → símbol. Les regles de la guia van per nom. */
export function indexSimbologia(temes: Tema[]): IndexSimbols {
  const cache = new Map<string, Simbol>();
  const variables = new Map(temes.flatMap((t) => t.variables.map((v) => [v.id, { v, t }] as const)));

  const resoldre = (variableId: number, categoriaId: number | null): Simbol => {
    const trobat = variables.get(variableId);
    if (!trobat) return puntDe('serveis');
    const { v, t } = trobat;
    const cat = v.categories.find((c) => c.id === categoriaId)?.nom;
    const familiaTema = FAMILIA_TEMA[t.nom] ?? 'serveis';

    if (v.geometria === 'punt') {
      const e = PUNTS.get(v.nom);
      const r = (cat && e?.cats.get(cat)) || e?.general;
      return r ? puntDe(r.familia ?? familiaTema, r.icona) : puntDe(familiaTema);
    }
    if (v.geometria === 'linia') {
      const e = LINIES.get(v.nom);
      const r = (cat && e?.cats.get(cat)) || e?.general;
      const estil = r?.estil && ESTILS_LINIA[r.estil];
      if (estil) return { tipus: 'linia', estil: r.estil!, ...estil };
      return { tipus: 'linia', estil: 'tema', nom: t.nom, color: t.color, amplada: 2, patro: 'continua' };
    }
    const e = PARCELES.get(v.nom);
    const r = (cat && e?.cats.get(cat)) || e?.general;
    const estil = r?.estil && ESTILS_PARCELA[r.estil];
    if (estil) return { tipus: 'parcela', estil: r.estil!, ...estil };
    return { tipus: 'parcela', estil: 'tema', nom: t.nom, color: t.color, contorn: '#574F46', trama: null };
  };

  return {
    simbol: (variableId, categoriaId = null) => {
      const clau = `${variableId}|${categoriaId ?? ''}`;
      let s = cache.get(clau);
      if (!s) cache.set(clau, (s = resoldre(variableId, categoriaId ?? null)));
      return s;
    },
  };
}

const hex = (c: string) => c.replace('#', '').toLowerCase();

/** Nom de la imatge de trama (line-pattern) o de fletxa per a un estil de línia. */
export const imatgeGlif = (glif: Glif, color: string) => `glif-${glif}-${hex(color)}`;

/**
 * Afig a cada element el que necessiten les capes del mapa (prefix s_):
 * s_color, s_contorn, s_icona (punts), s_patro, s_amplada, s_glif, s_imatge (línies), s_trama (parcel·les).
 */
export function ambSimbols(fc: FeatureCollection, index: IndexSimbols): FeatureCollection {
  return {
    ...fc,
    features: fc.features.map((f): Feature => {
      const p = f.properties ?? {};
      const s = index.simbol(p.variable_id as number, p.categoria_id as number | null);
      const extra: Record<string, unknown> = { s_color: s.color };
      if (s.tipus === 'punt') {
        extra.s_icona = s.icona;
        extra.s_contorn = s.contorn;
      } else if (s.tipus === 'linia') {
        extra.s_patro = s.glif && GLIFS_TRAMA.includes(s.glif) ? 'trama' : s.patro;
        extra.s_amplada = s.amplada;
        if (s.glif) {
          extra.s_glif = s.glif;
          extra.s_imatge = imatgeGlif(s.glif, s.color);
        }
      } else {
        extra.s_contorn = s.contorn;
        if (s.trama) extra.s_trama = `trama-${s.trama}`;
      }
      return { ...f, properties: { ...p, ...extra } };
    }),
  };
}

// ─── Imatges del mapa ──────────────────────────────────────────────────────

const RATIO = 2;

function llenç(w: number, h: number, dibuix: (c: CanvasRenderingContext2D) => void) {
  const canvas = document.createElement('canvas');
  canvas.width = w * RATIO;
  canvas.height = h * RATIO;
  const c = canvas.getContext('2d')!;
  c.scale(RATIO, RATIO);
  dibuix(c);
  return c.getImageData(0, 0, canvas.width, canvas.height);
}

/** Trames de les parcel·les: blanc sobre transparent (damunt del color de la parcel·la). */
function trama(tipus: Trama) {
  return tipus === 'ratlles'
    ? llenç(14, 14, (c) => {
      c.strokeStyle = '#ffffff';
      c.lineWidth = 2.5;
      // Diagonals que casen a les vores perquè la trama no es note
      for (const d of [-14, 0, 14]) {
        c.beginPath();
        c.moveTo(d, 14);
        c.lineTo(d + 14, 0);
        c.stroke();
      }
    })
    : llenç(16, 16, (c) => {
      c.fillStyle = '#ffffff';
      for (const [x, y] of [[4, 4], [12, 12]]) {
        c.beginPath();
        c.arc(x, y, 2.2, 0, Math.PI * 2);
        c.fill();
      }
    });
}

/** Tram d'una línia amb decoració, repetit al llarg (la línia va d'esquerra a dreta, al mig). */
export function dibuixGlif(c: CanvasRenderingContext2D, glif: Glif, color: string, w: number, h: number) {
  c.strokeStyle = color;
  c.fillStyle = color;
  c.lineWidth = 1.2;
  c.lineCap = 'butt';
  const m = h / 2;
  const linia = (y = m) => {
    c.beginPath();
    c.moveTo(0, y);
    c.lineTo(w, y);
    c.stroke();
  };
  switch (glif) {
    case 'quadrat':
      c.strokeRect(1.5, m - 3, 6, 6);
      break;
    case 'travesser':
      linia();
      c.beginPath();
      c.moveTo(w / 2, m - 2.5);
      c.lineTo(w / 2, m + 2.5);
      c.stroke();
      break;
    case 'mur':
      linia(m - 1.5);
      c.fillRect(w / 2 - 1, m - 1.5, 2.2, 4.5);
      break;
    case 'x':
      linia(m - 2.5);
      c.beginPath();
      c.moveTo(w / 2 - 2, m);
      c.lineTo(w / 2 + 2, m + 4);
      c.moveTo(w / 2 + 2, m);
      c.lineTo(w / 2 - 2, m + 4);
      c.stroke();
      break;
    case 'ziga':
      c.beginPath();
      c.moveTo(0, m + 3);
      c.lineTo(w / 2, m - 3);
      c.lineTo(w, m + 3);
      c.stroke();
      break;
    case 'ona':
      c.lineWidth = 1.5;
      c.beginPath();
      c.moveTo(0, m + 2);
      c.bezierCurveTo(0, m - 4, w / 2, m - 4, w / 2, m + 2);
      c.bezierCurveTo(w / 2, m + 3, w, m + 3, w, m + 2);
      c.stroke();
      break;
    case 'fletxa':
      c.beginPath();
      c.moveTo(w - 1, m);
      c.lineTo(1, m - h / 2 + 1);
      c.lineTo(4, m);
      c.lineTo(1, m + h / 2 - 1);
      c.closePath();
      c.fill();
      break;
  }
}

/** Mida (en px) del tram de cada glif: per a la trama, l'alçada és l'amplada de la línia. */
export const MIDA_GLIF: Record<Glif, [number, number]> = {
  quadrat: [9, 8], travesser: [7, 8], mur: [14, 8], x: [8, 10], ziga: [10, 8], ona: [12, 8], fletxa: [9, 8],
};

/**
 * Carrega a demanda les imatges que demana una capa: icones dels punts (/simbols/<nom>.png),
 * trames de parcel·la (trama-*) i trams de línia (glif-<glif>-<color>). MapLibre espera la
 * promesa abans de donar la imatge per perduda.
 */
export function servirImatges(mapa: MapaGL) {
  mapa.setMissingStyleImageResolver(async (id) => {
    if (mapa.hasImage(id)) return;
    if (id.startsWith('trama-')) {
      mapa.addImage(id, trama(id.slice(6) as Trama), { pixelRatio: RATIO });
    } else if (id.startsWith('glif-')) {
      const [, glif, color] = id.split('-') as [string, Glif, string];
      const [w, h] = MIDA_GLIF[glif];
      mapa.addImage(id, llenç(w, h, (c) => dibuixGlif(c, glif, `#${color}`, w, h)), { pixelRatio: RATIO });
    } else {
      // Sense icona (no hauria de passar): el punt es veu com a cercle a zoom baix
      const r = await mapa.loadImage(`/simbols/${id}.png`).catch(() => null);
      if (r && !mapa.hasImage(id)) mapa.addImage(id, r.data, { pixelRatio: 1 });
    }
  });
}
