import type { Feature, FeatureCollection, Point } from 'geojson';

// ─── Agrupació de punts ────────────────────────────────────────────────────
// Quan diverses icones de la mateixa categoria es trepitgen, se'n pinta una sola amb el
// nombre d'elements. Categories diferents no s'agrupen mai. Igual que en la app
// (app/lib/ui/capa_punts.dart).

/** A partir d'este zoom els punts es dibuixen amb la icona de la guia (abans, cercles). */
export const ZOOM_ICONES = 14;

/** A partir d'este zoom no s'agrupa: les icones ja no es trepitgen (o són al mateix lloc). */
export const ZOOM_SENSE_AGRUPAR = 18;

/** Mida de les icones segons el zoom (icon-size de la capa d'icones). */
export const MIDA_ICONA: [number, number][] = [[ZOOM_ICONES, 0.22], [17, 0.32], [19, 0.42]];

/** Costat, en píxels, de les icones a mida 1 (els PNG de public/simbols fan uns 125 px). */
const PX_ICONA = 125;

/** La mida de la icona al zoom [z], igual que la interpolació lineal de MapLibre. */
export function midaIcona(z: number): number {
  if (z <= MIDA_ICONA[0][0]) return MIDA_ICONA[0][1];
  for (let i = 1; i < MIDA_ICONA.length; i++) {
    const [z1, m1] = MIDA_ICONA[i];
    const [z0, m0] = MIDA_ICONA[i - 1];
    if (z <= z1) return m0 + ((m1 - m0) * (z - z0)) / (z1 - z0);
  }
  return MIDA_ICONA[MIDA_ICONA.length - 1][1];
}

/** Píxels del món (Web Mercator, tessel·les de 512) d'una longitud i latitud a un zoom. */
function pixels(lng: number, lat: number, z: number): [number, number] {
  const mon = 512 * 2 ** z;
  const s = Math.sin((lat * Math.PI) / 180);
  return [((lng + 180) / 360) * mon, (0.5 - Math.log((1 + s) / (1 - s)) / (4 * Math.PI)) * mon];
}

interface Grup {
  clau: string;
  x: number;
  y: number;
  membres: Feature<Point>[];
}

/**
 * Agrupa els punts de [punts] que, al zoom [z], són de la mateixa variable i categoria i
 * queden a menys d'una icona de distància. Torna els punts solts tal qual i, per cada grup,
 * un punt al centre amb: s_icona, s_color, n (nombre d'elements), per_revisar (si ho estan
 * tots), no_validat (si n'hi ha algun) i limits ([oest, sud, est, nord], en JSON).
 */
export function agruparPunts(punts: Feature<Point>[], z: number): FeatureCollection<Point> {
  if (z >= ZOOM_SENSE_AGRUPAR) return { type: 'FeatureCollection', features: punts };
  const dist = PX_ICONA * midaIcona(z);
  const d2 = dist * dist;
  // Graella de cel·les de la mida de la distància: només cal mirar les 9 del voltant
  const cella = new Map<string, Grup[]>();
  const grups: Grup[] = [];
  for (const f of punts) {
    const [lng, lat] = f.geometry.coordinates;
    const [x, y] = pixels(lng, lat, z);
    const p = f.properties ?? {};
    const clau = `${p.variable_id}|${p.categoria_id ?? ''}`;
    const cx = Math.floor(x / dist), cy = Math.floor(y / dist);
    let proper: Grup | null = null;
    let millor = d2;
    for (let i = -1; i <= 1; i++) {
      for (let j = -1; j <= 1; j++) {
        for (const g of cella.get(`${cx + i},${cy + j}`) ?? []) {
          if (g.clau !== clau) continue;
          const dd = (g.x - x) ** 2 + (g.y - y) ** 2;
          if (dd < millor) {
            millor = dd;
            proper = g;
          }
        }
      }
    }
    if (proper) {
      proper.membres.push(f);
      // centre mitjà; el grup es queda en la cel·la on va nàixer (prou per a distàncies d'una icona)
      proper.x += (x - proper.x) / proper.membres.length;
      proper.y += (y - proper.y) / proper.membres.length;
    } else {
      const g: Grup = { clau, x, y, membres: [f] };
      grups.push(g);
      const k = `${cx},${cy}`;
      cella.set(k, [...(cella.get(k) ?? []), g]);
    }
  }
  return {
    type: 'FeatureCollection',
    features: grups.map((g): Feature<Point> => {
      if (g.membres.length === 1) return g.membres[0];
      const coords = g.membres.map((m) => m.geometry.coordinates);
      const lngs = coords.map((c) => c[0]), lats = coords.map((c) => c[1]);
      const p = g.membres[0].properties ?? {};
      return {
        type: 'Feature',
        geometry: {
          type: 'Point',
          coordinates: [lngs.reduce((a, b) => a + b) / coords.length, lats.reduce((a, b) => a + b) / coords.length],
        },
        properties: {
          s_icona: p.s_icona,
          s_color: p.s_color,
          variable_id: p.variable_id,
          n: g.membres.length,
          per_revisar: g.membres.every((m) => m.properties?.per_revisar === true),
          no_validat: g.membres.some((m) => m.properties?.estat !== 'validat'),
          limits: JSON.stringify([Math.min(...lngs), Math.min(...lats), Math.max(...lngs), Math.max(...lats)]),
        },
      };
    }),
  };
}

/** Nom de la imatge de la pastilla amb el nombre d'elements d'un grup. */
export const imatgeNombre = (color: string, n: number) => `nombre-${color.replace('#', '').toLowerCase()}-${n}`;

/** Text fosc damunt dels colors clars (el taronja de construccions), blanc damunt dels foscos. */
function tinta(color: string): string {
  const h = color.replace('#', '');
  const [r, g, b] = [0, 2, 4].map((i) => parseInt(h.slice(i, i + 2), 16) / 255);
  const lin = (c: number) => (c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4);
  const l = 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b);
  return l > 0.3 ? '#2b2520' : '#ffffff';
}

/** La pastilla: el color de la família, vora blanca i el nombre (com en la app). */
export function dibuixNombre(color: string, n: number, ratio: number): ImageData {
  const text = n > 99 ? '99+' : String(n);
  const alt = 20;
  const ample = Math.max(alt, 10 + text.length * 7);
  const c = document.createElement('canvas');
  c.width = ample * ratio;
  c.height = alt * ratio;
  const ctx = c.getContext('2d')!;
  ctx.scale(ratio, ratio);
  const r = alt / 2;
  ctx.beginPath();
  ctx.roundRect(0.75, 0.75, ample - 1.5, alt - 1.5, r);
  ctx.fillStyle = color;
  ctx.fill();
  ctx.lineWidth = 1.5;
  ctx.strokeStyle = '#ffffff';
  ctx.stroke();
  ctx.fillStyle = tinta(color);
  ctx.font = "800 11px 'Montserrat Variable', system-ui, sans-serif";
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';
  ctx.fillText(text, ample / 2, alt / 2 + 0.5);
  return ctx.getImageData(0, 0, c.width, c.height);
}
