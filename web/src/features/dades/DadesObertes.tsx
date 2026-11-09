import { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { supabase } from '../../lib/supabase';
import { colorDelTema, descarregar } from './descarrega';
import type { Dades } from '../mapa/tipus';

interface Fila {
  nom: string;
  n: number;
}

interface Resum {
  total: number;
  per_tema: Fila[];
  per_municipi: Fila[];
}

function Barres({ titol, files, color }: { titol: string; files: Fila[]; color: (nom: string) => string }) {
  const { i18n } = useTranslation();
  const fmt = new Intl.NumberFormat(i18n.language);
  const maxim = Math.max(...files.map((f) => f.n), 1);
  return (
    <section className="grafica">
      <h2>{titol}</h2>
      <table>
        <tbody>
          {files.map((f) => (
            <tr key={f.nom}>
              <th scope="row">{f.nom}</th>
              <td className="barra-cel" aria-hidden="true">
                <span className="barra" style={{ width: `${(f.n / maxim) * 100}%`, background: color(f.nom) }} />
              </td>
              <td className="recompte">{fmt.format(f.n)}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </section>
  );
}

export function DadesObertes({ dades }: { dades: Dades }) {
  const { t, i18n } = useTranslation();
  const [resum, setResum] = useState<Resum | null>(null);
  const [error, setError] = useState(false);
  const [tema, setTema] = useState('');
  const [municipi, setMunicipi] = useState('');
  const [baixant, setBaixant] = useState<string | null>(null);
  const [errorBaixada, setErrorBaixada] = useState(false);

  useEffect(() => {
    void supabase.rpc('resum_inventari').then(({ data, error: err }) => {
      if (err) setError(true);
      else setResum(data as Resum);
    });
  }, []);

  const baixar = async (format: 'geojson' | 'csv') => {
    setBaixant(format);
    setErrorBaixada(false);
    try {
      await descarregar(format, { tema, municipi });
    } catch {
      setErrorBaixada(true);
    } finally {
      setBaixant(null);
    }
  };

  const url = `${import.meta.env.VITE_SUPABASE_URL as string}/rest/v1/dades_obertes`;
  const municipis = dades.municipis.features
    .map((f) => (f.properties as { nom: string }).nom)
    .sort((a, b) => a.localeCompare(b, 'ca'));
  const fmt = new Intl.NumberFormat(i18n.language);

  return (
    <main className="pagina">
      <h1>{t('dades.titol')}</h1>
      <p>{t('dades.intro', { total: resum ? fmt.format(resum.total) : '…' })}</p>
      {error && <p role="alert" className="error">{t('dades.error')}</p>}

      <section className="targeta">
        <h2>{t('dades.descarrega')}</h2>
        <div className="filtres">
          <label className="camp">
            <span>{t('fitxa.tema')}</span>
            <select value={tema} onChange={(e) => setTema(e.target.value)}>
              <option value="">{t('dades.tots')}</option>
              {dades.temes.map((x) => <option key={x.id} value={x.nom}>{x.nom}</option>)}
            </select>
          </label>
          <label className="camp">
            <span>{t('fitxa.municipi')}</span>
            <select value={municipi} onChange={(e) => setMunicipi(e.target.value)}>
              <option value="">{t('dades.tots')}</option>
              {municipis.map((m) => <option key={m} value={m}>{m}</option>)}
            </select>
          </label>
        </div>
        <div className="accions-dibuix">
          <button type="button" className="boto primari" disabled={!!baixant} onClick={() => void baixar('geojson')}>
            {baixant === 'geojson' ? t('dades.baixant') : 'GeoJSON'}
          </button>
          <button type="button" className="boto primari" disabled={!!baixant} onClick={() => void baixar('csv')}>
            {baixant === 'csv' ? t('dades.baixant') : 'CSV'}
          </button>
        </div>
        {errorBaixada && <p role="alert" className="error">{t('dades.errorBaixada')}</p>}
        <p className="nota">{t('dades.llicencia')}</p>
      </section>

      {resum && (
        <div className="grafiques">
          <Barres titol={t('dades.perTema')} files={resum.per_tema} color={(nom) => colorDelTema(dades.temes, nom)} />
          <Barres titol={t('dades.perMunicipi')} files={resum.per_municipi} color={() => 'var(--marca)'} />
        </div>
      )}

      <section className="targeta">
        <h2>{t('dades.api')}</h2>
        <p>{t('dades.apiIntro')}</p>
        <pre><code>{`curl "${url}?tema=eq.Construccions&limit=10" \\
  -H "apikey: <clau pública>"

# CSV
curl "${url}?limit=1000" -H "apikey: <clau pública>" -H "Accept: text/csv"

# GeoJSON
curl "${url}?municipi=eq.Paiporta" -H "apikey: <clau pública>" -H "Accept: application/geo+json"`}</code></pre>
        <p className="nota">{t('dades.apiPaginacio')}</p>
      </section>
    </main>
  );
}
