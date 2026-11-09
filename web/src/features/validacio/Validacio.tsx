import { useCallback, useEffect, useMemo, useState } from 'react';
import { useTranslation } from 'react-i18next';
import type { Geometry } from 'geojson';
import { useAuth } from '../../auth/AuthContext';
import { supabase } from '../../lib/supabase';
import { urlFoto } from '../mapa/dades';
import type { Dades } from '../mapa/tipus';
import { MiniMapa } from './MiniMapa';
import { LesMeuesPartides } from './LesMeuesPartides';
import { Padrinatges } from './Padrinatges';

const MIDA_PAGINA = 25;

interface Pendent {
  id: string;
  descripcio: string | null;
  text_lliure: string | null;
  origen: 'legacy_2018' | 'web' | 'app';
  created_at: string;
  partida_id: number | null;
  geom: Geometry;
  variable: { nom: string; tema: { nom: string; color: string } };
  categoria: { nom: string } | null;
  partida: { nom: string } | null;
  municipi: { nom: string } | null;
  fotos: { id: string; storage_path: string }[];
}

function Pendents({ dades, onCanvi, partidaInicial }: { dades: Dades; onCanvi: () => void; partidaInicial: number | '' }) {
  const { t, i18n } = useTranslation();
  const { uid, esCoordinador } = useAuth();
  const [partidaId, setPartidaId] = useState<number | ''>(partidaInicial);
  const [pagina, setPagina] = useState(0);
  const [files, setFiles] = useState<Pendent[]>([]);
  const [total, setTotal] = useState(0);
  const [carregant, setCarregant] = useState(true);
  const [error, setError] = useState(false);
  const [actual, setActual] = useState<Pendent | null>(null);
  const [motiu, setMotiu] = useState('');
  const [rebutjant, setRebutjant] = useState(false);
  const [errorAccio, setErrorAccio] = useState<string | null>(null);
  const [partidesPropies, setPartidesPropies] = useState<number[]>([]);

  useEffect(() => {
    if (esCoordinador || !uid) return;
    void supabase.from('padrinatges').select('partida_id').eq('perfil_id', uid)
      .then(({ data }) => setPartidesPropies((data ?? []).map((p) => p.partida_id as number)));
  }, [esCoordinador, uid]);

  const opcionsPartida = useMemo(() => {
    const totes = dades.partides.features
      .map((f) => f.properties as { id: number; nom: string; municipi: string })
      .filter((p) => esCoordinador || partidesPropies.includes(p.id));
    return totes.sort((a, b) => `${a.municipi} ${a.nom}`.localeCompare(`${b.municipi} ${b.nom}`, 'ca'));
  }, [dades.partides, esCoordinador, partidesPropies]);

  const carregar = useCallback(async () => {
    if (!uid) return;
    setCarregant(true);
    setError(false);
    let consulta = supabase
      .from('elements')
      .select(`id, descripcio, text_lliure, origen, created_at, partida_id, geom,
        variable:variables(nom, tema:temes(nom, color)),
        categoria:categories(nom),
        partida:partides(nom),
        municipi:municipis(nom),
        fotos:element_fotos(id, storage_path)`, { count: 'exact' })
      .eq('estat', 'pendent')
      .or(`autor_id.is.null,autor_id.neq.${uid}`)   // nadie valida lo suyo
      .order('created_at', { ascending: false })
      .range(pagina * MIDA_PAGINA, (pagina + 1) * MIDA_PAGINA - 1);
    if (partidaId !== '') consulta = consulta.eq('partida_id', partidaId);
    const { data, error: err, count } = await consulta;
    setCarregant(false);
    if (err) {
      setError(true);
      return;
    }
    const noves = data as unknown as Pendent[];
    setFiles(noves);
    setTotal(count ?? 0);
    setActual((a) => noves.find((n) => n.id === a?.id) ?? noves[0] ?? null);
  }, [uid, pagina, partidaId]);

  useEffect(() => { void carregar(); }, [carregar]);
  useEffect(() => {
    setMotiu('');
    setRebutjant(false);
    setErrorAccio(null);
  }, [actual?.id]);

  const canviar = async (estat: 'validat' | 'rebutjat') => {
    if (!actual) return;
    setErrorAccio(null);
    const { error: err } = await supabase.rpc('canviar_estat', {
      p_element_id: actual.id,
      p_estat: estat,
      p_motiu: estat === 'rebutjat' ? motiu.trim() : null,
    });
    if (err) {
      setErrorAccio(['42501', '22023'].includes(err.code) ? err.message : t('comu.errorDesar'));
      return;
    }
    // Pasa al siguiente de la lista
    const i = files.findIndex((f) => f.id === actual.id);
    const seguent = files[i + 1] ?? files[i - 1] ?? null;
    setActual(seguent);
    await carregar();
    onCanvi();
  };

  const nPagines = Math.max(1, Math.ceil(total / MIDA_PAGINA));

  return (
    <div className="validacio">
      <section className="validacio-llista" aria-label={t('validacio.pendents')}>
        <label className="camp">
          <span>{t('fitxa.partida')}</span>
          <select
            value={partidaId}
            onChange={(e) => {
              setPartidaId(e.target.value ? Number(e.target.value) : '');
              setPagina(0);
            }}
          >
            <option value="">{t(esCoordinador ? 'validacio.totes' : 'validacio.lesMeues')}</option>
            {opcionsPartida.map((p) => <option key={p.id} value={p.id}>{p.municipi} · {p.nom}</option>)}
          </select>
        </label>
        <p className="resum" role="status">
          {carregant ? t('comu.carregant') : t('validacio.recompte', { count: total })}
        </p>
        {error && <p role="alert" className="error">{t('validacio.error')}</p>}
        <ul>
          {files.map((f) => (
            <li key={f.id}>
              <button
                type="button"
                className={`fila ${actual?.id === f.id ? 'activa' : ''}`}
                aria-current={actual?.id === f.id}
                onClick={() => setActual(f)}
              >
                <span className="mostra" style={{ background: f.variable.tema.color }} aria-hidden="true" />
                <span className="fila-text">
                  <strong>{f.text_lliure ?? f.variable.nom}</strong>
                  <small>
                    {[f.categoria?.nom, f.partida?.nom, f.municipi?.nom].filter(Boolean).join(' · ')}
                  </small>
                </span>
              </button>
            </li>
          ))}
        </ul>
        {!carregant && !error && !files.length && <p className="nota">{t('validacio.buit')}</p>}
        {nPagines > 1 && (
          <div className="paginacio">
            <button type="button" className="boto petit" disabled={pagina === 0} onClick={() => setPagina(pagina - 1)}>‹</button>
            <span>{t('validacio.pagina', { n: pagina + 1, total: nPagines })}</span>
            <button type="button" className="boto petit" disabled={pagina >= nPagines - 1} onClick={() => setPagina(pagina + 1)}>›</button>
          </div>
        )}
      </section>

      {actual && (
        <section className="validacio-detall" aria-label={t('validacio.detall')}>
          <MiniMapa geom={actual.geom} />
          <div className="validacio-info">
            <p className="fitxa-tema">
              <span className="mostra" style={{ background: actual.variable.tema.color }} aria-hidden="true" />
              {actual.variable.tema.nom}
            </p>
            <h2>{actual.text_lliure ?? actual.variable.nom}</h2>
            {actual.descripcio && <p className="fitxa-descripcio">{actual.descripcio}</p>}
            <dl>
              {actual.categoria && (<><dt>{t('fitxa.categoria')}</dt><dd>{actual.categoria.nom}</dd></>)}
              {actual.partida && (<><dt>{t('fitxa.partida')}</dt><dd>{actual.partida.nom}</dd></>)}
              {actual.municipi && (<><dt>{t('fitxa.municipi')}</dt><dd>{actual.municipi.nom}</dd></>)}
              <dt>{t('fitxa.origen')}</dt><dd>{t(`fitxa.origens.${actual.origen}`)}</dd>
              <dt>{t('fitxa.data')}</dt><dd>{new Date(actual.created_at).toLocaleDateString(i18n.language)}</dd>
            </dl>
            {actual.fotos.length > 0 && (
              <div className="fotos fotos-fila">
                {actual.fotos.map((f, i) => (
                  <a key={f.id} href={urlFoto(f.storage_path)} target="_blank" rel="noreferrer">
                    <img src={urlFoto(f.storage_path)} alt={t('fitxa.foto', { n: i + 1, total: actual.fotos.length })} />
                  </a>
                ))}
              </div>
            )}
            {errorAccio && <p role="alert" className="error">{errorAccio}</p>}
            {rebutjant ? (
              <div className="camp">
                <label htmlFor="motiu">{t('validacio.motiu')}</label>
                <textarea id="motiu" rows={3} maxLength={500} value={motiu} onChange={(e) => setMotiu(e.target.value)} />
                <div className="accions-form">
                  <button type="button" className="boto" onClick={() => setRebutjant(false)}>{t('comu.cancelar')}</button>
                  <button type="button" className="boto perill" disabled={!motiu.trim()} onClick={() => void canviar('rebutjat')}>
                    {t('validacio.confirmarRebuig')}
                  </button>
                </div>
              </div>
            ) : (
              <div className="accions-form">
                <button type="button" className="boto" onClick={() => setRebutjant(true)}>{t('validacio.rebutjar')}</button>
                <button type="button" className="boto primari" onClick={() => void canviar('validat')}>{t('validacio.validar')}</button>
              </div>
            )}
          </div>
        </section>
      )}
    </div>
  );
}

export function Validacio({ dades, onCanvi }: { dades: Dades; onCanvi: () => void }) {
  const { t } = useTranslation();
  const { uid, perfil, potValidar, esCoordinador } = useAuth();
  const [pestanya, setPestanya] = useState<'pendents' | 'partides' | 'padrinatges'>('pendents');
  const [partidaFiltre, setPartidaFiltre] = useState<number | ''>('');

  if (uid && !perfil) return <div className="avis"><p>{t('comu.carregant')}</p></div>;
  if (!potValidar) return <div className="avis"><p>{t('validacio.senseAcces')}</p></div>;

  return (
    <main className="cos-validacio">
      <div className="pestanyes" role="tablist">
        <button
          type="button"
          role="tab"
          aria-selected={pestanya === 'pendents'}
          onClick={() => {
            setPartidaFiltre('');
            setPestanya('pendents');
          }}
        >
          {t('validacio.pendents')}
        </button>
        <button type="button" role="tab" aria-selected={pestanya === 'partides'} onClick={() => setPestanya('partides')}>
          {t('partides.titol')}
        </button>
        {esCoordinador && (
          <button type="button" role="tab" aria-selected={pestanya === 'padrinatges'} onClick={() => setPestanya('padrinatges')}>
            {t('padrinatges.titol')}
          </button>
        )}
      </div>
      {pestanya === 'pendents' && <Pendents key={partidaFiltre} dades={dades} onCanvi={onCanvi} partidaInicial={partidaFiltre} />}
      {pestanya === 'partides' && (
        <LesMeuesPartides
          onVeurePendents={(id) => {
            setPartidaFiltre(id);
            setPestanya('pendents');
          }}
        />
      )}
      {pestanya === 'padrinatges' && <Padrinatges dades={dades} />}
    </main>
  );
}
