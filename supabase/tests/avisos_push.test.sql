-- Tests pgTAP dels avisos push: registrar i oblidar dispositius, permisos i el trigger.
begin;
create extension if not exists pgtap with schema extensions;
select plan(13);

insert into auth.users (id, email) values
  ('00000000-0000-0000-0000-00000000000a', 'a@test.local'),
  ('00000000-0000-0000-0000-00000000000b', 'b@test.local');

create function pg_temp.com(p_uid uuid) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('sub', p_uid, 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
$$;
create function pg_temp.anonim() returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('role', 'anon')::text, true);
  select set_config('role', 'anon', true);
$$;

-- ─── Permisos ──────────────────────────────────────────────────────────────
select pg_temp.anonim();
select throws_ok($$select public.registrar_dispositiu(repeat('x', 40), 'android')$$, '42501', null, 'un anònim no registra res');
reset role;

select pg_temp.com('00000000-0000-0000-0000-00000000000a');
select throws_ok($$select public.registrar_dispositiu('curt', 'android')$$, '22023', null, 'un token massa curt no val');
select lives_ok($$select public.registrar_dispositiu(repeat('a', 40), 'android', 'es')$$, 'A registra el seu mòbil');
select is((select count(*)::int from public.dispositius_push), 1, 'A veu el seu dispositiu');
select is((select idioma from public.dispositius_push), 'es', 'amb el seu idioma');
select public.registrar_dispositiu(repeat('a', 40), 'android', 'en');
select is((select idioma from public.dispositius_push), 'en', 'també en anglés');
select public.registrar_dispositiu(repeat('a', 40), 'android', 'fr');
select is((select idioma from public.dispositius_push), 'ca', 'un idioma que no hi és: valencià');
select throws_ok($$insert into public.dispositius_push (token, perfil_id, plataforma) values (repeat('z', 40), '00000000-0000-0000-0000-00000000000b', 'ios')$$,
  '42501', null, 'no es pot inserir directament');
reset role;

-- El mateix mòbil, ara amb el compte de B: el token passa a B
select pg_temp.com('00000000-0000-0000-0000-00000000000b');
select is((select count(*)::int from public.dispositius_push), 0, 'B no veu els dispositius d''A');
select lives_ok($$select public.registrar_dispositiu(repeat('a', 40), 'android')$$, 'B registra el mateix token');
reset role;
select is((select perfil_id from public.dispositius_push where token = repeat('a', 40)),
  '00000000-0000-0000-0000-00000000000b'::uuid, 'el token ara és de B');

-- ─── El trigger: sense configuració en el Vault, l'aviso es crea igual ─────
insert into public.municipis (codcat, nom, geom) values
  (99900, 'Municipi de prova', extensions.st_multi(extensions.st_makeenvelope(10.00, 50.00, 10.10, 50.10, 4326)));
insert into public.elements (id, variable_id, geom, origen, estat)
select '70000000-0000-0000-0000-000000000001', v.id, extensions.st_setsrid(extensions.st_point(10.01, 50.01), 4326), 'legacy_2018', 'validat'
from public.variables v where v.nom = 'Alqueria';
select lives_ok($$insert into public.notificacions (perfil_id, element_id, accio)
  values ('00000000-0000-0000-0000-00000000000b', '70000000-0000-0000-0000-000000000001', 'validat')$$,
  'un aviso nou no falla encara que no hi haja configuració de push');

-- ─── Esborrar el compte esborra els seus dispositius ───────────────────────
select set_config('request.jwt.claims', '', true);
delete from auth.users where id = '00000000-0000-0000-0000-00000000000b';
select is((select count(*)::int from public.dispositius_push), 0, 'sense compte, sense dispositius');

select * from finish();
rollback;
