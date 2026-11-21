-- Esborrar el compte des de la web i des de la app (RGPD, art. 17; Apple 5.1.1(v); Google Play).
--
-- Què passa en esborrar un compte:
--   · S'esborra: el compte (correu, sessions, identitats), el perfil i l'àlies, els padrinatges,
--     els avisos, els resums per correu i les aportacions que encara no s'havien publicat
--     (pendents o rebutjades), amb les seues fotos i el seu historial.
--   · Es conserva, sense cap vincle amb la persona: les aportacions ja validades i les seues fotos,
--     que formen part de l'inventari públic amb llicència CC BY / CC BY-SA (les claus foranes
--     de perfils posen autor_id, validat_per i perfil_id a null).
--
-- Les fotos són fitxers de Storage i no es poden esborrar des de SQL (storage.protect_delete):
-- la web i la app demanen primer la llista (fotos_per_esborrar), les esborren amb l'API de
-- Storage (la política fotos_esborrar ho permet en la carpeta pròpia) i després criden
-- esborrar_compte.

-- ─── Fotos que s'han d'esborrar ────────────────────────────────────────────
-- Tot el que hi ha en la carpeta de la persona (fotos/<uid>/...) menys les fotos d'elements
-- validats, que es queden en l'inventari.
create or replace function public.fotos_per_esborrar()
returns setof text
language sql
stable
security definer
set search_path = ''
as $$
  select o.name
  from storage.objects o
  where o.bucket_id = 'fotos'
    and auth.uid() is not null
    and (storage.foldername(o.name))[1] = auth.uid()::text
    and not exists (
      select 1
      from public.element_fotos f
      join public.elements e on e.id = f.element_id
      where f.storage_path = o.name and e.estat = 'validat'
    );
$$;

revoke all on function public.fotos_per_esborrar() from public, anon;
grant execute on function public.fotos_per_esborrar() to authenticated;

-- ─── Esborrar el compte ────────────────────────────────────────────────────
create or replace function public.esborrar_compte()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'Cal haver entrat per a esborrar el compte' using errcode = '42501';
  end if;

  -- Les claus foranes posaran autor_id / validat_per a null en elements: és un canvi dels camps
  -- protegits (elements_abans_escriure) i no ha de deixar rastre en l'historial (elements_historial).
  -- Només dura fins al final de la transacció.
  perform set_config('observatori.canvi_estat', 'on', true);

  -- Aportacions no publicades: fora, amb les files de fotos i l'historial (on delete cascade)
  delete from public.elements
  where autor_id = v_uid and estat <> 'validat';

  -- Les fotos que queden (les d'elements validats) deixen de dir de qui són
  update public.element_fotos set autor_id = null where autor_id = v_uid;
  begin
    update storage.objects set owner = null, owner_id = null
    where bucket_id = 'fotos' and (owner = v_uid or owner_id = v_uid::text);
  exception when insufficient_privilege then
    null; -- sense permís sobre storage.objects: la carpeta ja no es pot relacionar amb ningú
  end;

  -- Registre d'accessos d'Auth (porta el correu): fora, si el rol té permís
  begin
    delete from auth.audit_log_entries
    where payload ->> 'actor_id' = v_uid::text;
  exception when insufficient_privilege or undefined_table then
    null;
  end;

  -- El compte. En cascada: perfils → padrinatges, notificacions, correus_resum; i
  -- autor_id / validat_per / perfil_id a null en la resta de taules.
  delete from auth.users where id = v_uid;
end;
$$;

revoke all on function public.esborrar_compte() from public, anon;
grant execute on function public.esborrar_compte() to authenticated;

comment on function public.esborrar_compte() is
  'Esborra el compte de qui la crida (RGPD art. 17). Abans cal esborrar de Storage les fotos de fotos_per_esborrar().';

-- ─── Les meues dades (RGPD, art. 15 i 20: accés i portabilitat) ─────────────
create or replace function public.les_meues_dades()
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object(
    'generat', now(),
    'compte', (
      select jsonb_build_object('id', u.id, 'correu', u.email, 'alta', u.created_at, 'darrera_entrada', u.last_sign_in_at)
      from auth.users u where u.id = auth.uid()
    ),
    'perfil', (
      select jsonb_build_object('alies', p.nom_public, 'rol', p.rol, 'resum_correu', p.resum_correu, 'alta', p.created_at)
      from public.perfils p where p.id = auth.uid()
    ),
    'partides_apadrinades', coalesce((
      select jsonb_agg(jsonb_build_object('partida', pa.nom, 'municipi', pa.codcat))
      from public.padrinatges pd join public.partides pa on pa.id = pd.partida_id
      where pd.perfil_id = auth.uid()
    ), '[]'::jsonb),
    'aportacions', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', e.id,
        'variable', v.nom,
        'categoria', c.nom,
        'text_lliure', e.text_lliure,
        'descripcio', e.descripcio,
        'estat', e.estat,
        'motiu_rebuig', e.motiu_rebuig,
        'data', e.created_at,
        'geometria', extensions.st_asgeojson(e.geom)::jsonb,
        'fotos', coalesce((select jsonb_agg(f.storage_path) from public.element_fotos f where f.element_id = e.id), '[]'::jsonb)
      ) order by e.created_at)
      from public.elements e
      join public.variables v on v.id = e.variable_id
      left join public.categories c on c.id = e.categoria_id
      where e.autor_id = auth.uid()
    ), '[]'::jsonb),
    'avisos', coalesce((
      select jsonb_agg(jsonb_build_object('accio', n.accio, 'motiu', n.motiu, 'llegit', n.llegida, 'data', n.created_at)
                       order by n.created_at)
      from public.notificacions n where n.perfil_id = auth.uid()
    ), '[]'::jsonb)
  )
  where auth.uid() is not null;
$$;

revoke all on function public.les_meues_dades() from public, anon;
grant execute on function public.les_meues_dades() to authenticated;
