-- ═══════════════════════════════════════════════════════════════════════════
-- Fase 2: datos abiertos, vista del padrí, noticias y notificaciones.
-- ═══════════════════════════════════════════════════════════════════════════

-- ─── Privacidad: un anónimo no puede saber quién aportó ni quién validó ────
-- La RLS filtra filas, no columnas: hasta ahora la API devolvía autor_id a cualquiera.

revoke select on public.elements from anon;
grant select (
  id, variable_id, categoria_id, text_lliure, descripcio, geom, partida_id, codcat,
  sigpac_ref, sigpac_dn_pk, sigpac_data, origen, estat, validat_at, motiu_rebuig,
  created_at, updated_at
) on public.elements to anon;

revoke select on public.element_fotos from anon;
grant select (id, element_id, storage_path, created_at) on public.element_fotos to anon;

-- ─── Datos abiertos (CC BY 4.0) ────────────────────────────────────────────
-- Vista con los permisos de su dueño a propósito: expone solo lo validado y ningún dato
-- de quien aportó. PostgREST la sirve en JSON, CSV (text/csv) y GeoJSON (application/geo+json).

create view public.dades_obertes as
  select e.id,
         t.nom as tema,
         v.nom as variable,
         c.nom as categoria,
         e.text_lliure,
         e.descripcio,
         m.nom as municipi,
         p.nom as partida,
         e.origen,
         e.sigpac_ref,
         e.created_at::date as data_alta,
         round(extensions.st_y(extensions.st_pointonsurface(e.geom))::numeric, 6) as lat,
         round(extensions.st_x(extensions.st_pointonsurface(e.geom))::numeric, 6) as lon,
         e.geom
    from public.elements e
    join public.variables v on v.id = e.variable_id
    join public.temes t on t.id = v.tema_id
    left join public.categories c on c.id = e.categoria_id
    left join public.municipis m on m.codcat = e.codcat
    left join public.partides p on p.id = e.partida_id
   where e.estat = 'validat';

grant select on public.dades_obertes to anon, authenticated;

create function public.resum_inventari()
returns jsonb
language sql stable
set search_path = public, pg_temp
as $$
  select jsonb_build_object(
    'total', (select count(*) from public.dades_obertes),
    'per_tema', (select coalesce(jsonb_agg(x order by x.n desc), '[]') from (
      select tema as nom, count(*) as n from public.dades_obertes group by 1) x),
    'per_municipi', (select coalesce(jsonb_agg(x order by x.n desc), '[]') from (
      select municipi as nom, count(*) as n from public.dades_obertes where municipi is not null group by 1) x)
  );
$$;

-- ─── Vista del padrí ───────────────────────────────────────────────────────
-- Security invoker: la RLS ya deja al padrí ver todo lo de sus partidas.

create function public.resum_les_meues_partides()
returns table (
  partida_id int, partida text, municipi text, des_de date, area_ha numeric,
  validats bigint, pendents bigint, rebutjats bigint, per_tema jsonb, darrera timestamptz
)
language sql stable
set search_path = public, pg_temp
as $$
  select p.id, p.nom, m.nom, g.des_de, round((p.area_m2 / 10000)::numeric, 1),
         count(*) filter (where e.estat = 'validat'),
         count(*) filter (where e.estat = 'pendent'),
         count(*) filter (where e.estat = 'rebutjat'),
         (select coalesce(jsonb_agg(x order by x.nom), '[]') from (
            select t.nom, t.color, count(*) as n
              from public.elements e2
              join public.variables v on v.id = e2.variable_id
              join public.temes t on t.id = v.tema_id
             where e2.partida_id = p.id
             group by 1, 2) x),
         max(e.created_at)
    from public.padrinatges g
    join public.partides p on p.id = g.partida_id
    join public.municipis m on m.codcat = p.codcat
    left join public.elements e on e.partida_id = p.id
   where g.perfil_id = auth.uid()
     and g.des_de <= current_date
     and (g.fins is null or g.fins >= current_date)
   group by p.id, p.nom, m.nom, g.des_de, p.area_m2
   order by m.nom, p.nom;
$$;

revoke execute on function public.resum_les_meues_partides() from anon, public;
grant  execute on function public.resum_les_meues_partides() to authenticated;

-- ─── Noticias y salidas de campo ───────────────────────────────────────────

create type public.tipus_noticia_t as enum ('noticia', 'eixida');

create table public.noticies (
  id          uuid primary key default gen_random_uuid(),
  tipus       public.tipus_noticia_t not null default 'noticia',
  titol       text not null,
  cos         text not null default '',           -- texto plano: párrafos separados por línea en blanco
  imatge_path text,                               -- bucket 'contingut'
  data_event  date,                               -- día de la actividad o salida
  publicat    bool not null default false,
  legacy_nid  int unique,
  autor_id    uuid references public.perfils on delete set null,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);
create index noticies_publicat_idx on public.noticies (publicat, created_at desc);

alter table public.noticies enable row level security;

create policy noticies_lectura on public.noticies
  for select to anon, authenticated using (publicat or public.es_coordinador());

create policy noticies_coordinacio on public.noticies
  for all to authenticated using (public.es_coordinador()) with check (public.es_coordinador());

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('contingut', 'contingut', true, 5242880, array['image/jpeg', 'image/webp', 'image/png'])
on conflict (id) do nothing;

create policy contingut_llegir on storage.objects
  for select to authenticated using (bucket_id = 'contingut' and public.es_coordinador());
create policy contingut_pujar on storage.objects
  for insert to authenticated with check (bucket_id = 'contingut' and public.es_coordinador());
create policy contingut_esborrar on storage.objects
  for delete to authenticated using (bucket_id = 'contingut' and public.es_coordinador());

-- ─── Notificaciones ────────────────────────────────────────────────────────
-- En la web de momento: enviarlas por correo requiere el SMTP del despliegue.

create table public.notificacions (
  id          bigserial primary key,
  perfil_id   uuid not null references public.perfils on delete cascade,
  element_id  uuid not null references public.elements on delete cascade,
  accio       text not null check (accio in ('validat', 'rebutjat', 'reobert')),
  motiu       text,
  llegida     bool not null default false,
  created_at  timestamptz not null default now()
);
create index notificacions_perfil_idx on public.notificacions (perfil_id, created_at desc);

alter table public.notificacions enable row level security;

create policy notificacions_propies on public.notificacions
  for select to authenticated using (perfil_id = auth.uid());

create policy notificacions_marcar on public.notificacions
  for update to authenticated using (perfil_id = auth.uid()) with check (perfil_id = auth.uid());

revoke update on public.notificacions from authenticated;
grant update (llegida) on public.notificacions to authenticated;

create function public.notificar_canvi_estat()
returns trigger
language plpgsql security definer
set search_path = public, pg_temp
as $$
begin
  if new.autor_id is not null and new.estat is distinct from old.estat then
    insert into public.notificacions (perfil_id, element_id, accio, motiu)
    values (
      new.autor_id, new.id,
      case new.estat when 'validat' then 'validat' when 'rebutjat' then 'rebutjat' else 'reobert' end,
      new.motiu_rebuig
    );
  end if;
  return null;
end;
$$;

-- Solo los cambios de canviar_estat(): corregir lo propio también vuelve a pendiente,
-- pero de eso no hay que avisar a su autor.
create trigger elements_notificar
  after update of estat on public.elements
  for each row
  when (current_setting('observatori.canvi_estat', true) = 'on')
  execute function public.notificar_canvi_estat();
