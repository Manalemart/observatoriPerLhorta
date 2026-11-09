-- GeoJSON del mapa precalculado.
--
-- En producción el rol anon tiene statement_timeout = 3 s. Generar al vuelo las
-- partidas (3,8 MB) y los elementos (5,5 MB) costaba ~1,5 s cada uno y, lanzados a la
-- vez por el mapa en la instancia pequeña, pasaban de 3 s → 500. Además cada visita
-- recalculaba lo mismo. Ahora se calcula al escribir, no al leer:
--   · municipis / partides: casi estáticos, se rehacen si cambian.
--   · elements_validats: lo que ve todo el mundo; se rehace cuando cambia un
--     elemento validado (o el catálogo). Lo no validado que alguien pueda ver (lo
--     suyo, su partida, coordinación) se añade al vuelo con la RLS de siempre.

create table public.cache_geojson (
  clau        text primary key check (clau in ('municipis', 'partides', 'elements_validats')),
  dades       jsonb not null,            -- FeatureCollection (municipis, partides) o array de features
  extensio    extensions.geometry,       -- solo elements_validats: extensión de lo que contiene
  actualitzat timestamptz not null default now()
);

alter table public.cache_geojson enable row level security;
create policy cache_geojson_lectura on public.cache_geojson for select to anon, authenticated using (true);
revoke all on public.cache_geojson from anon, authenticated;
grant select on public.cache_geojson to anon, authenticated;   -- datos públicos; solo escribe refrescar_cache_geojson

-- ─── Cálculo (lo que antes hacían las funciones públicas) ──────────────────

create function public._municipis_fc()
returns jsonb
language sql stable
set search_path = public, extensions, pg_temp
as $$
  select jsonb_build_object('type', 'FeatureCollection', 'features', coalesce(jsonb_agg(jsonb_build_object(
    'type', 'Feature',
    'geometry', st_asgeojson(geom, 5)::jsonb,
    'properties', jsonb_build_object('codcat', codcat, 'nom', nom)
  )), '[]'::jsonb))
  from public.municipis;
$$;

create function public._partides_fc()
returns jsonb
language sql stable
set search_path = public, extensions, pg_temp
as $$
  select jsonb_build_object('type', 'FeatureCollection', 'features', coalesce(jsonb_agg(jsonb_build_object(
    'type', 'Feature',
    'geometry', st_asgeojson(p.geom, 6)::jsonb,
    'properties', jsonb_build_object('id', p.id, 'nom', p.nom, 'municipi', m.nom)
  )), '[]'::jsonb))
  from public.partides p
  join public.municipis m on m.codcat = p.codcat;
$$;

-- Array de features. Security invoker: llamada por una persona, la RLS filtra;
-- llamada desde refrescar_cache_geojson (propietario), lo ve todo.
create function public._elements_features(
  p_env extensions.geometry,
  p_tema_id int default null,
  p_variable_id int default null,
  p_estat public.estat_t default null,
  p_sense_validats boolean default false
)
returns jsonb
language sql stable
set search_path = public, extensions, pg_temp
as $$
  select coalesce(jsonb_agg(jsonb_build_object(
    'type', 'Feature',
    'id', e.id,
    'geometry', st_asgeojson(e.geom, 7)::jsonb,
    'properties', jsonb_build_object(
      'id', e.id,                       -- MapLibre descarta los id de Feature que no son numéricos
      'tema_id', v.tema_id, 'tema', t.nom,
      'variable_id', e.variable_id, 'variable', v.nom,
      'categoria', c.nom, 'estat', e.estat, 'origen', e.origen,
      'partida_id', e.partida_id, 'created_at', e.created_at
    )
  )), '[]'::jsonb)
  from public.elements e
  join public.variables v on v.id = e.variable_id
  join public.temes t on t.id = v.tema_id
  left join public.categories c on c.id = e.categoria_id
  where (p_env is null or e.geom && p_env)
    and (p_tema_id is null or v.tema_id = p_tema_id)
    and (p_variable_id is null or e.variable_id = p_variable_id)
    and (p_estat is null or e.estat = p_estat)
    and (not p_sense_validats or e.estat <> 'validat');
$$;

-- ─── Refresco ──────────────────────────────────────────────────────────────

create function public.refrescar_cache_geojson(p_clau text default null)
returns void
language plpgsql security definer
set search_path = public, extensions, pg_temp
as $$
begin
  if p_clau is null or p_clau = 'municipis' then
    insert into public.cache_geojson (clau, dades) values ('municipis', public._municipis_fc())
    on conflict (clau) do update set dades = excluded.dades, actualitzat = now();
  end if;

  if p_clau is null or p_clau in ('municipis', 'partides') then      -- las partidas llevan el nombre del municipio
    insert into public.cache_geojson (clau, dades) values ('partides', public._partides_fc())
    on conflict (clau) do update set dades = excluded.dades, actualitzat = now();
  end if;

  if p_clau is null or p_clau = 'elements_validats' then
    insert into public.cache_geojson (clau, dades, extensio)
    values ('elements_validats',
            public._elements_features(null, null, null, 'validat'),
            (select st_setsrid(st_extent(geom)::geometry, 4326) from public.elements where estat = 'validat'))
    on conflict (clau) do update set dades = excluded.dades, extensio = excluded.extensio, actualitzat = now();
  end if;
end;
$$;

revoke execute on function public.refrescar_cache_geojson(text) from public, anon, authenticated;

-- Triggers por sentencia: una carga masiva (ETL) refresca una vez por lote, no por fila.

create function public._tg_refrescar_cache()
returns trigger
language plpgsql security definer
set search_path = public, pg_temp
as $$
begin
  perform public.refrescar_cache_geojson(tg_argv[0]);
  return null;
end;
$$;

-- En elements solo hace falta si la sentencia toca algo validado (antes o después).
-- Cada consulta va en su propio IF: «vells» no existe en INSERT ni «nous» en DELETE.
create function public._tg_cache_elements()
returns trigger
language plpgsql security definer
set search_path = public, pg_temp
as $$
declare
  v_cal boolean := false;
begin
  if tg_op <> 'INSERT' then
    v_cal := exists (select 1 from vells where estat = 'validat');
  end if;
  if not v_cal and tg_op <> 'DELETE' then
    v_cal := exists (select 1 from nous where estat = 'validat');
  end if;
  if v_cal then
    perform public.refrescar_cache_geojson('elements_validats');
  end if;
  return null;
end;
$$;

revoke execute on function public._tg_refrescar_cache() from public, anon, authenticated;
revoke execute on function public._tg_cache_elements() from public, anon, authenticated;

create trigger cache_municipis after insert or update or delete on public.municipis
  for each statement execute function public._tg_refrescar_cache('municipis');
create trigger cache_partides after insert or update or delete on public.partides
  for each statement execute function public._tg_refrescar_cache('partides');

create trigger cache_elements_ins after insert on public.elements
  referencing new table as nous
  for each statement execute function public._tg_cache_elements();
create trigger cache_elements_upd after update on public.elements
  referencing old table as vells new table as nous
  for each statement execute function public._tg_cache_elements();
create trigger cache_elements_del after delete on public.elements
  referencing old table as vells
  for each statement execute function public._tg_cache_elements();

-- Los nombres y colores del catálogo van dentro de cada feature.
create trigger cache_temes after insert or update or delete on public.temes
  for each statement execute function public._tg_refrescar_cache('elements_validats');
create trigger cache_variables after insert or update or delete on public.variables
  for each statement execute function public._tg_refrescar_cache('elements_validats');
create trigger cache_categories after insert or update or delete on public.categories
  for each statement execute function public._tg_refrescar_cache('elements_validats');

-- ─── Funciones públicas: misma firma, ahora leen la caché ──────────────────

create or replace function public.municipis_geojson()
returns jsonb
language sql stable
set search_path = public, extensions, pg_temp
as $$
  select coalesce((select dades from public.cache_geojson where clau = 'municipis'), public._municipis_fc());
$$;

create or replace function public.partides_geojson()
returns jsonb
language sql stable
set search_path = public, extensions, pg_temp
as $$
  select coalesce((select dades from public.cache_geojson where clau = 'partides'), public._partides_fc());
$$;

create or replace function public.elements_bbox(
  p_minx double precision, p_miny double precision,
  p_maxx double precision, p_maxy double precision,
  p_tema_id int default null,
  p_variable_id int default null,
  p_estat public.estat_t default null
)
returns jsonb
language plpgsql stable
set search_path = public, extensions, pg_temp
as $$
declare
  v_env   geometry := st_makeenvelope(p_minx, p_miny, p_maxx, p_maxy, 4326);
  v_cache public.cache_geojson;
begin
  -- Vía rápida: sin filtros de tema/variable y con una bbox que abarca todo lo validado
  -- (es lo que pide el mapa). Si no, se calcula como siempre.
  if p_tema_id is null and p_variable_id is null and (p_estat is null or p_estat = 'validat') then
    select * into v_cache from public.cache_geojson where clau = 'elements_validats';
    if found and (v_cache.extensio is null or st_covers(v_env, v_cache.extensio)) then
      if p_estat = 'validat' then
        return jsonb_build_object('type', 'FeatureCollection', 'features', v_cache.dades);
      end if;
      -- + lo no validado que esta persona puede ver (RLS); para anon, nada
      return jsonb_build_object('type', 'FeatureCollection', 'features',
        v_cache.dades || public._elements_features(v_env, null, null, null, true));
    end if;
  end if;

  return jsonb_build_object('type', 'FeatureCollection', 'features',
    public._elements_features(v_env, p_tema_id, p_variable_id, p_estat));
end;
$$;

-- Primera carga
select public.refrescar_cache_geojson();
