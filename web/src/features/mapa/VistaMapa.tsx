import { useCallback, useEffect, useRef, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { useLocation } from 'react-router-dom';
import type { FeatureCollection } from 'geojson';
import { useAuth } from '../../auth/AuthContext';
import { Aportar } from '../aportar/Aportar';
import { FitxaElement } from './FitxaElement';
import { FONS_INICIAL } from './estil';
import { Mapa } from './Mapa';
import { Panell } from './Panell';
import type { Dades, Esborrany, Fons, Variable } from './tipus';

interface Props {
  dades: Dades;
  elements: FeatureCollection;
  recarregarElements: () => void;
  panellObert: boolean;
  onDemanarEntrada: () => void;
}

export function VistaMapa({ dades, elements, recarregarElements, panellObert, onDemanarEntrada }: Props) {
  const { t } = useTranslation();
  const { uid } = useAuth();
  const [fons, setFons] = useState<Fons>(FONS_INICIAL);
  const [variablesActives, setVariablesActives] = useState<Set<number>>(
    () => new Set(dades.temes.flatMap((x) => x.variables.map((v) => v.id))),
  );
  const [veurePartides, setVeurePartides] = useState(true);
  const [veureMunicipis, setVeureMunicipis] = useState(true);
  const [veureSigpac, setVeureSigpac] = useState(false);
  const [seleccio, setSeleccio] = useState<string[]>(() => {
    const id = new URLSearchParams(window.location.search).get('element');
    return id ? [id] : [];
  });
  const [posicio, setPosicio] = useState(0);
  const [aportant, setAportant] = useState(false);
  const [variableCaptura, setVariableCaptura] = useState<Variable | null>(null);
  const [esborrany, setEsborrany] = useState<Esborrany>(null);
  const clicCaptura = useRef<((lng: number, lat: number) => void) | null>(null);

  const onSeleccionar = useCallback((ids: string[]) => {
    setSeleccio(ids);
    setPosicio(0);
  }, []);

  const onVariable = useCallback((v: Variable | null) => {
    setVariableCaptura(v);
    if (v?.geometria === 'parcela') setVeureSigpac(true); // se aporta sobre el recinto
  }, []);
  const registrarClic = useCallback((f: ((lng: number, lat: number) => void) | null) => {
    clicCaptura.current = f;
  }, []);
  const onClicCaptura = useCallback((lng: number, lat: number) => clicCaptura.current?.(lng, lat), []);

  const { key: claveNavegacio } = useLocation();
  useEffect(() => {
    const id = new URLSearchParams(window.location.search).get('element');
    if (id) onSeleccionar([id]);
  }, [claveNavegacio, onSeleccionar]);

  const seleccionat = seleccio[posicio] ?? null;

  // La ficha abierta queda en la URL: se puede compartir un enlace a un elemento
  useEffect(() => {
    const url = new URL(window.location.href);
    if (seleccionat) url.searchParams.set('element', seleccionat);
    else url.searchParams.delete('element');
    window.history.replaceState(null, '', url);
  }, [seleccionat]);

  return (
    <main className="cos">
      <nav className={`panell ${panellObert ? 'obert' : ''}`} aria-label={t('panell.obrir')}>
        <Panell
          dades={dades}
          elements={elements}
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
          elements={elements}
          fons={fons}
          variablesActives={variablesActives}
          veurePartides={veurePartides}
          veureMunicipis={veureMunicipis}
          veureSigpac={veureSigpac}
          seleccionat={seleccionat}
          onSeleccionar={onSeleccionar}
          capturant={!!variableCaptura}
          ignorarClics={aportant}
          onClicCaptura={onClicCaptura}
          esborrany={esborrany}
        />
        {!aportant && (
          <button
            type="button"
            className="boto primari boto-aportar"
            onClick={() => {
              if (!uid) {
                onDemanarEntrada();
                return;
              }
              onSeleccionar([]);
              setAportant(true);
            }}
          >
            {t('aportar.boto')}
          </button>
        )}
        {aportant && (
          <Aportar
            temes={dades.temes}
            onVariable={onVariable}
            onEsborrany={setEsborrany}
            registrarClic={registrarClic}
            onCancelar={() => setAportant(false)}
            onDesat={(id) => {
              setAportant(false);
              recarregarElements();
              onSeleccionar([id]);
            }}
          />
        )}
        {!aportant && seleccionat && (
          <FitxaElement
            id={seleccionat}
            posicio={posicio}
            total={seleccio.length}
            onMoure={(d) => setPosicio((p) => p + d)}
            onTancar={() => onSeleccionar([])}
            onCanvi={recarregarElements}
          />
        )}
      </div>
    </main>
  );
}
