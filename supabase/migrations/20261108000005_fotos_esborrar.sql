-- ═══════════════════════════════════════════════════════════════════════════
-- El API de Storage lee el objeto antes de borrarlo: sin política de SELECT, remove()
-- no borra nada ni da error, y la foto de un elemento borrado seguía publicada.
-- El bucket es público: las URLs funcionan sin esta política, solo afecta a la API.
-- ═══════════════════════════════════════════════════════════════════════════

create policy fotos_llegir_propies on storage.objects
  for select to authenticated
  using (bucket_id = 'fotos'
         and ((storage.foldername(name))[1] = auth.uid()::text or public.es_coordinador()));
