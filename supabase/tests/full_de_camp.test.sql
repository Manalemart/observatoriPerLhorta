-- Tests pgTAP de la hoja de campo.
begin;
create extension if not exists pgtap with schema extensions;
select plan(7);

insert into public.municipis (codcat, nom, geom) values
  (99900, 'Municipi de prova', extensions.st_multi(extensions.st_makeenvelope(10.00, 50.00, 10.10, 50.10, 4326)));
insert into public.partides (id, codcat, nom, geom) values
  (99001, 99900, 'Partida A', extensions.st_multi(extensions.st_makeenvelope(10.00, 50.00, 10.05, 50.05, 4326))),
  (99002, 99900, 'Partida B', extensions.st_multi(extensions.st_makeenvelope(10.05, 50.00, 10.10, 50.05, 4326)));
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
create function pg_temp.n(p jsonb) returns int language sql as $$ select jsonb_array_length(p -> 'elements') $$;
grant execute on function pg_temp.n(jsonb) to anon, authenticated;

-- Uno de 2018 (validado) y uno nuevo pendiente en la partida A; otro en la B
insert into public.elements (id, variable_id, geom, origen, estat, partida_id)
select '40000000-0000-0000-0000-000000000001', v.id, extensions.st_setsrid(extensions.st_point(10.02, 50.02), 4326),
       'legacy_2018', 'validat', 99001
from public.variables v where v.nom = 'Alqueria';
insert into public.elements (id, variable_id, geom, origen, estat, partida_id)
select '40000000-0000-0000-0000-000000000003', v.id, extensions.st_setsrid(extensions.st_point(10.07, 50.02), 4326),
       'legacy_2018', 'validat', 99002
from public.variables v where v.nom = 'Alqueria';
select pg_temp.com('00000000-0000-0000-0000-00000000000a');
insert into public.elements (id, variable_id, geom)
select '40000000-0000-0000-0000-000000000002', v.id, extensions.st_setsrid(extensions.st_point(10.03, 50.02), 4326)
from public.variables v where v.nom = 'Alqueria';

-- ─── Contenido ─────────────────────────────────────────────────────────────
select pg_temp.com('00000000-0000-0000-0000-00000000000b');
select is(public.full_de_camp(99001) -> 'partida' ->> 'nom', 'Partida A', 'Duu la partida');
select is(public.full_de_camp(99001) -> 'partida' ->> 'municipi', 'Municipi de prova', 'Duu el municipi');
select is(pg_temp.n(public.full_de_camp(99001)), 2, 'El padrí veu el validat i el pendent de la seua partida');
select ok(
  (select bool_and(jsonb_array_length(e -> 'etiqueta') = 2) from jsonb_array_elements(public.full_de_camp(99001) -> 'elements') e),
  'Cada element duu on posar-li el número');
select is(
  (select (e ->> 'per_revisar')::boolean from jsonb_array_elements(public.full_de_camp(99001) -> 'elements') e
   where e ->> 'id' = '40000000-0000-0000-0000-000000000001'),
  true, 'El de 2018 surt per revisar');

-- Otra persona sin padrinazgo: solo lo validado
select pg_temp.com('00000000-0000-0000-0000-00000000000d');
select is(pg_temp.n(public.full_de_camp(99001)), 1, 'Sense padrinatge només surt el validat');

select pg_temp.com_anon();
select throws_ok($$ select public.full_de_camp(99001) $$, '42501', null, 'Cal sessió');

select * from finish();
rollback;
