-- Las 52 noticias y salidas de 2017-2018 se importaron como borrador (publicat = false)
-- mientras se decidía si publicarlas. Decisión: son públicas. Solo las de 2018 que siguen
-- en borrador; lo creado en la web nueva no se toca.
update public.noticies
   set publicat = true, updated_at = now()
 where legacy_nid is not null
   and not publicat;
