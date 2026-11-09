import type { ExpressionSpecification, StyleSpecification } from 'maplibre-gl';
import type { Fons, Tema } from './tipus';

const wmts = (servei: string, capa: string) =>
  `https://www.ign.es/wmts/${servei}?service=WMTS&request=GetTile&version=1.0.0&layer=${capa}` +
  '&style=default&format=image/jpeg&tilematrixset=GoogleMapsCompatible' +
  '&tilematrix={z}&tilerow={y}&tilecol={x}';

const IGN = '© <a href="https://www.ign.es" target="_blank" rel="noreferrer">Instituto Geográfico Nacional</a>';

// Sin OpenStreetMap: sus servidores públicos no admiten el tráfico de una web en producción
export const FONS: Fons[] = ['topo', 'pnoa'];
export const FONS_INICIAL: Fons = 'topo';

// Vista inicial: los 37 municipios del ámbito
export const LIMITS_AMBIT: [[number, number], [number, number]] = [[-0.56, 39.33], [-0.25, 39.63]];

export const CAPES_ELEMENTS = ['elements-punts', 'elements-linies', 'elements-poligons'];

export function estilBase(): StyleSpecification {
  return {
    version: 8,
    sources: {
      topo: { type: 'raster', tiles: [wmts('mapa-raster', 'MTN')], tileSize: 256, maxzoom: 17, attribution: IGN },
      pnoa: { type: 'raster', tiles: [wmts('pnoa-ma', 'OI.OrthoimageCoverage')], tileSize: 256, maxzoom: 19, attribution: `PNOA ${IGN}` },
      sigpac: {
        type: 'vector',
        tiles: ['https://sigpac-hubcloud.es/mvt/recinto@3857@pbf/{z}/{x}/{y}.pbf'],
        minzoom: 13,
        maxzoom: 15,
        attribution: 'SIGPAC © FEGA',
      },
    },
    layers: FONS.map((id) => ({
      id: `fons-${id}`,
      type: 'raster',
      source: id,
      layout: { visibility: id === FONS_INICIAL ? 'visible' : 'none' },
    })),
  };
}

export function colorPerTema(temes: Tema[]): ExpressionSpecification {
  const parelles = temes.flatMap((t) => [t.id, t.color]);
  return ['match', ['get', 'tema_id'], ...parelles, '#888888'] as unknown as ExpressionSpecification;
}
