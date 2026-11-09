import { useCallback, useEffect, useRef, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../../auth/AuthContext';
import { supabase } from '../../lib/supabase';

interface Notificacio {
  id: number;
  element_id: string;
  accio: 'validat' | 'rebutjat' | 'reobert';
  motiu: string | null;
  llegida: boolean;
  created_at: string;
  element: { text_lliure: string | null; variable: { nom: string } };
}

const INTERVAL_MS = 60_000;
const MAXIM = 20;

export function Campana({ onCanvi }: { onCanvi: () => void }) {
  const { t, i18n } = useTranslation();
  const { uid } = useAuth();
  const navegar = useNavigate();
  const [items, setItems] = useState<Notificacio[]>([]);
  const [obert, setObert] = useState(false);
  const contenidor = useRef<HTMLDivElement>(null);
  const noLlegides = items.filter((n) => !n.llegida).length;
  const previes = useRef(0);

  const carregar = useCallback(async () => {
    const { data } = await supabase
      .from('notificacions')
      .select('id, element_id, accio, motiu, llegida, created_at, element:elements(text_lliure, variable:variables(nom))')
      .order('created_at', { ascending: false })
      .limit(MAXIM);
    if (!data) return;
    const noves = data as unknown as Notificacio[];
    setItems(noves);
    // Un cambio de estado nuevo también cambia lo que se ve en el mapa
    const n = noves.filter((x) => !x.llegida).length;
    if (n > previes.current) onCanvi();
    previes.current = n;
  }, [onCanvi]);

  useEffect(() => {
    if (!uid) return;
    void carregar();
    const interval = window.setInterval(() => void carregar(), INTERVAL_MS);
    return () => window.clearInterval(interval);
  }, [uid, carregar]);

  useEffect(() => {
    if (!obert) return;
    const fora = (e: MouseEvent) => {
      if (!contenidor.current?.contains(e.target as Node)) setObert(false);
    };
    document.addEventListener('mousedown', fora);
    return () => document.removeEventListener('mousedown', fora);
  }, [obert]);

  const obrir = async (n: Notificacio) => {
    setObert(false);
    if (!n.llegida) {
      await supabase.from('notificacions').update({ llegida: true }).eq('id', n.id);
      await carregar();
    }
    navegar(`/?element=${n.element_id}`);
  };

  return (
    <div className="campana" ref={contenidor}>
      <button
        type="button"
        className="boto"
        aria-expanded={obert}
        aria-label={t('notificacions.titol', { count: noLlegides })}
        onClick={() => setObert(!obert)}
      >
        <span aria-hidden="true">🔔</span>
        {noLlegides > 0 && <span className="insignia" aria-hidden="true">{noLlegides}</span>}
      </button>
      {obert && (
        <div className="campana-llista">
          {!items.length && <p className="nota">{t('notificacions.buit')}</p>}
          <ul>
            {items.map((n) => (
              <li key={n.id}>
                <button type="button" className={`fila ${n.llegida ? '' : 'activa'}`} onClick={() => void obrir(n)}>
                  <span className="fila-text">
                    <strong>{n.element.text_lliure ?? n.element.variable.nom}</strong>
                    <small>
                      {t(`notificacions.accio.${n.accio}`)} · {new Date(n.created_at).toLocaleDateString(i18n.language)}
                    </small>
                    {n.motiu && <small>{n.motiu}</small>}
                  </span>
                </button>
              </li>
            ))}
          </ul>
        </div>
      )}
    </div>
  );
}
