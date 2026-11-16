-- ═══════════════════════════════════════════════════════════════════════════
-- Resumen diario de avisos por correo.
--
-- Los avisos (notificacions) solo se veían al abrir la web o la app. Una vez al día,
-- quien tenga avisos nuevos sin leer recibe un correo con la lista y los enlaces:
-- sobre todo el padrí o padrina con aportaciones por validar, que se validan en la web.
--
-- · Lo envía la propia base de datos: pg_cron lo lanza y pg_net llama a la API de
--   Brevo (el mismo remitente verificado que los correos de entrada).
-- · La clave de la API de Brevo está en el Vault de Supabase con el nombre
--   'brevo_api_key'; la crea la persona responsable desde el editor SQL. Sin la clave
--   no se envía nada (y no falla).
-- · Cada aviso va en un solo correo (notificacions.enviada_correu). Solo entran los de
--   los últimos 14 días, y una aportación que ya no está pendiente no se pide validar.
-- · Se puede desactivar desde la campana de avisos de la web (perfils.resum_correu).
-- ═══════════════════════════════════════════════════════════════════════════

create extension if not exists pg_net with schema extensions;
create extension if not exists pg_cron with schema pg_catalog;

alter table public.perfils add column resum_correu bool not null default true;
grant update (resum_correu) on public.perfils to authenticated;

alter table public.notificacions add column enviada_correu timestamptz;
create index notificacions_per_enviar_idx on public.notificacions (perfil_id)
  where enviada_correu is null and not llegida;

-- Registro de envíos (para comprobar la respuesta de Brevo en net._http_response)
create table public.correus_resum (
  id          bigserial primary key,
  perfil_id   uuid not null references public.perfils on delete cascade,
  n_avisos    int not null,
  request_id  bigint,
  created_at  timestamptz not null default now()
);
alter table public.correus_resum enable row level security;   -- sin políticas: solo postgres

-- La dirección de la web; cambiará cuando haya dominio propio
create function public.url_web()
returns text
language sql immutable
as $$ select 'https://observatoriplh.vercel.app' $$;

create function public.escapar_html(p text)
returns text
language sql immutable
as $$
  select replace(replace(replace(replace(replace(coalesce(p, ''),
    '&', '&amp;'), '<', '&lt;'), '>', '&gt;'), '"', '&quot;'), '''', '&#39;')
$$;

-- ─── El contenido de cada correo ───────────────────────────────────────────
-- Una fila por persona con avisos por enviar. Separado del envío para poder probarlo.

create function public.resums_avisos()
returns table (perfil_id uuid, email text, assumpte text, text_pla text, html text, ids bigint[])
language sql stable security definer
set search_path = public, pg_temp
as $$
  with avisos as (
    select n.id, n.perfil_id, n.accio, n.motiu, n.element_id, n.created_at,
           coalesce(nullif(e.text_lliure, ''), v.nom) as titol,
           pa.nom as partida,
           case n.accio
             when 'nova_aportacio' then 1
             when 'revisat'        then 3
             else 2
           end as grup
      from public.notificacions n
      join public.perfils p   on p.id = n.perfil_id and p.resum_correu
      join public.elements e  on e.id = n.element_id
      join public.variables v on v.id = e.variable_id
      left join public.partides pa on pa.id = e.partida_id
     where n.enviada_correu is null
       and not n.llegida
       and n.created_at > now() - interval '14 days'
       -- ya validada, rechazada o de baja: no hay nada que pedir
       and (n.accio <> 'nova_aportacio' or (e.estat = 'pendent' and e.baixa_at is null))
  ),
  linies as (
    select a.*,
           a.titol || coalesce(' — ' || a.partida, '') ||
           case a.accio
             when 'validat'  then ': validada'
             when 'rebutjat' then ': rebutjada' || coalesce(' (' || a.motiu || ')', '')
             when 'reobert'  then ': torna a estar pendent'
             when 'revisat'  then case a.motiu
                                    when 'igual'     then ': continua igual'
                                    when 'canviat'   then ': ha canviat'
                                    when 'no_trobat' then ': no s''ha trobat (donat de baixa)'
                                    else '' end
             else ''
           end as linia,
           case a.accio
             when 'nova_aportacio' then public.url_web() || '/validacio'
             else public.url_web() || '/mapa?element=' || a.element_id
           end as enllac,
           row_number() over (partition by a.perfil_id, a.grup order by a.created_at desc) as ordre
      from avisos a
  ),
  grups as (
    select l.perfil_id, l.grup,
           case l.grup
             when 1 then 'Aportacions noves per validar a les teues partides'
             when 2 then 'Les teues aportacions'
             else        'Revisions a les teues partides'
           end as titol,
           count(*) as n,
           -- Como mucho 10 por grupo; el resto, «i N més»
           string_agg('• ' || l.linia, E'\n' order by l.created_at desc) filter (where l.ordre <= 10) as text_pla,
           string_agg('<li><a href="' || public.escapar_html(l.enllac) || '">' || public.escapar_html(l.linia) || '</a></li>',
                      '' order by l.created_at desc) filter (where l.ordre <= 10) as html,
           array_agg(l.id) as ids
      from linies l
     group by l.perfil_id, l.grup
  ),
  persones as (
    select g.perfil_id,
           sum(g.n)::int as total,
           string_agg(
             g.titol || E'\n' || g.text_pla ||
             case when g.n > 10 then E'\n  i ' || (g.n - 10) || ' més' else '' end ||
             case when g.grup = 1 then E'\nEs validen des del panell de validació: ' || public.url_web() || '/validacio' else '' end,
             E'\n\n' order by g.grup) as cos_text,
           string_agg(
             '<h2 style="font-size:16px;margin:24px 0 8px">' || g.titol || '</h2><ul style="padding-left:20px;margin:0">' ||
             g.html || case when g.n > 10 then '<li>i ' || (g.n - 10) || ' més</li>' else '' end || '</ul>' ||
             case when g.grup = 1 then '<p><a href="' || public.url_web() || '/validacio" style="display:inline-block;padding:8px 16px;border-radius:6px;background:#2C7A00;color:#fff;text-decoration:none">Obri el panell de validació</a></p>' else '' end,
             '' order by g.grup) as cos_html,
           (select array_agg(i) from grups g2, unnest(g2.ids) i where g2.perfil_id = g.perfil_id) as ids
      from grups g
     group by g.perfil_id
  )
  select p.perfil_id, u.email::text,
         case when p.total = 1 then 'Tens 1 avís nou a l''Observatori Ciutadà de l''Horta'
              else 'Tens ' || p.total || ' avisos nous a l''Observatori Ciutadà de l''Horta' end,
         p.cos_text || E'\n\n—\nReps aquest correu perquè tens avisos sense llegir a ' || public.url_web() ||
           E'.\nPots deixar de rebre''l des de la campana d''avisos de la web.',
         '<div style="font-family:Arial,sans-serif;font-size:15px;line-height:1.5;color:#1d1d1b;max-width:600px">' ||
           '<p style="color:#2C7A00;font-weight:bold">Observatori Ciutadà de l''Horta</p>' || p.cos_html ||
           '<hr style="border:none;border-top:1px solid #ddd;margin:24px 0"><p style="font-size:13px;color:#555">' ||
           'Reps aquest correu perquè tens avisos sense llegir a <a href="' || public.url_web() || '">l''Observatori</a>. ' ||
           'Pots deixar de rebre''l des de la campana d''avisos de la web.</p></div>',
         p.ids
    from persones p
    join auth.users u on u.id = p.perfil_id
   where u.email is not null and u.email <> '';
$$;

revoke execute on function public.resums_avisos() from public, anon, authenticated;

-- ─── El envío ──────────────────────────────────────────────────────────────

create function public.enviar_resums_avisos()
returns int
language plpgsql security definer
set search_path = public, pg_temp
as $$
declare
  v_clau text;
  v_req bigint;
  v_n int := 0;
  r record;
begin
  select decrypted_secret into v_clau from vault.decrypted_secrets where name = 'brevo_api_key';
  if v_clau is null or v_clau = '' then
    raise notice 'resum d''avisos: falta la clau brevo_api_key al Vault, no s''envia res';
    return 0;
  end if;

  for r in select * from public.resums_avisos() loop
    v_req := net.http_post(
      url     := 'https://api.brevo.com/v3/smtp/email',
      headers := jsonb_build_object('api-key', v_clau, 'content-type', 'application/json', 'accept', 'application/json'),
      body    := jsonb_build_object(
        'sender', jsonb_build_object('name', 'Observatori Ciutadà de l''Horta', 'email', 'desarrollo@mediamapes.com'),
        'to', jsonb_build_array(jsonb_build_object('email', r.email)),
        'subject', r.assumpte,
        'textContent', r.text_pla,
        'htmlContent', r.html,
        'tags', jsonb_build_array('resum-avisos')
      ),
      timeout_milliseconds := 10000
    );
    update public.notificacions set enviada_correu = now() where id = any (r.ids);
    insert into public.correus_resum (perfil_id, n_avisos, request_id) values (r.perfil_id, cardinality(r.ids), v_req);
    v_n := v_n + 1;
  end loop;
  return v_n;
end;
$$;

revoke execute on function public.enviar_resums_avisos() from public, anon, authenticated;

-- Cada día a las 17:00 UTC (las 18:00 en invierno, las 19:00 en verano)
select cron.schedule('resum-avisos-correu', '0 17 * * *', $$select public.enviar_resums_avisos()$$);
