-- Tests pgTAP de la caché de GeoJSON del mapa.
begin;
create extension if not exists pgtap with schema extensions;
select plan(16);

-- ─── Fixtures (zona ficticia, como en los otros tests) ─────────────────────
insert into public.municipis (codcat, nom, geom) values
  (99900, 'Municipi de prova', extensions.st_multi(extensions.st_makeenvelope(10.00, 50.00, 10.10, 50.10, 4326)));
insert into public.partides (id, codcat, nom, geom) values
  (99001, 99900, 'Partida A', extensions.st_multi(extensions.st_makeenvelope(10.00, 50.00, 10.05, 50.05, 4326)));
insert into auth.users (id, email) values
  ('00000000-0000-0000-0000-00000000000a', 'autora@test.local'),
  ('00000000-0000-0000-0000-00000000000b', 'padri@test.local'),
  ('00000000-0000-0000-0000-00000000000d', 'altra@test.local');
insert into public.padrinatges (perfil_id, partida_id) values ('00000000-0000-0000-0000-00000000000b', 99001);

create function pg_temp.com(p_uid uuid) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('sub', p_uid, 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
$$;
create function pg_temp.com_anon() returns void language sql as $$
  select set_config('request.jwt.claims', '{"role":"anon"}', true);
  select set_config('role', 'anon', true);
$$;
create function pg_temp.reset_rol() returns void language sql as $$
  select set_config('request.jwt.claims', '', true);
  select set_config('role', 'postgres', true);
$$;
-- Lo que pide el mapa web: lo público (caché) + lo no validado que se puede ver
create function pg_temp.mapa() returns setof text language sql as $$
  select f -> 'properties' ->> 'id' from json_array_elements(public.elements_publics() -> 'features') f
  union all
  select f -> 'properties' ->> 'id' from jsonb_array_elements(public.elements_no_validats() -> 'features') f;
$$;
grant execute on function pg_temp.mapa() to anon, authenticated;

create temp table ids as select v.id as var_punt from public.variables v where v.nom = 'Alqueria';
grant select on ids to authenticated, anon;

-- ─── Territorio ────────────────────────────────────────────────────────────
select ok(
  exists (select 1 from json_array_elements(public.partides_geojson() -> 'features') f
          where f -> 'properties' ->> 'nom' = 'Partida A'),
  'Una partida nova entra a la memòria cau');
update public.municipis set nom = 'Municipi reanomenat' where codcat = 99900;
select is(
  (select f -> 'properties' ->> 'municipi' from json_array_elements(public.partides_geojson() -> 'features') f
   where f -> 'properties' ->> 'nom' = 'Partida A'),
  'Municipi reanomenat', 'Reanomenar un municipi refresca també les partides');

-- ─── Elementos ─────────────────────────────────────────────────────────────
select pg_temp.com('00000000-0000-0000-0000-00000000000a');
insert into public.elements (id, variable_id, geom)
select '20000000-0000-0000-0000-000000000001', var_punt, extensions.st_setsrid(extensions.st_point(10.02, 50.02), 4326) from ids;
insert into public.elements (id, variable_id, geom)
select '20000000-0000-0000-0000-000000000002', var_punt, extensions.st_setsrid(extensions.st_point(10.03, 50.02), 4326) from ids;

select pg_temp.com_anon();
select is((select count(*)::int from pg_temp.mapa() where mapa like '20000000%'), 0, 'Anònim: els pendents no es veuen');

select pg_temp.com('00000000-0000-0000-0000-00000000000a');
select is((select count(*)::int from pg_temp.mapa() where mapa like '20000000%'), 2, 'L''autora veu els seus pendents');

select pg_temp.com('00000000-0000-0000-0000-00000000000b');
select public.canviar_estat('20000000-0000-0000-0000-000000000001', 'validat');

select pg_temp.com_anon();
select is(
  (select array_agg(mapa) from pg_temp.mapa() where mapa like '20000000%'),
  array['20000000-0000-0000-0000-000000000001'], 'Validar el posa a la memòria cau pública');
select is(
  (select f -> 'properties' ->> 'estat'
   from json_array_elements(public.elements_publics() -> 'features') f
   where f -> 'properties' ->> 'id' = '20000000-0000-0000-0000-000000000001'),
  'validat', 'La feature duu l''estat');

select pg_temp.com('00000000-0000-0000-0000-00000000000d');
select is((select count(*)::int from pg_temp.mapa() where mapa like '20000000%'), 1, 'Una altra persona només veu el validat');

select pg_temp.com('00000000-0000-0000-0000-00000000000a');
select is(
  (select count(*)::int from pg_temp.mapa() where mapa like '20000000%'), 2,
  'L''autora: validat (memòria cau) + pendent propi (al vol), sense duplicats');

-- Bbox parcial o filtros: cálculo al vuelo, mismo resultado
select pg_temp.com_anon();
select is(
  (select count(*)::int from jsonb_array_elements(public.elements_bbox(10.0, 50.0, 10.025, 50.05) -> 'features')),
  1, 'Bbox parcial: es calcula al vol');
select is(
  (select count(*)::int from jsonb_array_elements(public.elements_bbox(10.025, 50.0, 10.1, 50.05) -> 'features')),
  0, 'Bbox parcial: el pendent continua amagat');

-- Reabrir (coordinación) lo saca de la caché
select pg_temp.reset_rol();
update public.perfils set rol = 'coordinador' where id = '00000000-0000-0000-0000-00000000000d';
select pg_temp.com('00000000-0000-0000-0000-00000000000d');
select public.canviar_estat('20000000-0000-0000-0000-000000000001', 'pendent');
select pg_temp.com_anon();
select is((select count(*)::int from pg_temp.mapa() where mapa like '20000000%'), 0, 'Reobrir el trau de la memòria cau');

-- ─── Lo que se sirve tal cual ─────────────────────────────────────────────
select pg_temp.com_anon();
select is(json_typeof(public.partides_geojson() -> 'features'), 'array', 'Les partides surten com a FeatureCollection');
select is(
  (select count(*)::int from jsonb_array_elements(public.elements_no_validats() -> 'features')),
  0, 'Un anònim no rep cap element no validat');

-- ─── Permisos ──────────────────────────────────────────────────────────────
select throws_ok($$ select public.refrescar_cache_geojson() $$, '42501', null, 'Un anònim no pot refrescar');
select throws_ok($$ insert into public.cache_geojson (clau, dades) values ('municipis', '{}') $$, '42501', null,
  'Un anònim no pot escriure a la memòria cau');
select pg_temp.com('00000000-0000-0000-0000-00000000000a');
select throws_ok($$ update public.cache_geojson set dades = '[]' $$, '42501', null,
  'Una persona registrada tampoc');

select * from finish();
rollback;
