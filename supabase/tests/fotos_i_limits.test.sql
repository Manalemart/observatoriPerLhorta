-- Tests pgTAP: qui pot veure cada foto (bucket privat) i els límits d'enviament.
begin;
create extension if not exists pgtap with schema extensions;
select plan(10);

insert into public.municipis (codcat, nom, geom) values
  (99900, 'Municipi de prova', extensions.st_multi(extensions.st_makeenvelope(10.00, 50.00, 10.10, 50.10, 4326)));
insert into public.partides (id, codcat, nom, geom) values
  (99001, 99900, 'Partida A', extensions.st_multi(extensions.st_makeenvelope(10.00, 50.00, 10.05, 50.05, 4326)));
insert into auth.users (id, email) values
  ('00000000-0000-0000-0000-00000000000a', 'autora@test.local'),
  ('00000000-0000-0000-0000-00000000000b', 'padri@test.local'),
  ('00000000-0000-0000-0000-00000000000c', 'altra@test.local');
insert into public.padrinatges (perfil_id, partida_id) values ('00000000-0000-0000-0000-00000000000b', 99001);

insert into public.elements (id, variable_id, geom, origen, estat, partida_id, autor_id)
select x.id::uuid, v.id, extensions.st_setsrid(extensions.st_point(10.01, 50.01), 4326), 'app', x.estat::public.estat_t, 99001,
       '00000000-0000-0000-0000-00000000000a'
from public.variables v,
     (values ('80000000-0000-0000-0000-000000000001', 'validat'), ('80000000-0000-0000-0000-000000000002', 'pendent')) x(id, estat)
where v.nom = 'Alqueria';
insert into public.element_fotos (element_id, storage_path, autor_id) values
  ('80000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-00000000000a/v.jpg', '00000000-0000-0000-0000-00000000000a'),
  ('80000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-00000000000a/p.jpg', '00000000-0000-0000-0000-00000000000a');

create function pg_temp.com(p_uid uuid) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('sub', p_uid, 'role', 'authenticated')::text, true);
  select set_config('role', 'authenticated', true);
$$;
create function pg_temp.anonim() returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('role', 'anon')::text, true);
  select set_config('role', 'anon', true);
$$;

select is((select public from storage.buckets where id = 'fotos'), false, 'el bucket de fotos és privat');

-- ─── Qui veu cada foto ─────────────────────────────────────────────────────
select pg_temp.anonim();
select ok(public.pot_veure_foto('00000000-0000-0000-0000-00000000000a/v.jpg'), 'un anònim veu la d''un element validat');
select ok(not public.pot_veure_foto('00000000-0000-0000-0000-00000000000a/p.jpg'), 'un anònim no veu la d''un pendent');
reset role;
select pg_temp.com('00000000-0000-0000-0000-00000000000c');
select ok(not public.pot_veure_foto('00000000-0000-0000-0000-00000000000a/p.jpg'), 'una altra persona tampoc');
reset role;
select pg_temp.com('00000000-0000-0000-0000-00000000000b');
select ok(public.pot_veure_foto('00000000-0000-0000-0000-00000000000a/p.jpg'), 'el padrí de la partida sí');
reset role;
select pg_temp.com('00000000-0000-0000-0000-00000000000a');
select ok(public.pot_veure_foto('00000000-0000-0000-0000-00000000000a/p.jpg'), 'l''autora sí');

-- ─── Límit de fotos en una aportació pendent ───────────────────────────────
reset role;
insert into public.element_fotos (element_id, storage_path, autor_id)
select '80000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-00000000000a/p' || g || '.jpg', '00000000-0000-0000-0000-00000000000a'
from generate_series(2, 5) g;
select throws_ok($$insert into public.element_fotos (element_id, storage_path, autor_id)
  values ('80000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-00000000000a/p6.jpg', '00000000-0000-0000-0000-00000000000a')$$,
  '22023', null, 'una aportació pendent no passa de 5 fotos');
select lives_ok($$insert into public.element_fotos (element_id, storage_path, autor_id)
  select '80000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-00000000000a/r' || g || '.jpg', '00000000-0000-0000-0000-00000000000a'
  from generate_series(1, 6) g$$, 'un element validat (revisions) sí que en pot acumular més');

-- ─── Límit d'aportacions per hora ──────────────────────────────────────────
select pg_temp.com('00000000-0000-0000-0000-00000000000c');
select lives_ok($$insert into public.elements (variable_id, geom, origen)
  select v.id, extensions.st_setsrid(extensions.st_point(10.02, 50.02), 4326), 'app'
  from public.variables v, generate_series(1, 30) where v.nom = 'Alqueria'$$, '30 aportacions en una hora, sí');
select throws_ok($$insert into public.elements (variable_id, geom, origen)
  select v.id, extensions.st_setsrid(extensions.st_point(10.02, 50.02), 4326), 'app'
  from public.variables v where v.nom = 'Alqueria'$$, '22023', null, 'la 31a, no');

select * from finish();
rollback;
