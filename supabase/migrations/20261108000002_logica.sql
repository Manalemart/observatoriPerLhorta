-- ═══════════════════════════════════════════════════════════════════════════
-- Lógica de negocio: roles, padrinatges, validación de geometrías y estados.
--
-- Reglas (confirmadas 2026-11-07):
--   · Cualquier persona registrada aporta en el ámbito (37 municipios).
--   · El padrí valida/rechaza en sus partidas; el coordinador en todo el ámbito.
--   · Nadie valida ni rechaza sus propias aportaciones.
--   · Solo un coordinador reabre un elemento validado.
--
-- Las funciones que leen perfils/padrinatges son SECURITY DEFINER con
-- search_path fijo: si corrieran como invoker, RLS las dejaría sin filas
-- (lección del hook de Arrels i Fulles).
-- ═══════════════════════════════════════════════════════════════════════════

-- ─── Helpers de rol ────────────────────────────────────────────────────────

create function public.es_coordinador()
returns bool
language sql stable security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1 from public.perfils
    where id = auth.uid() and rol in ('coordinador', 'admin')
  );
$$;

create function public.es_padri_de(p_partida_id int)
returns bool
language sql stable security definer
set search_path = public, pg_temp
as $$
  select p_partida_id is not null and exists (
    select 1 from public.padrinatges
    where perfil_id = auth.uid()
      and partida_id = p_partida_id
      and des_de <= current_date
      and (fins is null or fins >= current_date)
  );
$$;

-- ─── Alta de perfil al registrarse ─────────────────────────────────────────

create function public.crear_perfil()
returns trigger
language plpgsql security definer
set search_path = public, pg_temp
as $$
begin
  insert into public.perfils (id, nom_public)
  values (new.id, new.raw_user_meta_data ->> 'nom_public');
  return new;
end;
$$;

create trigger auth_users_crear_perfil
  after insert on auth.users
  for each row execute function public.crear_perfil();

-- ─── Un usuario no puede cambiarse el rol a sí mismo ───────────────────────
create function public.protegir_rol()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
  if new.rol is distinct from old.rol
     and auth.uid() is not null
     and not public.es_coordinador()
     and current_setting('observatori.sync_rol', true) is distinct from 'on' then
    raise exception 'Només la coordinació pot canviar el rol' using errcode = '42501';
  end if;
  return new;
end;
$$;

create trigger perfils_protegir_rol
  before update on public.perfils
  for each row execute function public.protegir_rol();

-- ─── El rol padrí sigue a los padrinatges vigentes ─────────────────────────
-- Se ejecuta desde la sesión del coordinador que asigna el padrinatge: marca la
-- transacción para que protegir_rol permita el cambio.
create function public.sincronitzar_rol_padri()
returns trigger
language plpgsql security definer
set search_path = public, pg_temp
as $$
declare
  v_perfil uuid := coalesce(new.perfil_id, old.perfil_id);
  v_vigent bool;
begin
  select exists (
    select 1 from public.padrinatges
    where perfil_id = v_perfil
      and des_de <= current_date
      and (fins is null or fins >= current_date)
  ) into v_vigent;

  perform set_config('observatori.sync_rol', 'on', true);
  update public.perfils
     set rol = case when v_vigent then 'padri'::rol_t else 'ciutada'::rol_t end
   where id = v_perfil
     and rol in ('ciutada', 'padri');               -- no degrada coordinadors/admins
  perform set_config('observatori.sync_rol', 'off', true);
  return null;
end;
$$;

create trigger padrinatges_sincronitzar_rol
  after insert or update or delete on public.padrinatges
  for each row execute function public.sincronitzar_rol_padri();

-- ─── Elementos: validación antes de escribir ───────────────────────────────

create function public.elements_abans_escriure()
returns trigger
language plpgsql security definer
set search_path = public, extensions, pg_temp
as $$
declare
  v_var        public.variables;
  v_tipus      text := geometrytype(new.geom);
  v_usuari     uuid := auth.uid();
  -- coalesce: sin la variable definida current_setting() da NULL y NOT NULL dejaría pasar el cambio
  v_canvi_estat bool := coalesce(current_setting('observatori.canvi_estat', true) = 'on', false);
begin
  select * into v_var from public.variables where id = new.variable_id;

  -- Tipo de geometría coherente con la variable
  if not (
       (v_var.geometria = 'punt'                   and v_tipus in ('POINT'))
    or (v_var.geometria = 'linia'                  and v_tipus in ('LINESTRING', 'MULTILINESTRING'))
    or (v_var.geometria in ('poligon', 'parcela')  and v_tipus in ('POLYGON', 'MULTIPOLYGON'))
  ) then
    raise exception 'La geometria (%) no correspon a la variable (%)', v_tipus, v_var.geometria
      using errcode = '22023';
  end if;

  -- La categoría pertenece a la variable
  if new.categoria_id is not null and not exists (
    select 1 from public.categories where id = new.categoria_id and variable_id = new.variable_id
  ) then
    raise exception 'La categoria no pertany a la variable' using errcode = '22023';
  end if;

  if new.origen <> 'legacy_2018' then
    -- Dentro del ámbito
    if not exists (select 1 from public.municipis m where st_intersects(m.geom, new.geom)) then
      raise exception 'L''element està fora de l''àmbit de l''Observatori' using errcode = '22023';
    end if;
    -- Las parcelas nuevas vienen de SIGPAC
    if v_var.geometria = 'parcela' and new.sigpac_ref is null then
      raise exception 'Les parcel·les han de dur la referència SIGPAC' using errcode = '22023';
    end if;
  end if;

  -- Partida y municipio por posición
  select p.id, p.codcat into new.partida_id, new.codcat
    from public.partides p
   where st_intersects(p.geom, st_pointonsurface(new.geom))
   limit 1;
  if new.codcat is null then
    select m.codcat into new.codcat
      from public.municipis m
     where st_intersects(m.geom, st_pointonsurface(new.geom))
     limit 1;
  end if;

  -- Restricciones para usuarios (las cargas con service_role/postgres no tienen auth.uid())
  if v_usuari is not null then
    if tg_op = 'INSERT' then
      new.autor_id     := v_usuari;
      new.origen       := case when new.origen = 'app' then 'app'::origen_t else 'web'::origen_t end;
      new.estat        := 'pendent';
      new.validat_per  := null;
      new.validat_at   := null;
      new.motiu_rebuig := null;
      new.legacy_varid := null;
      new.legacy_nid   := null;
    elsif not v_canvi_estat then
      -- Edición normal: los campos de estado solo cambian vía canviar_estat()
      if new.estat is distinct from old.estat
         or new.validat_per is distinct from old.validat_per
         or new.validat_at is distinct from old.validat_at
         or new.motiu_rebuig is distinct from old.motiu_rebuig
         or new.autor_id is distinct from old.autor_id
         or new.origen is distinct from old.origen
         or new.legacy_varid is distinct from old.legacy_varid then
        raise exception 'L''estat només es canvia amb canviar_estat()' using errcode = '42501';
      end if;
      -- El autor corrige un elemento rechazado → vuelve a pendiente
      if old.estat = 'rebutjat' and old.autor_id = v_usuari then
        new.estat        := 'pendent';
        new.motiu_rebuig := null;
        new.validat_per  := null;
        new.validat_at   := null;
      end if;
    end if;
  end if;

  if tg_op = 'UPDATE' then
    new.updated_at := now();
  end if;
  return new;
end;
$$;

create trigger elements_abans_escriure
  before insert or update on public.elements
  for each row execute function public.elements_abans_escriure();

-- ─── Historial ─────────────────────────────────────────────────────────────

create function public.elements_historial()
returns trigger
language plpgsql security definer
set search_path = public, pg_temp
as $$
begin
  if tg_op = 'INSERT' then
    insert into public.element_historial (element_id, perfil_id, accio)
    values (new.id, auth.uid(), 'creat');
  elsif current_setting('observatori.canvi_estat', true) is distinct from 'on' then
    insert into public.element_historial (element_id, perfil_id, accio)
    values (new.id, auth.uid(), 'editat');
  end if;
  return null;
end;
$$;

create trigger elements_historial
  after insert or update on public.elements
  for each row execute function public.elements_historial();

-- ─── Cambio de estado (validar / rechazar / reabrir) ───────────────────────

create function public.canviar_estat(
  p_element_id uuid,
  p_estat      public.estat_t,
  p_motiu      text default null
)
returns public.elements
language plpgsql security definer
set search_path = public, pg_temp
as $$
declare
  v_usuari uuid := auth.uid();
  v_el     public.elements;
  v_coord  bool := public.es_coordinador();
  v_accio  text;
begin
  if v_usuari is null then
    raise exception 'Cal iniciar sessió' using errcode = '42501';
  end if;

  select * into v_el from public.elements where id = p_element_id for update;
  if not found then
    raise exception 'Element inexistent' using errcode = 'P0002';
  end if;

  if v_el.autor_id = v_usuari then
    raise exception 'No pots validar ni rebutjar les teues pròpies aportacions' using errcode = '42501';
  end if;

  if p_estat in ('validat', 'rebutjat') then
    if v_el.estat <> 'pendent' then
      raise exception 'Només es poden validar o rebutjar elements pendents' using errcode = '22023';
    end if;
    if not (v_coord or public.es_padri_de(v_el.partida_id)) then
      raise exception 'No tens permís per a validar en esta partida' using errcode = '42501';
    end if;
    if p_estat = 'rebutjat' and coalesce(trim(p_motiu), '') = '' then
      raise exception 'Cal indicar el motiu del rebuig' using errcode = '22023';
    end if;
    v_accio := p_estat::text;
  else -- p_estat = 'pendent' → reabrir
    if not v_coord then
      raise exception 'Només la coordinació pot reobrir elements' using errcode = '42501';
    end if;
    if v_el.estat = 'pendent' then
      raise exception 'L''element ja està pendent' using errcode = '22023';
    end if;
    v_accio := 'reobert';
  end if;

  perform set_config('observatori.canvi_estat', 'on', true);
  update public.elements
     set estat        = p_estat,
         validat_per  = case when p_estat = 'pendent' then null else v_usuari end,
         validat_at   = case when p_estat = 'pendent' then null else now() end,
         motiu_rebuig = case when p_estat = 'rebutjat' then p_motiu else null end
   where id = p_element_id
   returning * into v_el;
  perform set_config('observatori.canvi_estat', 'off', true);

  insert into public.element_historial (element_id, perfil_id, accio, detall)
  values (p_element_id, v_usuari, v_accio,
          case when p_motiu is not null then jsonb_build_object('motiu', p_motiu) end);

  return v_el;
end;
$$;

-- ─── Consulta por bbox → GeoJSON (respeta RLS: security invoker) ───────────

create function public.elements_bbox(
  p_minx double precision, p_miny double precision,
  p_maxx double precision, p_maxy double precision,
  p_tema_id int default null,
  p_variable_id int default null,
  p_estat public.estat_t default null
)
returns jsonb
language sql stable
set search_path = public, extensions, pg_temp
as $$
  select jsonb_build_object(
    'type', 'FeatureCollection',
    'features', coalesce(jsonb_agg(jsonb_build_object(
      'type', 'Feature',
      'id', e.id,
      'geometry', st_asgeojson(e.geom, 7)::jsonb,
      'properties', jsonb_build_object(
        'tema_id', v.tema_id, 'tema', t.nom,
        'variable_id', e.variable_id, 'variable', v.nom,
        'categoria', c.nom, 'estat', e.estat, 'origen', e.origen,
        'partida_id', e.partida_id, 'created_at', e.created_at
      )
    )), '[]'::jsonb)
  )
  from public.elements e
  join public.variables v on v.id = e.variable_id
  join public.temes t on t.id = v.tema_id
  left join public.categories c on c.id = e.categoria_id
  where e.geom && st_makeenvelope(p_minx, p_miny, p_maxx, p_maxy, 4326)
    and (p_tema_id is null or v.tema_id = p_tema_id)
    and (p_variable_id is null or e.variable_id = p_variable_id)
    and (p_estat is null or e.estat = p_estat);
$$;

-- ─── Custom access token hook: rol y partidas en el JWT ────────────────────

create function public.custom_access_token_hook(event jsonb)
returns jsonb
language plpgsql stable security definer
set search_path = public, pg_temp
as $$
declare
  v_uid     uuid := (event ->> 'user_id')::uuid;
  v_rol     text;
  v_partides jsonb;
  v_claims  jsonb := event -> 'claims';
begin
  select rol::text into v_rol from public.perfils where id = v_uid;
  select coalesce(jsonb_agg(partida_id), '[]'::jsonb) into v_partides
    from public.padrinatges
   where perfil_id = v_uid
     and des_de <= current_date
     and (fins is null or fins >= current_date);

  v_claims := jsonb_set(v_claims, '{app_metadata}', coalesce(v_claims -> 'app_metadata', '{}'::jsonb));
  v_claims := jsonb_set(v_claims, '{app_metadata,rol}', to_jsonb(coalesce(v_rol, 'ciutada')));
  v_claims := jsonb_set(v_claims, '{app_metadata,partides}', v_partides);
  return jsonb_set(event, '{claims}', v_claims);
end;
$$;

grant execute on function public.custom_access_token_hook(jsonb) to supabase_auth_admin;
revoke execute on function public.custom_access_token_hook(jsonb) from authenticated, anon, public;
