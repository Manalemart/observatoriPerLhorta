# Avisos al móvil (notificaciones push)

Cada aviso nuevo (aportación validada, rechazada, vuelta a pendiente, aportación nueva en tu partida, elemento revisado) llega también al móvil.

```
notificacions (insert) ─► trigger notificacions_push ─► pg_net ─► función Edge «enviar-push» ─► FCM ─► Android / iOS
```

| Pieza | Dónde |
|---|---|
| Tabla de móviles y funciones `registrar_dispositiu` / `oblidar_dispositiu` | `supabase/migrations/20261126000001_avisos_push.sql` |
| Envío (Firebase Cloud Messaging, API HTTP v1) | `supabase/functions/enviar-push/index.ts` |
| App: permiso, registro del móvil, abrir «Avisos» al tocar | `app/lib/services/avisos_push.dart` |
| Interruptor «Avisos al mòbil» | pantalla Avisos de la app (`perfils.avisos_push`) |

Sin configurar, **no pasa nada**: la app funciona igual, los avisos siguen en la pantalla «Avisos» y en el resumen diario por correo, y el trigger no envía nada.

## Privacidad

- A Google (Firebase) solo le llegan el token del móvil y el título y texto del aviso (el nombre del elemento). Ni correo, ni alias, ni ubicación.
- El token se borra al salir de la cuenta, al borrar la cuenta y cuando FCM dice que ya no vale.
- La política de privacidad lo explica (Firebase como subencargado) y «Les meues dades» incluye los móviles registrados.

## Puesta en marcha (una vez)

### 1. Firebase

1. [console.firebase.google.com](https://console.firebase.google.com) → *Add project* (por ejemplo «observatori-horta»). Analytics: **no** (no hace falta y evita otro tratamiento de datos).
2. *Add app* → **Android**, paquete `com.mamlabsfera.observatori_perlhorta`. No hace falta descargar `google-services.json`: de la pantalla final se apuntan *App ID*, *API key*, *Sender ID* y *Project ID*.
3. *Add app* → **iOS**, bundle `com.mamlabsfera.observatoriPerlhorta`. Se apunta su *App ID* (es distinto del de Android).
4. *Project settings → Cloud Messaging → Apple app configuration*: subir la **clave APNs** (.p8) de la cuenta de Apple (developer.apple.com → Keys → «Apple Push Notifications service»).
5. *Project settings → Service accounts → Generate new private key*: el JSON del compte de servei. **No va al repo.**

### 2. Supabase (producción)

```bash
npx.cmd supabase db push --remote
npx.cmd supabase functions deploy enviar-push --no-verify-jwt --project-ref fmhioekwuvzzdgtghwcx
npx.cmd supabase secrets set --project-ref fmhioekwuvzzdgtghwcx FCM_SERVICE_ACCOUNT="$(cat compte-servei.json)" PUSH_SECRET=<un secreto largo>
```

`--no-verify-jwt`: la función no la llama un usuario, sino la base de datos, con la cabecera `x-push-secret`.

En el editor SQL de Supabase, el mismo secreto y la dirección de la función en el Vault:

```sql
select vault.create_secret('https://fmhioekwuvzzdgtghwcx.supabase.co/functions/v1/enviar-push', 'push_url');
select vault.create_secret('<el mismo secreto largo>', 'push_secret');
```

### 3. Compilar la app con Firebase

Las claves de Firebase de la app no son secretas (van dentro de la app, como la clave pública de Supabase), pero cambian entre Android e iOS. En Codemagic, en el grupo `observatori`:

| Variable | Valor |
|---|---|
| `FIREBASE_API_KEY` | API key |
| `FIREBASE_PROJECT_ID` | Project ID |
| `FIREBASE_SENDER_ID` | Sender ID |
| `FIREBASE_APP_ID_ANDROID` | App ID de Android |
| `FIREBASE_APP_ID_IOS` | App ID de iOS |

`codemagic.yaml` ya las pasa a `flutter build` (`--dart-define=FIREBASE_APP_ID=…` con la de cada plataforma).

**iOS**: la app ya declara `aps-environment` (`Runner.entitlements`) y `remote-notification` en `UIBackgroundModes`. En el Apple Developer, el identificador de la app tiene que tener activada la capacidad **Push Notifications**; Codemagic la toma al generar el perfil. iOS mínimo: 15.0 (lo pide Firebase).

## Probar

1. Compilar con las variables de Firebase e instalar en un móvil real (en el simulador de iOS no llegan pushes; en el emulador de Android sí, si tiene Google Play).
2. Entrar: la app pide permiso de notificaciones.
3. Desde otra cuenta de coordinación, validar una aportación de la primera → llega «Aportació validada».
4. Si no llega: `select * from net._http_response order by created desc limit 5;` (respuesta de la función) y los registros de la función en Supabase (*Edge Functions → enviar-push → Logs*).
