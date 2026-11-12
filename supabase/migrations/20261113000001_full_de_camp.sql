-- Hoja de campo de una partida: todo lo necesario para imprimirla.
--
-- Geometría completa (no la simplificada del mapa web) y, para cada elemento, un punto
-- sobre él donde poner su número en el plano. Security invoker: la RLS decide qué
-- elementos salen (lo validado y, con permiso, lo pendiente de la partida).

create function public.full_de_camp(p_partida_id int)
returns jsonb
language sql stable
set search_path = public, extensions, pg_temp
as $$
  select jsonb_build_object(
    'partida', (
      select jsonb_build_object(
        'id', p.id, 'nom', p.nom, 'municipi', m.nom,
        'area_ha', round((p.area_m2 / 10000)::numeric, 1),
        'geometria', st_asgeojson(p.geom, 7)::jsonb
      )
      from public.partides p
      join public.municipis m on m.codcat = p.codcat
      where p.id = p_partida_id
    ),
    'elements', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', e.id,
        'tema_id', t.id, 'tema', t.nom, 'color', t.color,
        'variable', coalesce(e.text_lliure, v.nom),
        'categoria', c.nom,
        'estat', e.estat, 'origen', e.origen,
        'revisat_at', e.revisat_at, 'created_at', e.created_at,
        'per_revisar', e.origen = 'legacy_2018' and e.revisat_at is null,
        'geometria', st_asgeojson(e.geom, 7)::jsonb,
        'etiqueta', st_asgeojson(st_pointonsurface(e.geom), 7)::jsonb -> 'coordinates'
      ) order by t.nom, v.nom)
      from public.elements e
      join public.variables v on v.id = e.variable_id
      join public.temes t on t.id = v.tema_id
      left join public.categories c on c.id = e.categoria_id
      where e.partida_id = p_partida_id
    ), '[]'::jsonb)
  );
$$;

revoke execute on function public.full_de_camp(int) from public, anon;
grant execute on function public.full_de_camp(int) to authenticated;
