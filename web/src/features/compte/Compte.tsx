import { useState, type FormEvent } from 'react';
import { useTranslation } from 'react-i18next';
import { Link } from 'react-router-dom';
import { useAuth } from '../../auth/AuthContext';
import { supabase } from '../../lib/supabase';

// El meu compte: àlies, descàrrega de les dades (RGPD art. 15 i 20) i esborrar el compte
// (art. 17). També és la pàgina que s'indica a Google Play per a demanar l'esborrat:
// sense haver entrat explica com fer-ho.

const PARAULA = 'ESBORRA';

/** Esborra el compte de qui ha entrat: primer les fotos de Storage, després la resta. */
export async function esborrarCompte(): Promise<void> {
  const { data: fotos, error: e1 } = await supabase.rpc('fotos_per_esborrar');
  if (e1) throw e1;
  const camins = (fotos ?? []) as string[];
  // L'API de Storage n'esborra fins a 1.000 per crida
  for (let i = 0; i < camins.length; i += 1000) {
    const { error } = await supabase.storage.from('fotos').remove(camins.slice(i, i + 1000));
    if (error) throw error;
  }
  const { error: e2 } = await supabase.rpc('esborrar_compte');
  if (e2) throw e2;
  // El compte ja no existeix: la sessió es tanca només en este navegador
  await supabase.auth.signOut({ scope: 'local' });
}

function descarregar(nom: string, contingut: string) {
  const url = URL.createObjectURL(new Blob([contingut], { type: 'application/json' }));
  const a = document.createElement('a');
  a.href = url;
  a.download = nom;
  a.click();
  URL.revokeObjectURL(url);
}

export function Compte({ onEntrar }: { onEntrar: () => void }) {
  const { t } = useTranslation();
  const { uid, perfil, session, sessioLlesta, recarregarPerfil } = useAuth();
  const [alies, setAlies] = useState<string | null>(null);
  const [aliesDesat, setAliesDesat] = useState(false);
  const [errorAlies, setErrorAlies] = useState(false);
  const [baixant, setBaixant] = useState(false);
  const [errorDades, setErrorDades] = useState(false);
  const [confirmacio, setConfirmacio] = useState('');
  const [esborrant, setEsborrant] = useState(false);
  const [errorEsborrar, setErrorEsborrar] = useState(false);
  const [esborrat, setEsborrat] = useState(false);

  if (esborrat) {
    return (
      <main className="pagina pagina-estreta compte">
        <h1>{t('compte.esborratTitol')}</h1>
        <p role="status">{t('compte.esborratText')}</p>
        <Link to="/" className="boto">{t('compte.tornarInici')}</Link>
      </main>
    );
  }

  if (!sessioLlesta) return <main className="pagina pagina-estreta compte" aria-busy="true" />;

  if (!uid) {
    return (
      <main className="pagina pagina-estreta compte">
        <h1>{t('compte.titol')}</h1>
        <h2>{t('compte.esborrarTitol')}</h2>
        <p>{t('compte.senseSessio')}</p>
        <button type="button" className="boto primari" onClick={onEntrar}>{t('auth.entrar')}</button>
        <p className="nota">
          {t('compte.perCorreu')}{' '}
          <a href="mailto:perlhorta@perlhorta.info?subject=Esborrar%20el%20compte%20de%20l'Observatori">perlhorta@perlhorta.info</a>.
        </p>
        <h3>{t('compte.queEsborraTitol')}</h3>
        <QueEsborra />
      </main>
    );
  }

  const valorAlies = alies ?? perfil?.nom_public ?? '';

  const desarAlies = async (e: FormEvent) => {
    e.preventDefault();
    setErrorAlies(false);
    setAliesDesat(false);
    const { error } = await supabase.from('perfils').update({ nom_public: valorAlies.trim() }).eq('id', uid);
    if (error) setErrorAlies(true);
    else {
      await recarregarPerfil();
      setAlies(null);
      setAliesDesat(true);
    }
  };

  const baixarDades = async () => {
    setBaixant(true);
    setErrorDades(false);
    const { data, error } = await supabase.rpc('les_meues_dades');
    setBaixant(false);
    if (error) setErrorDades(true);
    else descarregar(`observatori-les-meues-dades-${new Date().toISOString().slice(0, 10)}.json`, JSON.stringify(data, null, 2));
  };

  const esborrar = async (e: FormEvent) => {
    e.preventDefault();
    setEsborrant(true);
    setErrorEsborrar(false);
    try {
      await esborrarCompte();
      setEsborrat(true);
    } catch {
      setErrorEsborrar(true);
    } finally {
      setEsborrant(false);
    }
  };

  return (
    <main className="pagina pagina-estreta compte">
      <h1>{t('compte.titol')}</h1>
      <p className="nota">{t('compte.correu', { email: session?.user.email ?? '' })}</p>

      <section className="compte-seccio">
        <h2>{t('auth.alies')}</h2>
        <form onSubmit={(e) => void desarAlies(e)}>
          <label className="camp">
            <span>{t('compte.aliesExplicacio')}</span>
            <input required maxLength={40} value={valorAlies} onChange={(e) => { setAlies(e.target.value); setAliesDesat(false); }} />
          </label>
          {errorAlies && <p role="alert" className="error">{t('comu.errorDesar')}</p>}
          {aliesDesat && <p role="status" className="nota">{t('compte.aliesDesat')}</p>}
          <button type="submit" className="boto" disabled={!valorAlies.trim() || valorAlies.trim() === perfil?.nom_public}>
            {t('comu.desar')}
          </button>
        </form>
      </section>

      <section className="compte-seccio">
        <h2>{t('compte.dadesTitol')}</h2>
        <p>{t('compte.dadesText')}</p>
        {errorDades && <p role="alert" className="error">{t('compte.dadesError')}</p>}
        <button type="button" className="boto" disabled={baixant} onClick={() => void baixarDades()}>
          {baixant ? t('comu.carregant') : t('compte.dadesBoto')}
        </button>
      </section>

      <section className="compte-seccio compte-perill">
        <h2>{t('compte.esborrarTitol')}</h2>
        <QueEsborra />
        <p>{t('compte.irreversible')}</p>
        <form onSubmit={(e) => void esborrar(e)}>
          <label className="camp">
            <span>{t('compte.escriu', { paraula: PARAULA })}</span>
            <input value={confirmacio} autoComplete="off" onChange={(e) => setConfirmacio(e.target.value)} />
          </label>
          {errorEsborrar && <p role="alert" className="error">{t('compte.esborrarError')}</p>}
          <button type="submit" className="boto perill" disabled={esborrant || confirmacio.trim().toUpperCase() !== PARAULA}>
            {esborrant ? t('compte.esborrant') : t('compte.esborrarBoto')}
          </button>
        </form>
      </section>
    </main>
  );
}

function QueEsborra() {
  const { t } = useTranslation();
  return (
    <>
      <p>{t('compte.esborraEs')}</p>
      <ul>
        <li>{t('compte.esborraCompte')}</li>
        <li>{t('compte.esborraPendents')}</li>
        <li>{t('compte.esborraAvisos')}</li>
      </ul>
      <p>{t('compte.esQueda')}</p>
    </>
  );
}
