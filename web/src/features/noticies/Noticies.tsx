import { useCallback, useEffect, useState, type FormEvent, type ReactNode } from 'react';
import { useTranslation } from 'react-i18next';
import { Link, useNavigate, useParams } from 'react-router-dom';
import { useAuth } from '../../auth/AuthContext';
import { comprimir } from '../../lib/fotos';
import { supabase } from '../../lib/supabase';

interface Noticia {
  id: string;
  tipus: 'noticia' | 'eixida';
  titol: string;
  cos: string;
  imatge_path: string | null;
  data_event: string | null;
  publicat: boolean;
  created_at: string;
}

const MIDA_PAGINA = 12;
const COLUMNES = 'id, tipus, titol, cos, imatge_path, data_event, publicat, created_at';

const urlImatge = (path: string) => supabase.storage.from('contingut').getPublicUrl(path).data.publicUrl;

/** Texto plano a párrafos con enlaces. Nunca HTML: el contenido se muestra como texto. */
function Cos({ text }: { text: string }) {
  return (
    <>
      {text.split(/\n{2,}/).map((p, i) => (
        <p key={i} className="cos-parraf">{ambEnllacos(p)}</p>
      ))}
    </>
  );
}

function ambEnllacos(text: string): ReactNode[] {
  // La puntuación final no es parte del enlace
  return text.split(/(https?:\/\/[^\s)]*[^\s).,;:!?»"'])/g).map((tros, i) =>
    /^https?:\/\//.test(tros) ? <a key={i} href={tros} target="_blank" rel="noreferrer noopener">{tros}</a> : tros,
  );
}

function Etiqueta({ n }: { n: Noticia }) {
  const { t, i18n } = useTranslation();
  const data = new Date(n.data_event ?? n.created_at).toLocaleDateString(i18n.language);
  return (
    <p className="nota">
      {t(`noticies.tipus.${n.tipus}`)} · {data}
      {!n.publicat && <strong className="esborrany"> · {t('noticies.esborrany')}</strong>}
    </p>
  );
}

export function LlistaNoticies() {
  const { t } = useTranslation();
  const { esCoordinador } = useAuth();
  const [files, setFiles] = useState<Noticia[] | null>(null);
  const [total, setTotal] = useState(0);
  const [pagina, setPagina] = useState(0);
  const [tipus, setTipus] = useState<'' | Noticia['tipus']>('');
  const [error, setError] = useState(false);

  useEffect(() => {
    let consulta = supabase
      .from('noticies')
      .select(COLUMNES, { count: 'exact' })
      .order('created_at', { ascending: false })
      .range(pagina * MIDA_PAGINA, (pagina + 1) * MIDA_PAGINA - 1);
    if (tipus) consulta = consulta.eq('tipus', tipus);
    void consulta.then(({ data, count, error: err }) => {
      if (err) {
        setError(true);
        return;
      }
      setFiles(data as Noticia[]);
      setTotal(count ?? 0);
    });
  }, [pagina, tipus, esCoordinador]);

  const nPagines = Math.max(1, Math.ceil(total / MIDA_PAGINA));

  return (
    <main className="pagina">
      <div className="pagina-cap">
        <h1>{t('noticies.titol')}</h1>
        {esCoordinador && <Link className="boto primari" to="/noticies/nova">{t('noticies.nova')}</Link>}
      </div>
      <label className="camp filtre-curt">
        <span>{t('noticies.mostrar')}</span>
        <select
          value={tipus}
          onChange={(e) => {
            setTipus(e.target.value as typeof tipus);
            setPagina(0);
          }}
        >
          <option value="">{t('noticies.totes')}</option>
          <option value="noticia">{t('noticies.tipus.noticia')}</option>
          <option value="eixida">{t('noticies.tipus.eixida')}</option>
        </select>
      </label>
      {error && <p role="alert" className="error">{t('noticies.error')}</p>}
      {!files && !error && <p role="status">{t('comu.carregant')}</p>}
      {files?.length === 0 && <p>{t('noticies.buit')}</p>}
      <div className="noticies">
        {files?.map((n) => (
          <article key={n.id} className="targeta noticia-targeta">
            {n.imatge_path && <img src={urlImatge(n.imatge_path)} alt="" loading="lazy" />}
            <div>
              <Etiqueta n={n} />
              <h2><Link to={`/noticies/${n.id}`}>{n.titol}</Link></h2>
              <p className="resum-noticia">{n.cos.slice(0, 160)}{n.cos.length > 160 ? '…' : ''}</p>
            </div>
          </article>
        ))}
      </div>
      {nPagines > 1 && (
        <div className="paginacio">
          <button type="button" className="boto petit" disabled={pagina === 0} onClick={() => setPagina(pagina - 1)}>‹</button>
          <span>{t('validacio.pagina', { n: pagina + 1, total: nPagines })}</span>
          <button type="button" className="boto petit" disabled={pagina >= nPagines - 1} onClick={() => setPagina(pagina + 1)}>›</button>
        </div>
      )}
    </main>
  );
}

export function DetallNoticia() {
  const { t } = useTranslation();
  const { id } = useParams();
  const { esCoordinador } = useAuth();
  const [n, setN] = useState<Noticia | null>(null);
  const [noTrobada, setNoTrobada] = useState(false);

  useEffect(() => {
    void supabase.from('noticies').select(COLUMNES).eq('id', id!).maybeSingle().then(({ data }) => {
      if (data) setN(data as Noticia);
      else setNoTrobada(true);
    });
  }, [id, esCoordinador]);

  if (noTrobada) return <main className="pagina"><p>{t('estat.noTrobat')}</p><Link to="/noticies">{t('noticies.tornar')}</Link></main>;
  if (!n) return <main className="pagina"><p role="status">{t('comu.carregant')}</p></main>;

  return (
    <main className="pagina pagina-estreta">
      <Link to="/noticies">{t('noticies.tornar')}</Link>
      <Etiqueta n={n} />
      <h1>{n.titol}</h1>
      {n.imatge_path && <img className="noticia-imatge" src={urlImatge(n.imatge_path)} alt="" />}
      <Cos text={n.cos} />
      {esCoordinador && <Link className="boto" to={`/noticies/${n.id}/edita`}>{t('comu.editar')}</Link>}
    </main>
  );
}

export function EditorNoticia() {
  const { t } = useTranslation();
  const { id } = useParams();
  const navegar = useNavigate();
  const { uid, esCoordinador, perfil } = useAuth();
  const [titol, setTitol] = useState('');
  const [cos, setCos] = useState('');
  const [tipus, setTipus] = useState<Noticia['tipus']>('noticia');
  const [dataEvent, setDataEvent] = useState('');
  const [publicat, setPublicat] = useState(false);
  const [imatge, setImatge] = useState<string | null>(null);
  const [fitxer, setFitxer] = useState<File | null>(null);
  const [enviant, setEnviant] = useState(false);
  const [error, setError] = useState(false);

  const carregar = useCallback(async () => {
    if (!id) return;
    const { data } = await supabase.from('noticies').select(COLUMNES).eq('id', id).maybeSingle();
    if (!data) return;
    const n = data as Noticia;
    setTitol(n.titol);
    setCos(n.cos);
    setTipus(n.tipus);
    setDataEvent(n.data_event ?? '');
    setPublicat(n.publicat);
    setImatge(n.imatge_path);
  }, [id]);

  useEffect(() => { void carregar(); }, [carregar]);

  if (uid && !perfil) return <main className="pagina"><p role="status">{t('comu.carregant')}</p></main>;
  if (!esCoordinador) return <main className="pagina"><p>{t('noticies.senseAcces')}</p></main>;

  const desar = async (e: FormEvent) => {
    e.preventDefault();
    setEnviant(true);
    setError(false);
    try {
      let imatgePath = imatge;
      if (fitxer) {
        imatgePath = `${crypto.randomUUID()}.jpg`;
        const pujada = await supabase.storage.from('contingut')
          .upload(imatgePath, await comprimir(fitxer), { contentType: 'image/jpeg' });
        if (pujada.error) throw pujada.error;
      }
      const fila = {
        titol: titol.trim(), cos: cos.trim(), tipus, publicat,
        data_event: dataEvent || null,
        imatge_path: imatgePath,
        updated_at: new Date().toISOString(),
      };
      const res = id
        ? await supabase.from('noticies').update(fila).eq('id', id).select('id').single()
        : await supabase.from('noticies').insert({ ...fila, autor_id: uid }).select('id').single();
      if (res.error) throw res.error;
      if (fitxer && imatge) await supabase.storage.from('contingut').remove([imatge]);
      navegar(`/noticies/${(res.data as { id: string }).id}`);
    } catch {
      setError(true);
    } finally {
      setEnviant(false);
    }
  };

  const esborrar = async () => {
    if (!id || !window.confirm(t('noticies.confirmarEsborrar'))) return;
    const { error: err } = await supabase.from('noticies').delete().eq('id', id);
    if (err) {
      setError(true);
      return;
    }
    if (imatge) await supabase.storage.from('contingut').remove([imatge]);
    navegar('/noticies');
  };

  return (
    <main className="pagina pagina-estreta">
      <h1>{id ? t('noticies.editar') : t('noticies.nova')}</h1>
      <form onSubmit={(e) => void desar(e)}>
        <label className="camp">
          <span>{t('noticies.titolCamp')}</span>
          <input required maxLength={200} value={titol} onChange={(e) => setTitol(e.target.value)} />
        </label>
        <label className="camp">
          <span>{t('noticies.mostrarTipus')}</span>
          <select value={tipus} onChange={(e) => setTipus(e.target.value as Noticia['tipus'])}>
            <option value="noticia">{t('noticies.tipus.noticia')}</option>
            <option value="eixida">{t('noticies.tipus.eixida')}</option>
          </select>
        </label>
        <label className="camp">
          <span>{t('noticies.data')}</span>
          <input type="date" value={dataEvent} onChange={(e) => setDataEvent(e.target.value)} />
        </label>
        <label className="camp">
          <span>{t('noticies.cos')}</span>
          <textarea rows={12} required value={cos} onChange={(e) => setCos(e.target.value)} />
        </label>
        <label className="camp">
          <span>{t('noticies.imatge')}</span>
          <input type="file" accept="image/*" onChange={(e) => setFitxer(e.target.files?.[0] ?? null)} />
        </label>
        {imatge && !fitxer && <img className="noticia-imatge" src={urlImatge(imatge)} alt="" />}
        <label className="opcio-publicar">
          <input type="checkbox" checked={publicat} onChange={(e) => setPublicat(e.target.checked)} />
          <span>{t('noticies.publicar')}</span>
        </label>
        {error && <p role="alert" className="error">{t('comu.errorDesar')}</p>}
        <div className="accions-form">
          {id && <button type="button" className="boto" onClick={() => void esborrar()}>{t('comu.esborrar')}</button>}
          <button type="submit" className="boto primari" disabled={enviant}>{t('comu.desar')}</button>
        </div>
      </form>
    </main>
  );
}
