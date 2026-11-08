import type { FeatureCollection } from 'geojson';

export interface Variable {
  id: number;
  nom: string;
  tema_id: number;
}

export interface Tema {
  id: number;
  nom: string;
  color: string;
  variables: Variable[];
}

export interface Dades {
  temes: Tema[];
  elements: FeatureCollection;
  partides: FeatureCollection;
  municipis: FeatureCollection;
}

export interface Fitxa {
  id: string;
  descripcio: string | null;
  text_lliure: string | null;
  estat: 'pendent' | 'validat' | 'rebutjat';
  origen: 'legacy_2018' | 'web' | 'app';
  created_at: string;
  variable: { nom: string; tema: { nom: string; color: string } };
  categoria: { nom: string } | null;
  partida: { nom: string } | null;
  municipi: { nom: string } | null;
  fotos: { id: string; storage_path: string }[];
}

export type Fons = 'topo' | 'pnoa' | 'osm';
