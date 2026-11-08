import type { FeatureCollection } from 'geojson';
import { supabase } from '../../lib/supabase';
import type { Dades, Fitxa, Tema } from './tipus';

// Bbox del ámbito: el inventario cabe entero en memoria (~6.000 elementos)
const AMBIT = { p_minx: -0.7, p_miny: 39.2, p_maxx: -0.1, p_maxy: 39.8 };

async function rpc(nom: string, args?: Record<string, unknown>): Promise<FeatureCollection> {
  const { data, error } = await supabase.rpc(nom, args);
  if (error) throw error;
  return data as FeatureCollection;
}

export async function carregarDades(): Promise<Dades> {
  const [temes, elements, partides, municipis] = await Promise.all([
    supabase
      .from('temes')
      .select('id, nom, color, variables(id, nom, tema_id)')
      .order('ordre')
      .order('nom', { referencedTable: 'variables' }),
    rpc('elements_bbox', AMBIT),
    rpc('partides_geojson'),
    rpc('municipis_geojson'),
  ]);
  if (temes.error) throw temes.error;
  return { temes: temes.data as unknown as Tema[], elements, partides, municipis };
}

export async function carregarFitxa(id: string): Promise<Fitxa> {
  const { data, error } = await supabase
    .from('elements')
    .select(`id, descripcio, text_lliure, estat, origen, created_at,
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
