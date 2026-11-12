import { useEffect, useMemo, useState, type FormEvent } from 'react';
import { useTranslation } from 'react-i18next';
import { Link } from 'react-router-dom';
import type { Feature, Geometry, Position } from 'geojson';
import { useAuth } from '../../auth/AuthContext';
import { pujarFoto } from '../../lib/fotos';
import { recintEnPunt, type Recinte } from '../../lib/sigpac';
import { supabase } from '../../lib/supabase';
import type { Esborrany, Tema, Variable } from '../mapa/tipus';

const MAX_FOTOS = 5;
const VERTEXS_MINIMS = { linia: 2, poligon: 3 } as const;

interface Props {
  temes: Tema[];
  /** Avisa de qué variable se está dibujando: el mapa captura clics si hay una. */
  onVariable: (v: Variable | null) => void;
  onEsborrany: (e: Esborrany) => void;
  /** Registra quién atiende los clics de captura del mapa. */
  registrarClic: (f: ((lng: number, lat: number) => void) | null) => void;
  onCancelar: () => void;
  onDesat: (id: string) => void;
  /** «Ha canviat»: el elemento que esta aportación sustituirá cuando se valide. */
  substitueixId?: string | null;
}

function geometria(variable: Variable | null, vertexs: Position[], recinte: Recinte | null): Geometry | null {
  if (!variable) return null;
  if (variable.geometria === 'parcela') return recinte?.geometria ?? null;
  if (variable.geometria === 'punt') return vertexs[0] ? { type: 'Point', coordinates: vertexs[0] } : null;
  if (vertexs.length < VERTEXS_MINIMS[variable.geometria]) return null;
  return variable.geometria === 'linia'
    ? { type: 'LineString', coordinates: vertexs }
    : { type: 'Polygon', coordinates: [[...vertexs, vertexs[0]]] };
}

/** Lo que se pinta mientras se dibuja, aunque aún no sea una geometría válida. */
function dibuix(vertexs: Position[], g: Geometry | null): Esborrany {
  if (g) return { type: 'Feature', geometry: g, properties: {} };
  if (!vertexs.length) return null;
  return { type: 'Feature', geometry: { type: 'MultiPoint', coordinates: vertexs }, properties: {} } as Feature<Geometry>;
}

export function Aportar({ temes, onVariable, onEsborrany, registrarClic, onCancelar, onDesat, substitueixId = null }: Props) {
  const { t } = useTranslation();
  const { uid } = useAuth();
  const [temaId, setTemaId] = useState<number | ''>('');
  const [variableId, setVariableId] = useState<number | ''>('');
  const [categoriaId, setCategoriaId] = useState<number | ''>('');
  const [textLliure, setTextLliure] = useState('');
  const [descripcio, setDescripcio] = useState('');
  const [fotos, setFotos] = useState<File[]>([]);
  const [vertexs, setVertexs] = useState<Position[]>([]);
  const [recinte, setRecinte] = useState<Recinte | null>(null);
  const [cercantRecinte, setCercantRecinte] = useState(false);
  const [avisRecinte, setAvisRecinte] = useState<string | null>(null);
  const [enviant, setEnviant] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const tema = temes.find((x) => x.id === temaId) ?? null;
  const variables = useMemo(() => tema?.variables.filter((v) => v.actiu) ?? [], [tema]);
  const variable = variables.find((v) => v.id === variableId) ?? null;
  const categories = variable?.categories.filter((c) => c.actiu) ?? [];
  const geom = useMemo(() => geometria(variable, vertexs, recinte), [variable, vertexs, recinte]);
  const esParcela = variable?.geometria === 'parcela';

  useEffect(() => { onVariable(variable); }, [variable, onVariable]);
  useEffect(() => { onEsborrany(dibuix(vertexs, geom)); }, [vertexs, geom, onEsborrany]);
  useEffect(() => () => { onVariable(null); onEsborrany(null); registrarClic(null); }, [onVariable, onEsborrany, registrarClic]);

  useEffect(() => {
    if (!variable) {
      registrarClic(null);
      return;
    }
    registrarClic((lng, lat) => {
      const punt = [lng, lat];
      if (variable.geometria === 'punt') setVertexs([punt]);
      else if (variable.geometria === 'parcela') {
        setCercantRecinte(true);
        setAvisRecinte(null);
        recintEnPunt(lng, lat)
          .then((r) => {
            setRecinte(r);
            if (!r) setAvisRecinte(t('aportar.senseRecinte'));
          })
          .catch(() => setAvisRecinte(t('aportar.errorSigpac')))
          .finally(() => setCercantRecinte(false));
      } else setVertexs((v) => [...v, punt]);
    });
  }, [variable, registrarClic, t]);

  const reiniciarDibuix = () => {
    setVertexs([]);
    setRecinte(null);
    setAvisRecinte(null);
  };

  const enviar = async (e: FormEvent) => {
    e.preventDefault();
    if (!variable || !geom || !uid) return;
    setEnviant(true);
    setError(null);
    const { data, error: err } = await supabase
      .from('elements')
      .insert({
        variable_id: variable.id,
        categoria_id: categoriaId === '' ? null : categoriaId,
        text_lliure: textLliure.trim() || null,
        descripcio: descripcio.trim() || null,
        geom,
        origen: 'web',
        substitueix_id: substitueixId,
        sigpac_ref: recinte?.ref ?? null,
        sigpac_dn_pk: recinte?.dnPk ?? null,
        sigpac_data: recinte ? new Date().toISOString().slice(0, 10) : null,
      })
      .select('id')
      .single();
    if (err) {
      // Los errores de validación del trigger ya vienen redactados en valenciano
      setError(err.code === '22023' ? err.message : t('comu.errorDesar'));
      setEnviant(false);
      return;
    }
    const id = (data as { id: string }).id;
    const resultats = await Promise.allSettled(fotos.map((f) => pujarFoto(f, uid, id)));
    setEnviant(false);
    if (resultats.some((r) => r.status === 'rejected')) window.alert(t('aportar.errorFotos'));
    onDesat(id);
  };

  return (
    <aside className="fitxa aportar" aria-label={t('aportar.titol')}>
      <button type="button" className="tancar" aria-label={t('comu.cancelar')} onClick={onCancelar}>×</button>
      <h2>{t('aportar.titol')}</h2>
      {substitueixId && <p className="instruccio">{t('aportar.substitueix')}</p>}
      <form onSubmit={(e) => void enviar(e)}>
        <label className="camp">
          <span>{t('fitxa.tema')}</span>
          <select
            required
            value={temaId}
            onChange={(e) => {
              setTemaId(e.target.value ? Number(e.target.value) : '');
              setVariableId('');
              setCategoriaId('');
              reiniciarDibuix();
            }}
          >
            <option value="">{t('comu.tria')}</option>
            {temes.map((x) => <option key={x.id} value={x.id}>{x.nom}</option>)}
          </select>
        </label>

        {tema && (
          <label className="camp">
            <span>{t('aportar.variable')}</span>
            <select
              required
              value={variableId}
              onChange={(e) => {
                setVariableId(e.target.value ? Number(e.target.value) : '');
                setCategoriaId('');
                reiniciarDibuix();
              }}
            >
              <option value="">{t('comu.tria')}</option>
              {variables.map((v) => <option key={v.id} value={v.id}>{v.nom}</option>)}
            </select>
          </label>
        )}

        {variable && categories.length > 0 && (
          <label className="camp">
            <span>{t('fitxa.categoria')}</span>
            <select
              required
              value={categoriaId}
              onChange={(e) => setCategoriaId(e.target.value ? Number(e.target.value) : '')}
            >
              <option value="">{t('comu.tria')}</option>
              {categories.map((c) => <option key={c.id} value={c.id}>{c.nom}</option>)}
            </select>
          </label>
        )}

        {variable && (
          <div className="instruccio" role="status">
            <p>{t(`aportar.instruccio.${variable.geometria}`)}</p>
            {cercantRecinte && <p>{t('aportar.cercantRecinte')}</p>}
            {avisRecinte && <p className="error">{avisRecinte}</p>}
            {recinte && <p>{t('aportar.recinte', { ref: recinte.ref })}</p>}
            {!esParcela && variable.geometria !== 'punt' && (
              <p>{t('aportar.vertexs', { count: vertexs.length })}</p>
            )}
            {!esParcela && geom && variable.geometria === 'punt' && <p>{t('aportar.puntMarcat')}</p>}
            <div className="accions-dibuix">
              {variable.geometria !== 'punt' && !esParcela && (
                <button type="button" className="boto" disabled={!vertexs.length} onClick={() => setVertexs((v) => v.slice(0, -1))}>
                  {t('aportar.desfer')}
                </button>
              )}
              <button type="button" className="boto" disabled={!vertexs.length && !recinte} onClick={reiniciarDibuix}>
                {t('aportar.esborrar')}
              </button>
            </div>
          </div>
        )}

        {variable?.text_lliure && (
          <label className="camp">
            <span>{t('aportar.quin')}</span>
            <input required maxLength={120} value={textLliure} onChange={(e) => setTextLliure(e.target.value)} />
          </label>
        )}

        {variable && (
          <>
            <label className="camp">
              <span>{t('aportar.descripcio')}</span>
              <textarea rows={3} maxLength={2000} value={descripcio} onChange={(e) => setDescripcio(e.target.value)} />
            </label>
            <label className="camp">
              <span>{t('aportar.fotos', { max: MAX_FOTOS })}</span>
              <input
                type="file"
                accept="image/*"
                multiple
                onChange={(e) => setFotos([...(e.target.files ?? [])].slice(0, MAX_FOTOS))}
              />
            </label>
            {fotos.length > 0 && <p className="nota">{t('aportar.fotosTriades', { count: fotos.length })}</p>}
            <p className="nota">
              {t('aportar.llicencia')} <Link to="/legal#condicions" target="_blank">{t('legal.condicions')}</Link>
            </p>
          </>
        )}

        {error && <p role="alert" className="error">{error}</p>}

        <div className="accions-form">
          <button type="button" className="boto" onClick={onCancelar}>{t('comu.cancelar')}</button>
          <button type="submit" className="boto primari" disabled={!geom || enviant}>
            {enviant ? t('aportar.enviant') : t('aportar.enviar')}
          </button>
        </div>
      </form>
    </aside>
  );
}
