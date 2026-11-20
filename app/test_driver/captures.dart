// Conductor de integration_test/captures_test.dart. S'executa en l'ordinador (no en el
// dispositiu): quan la prova demana una captura, la fa.
//
// - Amb SIMULADOR_UDID (Codemagic, Mac): `xcrun simctl io <udid> screenshot`, la pantalla
//   sencera amb la barra d'estat, a la resolució del simulador (la que demana Apple).
// - Sense: la imatge que dona Flutter (sense barra d'estat).
//
// Les captures van a CAPTURES_DIR (per defecte, captures/).
import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  final carpeta = Directory(Platform.environment['CAPTURES_DIR'] ?? 'captures')..createSync(recursive: true);
  final udid = Platform.environment['SIMULADOR_UDID'];
  if (udid != null && udid.isNotEmpty) {
    // Ara la app ja està instal·lada: el permís d'ubicació, abans que la prova toque «La meua posició»
    await Process.run('xcrun', ['simctl', 'privacy', udid, 'grant', 'location', 'com.mamlabsfera.observatoriPerlhorta']);
  }
  await integrationDriver(
    onScreenshot: (nom, bytes, [args]) async {
      final fitxer = '${carpeta.path}/$nom.png';
      if (udid != null && udid.isNotEmpty) {
        final r = await Process.run('xcrun', ['simctl', 'io', udid, 'screenshot', '--type=png', fitxer]);
        if (r.exitCode != 0) {
          stderr.writeln('simctl: ${r.stderr}');
          return false;
        }
      } else {
        File(fitxer).writeAsBytesSync(bytes);
      }
      stdout.writeln('Captura: $fitxer');
      return true;
    },
  );
}
