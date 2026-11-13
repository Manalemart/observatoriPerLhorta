-- Tests pgTAP de la versión de las capas del mapa (para invalidar la caché del CDN).
begin;
create extension if not exists pgtap with schema extensions;
select plan(4);

select ok(public.versions_geojson()::jsonb ? 'partides', 'Hi ha versió de les partides');
select ok(public.versions_geojson()::jsonb ? 'elements_validats', 'I dels elements');

-- now() es fijo dentro de la transacción: se fuerza una versión vieja para ver que cambia
update public.cache_geojson set actualitzat = '2000-01-01' where clau = 'partides';
create temp table abans as select (public.versions_geojson()::jsonb ->> 'partides')::bigint as v;

insert into public.municipis (codcat, nom, geom) values
  (99900, 'Municipi de prova', extensions.st_multi(extensions.st_makeenvelope(10.00, 50.00, 10.10, 50.10, 4326)));
insert into public.partides (id, codcat, nom, geom) values
  (99001, 99900, 'Partida A', extensions.st_multi(extensions.st_makeenvelope(10.00, 50.00, 10.05, 50.05, 4326)));
update public.partides set nom = 'Partida reanomenada' where id = 99001;

select cmp_ok((public.versions_geojson()::jsonb ->> 'partides')::bigint, '>', (select v from abans),
  'Reanomenar una partida canvia la versió');

set local role anon;
select lives_ok($$ select public.versions_geojson() $$, 'Un anònim la pot consultar');

select * from finish();
rollback;
