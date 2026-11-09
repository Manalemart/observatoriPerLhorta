import { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { supabase } from '../../lib/supabase';

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

export function LesMeuesPartides({ onVeurePendents }: { onVeurePendents: (partidaId: number) => void }) {
  const { t, i18n } = useTranslation();
  const [files, setFiles] = useState<ResumPartida[] | null>(null);
  const [error, setError] = useState(false);
  const data = (d: string) => new Date(d).toLocaleDateString(i18n.language);

  useEffect(() => {
    void supabase.rpc('resum_les_meues_partides').then(({ data: d, error: err }) => {
      if (err) setError(true);
      else setFiles(d as ResumPartida[]);
    });
  }, []);

  if (error) return <div className="avis" role="alert"><p>{t('partides.error')}</p></div>;
  if (!files) return <div className="avis" role="status"><p>{t('comu.carregant')}</p></div>;
  if (!files.length) return <div className="avis"><p>{t('partides.buit')}</p></div>;

  return (
    <div className="partides">
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
          <button type="button" className="boto" disabled={!p.pendents} onClick={() => onVeurePendents(p.partida_id)}>
            {t('partides.veurePendents')}
          </button>
        </article>
      ))}
    </div>
  );
}
