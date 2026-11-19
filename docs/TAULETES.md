# La app en tabletas (iPad y Android)

La app es la misma en móvil y en tableta: se adapta al **ancho de la ventana**, no al dispositivo. Así también funciona en pantalla dividida (Split View en iPad, multiventana en Android), donde el ancho cambia sobre la marcha.

## Qué cambia en pantalla ancha

Clases de ventana de Material 3: compacta (< 600 dp, móvil), media (600-839, tableta vertical o pantalla dividida) y expandida (≥ 840, tableta horizontal). El código está en `app/lib/ui/adaptatiu.dart`.

| Qué | Móvil | Tableta (≥ 600 dp) |
|---|---|---|
| Navegación, Android | barra inferior | **barra lateral** (NavigationRail) con el símbolo de la marca arriba, mismos colores y tipografía |
| Navegación, iPad | barra de pestañas de Apple | igual: es la navegación que piden las guías de Apple también en iPad |
| Listas (Partides, Avisos, Les meues) | todo el ancho | columna centrada de 720 dp como máximo |
| Formularios (Aporta, entrada) | todo el ancho | columna centrada de 600 dp (entrada, 420) |
| Mapas | pantalla completa | pantalla completa; la barra flotante y los avisos, con ancho de móvil |
| Hojas inferiores (ficha, revisión, leyenda) | todo el ancho | 640 dp como máximo (por defecto en Material 3) |

## Lo que piden las tiendas

### App Store (iPad)

- El proyecto ya admite iPad (`TARGETED_DEVICE_FAMILY = 1,2`) y las cuatro orientaciones en iPad (`UISupportedInterfaceOrientations~ipad`), con `LaunchScreen.storyboard` y sin `UIRequiresFullScreen`: es lo que exige Apple para la multitarea (Split View y Slide Over).
- **Capturas de iPad obligatorias** si se publica para iPad: tamaño de 13" (2064 × 2752 o 2752 × 2064). Se hacen en el simulador de iPad Pro 13" desde un Mac.
- Si no se quiere publicar en iPad: Xcode → Runner → General → Supported Destinations → quitar iPad (y entonces no hacen falta las capturas).

### Google Play (tabletas)

- La actividad no fija la orientación y es redimensionable (por defecto desde `targetSdk` 24): admite giro, multiventana y ventanas libres (ChromeOS).
- La interfaz no se estira ni deja bandas negras: la navegación pasa al lateral y el contenido de lectura se centra (calidad «Tier 2/3» de las directrices de pantallas grandes).
- **Capturas de tableta** en la ficha de Play: hasta 8 de tableta de 7" y de 10". Se pueden sacar del emulador `obs_tauleta_api35` (Pixel Tablet, 2560 × 1600).

## Cómo probarlo

- **Android:** emulador `obs_tauleta_api35` (Pixel Tablet, API 35, horizontal). Se creó a mano en `~/.android/avd/` a partir de la imagen de sistema del emulador del móvil.
- **iPad:** pendiente de Mac (ver [IOS.md](IOS.md)).
