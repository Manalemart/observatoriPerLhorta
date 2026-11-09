import { useEffect, useRef, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { Map as MapaGL, NavigationControl, type StyleSpecification } from 'maplibre-gl';
import 'maplibre-gl/dist/maplibre-gl.css';

const ICV = '© Institut Cartogràfic Valencià';
const IGN = 'PNOA © Instituto Geográfico Nacional';

const icv = (codi: string, capa = '01_8bits_01_RGB_05_PNG') =>
  `https://terramapas.icv.gva.es/0202_${codi}_3857/wmts/1.0.0/${capa}/default/GMEPSG3857/{z}/{y}/{x}.png`;

// La de 2025 aún no tiene WMTS en 3857: se pide por WMS
const icvWms = (codi: string, capa: string) =>
  `https://terramapas.icv.gva.es/0202_${codi}?service=WMS&request=GetMap&version=1.3.0&layers=${capa}&styles=` +
  '&crs=EPSG:3857&bbox={bbox-epsg-3857}&width=256&height=256&format=image/jpeg'; // JPEG: 16 KB por tesela frente a 160 KB en PNG

const PNOA_ACTUAL =
  'https://www.ign.es/wmts/pnoa-ma?service=WMTS&request=GetTile&version=1.0.0&layer=OI.OrthoimageCoverage' +
  '&style=default&format=image/jpeg&tilematrixset=GoogleMapsCompatible&tilematrix={z}&tilerow={y}&tilecol={x}';

// Solo las series que cubren l'Horta. El ICV no tiene vuelo sobre València de 1996, 1997
// ni 2002, y los vuelos Interministerial (1973-86) y Nacional (1981-86) del IGN vienen en
// blanco aquí. En orden: el desplegable las muestra así.
const ORTOFOTOS: Record<string, { tiles: string; attribution: string }> = {
  1956: { tiles: icv('1956AMSB0050', '01_8bits_04_PAN_05_PNG'), attribution: `Vol americà 1956 ${ICV}` },
  2000: { tiles: icv('2000VAES0050'), attribution: ICV },
  2004: { tiles: icv('2004PVAL0050'), attribution: ICV },
  2006: { tiles: icv('2006PVAL0050'), attribution: ICV },
  2008: { tiles: icv('2008PVAL0050'), attribution: ICV },
  2010: { tiles: icv('2010PVAL0035'), attribution: ICV },
  2012: { tiles: icv('2012CVAL0050'), attribution: ICV },
  2015: { tiles: icv('2015CAVA0025'), attribution: ICV },
  2017: { tiles: icv('2017CVAL0025'), attribution: ICV },
  2018: { tiles: icv('2018CVAL0025', 'odcv05_etrs89h30_2018'), attribution: ICV },
  2019: { tiles: icv('2019CVAL0025'), attribution: ICV },
  2020: { tiles: icv('2020CVAL0025'), attribution: ICV },
  2021: { tiles: icv('2021CVAL0025'), attribution: ICV },
  2022: { tiles: icv('2022CVAL0025'), attribution: ICV },
  2023: { tiles: icv('2023CVAL0025'), attribution: ICV },
  2024: { tiles: icv('2024CVAL0025'), attribution: ICV },
  2025: { tiles: icvWms('2025PVAL0015', '2025PVAL0015_RGB'), attribution: ICV },
  actual: { tiles: PNOA_ACTUAL, attribution: IGN },
};
const ANYS = Object.keys(ORTOFOTOS).sort((a, b) => (a === 'actual' ? 1 : b === 'actual' ? -1 : Number(a) - Number(b)));

// Se abre sobre l'Horta Nord, donde aún queda huerta que comparar
const VISTA = { center: [-0.3708, 39.5012] as [number, number], zoom: 14 };

function estil(any: string): StyleSpecification {
  const o = ORTOFOTOS[any];
  return {
    version: 8,
    sources: { orto: { type: 'raster', tiles: [o.tiles], tileSize: 256, maxzoom: 19, attribution: o.attribution } },
    // Fondo opaco: mientras cargan las teselas no se debe ver el otro año a través
    layers: [
      { id: 'fons', type: 'background', paint: { 'background-color': '#d9d6cf' } },
      { id: 'orto', type: 'raster', source: 'orto' },
    ],
  };
}

// Sin repetir la misma fuente: «Vol americà 1956 © ICV» ya incluye «© ICV»
function atribucio(a: string, b: string): string {
  const [x, y] = [ORTOFOTOS[a].attribution, ORTOFOTOS[b].attribution];
  if (x.includes(y)) return x;
  if (y.includes(x)) return y;
  return `${x} · ${y}`;
}

export function Comparador() {
  const { t } = useTranslation();
  const esquerra = useRef<HTMLDivElement>(null);
  const dreta = useRef<HTMLDivElement>(null);
  const mapes = useRef<{ e: MapaGL; d: MapaGL } | null>(null);
  const [anyE, setAnyE] = useState('1956');
  const [anyD, setAnyD] = useState('actual');
  const [tall, setTall] = useState(50);

  useEffect(() => {
    if (!esquerra.current || !dreta.current) return;
    const e = new MapaGL({ container: esquerra.current, style: estil('1956'), ...VISTA, attributionControl: false });
    const d = new MapaGL({ container: dreta.current, style: estil('actual'), ...VISTA, attributionControl: false });
    e.addControl(new NavigationControl({ showCompass: false }), 'top-right');
    // El superior no recibe eventos (ver CSS): se mueve con el que sí los recibe
    const sincronitzar = () => d.jumpTo({ center: e.getCenter(), zoom: e.getZoom(), bearing: e.getBearing(), pitch: e.getPitch() });
    e.on('move', sincronitzar);
    mapes.current = { e, d };
    return () => {
      e.remove();
      d.remove();
      mapes.current = null;
    };
  }, []);

  useEffect(() => { mapes.current?.e.setStyle(estil(anyE)); }, [anyE]);
  useEffect(() => { mapes.current?.d.setStyle(estil(anyD)); }, [anyD]);

  const selector = (etiqueta: string, valor: string, canvi: (a: string) => void, altre: string) => (
    <label className="comparador-any">
      <span>{etiqueta}</span>
      <select value={valor} onChange={(e) => canvi(e.target.value)}>
        {ANYS.map((a) => (
          <option key={a} value={a} disabled={a === altre}>{a === 'actual' ? t('comparador.actual') : a}</option>
        ))}
      </select>
    </label>
  );

  return (
    <main className="comparador">
      <div className="comparador-barra">
        {selector(t('comparador.esquerra'), anyE, setAnyE, anyD)}
        <label className="comparador-tall">
          <span className="visualment-amagat">{t('comparador.tall')}</span>
          <input type="range" min={0} max={100} value={tall} onChange={(e) => setTall(Number(e.target.value))} />
        </label>
        {selector(t('comparador.dreta'), anyD, setAnyD, anyE)}
      </div>
      <div className="comparador-mapes">
        <div ref={esquerra} className="comparador-mapa" />
        <div
          ref={dreta}
          className="comparador-mapa comparador-mapa-dalt"
          style={{ clipPath: `inset(0 0 0 ${tall}%)` }}
        />
        <div className="comparador-linia" style={{ left: `${tall}%` }} aria-hidden="true" />
        {/* Cada mapa solo mostraría su atribución, y el de encima no recibe clics */}
        <p className="comparador-atribucio">
          {atribucio(anyE, anyD)}
        </p>
      </div>
    </main>
  );
}
