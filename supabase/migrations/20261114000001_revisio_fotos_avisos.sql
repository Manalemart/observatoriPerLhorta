-- ═══════════════════════════════════════════════════════════════════════════
-- Revisión en el campo, fase 3: fotos en la revisión y avisos al padrí.
--
-- · Fotos: «Igual / Ha canviat / No el trobe» pueden llevar hasta 3 fotos. La app las sube
--   antes (bucket 'fotos', <uid>/<element_id>/<nom>.jpg) y revisar_element() las enlaza
--   al elemento: así el inventario tiene una foto de cómo está hoy.
-- · Reintentos: la app manda la revisión desde la cola del móvil y puede repetirla si se
--   corta la respuesta. Con p_id (el id de la cola) la segunda vez no hace nada.
-- · Avisos al padrí o padrina de la partida (en la app y en la campana de la web):
--     nova_aportacio → alguien ha aportado algo en su partida y le toca validarlo;
--     revisat        → otra persona (la coordinación o un co-padrí) ha revisado un
--                      elemento de su partida; motiu = igual / canviat / no_trobat.
-- ═══════════════════════════════════════════════════════════════════════════

alter table public.notificacions drop constraint notificacions_accio_check;
alter table public.notificacions add constraint notificacions_accio_check
  check (accio in ('validat', 'rebutjat', 'reobert', 'nova_aportacio', 'revisat'));

-- Padrins vigentes de una partida (para avisarles)
create function public.padrins_de(p_partida_id int)
returns setof uuid
language sql stable security definer
set search_path = public, pg_temp
as $$
  select distinct perfil_id from public.padrinatges
   where partida_id = p_partida_id
     and des_de <= current_date
     and (fins is null or fins >= current_date);
$$;

revoke execute on function public.padrins_de(int) from public, anon, authenticated;

-- ─── Aviso: aportación nueva en la partida ─────────────────────────────────

create function public.notificar_nova_aportacio()
returns trigger
language plpgsql security definer
set search_path = public, pg_temp
as $$
begin
  insert into public.notificacions (perfil_id, element_id, accio)
  select p, new.id, 'nova_aportacio'
    from public.padrins_de(new.partida_id) p
   where p is distinct from new.autor_id;
  return null;
end;
$$;

create trigger elements_notificar_padri
  after insert on public.elements
  for each row
  when (new.estat = 'pendent' and new.origen <> 'legacy_2018' and new.partida_id is not null)
  execute function public.notificar_nova_aportacio();

-- ─── revisar_element con fotos e id de la cola ─────────────────────────────

drop function public.revisar_element(uuid, text, text);

create function public.revisar_element(
  p_element_id uuid,
  p_resultat   text,
  p_nota       text   default null,
  p_fotos      text[] default null,
  p_id         uuid   default null
)
returns jsonb
language plpgsql security definer
set search_path = public, pg_temp
as $$
declare
  v_usuari uuid := auth.uid();
  v_el     public.elements;
  v_ara    timestamptz := now();
  v_nota   text := nullif(btrim(p_nota), '');
  v_fotos  text[] := coalesce(p_fotos, '{}');
  v_foto   text;
  v_prev   public.element_historial;
begin
  if v_usuari is null then
    raise exception 'Cal iniciar sessió' using errcode = '42501';
  end if;

  -- Ya llegó (la app reintenta si no le llegó la respuesta)
  if p_id is not null then
    select * into v_prev from public.element_historial
     where element_id = p_element_id and perfil_id = v_usuari and detall ->> 'id' = p_id::text
     limit 1;
    if found then
      return jsonb_build_object('resultat', p_resultat, 'revisat_at', v_prev.created_at, 'repetida', true);
    end if;
  end if;

  if p_resultat not in ('igual', 'canviat', 'no_trobat') then
    raise exception 'Resultat desconegut: %', p_resultat using errcode = '22023';
  end if;
  if cardinality(v_fotos) > 3 then
    raise exception 'Com a màxim 3 fotos' using errcode = '22023';
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

  -- Las fotos: subidas por quien revisa, en la carpeta de este elemento
  foreach v_foto in array v_fotos loop
    if v_foto !~ ('^' || v_usuari::text || '/' || p_element_id::text || '/[A-Za-z0-9_-]+\.jpg$') then
      raise exception 'Ruta de foto no vàlida: %', v_foto using errcode = '22023';
    end if;
    if not exists (select 1 from storage.objects where bucket_id = 'fotos' and name = v_foto) then
      raise exception 'La foto no s''ha pujat: %', v_foto using errcode = '22023';
    end if;
  end loop;

  -- «Igual» repetido el mismo mes por la misma persona, sin nada nuevo, no suma nada
  if p_resultat = 'igual' and v_nota is null and cardinality(v_fotos) = 0 and exists (
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

  insert into public.element_fotos (element_id, storage_path, autor_id)
  select p_element_id, f, v_usuari from unnest(v_fotos) f
  on conflict (storage_path) do nothing;

  insert into public.element_historial (element_id, perfil_id, accio, detall)
  values (p_element_id, v_usuari,
          case p_resultat when 'igual' then 'confirmat' else p_resultat end,
          nullif(jsonb_strip_nulls(jsonb_build_object(
            'nota', v_nota,
            'fotos', case when cardinality(v_fotos) > 0 then to_jsonb(v_fotos) end,
            'id', p_id)), '{}'::jsonb));

  -- Avisar al resto de padrins de la partida
  insert into public.notificacions (perfil_id, element_id, accio, motiu)
  select p, p_element_id, 'revisat', p_resultat
    from public.padrins_de(v_el.partida_id) p
   where p <> v_usuari;

  return jsonb_build_object('resultat', p_resultat, 'revisat_at', v_ara);
end;
$$;

revoke execute on function public.revisar_element(uuid, text, text, text[], uuid) from public, anon;
grant execute on function public.revisar_element(uuid, text, text, text[], uuid) to authenticated;

create or replace function public.confirmar_element(p_element_id uuid)
returns timestamptz
language sql security definer
set search_path = public, pg_temp
as $$
  select (public.revisar_element(p_element_id, 'igual') ->> 'revisat_at')::timestamptz;
$$;
