import type { Feature, FeatureCollection, Geometry } from 'geojson';

export type GeometriaVariable = 'punt' | 'linia' | 'poligon' | 'parcela';
export type Estat = 'pendent' | 'validat' | 'rebutjat';

export interface Categoria {
  id: number;
  nom: string;
  actiu: boolean;
}

export interface Variable {
  id: number;
  nom: string;
  tema_id: number;
  geometria: GeometriaVariable;
  text_lliure: boolean;
  actiu: boolean;
  categories: Categoria[];
}

export interface Tema {
  id: number;
  nom: string;
  color: string;
  variables: Variable[];
}

/** Lo que no cambia durante la sesión. Los elementos dependen de quién mira: van aparte. */
export interface Dades {
  temes: Tema[];
  partides: FeatureCollection;
  municipis: FeatureCollection;
}

export interface Fitxa {
  id: string;
  descripcio: string | null;
  text_lliure: string | null;
  estat: Estat;
  origen: 'legacy_2018' | 'web' | 'app';
  created_at: string;
  autor_id: string | null;
  motiu_rebuig: string | null;
  sigpac_ref: string | null;
  variable: { nom: string; tema: { nom: string; color: string } };
  categoria: { nom: string } | null;
  partida: { nom: string } | null;
  municipi: { nom: string } | null;
  fotos: { id: string; storage_path: string }[];
}

export type Fons = 'topo' | 'pnoa' | 'osm';
export type Esborrany = Feature<Geometry> | null;
