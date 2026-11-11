import 'package:latlong2/latlong.dart';

/// Se pasa al compilar:
///   flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_KEY=...
/// En un móvil, 127.0.0.1 es el propio móvil: usa la IP del PC (emulador: 10.0.2.2).
class Config {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: 'http://127.0.0.1:64321');
  static const supabaseKey = String.fromEnvironment('SUPABASE_KEY');

  static const paquet = 'com.mamlabsfera.observatori_perlhorta';

  /// Vuelta a la app desde el enlace del correo. El esquema no puede ser el nombre del
  /// paquete: los esquemas de URL no admiten «_». Tiene que estar en las Redirect URLs de
  /// Supabase y en el intent-filter de AndroidManifest.xml.
  static const redireccioEntrada = 'observatoriplh://login-callback';

  static const centreInicial = LatLng(39.48, -0.40);
  static const zoomInicial = 11.0;

  /// Por debajo de este zoom habría demasiados elementos para pintarlos en un móvil.
  static const zoomMinimElements = 13.0;

  static const maxFotos = 5;
}
