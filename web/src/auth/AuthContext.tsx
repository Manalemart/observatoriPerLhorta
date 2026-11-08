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
  recarregarPerfil: () => Promise<void>;
  eixir: () => Promise<void>;
}

const Context = createContext<Valor | null>(null);

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
    return {
      session,
      perfil,
      uid,
      esCoordinador,
      potValidar: esCoordinador || perfil?.rol === 'padri',
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
