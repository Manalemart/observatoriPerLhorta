-- ═══════════════════════════════════════════════════════════════════════════
-- Row Level Security, permisos de columna y bucket de fotos.
-- ═══════════════════════════════════════════════════════════════════════════

alter table public.municipis         enable row level security;
alter table public.partides          enable row level security;
alter table public.temes             enable row level security;
alter table public.variables         enable row level security;
alter table public.categories        enable row level security;
alter table public.perfils           enable row level security;
alter table public.padrinatges       enable row level security;
alter table public.elements          enable row level security;
alter table public.element_fotos     enable row level security;
alter table public.element_historial enable row level security;

-- ─── Territorio y catálogo: lectura pública, escritura coordinación ────────

do $$
declare t text;
begin
  foreach t in array array['municipis', 'partides', 'temes', 'variables', 'categories'] loop
    execute format('create policy %I on public.%I for select to anon, authenticated using (true)',
                   t || '_lectura', t);
    execute format('create policy %I on public.%I for all to authenticated
                      using (public.es_coordinador()) with check (public.es_coordinador())',
                   t || '_coordinacio', t);
  end loop;
end $$;

-- ─── Perfils ───────────────────────────────────────────────────────────────

create policy perfils_propi on public.perfils
  for select to authenticated using (id = auth.uid() or public.es_coordinador());

create policy perfils_editar_propi on public.perfils
  for update to authenticated using (id = auth.uid()) with check (id = auth.uid());

create policy perfils_coordinacio on public.perfils
  for update to authenticated using (public.es_coordinador()) with check (public.es_coordinador());

-- Solo el alias es público (vista sin RLS, propiedad de postgres)
create view public.perfils_publics as
  select id, nom_public from public.perfils;
grant select on public.perfils_publics to anon, authenticated;

-- Un usuario solo puede editar su alias; el rol lo cambia la coordinación (trigger protegir_rol)
revoke update on public.perfils from authenticated;
grant update (nom_public, rol) on public.perfils to authenticated;

-- ─── Padrinatges ───────────────────────────────────────────────────────────

create policy padrinatges_propis on public.padrinatges
  for select to authenticated using (perfil_id = auth.uid() or public.es_coordinador());

create policy padrinatges_coordinacio on public.padrinatges
  for all to authenticated using (public.es_coordinador()) with check (public.es_coordinador());

-- ─── Elements ──────────────────────────────────────────────────────────────

create policy elements_lectura on public.elements
  for select to anon, authenticated
  using (
    estat = 'validat'
    or autor_id = auth.uid()
    or public.es_coordinador()
    or public.es_padri_de(partida_id)
  );

create policy elements_aportar on public.elements
  for insert to authenticated
  with check (auth.uid() is not null);              -- el trigger fija autor y estado

create policy elements_editar_propis on public.elements
  for update to authenticated
  using (autor_id = auth.uid() and estat in ('pendent', 'rebutjat'))
  with check (autor_id = auth.uid());

create policy elements_editar_coordinacio on public.elements
  for update to authenticated
  using (public.es_coordinador()) with check (public.es_coordinador());

create policy elements_esborrar on public.elements
  for delete to authenticated
  using ((autor_id = auth.uid() and estat in ('pendent', 'rebutjat')) or public.es_coordinador());

-- ─── Fotos ─────────────────────────────────────────────────────────────────

create policy element_fotos_lectura on public.element_fotos
  for select to anon, authenticated
  using (exists (select 1 from public.elements e where e.id = element_id));   -- hereda la RLS de elements

create policy element_fotos_pujar on public.element_fotos
  for insert to authenticated
  with check (
    autor_id = auth.uid()
    and exists (select 1 from public.elements e where e.id = element_id and e.autor_id = auth.uid())
  );

create policy element_fotos_esborrar on public.element_fotos
  for delete to authenticated
  using (autor_id = auth.uid() or public.es_coordinador());

-- ─── Historial: solo lectura (lo escriben las funciones) ───────────────────

create policy element_historial_lectura on public.element_historial
  for select to authenticated
  using (
    public.es_coordinador()
    or exists (select 1 from public.elements e
               where e.id = element_id
                 and (e.autor_id = auth.uid() or public.es_padri_de(e.partida_id)))
  );

-- ─── Funciones expuestas ───────────────────────────────────────────────────

revoke execute on function public.canviar_estat(uuid, public.estat_t, text) from anon, public;
grant  execute on function public.canviar_estat(uuid, public.estat_t, text) to authenticated;

-- ─── Storage: bucket de fotos (ruta <uid>/<element_id>/<fichero>) ──────────
-- Lectura pública; CC BY-SA 4.0 aceptada al subir (términos de uso).

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('fotos', 'fotos', true, 5242880, array['image/jpeg', 'image/webp', 'image/png'])
on conflict (id) do nothing;

create policy fotos_pujar on storage.objects
  for insert to authenticated
  with check (bucket_id = 'fotos' and (storage.foldername(name))[1] = auth.uid()::text);

create policy fotos_esborrar on storage.objects
  for delete to authenticated
  using (bucket_id = 'fotos'
         and ((storage.foldername(name))[1] = auth.uid()::text or public.es_coordinador()));
