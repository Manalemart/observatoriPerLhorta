import { useCallback, useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { Link, NavLink, Route, Routes, useLocation } from 'react-router-dom';
import type { FeatureCollection } from 'geojson';
import { useAuth } from './auth/AuthContext';
import { DialegAlies, DialegEntrada } from './auth/Dialegs';
import { carregarDades, carregarElements } from './features/mapa/dades';
import type { Dades } from './features/mapa/tipus';
import { VistaMapa } from './features/mapa/VistaMapa';
import { Comparador } from './features/comparador/Comparador';
import { DadesObertes } from './features/dades/DadesObertes';
import { DetallNoticia, EditorNoticia, LlistaNoticies } from './features/noticies/Noticies';
import { Campana } from './features/notificacions/Campana';
import { Legal } from './features/legal/Legal';
import { Validacio } from './features/validacio/Validacio';

export function App() {
  const { t } = useTranslation();
  const { uid, perfil, potValidar, eixir } = useAuth();
  const { pathname } = useLocation();
  const [dades, setDades] = useState<Dades | null>(null);
  const [elements, setElements] = useState<FeatureCollection | null>(null);
  const [error, setError] = useState(false);
  const [panellObert, setPanellObert] = useState(false);
  const [entrant, setEntrant] = useState(false);

  const carregar = useCallback(() => {
    setError(false);
    carregarDades().then(setDades).catch(() => setError(true));
  }, []);
  useEffect(carregar, [carregar]);

  const recarregarElements = useCallback(() => {
    carregarElements().then(setElements).catch(() => setError(true));
  }, []);
  // Quien inicia sesión ve además sus aportaciones y lo que le toca validar
  useEffect(recarregarElements, [recarregarElements, uid]);

  useEffect(() => { if (uid) setEntrant(false); }, [uid]);

  const esMapa = pathname === '/';
  const llest = dades && elements;

  return (
    <div className="app">
      <header className="capcalera">
        <Link to="/"><img src="/logo.png" alt={t('app.titol')} className="logo" /></Link>
        <nav className="nav-principal" aria-label={t('nav.titol')}>
          <NavLink to="/" end>{t('nav.mapa')}</NavLink>
          <NavLink to="/noticies">{t('nav.noticies')}</NavLink>
          <NavLink to="/comparador">{t('nav.comparador')}</NavLink>
          <NavLink to="/dades">{t('nav.dades')}</NavLink>
          {potValidar && <NavLink to="/validacio">{t('validacio.titol')}</NavLink>}
        </nav>
        <div className="capcalera-accions">
          {llest && esMapa && (
            <button
              type="button"
              className="boto obrir-panell"
              aria-expanded={panellObert}
              onClick={() => setPanellObert(!panellObert)}
            >
              {panellObert ? t('panell.tancar') : t('panell.obrir')}
            </button>
          )}
          {uid ? (
            <>
              <Campana onCanvi={recarregarElements} />
              <span className="usuari">{perfil?.nom_public}</span>
              <button type="button" className="boto" onClick={() => void eixir()}>{t('auth.eixir')}</button>
            </>
          ) : (
            <button type="button" className="boto" onClick={() => setEntrant(true)}>{t('auth.entrar')}</button>
          )}
        </div>
      </header>

      {error && (
        <div className="avis" role="alert">
          <p>{t('estat.error')}</p>
          <button type="button" className="boto" onClick={() => { carregar(); recarregarElements(); }}>{t('estat.reintentar')}</button>
        </div>
      )}
      {!error && !llest && <div className="avis" role="status"><p>{t('estat.carregant')}</p></div>}

      {!error && llest && (
        <Routes>
          <Route
            path="/"
            element={(
              <VistaMapa
                dades={dades}
                elements={elements}
                recarregarElements={recarregarElements}
                panellObert={panellObert}
                onDemanarEntrada={() => setEntrant(true)}
              />
            )}
          />
          <Route path="/validacio" element={<Validacio dades={dades} onCanvi={recarregarElements} />} />
          <Route path="/dades" element={<DadesObertes dades={dades} />} />
          <Route path="/comparador" element={<Comparador />} />
          <Route path="/legal" element={<Legal />} />
          <Route path="/noticies" element={<LlistaNoticies />} />
          <Route path="/noticies/nova" element={<EditorNoticia />} />
          <Route path="/noticies/:id" element={<DetallNoticia />} />
          <Route path="/noticies/:id/edita" element={<EditorNoticia />} />
          <Route path="*" element={<div className="avis"><p>{t('estat.noTrobat')}</p><Link className="boto" to="/">{t('validacio.tornar')}</Link></div>} />
        </Routes>
      )}

      {entrant && <DialegEntrada onTancar={() => setEntrant(false)} />}
      {perfil && !perfil.nom_public && <DialegAlies />}
    </div>
  );
}
