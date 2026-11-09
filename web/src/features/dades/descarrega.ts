import { supabase } from '../../lib/supabase';
import type { Tema } from '../mapa/tipus';

const MIDA_PAGINA = 1000; // límite de filas por petición de la API
const COLUMNES = ['id', 'tema', 'variable', 'categoria', 'text_lliure', 'descripcio', 'municipi', 'partida', 'origen', 'sigpac_ref', 'data_alta', 'lat', 'lon'] as const;
const ATRIBUCIO = "Observatori Ciutadà de l'Horta — Per l'Horta. CC BY 4.0";

type Fila = Record<(typeof COLUMNES)[number], string | number | null> & { geom: GeoJSON.Geometry };

export function colorDelTema(temes: Tema[], nom: string): string {
  return temes.find((t) => t.nom === nom)?.color ?? '#888888';
}

async function totesLesFiles(filtres: { tema: string; municipi: string }): Promise<Fila[]> {
  const files: Fila[] = [];
  for (let desde = 0; ; desde += MIDA_PAGINA) {
    let consulta = supabase
      .from('dades_obertes')
      .select('*')
      .order('id')
      .range(desde, desde + MIDA_PAGINA - 1);
    if (filtres.tema) consulta = consulta.eq('tema', filtres.tema);
    if (filtres.municipi) consulta = consulta.eq('municipi', filtres.municipi);
    const { data, error } = await consulta;
    if (error) throw error;
    files.push(...(data as Fila[]));
    if (data.length < MIDA_PAGINA) return files;
  }
}

/** Comillas alrededor de lo que lo necesite, y una protección contra fórmulas al abrirlo en Excel. */
export function campCsv(valor: string | number | null): string {
  if (valor === null) return '';
  if (typeof valor === 'number') return String(valor);
  const net = /^[=+\-@\t\r]/.test(valor) ? `'${valor}` : valor;
  return /[",\n\r]/.test(net) ? `"${net.replaceAll('"', '""')}"` : net;
}

function guardar(contingut: string, tipus: string, nom: string) {
  const url = URL.createObjectURL(new Blob([contingut], { type: tipus }));
  const a = document.createElement('a');
  a.href = url;
  a.download = nom;
  a.click();
  URL.revokeObjectURL(url);
}

export async function descarregar(format: 'geojson' | 'csv', filtres: { tema: string; municipi: string }) {
  const files = await totesLesFiles(filtres);
  if (format === 'csv') {
    const linies = [COLUMNES.join(','), ...files.map((f) => COLUMNES.map((c) => campCsv(f[c])).join(','))];
    guardar(`﻿${linies.join('\r\n')}\r\n`, 'text/csv;charset=utf-8', 'observatori-horta.csv');
    return;
  }
  guardar(
    JSON.stringify({
      type: 'FeatureCollection',
      attribution: ATRIBUCIO,
      features: files.map(({ geom, ...propietats }) => ({ type: 'Feature', geometry: geom, properties: propietats })),
    }),
    'application/geo+json',
    'observatori-horta.geojson',
  );
}
