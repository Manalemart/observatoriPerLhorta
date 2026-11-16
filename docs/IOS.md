# App de l'Observatori en iOS

La carpeta `app/ios` está preparada desde Windows, **sin haber compilado nunca**: no hay Mac ni Xcode en el equipo de desarrollo. Este documento recoge qué está hecho, qué falta y cómo probarlo cuando haya un Mac.

## Qué está hecho

| Qué | Valor | Dónde |
|---|---|---|
| Proyecto iOS | `flutter create --platforms=ios .` (Flutter 3.41) | `app/ios/` |
| Bundle ID | `com.mamlabsfera.observatoriPerlhorta` | `Runner.xcodeproj/project.pbxproj` |
| Nombre visible | «Observatori» | `Info.plist` (`CFBundleDisplayName`) |
| Versión | la de `pubspec.yaml` (`1.0.1+2` → `CFBundleShortVersionString` 1.0.1, `CFBundleVersion` 2) | automática |
| iOS mínimo | **13.0** | `Podfile`, `project.pbxproj` |
| Idioma | `ca` | `Info.plist` |
| Esquema del enlace de acceso | `observatoriplh://login-callback` | `Info.plist` (`CFBundleURLTypes`) |
| Icono | símbolo vectorial del manual, fondo blanco, sin transparencia | `Assets.xcassets/AppIcon.appiconset` |
| Pantalla de inicio | símbolo centrado y logotipo abajo; fondo `#FFFFFF` claro / `#1E1C19` oscuro | `LaunchScreen.storyboard`, `LaunchFons`, `LaunchImage`, `LaunchMarca` |
| Navegación | `CupertinoTabBar` en iOS, `NavigationBar` en Android | `lib/app.dart` (`_Seccions`) |
| Confirmaciones | alerta de Apple en iOS (acciones destructivas en rojo) | `lib/ui/adaptatiu.dart` (`confirmar`) |

### Decisiones

- **Bundle ID.** Android usa `com.mamlabsfera.observatori_perlhorta`, pero en iOS el guion bajo no es válido en un bundle ID; se usa `com.mamlabsfera.observatoriPerlhorta` (mismo dominio, camelCase). Una vez registrado en App Store Connect **no se puede cambiar**.
- **iOS 13.0.** Es el mínimo de Flutter 3.41 y el que piden `app_links` (enlace de acceso de Supabase), `connectivity_plus`, `image_picker_ios`, `url_launcher_ios` y `shared_preferences_foundation`. `geolocator_apple` (11.0) y `sqlite3_flutter_libs` (12.0) piden menos.
- **Permisos** (`Info.plist`, en valenciano):
  - `NSCameraUsageDescription`: hacer fotos de lo que se aporta o revisa.
  - `NSPhotoLibraryUsageDescription`: elegir fotos de la fototeca.
  - `NSLocationWhenInUseUsageDescription`: situarse en el mapa y colocar las aportaciones. Solo «mientras se usa»: la app no pide ubicación en segundo plano, así que no hay `NSLocationAlways…`.
  - No hay `NSMicrophoneUsageDescription`: `image_picker` solo lo necesita para vídeo, y la app no graba vídeo.
- **`FlutterDeepLinkingEnabled = false`.** El enlace `observatoriplh://login-callback#…` lo recoge `supabase_flutter` (vía `app_links`); si Flutter también lo pasara a `go_router`, este intentaría abrir una ruta que no existe. Es lo que recomienda `app_links`.
- **`ITSAppUsesNonExemptEncryption = false`.** La app solo usa HTTPS estándar; así App Store Connect no pide documentación de exportación en cada build.
- **Icono y pantalla de inicio** se generan con `app/ios/eines/generar_recursos.py` (PyMuPDF): el icono, desde el PDF del manual de identidad; la pantalla de inicio, copiando las imágenes de Android (`mdpi/xhdpi/xxhdpi` = `@1x/@2x/@3x`) para que las dos plataformas salgan iguales. Para regenerar:
  ```bash
  cd app && python ios/eines/generar_recursos.py "ruta/al/Lobservatori_Manual_dIdentitat_Corporativa.pdf"
  ```
- **iPad.** El proyecto admite iPhone y iPad (`TARGETED_DEVICE_FAMILY = 1,2`), como Android admite tabletas. Si no se quiere revisar la app en iPad ni hacer capturas de iPad para la App Store, en Xcode → Runner → General → Supported Destinations se quita iPad.
- **Hojas inferiores** (`showModalBottomSheet`: ficha del mapa, perfil, ficha de revisión) se mantienen como en Android: en iOS se ven como una hoja estándar y funcionan bien. El diálogo del alias (con campo de texto) también se deja en Material.

## Qué falta (necesita Mac y cuenta de Apple)

1. **Un Mac** con macOS reciente y **Xcode** (App Store, gratis) + `sudo xcode-select -s /Applications/Xcode.app` y abrir Xcode una vez para aceptar la licencia.
2. **Flutter** en el Mac y **CocoaPods** (`brew install cocoapods`). `flutter doctor` debe salir limpio en la parte de iOS.
3. **Primera compilación**:
   ```bash
   cd app
   flutter pub get
   cd ios && pod install && cd ..
   flutter build ios --debug --no-codesign
   ```
   `pod install` crea `Podfile.lock` y `Pods/`; hay que hacer commit de `Podfile.lock` (y de los cambios que Xcode/Flutter hagan en `project.pbxproj`, `Runner.xcworkspace`, etc.). Si Flutter tiene activado Swift Package Manager, algunos plugins entrarán por SPM y no por CocoaPods: es normal.
4. **Abrir `app/ios/Runner.xcworkspace`** (no el `.xcodeproj`) y revisar que el `LaunchScreen.storyboard` y los assets se ven bien: se escribieron a mano, sin Interface Builder, y Xcode puede reescribir la cabecera del storyboard al guardarlo.
5. **Cuenta Apple Developer** (99 €/año, developer.apple.com/programs). Para probar en un iPhone propio basta un Apple ID gratuito (firma personal, la app caduca a los 7 días); para TestFlight y la App Store hace falta la cuenta de pago. Si se quiere publicar a nombre de Per l'Horta, conviene una cuenta de **organización** (necesita número D-U-N-S).
6. **Firma**: Xcode → Runner → Signing & Capabilities → Team = el equipo de la cuenta; «Automatically manage signing». El bundle ID se registrará solo. No hay que añadir capacidades (ni Push, ni Associated Domains): el enlace de acceso es un esquema propio.
7. **App Store Connect**: crear la app con el bundle ID `com.mamlabsfera.observatoriPerlhorta`, nombre, idioma principal catalán, categoría, URL de política de privacidad y la ficha de **privacidad de datos** (correo electrónico para la cuenta, ubicación precisa y fotos vinculadas a las aportaciones; sin seguimiento).
8. **TestFlight**: `flutter build ipa` (o Product → Archive en Xcode) y subir con Xcode Organizer o Transporter. Los testers internos (hasta 100, del equipo) la reciben sin revisión; los externos necesitan una revisión beta de Apple.
9. **Supabase**: la URL `observatoriplh://login-callback` **ya está** en Authentication → URL Configuration → Redirect URLs. No hay que tocar nada más en el servidor.
10. **Manifiesto de privacidad** (`PrivacyInfo.xcprivacy`): los plugins traen el suyo; si Apple avisa al subir el build de que falta uno para la app, se añade desde Xcode (File → New → App Privacy) declarando `UserDefaults` (motivo `CA92.1`).

## Lista de comprobación en un iPhone

Instalar con `flutter run --release` (o desde TestFlight) y comprobar:

- [ ] El icono en la pantalla de inicio es el símbolo sobre blanco, sin bordes raros; el nombre debajo es «Observatori».
- [ ] La pantalla de inicio sale con el símbolo centrado y el logotipo abajo, con fondo blanco en modo claro y `#1E1C19` en modo oscuro (Ajustes → Pantalla y brillo).
- [ ] **Entrada**: pedir el enlace, abrir el correo **en el mismo iPhone**, tocar el enlace → se abre la app (no Safari) y entra directamente. Probarlo con la app cerrada del todo y con la app en segundo plano.
- [ ] Primer acceso: pide el alias y lo guarda.
- [ ] **Ubicación**: el primer uso muestra el aviso de iOS con el texto en valenciano; «Permitir al usar la app» centra el mapa; «No permitir» muestra el aviso de GPS no disponible sin colgarse.
- [ ] **Cámara**: aportar → hacer foto: aviso con texto en valenciano; la foto se adjunta.
- [ ] **Fototeca**: aportar → galería: se puede elegir una foto (con acceso limitado y con acceso total).
- [ ] **Barra de pestañas**: estilo iOS, cuatro secciones, insignias de avisos no leídos y de pendientes; tocar la pestaña activa vuelve a su pantalla principal; cada pestaña conserva su historial.
- [ ] Gesto de **deslizar desde el borde izquierdo** para volver atrás en aportar y en la revisión de una partida.
- [ ] Confirmaciones (descargar/borrar paquete de partida, «no trobat») salen como alerta de Apple; las de borrar y «no trobat» en rojo.
- [ ] **Sin conexión** (modo avión): el mapa de una partida descargada se ve; una aportación queda pendiente y se envía al volver la conexión.
- [ ] Cerrar sesión desde el perfil y volver a entrar.
- [ ] Modo oscuro y tamaño de texto grande (Ajustes → Accesibilidad) no rompen ninguna pantalla.
- [ ] En un iPhone con muesca/isla dinámica, nada queda tapado arriba ni por la barra de inicio abajo.
- [ ] Si se mantiene iPad: girar el iPad y usar la app en vertical y horizontal.
