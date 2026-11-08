import { useEffect, useRef, useState, type FormEvent, type ReactNode } from 'react';
import { useTranslation } from 'react-i18next';
import { supabase } from '../lib/supabase';
import { useAuth } from './AuthContext';

// Google solo aparece cuando el proveedor está configurado en Supabase
const AMB_GOOGLE = import.meta.env.VITE_AUTH_GOOGLE === 'true';

function Dialeg({ titol, onTancar, children }: { titol: string; onTancar?: () => void; children: ReactNode }) {
  const ref = useRef<HTMLDialogElement>(null);
  useEffect(() => {
    const d = ref.current;
    if (d && !d.open) d.showModal();
  }, []);
  return (
    <dialog
      ref={ref}
      className="dialeg"
      onCancel={(e) => { if (onTancar) onTancar(); else e.preventDefault(); }}
    >
      <h2>{titol}</h2>
      {children}
    </dialog>
  );
}

export function DialegEntrada({ onTancar }: { onTancar: () => void }) {
  const { t } = useTranslation();
  const [email, setEmail] = useState('');
  const [enviat, setEnviat] = useState(false);
  const [enviant, setEnviant] = useState(false);
  const [error, setError] = useState(false);
  const retorn = window.location.origin + window.location.pathname;

  const enviar = async (e: FormEvent) => {
    e.preventDefault();
    setEnviant(true);
    setError(false);
    const { error: err } = await supabase.auth.signInWithOtp({ email, options: { emailRedirectTo: retorn } });
    setEnviant(false);
    if (err) setError(true);
    else setEnviat(true);
  };

  return (
    <Dialeg titol={t('auth.entrar')} onTancar={onTancar}>
      {enviat ? (
        <p role="status">{t('auth.revisaCorreu', { email })}</p>
      ) : (
        <form onSubmit={(e) => void enviar(e)}>
          <p>{t('auth.explicacio')}</p>
          <label className="camp">
            <span>{t('auth.correu')}</span>
            <input type="email" required autoComplete="email" value={email} onChange={(e) => setEmail(e.target.value)} />
          </label>
          {error && <p role="alert" className="error">{t('auth.error')}</p>}
          <button type="submit" className="boto primari" disabled={enviant}>{t('auth.enviarEnllac')}</button>
          {AMB_GOOGLE && (
            <button
              type="button"
              className="boto"
              onClick={() => void supabase.auth.signInWithOAuth({ provider: 'google', options: { redirectTo: retorn } })}
            >
              {t('auth.google')}
            </button>
          )}
        </form>
      )}
      <div className="dialeg-peu">
        <button type="button" className="boto" onClick={onTancar}>{t('comu.tancar')}</button>
      </div>
    </Dialeg>
  );
}

/** Primer acceso: sin alias, la coordinación y la comunidad no sabrían quién es. */
export function DialegAlies() {
  const { t } = useTranslation();
  const { uid, recarregarPerfil } = useAuth();
  const [nom, setNom] = useState('');
  const [error, setError] = useState(false);

  const desar = async (e: FormEvent) => {
    e.preventDefault();
    const { error: err } = await supabase.from('perfils').update({ nom_public: nom.trim() }).eq('id', uid!);
    if (err) setError(true);
    else await recarregarPerfil();
  };

  return (
    <Dialeg titol={t('auth.benvinguda')}>
      <form onSubmit={(e) => void desar(e)}>
        <p>{t('auth.aliesExplicacio')}</p>
        <label className="camp">
          <span>{t('auth.alies')}</span>
          <input required maxLength={40} value={nom} onChange={(e) => setNom(e.target.value)} />
        </label>
        {error && <p role="alert" className="error">{t('comu.errorDesar')}</p>}
        <button type="submit" className="boto primari" disabled={!nom.trim()}>{t('comu.desar')}</button>
      </form>
    </Dialeg>
  );
}
