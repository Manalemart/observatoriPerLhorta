-- ═══════════════════════════════════════════════════════════════════════════
-- Observatori Ciutadà de l'Horta — esquema base (modelo de datos v2)
-- Geometrías en EPSG:4326; las métricas se calculan en EPSG:25830.
-- Doc: Obsidian · Desarrollo Apps/OBSERVATORI/Modelo de datos v2
-- ═══════════════════════════════════════════════════════════════════════════

create extension if not exists postgis with schema extensions;

-- ─── Territorio ────────────────────────────────────────────────────────────

create table public.municipis (
  codcat  int primary key,                         -- código catastral (900 = València)
  nom     text not null,
  geom    extensions.geometry(MultiPolygon, 4326) not null
);
create index municipis_geom_idx on public.municipis using gist (geom);

create table public.partides (
  id         serial primary key,
  codcat     int not null references public.municipis,
  nom        text not null,
  legacy_id  int unique,                           -- plhcat.partides_unides_v3.id
  geom       extensions.geometry(MultiPolygon, 4326) not null,
  area_m2    double precision generated always as
               (extensions.st_area(extensions.st_transform(geom, 25830))) stored
);
create index partides_geom_idx on public.partides using gist (geom);
create index partides_codcat_idx on public.partides (codcat);

-- ─── Catálogo (Tema → Variable → Categoria) ────────────────────────────────

create type public.geometria_t as enum ('punt', 'linia', 'poligon', 'parcela');

-- nom = valenciano (canónico); traduccions = {"es": "..."} opcional
create table public.temes (
  id           serial primary key,
  nom          text not null unique,
  traduccions  jsonb not null default '{}',
  ordre        int,
  color        text
);

create table public.variables (
  id           serial primary key,
  tema_id      int not null references public.temes,
  nom          text not null,
  traduccions  jsonb not null default '{}',
  geometria    public.geometria_t not null,
  text_lliure  bool not null default false,       -- variables "Altre (text lliure)"
  actiu        bool not null default true,
  unique (tema_id, nom)
);

create table public.categories (
  id           serial primary key,
  variable_id  int not null references public.variables,
  nom          text not null,
  traduccions  jsonb not null default '{}',
  actiu        bool not null default true,
  unique (variable_id, nom)
);

-- ─── Usuarios ──────────────────────────────────────────────────────────────

create type public.rol_t as enum ('ciutada', 'padri', 'coordinador', 'admin');

create table public.perfils (
  id          uuid primary key references auth.users on delete cascade,
  nom_public  text,
  rol         public.rol_t not null default 'ciutada',
  created_at  timestamptz not null default now()
);

create table public.padrinatges (
  id          serial primary key,
  perfil_id   uuid not null references public.perfils on delete cascade,
  partida_id  int  not null references public.partides,
  des_de      date not null default current_date,
  fins        date,                                 -- null = vigente
  unique (perfil_id, partida_id, des_de),
  check (fins is null or fins >= des_de)
);
create index padrinatges_perfil_idx on public.padrinatges (perfil_id);

-- ─── Elementos inventariados ───────────────────────────────────────────────

create type public.estat_t  as enum ('pendent', 'validat', 'rebutjat');
create type public.origen_t as enum ('legacy_2018', 'web', 'app');

create table public.elements (
  id            uuid primary key default gen_random_uuid(),
  variable_id   int not null references public.variables,
  categoria_id  int references public.categories,
  text_lliure   text,
  descripcio    text,
  geom          extensions.geometry(Geometry, 4326) not null,
  partida_id    int references public.partides,     -- por trigger
  codcat        int references public.municipis,    -- por trigger
  sigpac_ref    text,                               -- tipo 'parcela': 'prov:mun:agr:zona:pol:parc:rec'
  sigpac_dn_pk  bigint,                             -- id del recinto en el OGC API del FEGA
  sigpac_data   date,                               -- fecha de la consulta a SIGPAC
  autor_id      uuid references public.perfils on delete set null,
  origen        public.origen_t not null default 'web',
  estat         public.estat_t  not null default 'pendent',
  validat_per   uuid references public.perfils on delete set null,
  validat_at    timestamptz,
  motiu_rebuig  text,
  legacy_varid  text unique,
  legacy_nid    int,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  constraint elements_geom_valida check (extensions.st_isvalid(geom))
);
create index elements_geom_idx on public.elements using gist (geom);
create index elements_estat_variable_idx on public.elements (estat, variable_id);
create index elements_partida_idx on public.elements (partida_id);
create index elements_autor_idx on public.elements (autor_id);

create table public.element_fotos (
  id            uuid primary key default gen_random_uuid(),
  element_id    uuid not null references public.elements on delete cascade,
  storage_path  text not null unique,               -- bucket 'fotos'
  autor_id      uuid references public.perfils on delete set null,
  created_at    timestamptz not null default now()
);
create index element_fotos_element_idx on public.element_fotos (element_id);

create table public.element_historial (
  id          bigserial primary key,
  element_id  uuid not null references public.elements on delete cascade,
  perfil_id   uuid references public.perfils on delete set null,
  accio       text not null check (accio in ('creat', 'editat', 'validat', 'rebutjat', 'reobert')),
  detall      jsonb,
  created_at  timestamptz not null default now()
);
create index element_historial_element_idx on public.element_historial (element_id);
