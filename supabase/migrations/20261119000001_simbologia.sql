-- Simbologia del mapa (guia de disseny de Per l'Horta, docs/simbologia).
--
-- El símbol de cada element depén de la variable i, en reg, serveis, línies i parcel·les,
-- de la categoria: les tres fonts del mapa (web, app i full de camp) passen a portar
-- categoria_id. I els temes prenen el color de la seua família en la guia.

create or replace function public._elements_features(
  p_env extensions.geometry,
  p_tema_id int default null,
  p_variable_id int default null,
  p_estat public.estat_t default null,
  p_sense_validats boolean default false
)
returns jsonb
language sql stable
set search_path = public, extensions, pg_temp
as $$
  select coalesce(jsonb_agg(jsonb_build_object(
    'type', 'Feature',
    'id', e.id,
    'geometry', st_asgeojson(e.geom, 7)::jsonb,
    'properties', jsonb_build_object(
      'id', e.id,
      'tema_id', v.tema_id, 'tema', t.nom,
      'variable_id', e.variable_id, 'variable', v.nom,
      'categoria', c.nom, 'categoria_id', e.categoria_id, 'estat', e.estat, 'origen', e.origen,
      'partida_id', e.partida_id, 'created_at', e.created_at,
      'revisat_at', e.revisat_at,
      'per_revisar', e.origen = 'legacy_2018' and e.revisat_at is null
    )
  )), '[]'::jsonb)
  from public.elements e
  join public.variables v on v.id = e.variable_id
  join public.temes t on t.id = v.tema_id
  left join public.categories c on c.id = e.categoria_id
  where e.baixa_at is null
    and (p_env is null or e.geom && p_env)
    and (p_tema_id is null or v.tema_id = p_tema_id)
    and (p_variable_id is null or e.variable_id = p_variable_id)
    and (p_estat is null or e.estat = p_estat)
    and (not p_sense_validats or e.estat <> 'validat');
$$;


create or replace function public._elements_publics_fc()
returns json
language sql stable
set search_path = public, extensions, pg_temp
as $$
  select json_build_object('type', 'FeatureCollection', 'features', coalesce(json_agg(json_build_object(
    'type', 'Feature',
    'geometry', st_asgeojson(
      case when geometrytype(e.geom) like '%POLYGON' then st_simplifypreservetopology(e.geom, 0.00001) else e.geom end,
      6)::json,
    'properties', json_build_object(
      'id', e.id, 'tema_id', v.tema_id, 'variable_id', e.variable_id, 'categoria_id', e.categoria_id, 'estat', e.estat,
      'per_revisar', e.origen = 'legacy_2018' and e.revisat_at is null
    )
  )), '[]'::json))
  from public.elements e
  join public.variables v on v.id = e.variable_id
  where e.estat = 'validat' and e.baixa_at is null;
$$;


create or replace function public.full_de_camp(p_partida_id int)
returns jsonb
language sql stable
set search_path = public, extensions, pg_temp
as $$
  with
  merc as (                      -- Mercator 0..1 (y crece hacia el sur)
    select p.id,
           (st_xmin(p.geom) + 180) / 360 as x0,
           (st_xmax(p.geom) + 180) / 360 as x1,
           (1 - ln(tan(radians(st_ymax(p.geom))) + 1 / cos(radians(st_ymax(p.geom)))) / pi()) / 2 as y0,
           (1 - ln(tan(radians(st_ymin(p.geom))) + 1 / cos(radians(st_ymin(p.geom)))) / pi()) / 2 as y1
      from public.partides p where p.id = p_partida_id
  ),
  pag as (
    select m.*, (x1 - x0) >= (y1 - y0) as apaisat,
           case when (x1 - x0) >= (y1 - y0) then 297 - 2 * 8 - 5 else 210 - 2 * 8 - 5 end::float8 as mw,
           case when (x1 - x0) >= (y1 - y0) then 210 - 27 - 5 - 17 else 297 - 27 - 5 - 17 end::float8 as mh
      from merc m
  ),
  caixa as (
    select p.*,
           case when ((x1 - x0) * 1.06) / ((y1 - y0) * 1.06) > mw / mh
                then (x1 - x0) * 1.06 else ((y1 - y0) * 1.06) * mw / mh end as w,
           case when ((x1 - x0) * 1.06) / ((y1 - y0) * 1.06) > mw / mh
                then ((x1 - x0) * 1.06) * mh / mw else (y1 - y0) * 1.06 end as h,
           greatest(2, round((mw / 40)::numeric))::int as cols,
           greatest(2, round((mh / 40)::numeric))::int as files
      from pag p
  ),
  vista as (
    select c.*, (x0 + x1) / 2 - w / 2 as ox, (y0 + y1) / 2 - h / 2 as oy from caixa c
  ),
  els as (
    select e.*, st_pointonsurface(e.geom) as pt from public.elements e
     where e.partida_id = p_partida_id and e.baixa_at is null
  ),
  pos as (
    select e.id,
           ((st_x(e.pt) + 180) / 360 - v.ox) / v.w as u,
           ((1 - ln(tan(radians(st_y(e.pt))) + 1 / cos(radians(st_y(e.pt)))) / pi()) / 2 - v.oy) / v.h as t,
           v.cols, v.files
      from els e cross join vista v
  ),
  celes as (
    select id, u, t,
           least(cols - 1, greatest(0, floor(u * cols)))::int as c,
           least(files - 1, greatest(0, floor(t * files)))::int as f
      from pos
  ),
  numerats as (
    select id, chr(65 + c) || (f + 1) as quadre,
           row_number() over (order by f, c, t, u) as numero
      from celes
  ),
  darrera as (                   -- última revisión de cada elemento (lo que la RLS deja ver)
    select distinct on (h.element_id) h.element_id, h.accio, h.created_at, h.detall ->> 'nota' as nota
      from public.element_historial h
      join els e on e.id = h.element_id
     where h.accio in ('confirmat', 'canviat')
     order by h.element_id, h.created_at desc
  )
  select jsonb_build_object(
    'partida', (
      select jsonb_build_object(
        'id', p.id, 'nom', p.nom, 'municipi', m.nom,
        'area_ha', round((p.area_m2 / 10000)::numeric, 1),
        'geometria', st_asgeojson(p.geom, 7)::jsonb,
        'es_padri', public.es_padri_de(p.id) or public.es_coordinador()
      )
      from public.partides p
      join public.municipis m on m.codcat = p.codcat
      where p.id = p_partida_id
    ),
    'elements', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', e.id,
        'numero', n.numero, 'quadre', n.quadre,
        'tema_id', t.id, 'tema', t.nom, 'color', t.color,
        'variable_id', v.id,
        'variable', coalesce(e.text_lliure, v.nom),
        'categoria', c.nom, 'categoria_id', e.categoria_id,
        'estat', e.estat, 'origen', e.origen,
        'revisat_at', e.revisat_at, 'created_at', e.created_at,
        'per_revisar', e.origen = 'legacy_2018' and e.revisat_at is null,
        'darrera_revisio', case when d.accio is not null then jsonb_build_object(
          'resultat', case d.accio when 'confirmat' then 'igual' else d.accio end,
          'data', d.created_at, 'nota', d.nota) end,
        'substitucio_pendent', exists (
          select 1 from public.elements s where s.substitueix_id = e.id and s.estat = 'pendent'),
        'geometria', st_asgeojson(e.geom, 7)::jsonb,
        'etiqueta', st_asgeojson(e.pt, 7)::jsonb -> 'coordinates'
      ) order by n.numero)
      from els e
      join numerats n on n.id = e.id
      join public.variables v on v.id = e.variable_id
      join public.temes t on t.id = v.tema_id
      left join public.categories c on c.id = e.categoria_id
      left join darrera d on d.element_id = e.id
    ), '[]'::jsonb)
  );
$$;


update public.temes t set color = c.color
  from (values ('Agressions', '#E2001A'), ('Construccions', '#F9AC00'), ('Infraestructura', '#009EE0'),
               ('Ús del sòl', '#9ED100'), ('Vegetació', '#348E00')) as c(nom, color)
 where t.nom = c.nom;

select public.refrescar_cache_geojson('elements_validats');
