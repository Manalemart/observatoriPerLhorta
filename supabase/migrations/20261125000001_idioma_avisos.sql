-- ═══════════════════════════════════════════════════════════════════════════
-- L'idioma de cada persona, per als correus i els avisos push.
--
-- · perfils.idioma ('ca', 'es' o 'en'): el posen la web i la app amb l'idioma que
--   mostren (en entrar i quan es canvia). Al registrar-se, el de la web o la app des
--   d'on s'ha demanat el codi (raw_user_meta_data.idioma).
-- · Es copia a auth.users.raw_user_meta_data.idioma perquè les plantilles de correu
--   de Supabase (codi d'entrada) el puguen llegir com a {{ .Data.idioma }}.
-- · El resum diari d'avisos ix en l'idioma de cada persona, amb els noms del catàleg
--   traduïts (nom_es / nom_en).
-- ═══════════════════════════════════════════════════════════════════════════

alter table public.perfils add column if not exists idioma text not null default 'ca'
  check (idioma in ('ca', 'es', 'en'));
grant update (idioma) on public.perfils to authenticated;

-- Al registrar-se: l'àlies i l'idioma de la web o la app
create or replace function public.crear_perfil()
returns trigger
language plpgsql security definer
set search_path = public, pg_temp
as $$
begin
  insert into public.perfils (id, nom_public, idioma)
  values (new.id, new.raw_user_meta_data ->> 'nom_public',
          case when new.raw_user_meta_data ->> 'idioma' in ('ca', 'es', 'en')
               then new.raw_user_meta_data ->> 'idioma' else 'ca' end);
  return new;
end;
$$;

-- perfils.idioma → auth.users (per a les plantilles de correu)
create function public.copiar_idioma_usuari()
returns trigger
language plpgsql security definer
set search_path = public, pg_temp
as $$
begin
  update auth.users
     set raw_user_meta_data = coalesce(raw_user_meta_data, '{}'::jsonb) || jsonb_build_object('idioma', new.idioma)
   where id = new.id;
  return new;
end;
$$;

revoke execute on function public.copiar_idioma_usuari() from public, anon, authenticated;

create trigger perfils_copiar_idioma
  after update of idioma on public.perfils
  for each row when (old.idioma is distinct from new.idioma)
  execute function public.copiar_idioma_usuari();

-- Tria el text segons l'idioma
create function public.tr(p_idioma text, p_ca text, p_es text, p_en text)
returns text
language sql immutable
as $$ select case p_idioma when 'es' then p_es when 'en' then p_en else p_ca end $$;

-- ─── El resum diari, en l'idioma de cada persona ───────────────────────────

create or replace function public.resums_avisos()
returns table (perfil_id uuid, email text, assumpte text, text_pla text, html text, ids bigint[])
language sql stable security definer
set search_path = public, pg_temp
as $$
  with avisos as (
    select n.id, n.perfil_id, n.accio, n.motiu, n.element_id, n.created_at, p.idioma,
           coalesce(nullif(e.text_lliure, ''),
                    case p.idioma when 'es' then coalesce(v.nom_es, v.nom)
                                  when 'en' then coalesce(v.nom_en, v.nom)
                                  else v.nom end) as titol,
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
       -- ja validada, rebutjada o de baixa: no hi ha res a demanar
       and (n.accio <> 'nova_aportacio' or (e.estat = 'pendent' and e.baixa_at is null))
  ),
  linies as (
    select a.*,
           a.titol || coalesce(' — ' || a.partida, '') ||
           case a.accio
             when 'validat'  then public.tr(a.idioma, ': validada', ': validada', ': validated')
             when 'rebutjat' then public.tr(a.idioma, ': rebutjada', ': rechazada', ': rejected')
                                  || coalesce(' (' || a.motiu || ')', '')
             when 'reobert'  then public.tr(a.idioma, ': torna a estar pendent', ': vuelve a estar pendiente', ': pending again')
             when 'revisat'  then case a.motiu
                                    when 'igual'     then public.tr(a.idioma, ': continua igual', ': sigue igual', ': unchanged')
                                    when 'canviat'   then public.tr(a.idioma, ': ha canviat', ': ha cambiado', ': has changed')
                                    when 'no_trobat' then public.tr(a.idioma, ': no s''ha trobat (donat de baixa)',
                                                                    ': no se ha encontrado (dado de baja)',
                                                                    ': not found (retired)')
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
    select l.perfil_id, l.idioma, l.grup,
           case l.grup
             when 1 then public.tr(l.idioma, 'Aportacions noves per validar a les teues partides',
                                   'Aportaciones nuevas por validar en tus partidas',
                                   'New contributions to validate in your partidas')
             when 2 then public.tr(l.idioma, 'Les teues aportacions', 'Tus aportaciones', 'Your contributions')
             else        public.tr(l.idioma, 'Revisions a les teues partides', 'Revisiones en tus partidas',
                                   'Reviews in your partidas')
           end as titol,
           count(*) as n,
           -- Com a molt 10 per grup; la resta, «i N més»
           string_agg('• ' || l.linia, E'\n' order by l.created_at desc) filter (where l.ordre <= 10) as text_pla,
           string_agg('<li><a href="' || public.escapar_html(l.enllac) || '">' || public.escapar_html(l.linia) || '</a></li>',
                      '' order by l.created_at desc) filter (where l.ordre <= 10) as html,
           array_agg(l.id) as ids
      from linies l
     group by l.perfil_id, l.idioma, l.grup
  ),
  persones as (
    select g.perfil_id, g.idioma,
           sum(g.n)::int as total,
           string_agg(
             g.titol || E'\n' || g.text_pla ||
             case when g.n > 10
                  then E'\n  ' || public.tr(g.idioma, 'i ', 'y ', 'and ') || (g.n - 10) || public.tr(g.idioma, ' més', ' más', ' more')
                  else '' end ||
             case when g.grup = 1
                  then E'\n' || public.tr(g.idioma, 'Es validen des del panell de validació: ',
                                          'Se validan desde el panel de validación: ',
                                          'Validate them from the validation panel: ') || public.url_web() || '/validacio'
                  else '' end,
             E'\n\n' order by g.grup) as cos_text,
           string_agg(
             '<h2 style="font-size:16px;margin:24px 0 8px">' || g.titol || '</h2><ul style="padding-left:20px;margin:0">' ||
             g.html ||
             case when g.n > 10
                  then '<li>' || public.tr(g.idioma, 'i ', 'y ', 'and ') || (g.n - 10) || public.tr(g.idioma, ' més', ' más', ' more') || '</li>'
                  else '' end || '</ul>' ||
             case when g.grup = 1
                  then '<p><a href="' || public.url_web() || '/validacio" style="display:inline-block;padding:8px 16px;border-radius:6px;background:#2C7A00;color:#fff;text-decoration:none">' ||
                       public.tr(g.idioma, 'Obri el panell de validació', 'Abre el panel de validación', 'Open the validation panel') || '</a></p>'
                  else '' end,
             '' order by g.grup) as cos_html,
           (select array_agg(i) from grups g2, unnest(g2.ids) i where g2.perfil_id = g.perfil_id) as ids
      from grups g
     group by g.perfil_id, g.idioma
  )
  select p.perfil_id, u.email::text,
         case when p.total = 1
              then public.tr(p.idioma, 'Tens 1 avís nou a l''Observatori Ciutadà de l''Horta',
                                       'Tienes 1 aviso nuevo en el Observatori Ciutadà de l''Horta',
                                       'You have 1 new notification at the Observatori Ciutadà de l''Horta')
              else public.tr(p.idioma, 'Tens ', 'Tienes ', 'You have ') || p.total ||
                   public.tr(p.idioma, ' avisos nous a l''Observatori Ciutadà de l''Horta',
                                       ' avisos nuevos en el Observatori Ciutadà de l''Horta',
                                       ' new notifications at the Observatori Ciutadà de l''Horta') end,
         p.cos_text || E'\n\n—\n' ||
           public.tr(p.idioma, 'Reps aquest correu perquè tens avisos sense llegir a ',
                               'Recibes este correo porque tienes avisos sin leer en ',
                               'You are receiving this email because you have unread notifications at ') ||
           public.url_web() || E'.\n' ||
           public.tr(p.idioma, 'Pots deixar de rebre''l des de la campana d''avisos de la web.',
                               'Puedes dejar de recibirlo desde la campana de avisos de la web.',
                               'You can stop receiving it from the notifications bell on the website.'),
         '<div style="font-family:Arial,sans-serif;font-size:15px;line-height:1.5;color:#1d1d1b;max-width:600px">' ||
           '<p style="color:#2C7A00;font-weight:bold">Observatori Ciutadà de l''Horta</p>' || p.cos_html ||
           '<hr style="border:none;border-top:1px solid #ddd;margin:24px 0"><p style="font-size:13px;color:#555">' ||
           public.tr(p.idioma, 'Reps aquest correu perquè tens avisos sense llegir a ',
                               'Recibes este correo porque tienes avisos sin leer en ',
                               'You are receiving this email because you have unread notifications at ') ||
           '<a href="' || public.url_web() || '">' ||
           public.tr(p.idioma, 'l''Observatori', 'el Observatori', 'the Observatori') || '</a>. ' ||
           public.tr(p.idioma, 'Pots deixar de rebre''l des de la campana d''avisos de la web.',
                               'Puedes dejar de recibirlo desde la campana de avisos de la web.',
                               'You can stop receiving it from the notifications bell on the website.') ||
           '</p></div>',
         p.ids
    from persones p
    join auth.users u on u.id = p.perfil_id
   where u.email is not null and u.email <> '';
$$;

revoke execute on function public.resums_avisos() from public, anon, authenticated;
