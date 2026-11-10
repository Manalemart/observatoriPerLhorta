import { useEffect, useMemo, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { Link } from 'react-router-dom';
import { useAuth } from '../../auth/AuthContext';
import { supabase } from '../../lib/supabase';
import './portada.css';

interface ResumRevisio {
  elements_2018: number;
  per_revisar: number;
  revisats: number;
  noves: number;
  partides: number;
  partides_amb_revisio: number;
  partides_apadrinades: number;
  ultima_activitat: string | null;
}

// Mismas fechas que el comparador
const ANYS = [1956, 2000, 2004, 2006, 2008, 2010, 2012, 2015, 2017, 2018, 2019, 2020, 2021, 2022, 2023, 2024, 2025];

// Ilustración de «Abans i ara»: 6×4 parcelas en un paisaje de 600×260. La mitad izquierda
// es la foto antigua y la derecha, la de hoy. Cada parcela lleva el año en que se urbanizó
// (0 = sigue siendo huerta).
const URBA = [
  [0, 2006, 1975, 1990, 0, 1962],
  [0, 0, 2000, 1985, 2010, 1966],
  [2018, 0, 1980, 0, 1970, 1958],
  [0, 2012, 0, 2004, 0, 1978],
];
const CULTIU = ['#8fae5a', '#a8bf6a', '#7d9e4c', '#b5c77a'];
const URBA_COLOR = '#b6aea1';
const PARCELES = URBA.flatMap((fila, r) => fila.map((u, c) => ({
  x: 8 + c * 99, y: 8 + r * 63, w: 91, h: 55, u, k: (r * 7 + c * 3) % 4, clau: `${r}-${c}`,
})));
const urbanitzades = (any: number) => PARCELES.filter((p) => p.u && p.u <= any).length;

function Parceles({ any, dreta }: { any: number; dreta: boolean }) {
  return (
    <>
      <rect x={dreta ? 300 : 0} width="300" height="260" fill="#e9e4d4" />
      {PARCELES.filter((p) => (dreta ? p.x + p.w > 300 : p.x < 300)).map((p) => (
        <rect key={p.clau} x={p.x} y={p.y} width={p.w} height={p.h} rx="3" fill={p.u && p.u <= any ? URBA_COLOR : CULTIU[p.k]} />
      ))}
    </>
  );
}

function AbansAra() {
  const { t } = useTranslation();
  const [any, setAny] = useState(1956);
  const perdudes = urbanitzades(2025) - urbanitzades(any);
  return (
    <div className="abans-ara">
      <div className="abans-ara-vista">
        <figure>
          <svg role="img" aria-label={t('portada.abansAra.abansEtiqueta', { any })} viewBox="0 0 300 260">
            <Parceles any={any} dreta={false} />
          </svg>
          <figcaption className="etiqueta-esq">{any}</figcaption>
        </figure>
        <div className="abans-ara-tall" aria-hidden="true">
          <span>
            <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round"><path d="m9 6-6 6 6 6" /><path d="m15 6 6 6-6 6" /></svg>
          </span>
        </div>
        <figure>
          <svg role="img" aria-label={t('portada.abansAra.araEtiqueta')} viewBox="300 0 300 260">
            <Parceles any={2025} dreta />
          </svg>
          <figcaption className="etiqueta-dre">{t('portada.abansAra.hui')}</figcaption>
        </figure>
      </div>
      <div className="abans-ara-control">
        <div className="abans-ara-resum">
          <span>{t('portada.abansAra.tria')}</span>
          <strong aria-live="polite">
            {perdudes > 0 ? t('portada.abansAra.perdudes', { any, n: perdudes }) : t('portada.abansAra.senseCanvis', { any })}
          </strong>
        </div>
        <div role="group" aria-label={t('portada.abansAra.anys')} className="anys">
          {ANYS.map((a) => (
            <button key={a} type="button" aria-pressed={a === any} onClick={() => setAny(a)}>{a}</button>
          ))}
        </div>
      </div>
    </div>
  );
}

function Revisio({ onEntrar }: { onEntrar: () => void }) {
  const { t, i18n } = useTranslation();
  const { uid } = useAuth();
  const [resum, setResum] = useState<ResumRevisio | null>(null);
  const fmt = useMemo(() => new Intl.NumberFormat(i18n.language), [i18n.language]);

  useEffect(() => {
    supabase.rpc('resum_revisio').then(({ data }) => { if (data) setResum(data as ResumRevisio); });
  }, []);

  const n = (v: number | undefined) => (v === undefined ? '…' : fmt.format(v));
  const pct = resum && resum.partides ? Math.round((resum.partides_amb_revisio / resum.partides) * 100) : 0;
  const ultima = resum?.ultima_activitat
    ? new Date(resum.ultima_activitat).toLocaleDateString(i18n.language, { day: 'numeric', month: 'long', year: 'numeric' })
    : t('portada.revisio.mai');

  return (
    <section className="banda-revisio" aria-labelledby="revisio-titol">
      <div className="contenidor banda-revisio-graella">
        <div className="banda-revisio-text">
          <p className="etiqueta-lima">{t('portada.revisio.etiqueta')}</p>
          <h2 id="revisio-titol">{t('portada.revisio.titol')}</h2>
          <p className="serif">{t('portada.revisio.text', { n: n(resum?.elements_2018 ?? 7104) })}</p>
          <div className="botons">
            {uid
              ? <Link to="/mapa" className="boto lima gran">{t('portada.revisio.revisa')}</Link>
              : <button type="button" className="boto lima gran" onClick={onEntrar}>{t('portada.revisio.revisa')}</button>}
            <Link to="/dades" className="enllac-clar">{t('portada.revisio.consulta')}</Link>
          </div>
        </div>
        <div className="banda-revisio-xifres">
          <p className="xifra-etiqueta">{t('portada.revisio.progres')}</p>
          <p className="xifra-gran">
            {n(resum?.partides_amb_revisio)} <span>{t('portada.revisio.de', { n: n(resum?.partides ?? 412) })}</span>
          </p>
          <div
            className="progres"
            role="progressbar"
            aria-label={t('portada.revisio.progres')}
            aria-valuemin={0}
            aria-valuemax={resum?.partides ?? 412}
            aria-valuenow={resum?.partides_amb_revisio ?? 0}
            aria-valuetext={t('portada.revisio.progresEtiqueta', { fet: n(resum?.partides_amb_revisio), total: n(resum?.partides) })}
          >
            <span style={{ width: `${Math.max(pct, resum?.partides_amb_revisio ? 1 : 0)}%` }} />
          </div>
          <dl>
            <div><dt>{t('portada.revisio.revisats')}</dt><dd>{n(resum?.revisats)}</dd></div>
            <div><dt>{t('portada.revisio.noves')}</dt><dd>{n(resum?.noves)}</dd></div>
            <div><dt>{t('portada.revisio.apadrinades')}</dt><dd>{n(resum?.partides_apadrinades)}</dd></div>
            <div><dt>{t('portada.revisio.ultima')}</dt><dd>{resum ? ultima : '…'}</dd></div>
          </dl>
          <p className="xifra-nota">{t('portada.revisio.directe')}</p>
        </div>
      </div>
    </section>
  );
}

const Icona = ({ d }: { d: string[] }) => (
  <span className="icona-pas" aria-hidden="true">
    <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      {d.map((p) => <path key={p} d={p} />)}
    </svg>
  </span>
);

export function Portada({ onEntrar }: { onEntrar: () => void }) {
  const { t } = useTranslation();
  const { uid } = useAuth();

  return (
    <main className="portada">
      <section className="contenidor heroi">
        <div className="heroi-text">
          <p className="etiqueta-verda">{t('portada.subtitol')}</p>
          <h1>{t('portada.titol')}</h1>
          <p className="serif gran"><strong>L’observatori ciutadà de l’horta</strong> {t('portada.intro')}</p>
          <div className="botons">
            <Link to="/mapa" className="boto primari gran">{t('portada.explora')}</Link>
            {uid
              ? <Link to="/mapa?aportar=1" className="boto lima gran">{t('portada.aporta')}</Link>
              : <button type="button" className="boto lima gran" onClick={onEntrar}>{t('portada.aporta')}</button>}
          </div>
        </div>
        <div className="heroi-imatge">
          <div className="trama heroi-trama" aria-hidden="true" />
          <Link to="/mapa" className="heroi-mapa" aria-label={t('portada.explora')}>
            <svg role="img" aria-label={t('portada.previsio')} viewBox="0 0 560 380">
              <rect width="560" height="380" fill="#eef0e2" />
              <path d="M380 0 C400 90 360 160 420 230 S520 330 560 340 V0Z" fill="#d6dde8" />
              <g fill="none" stroke="#574F46" strokeOpacity="0.35" strokeWidth="1.5">
                <path d="M40 40 L180 30 L210 120 L90 150 Z" /><path d="M180 30 L330 50 L320 140 L210 120 Z" />
                <path d="M90 150 L210 120 L230 230 L70 240 Z" /><path d="M210 120 L320 140 L340 240 L230 230 Z" />
                <path d="M320 140 L400 120 L420 230 L340 240 Z" /><path d="M70 240 L230 230 L240 340 L60 350 Z" />
                <path d="M230 230 L340 240 L350 345 L240 340 Z" />
              </g>
              <path d="M210 120 L320 140 L340 240 L230 230 Z" fill="#9ED100" fillOpacity="0.35" stroke="#2c7a00" strokeWidth="3" />
              <g fill="#ffffff" strokeWidth="3.5">
                <circle cx="120" cy="90" r="7" stroke="#c9302c" /><circle cx="250" cy="170" r="7" stroke="#1f5fb0" />
                <circle cx="160" cy="200" r="7" stroke="#eda100" /><circle cx="265" cy="80" r="7" stroke="#1baf7a" />
              </g>
              <g stroke="#ffffff" strokeWidth="2">
                <circle cx="290" cy="200" r="8" fill="#1baf7a" /><circle cx="360" cy="190" r="8" fill="#1f5fb0" />
                <circle cx="300" cy="300" r="8" fill="#c9302c" />
              </g>
            </svg>
          </Link>
        </div>
      </section>

      <Revisio onEntrar={onEntrar} />

      <section className="contenidor seccio" aria-labelledby="funciona-titol">
        <h2 id="funciona-titol" className="titol-seccio">{t('portada.funciona.titol')}</h2>
        <p className="serif gran intro-seccio">{t('portada.funciona.intro')}</p>
        <div className="passos">
          <article>
            <Icona d={['M11 18a7 7 0 1 0 0-14 7 7 0 0 0 0 14Z', 'm20 20-3.5-3.5']} />
            <h3>{t('portada.funciona.observa')}</h3>
            <p className="serif">{t('portada.funciona.observaText')}</p>
          </article>
          <article>
            <Icona d={['M20 6 9 17l-5-5']} />
            <h3>{t('portada.funciona.valida')}</h3>
            <p className="serif">{t('portada.funciona.validaText')}</p>
          </article>
          <article>
            <Icona d={['M12 3v12', 'm7 10 5 5 5-5', 'M5 21h14']} />
            <h3>{t('portada.funciona.comparteix')}</h3>
            <p className="serif">{t('portada.funciona.comparteixText')}</p>
          </article>
        </div>
      </section>

      <section className="contenidor seccio seccio-abans" aria-labelledby="abans-titol">
        <div className="seccio-abans-text">
          <h2 id="abans-titol" className="titol-seccio">{t('portada.abansAra.titol')}</h2>
          <p className="serif gran">{t('portada.abansAra.text')}</p>
          <Link to="/comparador" className="enllac-fort">{t('portada.abansAra.obri')} →</Link>
        </div>
        <div className="seccio-abans-vista">
          <AbansAra />
          <p className="nota-il">{t('portada.abansAra.nota')}</p>
        </div>
      </section>

      <section className="contenidor seccio" aria-labelledby="apadrina-titol">
        <div className="apadrina">
          <div className="apadrina-text">
            <h2 id="apadrina-titol" className="titol-seccio">{t('portada.apadrina.titol')}</h2>
            <p className="serif gran">{t('portada.apadrina.text')}</p>
            {uid
              ? <p className="serif">{t('portada.apadrina.jaDins')}</p>
              : <div className="botons"><button type="button" className="boto primari gran" onClick={onEntrar}>{t('portada.apadrina.boto')}</button></div>}
          </div>
          <div className="trama apadrina-trama" aria-hidden="true" />
        </div>
      </section>

      <footer className="peu-portada">
        <div className="trama-tira" aria-hidden="true" />
        <div className="contenidor peu-portada-graella">
          <div>
            <img src="/logo.png" alt={t('app.titol')} className="logo" />
            <p>{t('portada.peu.iniciativa')} <strong>Per l’Horta</strong> · {t('portada.peu.tecnic')}</p>
          </div>
          <div>
            <p>{t('llicencia.codi')} · {t('llicencia.dades')}</p>
            <p><Link to="/legal">{t('legal.enllac')}</Link> · <Link to="/dades">{t('nav.dades')}</Link></p>
          </div>
        </div>
      </footer>
    </main>
  );
}
