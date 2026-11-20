# Compilar en Codemagic (iOS sense Mac, i Android)

[Codemagic](https://codemagic.io) compila la app en Macs al núvol. El compte individual té **500 minuts de macOS M2 al mes gratis**. La configuració és [`codemagic.yaml`](../codemagic.yaml), a l'arrel del repo.

| Flux | Què fa | Quan |
|---|---|---|
| `ios-testflight` | Proves, IPA firmat i pujada a TestFlight | A mà, o en pujar una etiqueta `app-v*` (p. ex. `app-v1.0.0`) |
| `ios-captures` | Captures de l'App Store en el simulador: iPhone 6,9" (1320 × 2868) i iPad 13" (2064 × 2752) | A mà |
| `android-play` | Proves i *app bundle* (`.aab`) firmat per a Google Play | A mà, o amb una etiqueta `app-v*` |

## Posada en marxa (una vegada)

1. **Compte de Codemagic** amb GitHub, i afegir el repo `observatoriPerLhorta`. Detecta `codemagic.yaml` tot sol.
2. **Variables** (*Environment variables*), en dos grups:
   - `observatori`: `SUPABASE_URL` = `https://fmhioekwuvzzdgtghwcx.supabase.co` i `SUPABASE_KEY` = la clau pública (*anon*, la mateixa que porta la web). Marcar-les com a *secure*.
   - `captures`: `CAPTURES_EMAIL` i `CAPTURES_PASSWORD`, d'un compte de prova (vegeu més avall).
3. **App Store Connect** (cal el compte de desenvolupador d'Apple):
   - Crear la app en App Store Connect amb el bundle ID `com.mamlabsfera.observatoriPerlhorta`.
   - *Users and Access → Integrations → App Store Connect API*: una clau amb rol *App Manager*. En Codemagic, *Team settings → Integrations → App Store Connect*, amb el nom **`observatori-asc`**.
   - En `codemagic.yaml`, canviar `APP_STORE_APPLE_ID` pel número de la app (App Store Connect → App Information → Apple ID).
   - Firma: Codemagic crea el certificat de distribució i el perfil (*Code signing identities → iOS*, «Generate certificate» i «Fetch profiles»).
4. **Google Play**:
   - Crear la clau de publicació (una sola vegada, i guardar-la bé: si es perd, no es pot actualitzar la app):
     ```bash
     keytool -genkey -v -keystore observatori-play.jks -keyalg RSA -keysize 2048 -validity 10000 -alias observatori
     ```
   - Pujar-la en Codemagic (*Code signing identities → Android keystores*) amb la referència **`observatori-play`**.
   - En local, per a firmar sense Codemagic: `app/android/key.properties` (fora del repo) amb `storeFile`, `storePassword`, `keyAlias` i `keyPassword`. Sense, el build de *release* es firma amb la clau de depuració (serveix per a provar, no per a Play).
   - La **primera** versió es puja a mà en Play Console. Després, si es vol, Codemagic pot publicar en proves internes (secció comentada al final de `codemagic.yaml`).

## Compte de prova per a les captures

La prova `app/integration_test/captures_test.dart` entra amb **correu i contrasenya** (la app, amb codi), així que el compte s'ha de crear així:

1. Supabase → *Authentication → Users → Add user → Create new user*, amb correu i contrasenya i «Auto Confirm User».
2. Entrar una vegada a la web o a la app amb eixe correu per a posar-li l'**àlies** (si no, la prova es queda en el diàleg de l'àlies).
3. Millor si apadrina una partida i té alguna aportació: les captures de Partides i Avisos no ixen buides.

El mateix compte servix per als **revisors d'Apple**, que també han de poder entrar (vegeu [botigues/README.md](botigues/README.md#bloquejos)).

## Les captures

El flux `ios-captures` fa, en cada simulador ([`app/ios/eines/captures.sh`](../app/ios/eines/captures.sh)):

1. Arranca el simulador, posa la barra d'estat neta (9:41, bateria plena) i la ubicació a l'horta de Benimaclet.
2. Llança la prova d'integració: entra, toca «La meua posició», obri la llegenda, el primer pas d'«Aporta» i les seccions Partides, Avisos i Les meues.
3. A cada pas, el conductor ([`app/test_driver/captures.dart`](../app/test_driver/captures.dart)) fa la captura amb `xcrun simctl io screenshot`, a la resolució del simulador.

Les captures queden en els *artifacts* del build (`app/captures/iphone-6.9/` i `app/captures/ipad-13/`), a punt per a pujar-les a App Store Connect.

Les d'Android estan fetes ja, en [`botigues/captures/`](botigues/captures/).

## Si alguna cosa falla

- **Primera compilació d'iOS**: la app no s'ha compilat mai per a iOS ([IOS.md](IOS.md)). És normal que la primera vegada isquen errors de Pods o de firma: es mira el registre del pas que falla.
- **Simulador no trobat**: els noms dels simuladors canvien amb cada Xcode. `captures.sh` accepta diversos noms (`"iPhone 17 Pro Max|iPhone 16 Pro Max"`); se n'afig un altre en `codemagic.yaml`.
- **Minuts**: un build d'iOS sol durar 10-20 minuts; les captures, uns 15. Els 500 minuts gratuïts donen per a unes quantes proves al mes.
