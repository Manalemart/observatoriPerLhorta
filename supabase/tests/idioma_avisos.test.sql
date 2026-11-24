-- Tests pgTAP de l'idioma de cada persona: perfil, metadades per a les plantilles i resum diari.
begin;
create extension if not exists pgtap with schema extensions;
select plan(8);

insert into public.municipis (codcat, nom, geom) values
  (99900, 'Municipi de prova', extensions.st_multi(extensions.st_makeenvelope(10.00, 50.00, 10.10, 50.10, 4326)));
insert into public.partides (id, codcat, nom, geom) values
  (99001, 99900, 'Partida A', extensions.st_multi(extensions.st_makeenvelope(10.00, 50.00, 10.05, 50.05, 4326)));
insert into auth.users (id, email, raw_user_meta_data) values
  ('00000000-0000-0000-0000-0000000000a1', 'autora@test.local', '{}'),
  ('00000000-0000-0000-0000-0000000000b1', 'padri@test.local', '{"idioma": "en"}'),
  ('00000000-0000-0000-0000-0000000000c1', 'raro@test.local', '{"idioma": "fr"}');

select is((select idioma from public.perfils where id = '00000000-0000-0000-0000-0000000000a1'), 'ca',
  'Sense idioma en registrar-se: valencià');
select is((select idioma from public.perfils where id = '00000000-0000-0000-0000-0000000000b1'), 'en',
  'L''idioma de la web o la app en registrar-se passa al perfil');
select is((select idioma from public.perfils where id = '00000000-0000-0000-0000-0000000000c1'), 'ca',
  'Un idioma que no hi és: valencià');

-- La persona canvia l'idioma des de la web o la app
set local role authenticated;
select set_config('request.jwt.claims', '{"sub": "00000000-0000-0000-0000-0000000000a1", "role": "authenticated"}', true);
update public.perfils set idioma = 'es' where id = '00000000-0000-0000-0000-0000000000a1';
reset role;

select is((select idioma from public.perfils where id = '00000000-0000-0000-0000-0000000000a1'), 'es',
  'Cadascú pot canviar el seu idioma');
select is((select raw_user_meta_data ->> 'idioma' from auth.users where id = '00000000-0000-0000-0000-0000000000a1'), 'es',
  'L''idioma es copia a les metadades (per a les plantilles de correu)');

select throws_ok($$update public.perfils set idioma = 'fr' where id = '00000000-0000-0000-0000-0000000000a1'$$,
  '23514', null, 'Només ca, es o en');

-- El resum diari en anglés per al padrí, amb el nom del catàleg traduït
insert into public.padrinatges (perfil_id, partida_id) values ('00000000-0000-0000-0000-0000000000b1', 99001);
insert into public.elements (id, variable_id, geom, origen, estat, partida_id, autor_id)
select '61000000-0000-0000-0000-000000000001', v.id, extensions.st_setsrid(extensions.st_point(10.01, 50.01), 4326),
       'web', 'pendent', 99001, '00000000-0000-0000-0000-0000000000a1'
from public.variables v where v.nom = 'Alqueria';

select is((select assumpte from public.resums_avisos() where perfil_id = '00000000-0000-0000-0000-0000000000b1'),
  'You have 1 new notification at the Observatori Ciutadà de l''Horta', 'L''assumpte en anglés');
select ok((select text_pla from public.resums_avisos() where perfil_id = '00000000-0000-0000-0000-0000000000b1')
            like '%New contributions to validate%• ' ||
                 (select coalesce(nom_en, nom) from public.variables where nom = 'Alqueria') || ' — Partida A%',
  'El text en anglés, amb el nom de la variable traduït');

select * from finish();
rollback;
