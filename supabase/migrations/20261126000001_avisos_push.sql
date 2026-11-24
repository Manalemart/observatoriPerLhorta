-- ═══════════════════════════════════════════════════════════════════════════
-- Avisos al mòbil (notificacions push).
--
-- Cada aviso nou (notificacions) s'envia també als mòbils de la persona:
--
--   notificacions (insert) ─► trigger ─► pg_net ─► funció Edge «enviar-push» ─► FCM ─► Android / iOS
--
-- · La app registra el seu token de Firebase Cloud Messaging en dispositius_push
--   (registrar_dispositiu) en entrar i l'esborra en eixir (oblidar_dispositiu).
-- · El trigger no espera: pg_net crida la funció de fons. Si falta la configuració
--   (Vault: «push_url» i «push_secret»), no s'envia res i no falla.
-- · La funció «enviar-push» (supabase/functions/enviar-push) té el compte de servei de
--   Firebase; la base de dades només li passa l'identificador de l'aviso.
-- · Es pot desactivar en la pantalla d'avisos (perfils.avisos_push).
-- · Esborrar el compte esborra els tokens (on delete cascade).
-- Vegeu docs/PUSH.md.
-- ═══════════════════════════════════════════════════════════════════════════

create extension if not exists pg_net with schema extensions;

alter table public.perfils add column avisos_push bool not null default true;
grant update (avisos_push) on public.perfils to authenticated;

create table public.dispositius_push (
  token       text primary key,
  perfil_id   uuid not null references public.perfils on delete cascade,
  plataforma  text not null check (plataforma in ('android', 'ios')),
  idioma      text not null default 'ca' check (idioma in ('ca', 'es', 'en')),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);
create index dispositius_push_perfil_idx on public.dispositius_push (perfil_id);
alter table public.dispositius_push enable row level security;

-- Cada persona veu els seus; s'escriuen només amb les funcions de baix
create policy dispositius_push_propis on public.dispositius_push
  for select to authenticated using (perfil_id = auth.uid());

-- ─── Registrar i oblidar el dispositiu (des de la app) ─────────────────────
-- Un token és d'un sol mòbil: si abans era d'una altra persona (s'ha canviat de compte
-- en el mateix mòbil), passa a la que l'ha registrat ara.
create function public.registrar_dispositiu(p_token text, p_plataforma text, p_idioma text default 'ca')
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'Cal haver entrat' using errcode = '42501';
  end if;
  if p_token is null or length(p_token) < 20 or length(p_token) > 4096 then
    raise exception 'Token no vàlid' using errcode = '22023';
  end if;
  insert into public.dispositius_push (token, perfil_id, plataforma, idioma)
  values (p_token, auth.uid(), p_plataforma, case when p_idioma in ('es', 'en') then p_idioma else 'ca' end)
  on conflict (token) do update
    set perfil_id = excluded.perfil_id, plataforma = excluded.plataforma,
        idioma = excluded.idioma, updated_at = now();
end;
$$;

create function public.oblidar_dispositiu(p_token text)
returns void
language sql
security definer
set search_path = ''
as $$
  delete from public.dispositius_push where token = p_token and perfil_id = auth.uid();
$$;

revoke all on function public.registrar_dispositiu(text, text, text) from public, anon;
revoke all on function public.oblidar_dispositiu(text) from public, anon;
grant execute on function public.registrar_dispositiu(text, text, text) to authenticated;
grant execute on function public.oblidar_dispositiu(text) to authenticated;

-- ─── Enviar: un aviso nou ─► la funció Edge ────────────────────────────────
create function public._push_aviso()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_url text;
  v_secret text;
begin
  -- Ningú a qui enviar-ho: no cal cridar la funció
  if not exists (
    select 1 from public.dispositius_push d
    join public.perfils p on p.id = d.perfil_id
    where d.perfil_id = new.perfil_id and p.avisos_push
  ) then
    return null;
  end if;

  select decrypted_secret into v_url from vault.decrypted_secrets where name = 'push_url';
  select decrypted_secret into v_secret from vault.decrypted_secrets where name = 'push_secret';
  if coalesce(v_url, '') = '' or coalesce(v_secret, '') = '' then
    return null; -- sense configurar: no s'envia res
  end if;

  perform net.http_post(
    url := v_url,
    headers := jsonb_build_object('content-type', 'application/json', 'x-push-secret', v_secret),
    body := jsonb_build_object('notificacio_id', new.id),
    timeout_milliseconds := 10000
  );
  return null;
exception when others then
  -- Un aviso no es perd mai per l'enviament: queda en la app i en el resum per correu
  raise warning 'push: %', sqlerrm;
  return null;
end;
$$;

revoke all on function public._push_aviso() from public, anon, authenticated;

create trigger notificacions_push
  after insert on public.notificacions
  for each row execute function public._push_aviso();

-- ─── Les meues dades: també els dispositius ────────────────────────────────
create or replace function public.les_meues_dades()
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object(
    'generat', now(),
    'compte', (
      select jsonb_build_object('id', u.id, 'correu', u.email, 'alta', u.created_at, 'darrera_entrada', u.last_sign_in_at)
      from auth.users u where u.id = auth.uid()
    ),
    'perfil', (
      select jsonb_build_object('alies', p.nom_public, 'rol', p.rol, 'resum_correu', p.resum_correu,
                                'avisos_push', p.avisos_push, 'idioma', p.idioma, 'alta', p.created_at)
      from public.perfils p where p.id = auth.uid()
    ),
    'dispositius_push', coalesce((
      select jsonb_agg(jsonb_build_object('plataforma', d.plataforma, 'idioma', d.idioma, 'alta', d.created_at))
      from public.dispositius_push d where d.perfil_id = auth.uid()
    ), '[]'::jsonb),
    'partides_apadrinades', coalesce((
      select jsonb_agg(jsonb_build_object('partida', pa.nom, 'municipi', pa.codcat))
      from public.padrinatges pd join public.partides pa on pa.id = pd.partida_id
      where pd.perfil_id = auth.uid()
    ), '[]'::jsonb),
    'aportacions', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', e.id,
        'variable', v.nom,
        'categoria', c.nom,
        'text_lliure', e.text_lliure,
        'descripcio', e.descripcio,
        'estat', e.estat,
        'motiu_rebuig', e.motiu_rebuig,
        'data', e.created_at,
        'geometria', extensions.st_asgeojson(e.geom)::jsonb,
        'fotos', coalesce((select jsonb_agg(f.storage_path) from public.element_fotos f where f.element_id = e.id), '[]'::jsonb)
      ) order by e.created_at)
      from public.elements e
      join public.variables v on v.id = e.variable_id
      left join public.categories c on c.id = e.categoria_id
      where e.autor_id = auth.uid()
    ), '[]'::jsonb),
    'avisos', coalesce((
      select jsonb_agg(jsonb_build_object('accio', n.accio, 'motiu', n.motiu, 'llegit', n.llegida, 'data', n.created_at)
                       order by n.created_at)
      from public.notificacions n where n.perfil_id = auth.uid()
    ), '[]'::jsonb)
  )
  where auth.uid() is not null;
$$;
