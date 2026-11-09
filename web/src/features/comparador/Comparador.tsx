import { useEffect, useRef, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { Map as MapaGL, NavigationControl, type StyleSpecification } from 'maplibre-gl';
import 'maplibre-gl/dist/maplibre-gl.css';

const ICV = '© Institut Cartogràfic Valencià';

const icv = (codi: string, capa = '01_8bits_01_RGB_05_PNG') =>
  `https://terramapas.icv.gva.es/0202_${codi}_3857/wmts/1.0.0/${capa}/default/GMEPSG3857/{z}/{y}/{x}.png`;

// 2020 solo se ofrece en falso color: no sirve para comparar a simple vista
const ORTOFOTOS: Record<string, { tiles: string; attribution: string }> = {
  1956: { tiles: icv('1956AMSB0050', '01_8bits_04_PAN_05_PNG'), attribution: `Vol americà 1956 ${ICV}` },
  2017: { tiles: icv('2017CVAL0025'), attribution: ICV },
  2018: { tiles: icv('2018CVAL0025', 'odcv05_etrs89h30_2018'), attribution: ICV },
  2019: { tiles: icv('2019CVAL0025'), attribution: ICV },
  2021: { tiles: icv('2021CVAL0025'), attribution: ICV },
  2022: { tiles: icv('2022CVAL0025'), attribution: ICV },
  2023: { tiles: icv('2023CVAL0025'), attribution: ICV },
  2024: { tiles: icv('2024CVAL0025'), attribution: ICV },
};
const ANYS = Object.keys(ORTOFOTOS);

// Se abre sobre l'Horta Nord, donde aún queda huerta que comparar
const VISTA = { center: [-0.3708, 39.5012] as [number, number], zoom: 14 };

function estil(any: string): StyleSpecification {
  const o = ORTOFOTOS[any];
  return {
    version: 8,
    sources: { orto: { type: 'raster', tiles: [o.tiles], tileSize: 256, maxzoom: 19, attribution: o.attribution } },
    layers: [{ id: 'orto', type: 'raster', source: 'orto' }],
  };
}

export function Comparador() {
  const { t } = useTranslation();
  const esquerra = useRef<HTMLDivElement>(null);
  const dreta = useRef<HTMLDivElement>(null);
  const mapes = useRef<{ e: MapaGL; d: MapaGL } | null>(null);
  const [anyE, setAnyE] = useState('1956');
  const [anyD, setAnyD] = useState('2024');
  const [tall, setTall] = useState(50);

  useEffect(() => {
    if (!esquerra.current || !dreta.current) return;
    const e = new MapaGL({ container: esquerra.current, style: estil('1956'), ...VISTA, attributionControl: { compact: true } });
    const d = new MapaGL({ container: dreta.current, style: estil('2024'), ...VISTA, attributionControl: false });
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
        {ANYS.map((a) => <option key={a} value={a} disabled={a === altre}>{a}</option>)}
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
      </div>
    </main>
  );
}
