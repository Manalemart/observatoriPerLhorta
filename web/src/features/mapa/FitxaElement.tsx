import { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { useAuth } from '../../auth/AuthContext';
import { esborrarFotos } from '../../lib/fotos';
import { supabase } from '../../lib/supabase';
import { carregarFitxa, urlFoto } from './dades';
import type { Fitxa } from './tipus';

interface Props {
  id: string;
  /** Posición entre los elementos superpuestos bajo el clic. */
  posicio: number;
  total: number;
  onMoure: (delta: number) => void;
  onTancar: () => void;
  /** Algo ha cambiado: hay que recargar los elementos del mapa. */
  onCanvi: () => void;
  onDemanarEntrada: () => void;
  /** «Ha canviat»: se aporta un elemento nuevo por el circuito normal. */
  onHaCanviat: () => void;
}

const ARA = new Date();

export function FitxaElement({ id, posicio, total, onMoure, onTancar, onCanvi, onDemanarEntrada, onHaCanviat }: Props) {
  const { t, i18n } = useTranslation();
  const { uid, esCoordinador } = useAuth();
  const [fitxa, setFitxa] = useState<Fitxa | null>(null);
  const [error, setError] = useState(false);
  const [editant, setEditant] = useState(false);
  const [text, setText] = useState('');
  const [errorAccio, setErrorAccio] = useState(false);
  const [confirmat, setConfirmat] = useState(false);
  const [errorConfirmar, setErrorConfirmar] = useState(false);

  const carregar = () => carregarFitxa(id, !!uid);

  useEffect(() => {
    let vigent = true;
    setFitxa(null);
    setError(false);
    setEditant(false);
    setErrorAccio(false);
    setConfirmat(false);
    setErrorConfirmar(false);
    carregar()
      .then((f) => { if (vigent) setFitxa(f); })
      .catch(() => { if (vigent) setError(true); });
    return () => { vigent = false; };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [id, uid]);

  const esMeu = !!uid && fitxa?.autor_id === uid;
  const editable = esMeu && fitxa?.estat !== 'validat';

  const desar = async () => {
    setErrorAccio(false);
    const { error: err } = await supabase.from('elements').update({ descripcio: text.trim() || null }).eq('id', id);
    if (err) {
      setErrorAccio(true);
      return;
    }
    setEditant(false);
    setFitxa(await carregar());
    onCanvi(); // si estaba rechazado, vuelve a pendiente
  };

  const esborrar = async () => {
    if (!fitxa || !window.confirm(t('fitxa.confirmarEsborrar'))) return;
    setErrorAccio(false);
    // Primero las fotos: si fallan, el elemento sigue ahí y se puede reintentar
    try {
      await esborrarFotos(fitxa.fotos.map((f) => f.storage_path));
    } catch {
      setErrorAccio(true);
      return;
    }
    const { error: err } = await supabase.from('elements').delete().eq('id', id);
    if (err) {
      setErrorAccio(true);
      return;
    }
    onTancar();
    onCanvi();
  };

  const confirmar = async () => {
    if (!uid) {
      onDemanarEntrada();
      return;
    }
    setErrorConfirmar(false);
    const { error: err } = await supabase.rpc('confirmar_element', { p_element_id: id });
    if (err) {
      setErrorConfirmar(true);
      return;
    }
    setConfirmat(true);
    setFitxa(await carregar());
    onCanvi(); // el punto deja de estar «per revisar»
  };

  const reobrir = async () => {
    setErrorAccio(false);
    const { error: err } = await supabase.rpc('canviar_estat', { p_element_id: id, p_estat: 'pendent' });
    if (err) {
      setErrorAccio(true);
      return;
    }
    setFitxa(await carregar());
    onCanvi();
  };

  return (
    <aside className="fitxa" aria-live="polite">
      <button type="button" className="tancar" aria-label={t('fitxa.tancar')} onClick={onTancar}>×</button>
      {total > 1 && (
        <div className="superposats">
          <button type="button" className="boto petit" aria-label={t('fitxa.anterior')} disabled={posicio === 0} onClick={() => onMoure(-1)}>‹</button>
          <span>{t('fitxa.posicio', { n: posicio + 1, total })}</span>
          <button type="button" className="boto petit" aria-label={t('fitxa.seguent')} disabled={posicio === total - 1} onClick={() => onMoure(1)}>›</button>
        </div>
      )}
      {error && <p role="alert">{t('fitxa.error')}</p>}
      {!error && !fitxa && <p>{t('fitxa.carregant')}</p>}
      {fitxa && (
        <>
          <p className="fitxa-xips">
            <span className="xip">
              <span className="mostra" style={{ background: fitxa.variable.tema.color }} aria-hidden="true" />
              {fitxa.variable.tema.nom}
            </span>
            {fitxa.origen === 'legacy_2018' && (
              <span className="xip xip-2018">
                <svg aria-hidden="true" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.6" strokeLinecap="round" strokeLinejoin="round"><rect x="3" y="5" width="18" height="16" rx="2" /><path d="M3 10h18" /><path d="M8 3v4" /><path d="M16 3v4" /></svg>
                {t('fitxa.inventari2018')}
              </span>
            )}
          </p>
          <h2>{fitxa.text_lliure ?? fitxa.variable.nom}</h2>
          {fitxa.estat === 'rebutjat' && fitxa.motiu_rebuig && (
            <p className="motiu" role="status"><strong>{t('fitxa.motiu')}:</strong> {fitxa.motiu_rebuig}</p>
          )}
          {editant ? (
            <div className="camp">
              <label htmlFor="fitxa-descripcio">{t('aportar.descripcio')}</label>
              <textarea id="fitxa-descripcio" rows={3} maxLength={2000} value={text} onChange={(e) => setText(e.target.value)} />
              <div className="accions-form">
                <button type="button" className="boto" onClick={() => setEditant(false)}>{t('comu.cancelar')}</button>
                <button type="button" className="boto primari" onClick={() => void desar()}>{t('comu.desar')}</button>
              </div>
            </div>
          ) : (
            fitxa.descripcio && <p className="fitxa-descripcio">{fitxa.descripcio}</p>
          )}
          <dl>
            {fitxa.categoria && (<><dt>{t('fitxa.categoria')}</dt><dd>{fitxa.categoria.nom}</dd></>)}
            {fitxa.partida && (<><dt>{t('fitxa.partida')}</dt><dd>{fitxa.partida.nom}</dd></>)}
            {fitxa.municipi && (<><dt>{t('fitxa.municipi')}</dt><dd>{fitxa.municipi.nom}</dd></>)}
            {fitxa.sigpac_ref && (<><dt>SIGPAC</dt><dd>{fitxa.sigpac_ref}</dd></>)}
            <dt>{t('fitxa.estat')}</dt><dd>{t(`fitxa.estats.${fitxa.estat}`)}</dd>
            <dt>{t('fitxa.origen')}</dt><dd>{t(`fitxa.origens.${fitxa.origen}`)}</dd>
            <dt>{t('fitxa.data')}</dt>
            <dd>{new Date(fitxa.created_at).toLocaleDateString(i18n.language)}</dd>
            {fitxa.origen === 'legacy_2018' && (
              <>
                <dt>{t('fitxa.ultimaRevisio')}</dt>
                <dd>
                  {fitxa.revisat_at
                    ? new Date(fitxa.revisat_at).toLocaleDateString(i18n.language)
                    : t('fitxa.revisio2018', { count: ARA.getFullYear() - 2018 })}
                </dd>
              </>
            )}
          </dl>
          {fitxa.origen === 'legacy_2018' && fitxa.estat === 'validat' && !editant && (
            <div className="encara-aixi">
              {confirmat ? (
                <p role="status" className="encara-aixi-fet">{t('fitxa.gracies')}</p>
              ) : (
                <>
                  <p className="encara-aixi-titol">{t('fitxa.encaraAixi')}</p>
                  <p className="encara-aixi-text">{t('fitxa.encaraAixiText')}</p>
                  <div className="encara-aixi-botons">
                    <button type="button" className="boto contorn" onClick={() => void confirmar()}>{t('fitxa.continuaIgual')}</button>
                    <button type="button" className="boto lima" onClick={onHaCanviat}>{t('fitxa.haCanviat')}</button>
                  </div>
                  {errorConfirmar && <p role="alert" className="error">{t('fitxa.errorConfirmar')}</p>}
                </>
              )}
            </div>
          )}
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
          {errorAccio && <p role="alert" className="error">{t('comu.errorDesar')}</p>}
          {!editant && (editable || (esCoordinador && fitxa.estat !== 'pendent')) && (
            <div className="accions-form">
              {editable && (
                <>
                  <button type="button" className="boto" onClick={() => { setText(fitxa.descripcio ?? ''); setEditant(true); }}>
                    {t('comu.editar')}
                  </button>
                  <button type="button" className="boto" onClick={() => void esborrar()}>{t('comu.esborrar')}</button>
                </>
              )}
              {esCoordinador && !esMeu && fitxa.estat !== 'pendent' && (
                <button type="button" className="boto" onClick={() => void reobrir()}>{t('fitxa.reobrir')}</button>
              )}
            </div>
          )}
        </>
      )}
    </aside>
  );
}
