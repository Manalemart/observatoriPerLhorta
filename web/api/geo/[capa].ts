// GeoJSON público del mapa, servido desde la caché del CDN de Vercel.
//
// Son 4-6 MB por capa. Servirlos desde Supabase en cada visita satura la instancia
// pequeña: con unas cuantas visitas a la vez las consultas pasan del statement_timeout
// de anon (3 s) aunque solo devuelvan un texto guardado. Aquí se piden una vez cada
// pocos minutos y el CDN los reparte comprimidos; mientras se renuevan, sirve la copia
// anterior (stale-while-revalidate).
//
// Solo estas tres capas, sin parámetros: no es un proxy abierto a la API.

const CAPES: Record<string, { rpc: string; segons: number }> = {
  elements: { rpc: 'elements_publics', segons: 120 },   // cambia al validar
  partides: { rpc: 'partides_geojson', segons: 3600 },
  municipis: { rpc: 'municipis_geojson', segons: 86400 },
};

export async function GET(request: Request): Promise<Response> {
  const adreca = new URL(request.url);
  const capa = adreca.pathname.split('/').pop() ?? '';
  // ?v=<versión> (segundos de la última actualización, de versions_geojson()): esa URL no
  // cambiará nunca de contenido, así que se guarda sin caducidad. Sin v, caché corta.
  const versio = adreca.searchParams.get('v');
  if (versio !== null && !/^\d{1,12}$/.test(versio)) return new Response('Versió no vàlida', { status: 400 });
  const config = CAPES[capa];
  if (!config) return new Response('Capa desconeguda', { status: 404 });

  const url = process.env.VITE_SUPABASE_URL;
  const clau = process.env.VITE_SUPABASE_ANON_KEY;
  if (!url || !clau) return new Response('Falta la configuració de Supabase', { status: 500 });

  const resposta = await fetch(`${url}/rest/v1/rpc/${config.rpc}`, {
    headers: { apikey: clau, Authorization: `Bearer ${clau}`, Accept: 'application/json' },
  });
  if (!resposta.ok) {
    // Sin caché: que el siguiente intento vuelva a preguntar
    return new Response(await resposta.text(), {
      status: 502,
      headers: { 'Content-Type': 'application/json', 'Cache-Control': 'no-store' },
    });
  }

  return new Response(await resposta.text(), {
    headers: {
      'Content-Type': 'application/json; charset=utf-8',
      'Cache-Control': versio
        ? 'public, max-age=31536000, immutable'
        // s-maxage: CDN; max-age corto en el navegador para ver pronto lo recién validado
        : `public, max-age=60, s-maxage=${config.segons}, stale-while-revalidate=86400`,
    },
  });
}
