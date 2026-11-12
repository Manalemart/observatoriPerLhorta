import { useEffect, useRef, useState } from 'react';
import {
  GeoJSONSource, Map as MapaGL, NavigationControl, ScaleControl, setWorkerUrl,
  type ExpressionSpecification, type FilterSpecification, type Point,
} from 'maplibre-gl';
import 'maplibre-gl/dist/maplibre-gl.css';
import type { FeatureCollection } from 'geojson';
import { CAPES_ELEMENTS, colorPerTema, estilBase, FONS, LIMITS_AMBIT } from './estil';
import type { Dades, Epoca, Esborrany, Fons } from './tipus';

interface Props {
  dades: Dades;
  elements: FeatureCollection;
  fons: Fons;
  variablesActives: Set<number>;
  epoca: Epoca;
  veurePartides: boolean;
  veureMunicipis: boolean;
  veureSigpac: boolean;
  seleccionat: string | null;
  /** Ids de los elementos bajo el clic: pueden ser varios superpuestos. */
  onSeleccionar: (ids: string[]) => void;
  /** Mientras se aporta, los clics capturan posiciones en lugar de abrir fichas. */
  capturant: boolean;
  /** Aportando, sin variable aún: los clics no hacen nada. */
  ignorarClics: boolean;
  onClicCaptura: (lng: number, lat: number) => void;
  esborrany: Esborrany;
}

// Worker servido tal cual desde public/ (lo copian predev y prebuild): Vite le inyecta su
// cliente HMR si lo importa, y maplibre 6 no lo encuentra por sí solo una vez empaquetado
setWorkerUrl('/maplibre-gl-worker.mjs');

const MARGE_CLIC_PX = 5;
const BUIT: FeatureCollection = { type: 'FeatureCollection', features: [] };
const COLOR_ESBORRANY = '#0b0b0b';
// map.remove() borra el hash de la URL: sin esto, el doble montaje de StrictMode pierde la vista
const HASH_INICIAL = /^#[\d.]+\/-?[\d.]+\/-?[\d.]+/.test(window.location.hash) ? window.location.hash : '';

const NO_VALIDAT: ExpressionSpecification = ['!=', ['get', 'estat'], 'validat'];
// Inventario de 2017-2018 sin confirmar desde entonces: puntos huecos, parcelas con borde discontinuo
const PER_REVISAR: ExpressionSpecification = ['==', ['get', 'per_revisar'], true];
const FILTRE_EPOCA: Record<Epoca, unknown> = {
  tot: true,
  '2018': PER_REVISAR,
  noves: ['!', PER_REVISAR],
};

function visibilitat(mapa: MapaGL, capa: string, visible: boolean) {
  mapa.setLayoutProperty(capa, 'visibility', visible ? 'visible' : 'none');
}

function afegirCapes(mapa: MapaGL, dades: Dades, elements: FeatureCollection) {
  const color = colorPerTema(dades.temes);
  mapa.addSource('municipis', { type: 'geojson', data: dades.municipis });
  mapa.addSource('partides', { type: 'geojson', data: dades.partides });
  mapa.addSource('elements', {
    type: 'geojson',
    data: elements,
    attribution: "Observatori Ciutadà de l'Horta · Per l'Horta · Font parcel·les 2018: D. G. del Cadastre",
  });
  mapa.addSource('esborrany', { type: 'geojson', data: BUIT });

  mapa.addLayer({
    id: 'sigpac-linies', type: 'line', source: 'sigpac', 'source-layer': 'recinto', minzoom: 14,
    layout: { visibility: 'none' },
    paint: { 'line-color': '#ffffff', 'line-width': 1, 'line-opacity': 0.9 },
  });
  mapa.addLayer({
    id: 'municipis-linies', type: 'line', source: 'municipis',
    paint: { 'line-color': '#3d3a33', 'line-width': 1.5, 'line-dasharray': [3, 2] },
  });
  mapa.addLayer({
    id: 'partides-linies', type: 'line', source: 'partides', minzoom: 11,
    paint: { 'line-color': '#2c7a00', 'line-width': 1.25, 'line-opacity': 0.85 },
  });
  mapa.addLayer({
    id: 'elements-poligons', type: 'fill', source: 'elements',
    filter: ['==', ['geometry-type'], 'Polygon'],
    paint: {
      'fill-color': color,
      'fill-opacity': ['case', NO_VALIDAT, 0.2, PER_REVISAR, 0.18, 0.45],
      'fill-outline-color': ['case', NO_VALIDAT, '#0b0b0b', color],
    },
  });
  mapa.addLayer({
    id: 'elements-poligons-revisar', type: 'line', source: 'elements', minzoom: 13,
    filter: ['all', ['==', ['geometry-type'], 'Polygon'], PER_REVISAR] as unknown as FilterSpecification,
    paint: { 'line-color': color, 'line-width': 1.5, 'line-dasharray': [3, 2] },
  });
  mapa.addLayer({
    id: 'elements-linies', type: 'line', source: 'elements',
    filter: ['==', ['geometry-type'], 'LineString'],
    paint: { 'line-color': color, 'line-width': 3 },
  });
  // Lo no validado (solo lo ve quien tiene permiso) lleva contorno negro
  mapa.addLayer({
    id: 'elements-punts', type: 'circle', source: 'elements',
    filter: ['==', ['geometry-type'], 'Point'],
    paint: {
      'circle-color': ['case', PER_REVISAR, '#ffffff', color],
      'circle-radius': ['interpolate', ['linear'], ['zoom'], 10, 3, 15, 7],
      'circle-stroke-color': ['case', NO_VALIDAT, '#0b0b0b', PER_REVISAR, color, '#ffffff'],
      // zoom solo vale en un interpolate de primer nivel: el case va dentro de cada parada
      'circle-stroke-width': ['interpolate', ['linear'], ['zoom'], 10, ['case', PER_REVISAR, 1.5, 1.5], 15, ['case', PER_REVISAR, 3, 1.5]],
    },
  });
  mapa.addLayer({
    id: 'seleccio-poligon', type: 'line', source: 'elements',
    filter: ['==', ['get', 'id'], ''],
    paint: { 'line-color': '#0b0b0b', 'line-width': 3 },
  });
  mapa.addLayer({
    id: 'seleccio-punt', type: 'circle', source: 'elements',
    filter: ['==', ['get', 'id'], ''],
    paint: {
      'circle-radius': 10,
      'circle-color': 'rgba(0,0,0,0)',
      'circle-stroke-color': '#0b0b0b',
      'circle-stroke-width': 3,
    },
  });
  // Lo que se está dibujando
  mapa.addLayer({
    id: 'esborrany-fons', type: 'fill', source: 'esborrany',
    filter: ['==', ['geometry-type'], 'Polygon'],
    paint: { 'fill-color': '#ffffff', 'fill-opacity': 0.35 },
  });
  mapa.addLayer({
    id: 'esborrany-linies', type: 'line', source: 'esborrany',
    paint: { 'line-color': COLOR_ESBORRANY, 'line-width': 3, 'line-dasharray': [2, 1] },
  });
  mapa.addLayer({
    id: 'esborrany-punts', type: 'circle', source: 'esborrany',
    paint: {
      'circle-radius': 6, 'circle-color': '#ffffff',
      'circle-stroke-color': COLOR_ESBORRANY, 'circle-stroke-width': 3,
    },
  });
}

export function Mapa({
  dades, elements, fons, variablesActives, epoca, veurePartides, veureMunicipis, veureSigpac,
  seleccionat, onSeleccionar, capturant, ignorarClics, onClicCaptura, esborrany,
}: Props) {
  const contenidor = useRef<HTMLDivElement>(null);
  const mapaRef = useRef<MapaGL | null>(null);
  const [llest, setLlest] = useState(false);

  // Los manejadores del mapa viven tanto como él: leen siempre el último valor de estos refs
  const ultim = useRef({ onSeleccionar, capturant, ignorarClics, onClicCaptura, elements });
  ultim.current = { onSeleccionar, capturant, ignorarClics, onClicCaptura, elements };

  useEffect(() => {
    if (!contenidor.current) return;
    if (HASH_INICIAL && !window.location.hash) window.history.replaceState(null, '', HASH_INICIAL);
    const mapa = new MapaGL({
      container: contenidor.current,
      style: estilBase(),
      bounds: HASH_INICIAL ? undefined : LIMITS_AMBIT, // bounds tendría prioridad sobre el hash
      attributionControl: { compact: true },
      hash: true,                       // la vista queda en la URL y se puede compartir
    });
    mapaRef.current = mapa;
    // Solo en desarrollo: inspeccionar capas y fuentes desde la consola
    if (import.meta.env.DEV) (window as unknown as { __mapa?: MapaGL }).__mapa = mapa;
    mapa.addControl(new NavigationControl({ showCompass: false }), 'top-right');
    mapa.addControl(new ScaleControl({ unit: 'metric' }), 'bottom-left');

    mapa.on('load', () => {
      afegirCapes(mapa, dades, ultim.current.elements);
      setLlest(true);
    });

    const elementsAlPunt = (p: Point) =>
      mapa.queryRenderedFeatures(
        [[p.x - MARGE_CLIC_PX, p.y - MARGE_CLIC_PX], [p.x + MARGE_CLIC_PX, p.y + MARGE_CLIC_PX]],
        { layers: CAPES_ELEMENTS },
      );
    mapa.on('click', (e) => {
      const { capturant: capturantAra, ignorarClics: ignorar } = ultim.current;
      if (capturantAra) {
        ultim.current.onClicCaptura(e.lngLat.lng, e.lngLat.lat);
        return;
      }
      if (ignorar || !mapa.getLayer(CAPES_ELEMENTS[0])) return;
      // Sin repetir: queryRenderedFeatures puede devolver un elemento por cada tesela que cruza
      const ids = elementsAlPunt(e.point).map((f) => f.properties?.id as string);
      ultim.current.onSeleccionar([...new Set(ids)]);
    });
    mapa.on('mousemove', (e) => {
      if (!mapa.getLayer(CAPES_ELEMENTS[0])) return;
      const { capturant: capturantAra, ignorarClics: ignorar } = ultim.current;
      let cursor = '';
      if (capturantAra) cursor = 'crosshair';
      else if (!ignorar && elementsAlPunt(e.point).length) cursor = 'pointer';
      mapa.getCanvas().style.cursor = cursor;
    });

    return () => {
      mapaRef.current = null;
      setLlest(false);
      mapa.remove();
    };
  }, [dades]);

  useEffect(() => {
    if (!llest) return;
    mapaRef.current?.getSource<GeoJSONSource>('elements')?.setData(elements);
  }, [elements, llest]);

  useEffect(() => {
    if (!llest) return;
    mapaRef.current?.getSource<GeoJSONSource>('esborrany')?.setData(esborrany ?? BUIT);
  }, [esborrany, llest]);

  useEffect(() => {
    const mapa = mapaRef.current;
    if (!mapa || !llest) return;
    FONS.forEach((f) => visibilitat(mapa, `fons-${f}`, f === fons));
  }, [fons, llest]);

  useEffect(() => {
    const mapa = mapaRef.current;
    if (!mapa || !llest) return;
    visibilitat(mapa, 'partides-linies', veurePartides);
    visibilitat(mapa, 'municipis-linies', veureMunicipis);
    visibilitat(mapa, 'sigpac-linies', veureSigpac);
  }, [veurePartides, veureMunicipis, veureSigpac, llest]);

  useEffect(() => {
    const mapa = mapaRef.current;
    if (!mapa || !llest) return;
    const actives = ['in', ['get', 'variable_id'], ['literal', [...variablesActives]]];
    const perTipus = (tipus: string, ...mes: unknown[]) =>
      ['all', ['==', ['geometry-type'], tipus], actives, FILTRE_EPOCA[epoca], ...mes] as unknown as FilterSpecification;
    mapa.setFilter('elements-punts', perTipus('Point'));
    mapa.setFilter('elements-linies', perTipus('LineString'));
    mapa.setFilter('elements-poligons', perTipus('Polygon'));
    mapa.setFilter('elements-poligons-revisar', perTipus('Polygon', PER_REVISAR));
  }, [variablesActives, epoca, llest]);

  useEffect(() => {
    const mapa = mapaRef.current;
    if (!mapa || !llest) return;
    const filtre = (tipus: string[]) => ['all',
      ['==', ['get', 'id'], seleccionat ?? ''],
      ['in', ['geometry-type'], ['literal', tipus]],
    ] as unknown as FilterSpecification;
    mapa.setFilter('seleccio-punt', filtre(['Point']));
    mapa.setFilter('seleccio-poligon', filtre(['Polygon', 'LineString']));
  }, [seleccionat, llest]);

  return <div ref={contenidor} className="mapa" role="application" aria-label="Mapa de l'inventari" />;
}
