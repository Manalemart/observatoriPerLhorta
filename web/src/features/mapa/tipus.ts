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
  revisat_at: string | null;
  autor_id?: string | null;
  motiu_rebuig: string | null;
  sigpac_ref: string | null;
  variable: { nom: string; tema: { nom: string; color: string } };
  categoria: { nom: string } | null;
  partida: { nom: string } | null;
  municipi: { nom: string } | null;
  fotos: { id: string; storage_path: string }[];
}

export type Fons = 'topo' | 'pnoa';
/** Qué parte del inventario se ve: lo de 2017-2018 sin revisar, lo nuevo o revisado, o todo. */
export type Epoca = 'tot' | '2018' | 'noves';
export type Esborrany = Feature<Geometry> | null;
