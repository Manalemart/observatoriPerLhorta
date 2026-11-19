import { useEffect, useMemo, useRef, useState } from 'react';
import {
  GeoJSONSource, Map as MapaGL, NavigationControl, ScaleControl, setWorkerUrl,
  type ExpressionSpecification, type FilterSpecification, type LayerSpecification, type Point,
} from 'maplibre-gl';
import 'maplibre-gl/dist/maplibre-gl.css';
import type { Feature, FeatureCollection, Point as PuntGeo } from 'geojson';
import { agruparPunts, MIDA_ICONA, ZOOM_ICONES, ZOOM_SENSE_AGRUPAR } from './agrupacio';
import { CAPES_ELEMENTS, estilBase, FONS, LIMITS_AMBIT } from './estil';
import { ambSimbols, indexSimbologia, servirImatges } from './simbologia';
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

// Capes dels elements i el seu filtre propi (a banda del de variables i època)
const PUNT = ['==', ['geometry-type'], 'Point'];
const LINIA = ['==', ['geometry-type'], 'LineString'];
const POLIGON = ['==', ['geometry-type'], 'Polygon'];
const ambPatro = (...patrons: string[]) => ['all', LINIA, ['in', ['get', 's_patro'], ['literal', patrons]]];
const BASE_CAPES: Record<string, unknown> = {
  'elements-poligons': POLIGON,
  'elements-poligons-trama': ['all', POLIGON, ['has', 's_trama']],
  'elements-poligons-revisar': ['all', POLIGON, PER_REVISAR],
  'elements-linies': ambPatro('continua'),
  'elements-linies-discontinua': ambPatro('discontinua'),
  'elements-linies-puntejada': ambPatro('puntejada'),
  'elements-linies-punt-ratlla': ambPatro('punt_ratlla'),
  'elements-linies-doble': ambPatro('doble'),
  'elements-linies-trama': ambPatro('trama'),
  'elements-linies-fletxes': ['all', LINIA, ['==', ['get', 's_glif'], 'fletxa']],
  'elements-punts': PUNT,
};

// A partir de ZOOM_ICONES els punts es dibuixen amb la icona de la guia (abans, un cercle del
// color) i des de la font «punts»: els de la mateixa categoria que es trepitgen, agrupats
// (agrupacio.ts). Els filtres de variables i època s'apliquen abans d'agrupar.
const GRUP: ExpressionSpecification = ['has', 'n'];
const MIDA = ['interpolate', ['linear'], ['zoom'], ...MIDA_ICONA.flat()] as unknown as ExpressionSpecification;

function afegirCapes(mapa: MapaGL, dades: Dades, elements: FeatureCollection) {
  servirImatges(mapa);
  mapa.addSource('municipis', { type: 'geojson', data: dades.municipis });
  mapa.addSource('partides', { type: 'geojson', data: dades.partides });
  mapa.addSource('elements', {
    type: 'geojson',
    data: elements,
    attribution: "Observatori Ciutadà de l'Horta · Per l'Horta · Font parcel·les 2018: D. G. del Cadastre",
  });
  mapa.addSource('punts', { type: 'geojson', data: BUIT });
  mapa.addSource('esborrany', { type: 'geojson', data: BUIT });
  const filtre = (id: string) => BASE_CAPES[id] as FilterSpecification;
  const COLOR: ExpressionSpecification = ['get', 's_color'];
  const AMPLADA: ExpressionSpecification = ['coalesce', ['get', 's_amplada'], 2];
  // Parcel·les: el color de la guia, una mica transparent per a veure l'ortofoto davall
  const OPACITAT_PARCELA: ExpressionSpecification = ['case', NO_VALIDAT, 0.3, PER_REVISAR, 0.5, 0.75];

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
    id: 'elements-poligons', type: 'fill', source: 'elements', filter: filtre('elements-poligons'),
    paint: {
      'fill-color': COLOR,
      'fill-opacity': OPACITAT_PARCELA,
      'fill-outline-color': ['case', NO_VALIDAT, '#0b0b0b', ['get', 's_contorn']],
    },
  });
  mapa.addLayer({
    id: 'elements-poligons-trama', type: 'fill', source: 'elements', filter: filtre('elements-poligons-trama'),
    paint: { 'fill-pattern': ['get', 's_trama'], 'fill-opacity': OPACITAT_PARCELA },
  });
  mapa.addLayer({
    id: 'elements-poligons-revisar', type: 'line', source: 'elements', minzoom: 13, filter: filtre('elements-poligons-revisar'),
    paint: { 'line-color': ['get', 's_contorn'], 'line-width': 1.5, 'line-dasharray': [3, 2] },
  });
  // Línies: una capa per patró (el traç discontinu no pot dependre de cada element)
  const linia = (id: string, paint: Record<string, unknown>, layout: Record<string, unknown> = {}) =>
    mapa.addLayer({
      id, type: 'line', source: 'elements', filter: filtre(id),
      layout: { 'line-join': 'round', ...layout },
      paint: { 'line-color': COLOR, 'line-width': AMPLADA, ...paint },
    } as LayerSpecification);
  linia('elements-linies', {});
  linia('elements-linies-discontinua', { 'line-dasharray': [3, 2] });
  linia('elements-linies-puntejada', { 'line-dasharray': [0.1, 2] }, { 'line-cap': 'round' });
  linia('elements-linies-punt-ratlla', { 'line-dasharray': [4, 1.5, 0.1, 1.5] }, { 'line-cap': 'round' });
  // Camí: dos traços paral·lels
  linia('elements-linies-doble', { 'line-width': 1.2, 'line-gap-width': 2.5 });
  // Tancaments i tanca vegetal: el tram dibuixat (quadrats, travessers, ziga-zaga...) repetit
  mapa.addLayer({
    id: 'elements-linies-trama', type: 'line', source: 'elements', filter: filtre('elements-linies-trama'),
    layout: { 'line-join': 'round' },
    paint: { 'line-pattern': ['get', 's_imatge'], 'line-width': 8 },
  });
  // Sèquies: fletxes en el sentit de l'aigua (el del traç)
  mapa.addLayer({
    id: 'elements-linies-fletxes', type: 'symbol', source: 'elements', minzoom: 15, filter: filtre('elements-linies-fletxes'),
    layout: {
      'symbol-placement': 'line', 'symbol-spacing': 70,
      'icon-image': ['get', 's_imatge'], 'icon-rotation-alignment': 'map',
      'icon-allow-overlap': true, 'icon-ignore-placement': true,
    },
  });
  // Partidas por encima de las parcelas del inventario (que las tapaban) y con un borde
  // blanco debajo: el topográfico ya tiene tramas verdes y en la ortofoto no se veían.
  mapa.addLayer({
    id: 'partides-vora', type: 'line', source: 'partides', minzoom: 10,
    layout: { 'line-join': 'round' },
    paint: { 'line-color': '#ffffff', 'line-opacity': 0.9, 'line-width': ['interpolate', ['linear'], ['zoom'], 10, 2.5, 15, 5] },
  });
  mapa.addLayer({
    id: 'partides-linies', type: 'line', source: 'partides', minzoom: 10,
    layout: { 'line-join': 'round' },
    paint: { 'line-color': '#215c00', 'line-width': ['interpolate', ['linear'], ['zoom'], 10, 1.2, 15, 2.5] },
  });
  // Punts a zoom baix: cercle del color de la família. Lo de 2018 sense revisar, buit;
  // lo no validat (només ho veu qui té permís), amb contorn negre.
  mapa.addLayer({
    id: 'elements-punts', type: 'circle', source: 'elements', maxzoom: ZOOM_ICONES, filter: filtre('elements-punts'),
    paint: {
      'circle-color': ['case', PER_REVISAR, '#ffffff', COLOR],
      'circle-radius': ['interpolate', ['linear'], ['zoom'], 10, 3, ZOOM_ICONES, 6],
      'circle-stroke-color': ['case', NO_VALIDAT, '#0b0b0b', PER_REVISAR, COLOR, '#ffffff'],
      'circle-stroke-width': 1.5,
    },
  });
  // A prop: la icona de la guia. Lo de 2018 sense revisar, més pàl·lid; lo no validat, amb un anell negre
  mapa.addLayer({
    id: 'elements-punts-no-validats', type: 'circle', source: 'punts', minzoom: ZOOM_ICONES,
    filter: ['all', ['!', GRUP], NO_VALIDAT],
    paint: {
      'circle-radius': ['interpolate', ['linear'], ['zoom'], ZOOM_ICONES, 15, 19, 24],
      'circle-color': 'rgba(255,255,255,0.6)', 'circle-stroke-color': '#0b0b0b', 'circle-stroke-width': 2,
    },
  });
  // Grup: cercle blanc amb la vora del color de la família (negra si hi ha res sense validar)
  mapa.addLayer({
    id: 'punts-grups', type: 'circle', source: 'punts', minzoom: ZOOM_ICONES, filter: GRUP,
    paint: {
      'circle-radius': ['interpolate', ['linear'], ['zoom'], ZOOM_ICONES, 19, 17, 26, 19, 32],
      'circle-color': 'rgba(255,255,255,0.85)',
      'circle-stroke-color': ['case', ['==', ['get', 'no_validat'], true], '#0b0b0b', COLOR],
      'circle-stroke-width': 2,
    },
  });
  mapa.addLayer({
    id: 'elements-icones', type: 'symbol', source: 'punts', minzoom: ZOOM_ICONES,
    layout: {
      'icon-image': ['get', 's_icona'],
      'icon-size': MIDA,
      'icon-allow-overlap': true, 'icon-ignore-placement': true,
    },
    paint: { 'icon-opacity': ['case', PER_REVISAR, 0.6, 1] },
  });
  // El nombre d'elements, en una pastilla a dalt a la dreta del cercle
  mapa.addLayer({
    id: 'punts-grups-nombre', type: 'symbol', source: 'punts', minzoom: ZOOM_ICONES, filter: GRUP,
    layout: {
      'icon-image': ['concat', 'nombre-', ['downcase', ['slice', COLOR, 1]], '-', ['to-string', ['get', 'n']]],
      'icon-offset': ['interpolate', ['linear'], ['zoom'],
        ZOOM_ICONES, ['literal', [15, -15]], 17, ['literal', [21, -21]], 19, ['literal', [26, -26]]],
      'icon-allow-overlap': true, 'icon-ignore-placement': true,
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
      'circle-radius': ['interpolate', ['linear'], ['zoom'], ZOOM_ICONES - 1, 10, ZOOM_ICONES, 17, 19, 26],
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
  // Cada element amb el seu símbol de la guia (icona, estil de línia o de parcel·la)
  const index = useMemo(() => indexSimbologia(dades.temes), [dades.temes]);
  const simbolitzats = useMemo(() => ambSimbols(elements, index), [elements, index]);

  // Punts que es veuen (variables actives i època), abans d'agrupar-los segons el zoom
  const puntsVisibles = useMemo(
    () => simbolitzats.features.filter((f): f is Feature<PuntGeo> => {
      if (f.geometry?.type !== 'Point') return false;
      const p = f.properties ?? {};
      if (!variablesActives.has(p.variable_id as number)) return false;
      return epoca === 'tot' || (epoca === '2018') === (p.per_revisar === true);
    }),
    [simbolitzats, variablesActives, epoca],
  );

  const ultim = useRef({ onSeleccionar, capturant, ignorarClics, onClicCaptura, elements: simbolitzats, puntsVisibles });
  ultim.current = { onSeleccionar, capturant, ignorarClics, onClicCaptura, elements: simbolitzats, puntsVisibles };
  // Zoom (a mitjos nivells) al qual s'han agrupat els punts que hi ha ara en la font
  const zoomAgrupat = useRef<number | null>(null);

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
    // En canviar de mig nivell de zoom, es tornen a agrupar els punts
    mapa.on('zoom', () => {
      const z = Math.floor(mapa.getZoom() * 2) / 2;
      if (zoomAgrupat.current === null || z === zoomAgrupat.current) return;
      zoomAgrupat.current = z;
      mapa.getSource<GeoJSONSource>('punts')?.setData(agruparPunts(ultim.current.puntsVisibles, z));
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
      const tocats = elementsAlPunt(e.point);
      // Un grup de punts: s'acosta fins que se separen
      const grup = tocats.find((f) => f.properties?.n);
      if (grup) {
        const [o, s, est, n] = JSON.parse(grup.properties.limits as string) as number[];
        const desti = mapa.cameraForBounds([[o, s], [est, n]], { padding: 80, maxZoom: ZOOM_SENSE_AGRUPAR });
        const zoom = Math.max(desti?.zoom ?? 0, Math.min(mapa.getZoom() + 2, ZOOM_SENSE_AGRUPAR));
        mapa.easeTo({ center: desti?.center ?? e.lngLat, zoom });
        return;
      }
      // Sin repetir: queryRenderedFeatures puede devolver un elemento por cada tesela que cruza
      const ids = tocats.map((f) => f.properties?.id as string);
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
    mapaRef.current?.getSource<GeoJSONSource>('elements')?.setData(simbolitzats);
  }, [simbolitzats, llest]);

  useEffect(() => {
    const mapa = mapaRef.current;
    if (!mapa || !llest) return;
    const z = Math.floor(mapa.getZoom() * 2) / 2;
    zoomAgrupat.current = z;
    mapa.getSource<GeoJSONSource>('punts')?.setData(agruparPunts(puntsVisibles, z));
  }, [puntsVisibles, llest]);

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
    visibilitat(mapa, 'partides-vora', veurePartides);
    visibilitat(mapa, 'partides-linies', veurePartides);
    visibilitat(mapa, 'municipis-linies', veureMunicipis);
    visibilitat(mapa, 'sigpac-linies', veureSigpac);
  }, [veurePartides, veureMunicipis, veureSigpac, llest]);

  useEffect(() => {
    const mapa = mapaRef.current;
    if (!mapa || !llest) return;
    const actives = ['in', ['get', 'variable_id'], ['literal', [...variablesActives]]];
    for (const [capa, base] of Object.entries(BASE_CAPES)) {
      mapa.setFilter(capa, ['all', base, actives, FILTRE_EPOCA[epoca]] as unknown as FilterSpecification);
    }
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
