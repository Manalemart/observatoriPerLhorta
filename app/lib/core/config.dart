import 'package:latlong2/latlong.dart';

/// Se pasa al compilar:
///   flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_KEY=...
/// En un móvil, 127.0.0.1 es el propio móvil: usa la IP del PC (emulador: 10.0.2.2).
class Config {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: 'http://127.0.0.1:64321');
  static const supabaseKey = String.fromEnvironment('SUPABASE_KEY');

  static const paquet = 'org.perlhorta.observatori_horta';

  static const centreInicial = LatLng(39.48, -0.40);
  static const zoomInicial = 11.0;

  /// Por debajo de este zoom habría demasiados elementos para pintarlos en un móvil.
  static const zoomMinimElements = 13.0;

  static const maxFotos = 5;
}
