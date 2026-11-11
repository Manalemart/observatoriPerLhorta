import { useCallback, useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { Link, Navigate, NavLink, Route, Routes, useLocation } from 'react-router-dom';
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
import { Portada } from './features/portada/Portada';
import { useTema } from './lib/tema';
import { Validacio } from './features/validacio/Validacio';

export function App() {
  const { t } = useTranslation();
  const { uid, perfil, potValidar, eixir } = useAuth();
  const { pathname } = useLocation();
  const { tema, canviar: canviarTema } = useTema();
  const [dades, setDades] = useState<Dades | null>(null);
  const [elements, setElements] = useState<FeatureCollection | null>(null);
  const [error, setError] = useState(false);
  const [panellObert, setPanellObert] = useState(false);
  const [entrant, setEntrant] = useState(false);

  // La portada, los textos legales y las noticias no necesitan el inventario (~10 MB):
  // se descarga la primera vez que se entra en una página que lo usa.
  const necessitaDades = !(pathname === '/' || pathname === '/legal' || pathname.startsWith('/noticies'));
  const [demanat, setDemanat] = useState(necessitaDades);
  useEffect(() => { if (necessitaDades) setDemanat(true); }, [necessitaDades]);

  const carregar = useCallback(() => {
    setError(false);
    carregarDades().then(setDades).catch(() => setError(true));
  }, []);
  useEffect(() => { if (demanat) carregar(); }, [demanat, carregar]);

  const recarregarElements = useCallback(() => {
    carregarElements().then(setElements).catch(() => setError(true));
  }, []);
  // Quien inicia sesión ve además sus aportaciones y lo que le toca validar
  useEffect(() => { if (demanat) recarregarElements(); }, [demanat, recarregarElements, uid]);

  useEffect(() => { if (uid) setEntrant(false); }, [uid]);

  const esMapa = pathname === '/mapa';
  const llest = dades && elements;
  // Enlaces anteriores a la portada: el mapa estaba en / (vista en el hash o ?element=)
  const enllacAntic = pathname === '/' && (/^#[\d.]+\//.test(window.location.hash) || window.location.search.includes('element='));

  return (
    <div className="app">
      <header className="capcalera">
        <Link to="/"><img src="/logo.png" alt={t('app.titol')} className="logo" /></Link>
        <nav className="nav-principal" aria-label={t('nav.titol')}>
          <NavLink to="/" end>{t('nav.inici')}</NavLink>
          <NavLink to="/mapa">{t('nav.mapa')}</NavLink>
          <NavLink to="/noticies">{t('nav.noticies')}</NavLink>
          <NavLink to="/comparador">{t('nav.comparador')}</NavLink>
          <NavLink to="/dades">{t('nav.dades')}</NavLink>
          {potValidar && <NavLink to="/validacio">{t('validacio.titol')}</NavLink>}
        </nav>
        <div className="capcalera-accions">
          <button
            type="button"
            className="boto-tema"
            aria-label={t(tema === 'fosc' ? 'tema.aClar' : 'tema.aFosc')}
            title={t(tema === 'fosc' ? 'tema.aClar' : 'tema.aFosc')}
            onClick={canviarTema}
          >
            {tema === 'fosc' ? (
              <svg aria-hidden="true" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                <circle cx="12" cy="12" r="4" /><path d="M12 2v2" /><path d="M12 20v2" /><path d="m4.9 4.9 1.4 1.4" /><path d="m17.7 17.7 1.4 1.4" />
                <path d="M2 12h2" /><path d="M20 12h2" /><path d="m4.9 19.1 1.4-1.4" /><path d="m17.7 6.3 1.4-1.4" />
              </svg>
            ) : (
              <svg aria-hidden="true" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                <path d="M21 12.8A9 9 0 1 1 11.2 3a7 7 0 0 0 9.8 9.8Z" />
              </svg>
            )}
          </button>
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

      {necessitaDades && error && (
        <div className="avis" role="alert">
          <p>{t('estat.error')}</p>
          <button type="button" className="boto" onClick={() => { carregar(); recarregarElements(); }}>{t('estat.reintentar')}</button>
        </div>
      )}
      {necessitaDades && !error && !llest && <div className="avis" role="status"><p>{t('estat.carregant')}</p></div>}

      {enllacAntic && <Navigate to={`/mapa${window.location.search}${window.location.hash}`} replace />}

      {!necessitaDades && !enllacAntic && (
        <Routes>
          <Route path="/" element={<Portada onEntrar={() => setEntrant(true)} />} />
          <Route path="/legal" element={<Legal />} />
          <Route path="/noticies" element={<LlistaNoticies />} />
          <Route path="/noticies/nova" element={<EditorNoticia />} />
          <Route path="/noticies/:id" element={<DetallNoticia />} />
          <Route path="/noticies/:id/edita" element={<EditorNoticia />} />
        </Routes>
      )}

      {necessitaDades && !error && llest && (
        <Routes>
          <Route
            path="/mapa"
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
          <Route path="*" element={<div className="avis"><p>{t('estat.noTrobat')}</p><Link className="boto" to="/">{t('validacio.tornar')}</Link></div>} />
        </Routes>
      )}

      {entrant && <DialegEntrada onTancar={() => setEntrant(false)} />}
      {perfil && !perfil.nom_public && <DialegAlies />}
    </div>
  );
}
