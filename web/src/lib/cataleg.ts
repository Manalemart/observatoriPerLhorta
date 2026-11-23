import { idiomaCurt } from './i18n';

// Noms del catàleg (temes, variables, categories) en l'idioma de la web. El nom de sempre
// (nom, en valencià) és la clau de la simbologia i de les exportacions: no es toca; nom_es
// i nom_en només són per a mostrar (si falten, el valencià). Vegeu la migració cataleg_idiomes.

export interface NomCataleg {
  nom: string;
  nom_es?: string | null;
  nom_en?: string | null;
}

/** Les columnes per a demanar a Supabase un element del catàleg amb els seus noms. */
export const COLS_NOM = 'nom, nom_es, nom_en';

export function nomCat(x: NomCataleg | null | undefined): string {
  if (!x) return '';
  const l = idiomaCurt();
  return (l === 'es' ? x.nom_es : l === 'en' ? x.nom_en : null) ?? x.nom;
}
