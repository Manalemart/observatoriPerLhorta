import { useMemo, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { Link } from 'react-router-dom';
import type { FeatureCollection } from 'geojson';
import { FONS } from './estil';
import type { Dades, Epoca, Fons, Tema } from './tipus';

const EPOQUES: Epoca[] = ['tot', '2018', 'noves'];

interface Props {
  dades: Dades;
  elements: FeatureCollection;
  fons: Fons;
  onFons: (f: Fons) => void;
  variablesActives: Set<number>;
  onVariablesActives: (v: Set<number>) => void;
  epoca: Epoca;
  onEpoca: (e: Epoca) => void;
  veurePartides: boolean;
  onPartides: (v: boolean) => void;
  veureMunicipis: boolean;
  onMunicipis: (v: boolean) => void;
  veureSigpac: boolean;
  onSigpac: (v: boolean) => void;
}

function FilaTema({ tema, recompte, actives, onCanvi }: {
  tema: Tema;
  recompte: Map<number, number>;
  actives: Set<number>;
  onCanvi: (v: Set<number>) => void;
}) {
  const { t, i18n } = useTranslation();
  const [obert, setObert] = useState(false);
  const fmt = new Intl.NumberFormat(i18n.language);

  const ids = tema.variables.map((v) => v.id);
  const nActives = ids.filter((id) => actives.has(id)).length;
  const total = ids.reduce((suma, id) => suma + (recompte.get(id) ?? 0), 0);

  const canviarTema = (marcat: boolean) => {
    const seguent = new Set(actives);
    ids.forEach((id) => (marcat ? seguent.add(id) : seguent.delete(id)));
    onCanvi(seguent);
  };
  const canviarVariable = (id: number, marcat: boolean) => {
    const seguent = new Set(actives);
    if (marcat) seguent.add(id);
    else seguent.delete(id);
    onCanvi(seguent);
  };

  return (
    <li className="tema">
      <div className="tema-fila">
        <label className="tema-etiqueta">
          <input
            type="checkbox"
            checked={nActives === ids.length}
            ref={(el) => { if (el) el.indeterminate = nActives > 0 && nActives < ids.length; }}
            onChange={(e) => canviarTema(e.target.checked)}
          />
          <span className="mostra" style={{ background: tema.color }} aria-hidden="true" />
          <span>{tema.nom}</span>
        </label>
        <span className="recompte">{fmt.format(total)}</span>
        <button
          type="button"
          className="desplegar"
          aria-expanded={obert}
          aria-label={t(obert ? 'panell.plegar' : 'panell.desplegar', { tema: tema.nom })}
          onClick={() => setObert(!obert)}
        >
          {obert ? '▾' : '▸'}
        </button>
      </div>
      {obert && (
        <ul className="variables">
          {tema.variables.map((v) => (
            <li key={v.id}>
              <label>
                <input
                  type="checkbox"
                  checked={actives.has(v.id)}
                  onChange={(e) => canviarVariable(v.id, e.target.checked)}
                />
                <span>{v.nom}</span>
              </label>
              <span className="recompte">{fmt.format(recompte.get(v.id) ?? 0)}</span>
            </li>
          ))}
        </ul>
      )}
    </li>
  );
}

export function Panell({
  dades, elements, fons, onFons, variablesActives, onVariablesActives, epoca, onEpoca,
  veurePartides, onPartides, veureMunicipis, onMunicipis, veureSigpac, onSigpac,
}: Props) {
  const { t, i18n } = useTranslation();

  const recompte = useMemo(() => {
    const m = new Map<number, number>();
    for (const f of elements.features) {
      const id = f.properties?.variable_id as number;
      m.set(id, (m.get(id) ?? 0) + 1);
    }
    return m;
  }, [elements]);

  const total = elements.features.length;
  const noValidats = useMemo(
    () => elements.features.filter((f) => f.properties?.estat !== 'validat').length,
    [elements],
  );
  const visibles = useMemo(
    () => [...recompte].reduce((s, [id, n]) => s + (variablesActives.has(id) ? n : 0), 0),
    [recompte, variablesActives],
  );
  const perRevisar = useMemo(
    () => elements.features.filter((f) => f.properties?.per_revisar === true).length,
    [elements],
  );
  const fmt = new Intl.NumberFormat(i18n.language);
  const totes = useMemo(() => new Set(dades.temes.flatMap((x) => x.variables.map((v) => v.id))), [dades.temes]);

  return (
    <div className="panell-contingut">
      <section className="epoca">
        <h2 id="epoca-titol">{t('panell.epoca')}</h2>
        <div className="segmentat" role="group" aria-labelledby="epoca-titol">
          {EPOQUES.map((e) => (
            <button key={e} type="button" aria-pressed={epoca === e} onClick={() => onEpoca(e)}>
              {t(`panell.epoques.${e}`)}
            </button>
          ))}
        </div>
        <ul className="llegenda-epoca">
          <li>
            <svg aria-hidden="true" width="18" height="18" viewBox="0 0 18 18"><circle cx="9" cy="9" r="6" fill="#fff" stroke="currentColor" strokeWidth="3" /></svg>
            <span>{t('panell.llegenda2018')}</span>
            <strong>{fmt.format(perRevisar)}</strong>
          </li>
          <li>
            <svg aria-hidden="true" width="18" height="18" viewBox="0 0 18 18"><circle cx="9" cy="9" r="7" fill="currentColor" /></svg>
            <span>{t('panell.llegendaNoves')}</span>
            <strong>{fmt.format(total - perRevisar)}</strong>
          </li>
        </ul>
      </section>

      <section>
        <div className="seccio-cap">
          <h2>{t('panell.inventari')}</h2>
          <div className="accions">
            <button type="button" onClick={() => onVariablesActives(new Set(totes))}>{t('panell.tots')}</button>
            <button type="button" onClick={() => onVariablesActives(new Set())}>{t('panell.cap')}</button>
          </div>
        </div>
        <p className="resum">
          <strong>{t('panell.elements', { count: total - noValidats })}</strong>
          {noValidats > 0 && <><br />{t('panell.noValidats', { count: noValidats })}</>}
          <br />
          {t('panell.visibles', { visibles, total })}
        </p>
        <ul className="temes">
          {dades.temes.map((tema) => (
            <FilaTema
              key={tema.id}
              tema={tema}
              recompte={recompte}
              actives={variablesActives}
              onCanvi={onVariablesActives}
            />
          ))}
        </ul>
      </section>

      <section>
        <h2>{t('panell.fons')}</h2>
        <div className="opcions">
          {FONS.map((f) => (
            <label key={f}>
              <input type="radio" name="fons" checked={fons === f} onChange={() => onFons(f)} />
              <span>{t(`fons.${f}`)}</span>
            </label>
          ))}
        </div>
      </section>

      <section>
        <h2>{t('panell.capes')}</h2>
        <div className="opcions">
          <label>
            <input type="checkbox" checked={veureMunicipis} onChange={(e) => onMunicipis(e.target.checked)} />
            <span>{t('panell.municipis')}</span>
          </label>
          <label>
            <input type="checkbox" checked={veurePartides} onChange={(e) => onPartides(e.target.checked)} />
            <span>{t('panell.partides')}</span>
          </label>
          <label>
            <input type="checkbox" checked={veureSigpac} onChange={(e) => onSigpac(e.target.checked)} />
            <span>
              {t('panell.sigpac')}
              <small>{t('panell.sigpacZoom')}</small>
            </span>
          </label>
        </div>
      </section>

      <footer className="peu">
        {t('llicencia.dades')} · {t('llicencia.codi')} · <Link to="/legal">{t('legal.enllac')}</Link>
      </footer>
    </div>
  );
}
