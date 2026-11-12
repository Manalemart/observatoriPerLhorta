import { useState } from 'react';
import { useTranslation } from 'react-i18next';
import type { Fons } from '../mapa/tipus';
import type { Pas, TipusFull } from './fullDeCamp';

/** Genera y descarga una hoja de la partida. El generador (y jsPDF) se cargan al pulsar. */
export function BotoFullDeCamp({ partidaId, tipus, fons, primari = false }: {
  partidaId: number | null; tipus: TipusFull; fons: Fons; primari?: boolean;
}) {
  const { t, i18n } = useTranslation();
  const [pas, setPas] = useState<Pas | null>(null);
  const [error, setError] = useState(false);

  const generar = async () => {
    if (partidaId === null) return;
    setError(false);
    try {
      const { generarFull } = await import('./fullDeCamp');
      const { pdf, nom } = await generarFull(partidaId, tipus, fons, setPas, i18n.language);
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
          {tipus === 'camp'
            ? <><path d="M9 4 3 6v14l6-2 6 2 6-2V4l-6 2-6-2Z" /><path d="M9 4v14" /><path d="M15 6v14" /></>
            : <><path d="M9 6h11" /><path d="M9 12h11" /><path d="M9 18h11" /><path d="m4 6 1 1 2-2" /><path d="m4 12 1 1 2-2" /><path d="m4 18 1 1 2-2" /></>}
        </svg>
        {pas ? t(`fulls.generant.${pas}`) : t(tipus === 'camp' ? 'fulls.botoCamp' : 'fulls.botoRevisio')}
      </button>
      {error && <p role="alert" className="error">{t('fulls.error')}</p>}
    </div>
  );
}
