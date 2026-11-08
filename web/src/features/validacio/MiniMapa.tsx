import { useEffect, useRef } from 'react';
import { LngLatBounds, Map as MapaGL, NavigationControl } from 'maplibre-gl';
import type { Geometry, Position } from 'geojson';
import { estilBase } from '../mapa/estil';

const ZOOM_MAXIM = 18;

function coordenades(g: Geometry): Position[] {
  switch (g.type) {
    case 'Point': return [g.coordinates];
    case 'LineString':
    case 'MultiPoint': return g.coordinates;
    case 'Polygon':
    case 'MultiLineString': return g.coordinates.flat();
    case 'MultiPolygon': return g.coordinates.flat(2);
    default: return [];
  }
}

/** Situa el elemento sobre la ortofoto para que quien valida lo pueda comprobar. */
export function MiniMapa({ geom }: { geom: Geometry }) {
  const contenidor = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!contenidor.current) return;
    const limits = coordenades(geom).reduce(
      (b, c) => b.extend(c as [number, number]),
      new LngLatBounds(),
    );
    const estil = estilBase();
    estil.layers = estil.layers.map((c) => (c.id === 'fons-pnoa'
      ? { ...c, layout: { visibility: 'visible' as const } }
      : { ...c, layout: { visibility: 'none' as const } }));
    const mapa = new MapaGL({
      container: contenidor.current,
      style: estil,
      bounds: limits,
      fitBoundsOptions: { padding: 60, maxZoom: ZOOM_MAXIM },
      attributionControl: { compact: true },
    });
    mapa.addControl(new NavigationControl({ showCompass: false }), 'top-right');
    mapa.on('load', () => {
      mapa.addSource('element', { type: 'geojson', data: { type: 'Feature', geometry: geom, properties: {} } });
      mapa.addLayer({
        id: 'element-fons', type: 'fill', source: 'element',
        filter: ['==', ['geometry-type'], 'Polygon'],
        paint: { 'fill-color': '#ffffff', 'fill-opacity': 0.25 },
      });
      mapa.addLayer({
        id: 'element-linia', type: 'line', source: 'element',
        filter: ['!=', ['geometry-type'], 'Point'],
        paint: { 'line-color': '#ffdd00', 'line-width': 3 },
      });
      mapa.addLayer({
        id: 'element-punt', type: 'circle', source: 'element',
        filter: ['==', ['geometry-type'], 'Point'],
        paint: { 'circle-radius': 8, 'circle-color': '#ffdd00', 'circle-stroke-color': '#0b0b0b', 'circle-stroke-width': 2 },
      });
    });
    return () => mapa.remove();
  }, [geom]);

  return <div ref={contenidor} className="minimapa" />;
}
