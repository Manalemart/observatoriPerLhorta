-- GeoJSON del mapa servido tal cual.
--
-- Con la caché de 20261109000002 cada petición aún hacía varias copias de 5,8 MB:
-- leer el jsonb, concatenarle lo no validado, envolverlo en una FeatureCollection y
-- convertirlo a texto. Solo, 0,4 s; con unas cuantas visitas a la vez en la instancia
-- pequeña, más de 3 s → 500 (statement_timeout de anon). Ahora:
--   · la caché guarda cada FeatureCollection ya serializada (json, no jsonb): devolverla
--     es copiar texto;
--   · elements_publics() devuelve lo validado tal cual; lo no validado que alguien puede
--     ver va aparte en elements_no_validats(), pequeño, y solo se pide con sesión;
--   · se piden por GET con Cache-Control: el navegador reutiliza la respuesta.
-- elements_bbox() queda para consultas por zona (la app la usa con bbox pequeñas).

alter table public.cache_geojson alter column dades type json using dades::json;

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

  if p_clau is null or p_clau in ('municipis', 'partides') then      -- las partidas llevan el nombre del municipio
    insert into public.cache_geojson (clau, dades) values ('partides', public._partides_fc()::json)
    on conflict (clau) do update set dades = excluded.dades, actualitzat = now();
  end if;

  if p_clau is null or p_clau = 'elements_validats' then
    insert into public.cache_geojson (clau, dades, extensio)
    values ('elements_validats',
            jsonb_build_object('type', 'FeatureCollection',
                               'features', public._elements_features(null, null, null, 'validat'))::json,
            (select st_setsrid(st_extent(geom)::geometry, 4326) from public.elements where estat = 'validat'))
    on conflict (clau) do update set dades = excluded.dades, extensio = excluded.extensio, actualitzat = now();
  end if;
end;
$$;

revoke execute on function public.refrescar_cache_geojson(text) from public, anon, authenticated;

-- El tipo de retorno cambia (jsonb → json): hay que recrearlas
drop function public.municipis_geojson();
drop function public.partides_geojson();

create function public.municipis_geojson()
returns json
language plpgsql stable
set search_path = public, extensions, pg_temp
as $$
begin
  perform set_config('response.headers', '[{"Cache-Control": "public, max-age=3600"}]', true);
  return coalesce((select dades from public.cache_geojson where clau = 'municipis'), public._municipis_fc()::json);
end;
$$;

create function public.partides_geojson()
returns json
language plpgsql stable
set search_path = public, extensions, pg_temp
as $$
begin
  perform set_config('response.headers', '[{"Cache-Control": "public, max-age=3600"}]', true);
  return coalesce((select dades from public.cache_geojson where clau = 'partides'), public._partides_fc()::json);
end;
$$;

-- Lo validado: igual para todo el mundo
create function public.elements_publics()
returns json
language plpgsql stable
set search_path = public, extensions, pg_temp
as $$
begin
  perform set_config('response.headers', '[{"Cache-Control": "public, max-age=60"}]', true);
  return coalesce(
    (select dades from public.cache_geojson where clau = 'elements_validats'),
    jsonb_build_object('type', 'FeatureCollection',
                       'features', public._elements_features(null, null, null, 'validat'))::json
  );
end;
$$;

-- Lo no validado que esta persona puede ver (RLS: lo suyo, sus partidas, coordinación)
create function public.elements_no_validats()
returns jsonb
language sql stable
set search_path = public, extensions, pg_temp
as $$
  select jsonb_build_object('type', 'FeatureCollection',
                            'features', public._elements_features(null, null, null, null, true));
$$;

grant execute on function public.municipis_geojson() to anon, authenticated;
grant execute on function public.partides_geojson() to anon, authenticated;
grant execute on function public.elements_publics() to anon, authenticated;
grant execute on function public.elements_no_validats() to anon, authenticated;

-- elements_bbox sin vía rápida: la caché ya no es un array de features que concatenar
create or replace function public.elements_bbox(
  p_minx double precision, p_miny double precision,
  p_maxx double precision, p_maxy double precision,
  p_tema_id int default null,
  p_variable_id int default null,
  p_estat public.estat_t default null
)
returns jsonb
language sql stable
set search_path = public, extensions, pg_temp
as $$
  select jsonb_build_object('type', 'FeatureCollection', 'features',
    public._elements_features(st_makeenvelope(p_minx, p_miny, p_maxx, p_maxy, 4326), p_tema_id, p_variable_id, p_estat));
$$;

select public.refrescar_cache_geojson();
