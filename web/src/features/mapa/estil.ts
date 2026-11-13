import type { ExpressionSpecification, StyleSpecification } from 'maplibre-gl';
import type { Fons, Tema } from './tipus';

const wmts = (servei: string, capa: string) =>
  `https://www.ign.es/wmts/${servei}?service=WMTS&request=GetTile&version=1.0.0&layer=${capa}` +
  '&style=default&format=image/jpeg&tilematrixset=GoogleMapsCompatible' +
  '&tilematrix={z}&tilerow={y}&tilecol={x}';

/** URL de una tesela concreta del fondo (para dibujar mapas fuera de MapLibre, como en las hojas de campo). */
export const urlTesela = (fons: Fons, z: number, x: number, y: number) =>
  (fons === 'pnoa' ? wmts('pnoa-ma', 'OI.OrthoimageCoverage') : wmts('mapa-raster', 'MTN'))
    .replace('{z}', String(z)).replace('{x}', String(x)).replace('{y}', String(y));

export const ZOOM_MAX_FONS: Record<Fons, number> = { topo: 17, pnoa: 19 };

const IGN ='© <a href="https://www.ign.es" target="_blank" rel="noreferrer">Instituto Geográfico Nacional</a>';

// Sin OpenStreetMap: sus servidores públicos no admiten el tráfico de una web en producción
export const FONS: Fons[] = ['pnoa', 'topo'];
// Por defecto, la ortofoto (decisión 2026-11-13): en la web, en la app y en las hojas de campo
export const FONS_INICIAL: Fons = 'pnoa';

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
