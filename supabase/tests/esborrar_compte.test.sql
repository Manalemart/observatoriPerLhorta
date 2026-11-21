-- Tests pgTAP d'esborrar el compte (RGPD art. 17) i de «les meues dades» (art. 15 i 20).
begin;
create extension if not exists pgtap with schema extensions;
select plan(17);

insert into public.municipis (codcat, nom, geom) values
  (99900, 'Municipi de prova', extensions.st_multi(extensions.st_makeenvelope(10.00, 50.00, 10.10, 50.10, 4326)));
insert into public.partides (id, codcat, nom, geom) values
  (99001, 99900, 'Partida A', extensions.st_multi(extensions.st_makeenvelope(10.00, 50.00, 10.05, 50.05, 4326)));
insert into auth.users (id, email) values
  ('00000000-0000-0000-0000-00000000000a', 'autora@test.local'),
  ('00000000-0000-0000-0000-00000000000c', 'coord@test.local');
update public.perfils set nom_public = 'Autora' where id = '00000000-0000-0000-0000-00000000000a';
insert into public.padrinatges (perfil_id, partida_id) values ('00000000-0000-0000-0000-00000000000a', 99001);

-- Dues aportacions de l'autora: una validada (es queda) i una pendent (se'n va), amb una foto cadascuna
insert into public.elements (id, variable_id, geom, origen, estat, partida_id, autor_id, validat_per)
select x.id::uuid, v.id, extensions.st_setsrid(extensions.st_point(10.01, 50.01), 4326), 'app',
       x.estat::public.estat_t, 99001, '00000000-0000-0000-0000-00000000000a',
       case when x.estat = 'validat' then '00000000-0000-0000-0000-00000000000c'::uuid end
from public.variables v,
     (values ('60000000-0000-0000-0000-000000000001', 'validat'),
             ('60000000-0000-0000-0000-000000000002', 'pendent')) as x(id, estat)
where v.nom = 'Alqueria';
insert into public.element_fotos (element_id, storage_path, autor_id) values
  ('60000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-00000000000a/validada.jpg', '00000000-0000-0000-0000-00000000000a'),
  ('60000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-00000000000a/pendent.jpg', '00000000-0000-0000-0000-00000000000a');
insert into storage.objects (bucket_id, name, owner, owner_id) values
  ('fotos', '00000000-0000-0000-0000-00000000000a/validada.jpg', '00000000-0000-0000-0000-00000000000a', '00000000-0000-0000-0000-00000000000a'),
  ('fotos', '00000000-0000-0000-0000-00000000000a/pendent.jpg', '00000000-0000-0000-0000-00000000000a', '00000000-0000-0000-0000-00000000000a'),
  ('fotos', '00000000-0000-0000-0000-00000000000a/orfena.jpg', '00000000-0000-0000-0000-00000000000a', '00000000-0000-0000-0000-00000000000a'),
  ('fotos', '00000000-0000-0000-0000-00000000000c/altra.jpg', '00000000-0000-0000-0000-00000000000c', '00000000-0000-0000-0000-00000000000c');
insert into public.notificacions (perfil_id, element_id, accio) values
  ('00000000-0000-0000-0000-00000000000a', '60000000-0000-0000-0000-000000000001', 'validat');

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
select throws_ok('select public.esborrar_compte()', '42501', null, 'un anònim no pot cridar-la');
select throws_ok('select public.les_meues_dades()', '42501', null, 'un anònim no veu dades de ningú');
reset role;

-- ─── Les meues dades ───────────────────────────────────────────────────────
select pg_temp.com('00000000-0000-0000-0000-00000000000a');
select is((public.les_meues_dades() -> 'compte' ->> 'correu'), 'autora@test.local', 'les meues dades: el correu');
select is((public.les_meues_dades() -> 'perfil' ->> 'alies'), 'Autora', 'les meues dades: l''àlies');
select is(jsonb_array_length(public.les_meues_dades() -> 'aportacions'), 2, 'les meues dades: les dues aportacions');
select is(jsonb_array_length(public.les_meues_dades() -> 'partides_apadrinades'), 1, 'les meues dades: la partida apadrinada');

-- ─── Fotos per esborrar ────────────────────────────────────────────────────
select set_eq(
  'select * from public.fotos_per_esborrar()',
  array['00000000-0000-0000-0000-00000000000a/pendent.jpg', '00000000-0000-0000-0000-00000000000a/orfena.jpg'],
  'fotos per esborrar: la pendent i l''òrfena, no la validada ni les d''altres');

-- ─── Esborrar el compte ────────────────────────────────────────────────────
select lives_ok('select public.esborrar_compte()', 'esborra el compte');
reset role;

select is((select count(*)::int from auth.users where id = '00000000-0000-0000-0000-00000000000a'), 0, 'el compte ja no existeix');
select is((select count(*)::int from public.perfils where id = '00000000-0000-0000-0000-00000000000a'), 0, 'ni el perfil');
select is((select count(*)::int from public.padrinatges where perfil_id = '00000000-0000-0000-0000-00000000000a'), 0, 'ni els padrinatges');
select is((select count(*)::int from public.notificacions where perfil_id = '00000000-0000-0000-0000-00000000000a'), 0, 'ni els avisos');
select is((select count(*)::int from public.elements where id = '60000000-0000-0000-0000-000000000002'), 0, 'l''aportació pendent s''esborra');
select is((select autor_id from public.elements where id = '60000000-0000-0000-0000-000000000001'), null, 'la validada es queda, sense autora');
select is((select validat_per from public.elements where id = '60000000-0000-0000-0000-000000000001'),
          '00000000-0000-0000-0000-00000000000c'::uuid, 'la validada guarda qui la va validar');
select is((select autor_id from public.element_fotos where storage_path like '%validada.jpg'), null, 'la foto validada, sense autora');
select is((select count(*)::int from auth.users where id = '00000000-0000-0000-0000-00000000000c'), 1, 'els altres comptes no es toquen');

select * from finish();
rollback;
