import { createContext, useCallback, useContext, useEffect, useMemo, useState, type ReactNode } from 'react';
import type { Session } from '@supabase/supabase-js';
import { supabase } from '../lib/supabase';

export type Rol = 'ciutada' | 'padri' | 'coordinador' | 'admin';

export interface Perfil {
  id: string;
  nom_public: string | null;
  rol: Rol;
}

interface Valor {
  session: Session | null;
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
  const [perfil, setPerfil] = useState<Perfil | null>(null);
  const uid = session?.user.id ?? null;

  useEffect(() => {
    void supabase.auth.getSession().then(({ data }) => setSession(data.session));
    const { data } = supabase.auth.onAuthStateChange((_event, s) => setSession(s));
    return () => data.subscription.unsubscribe();
  }, []);

  const recarregarPerfil = useCallback(async () => {
    if (!uid) {
      setPerfil(null);
      return;
    }
    const { data } = await supabase.from('perfils').select('id, nom_public, rol').eq('id', uid).single();
    setPerfil(data as Perfil | null);
  }, [uid]);

  useEffect(() => { void recarregarPerfil(); }, [recarregarPerfil]);

  const valor = useMemo<Valor>(() => {
    const esCoordinador = perfil?.rol === 'coordinador' || perfil?.rol === 'admin';
    const partides = partidesDelToken(session?.access_token);
    return {
      session,
      perfil,
      uid,
      esCoordinador,
      potValidar: esCoordinador || perfil?.rol === 'padri',
      partides,
      potRevisar: (id) => esCoordinador || (id != null && partides.includes(id)),
      recarregarPerfil,
      eixir: async () => { await supabase.auth.signOut(); },
    };
  }, [session, perfil, uid, recarregarPerfil]);

  return <Context.Provider value={valor}>{children}</Context.Provider>;
}

export function useAuth(): Valor {
  const valor = useContext(Context);
  if (!valor) throw new Error('useAuth fora de AuthProvider');
  return valor;
}
