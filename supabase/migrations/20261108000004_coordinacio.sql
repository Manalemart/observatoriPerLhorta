-- ═══════════════════════════════════════════════════════════════════════════
-- Funciones del panel de coordinación.
-- ═══════════════════════════════════════════════════════════════════════════

-- La coordinación necesita identificar a quién asigna una partida: el email solo
-- está en auth.users, que no es accesible desde la API.
create function public.usuaris_coordinacio()
returns table (id uuid, email text, nom_public text, rol public.rol_t, created_at timestamptz)
language plpgsql stable security definer
set search_path = public, pg_temp
as $$
begin
  if not public.es_coordinador() then
    raise exception 'Només la coordinació pot consultar els usuaris' using errcode = '42501';
  end if;
  return query
    select p.id, u.email::text, p.nom_public, p.rol, p.created_at
      from public.perfils p
      join auth.users u on u.id = p.id
     order by coalesce(p.nom_public, u.email::text);
end;
$$;

revoke execute on function public.usuaris_coordinacio() from anon, public;
grant  execute on function public.usuaris_coordinacio() to authenticated;

-- Un padrinatge vigente sigue valiendo durante el día de su fecha "fins": para que
-- termine ya, se le pone la de ayer; si empezó hoy, no se puede y se borra.
create function public.finalitzar_padrinatge(p_id int)
returns void
language plpgsql
set search_path = public, pg_temp
as $$
begin
  delete from public.padrinatges where id = p_id and des_de >= current_date;
  if not found then
    update public.padrinatges set fins = current_date - 1 where id = p_id;
  end if;
end;
$$;

revoke execute on function public.finalitzar_padrinatge(int) from anon, public;
grant  execute on function public.finalitzar_padrinatge(int) to authenticated;
