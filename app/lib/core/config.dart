import 'package:latlong2/latlong.dart';

/// Se pasa al compilar:
///   flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_KEY=...
/// En un móvil, 127.0.0.1 es el propio móvil: usa la IP del PC (emulador: 10.0.2.2).
class Config {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: 'http://127.0.0.1:64321');
  static const supabaseKey = String.fromEnvironment('SUPABASE_KEY');

  static const paquet = 'com.mamlabsfera.observatori_perlhorta';

  /// Firebase (avisos push). Buit = sense avisos push. Vegeu docs/PUSH.md.
  /// L'appId és diferent per a Android i iOS: cada compilació porta el seu.
  static const firebaseApiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const firebaseAppId = String.fromEnvironment('FIREBASE_APP_ID');
  static const firebaseSenderId = String.fromEnvironment('FIREBASE_SENDER_ID');
  static const firebaseProjectId = String.fromEnvironment('FIREBASE_PROJECT_ID');

  /// Adreça de la web pública, per a compartir enllaços als elements (`/mapa?element=…`).
  /// Buida = encara no hi ha domini: la app no mostra «Comparteix».
  /// Es passa en compilar: --dart-define=URL_WEB=https://...
  static const urlWeb = String.fromEnvironment('URL_WEB');

  /// Compte de revisió de les botigues (Apple i Google no poden rebre el codi del correu).
  /// Només este correu entra amb contrasenya; la resta, sempre amb enllaç o codi.
  /// La contrasenya només és en Supabase. Es pot canviar en compilar
  /// (--dart-define=COMPTE_REVISIO=...) o desactivar amb --dart-define=COMPTE_REVISIO=
  static const compteRevisio = String.fromEnvironment('COMPTE_REVISIO', defaultValue: 'test@mediamapes.com');

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
