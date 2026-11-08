import { useEffect, useRef, useState } from 'react';
import { Map as MapaGL, NavigationControl, ScaleControl, type FilterSpecification, type Point } from 'maplibre-gl';
import { setWorkerUrl } from 'maplibre-gl';
import 'maplibre-gl/dist/maplibre-gl.css';
import { CAPES_ELEMENTS, colorPerTema, estilBase, FONS, LIMITS_AMBIT } from './estil';
import type { Dades, Fons } from './tipus';

interface Props {
  dades: Dades;
  fons: Fons;
  variablesActives: Set<number>;
  veurePartides: boolean;
  veureMunicipis: boolean;
  veureSigpac: boolean;
  seleccionat: string | null;
  onSeleccionar: (id: string | null) => void;
}

// Worker servido tal cual desde public/ (lo copian predev y prebuild): Vite le inyecta su
// cliente HMR si lo importa, y maplibre 6 no lo encuentra por sí solo una vez empaquetado
setWorkerUrl('/maplibre-gl-worker.mjs');

const MARGE_CLIC_PX = 5;
// map.remove() borra el hash de la URL: sin esto, el doble montaje de StrictMode pierde la vista
const HASH_INICIAL = window.location.hash;

function visibilitat(mapa: MapaGL, capa: string, visible: boolean) {
  mapa.setLayoutProperty(capa, 'visibility', visible ? 'visible' : 'none');
}

function afegirCapes(mapa: MapaGL, dades: Dades) {
  const color = colorPerTema(dades.temes);
  mapa.addSource('municipis', { type: 'geojson', data: dades.municipis });
  mapa.addSource('partides', { type: 'geojson', data: dades.partides });
  mapa.addSource('elements', {
    type: 'geojson',
    data: dades.elements,
    attribution: "Observatori Ciutadà de l'Horta · Per l'Horta · Font parcel·les 2018: D. G. del Cadastre",
  });

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
    paint: { 'line-color': '#5f8f1f', 'line-width': 1.25, 'line-opacity': 0.85 },
  });
  mapa.addLayer({
    id: 'elements-poligons', type: 'fill', source: 'elements',
    filter: ['==', ['geometry-type'], 'Polygon'],
    paint: { 'fill-color': color, 'fill-opacity': 0.4, 'fill-outline-color': color },
  });
  mapa.addLayer({
    id: 'elements-linies', type: 'line', source: 'elements',
    filter: ['==', ['geometry-type'], 'LineString'],
    paint: { 'line-color': color, 'line-width': 3 },
  });
  mapa.addLayer({
    id: 'elements-punts', type: 'circle', source: 'elements',
    filter: ['==', ['geometry-type'], 'Point'],
    paint: {
      'circle-color': color,
      'circle-radius': ['interpolate', ['linear'], ['zoom'], 10, 3, 15, 7],
      'circle-stroke-color': '#ffffff',
      'circle-stroke-width': 1.5,
    },
  });
  // Resalte del elemento seleccionado
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
}

export function Mapa({
  dades, fons, variablesActives, veurePartides, veureMunicipis, veureSigpac, seleccionat, onSeleccionar,
}: Props) {
  const contenidor = useRef<HTMLDivElement>(null);
  const mapaRef = useRef<MapaGL | null>(null);
  const [llest, setLlest] = useState(false);
  const onSeleccionarRef = useRef(onSeleccionar);
  onSeleccionarRef.current = onSeleccionar;

  useEffect(() => {
    if (!contenidor.current) return;
    if (HASH_INICIAL && !window.location.hash) window.history.replaceState(null, '', HASH_INICIAL);
    const mapa = new MapaGL({
      container: contenidor.current,
      style: estilBase(),
      bounds: window.location.hash ? undefined : LIMITS_AMBIT, // bounds tendría prioridad sobre el hash
      attributionControl: { compact: true },
      hash: true,                       // la vista queda en la URL y se puede compartir
    });
    mapaRef.current = mapa;
    mapa.addControl(new NavigationControl({ showCompass: false }), 'top-right');
    mapa.addControl(new ScaleControl({ unit: 'metric' }), 'bottom-left');

    mapa.on('load', () => {
      afegirCapes(mapa, dades);
      setLlest(true);
    });

    const capesAlPunt = (p: Point) =>
      mapa.queryRenderedFeatures(
        [[p.x - MARGE_CLIC_PX, p.y - MARGE_CLIC_PX], [p.x + MARGE_CLIC_PX, p.y + MARGE_CLIC_PX]],
        { layers: CAPES_ELEMENTS },
      );
    mapa.on('click', (e) => {
      if (!mapa.getLayer(CAPES_ELEMENTS[0])) return;
      const f = capesAlPunt(e.point)[0];     // queryRenderedFeatures: primero lo de más arriba
      onSeleccionarRef.current((f?.properties?.id as string | undefined) ?? null);
    });
    mapa.on('mousemove', (e) => {
      if (!mapa.getLayer(CAPES_ELEMENTS[0])) return;
      mapa.getCanvas().style.cursor = capesAlPunt(e.point).length ? 'pointer' : '';
    });

    return () => {
      mapaRef.current = null;
      setLlest(false);
      mapa.remove();
    };
  }, [dades]);

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
    const perTipus = (tipus: string) => ['all', ['==', ['geometry-type'], tipus], actives] as unknown as FilterSpecification;
    mapa.setFilter('elements-punts', perTipus('Point'));
    mapa.setFilter('elements-linies', perTipus('LineString'));
    mapa.setFilter('elements-poligons', perTipus('Polygon'));
  }, [variablesActives, llest]);

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
