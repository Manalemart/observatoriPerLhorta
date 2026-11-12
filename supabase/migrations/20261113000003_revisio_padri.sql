-- ═══════════════════════════════════════════════════════════════════════════
-- Revisión del inventario por el padrí (web, hojas de papel y app de campo).
--
-- Decisiones (2026-11-12):
--   · Solo revisa el padrí de la partida (y la coordinación).
--   · «No el trobe»: lo decide el padrí → el elemento se da de baja (sigue en la base
--     de datos y en el historial, pero deja de verse en el mapa).
--   · «Ha canviat»: se aporta uno nuevo que lo sustituye; al validarlo, el antiguo queda
--     dado de baja como «substituït». Los dos siguen en el historial.
--   · La numeración de cada partida se calcula aquí, una sola vez, para que el Full de
--     revisió en papel y la app digan el mismo número.
-- ═══════════════════════════════════════════════════════════════════════════

alter table public.elements
  add column baixa_at       timestamptz,
  add column motiu_baixa    text check (motiu_baixa in ('no_trobat', 'substituit')),
  add column substitueix_id uuid references public.elements on delete set null,
  add constraint elements_baixa_coherent check ((baixa_at is null) = (motiu_baixa is null));

create index elements_substitueix_idx on public.elements (substitueix_id) where substitueix_id is not null;

grant select (baixa_at, motiu_baixa, substitueix_id) on public.elements to anon;

alter table public.element_historial drop constraint element_historial_accio_check;
alter table public.element_historial add constraint element_historial_accio_check
  check (accio in ('creat', 'editat', 'validat', 'rebutjat', 'reobert',
                   'confirmat', 'canviat', 'no_trobat', 'substituit'));

-- revisat_at y la baja solo cambian por las funciones de revisión
create or replace function public.elements_protegir_revisio()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
  if auth.uid() is not null
     and not coalesce(current_setting('observatori.revisio', true) = 'on', false)
     and (new.revisat_at is distinct from old.revisat_at
          or new.baixa_at is distinct from old.baixa_at
          or new.motiu_baixa is distinct from old.motiu_baixa) then
    raise exception 'La revisió només es registra amb revisar_element()' using errcode = '42501';
  end if;
  return new;
end;
$$;

drop trigger elements_protegir_revisio on public.elements;
create trigger elements_protegir_revisio
  before update of revisat_at, baixa_at, motiu_baixa on public.elements
  for each row execute function public.elements_protegir_revisio();

-- Lo que sustituye tiene que apuntar a algo vigente
create function public.elements_comprovar_substitucio()
returns trigger
language plpgsql security definer
set search_path = public, pg_temp
as $$
begin
  if new.substitueix_id is not null and (tg_op = 'INSERT' or new.substitueix_id is distinct from old.substitueix_id) then
    if new.substitueix_id = new.id or not exists (
      select 1 from public.elements where id = new.substitueix_id and baixa_at is null
    ) then
      raise exception 'L''element substituït no existeix o ja està donat de baixa' using errcode = '22023';
    end if;
  end if;
  return new;
end;
$$;

create trigger elements_comprovar_substitucio
  before insert or update of substitueix_id on public.elements
  for each row execute function public.elements_comprovar_substitucio();

-- Al validar un sustituto, el antiguo se da de baja
create function public.elements_aplicar_substitucio()
returns trigger
language plpgsql security definer
set search_path = public, pg_temp
as $$
declare
  v_n int;
begin
  perform set_config('observatori.revisio', 'on', true);
  update public.elements
     set baixa_at = now(), motiu_baixa = 'substituit'
   where id = new.substitueix_id and baixa_at is null;
  get diagnostics v_n = row_count;
  perform set_config('observatori.revisio', 'off', true);
  if v_n > 0 then
    insert into public.element_historial (element_id, perfil_id, accio, detall)
    values (new.substitueix_id, auth.uid(), 'substituit', jsonb_build_object('per', new.id));
  end if;
  return null;
end;
$$;

create trigger elements_aplicar_substitucio
  after update of estat on public.elements
  for each row
  when (new.estat = 'validat' and old.estat is distinct from 'validat' and new.substitueix_id is not null)
  execute function public.elements_aplicar_substitucio();

-- ─── Revisar ───────────────────────────────────────────────────────────────

create function public.revisar_element(p_element_id uuid, p_resultat text, p_nota text default null)
returns jsonb
language plpgsql security definer
set search_path = public, pg_temp
as $$
declare
  v_usuari uuid := auth.uid();
  v_el     public.elements;
  v_ara    timestamptz := now();
  v_nota   text := nullif(btrim(p_nota), '');
begin
  if v_usuari is null then
    raise exception 'Cal iniciar sessió' using errcode = '42501';
  end if;
  if p_resultat not in ('igual', 'canviat', 'no_trobat') then
    raise exception 'Resultat desconegut: %', p_resultat using errcode = '22023';
  end if;

  select * into v_el from public.elements where id = p_element_id;
  if not found then
    raise exception 'Element inexistent' using errcode = 'P0002';
  end if;
  if v_el.estat <> 'validat' or v_el.baixa_at is not null then
    raise exception 'Només es revisen elements validats i vigents' using errcode = '22023';
  end if;
  if not (public.es_padri_de(v_el.partida_id) or public.es_coordinador()) then
    raise exception 'Només revisa el padrí o la padrina de la partida' using errcode = '42501';
  end if;

  -- «Igual» repetido el mismo mes por la misma persona no suma nada
  if p_resultat = 'igual' and v_nota is null and exists (
    select 1 from public.element_historial
     where element_id = p_element_id and perfil_id = v_usuari and accio = 'confirmat'
       and created_at > v_ara - interval '30 days'
  ) then
    return jsonb_build_object('resultat', 'igual', 'revisat_at', v_el.revisat_at);
  end if;

  perform set_config('observatori.revisio', 'on', true);
  if p_resultat = 'no_trobat' then
    update public.elements set revisat_at = v_ara, baixa_at = v_ara, motiu_baixa = 'no_trobat' where id = p_element_id;
  else
    update public.elements set revisat_at = v_ara where id = p_element_id;
  end if;
  perform set_config('observatori.revisio', 'off', true);

  insert into public.element_historial (element_id, perfil_id, accio, detall)
  values (p_element_id, v_usuari,
          case p_resultat when 'igual' then 'confirmat' else p_resultat end,
          case when v_nota is not null then jsonb_build_object('nota', v_nota) end);

  return jsonb_build_object('resultat', p_resultat, 'revisat_at', v_ara);
end;
$$;

revoke execute on function public.revisar_element(uuid, text, text) from public, anon;
grant execute on function public.revisar_element(uuid, text, text) to authenticated;

-- La web la sigue usando para «Sí, continua igual»: ahora con las mismas reglas
create or replace function public.confirmar_element(p_element_id uuid)
returns timestamptz
language sql security definer
set search_path = public, pg_temp
as $$
  select (public.revisar_element(p_element_id, 'igual') ->> 'revisat_at')::timestamptz;
$$;

revoke execute on function public.confirmar_element(uuid) from public, anon;
grant execute on function public.confirmar_element(uuid) to authenticated;

-- ─── Lo dado de baja deja de verse en el mapa ──────────────────────────────

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
      'categoria', c.nom, 'estat', e.estat, 'origen', e.origen,
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
      'id', e.id, 'tema_id', v.tema_id, 'variable_id', e.variable_id, 'estat', e.estat,
      'per_revisar', e.origen = 'legacy_2018' and e.revisat_at is null
    )
  )), '[]'::json))
  from public.elements e
  join public.variables v on v.id = e.variable_id
  where e.estat = 'validat' and e.baixa_at is null;
$$;

create or replace function public.resum_revisio()
returns jsonb
language sql stable security definer
set search_path = public, pg_temp
as $$
  with v as (select * from public.elements where estat = 'validat')
  select jsonb_build_object(
    'elements_2018',       (select count(*) from v where origen = 'legacy_2018'),
    'per_revisar',         (select count(*) from v where origen = 'legacy_2018' and revisat_at is null and baixa_at is null),
    'revisats',            (select count(*) from v where origen = 'legacy_2018' and revisat_at is not null),
    'baixes',              (select count(*) from v where baixa_at is not null),
    'noves',               (select count(*) from v where origen <> 'legacy_2018'),
    'partides',            (select count(*) from public.partides),
    'partides_amb_revisio', (select count(distinct partida_id) from v
                              where partida_id is not null
                                and (revisat_at is not null or origen <> 'legacy_2018')),
    'partides_apadrinades', (select count(distinct partida_id) from public.padrinatges
                              where fins is null or fins >= current_date),
    'ultima_activitat',    (select max(greatest(revisat_at, case when origen <> 'legacy_2018' then validat_at end))
                              from v)
  );
$$;

-- ─── Hoja de la partida, con la numeración ─────────────────────────────────
-- Mismas reglas que web/src/features/fulls/fullDeCamp.ts: página A4 en la orientación de
-- la partida, recuadro del plano, encuadre con un 3 % de margen, cuadros de ~40 mm, y
-- números por cuadros (fila a fila, de izquierda a derecha) y dentro de cada uno de
-- arriba abajo. Si se cambia aquí, cambiarlo allí.

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
        'categoria', c.nom,
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

revoke execute on function public.full_de_camp(int) from public, anon;
grant execute on function public.full_de_camp(int) to authenticated;

select public.refrescar_cache_geojson('elements_validats');
