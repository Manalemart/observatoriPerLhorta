-- Tests pgTAP de la revisión del inventario de 2018.
begin;
create extension if not exists pgtap with schema extensions;
select plan(13);

insert into public.municipis (codcat, nom, geom) values
  (99900, 'Municipi de prova', extensions.st_multi(extensions.st_makeenvelope(10.00, 50.00, 10.10, 50.10, 4326)));
insert into public.partides (id, codcat, nom, geom) values
  (99001, 99900, 'Partida A', extensions.st_multi(extensions.st_makeenvelope(10.00, 50.00, 10.05, 50.05, 4326)));
insert into auth.users (id, email) values
  ('00000000-0000-0000-0000-00000000000a', 'autora@test.local'),
  ('00000000-0000-0000-0000-00000000000b', 'padri@test.local');
insert into public.padrinatges (perfil_id, partida_id) values ('00000000-0000-0000-0000-00000000000b', 99001);

create function pg_temp.com(p_uid uuid) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('sub', p_uid, 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
$$;
create function pg_temp.com_anon() returns void language sql as $$
  select set_config('request.jwt.claims', '{"role":"anon"}', true);
  select set_config('role', 'anon', true);
$$;
-- El historial tiene RLS: los recuentos de control se leen como administrador
create function pg_temp.confirmacions(p_id uuid) returns int language sql security definer as $$
  select count(*)::int from public.element_historial where element_id = p_id and accio = 'confirmat';
$$;
grant execute on function pg_temp.confirmacions(uuid) to anon, authenticated;
create function pg_temp.per_revisar(p_id text) returns boolean language sql as $$
  select (f -> 'properties' ->> 'per_revisar')::boolean
  from jsonb_array_elements(public.elements_bbox(-180, -90, 180, 90) -> 'features') f
  where f -> 'properties' ->> 'id' = p_id;
$$;
grant execute on function pg_temp.per_revisar(text) to anon, authenticated;

-- Un elemento de 2018 (carga sin sesión, como el ETL) y uno nuevo pendiente
insert into public.elements (id, variable_id, geom, origen, estat, partida_id)
select '30000000-0000-0000-0000-000000000001', v.id, extensions.st_setsrid(extensions.st_point(10.02, 50.02), 4326),
       'legacy_2018', 'validat', 99001
from public.variables v where v.nom = 'Alqueria';

select pg_temp.com('00000000-0000-0000-0000-00000000000a');
insert into public.elements (id, variable_id, geom)
select '30000000-0000-0000-0000-000000000002', v.id, extensions.st_setsrid(extensions.st_point(10.03, 50.02), 4326)
from public.variables v where v.nom = 'Alqueria';

-- ─── Estado inicial ────────────────────────────────────────────────────────
select pg_temp.com_anon();
select ok(pg_temp.per_revisar('30000000-0000-0000-0000-000000000001'), 'El de 2018 està per revisar');
select is((public.resum_revisio() ->> 'per_revisar')::int, 1, 'Resum: 1 per revisar');
select is((public.resum_revisio() ->> 'partides_apadrinades')::int, 1, 'Resum: 1 partida apadrinada');
select throws_ok($$ select public.confirmar_element('30000000-0000-0000-0000-000000000001') $$, '42501', null,
  'Un anònim no pot confirmar');

-- ─── Confirmar ─────────────────────────────────────────────────────────────
select pg_temp.com('00000000-0000-0000-0000-00000000000a');
select throws_ok($$ select public.confirmar_element('30000000-0000-0000-0000-000000000002') $$, '22023', null,
  'Un pendent no es confirma');
select throws_ok($$ update public.elements set revisat_at = now() where id = '30000000-0000-0000-0000-000000000002' $$,
  '42501', null, 'revisat_at no es toca a mà');
select pg_temp.com('00000000-0000-0000-0000-00000000000b');   -- només revisa el padrí
select isnt(public.confirmar_element('30000000-0000-0000-0000-000000000001'), null, 'Confirmar torna la data');
select is(
  pg_temp.confirmacions('30000000-0000-0000-0000-000000000001'),
  1, 'Queda a l''historial');
select public.confirmar_element('30000000-0000-0000-0000-000000000001');
select is(
  pg_temp.confirmacions('30000000-0000-0000-0000-000000000001'),
  1, 'Repetir-ho el mateix mes no duplica');
select is(
  (select estat::text from public.elements where id = '30000000-0000-0000-0000-000000000001'),
  'validat', 'Confirmar no canvia l''estat');

select pg_temp.com_anon();
select ok(not pg_temp.per_revisar('30000000-0000-0000-0000-000000000001'), 'Al mapa ja no està per revisar');
select is((public.resum_revisio() ->> 'revisats')::int, 1, 'Resum: 1 revisat');
select is((public.resum_revisio() ->> 'partides_amb_revisio')::int, 1, 'Resum: la partida té revisions');

select * from finish();
rollback;
