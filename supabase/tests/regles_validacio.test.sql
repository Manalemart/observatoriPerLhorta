-- Tests pgTAP de las reglas de aportación y validación.
-- Ejecutar: npx supabase test db
begin;
create extension if not exists pgtap with schema extensions;
select plan(21);

-- ─── Fixtures ──────────────────────────────────────────────────────────────
-- Municipio y dos partidas en una zona ficticia, lejos de l'Horta: los tests no dependen
-- de que la BD esté vacía o ya tenga los datos cargados (EPSG:4326)
insert into public.municipis (codcat, nom, geom) values
  (99900, 'Municipi de prova', extensions.st_multi(extensions.st_makeenvelope(10.00, 50.00, 10.10, 50.10, 4326)));
insert into public.partides (id, codcat, nom, geom) values
  (99001, 99900, 'Partida A', extensions.st_multi(extensions.st_makeenvelope(10.00, 50.00, 10.05, 50.05, 4326))),
  (99002, 99900, 'Partida B', extensions.st_multi(extensions.st_makeenvelope(10.05, 50.00, 10.10, 50.05, 4326)));

-- Usuarios (el trigger crea los perfils)
insert into auth.users (id, email, raw_user_meta_data) values
  ('00000000-0000-0000-0000-00000000000a', 'ciutada@test.local', '{"nom_public":"Ciutadana"}'),
  ('00000000-0000-0000-0000-00000000000b', 'padri@test.local',   '{}'),
  ('00000000-0000-0000-0000-00000000000c', 'coord@test.local',   '{}'),
  ('00000000-0000-0000-0000-00000000000d', 'padri2@test.local',  '{}');
update public.perfils set rol = 'coordinador' where id = '00000000-0000-0000-0000-00000000000c';
insert into public.padrinatges (perfil_id, partida_id) values
  ('00000000-0000-0000-0000-00000000000b', 99001),
  ('00000000-0000-0000-0000-00000000000d', 99001);

select is((select rol::text from public.perfils where id = '00000000-0000-0000-0000-00000000000b'),
          'padri', 'Un padrinatge vigent converteix l''usuari en padrí');
select is((select count(*)::int from public.perfils where id::text like '00000000-0000-0000-0000-00000000000_'), 4, 'El registre crea el perfil');

create function pg_temp.com(p_uid uuid) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('sub', p_uid, 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
$$;
create function pg_temp.com_anon() returns void language sql as $$
  select set_config('request.jwt.claims', '{"role":"anon"}', true);
  select set_config('role', 'anon', true);
$$;

-- Variable puntual (Construccions / Alqueria) y su categoría
create temp table ids as
  select v.id as var_punt, c.id as cat_punt,
         (select v2.id from public.variables v2 where v2.nom = 'Sèquies') as var_linia
    from public.variables v join public.categories c on c.variable_id = v.id
   where v.nom = 'Alqueria' and c.nom = 'Ben conservat';
grant select on ids to authenticated, anon;

-- ─── Aportación de un ciutadà ──────────────────────────────────────────────
select pg_temp.com('00000000-0000-0000-0000-00000000000a');

insert into public.elements (id, variable_id, categoria_id, geom, estat, autor_id)
select '10000000-0000-0000-0000-000000000001', var_punt, cat_punt,
       extensions.st_setsrid(extensions.st_point(10.02, 50.02), 4326),
       'validat', '00000000-0000-0000-0000-00000000000c'      -- intenta colarse como validado y con otro autor
  from ids;

reset role;
select is((select estat::text from public.elements where id = '10000000-0000-0000-0000-000000000001'),
          'pendent', 'Una aportació nova sempre entra pendent');
select is((select autor_id from public.elements where id = '10000000-0000-0000-0000-000000000001'),
          '00000000-0000-0000-0000-00000000000a'::uuid, 'L''autor és qui aporta, no el que envia el client');
select is((select partida_id from public.elements where id = '10000000-0000-0000-0000-000000000001'),
          99001, 'La partida s''assigna per posició');

select pg_temp.com('00000000-0000-0000-0000-00000000000a');
select throws_ok(
  $$ insert into public.elements (variable_id, geom) select var_punt, extensions.st_setsrid(extensions.st_point(2.0, 41.0), 4326) from ids $$,
  '22023', null, 'No es pot aportar fora de l''àmbit');
select throws_ok(
  $$ insert into public.elements (variable_id, geom) select var_linia, extensions.st_setsrid(extensions.st_point(10.02, 50.02), 4326) from ids $$,
  '22023', null, 'El tipus de geometria ha de correspondre a la variable');
select throws_ok(
  $$ update public.elements set estat = 'validat' where id = '10000000-0000-0000-0000-000000000001' $$,
  '42501', null, 'L''autor no pot canviar l''estat directament');
select throws_ok(
  $$ select public.canviar_estat('10000000-0000-0000-0000-000000000001', 'validat') $$,
  '42501', null, 'Ningú valida les seues pròpies aportacions');
select throws_ok(
  $$ update public.perfils set rol = 'coordinador' where id = auth.uid() $$,
  '42501', null, 'Un usuari no es pot canviar el rol');

-- ─── Visibilidad ───────────────────────────────────────────────────────────
select pg_temp.com_anon();
select is((select count(*)::int from public.elements where partida_id in (99001, 99002)), 0, 'Els anònims no veuen elements pendents');

select pg_temp.com('00000000-0000-0000-0000-00000000000b');
select is((select count(*)::int from public.elements where partida_id in (99001, 99002)), 1, 'El padrí veu els pendents de la seua partida');

-- ─── Validación por padrí ──────────────────────────────────────────────────
select lives_ok(
  $$ select public.canviar_estat('10000000-0000-0000-0000-000000000001', 'rebutjat', 'Foto borrosa') $$,
  'El padrí rebutja a la seua partida');
reset role;
select is((select motiu_rebuig from public.elements where id = '10000000-0000-0000-0000-000000000001'),
          'Foto borrosa', 'Es guarda el motiu del rebuig');

-- El autor corrige → vuelve a pendiente
select pg_temp.com('00000000-0000-0000-0000-00000000000a');
update public.elements set descripcio = 'Nova foto' where id = '10000000-0000-0000-0000-000000000001';
reset role;
select is((select estat::text from public.elements where id = '10000000-0000-0000-0000-000000000001'),
          'pendent', 'Si l''autor corregeix un element rebutjat, torna a pendent');

select pg_temp.com('00000000-0000-0000-0000-00000000000d');
select lives_ok(
  $$ select public.canviar_estat('10000000-0000-0000-0000-000000000001', 'validat') $$,
  'Un altre padrí de la partida valida');

select throws_ok(
  $$ select public.canviar_estat('10000000-0000-0000-0000-000000000001', 'pendent') $$,
  '42501', null, 'Un padrí no pot reobrir un element validat');

-- Fuera de su partida, el padrí no valida
reset role;
insert into public.elements (id, variable_id, geom, autor_id, origen)
select '10000000-0000-0000-0000-000000000002', var_punt,
       extensions.st_setsrid(extensions.st_point(10.08, 50.02), 4326),
       '00000000-0000-0000-0000-00000000000a', 'web' from ids;
select pg_temp.com('00000000-0000-0000-0000-00000000000b');
select throws_ok(
  $$ select public.canviar_estat('10000000-0000-0000-0000-000000000002', 'validat') $$,
  '42501', null, 'El padrí no valida fora de les seues partides');

-- ─── Coordinador ───────────────────────────────────────────────────────────
select pg_temp.com('00000000-0000-0000-0000-00000000000c');
select lives_ok(
  $$ select public.canviar_estat('10000000-0000-0000-0000-000000000001', 'pendent') $$,
  'La coordinació reobri un element validat');

select pg_temp.com_anon();
select is((public.elements_bbox(9.9, 49.9, 10.2, 50.2) -> 'features')::text, '[]',
          'elements_bbox respecta la RLS (anònim sense validats)');

-- ─── Carga del inventario de 2018 ──────────────────────────────────────────
reset role;
select set_config('request.jwt.claims', '', true);
insert into public.elements (id, variable_id, geom, origen, estat, partida_id, legacy_varid)
select '10000000-0000-0000-0000-000000000003', var_punt,
       extensions.st_setsrid(extensions.st_point(10.08, 50.02), 4326),   -- por posición sería la partida B
       'legacy_2018', 'validat', 99001, 'test-legacy' from ids;
select is((select partida_id from public.elements where id = '10000000-0000-0000-0000-000000000003'),
          99001, 'L''inventari de 2018 conserva la partida original');

select * from finish();
rollback;
