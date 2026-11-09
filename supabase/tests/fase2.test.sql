-- Tests pgTAP de la fase 2.
begin;
create extension if not exists pgtap with schema extensions;
select plan(19);

-- ─── Fixtures (zona ficticia, como en regles_validacio) ────────────────────
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
create function pg_temp.com_anon() returns void language sql as $$
  select set_config('request.jwt.claims', '{"role":"anon"}', true);
  select set_config('role', 'anon', true);
$$;

create temp table ids as select v.id as var_punt from public.variables v where v.nom = 'Alqueria';
grant select on ids to authenticated, anon;

select pg_temp.com('00000000-0000-0000-0000-00000000000a');
insert into public.elements (id, variable_id, geom)
select '10000000-0000-0000-0000-000000000001', var_punt, extensions.st_setsrid(extensions.st_point(10.02, 50.02), 4326) from ids;
insert into public.elements (id, variable_id, geom)
select '10000000-0000-0000-0000-000000000002', var_punt, extensions.st_setsrid(extensions.st_point(10.03, 50.02), 4326) from ids;

-- ─── Notificaciones ────────────────────────────────────────────────────────
select is((select count(*)::int from public.notificacions), 0, 'Aportar no genera avisos');

select pg_temp.com('00000000-0000-0000-0000-00000000000b');
select public.canviar_estat('10000000-0000-0000-0000-000000000001', 'validat');
select public.canviar_estat('10000000-0000-0000-0000-000000000002', 'rebutjat', 'Falta foto');
select is((select count(*)::int from public.notificacions), 0, 'Un padrí no veu els avisos d''altri');

select pg_temp.com('00000000-0000-0000-0000-00000000000a');
select is((select count(*)::int from public.notificacions), 2, 'L''autora rep un avís per cada canvi');
select is((select motiu from public.notificacions where accio = 'rebutjat'), 'Falta foto', 'L''avís duu el motiu');
update public.notificacions set llegida = true;
select is((select count(*)::int from public.notificacions where llegida), 2, 'Pot marcar-los com a llegits');
select throws_ok($$ update public.notificacions set motiu = 'x' $$, '42501', null, 'No pot alterar el contingut de l''avís');

update public.elements set descripcio = 'Corregit' where id = '10000000-0000-0000-0000-000000000002';
select is((select estat::text from public.elements where id = '10000000-0000-0000-0000-000000000002'), 'pendent', 'Corregir torna a pendent');
select is((select count(*)::int from public.notificacions), 2, 'Corregir el propi no genera avís');

-- ─── Vista del padrí ───────────────────────────────────────────────────────
select pg_temp.com('00000000-0000-0000-0000-00000000000b');
select is((select validats::int from public.resum_les_meues_partides()), 1, 'El padrí veu els validats de la seua partida');
select is((select pendents::int from public.resum_les_meues_partides()), 1, 'El padrí veu els pendents de la seua partida');
select pg_temp.com('00000000-0000-0000-0000-00000000000a');
select is((select count(*)::int from public.resum_les_meues_partides()), 0, 'Sense padrinatge no hi ha partides');

-- ─── Privacidad y datos abiertos ───────────────────────────────────────────
select pg_temp.com_anon();
select throws_ok($$ select autor_id from public.elements limit 1 $$, '42501', null, 'Un anònim no pot llegir l''autor');
select lives_ok($$ select id, estat from public.elements limit 1 $$, 'Un anònim pot llegir la resta de columnes');
select is(
  (select count(*)::int from public.dades_obertes where municipi = 'Municipi de prova'), 1,
  'Dades obertes: només el validat');
select ok(
  not exists (select 1 from information_schema.columns
               where table_name = 'dades_obertes' and column_name in ('autor_id', 'validat_per')),
  'Dades obertes: sense dades de qui aporta');
select ok((public.resum_inventari() ->> 'total')::int >= 1, 'El resum és públic');

-- ─── Noticias ──────────────────────────────────────────────────────────────
reset role;
insert into public.noticies (titol, publicat) values ('Publicada', true), ('Esborrany', false);
select pg_temp.com_anon();
select is((select count(*)::int from public.noticies where titol in ('Publicada', 'Esborrany')), 1, 'Un anònim només veu les publicades');
select pg_temp.com('00000000-0000-0000-0000-00000000000a');
select throws_ok($$ insert into public.noticies (titol) values ('x') $$, '42501', null, 'Un ciutadà no pot publicar');
select pg_temp.com('00000000-0000-0000-0000-00000000000c');
select is((select count(*)::int from public.noticies where titol in ('Publicada', 'Esborrany')), 2, 'La coordinació veu els esborranys');

select * from finish();
rollback;
