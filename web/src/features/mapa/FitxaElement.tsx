import { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { carregarFitxa, urlFoto } from './dades';
import type { Fitxa } from './tipus';

export function FitxaElement({ id, onTancar }: { id: string; onTancar: () => void }) {
  const { t, i18n } = useTranslation();
  const [fitxa, setFitxa] = useState<Fitxa | null>(null);
  const [error, setError] = useState(false);

  useEffect(() => {
    let vigent = true;
    setFitxa(null);
    setError(false);
    carregarFitxa(id)
      .then((f) => { if (vigent) setFitxa(f); })
      .catch(() => { if (vigent) setError(true); });
    return () => { vigent = false; };
  }, [id]);

  return (
    <aside className="fitxa" aria-live="polite">
      <button type="button" className="tancar" aria-label={t('fitxa.tancar')} onClick={onTancar}>×</button>
      {error && <p role="alert">{t('fitxa.error')}</p>}
      {!error && !fitxa && <p>{t('fitxa.carregant')}</p>}
      {fitxa && (
        <>
          <p className="fitxa-tema">
            <span className="mostra" style={{ background: fitxa.variable.tema.color }} aria-hidden="true" />
            {fitxa.variable.tema.nom}
          </p>
          <h2>{fitxa.text_lliure ?? fitxa.variable.nom}</h2>
          {fitxa.descripcio && <p className="fitxa-descripcio">{fitxa.descripcio}</p>}
          <dl>
            {fitxa.categoria && (<><dt>{t('fitxa.categoria')}</dt><dd>{fitxa.categoria.nom}</dd></>)}
            {fitxa.partida && (<><dt>{t('fitxa.partida')}</dt><dd>{fitxa.partida.nom}</dd></>)}
            {fitxa.municipi && (<><dt>{t('fitxa.municipi')}</dt><dd>{fitxa.municipi.nom}</dd></>)}
            <dt>{t('fitxa.estat')}</dt><dd>{t(`fitxa.estats.${fitxa.estat}`)}</dd>
            <dt>{t('fitxa.origen')}</dt><dd>{t(`fitxa.origens.${fitxa.origen}`)}</dd>
            <dt>{t('fitxa.data')}</dt>
            <dd>{new Date(fitxa.created_at).toLocaleDateString(i18n.language)}</dd>
          </dl>
          {fitxa.fotos.length > 0 && (
            <div className="fotos">
              <h3>{t('fitxa.fotos')}</h3>
              {fitxa.fotos.map((f, i) => (
                <a key={f.id} href={urlFoto(f.storage_path)} target="_blank" rel="noreferrer">
                  <img
                    src={urlFoto(f.storage_path)}
                    alt={t('fitxa.foto', { n: i + 1, total: fitxa.fotos.length })}
                    loading="lazy"
                  />
                </a>
              ))}
            </div>
          )}
        </>
      )}
    </aside>
  );
}
