// Comprueba que lo cargado por migrar.mjs cuadra con el origen. Sale con código 1 si algo no cuadra.
import pg from 'pg';

const { LEGACY_DB_URL, TARGET_DB_URL, SUPABASE_URL, SUPABASE_ANON_KEY } = process.env;
const legacy = new pg.Client({ connectionString: LEGACY_DB_URL });
const target = new pg.Client({ connectionString: TARGET_DB_URL });
await legacy.connect();
await target.connect();

const un = async (client, sql) => Object.values((await client.query(sql)).rows[0])[0];
let errors = 0;
function comprova(nom, obtingut, esperat) {
  const ok = String(obtingut) === String(esperat);
  if (!ok) errors++;
  console.log(`${ok ? 'OK ' : 'ERR'} ${nom}: ${obtingut}${ok ? '' : ` (esperado ${esperat})`}`);
}

const ELEMENTS_LEGACY = `(select gid, tipoid, idpartida, varid from plhcat.plh_variables_punts
  union all select gid, tipoid, idpartida, varid from plhcat.plh_variables_linies
  union all select gid, tipoid, idpartida, varid from plhcat.plh_variables_poligons) e`;

comprova('municipis', await un(target, 'select count(*) from public.municipis'), 37);
comprova('partides', await un(target, 'select count(*) from public.partides'),
  await un(legacy, 'select count(*) from plhcat.partides_unides_v3'));
comprova('elements', await un(target, `select count(*) from public.elements where origen = 'legacy_2018'`),
  await un(legacy, `select count(*) from ${ELEMENTS_LEGACY}`));
const totalLegacy = await un(legacy, `select count(*) from ${ELEMENTS_LEGACY}`);
const validats2018 = await un(legacy, `select count(*) from ${ELEMENTS_LEGACY}
    join plhcat.plh_variable_nodo n on n.varid = e.varid
    join pldrupal.plhm_field_data_field_validat v on v.entity_id = n.nid and v.field_validat_value = 1`);
comprova('validats (en bloque)', await un(target, `select count(*) from public.elements where estat = 'validat'`), totalLegacy);
comprova('sin revisar en 2018, identificados', await un(target,
  `select count(*) from public.element_historial where accio = 'validat' and detall ->> 'motiu' like 'Validació en bloc%'`),
  Number(totalLegacy) - Number(validats2018));
comprova('noticias y salidas', await un(target, 'select count(*) from public.noticies where legacy_nid is not null'),
  await un(legacy, "select count(*) from pldrupal.plhm_node where type in ('not_act', 'eixida')"));
comprova('elementos con autor (RGPD)', await un(target, `select count(*) from public.elements where autor_id is not null`), 0);
comprova('elements sin partida', await un(target, `select count(*) from public.elements where partida_id is null`), 0);
comprova('elements sin municipio', await un(target, `select count(*) from public.elements where codcat is null`), 0);
comprova('geometrías inválidas', await un(target, `select count(*) from public.elements where not extensions.st_isvalid(geom)`), 0);

// Por tema, contra el origen
const { rows: origen } = await legacy.query(`select t.tema, count(*)::int as n from ${ELEMENTS_LEGACY}
  join plhcat.plh_variables_tipos_v2 t on t.id = e.tipoid group by 1 order by 1`);
const { rows: desti } = await target.query(`select t.nom as tema, count(*)::int as n from public.elements e
  join public.variables v on v.id = e.variable_id join public.temes t on t.id = v.tema_id group by 1 order by 1`);
comprova('elementos por tema', JSON.stringify(desti), JSON.stringify(origen));

// Superficie de los polígonos: migrar no debe alterarla (salvo los 23 inválidos reparados)
const sup = (client, sql) => un(client, sql).then(Number);
const haOrigen = await sup(legacy, 'select sum(st_area(geom)) / 10000 from plhcat.plh_variables_poligons');
const haDesti = await sup(target, `select sum(extensions.st_area(extensions.st_transform(geom, 25830))) / 10000
  from public.elements where extensions.geometrytype(geom) in ('POLYGON', 'MULTIPOLYGON')`);
const dif = Math.abs(haDesti - haOrigen) / haOrigen;
comprova('superficie de polígonos, diferencia < 0,1 %', dif < 0.001, true);
console.log(`    ${haOrigen.toFixed(1)} ha en origen · ${haDesti.toFixed(1)} ha en destino`);

// Informativo: cuánto cae fuera de los límites oficiales actuales
const { rows: [fora] } = await target.query(`
  with ambit as (select extensions.st_union(geom) as g from public.municipis)
  select count(*) filter (where not extensions.st_intersects(e.geom, a.g)) as elements_fora,
         (select count(*) from public.partides p, ambit a2 where not extensions.st_intersects(p.geom, a2.g)) as partides_fora,
         (select round(sum(extensions.st_area(extensions.st_transform(extensions.st_difference(p.geom, a3.g), 25830)))::numeric / 10000, 1)
            from public.partides p, ambit a3) as ha_partides_fora,
         (select round(sum(p.area_m2)::numeric / 10000, 1) from public.partides p) as ha_partides
    from public.elements e, ambit a`);
console.log(`INF fuera de los límites IGN: ${fora.elements_fora} elementos, ${fora.partides_fora} partidas enteras, `
  + `${fora.ha_partides_fora} ha de ${fora.ha_partides} ha de partidas`);

await legacy.end();
await target.end();

// De punta a punta: un visitante anónimo solo ve los validados
const res = await fetch(`${SUPABASE_URL}/rest/v1/rpc/elements_bbox`, {
  method: 'POST',
  headers: { apikey: SUPABASE_ANON_KEY, 'Content-Type': 'application/json' },
  body: JSON.stringify({ p_minx: -0.7, p_miny: 39.2, p_maxx: -0.1, p_maxy: 39.8 }),
});
const geojson = await res.json();
const anon = geojson.features?.length;
const validats = geojson.features?.filter((f) => f.properties.estat === 'validat').length;
comprova('API anónima: solo validados', anon, validats);
console.log(`    ${anon} elementos visibles para anónimos`);

process.exit(errors ? 1 : 0);
