-- Tests pgTAP del buscador del mapa (cercar_llocs).
begin;
create extension if not exists pgtap with schema extensions;
select plan(7);

insert into public.municipis (codcat, nom, geom) values
  (99900, 'Vilaprova de l''Horta', extensions.st_multi(extensions.st_makeenvelope(10.00, 50.00, 10.10, 50.10, 4326)));
insert into public.partides (id, codcat, nom, geom) values
  (99001, 99900, 'Camí de la Séquia', extensions.st_multi(extensions.st_makeenvelope(10.00, 50.00, 10.05, 50.05, 4326))),
  (99002, 99900, 'Sequiola', extensions.st_multi(extensions.st_makeenvelope(10.05, 50.05, 10.10, 50.10, 4326)));

select set_config('role', 'anon', true);

select is((select nom from public.cercar_llocs('vilaprova') limit 1), 'Vilaprova de l''Horta', 'troba el municipi');
select is((select tipus from public.cercar_llocs('vilaprova') limit 1), 'municipi', 'i diu que és un municipi');
select is((select nom from public.cercar_llocs('cami de la sequia') limit 1), 'Camí de la Séquia', 'sense accents');
select is((select municipi from public.cercar_llocs('Camí de la Séquia') limit 1), 'Vilaprova de l''Horta', 'la partida porta el seu municipi');
select is((select nom from public.cercar_llocs('sequi') limit 1), 'Sequiola', 'primer el que comença pel text');
select is((select array[oest, sud, est, nord] from public.cercar_llocs('sequiola') limit 1),
          array[10.05, 50.05, 10.10, 50.10]::double precision[], 'torna la caixa del lloc');
select is((select count(*)::int from public.cercar_llocs('s')), 0, 'amb una lletra no busca');

select * from finish();
rollback;
