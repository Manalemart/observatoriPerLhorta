import { createContext, useCallback, useContext, useEffect, useMemo, useState, type ReactNode } from 'react';
import type { Session } from '@supabase/supabase-js';
import { useTranslation } from 'react-i18next';
import { idiomaCurt } from '../lib/i18n';
import { supabase } from '../lib/supabase';

export type Rol = 'ciutada' | 'padri' | 'coordinador' | 'admin';

export interface Perfil {
  id: string;
  nom_public: string | null;
  rol: Rol;
  /** Recibe el resumen diario de avisos por correo. */
  resum_correu: boolean;
  /** Idioma dels correus i els avisos push ('ca', 'es' o 'en'). */
  idioma: 'ca' | 'es' | 'en';
}

interface Valor {
  session: Session | null;
  /** Ja se sap si hi ha sessió (al principi es llig de l'emmagatzematge, de manera asíncrona). */
  sessioLlesta: boolean;
  perfil: Perfil | null;
  uid: string | null;
  esCoordinador: boolean;
  potValidar: boolean;
  /** Partidas apadrinadas ahora (del token: las pone custom_access_token_hook). */
  partides: number[];
  /** Puede revisar el inventario de esta partida: su padrí o la coordinación. */
  potRevisar: (partidaId: number | null | undefined) => boolean;
  recarregarPerfil: () => Promise<void>;
  eixir: () => Promise<void>;
}

const Context = createContext<Valor | null>(null);

function partidesDelToken(token: string | undefined): number[] {
  if (!token) return [];
  try {
    const carrega = JSON.parse(atob(token.split('.')[1].replace(/-/g, '+').replace(/_/g, '/')));
    const p = carrega?.app_metadata?.partides;
    return Array.isArray(p) ? p.filter((x): x is number => typeof x === 'number') : [];
  } catch {
    return [];
  }
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [session, setSession] = useState<Session | null>(null);
  const [sessioLlesta, setSessioLlesta] = useState(false);
  const [perfil, setPerfil] = useState<Perfil | null>(null);
  const uid = session?.user.id ?? null;

  useEffect(() => {
    void supabase.auth.getSession().then(({ data }) => { setSession(data.session); setSessioLlesta(true); });
    const { data } = supabase.auth.onAuthStateChange((_event, s) => setSession(s));
    return () => data.subscription.unsubscribe();
  }, []);

  const recarregarPerfil = useCallback(async () => {
    if (!uid) {
      setPerfil(null);
      return;
    }
    const { data } = await supabase.from('perfils').select('id, nom_public, rol, resum_correu, idioma').eq('id', uid).single();
    setPerfil(data as Perfil | null);
  }, [uid]);

  useEffect(() => { void recarregarPerfil(); }, [recarregarPerfil]);

  // Els correus i els avisos push ixen en l'idioma que es veu en la web
  const { i18n } = useTranslation();
  const idioma = idiomaCurt(i18n.language);
  useEffect(() => {
    if (!perfil || perfil.idioma === idioma) return;
    void supabase.from('perfils').update({ idioma }).eq('id', perfil.id).then(({ error }) => {
      if (!error) setPerfil((p) => (p && p.id === perfil.id ? { ...p, idioma } : p));
    });
  }, [perfil, idioma]);

  const valor = useMemo<Valor>(() => {
    const esCoordinador = perfil?.rol === 'coordinador' || perfil?.rol === 'admin';
    const partides = partidesDelToken(session?.access_token);
    return {
      session,
      sessioLlesta,
      perfil,
      uid,
      esCoordinador,
      potValidar: esCoordinador || perfil?.rol === 'padri',
      partides,
      potRevisar: (id) => esCoordinador || (id != null && partides.includes(id)),
      recarregarPerfil,
      eixir: async () => { await supabase.auth.signOut(); },
    };
  }, [session, sessioLlesta, perfil, uid, recarregarPerfil]);

  return <Context.Provider value={valor}>{children}</Context.Provider>;
}

export function useAuth(): Valor {
  const valor = useContext(Context);
  if (!valor) throw new Error('useAuth fora de AuthProvider');
  return valor;
}
