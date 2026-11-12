-- GeoJSON del mapa más ligero: de ~10 MB a ~3,5 MB entre elementos y partidas.
--
-- Aun en caché y servidas tal cual, varias descargas simultáneas de 4-6 MB saturan la
-- instancia de Supabase cuando la caché del CDN está vacía (cada nodo del CDN tiene la
-- suya). Menos bytes = menos tiempo por petición. Solo cambia lo que dibuja el mapa web:
--   · elementos: solo las propiedades que usa el mapa (id, tema_id, variable_id, estat,
--     per_revisar); los nombres ya están en el catálogo. Polígonos simplificados ~1 m.
--   · partidas: contorno simplificado ~1 m, 5 decimales (~1 m).
-- La ficha, la app (elements_bbox) y las hojas de campo usan la geometría completa.

create or replace function public._partides_fc()
returns jsonb
language sql stable
set search_path = public, extensions, pg_temp
as $$
  select jsonb_build_object('type', 'FeatureCollection', 'features', coalesce(jsonb_agg(jsonb_build_object(
    'type', 'Feature',
    'geometry', st_asgeojson(st_simplifypreservetopology(p.geom, 0.00001), 5)::jsonb,
    'properties', jsonb_build_object('id', p.id, 'nom', p.nom, 'municipi', m.nom)
  )), '[]'::jsonb))
  from public.partides p
  join public.municipis m on m.codcat = p.codcat;
$$;

-- Solo lo validado, con lo mínimo para pintar y filtrar
create function public._elements_publics_fc()
returns json
language sql stable
set search_path = public, extensions, pg_temp
as $$
  select json_build_object('type', 'FeatureCollection', 'features', coalesce(json_agg(json_build_object(
    'type', 'Feature',
    'geometry', st_asgeojson(
      case when geometrytype(e.geom) like '%POLYGON' then st_simplifypreservetopology(e.geom, 0.00001) else e.geom end,
      6)::json,
    'properties', json_build_object(
      'id', e.id, 'tema_id', v.tema_id, 'variable_id', e.variable_id, 'estat', e.estat,
      'per_revisar', e.origen = 'legacy_2018' and e.revisat_at is null
    )
  )), '[]'::json))
  from public.elements e
  join public.variables v on v.id = e.variable_id
  where e.estat = 'validat';
$$;

-- Sin revoke: solo devuelve lo validado y elements_publics() la usa si falta la caché

create or replace function public.refrescar_cache_geojson(p_clau text default null)
returns void
language plpgsql security definer
set search_path = public, extensions, pg_temp
as $$
begin
  if p_clau is null or p_clau = 'municipis' then
    insert into public.cache_geojson (clau, dades) values ('municipis', public._municipis_fc()::json)
    on conflict (clau) do update set dades = excluded.dades, actualitzat = now();
  end if;

  if p_clau is null or p_clau in ('municipis', 'partides') then
    insert into public.cache_geojson (clau, dades) values ('partides', public._partides_fc()::json)
    on conflict (clau) do update set dades = excluded.dades, actualitzat = now();
  end if;

  if p_clau is null or p_clau = 'elements_validats' then
    insert into public.cache_geojson (clau, dades, extensio)
    values ('elements_validats', public._elements_publics_fc(),
            (select st_setsrid(st_extent(geom)::geometry, 4326) from public.elements where estat = 'validat'))
    on conflict (clau) do update set dades = excluded.dades, extensio = excluded.extensio, actualitzat = now();
  end if;
end;
$$;

revoke execute on function public.refrescar_cache_geojson(text) from public, anon, authenticated;

create or replace function public.elements_publics()
returns json
language plpgsql stable
set search_path = public, extensions, pg_temp
as $$
begin
  perform set_config('response.headers', '[{"Cache-Control": "public, max-age=60"}]', true);
  return coalesce((select dades from public.cache_geojson where clau = 'elements_validats'), public._elements_publics_fc());
end;
$$;

select public.refrescar_cache_geojson();
