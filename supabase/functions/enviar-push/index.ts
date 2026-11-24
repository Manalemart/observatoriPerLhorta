// Funció Edge «enviar-push»: envia un aviso (notificacions) als mòbils de la persona per
// Firebase Cloud Messaging (API HTTP v1). La crida el trigger notificacions_push amb
// { notificacio_id } i la capçalera x-push-secret (vegeu docs/PUSH.md).
//
// Secrets (supabase secrets set …):
//   FCM_SERVICE_ACCOUNT  el JSON del compte de servei de Firebase (rol «Firebase Cloud Messaging API Admin»)
//   PUSH_SECRET          el mateix valor que «push_secret» en el Vault de la base de dades
// SUPABASE_URL i SUPABASE_SERVICE_ROLE_KEY ja els posa Supabase.
//
// Què s'envia: un títol i un text curts, sense dades personals (ni correu ni àlies), i
// el tipus d'aviso perquè la app òbriga la pantalla d'avisos. Els tokens que FCM diu que ja
// no existixen s'esborren.

import { createClient } from 'npm:@supabase/supabase-js@2.49.4';

type Accio = 'validat' | 'rebutjat' | 'reobert' | 'nova_aportacio' | 'revisat';

type Idioma = 'ca' | 'es' | 'en';

const TEXTOS: Record<Idioma, Record<Accio, [string, string]>> = {
  ca: {
    validat: ['Aportació validada', "«{e}» ja és en l'inventari. Gràcies!"],
    rebutjat: ['Aportació rebutjada', '«{e}»: mira el motiu en Avisos.'],
    reobert: ['Aportació pendent de nou', '«{e}» torna a estar pendent de validar.'],
    nova_aportacio: ['Aportació nova en la teua partida', '«{e}» està pendent de validar.'],
    revisat: ['Element revisat', 'Algú ha revisat «{e}» en la teua partida.'],
  },
  es: {
    validat: ['Aportación validada', '«{e}» ya está en el inventario. ¡Gracias!'],
    rebutjat: ['Aportación rechazada', '«{e}»: mira el motivo en Avisos.'],
    reobert: ['Aportación pendiente de nuevo', '«{e}» vuelve a estar pendiente de validar.'],
    nova_aportacio: ['Aportación nueva en tu partida', '«{e}» está pendiente de validar.'],
    revisat: ['Elemento revisado', 'Alguien ha revisado «{e}» en tu partida.'],
  },
  en: {
    validat: ['Contribution validated', '“{e}” is now in the inventory. Thank you!'],
    rebutjat: ['Contribution rejected', '“{e}”: see the reason in Notifications.'],
    reobert: ['Contribution pending again', '“{e}” is pending validation again.'],
    nova_aportacio: ['New contribution in your partida', '“{e}” is pending validation.'],
    revisat: ['Feature reviewed', 'Someone has reviewed “{e}” in your partida.'],
  },
};

const idiomaDe = (x: unknown): Idioma => (x === 'es' || x === 'en' ? x : 'ca');

interface CompteServei {
  project_id: string;
  client_email: string;
  private_key: string;
}

const b64url = (b: ArrayBuffer | Uint8Array | string) => {
  const bytes = typeof b === 'string' ? new TextEncoder().encode(b) : new Uint8Array(b);
  let s = '';
  for (const x of bytes) s += String.fromCharCode(x);
  return btoa(s).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
};

/** Token d'accés OAuth 2 del compte de servei (JWT signat RS256), guardat mentre val. */
let accessToken: { valor: string; caduca: number } | null = null;
async function tokenAcces(cs: CompteServei): Promise<string> {
  const ara = Math.floor(Date.now() / 1000);
  if (accessToken && accessToken.caduca > ara + 60) return accessToken.valor;
  const cap = b64url(JSON.stringify({ alg: 'RS256', typ: 'JWT' }));
  const cos = b64url(JSON.stringify({
    iss: cs.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    iat: ara,
    exp: ara + 3600,
  }));
  const pem = cs.private_key.replace(/-----[^-]+-----/g, '').replace(/\s+/g, '');
  const der = Uint8Array.from(atob(pem), (c) => c.charCodeAt(0));
  const clau = await crypto.subtle.importKey('pkcs8', der, { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' }, false, ['sign']);
  const firma = await crypto.subtle.sign('RSASSA-PKCS1-v1_5', clau, new TextEncoder().encode(`${cap}.${cos}`));
  const r = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'content-type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({ grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer', assertion: `${cap}.${cos}.${b64url(firma)}` }),
  });
  if (!r.ok) throw new Error(`OAuth ${r.status}`);
  const j = await r.json();
  accessToken = { valor: j.access_token, caduca: ara + (j.expires_in ?? 3600) };
  return accessToken.valor;
}

/** Comparació en temps constant (el secret no es pot endevinar per temps de resposta). */
function iguals(a: string, b: string) {
  if (a.length !== b.length) return false;
  let d = 0;
  for (let i = 0; i < a.length; i++) d |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return d === 0;
}

Deno.serve(async (req) => {
  const secret = Deno.env.get('PUSH_SECRET') ?? '';
  if (req.method !== 'POST' || !secret || !iguals(req.headers.get('x-push-secret') ?? '', secret)) {
    return new Response('No', { status: 401 });
  }
  const { notificacio_id } = await req.json().catch(() => ({}));
  if (!Number.isInteger(notificacio_id)) return new Response('Falta notificacio_id', { status: 400 });

  const db = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!, {
    auth: { persistSession: false },
  });

  const { data: n } = await db
    .from('notificacions')
    .select('id, perfil_id, accio, llegida, element:elements(text_lliure, variable:variables(nom, nom_es, nom_en)), perfil:perfils(avisos_push)')
    .eq('id', notificacio_id)
    .maybeSingle();
  // deno-lint-ignore no-explicit-any
  const aviso = n as any;
  if (!aviso || aviso.llegida || !aviso.perfil?.avisos_push) return new Response('Res a enviar');

  const { data: dispositius } = await db.from('dispositius_push').select('token, plataforma, idioma').eq('perfil_id', aviso.perfil_id);
  if (!dispositius?.length) return new Response('Cap dispositiu');

  const cs: CompteServei = JSON.parse(Deno.env.get('FCM_SERVICE_ACCOUNT') ?? '{}');
  if (!cs.project_id) return new Response('Falta FCM_SERVICE_ACCOUNT', { status: 500 });
  const token = await tokenAcces(cs);
  // El text de la persona tal com està; si no n'hi ha, el nom del catàleg en l'idioma del mòbil
  const nomElement = (l: Idioma): string => {
    const v = aviso.element?.variable;
    const cataleg = (l === 'es' ? v?.nom_es : l === 'en' ? v?.nom_en : null) ?? v?.nom;
    return aviso.element?.text_lliure || cataleg || '';
  };
  const accio = aviso.accio as Accio;

  let enviats = 0;
  for (const d of dispositius) {
    const l = idiomaDe(d.idioma);
    const textos = TEXTOS[l][accio] ?? TEXTOS[l].validat;
    const r = await fetch(`https://fcm.googleapis.com/v1/projects/${cs.project_id}/messages:send`, {
      method: 'POST',
      headers: { authorization: `Bearer ${token}`, 'content-type': 'application/json' },
      body: JSON.stringify({
        message: {
          token: d.token,
          notification: { title: textos[0], body: textos[1].replace('{e}', nomElement(l)) },
          data: { pantalla: 'avisos', accio },
          android: { priority: 'normal', notification: { tag: `aviso-${aviso.id}` } },
          apns: { payload: { aps: { sound: 'default', 'thread-id': 'avisos' } } },
        },
      }),
    });
    if (r.ok) {
      enviats++;
    } else if (r.status === 404 || r.status === 400) {
      // UNREGISTERED o INVALID_ARGUMENT: el token ja no val
      await db.from('dispositius_push').delete().eq('token', d.token);
    } else {
      console.error('FCM', r.status, await r.text());
    }
  }
  return new Response(JSON.stringify({ enviats }), { headers: { 'content-type': 'application/json' } });
});
