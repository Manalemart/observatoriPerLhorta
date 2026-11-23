-- ═══════════════════════════════════════════════════════════════════════════
-- SEGURETAT (urgent): la vista perfils_publics permetia escriure en perfils sense entrar.
--
-- La vista era «auto-updatable», de postgres (que se salta l'RLS) i, amb els permisos per
-- defecte de Supabase, anon i authenticated hi tenien INSERT, UPDATE i DELETE. Qualsevol
-- persona amb la clau pública podia, sense compte:
--   · canviar l'àlies de qualsevol persona,
--   · esborrar perfils (i amb ells el rol, els padrinatges i els avisos, en cascada),
--   · crear perfils.
-- També publicava l'àlies de tots els comptes.
--
-- Ningú no la fa servir (ni la web ni la app): s'esborra. Per a no repetir-ho, a més,
-- les vistes del public que queden no admeten escriptura per a anon ni authenticated.
-- ═══════════════════════════════════════════════════════════════════════════

drop view if exists public.perfils_publics;

-- dades_obertes no és actualitzable (té joins), però que no ho siga mai per error
revoke insert, update, delete, truncate on public.dades_obertes from anon, authenticated;
