// ETL: inventario 2017-2018 (BD legacy restaurada) + límites oficiales IGN → esquema v2.
//
//   npm run migrar              carga lo que falte (se puede repetir)
//   npm run migrar -- --reset   borra el inventario de 2018 y lo vuelve a cargar
//
// No migra usuarios (RGPD): los elementos de 2018 quedan sin autor.
// Variables: ver .env.example
import { readFile } from 'node:fs/promises';
import path from 'node:path';
import pg from 'pg';
import sharp from 'sharp';

const { LEGACY_DB_URL, TARGET_DB_URL, SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, LEGACY_FILES_DIR } = process.env;
const RESET = process.argv.includes('--reset');

const IGN_WFS = 'https://www.ign.es/wfs-inspire/unidades-administrativas';
const AMBIT_BBOX = '39.30,-0.60,39.70,-0.20'; // lat,lon: cubre los 37 municipios
const MUSEROS = { natcode: '34104646177', codcat: 179 }; // tenía partidas en 2018 pero no límite
const FOTO_COSTAT_MAX = 1600;
const MIDA_LOT = 500;

const legacy = new pg.Client({ connectionString: LEGACY_DB_URL });
const target = new pg.Client({ connectionString: TARGET_DB_URL });

// ─── Municipios: límites oficiales del IGN ─────────────────────────────────

async function migrarMunicipis() {
  const { rows } = await legacy.query('select natcode, codcat::int as codcat from plhcat.municipis');
  const codcatPerNatcode = new Map(rows.map((r) => [r.natcode, r.codcat]));
  codcatPerNatcode.set(MUSEROS.natcode, MUSEROS.codcat);

  const params = new URLSearchParams({
    service: 'WFS', version: '2.0.0', request: 'GetFeature',
    typeNames: 'au:AdministrativeUnit', count: '400',
    outputFormat: 'application/geo+json',
    srsName: 'urn:ogc:def:crs:EPSG::4326',
    bbox: `${AMBIT_BBOX},urn:ogc:def:crs:EPSG::4326`,
  });
  const res = await fetch(`${IGN_WFS}?${params}`);
  if (!res.ok) throw new Error(`WFS IGN: HTTP ${res.status}`);
  const { features } = await res.json();

  let carregats = 0;
  for (const f of features) {
    const codcat = codcatPerNatcode.get(f.properties.nationalCode);
    if (codcat === undefined) continue;
    // Nombres oficiales bilingües ("Alboraia/Alboraya"): el primero es el valenciano
    const nom = f.properties.name.GeographicalName.spelling.SpellingOfName.text.split('/')[0].trim();
    await target.query(
      `insert into public.municipis (codcat, nom, geom)
       values ($1, $2, extensions.st_multi(extensions.st_collectionextract(extensions.st_makevalid(
                 extensions.st_setsrid(extensions.st_geomfromgeojson($3), 4326)), 3)))
       on conflict (codcat) do update set nom = excluded.nom, geom = excluded.geom`,
      [codcat, nom, JSON.stringify(f.geometry)],
    );
    carregats++;
  }
  if (carregats !== codcatPerNatcode.size) {
    throw new Error(`Municipios: esperados ${codcatPerNatcode.size}, cargados ${carregats}`);
  }
  console.log(`municipis: ${carregats}`);
}

// ─── Partidas ──────────────────────────────────────────────────────────────

async function migrarPartides() {
  const { rows } = await legacy.query(`
    select id, municipio::int as codcat, partida as nom,
           encode(st_asewkb(st_multi(st_collectionextract(st_makevalid(
             st_transform(st_makevalid(geom), 4326)), 3))), 'hex') as geom
      from plhcat.partides_unides_v3`);
  for (const r of rows) {
    await target.query(
      `insert into public.partides (legacy_id, codcat, nom, geom)
       values ($1, $2, $3, $4::extensions.geometry)
       on conflict (legacy_id) do update
         set codcat = excluded.codcat, nom = excluded.nom, geom = excluded.geom`,
      [r.id, r.codcat, r.nom, r.geom],
    );
  }
  console.log(`partides: ${rows.length}`);
}

// ─── Elementos ─────────────────────────────────────────────────────────────

const SQL_ELEMENTS = (taula, geom) => `
  select e.gid, '${taula}' as taula, e.tipoid, e.idpartida, e.varid, n.nid,
         t.tema, t.variable, t.categoria,
         coalesce(v.field_validat_value, 0) = 1 as validat,
         e.createtime at time zone 'Europe/Madrid' as created_at,
         coalesce(e.modifytime, e.createtime) at time zone 'Europe/Madrid' as updated_at,
         encode(st_asewkb(${geom}), 'hex') as geom,
         obs.field_observacions_value as observacions,
         topo.field_topo_value as topo,
         us.field_us_actual_value as us_actual,
         coalesce(veg.field_altra_vegetacio_value, agr.field_altres_agressions_value) as text_lliure
    from plhcat.${taula} e
    join plhcat.plh_variables_tipos_v2 t on t.id = e.tipoid
    left join plhcat.plh_variable_nodo n on n.varid = e.varid
    left join pldrupal.plhm_field_data_field_validat v on v.entity_id = n.nid and v.bundle = 'fitxes'
    left join pldrupal.plhm_field_data_field_observacions obs on obs.entity_id = n.nid and obs.bundle = 'fitxes'
    left join pldrupal.plhm_field_data_field_topo topo on topo.entity_id = n.nid and topo.bundle = 'fitxes'
    left join pldrupal.plhm_field_data_field_us_actual us on us.entity_id = n.nid and us.bundle = 'fitxes'
    left join pldrupal.plhm_field_data_field_altra_vegetacio veg on veg.entity_id = n.nid and veg.bundle = 'fitxes'
    left join pldrupal.plhm_field_data_field_altres_agressions agr on agr.entity_id = n.nid and agr.bundle = 'fitxes'`;

const POLIGON_VALID = 'st_collectionextract(st_makevalid(st_transform(st_makevalid(e.geom), 4326)), 3)';

function descripcio(r) {
  const parts = [];
  if (r.observacions) parts.push(r.observacions);
  if (r.topo) parts.push(`Topònim: ${r.topo}`);
  if (r.us_actual) parts.push(`Ús actual: ${r.us_actual}`);
  return parts.length ? parts.join('\n') : null;
}

async function migrarElements() {
  if (RESET) {
    // Los elementos recargados tendrán ids nuevos: sus fotos quedarían huérfanas en Storage
    const { rows: fotos } = await target.query(`
      select f.storage_path from public.element_fotos f
        join public.elements e on e.id = f.element_id
       where e.origen = 'legacy_2018'`);
    if (fotos.length) {
      const res = await fetch(`${SUPABASE_URL}/storage/v1/object/fotos`, {
        method: 'DELETE',
        headers: {
          Authorization: `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
          apikey: SUPABASE_SERVICE_ROLE_KEY,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ prefixes: fotos.map((f) => f.storage_path) }),
      });
      if (!res.ok) throw new Error(`Storage (borrado): HTTP ${res.status} ${await res.text()}`);
    }
    const { rowCount } = await target.query(`delete from public.elements where origen = 'legacy_2018'`);
    console.log(`--reset: ${rowCount} elementos borrados`);
  }

  const { rows: cataleg } = await target.query(`
    select t.nom as tema, v.nom as variable, c.nom as categoria, v.id as variable_id, c.id as categoria_id
      from public.categories c
      join public.variables v on v.id = c.variable_id
      join public.temes t on t.id = v.tema_id`);
  const perClau = new Map(cataleg.map((c) => [`${c.tema}|${c.variable}|${c.categoria}`, c]));

  const { rows: partides } = await target.query('select id, legacy_id from public.partides');
  const partidaPerLegacy = new Map(partides.map((p) => [p.legacy_id, p.id]));

  const { rows } = await legacy.query(`
    ${SQL_ELEMENTS('plh_variables_punts', 'st_transform(e.geom, 4326)')}
    union all ${SQL_ELEMENTS('plh_variables_linies', 'st_transform(e.geom, 4326)')}
    union all ${SQL_ELEMENTS('plh_variables_poligons', POLIGON_VALID)}`);

  const files = rows.map((r) => {
    const cat = perClau.get(`${r.tema}|${r.variable}|${r.categoria}`);
    if (!cat) throw new Error(`Categoría sin correspondencia: ${r.tema}|${r.variable}|${r.categoria}`);
    const partida = partidaPerLegacy.get(Number(r.idpartida));
    if (!partida) throw new Error(`Partida sin correspondencia: ${r.idpartida} (${r.taula}:${r.gid})`);
    return {
      variable_id: cat.variable_id,
      categoria_id: cat.categoria_id,
      text_lliure: r.text_lliure,
      descripcio: descripcio(r),
      geom: r.geom,
      partida_id: partida,
      // Decisión 2026-11-09: todo el inventario de 2018 entra validado (ver marcarValidacioEnBloc)
      estat: 'validat',
      legacy_varid: r.varid ?? `sense-varid:${r.taula}:${r.gid}`, // 6 polígonos de 2018 no tienen varid
      legacy_nid: r.nid,
      created_at: r.created_at,
      updated_at: r.updated_at,
    };
  });

  // Por lotes: una ida y vuelta por elemento tarda minutos, y contra Supabase cloud mucho más
  let inserits = 0;
  for (let i = 0; i < files.length; i += MIDA_LOT) {
    const res = await target.query(
      `insert into public.elements
         (variable_id, categoria_id, text_lliure, descripcio, geom, partida_id, origen, estat,
          legacy_varid, legacy_nid, created_at, updated_at)
       select variable_id, categoria_id, text_lliure, descripcio, geom::extensions.geometry, partida_id,
              'legacy_2018', estat::public.estat_t, legacy_varid, legacy_nid, created_at, updated_at
         from jsonb_to_recordset($1::jsonb) as x(
           variable_id int, categoria_id int, text_lliure text, descripcio text, geom text, partida_id int,
           estat text, legacy_varid text, legacy_nid int, created_at timestamptz, updated_at timestamptz)
       on conflict (legacy_varid) do nothing`,
      [JSON.stringify(files.slice(i, i + MIDA_LOT))],
    );
    inserits += res.rowCount;
  }
  console.log(`elements: ${rows.length} en origen, ${inserits} nuevos`);

  await marcarValidacioEnBloc(files.filter((_, i) => !rows[i].validat).map((f) => f.legacy_varid));
}

// Lo que en 2018 no llegó a validar ningún coordinador queda identificado en el historial
async function marcarValidacioEnBloc(varids) {
  const { rowCount } = await target.query(
    `insert into public.element_historial (element_id, accio, detall)
     select e.id, 'validat', jsonb_build_object('motiu', $2::text)
       from public.elements e
      where e.legacy_varid = any($1)
        and not exists (select 1 from public.element_historial h
                         where h.element_id = e.id and h.accio = 'validat')`,
    [varids, 'Validació en bloc del inventari 2017-2018: no revisat en 2018'],
  );
  console.log(`validación en bloque: ${varids.length} sin revisar en 2018, ${rowCount} marcados`);
}

// ─── Fotos: se recodifican (sin EXIF ni GPS) y se suben a Storage ──────────

async function migrarFotos() {
  const { rows } = await legacy.query(`
    select i.entity_id as nid, f.uri
      from pldrupal.plhm_field_data_field_imatges i
      join pldrupal.plhm_file_managed f on f.fid = i.field_imatges_fid
     where i.bundle = 'fitxes'`);

  let pujades = 0;
  for (const { nid, uri } of rows) {
    const { rows: [el] } = await target.query('select id from public.elements where legacy_nid = $1', [nid]);
    if (!el) throw new Error(`Foto de una ficha sin elemento: nid ${nid}`);

    const fitxer = uri.replace('public://', '');
    const storagePath = `legacy_2018/${el.id}/${path.parse(fitxer).name}.jpg`;

    const original = await readFile(path.join(LEGACY_FILES_DIR, fitxer));
    const foto = await sharp(original)
      .rotate() // aplica la orientación EXIF antes de descartar los metadatos
      .resize({ width: FOTO_COSTAT_MAX, height: FOTO_COSTAT_MAX, fit: 'inside', withoutEnlargement: true })
      .jpeg({ quality: 80 })
      .toBuffer();

    const res = await fetch(`${SUPABASE_URL}/storage/v1/object/fotos/${storagePath}`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
        apikey: SUPABASE_SERVICE_ROLE_KEY,
        'Content-Type': 'image/jpeg',
        'x-upsert': 'true',
      },
      body: foto,
    });
    if (!res.ok) throw new Error(`Storage ${fitxer}: HTTP ${res.status} ${await res.text()}`);

    await target.query(
      `insert into public.element_fotos (element_id, storage_path)
       values ($1, $2) on conflict (storage_path) do nothing`,
      [el.id, storagePath],
    );
    pujades++;
  }
  console.log(`fotos: ${pujades}`);
}

await legacy.connect();
await target.connect();
try {
  await target.query('begin');
  await migrarMunicipis();
  await migrarPartides();
  await migrarElements();
  await target.query('commit');
  await migrarFotos(); // fuera de la transacción: Storage no participa en ella
} catch (err) {
  await target.query('rollback');
  throw err;
} finally {
  await legacy.end();
  await target.end();
}
