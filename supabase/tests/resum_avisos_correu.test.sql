-- Tests pgTAP del resumen diario de avisos por correo.
-- La transacción se deshace al final: pg_net no llega a enviar nada.
begin;
create extension if not exists pgtap with schema extensions;
select plan(15);

insert into public.municipis (codcat, nom, geom) values
  (99900, 'Municipi de prova', extensions.st_multi(extensions.st_makeenvelope(10.00, 50.00, 10.10, 50.10, 4326)));
insert into public.partides (id, codcat, nom, geom) values
  (99001, 99900, 'Partida A', extensions.st_multi(extensions.st_makeenvelope(10.00, 50.00, 10.05, 50.05, 4326)));
insert into auth.users (id, email) values
  ('00000000-0000-0000-0000-00000000000a', 'autora@test.local'),
  ('00000000-0000-0000-0000-00000000000b', 'padri@test.local'),
  ('00000000-0000-0000-0000-00000000000d', 'nocorreu@test.local');
insert into public.padrinatges (perfil_id, partida_id) values
  ('00000000-0000-0000-0000-00000000000b', 99001),
  ('00000000-0000-0000-0000-00000000000d', 99001);
update public.perfils set resum_correu = false where id = '00000000-0000-0000-0000-00000000000d';

-- Dos aportaciones nuevas de la autora (avisan a los dos padrins); una lleva HTML en el texto
insert into public.elements (id, variable_id, text_lliure, geom, origen, estat, partida_id, autor_id)
select x.id::uuid, v.id, x.txt, extensions.st_setsrid(extensions.st_point(10.01, 50.01), 4326), 'web', 'pendent', 99001,
       '00000000-0000-0000-0000-00000000000a'
from public.variables v,
     (values ('60000000-0000-0000-0000-000000000001', null),
             ('60000000-0000-0000-0000-000000000002', 'Pou <b>vell</b>')) as x(id, txt)
where v.nom = 'Alqueria';

select is((select count(*)::int from public.resums_avisos()), 1,
  'Un sol correu: el padrí que no vol resum no en rep');

select is((select assumpte from public.resums_avisos()), 'Tens 2 avisos nous a l''Observatori Ciutadà de l''Horta',
  'L''assumpte compta els avisos');

select ok((select text_pla from public.resums_avisos()) like '%Aportacions noves per validar%• Alqueria — Partida A%',
  'El text diu què cal validar i on');

select ok((select html from public.resums_avisos()) like '%/validacio%',
  'L''HTML porta al panell de validació');

select ok((select html from public.resums_avisos()) like '%Pou &lt;b&gt;vell&lt;/b&gt;%'
      and (select html from public.resums_avisos()) not like '%<b>vell%',
  'El text de les persones s''escapa en l''HTML');

-- Una ya validada no se pide validar
update public.elements set estat = 'validat' where id = '60000000-0000-0000-0000-000000000002';
select is((select cardinality(ids) from public.resums_avisos()), 1,
  'Una aportació que ja no està pendent no entra');

-- Los leídos y los antiguos no entran
update public.notificacions set llegida = true
 where perfil_id = '00000000-0000-0000-0000-00000000000b' and element_id = '60000000-0000-0000-0000-000000000001';
select is((select count(*)::int from public.resums_avisos()), 0, 'Els avisos llegits no s''envien');

update public.notificacions set llegida = false, created_at = now() - interval '20 days'
 where perfil_id = '00000000-0000-0000-0000-00000000000b';
select is((select count(*)::int from public.resums_avisos()), 0, 'Els avisos de fa més de 14 dies no s''envien');
update public.notificacions set created_at = now() where perfil_id = '00000000-0000-0000-0000-00000000000b';

-- La autora recibe lo de sus aportaciones, con el motivo del rechazo
insert into public.notificacions (perfil_id, element_id, accio, motiu) values
  ('00000000-0000-0000-0000-00000000000a', '60000000-0000-0000-0000-000000000002', 'rebutjat', 'Duplicat');
select ok((select text_pla from public.resums_avisos() where perfil_id = '00000000-0000-0000-0000-00000000000a')
          like '%Les teues aportacions%rebutjada (Duplicat)%',
  'L''autora rep el rebuig amb el motiu');

-- ─── Envío ─────────────────────────────────────────────────────────────────
select is(public.enviar_resums_avisos(), 0, 'Sense la clau de Brevo al Vault no s''envia res');
select is((select count(*)::int from public.notificacions where enviada_correu is not null), 0,
  'i no es marca cap avís');

select vault.create_secret('clau-de-prova', 'brevo_api_key');
select is(public.enviar_resums_avisos(), 2, 'Amb la clau s''envia un correu a cada persona');
select is((select count(*)::int from public.correus_resum where request_id is not null), 2,
  'Cada enviament queda registrat amb la petició de pg_net');
select is(public.enviar_resums_avisos(), 0, 'Un avís no s''envia dues vegades');

-- ─── Preferencia ───────────────────────────────────────────────────────────
select set_config('request.jwt.claims', json_build_object('sub', '00000000-0000-0000-0000-00000000000d', 'role', 'authenticated')::text, true);
set local role authenticated;
select lives_ok($$ update public.perfils set resum_correu = true where id = '00000000-0000-0000-0000-00000000000d' $$,
  'Cadascú pot activar o desactivar el seu resum');
reset role;

select * from finish();
rollback;
