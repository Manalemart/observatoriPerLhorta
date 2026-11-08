import { useCallback, useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { carregarDades } from './features/mapa/dades';
import { FitxaElement } from './features/mapa/FitxaElement';
import { FONS_INICIAL } from './features/mapa/estil';
import { Mapa } from './features/mapa/Mapa';
import { Panell } from './features/mapa/Panell';
import type { Dades, Fons } from './features/mapa/tipus';

export function App() {
  const { t } = useTranslation();
  const [dades, setDades] = useState<Dades | null>(null);
  const [error, setError] = useState(false);
  const [fons, setFons] = useState<Fons>(FONS_INICIAL);
  const [variablesActives, setVariablesActives] = useState<Set<number>>(new Set());
  const [veurePartides, setVeurePartides] = useState(true);
  const [veureMunicipis, setVeureMunicipis] = useState(true);
  const [veureSigpac, setVeureSigpac] = useState(false);
  const [seleccionat, setSeleccionat] = useState<string | null>(null);
  const [panellObert, setPanellObert] = useState(false);

  const carregar = useCallback(() => {
    setError(false);
    carregarDades()
      .then((d) => {
        setDades(d);
        setVariablesActives(new Set(d.temes.flatMap((x) => x.variables.map((v) => v.id))));
      })
      .catch(() => setError(true));
  }, []);

  useEffect(carregar, [carregar]);

  return (
    <div className="app">
      <header className="capcalera">
        <img src="/logo.png" alt={t('app.titol')} className="logo" />
        <span className="promou">{t('app.promou')}</span>
        {dades && (
          <button
            type="button"
            className="obrir-panell"
            aria-expanded={panellObert}
            onClick={() => setPanellObert(!panellObert)}
          >
            {panellObert ? t('panell.tancar') : t('panell.obrir')}
          </button>
        )}
      </header>

      {error && (
        <div className="avis" role="alert">
          <p>{t('estat.error')}</p>
          <button type="button" onClick={carregar}>{t('estat.reintentar')}</button>
        </div>
      )}
      {!error && !dades && <div className="avis" role="status"><p>{t('estat.carregant')}</p></div>}

      {dades && (
        <main className="cos">
          <nav className={`panell ${panellObert ? 'obert' : ''}`} aria-label={t('panell.obrir')}>
            <Panell
              dades={dades}
              fons={fons}
              onFons={setFons}
              variablesActives={variablesActives}
              onVariablesActives={setVariablesActives}
              veurePartides={veurePartides}
              onPartides={setVeurePartides}
              veureMunicipis={veureMunicipis}
              onMunicipis={setVeureMunicipis}
              veureSigpac={veureSigpac}
              onSigpac={setVeureSigpac}
            />
          </nav>
          <div className="zona-mapa">
            <Mapa
              dades={dades}
              fons={fons}
              variablesActives={variablesActives}
              veurePartides={veurePartides}
              veureMunicipis={veureMunicipis}
              veureSigpac={veureSigpac}
              seleccionat={seleccionat}
              onSeleccionar={setSeleccionat}
            />
            {seleccionat && <FitxaElement id={seleccionat} onTancar={() => setSeleccionat(null)} />}
          </div>
        </main>
      )}
    </div>
  );
}
