-- Tests pgTAP de la fase 3 de la revisión: fotos, reintentos de la app y avisos al padrí.
begin;
create extension if not exists pgtap with schema extensions;
select plan(13);

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
create function pg_temp.avisos(p_perfil uuid, p_accio text) returns int language sql security definer as $$
  select count(*)::int from public.notificacions where perfil_id = p_perfil and accio = p_accio;
$$;
create function pg_temp.fotos(p_id uuid) returns int language sql security definer as $$
  select count(*)::int from public.element_fotos where element_id = p_id;
$$;
create function pg_temp.historial(p_id uuid) returns int language sql security definer as $$
  select count(*)::int from public.element_historial where element_id = p_id and accio in ('confirmat', 'canviat', 'no_trobat');
$$;
grant execute on function pg_temp.avisos(uuid, text) to authenticated;
grant execute on function pg_temp.fotos(uuid) to authenticated;
grant execute on function pg_temp.historial(uuid) to authenticated;

insert into public.elements (id, variable_id, geom, origen, estat, partida_id)
select x.id::uuid, v.id, extensions.st_setsrid(extensions.st_point(x.lon, x.lat), 4326), 'legacy_2018', 'validat', 99001
from public.variables v,
     (values ('50000000-0000-0000-0000-000000000001', 10.01, 50.04),
             ('50000000-0000-0000-0000-000000000002', 10.04, 50.04)) as x(id, lon, lat)
where v.nom = 'Alqueria';

-- La foto que la app ha subido antes de revisar
insert into storage.objects (bucket_id, name, owner)
values ('fotos', '00000000-0000-0000-0000-00000000000b/50000000-0000-0000-0000-000000000001/rev-1.jpg',
        '00000000-0000-0000-0000-00000000000b');

-- ─── Fotos ─────────────────────────────────────────────────────────────────
select pg_temp.com('00000000-0000-0000-0000-00000000000b');
select throws_ok($$ select public.revisar_element('50000000-0000-0000-0000-000000000001', 'igual', null,
    array['00000000-0000-0000-0000-00000000000b/50000000-0000-0000-0000-000000000001/no-pujada.jpg']) $$,
  '22023', null, 'Una foto que no està pujada no s''accepta');
select throws_ok($$ select public.revisar_element('50000000-0000-0000-0000-000000000001', 'igual', null,
    array['00000000-0000-0000-0000-00000000000a/50000000-0000-0000-0000-000000000001/rev-1.jpg']) $$,
  '22023', null, 'Ni una foto d''una altra carpeta');

select is(public.revisar_element('50000000-0000-0000-0000-000000000001', 'igual', null,
    array['00000000-0000-0000-0000-00000000000b/50000000-0000-0000-0000-000000000001/rev-1.jpg'],
    '70000000-0000-0000-0000-000000000001') ->> 'resultat', 'igual', 'Igual amb foto');
select is(pg_temp.fotos('50000000-0000-0000-0000-000000000001'), 1, 'La foto queda a l''element');
select is(pg_temp.historial('50000000-0000-0000-0000-000000000001'), 1, 'I la revisió a l''historial');

-- ─── Reintento desde la cola del móvil ─────────────────────────────────────
select is(public.revisar_element('50000000-0000-0000-0000-000000000001', 'igual', null,
    array['00000000-0000-0000-0000-00000000000b/50000000-0000-0000-0000-000000000001/rev-1.jpg'],
    '70000000-0000-0000-0000-000000000001') ->> 'repetida', 'true', 'El mateix id no es registra dues vegades');
select is(pg_temp.historial('50000000-0000-0000-0000-000000000001'), 1, 'L''historial no es duplica');

select public.revisar_element('50000000-0000-0000-0000-000000000002', 'no_trobat', null, null, '70000000-0000-0000-0000-000000000002');
select lives_ok($$ select public.revisar_element('50000000-0000-0000-0000-000000000002', 'no_trobat', null, null,
    '70000000-0000-0000-0000-000000000002') $$,
  'Repetir un «no el trobe» que ja va arribar no dona error encara que estiga de baixa');
select is(pg_temp.avisos('00000000-0000-0000-0000-00000000000b', 'revisat'), 0, 'El padrí no s''avisa a si mateix');

-- ─── Avisos al padrí ───────────────────────────────────────────────────────
select pg_temp.com('00000000-0000-0000-0000-00000000000a');
insert into public.elements (variable_id, geom)
select v.id, extensions.st_setsrid(extensions.st_point(10.02, 50.02), 4326)
  from public.variables v where v.nom = 'Alqueria';
select is(pg_temp.avisos('00000000-0000-0000-0000-00000000000b', 'nova_aportacio'), 1,
  'Una aportació nova a la partida avisa el padrí');

select pg_temp.com('00000000-0000-0000-0000-00000000000b');
insert into public.elements (variable_id, geom)
select v.id, extensions.st_setsrid(extensions.st_point(10.03, 50.03), 4326)
  from public.variables v where v.nom = 'Alqueria';
select is(pg_temp.avisos('00000000-0000-0000-0000-00000000000b', 'nova_aportacio'), 1,
  'El que aporta el padrí no l''avisa a ell');

select pg_temp.com('00000000-0000-0000-0000-00000000000c');
select public.confirmar_element('50000000-0000-0000-0000-000000000001');
select is(pg_temp.avisos('00000000-0000-0000-0000-00000000000b', 'revisat'), 1,
  'Si revisa la coordinació, el padrí ho sap');
select is((select motiu from public.notificacions where accio = 'revisat' limit 1), null,
  'Les notificacions d''altri no es veuen (RLS)');

select * from finish();
rollback;
