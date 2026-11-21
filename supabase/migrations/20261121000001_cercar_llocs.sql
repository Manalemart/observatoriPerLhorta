-- Buscador del mapa (web i app): municipis i partides per nom.
--
-- Sense accents ni majúscules («alqueria» troba «Alquería», «albalat» troba «Albalat dels
-- Sorells»), amb prioritat per al nom exacte, després el que hi comença, després una paraula
-- que hi comença i, al final, el que el conté. Torna la caixa del lloc per a centrar el mapa.

create or replace function public._normalitza(p text)
returns text
language sql
immutable
parallel safe
set search_path = ''
as $$
  select regexp_replace(
    translate(lower(coalesce(p, '')),
              'àáâäèéêëìíîïòóôöùúûüçñ·''’-',
              'aaaaeeeeiiiioooouuuucn    '),
    '\s+', ' ', 'g')
$$;

create or replace function public.cercar_llocs(p_text text, p_limit int default 8)
returns table (
  tipus text,          -- 'municipi' | 'partida'
  id integer,          -- codcat del municipi o id de la partida
  nom text,
  municipi text,       -- en les partides, el seu municipi
  oest double precision,
  sud double precision,
  est double precision,
  nord double precision
)
language sql
stable
security definer
set search_path = ''
as $$
  with q as (select trim(public._normalitza(p_text)) as t),
  llocs as (
    select 'municipi'::text as tipus, m.codcat as id, m.nom, null::text as municipi, m.geom, 0 as ordre_tipus
    from public.municipis m
    union all
    select 'partida', p.id, p.nom, m.nom, p.geom, 1
    from public.partides p
    left join public.municipis m on m.codcat = p.codcat
  ),
  puntuats as (
    select l.*,
           public._normalitza(l.nom) as n,
           case
             when public._normalitza(l.nom) = q.t then 0
             when public._normalitza(l.nom) like q.t || '%' then 1
             when ' ' || public._normalitza(l.nom) like '% ' || q.t || '%' then 2
             when public._normalitza(l.nom) like '%' || q.t || '%' then 3
             -- «partida, municipi»: també troba per municipi («benimaclet valencia»)
             when public._normalitza(l.nom || ' ' || coalesce(l.municipi, '')) like '%' || q.t || '%' then 4
           end as rang
    from llocs l, q
    where length(q.t) >= 2
  )
  select tipus, id, nom, municipi,
         extensions.st_xmin(geom), extensions.st_ymin(geom), extensions.st_xmax(geom), extensions.st_ymax(geom)
  from puntuats
  where rang is not null
  order by rang, ordre_tipus, length(nom), nom
  limit least(greatest(coalesce(p_limit, 8), 1), 20);
$$;

revoke all on function public.cercar_llocs(text, int) from public;
grant execute on function public.cercar_llocs(text, int) to anon, authenticated;
