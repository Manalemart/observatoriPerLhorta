import type { FeatureCollection } from 'geojson';
import { supabase } from '../../lib/supabase';
import type { Dades, Fitxa, Tema } from './tipus';

// El inventario cabe entero en memoria (~7.000 elementos). Lo público se pide por GET:
// la base de datos lo devuelve ya serializado y el navegador lo puede reutilizar.
async function rpc(nom: string): Promise<FeatureCollection> {
  const { data, error } = await supabase.rpc(nom, undefined, { get: true });
  if (error) throw error;
  return data as FeatureCollection;
}

export async function carregarDades(): Promise<Dades> {
  const [temes, partides, municipis] = await Promise.all([
    supabase
      .from('temes')
      .select('id, nom, color, variables(id, nom, tema_id, geometria, text_lliure, actiu, categories(id, nom, actiu))')
      .order('ordre')
      .order('nom', { referencedTable: 'variables' }),
    rpc('partides_geojson'),
    rpc('municipis_geojson'),
  ]);
  if (temes.error) throw temes.error;
  return { temes: temes.data as unknown as Tema[], partides, municipis };
}

/**
 * Lo validado (igual para todo el mundo) y, con sesión, lo no validado que la RLS deja
 * ver a esta persona: lo suyo, lo de sus partidas o todo si coordina.
 */
export async function carregarElements(ambSessio: boolean): Promise<FeatureCollection> {
  const [publics, propis] = await Promise.all([
    rpc('elements_publics'),
    ambSessio ? rpc('elements_no_validats') : Promise.resolve(null),
  ]);
  if (!propis?.features.length) return publics;
  return { type: 'FeatureCollection', features: [...publics.features, ...propis.features] };
}

/** autor_id solo se puede pedir con sesión: la API se lo niega a los anónimos. */
export async function carregarFitxa(id: string, ambSessio: boolean): Promise<Fitxa> {
  const { data, error } = await supabase
    .from('elements')
    .select(`id, descripcio, text_lliure, estat, origen, created_at, revisat_at, ${ambSessio ? 'autor_id, ' : ''}motiu_rebuig, sigpac_ref,
      variable:variables(nom, tema:temes(nom, color)),
      categoria:categories(nom),
      partida:partides(nom),
      municipi:municipis(nom),
      fotos:element_fotos(id, storage_path)`)
    .eq('id', id)
    .single();
  if (error) throw error;
  return data as unknown as Fitxa;
}

export function urlFoto(storagePath: string): string {
  return supabase.storage.from('fotos').getPublicUrl(storagePath).data.publicUrl;
}
