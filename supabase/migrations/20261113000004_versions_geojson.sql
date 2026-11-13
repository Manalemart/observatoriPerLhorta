-- Versión de cada capa del mapa, para que el CDN no sirva datos viejos.
--
-- El GeoJSON del mapa lo reparte el CDN de Vercel (web/api/geo) con caché larga. Al
-- cambiar una partida o validar un elemento, la copia del CDN seguía viva hasta una hora.
-- Ahora la web pregunta primero esto (unos bytes) y pide /api/geo/<capa>?v=<versión>:
-- cada versión es una URL distinta en la caché, y una actualización se ve en la carga
-- siguiente.

create function public.versions_geojson()
returns json
language plpgsql stable
set search_path = public, pg_temp
as $$
begin
  -- Que nadie la guarde: es lo que dice si hay datos nuevos
  perform set_config('response.headers', '[{"Cache-Control": "no-store"}]', true);
  return (
    select coalesce(json_object_agg(clau, floor(extract(epoch from actualitzat))::bigint), '{}'::json)
      from public.cache_geojson
  );
end;
$$;

grant execute on function public.versions_geojson() to anon, authenticated;
