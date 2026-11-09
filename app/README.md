# App de camp — Observatori Ciutadà de l'Horta

Flutter. Android primero; `web` existe solo como vista previa de desarrollo (sin cola persistente).

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # si cambia cola_drift.dart

# Claves: npx supabase status -o env. En un móvil, 127.0.0.1 es el móvil:
# emulador → 10.0.2.2 · dispositivo → IP del PC en la misma red
flutter run --dart-define=SUPABASE_URL=http://10.0.2.2:64321 --dart-define=SUPABASE_KEY=<clave>

flutter analyze
flutter test                                               # 16 tests; 4 más de integración:
SUPABASE_KEY=<anon> SUPABASE_SERVICE_KEY=<service> flutter test
```
