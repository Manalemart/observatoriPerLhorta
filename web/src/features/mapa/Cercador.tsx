import { useEffect, useId, useRef, useState, type KeyboardEvent } from 'react';
import { useTranslation } from 'react-i18next';
import { supabase } from '../../lib/supabase';

// Buscador del mapa: municipis i partides per nom (cercar_llocs, en el servidor).
// Combobox accessible: fletxes per a moure's, Intro per a triar, Escape per a tancar.

export interface Lloc {
  tipus: 'municipi' | 'partida';
  id: number;
  nom: string;
  municipi: string | null;
  oest: number;
  sud: number;
  est: number;
  nord: number;
}

const ESPERA_MS = 250;

export function Cercador({ onTriar }: { onTriar: (lloc: Lloc) => void }) {
  const { t } = useTranslation();
  const id = useId();
  const [text, setText] = useState('');
  const [resultats, setResultats] = useState<Lloc[]>([]);
  const [obert, setObert] = useState(false);
  const [actiu, setActiu] = useState(-1);
  const [error, setError] = useState(false);
  const [respost, setRespost] = useState('');
  const peticio = useRef(0);

  useEffect(() => {
    const q = text.trim();
    if (q.length < 2) {
      setResultats([]);
      setError(false);
      return;
    }
    const n = ++peticio.current;
    const temps = setTimeout(async () => {
      const { data, error: err } = await supabase.rpc('cercar_llocs', { p_text: q, p_limit: 8 });
      if (n !== peticio.current) return; // ja s'ha escrit una altra cosa
      setError(!!err);
      setResultats((data ?? []) as Lloc[]);
      setRespost(q);
      setActiu(-1);
    }, ESPERA_MS);
    return () => clearTimeout(temps);
  }, [text]);

  const triar = (l: Lloc) => {
    onTriar(l);
    setText(l.nom);
    setObert(false);
    setResultats([]);
  };

  const tecla = (e: KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'ArrowDown' && resultats.length) {
      e.preventDefault();
      setObert(true);
      setActiu((a) => (a + 1) % resultats.length);
    } else if (e.key === 'ArrowUp' && resultats.length) {
      e.preventDefault();
      setActiu((a) => (a <= 0 ? resultats.length - 1 : a - 1));
    } else if (e.key === 'Enter' && resultats.length) {
      e.preventDefault();
      triar(resultats[Math.max(actiu, 0)]);
    } else if (e.key === 'Escape') {
      setObert(false);
    }
  };

  // Sense resultats encara (esperant la resposta), no es mostra la llista buida
  const mostrar = obert && text.trim().length >= 2 && (resultats.length > 0 || respost === text.trim());

  return (
    <div className="cercador" role="search">
      <svg aria-hidden="true" className="cercador-icona" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round">
        <circle cx="11" cy="11" r="7" /><path d="m20 20-3.5-3.5" />
      </svg>
      <input
        type="search"
        role="combobox"
        aria-label={t('cercador.etiqueta')}
        aria-expanded={mostrar && resultats.length > 0}
        aria-controls={`${id}-llista`}
        aria-activedescendant={actiu >= 0 ? `${id}-${actiu}` : undefined}
        aria-autocomplete="list"
        placeholder={t('cercador.placeholder')}
        value={text}
        onChange={(e) => { setText(e.target.value); setObert(true); }}
        onFocus={() => setObert(true)}
        onBlur={() => setTimeout(() => setObert(false), 150)}
        onKeyDown={tecla}
      />
      {mostrar && (
        <ul id={`${id}-llista`} role="listbox" className="cercador-llista">
          {resultats.map((l, i) => (
            <li
              key={`${l.tipus}-${l.id}`}
              id={`${id}-${i}`}
              role="option"
              aria-selected={i === actiu}
              className={i === actiu ? 'actiu' : undefined}
              onMouseDown={(e) => { e.preventDefault(); triar(l); }}
            >
              <span className="cercador-nom">{l.nom}</span>
              <span className="cercador-tipus">
                {l.tipus === 'municipi' ? t('cercador.municipi') : t('cercador.partida', { municipi: l.municipi ?? '' })}
              </span>
            </li>
          ))}
          {!resultats.length && respost === text.trim() && <li className="cercador-buit" role="presentation">{error ? t('estat.error') : t('cercador.cap')}</li>}
        </ul>
      )}
    </div>
  );
}
