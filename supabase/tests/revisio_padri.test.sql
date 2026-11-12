-- Tests pgTAP de la revisión por el padrí: igual / canviat / no el trobe, sustitución y numeración.
begin;
create extension if not exists pgtap with schema extensions;
select plan(16);

insert into public.municipis (codcat, nom, geom) values
  (99900, 'Municipi de prova', extensions.st_multi(extensions.st_makeenvelope(10.00, 50.00, 10.10, 50.10, 4326)));
insert into public.partides (id, codcat, nom, geom) values
  (99001, 99900, 'Partida A', extensions.st_multi(extensions.st_makeenvelope(10.00, 50.00, 10.05, 50.05, 4326)));
insert into auth.users (id, email) values
  ('00000000-0000-0000-0000-00000000000a', 'autora@test.local'),
  ('00000000-0000-0000-0000-00000000000b', 'padri@test.local'),
  ('00000000-0000-0000-0000-00000000000c', 'coord@test.local');
update public.perfils set rol = 'coordinador' where id = '00000000-0000-0000-0000-00000000000c';
insert into public.padrinatges (perfil_id, partida_id) values ('00000000-0000-0000-0000-00000000000b', 99001);

create function pg_temp.com(p_uid uuid) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('sub', p_uid, 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
$$;
create function pg_temp.historial(p_id uuid, p_accio text) returns int language sql security definer as $$
  select count(*)::int from public.element_historial where element_id = p_id and accio = p_accio;
$$;
create function pg_temp.baixa(p_id uuid) returns text language sql security definer as $$
  select motiu_baixa from public.elements where id = p_id;
$$;
grant execute on function pg_temp.historial(uuid, text) to authenticated;
grant execute on function pg_temp.baixa(uuid) to authenticated;

-- Tres elementos de 2018 validados en la partida
insert into public.elements (id, variable_id, geom, origen, estat, partida_id)
select x.id::uuid, v.id, extensions.st_setsrid(extensions.st_point(x.lon, x.lat), 4326), 'legacy_2018', 'validat', 99001
from public.variables v,
     (values ('50000000-0000-0000-0000-000000000001', 10.01, 50.04),
             ('50000000-0000-0000-0000-000000000002', 10.04, 50.04),
             ('50000000-0000-0000-0000-000000000003', 10.02, 50.01)) as x(id, lon, lat)
where v.nom = 'Alqueria';

-- ─── Permisos ──────────────────────────────────────────────────────────────
select pg_temp.com('00000000-0000-0000-0000-00000000000a');
select throws_ok($$ select public.revisar_element('50000000-0000-0000-0000-000000000001', 'igual') $$,
  '42501', null, 'Qui no és padrí de la partida no la revisa');
select throws_ok($$ select public.confirmar_element('50000000-0000-0000-0000-000000000001') $$,
  '42501', null, 'Tampoc amb «És encara així?» de la web');

-- ─── Numeración ────────────────────────────────────────────────────────────
select pg_temp.com('00000000-0000-0000-0000-00000000000b');
select is(
  (select array_agg((e ->> 'numero')::int order by (e ->> 'numero')::int) from jsonb_array_elements(public.full_de_camp(99001) -> 'elements') e),
  array[1, 2, 3], 'Numerats de l''1 al 3');
select ok(
  (select bool_and(e ->> 'quadre' ~ '^[A-Z][0-9]+$') from jsonb_array_elements(public.full_de_camp(99001) -> 'elements') e),
  'Cada element té quadre');
select is(
  (select e ->> 'id' from jsonb_array_elements(public.full_de_camp(99001) -> 'elements') e where (e ->> 'numero')::int = 1),
  '50000000-0000-0000-0000-000000000001', 'L''1 és el de dalt a l''esquerra');
select is((public.full_de_camp(99001) -> 'partida' ->> 'es_padri')::boolean, true, 'La fulla sap que és el padrí');

-- ─── Igual ─────────────────────────────────────────────────────────────────
select is(public.revisar_element('50000000-0000-0000-0000-000000000001', 'igual', 'Tot bé') ->> 'resultat', 'igual', 'Igual');
select is(pg_temp.historial('50000000-0000-0000-0000-000000000001', 'confirmat'), 1, 'Igual queda a l''historial');

-- ─── No el trobe: baja ─────────────────────────────────────────────────────
select public.revisar_element('50000000-0000-0000-0000-000000000002', 'no_trobat', 'Ja no hi és');
select is(pg_temp.baixa('50000000-0000-0000-0000-000000000002'), 'no_trobat', 'No el trobe: donat de baixa');
select is(
  (select count(*)::int from json_array_elements(public.elements_publics() -> 'features') f
    where f -> 'properties' ->> 'id' = '50000000-0000-0000-0000-000000000002'),
  0, 'Ja no surt al mapa públic');
select is(jsonb_array_length(public.full_de_camp(99001) -> 'elements'), 2, 'Ni a la fulla de la partida');
select throws_ok($$ select public.revisar_element('50000000-0000-0000-0000-000000000002', 'igual') $$,
  '22023', null, 'Un element de baixa no es revisa');
-- La coordinación sí puede editar elementos (RLS): lo que lo impide es la protección
select pg_temp.com('00000000-0000-0000-0000-00000000000c');
select throws_ok($$ update public.elements set baixa_at = null, motiu_baixa = null where id = '50000000-0000-0000-0000-000000000002' $$,
  '42501', null, 'La baixa no es desfà a mà');
select pg_temp.com('00000000-0000-0000-0000-00000000000b');

-- ─── Ha canviat: sustituto que, al validarse, da de baja al antiguo ────────
select public.revisar_element('50000000-0000-0000-0000-000000000003', 'canviat', 'Ara és un magatzem');
select is(pg_temp.historial('50000000-0000-0000-0000-000000000003', 'canviat'), 1, 'Ha canviat queda a l''historial');

select pg_temp.com('00000000-0000-0000-0000-00000000000a');
insert into public.elements (id, variable_id, geom, substitueix_id)
select '50000000-0000-0000-0000-000000000004', v.id, extensions.st_setsrid(extensions.st_point(10.021, 50.011), 4326),
       '50000000-0000-0000-0000-000000000003'
from public.variables v where v.nom = 'Alqueria';

select pg_temp.com('00000000-0000-0000-0000-00000000000b');
select public.canviar_estat('50000000-0000-0000-0000-000000000004', 'validat');
select is(pg_temp.baixa('50000000-0000-0000-0000-000000000003'), 'substituit', 'En validar el nou, l''antic queda substituït');
select is(pg_temp.historial('50000000-0000-0000-0000-000000000003', 'substituit'), 1, 'I consta a l''historial');

select * from finish();
rollback;
