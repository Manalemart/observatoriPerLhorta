import { useCallback, useEffect, useMemo, useState, type FormEvent } from 'react';
import { useTranslation } from 'react-i18next';
import { supabase } from '../../lib/supabase';
import type { Dades } from '../mapa/tipus';

interface Usuari {
  id: string;
  email: string;
  nom_public: string | null;
  rol: string;
}

interface Padrinatge {
  id: number;
  perfil_id: string;
  partida_id: number;
  des_de: string;
}

export function Padrinatges({ dades }: { dades: Dades }) {
  const { t, i18n } = useTranslation();
  const [usuaris, setUsuaris] = useState<Usuari[]>([]);
  const [padrinatges, setPadrinatges] = useState<Padrinatge[]>([]);
  const [usuariId, setUsuariId] = useState('');
  const [partidaId, setPartidaId] = useState<number | ''>('');
  const [error, setError] = useState(false);

  const partides = useMemo(() => {
    const totes = dades.partides.features.map((f) => f.properties as { id: number; nom: string; municipi: string });
    return totes.sort((a, b) => `${a.municipi} ${a.nom}`.localeCompare(`${b.municipi} ${b.nom}`, 'ca'));
  }, [dades.partides]);
  const nomPartida = (id: number) => {
    const p = partides.find((x) => x.id === id);
    return p ? `${p.municipi} · ${p.nom}` : String(id);
  };
  const nomUsuari = (id: string) => {
    const u = usuaris.find((x) => x.id === id);
    return u ? `${u.nom_public ?? '—'} (${u.email})` : id;
  };

  const carregar = useCallback(async () => {
    const avui = new Date().toISOString().slice(0, 10);
    const [u, p] = await Promise.all([
      supabase.rpc('usuaris_coordinacio'),
      supabase.from('padrinatges').select('id, perfil_id, partida_id, des_de')
        .or(`fins.is.null,fins.gte.${avui}`).order('des_de', { ascending: false }),
    ]);
    if (u.error || p.error) {
      setError(true);
      return;
    }
    setError(false);
    setUsuaris(u.data as Usuari[]);
    setPadrinatges(p.data as Padrinatge[]);
  }, []);

  useEffect(() => { void carregar(); }, [carregar]);

  const assignar = async (e: FormEvent) => {
    e.preventDefault();
    const { error: err } = await supabase.from('padrinatges').insert({ perfil_id: usuariId, partida_id: partidaId });
    if (err) {
      setError(true);
      return;
    }
    setUsuariId('');
    setPartidaId('');
    await carregar();
  };

  const finalitzar = async (id: number) => {
    const { error: err } = await supabase.rpc('finalitzar_padrinatge', { p_id: id });
    if (err) setError(true);
    else await carregar();
  };

  return (
    <div className="padrinatges">
      <form className="padrinatges-form" onSubmit={(e) => void assignar(e)}>
        <label className="camp">
          <span>{t('padrinatges.persona')}</span>
          <select required value={usuariId} onChange={(e) => setUsuariId(e.target.value)}>
            <option value="">{t('comu.tria')}</option>
            {usuaris.map((u) => <option key={u.id} value={u.id}>{u.nom_public ?? '—'} ({u.email})</option>)}
          </select>
        </label>
        <label className="camp">
          <span>{t('fitxa.partida')}</span>
          <select
            required
            value={partidaId}
            onChange={(e) => setPartidaId(e.target.value ? Number(e.target.value) : '')}
          >
            <option value="">{t('comu.tria')}</option>
            {partides.map((p) => <option key={p.id} value={p.id}>{p.municipi} · {p.nom}</option>)}
          </select>
        </label>
        <button type="submit" className="boto primari">{t('padrinatges.assignar')}</button>
      </form>
      {error && <p role="alert" className="error">{t('comu.errorDesar')}</p>}
      <h2>{t('padrinatges.vigents', { count: padrinatges.length })}</h2>
      {padrinatges.length === 0 && <p className="nota">{t('padrinatges.buit')}</p>}
      <ul className="padrinatges-llista">
        {padrinatges.map((p) => (
          <li key={p.id}>
            <span className="fila-text">
              <strong>{nomPartida(p.partida_id)}</strong>
              <small>{nomUsuari(p.perfil_id)} · {t('padrinatges.desDe', { data: new Date(p.des_de).toLocaleDateString(i18n.language) })}</small>
            </span>
            <button type="button" className="boto" onClick={() => void finalitzar(p.id)}>{t('padrinatges.finalitzar')}</button>
          </li>
        ))}
      </ul>
    </div>
  );
}
