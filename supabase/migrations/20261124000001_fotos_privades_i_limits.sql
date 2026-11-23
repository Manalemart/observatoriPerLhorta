-- ═══════════════════════════════════════════════════════════════════════════
-- Fotos: bucket privat i límits d'enviament.
--
-- 1. El bucket «fotos» deixa de ser públic. Les fotos es veuen amb URL signades
--    (createSignedUrl), i les pot signar qui les pot veure:
--      · tothom (també sense compte): les dels elements validats;
--      · qui les ha pujades, la coordinació i el padrí o padrina de la partida: la resta.
--    Les fotos d'una aportació pendent o rebutjada ja no s'obrin per URL sense permís.
--
-- 2. Límits per persona (la app i la web ja en tenen; ara també el servidor):
--      · aportacions: 30 per hora;
--      · fotos per aportació sense publicar: 5 (Config.maxFotos en la app, MAX_FOTOS en la web);
--      · fitxers pujats al bucket: 100 per hora.
--    La coordinació no té límit d'aportacions (càrregues i correccions en bloc).
-- ═══════════════════════════════════════════════════════════════════════════

update storage.buckets set public = false where id = 'fotos';

-- ─── Lectura (i, per tant, URL signades) ───────────────────────────────────
-- security definer: la política no pot consultar element_fotos/elements amb l'RLS de qui
-- llig (un anònim no veu els pendents i la condició sempre seria falsa per a ells).
create or replace function public.pot_veure_foto(p_nom text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.element_fotos f
    join public.elements e on e.id = f.element_id
    where f.storage_path = p_nom
      and (
        e.estat = 'validat'
        or (auth.uid() is not null and (e.autor_id = auth.uid() or public.es_coordinador() or public.es_padri_de(e.partida_id)))
      )
  );
$$;

revoke all on function public.pot_veure_foto(text) from public;
grant execute on function public.pot_veure_foto(text) to anon, authenticated;

drop policy if exists fotos_llegir_propies on storage.objects;
create policy fotos_llegir on storage.objects
  for select to anon, authenticated
  using (
    bucket_id = 'fotos'
    and (
      (auth.uid() is not null and ((storage.foldername(name))[1] = auth.uid()::text or public.es_coordinador()))
      or public.pot_veure_foto(name)
    )
  );

-- ─── Límit de fitxers pujats ───────────────────────────────────────────────
create or replace function public.fotos_pujades_ultima_hora()
returns integer
language sql
stable
security definer
set search_path = ''
as $$
  select count(*)::int
  from storage.objects
  where bucket_id = 'fotos'
    and (storage.foldername(name))[1] = auth.uid()::text
    and created_at > now() - interval '1 hour';
$$;

revoke all on function public.fotos_pujades_ultima_hora() from public, anon;
grant execute on function public.fotos_pujades_ultima_hora() to authenticated;

drop policy if exists fotos_pujar on storage.objects;
create policy fotos_pujar on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'fotos'
    and (storage.foldername(name))[1] = auth.uid()::text
    and public.fotos_pujades_ultima_hora() < 100
  );

-- ─── Límit d'aportacions i de fotos per element ────────────────────────────
create or replace function public.limit_aportacions()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is not null and not public.es_coordinador() and (
    select count(*) from public.elements
    where autor_id = auth.uid() and created_at > now() - interval '1 hour'
  ) >= 30 then
    raise exception 'Has enviat moltes aportacions en poca estona. Espera una mica i torna-ho a provar.'
      using errcode = '22023';
  end if;
  return new;
end;
$$;

revoke all on function public.limit_aportacions() from public, anon, authenticated;

create trigger elements_limit
  before insert on public.elements
  for each row execute function public.limit_aportacions();

create or replace function public.limit_fotos_element()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  -- Només en les aportacions encara sense publicar: les revisions de camp afegixen fotos a
  -- elements ja validats i, amb els anys, en poden acumular més (revisar_element en limita 3 per revisió)
  if exists (select 1 from public.elements where id = new.element_id and estat <> 'validat')
     and (select count(*) from public.element_fotos where element_id = new.element_id) >= 5 then
    raise exception 'Un element no pot tindre més de 5 fotos.' using errcode = '22023';
  end if;
  return new;
end;
$$;

revoke all on function public.limit_fotos_element() from public, anon, authenticated;

create trigger element_fotos_limit
  before insert on public.element_fotos
  for each row execute function public.limit_fotos_element();
