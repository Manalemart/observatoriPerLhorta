// Recinto SIGPAC bajo un punto, consultado en vivo al OGC API del FEGA (campaña vigente).
import type { Polygon, Position } from 'geojson';

const OGCAPI = 'https://sigpac-hubcloud.es/ogcapi/collections/recintos/items';
const MARGE_GRAUS = 0.00002; // ~2 m: el servicio filtra por caja; el punto exacto se comprueba aquí
const MAX_RESULTATS = 50;

export interface Recinte {
  ref: string;
  dnPk: number;
  geometria: Polygon;
}

interface PropietatsRecinte {
  dn_pk: number;
  provincia: number;
  municipio: number;
  agregado: number;
  zona: number;
  poligono: number;
  parcela: number;
  recinto: number;
}

const zeros = (n: number, ample: number) => String(n).padStart(ample, '0');

// Formato oficial: provincia:municipio:agregado:zona:poligono:parcela:recinto
function referencia(p: PropietatsRecinte): string {
  return [
    zeros(p.provincia, 2), zeros(p.municipio, 3), p.agregado, p.zona,
    zeros(p.poligono, 3), zeros(p.parcela, 5), zeros(p.recinto, 4),
  ].join(':');
}

function dinsAnell([x, y]: number[], anell: Position[]): boolean {
  let dins = false;
  for (let i = 0, j = anell.length - 1; i < anell.length; j = i++) {
    const [xi, yi] = anell[i];
    const [xj, yj] = anell[j];
    if (yi > y !== yj > y && x < ((xj - xi) * (y - yi)) / (yj - yi) + xi) dins = !dins;
  }
  return dins;
}

function dinsPoligon(punt: number[], poligon: Polygon): boolean {
  const [exterior, ...forats] = poligon.coordinates;
  return dinsAnell(punt, exterior) && !forats.some((f) => dinsAnell(punt, f));
}

export async function recintEnPunt(lng: number, lat: number): Promise<Recinte | null> {
  const bbox = [lng - MARGE_GRAUS, lat - MARGE_GRAUS, lng + MARGE_GRAUS, lat + MARGE_GRAUS].join(',');
  const res = await fetch(`${OGCAPI}?f=json&limit=${MAX_RESULTATS}&bbox=${bbox}`);
  if (!res.ok) throw new Error(`SIGPAC: HTTP ${res.status}`);
  const { features } = (await res.json()) as {
    features: { geometry: Polygon; properties: PropietatsRecinte }[];
  };
  const trobat = features.find((f) => f.geometry.type === 'Polygon' && dinsPoligon([lng, lat], f.geometry));
  if (!trobat) return null;
  return { ref: referencia(trobat.properties), dnPk: trobat.properties.dn_pk, geometria: trobat.geometry };
}
