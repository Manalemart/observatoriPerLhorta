-- ═══════════════════════════════════════════════════════════════════════════
-- Revisión del inventario de 2017-2018.
--
-- Los 7.104 elementos de 2018 se validaron en bloque al migrarlos, pero describen el
-- horta de hace años. Cualquiera con sesión puede confirmar en campo que un elemento
-- «continua igual»: queda en el historial y el elemento pasa a «revisat». Si ha
-- cambiado, se aporta uno nuevo por el circuito normal (padrí valida).
-- ═══════════════════════════════════════════════════════════════════════════

alter table public.elements add column revisat_at timestamptz;
grant select (revisat_at) on public.elements to anon;   -- anon tiene permisos por columna (fase 2)

alter table public.element_historial drop constraint element_historial_accio_check;
alter table public.element_historial add constraint element_historial_accio_check
  check (accio in ('creat', 'editat', 'validat', 'rebutjat', 'reobert', 'confirmat'));

-- revisat_at solo cambia vía confirmar_element()
create function public.elements_protegir_revisio()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
  if new.revisat_at is distinct from old.revisat_at
     and auth.uid() is not null
     and not coalesce(current_setting('observatori.revisio', true) = 'on', false) then
    raise exception 'La revisió només es registra amb confirmar_element()' using errcode = '42501';
  end if;
  return new;
end;
$$;

create trigger elements_protegir_revisio
  before update of revisat_at on public.elements
  for each row execute function public.elements_protegir_revisio();

-- «Continua igual». Una confirmación por persona y elemento cada 30 días: repetirla
-- no suma nada y llenaría el historial.
create function public.confirmar_element(p_element_id uuid)
returns timestamptz
language plpgsql security definer
set search_path = public, pg_temp
as $$
declare
  v_usuari uuid := auth.uid();
  v_estat  public.estat_t;
  v_ara    timestamptz := now();
begin
  if v_usuari is null then
    raise exception 'Cal iniciar sessió' using errcode = '42501';
  end if;

  select estat into v_estat from public.elements where id = p_element_id;
  if not found then
    raise exception 'Element inexistent' using errcode = 'P0002';
  end if;
  if v_estat <> 'validat' then
    raise exception 'Només es confirmen elements validats' using errcode = '22023';
  end if;

  if exists (
    select 1 from public.element_historial
     where element_id = p_element_id and perfil_id = v_usuari and accio = 'confirmat'
       and created_at > v_ara - interval '30 days'
  ) then
    return (select revisat_at from public.elements where id = p_element_id);
  end if;

  perform set_config('observatori.revisio', 'on', true);
  update public.elements set revisat_at = v_ara where id = p_element_id;
  perform set_config('observatori.revisio', 'off', true);

  insert into public.element_historial (element_id, perfil_id, accio)
  values (p_element_id, v_usuari, 'confirmat');

  return v_ara;
end;
$$;

revoke execute on function public.confirmar_element(uuid) from public, anon;
grant execute on function public.confirmar_element(uuid) to authenticated;

-- ─── El mapa necesita saber qué está por revisar ───────────────────────────

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
      'id', e.id,                       -- MapLibre descarta los id de Feature que no son numéricos
      'tema_id', v.tema_id, 'tema', t.nom,
      'variable_id', e.variable_id, 'variable', v.nom,
      'categoria', c.nom, 'estat', e.estat, 'origen', e.origen,
      'partida_id', e.partida_id, 'created_at', e.created_at,
      'revisat_at', e.revisat_at,
      -- Del inventario de 2018 y sin confirmar desde entonces
      'per_revisar', e.origen = 'legacy_2018' and e.revisat_at is null
    )
  )), '[]'::jsonb)
  from public.elements e
  join public.variables v on v.id = e.variable_id
  join public.temes t on t.id = v.tema_id
  left join public.categories c on c.id = e.categoria_id
  where (p_env is null or e.geom && p_env)
    and (p_tema_id is null or v.tema_id = p_tema_id)
    and (p_variable_id is null or e.variable_id = p_variable_id)
    and (p_estat is null or e.estat = p_estat)
    and (not p_sense_validats or e.estat <> 'validat');
$$;

-- ─── Cifras de la portada ──────────────────────────────────────────────────
-- Solo agregados de lo público (validado) y de los padrinazgos vigentes.

create function public.resum_revisio()
returns jsonb
language sql stable security definer
set search_path = public, pg_temp
as $$
  with v as (select * from public.elements where estat = 'validat')
  select jsonb_build_object(
    'elements_2018',       (select count(*) from v where origen = 'legacy_2018'),
    'per_revisar',         (select count(*) from v where origen = 'legacy_2018' and revisat_at is null),
    'revisats',            (select count(*) from v where origen = 'legacy_2018' and revisat_at is not null),
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

grant execute on function public.resum_revisio() to anon, authenticated;

select public.refrescar_cache_geojson('elements_validats');
