import { useState } from 'react';
import { useTranslation } from 'react-i18next';
import type { Fons } from '../mapa/tipus';
import type { Pas } from './fullDeCamp';

/** Genera y descarga la hoja de campo de una partida. El generador (y jsPDF) se cargan al pulsar. */
export function BotoFullDeCamp({ partidaId, fons, primari = false }: { partidaId: number | null; fons: Fons; primari?: boolean }) {
  const { t, i18n } = useTranslation();
  const [pas, setPas] = useState<Pas | null>(null);
  const [error, setError] = useState(false);

  const generar = async () => {
    if (partidaId === null) return;
    setError(false);
    try {
      const { generarFullDeCamp } = await import('./fullDeCamp');
      const { pdf, nom } = await generarFullDeCamp(partidaId, fons, setPas, i18n.language);
      const url = URL.createObjectURL(pdf);
      const enllac = document.createElement('a');
      enllac.href = url;
      enllac.download = nom;
      enllac.click();
      setTimeout(() => URL.revokeObjectURL(url), 10000);
    } catch (e) {
      console.error(e);
      setError(true);
    } finally {
      setPas(null);
    }
  };

  return (
    <div className="full-camp">
      <button
        type="button"
        className={`boto ${primari ? 'primari' : 'contorn'}`}
        disabled={partidaId === null || pas !== null}
        aria-busy={pas !== null}
        onClick={() => void generar()}
      >
        <svg aria-hidden="true" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
          <path d="M6 9V3h12v6" /><rect x="3" y="9" width="18" height="8" rx="2" /><path d="M6 14h12v7H6Z" />
        </svg>
        {pas ? t(`fulls.generant.${pas}`) : t('fulls.boto')}
      </button>
      {error && <p role="alert" className="error">{t('fulls.error')}</p>}
    </div>
  );
}
