import { useEffect, useMemo, useState } from 'react';
import { useTranslation } from 'react-i18next';
import type { FeatureCollection } from 'geojson';
import { useAuth } from '../../auth/AuthContext';
import { supabase } from '../../lib/supabase';
import { BotoFullDeCamp } from '../fulls/BotoFullDeCamp';
import type { Fons } from '../mapa/tipus';

interface ResumPartida {
  partida_id: number;
  partida: string;
  municipi: string;
  des_de: string;
  area_ha: number;
  validats: number;
  pendents: number;
  rebutjats: number;
  per_tema: { nom: string; color: string; n: number }[];
  darrera: string | null;
}

/** Fondo del plano y, para la coordinación, hoja de cualquier partida. */
function FullsDeCamp({ fons, onFons, partides }: { fons: Fons; onFons: (f: Fons) => void; partides: FeatureCollection }) {
  const { t, i18n } = useTranslation();
  const { esCoordinador } = useAuth();
  const [triada, setTriada] = useState<number | null>(null);
  const opcions = useMemo(
    () => partides.features
      .map((f) => ({ id: f.properties?.id as number, nom: f.properties?.nom as string, municipi: f.properties?.municipi as string }))
      .sort((a, b) => a.municipi.localeCompare(b.municipi, i18n.language) || a.nom.localeCompare(b.nom, i18n.language)),
    [partides, i18n.language],
  );
  return (
    <section className="targeta fulls-camp" aria-labelledby="fulls-titol">
      <h2 id="fulls-titol">{t('fulls.titol')}</h2>
      <p className="nota">{t('fulls.nota')}</p>
      <div className="fulls-controls">
        <fieldset className="segmentat segmentat-2">
          <legend className="visualment-amagat">{t('fulls.fons')}</legend>
          {(['pnoa', 'topo'] as Fons[]).map((f) => (
            <button key={f} type="button" aria-pressed={fons === f} onClick={() => onFons(f)}>
              {t(f === 'pnoa' ? 'fulls.fonsPnoa' : 'fulls.fonsTopo')}
            </button>
          ))}
        </fieldset>
        {esCoordinador && (
          <div className="fulls-qualsevol">
            <label className="camp">
              <span>{t('fulls.qualsevol')}</span>
              <select value={triada ?? ''} onChange={(e) => setTriada(e.target.value ? Number(e.target.value) : null)}>
                <option value="">{t('fulls.tria')}</option>
                {opcions.map((o) => <option key={o.id} value={o.id}>{o.municipi} · {o.nom}</option>)}
              </select>
            </label>
            <BotoFullDeCamp partidaId={triada} tipus="camp" fons={fons} primari />
            <BotoFullDeCamp partidaId={triada} tipus="revisio" fons={fons} />
          </div>
        )}
      </div>
    </section>
  );
}

export function LesMeuesPartides({ onVeurePendents, partides }: { onVeurePendents: (partidaId: number) => void; partides: FeatureCollection }) {
  const { t, i18n } = useTranslation();
  const [fons, setFons] = useState<Fons>('pnoa');
  const [files, setFiles] = useState<ResumPartida[] | null>(null);
  const [error, setError] = useState(false);
  const data = (d: string) => new Date(d).toLocaleDateString(i18n.language);

  useEffect(() => {
    void supabase.rpc('resum_les_meues_partides').then(({ data: d, error: err }) => {
      if (err) setError(true);
      else setFiles(d as ResumPartida[]);
    });
  }, []);

  const fulls = <FullsDeCamp fons={fons} onFons={setFons} partides={partides} />;
  if (error) return <div className="partides">{fulls}<div className="avis" role="alert"><p>{t('partides.error')}</p></div></div>;
  if (!files) return <div className="avis" role="status"><p>{t('comu.carregant')}</p></div>;
  if (!files.length) return <div className="partides">{fulls}<div className="avis"><p>{t('partides.buit')}</p></div></div>;

  return (
    <div className="partides">
      {fulls}
      {files.map((p) => (
        <article key={p.partida_id} className="targeta">
          <h2>{p.partida}</h2>
          <p className="nota">
            {p.municipi} · {t('partides.area', { ha: new Intl.NumberFormat(i18n.language).format(p.area_ha) })} · {t('padrinatges.desDe', { data: data(p.des_de) })}
          </p>
          <dl className="xifres">
            <div><dt>{t('partides.validats')}</dt><dd>{p.validats}</dd></div>
            <div><dt>{t('partides.pendents')}</dt><dd>{p.pendents}</dd></div>
            <div><dt>{t('partides.rebutjats')}</dt><dd>{p.rebutjats}</dd></div>
          </dl>
          {p.per_tema.length > 0 && (
            <ul className="temes-partida">
              {p.per_tema.map((x) => (
                <li key={x.nom}>
                  <span className="mostra" style={{ background: x.color }} aria-hidden="true" />
                  {x.nom}: {x.n}
                </li>
              ))}
            </ul>
          )}
          {p.darrera && <p className="nota">{t('partides.darrera', { data: data(p.darrera) })}</p>}
          <div className="accions-partida">
            <BotoFullDeCamp partidaId={p.partida_id} tipus="camp" fons={fons} primari />
            <BotoFullDeCamp partidaId={p.partida_id} tipus="revisio" fons={fons} />
            <button type="button" className="boto" disabled={!p.pendents} onClick={() => onVeurePendents(p.partida_id)}>
              {t('partides.veurePendents')}
            </button>
          </div>
        </article>
      ))}
    </div>
  );
}
