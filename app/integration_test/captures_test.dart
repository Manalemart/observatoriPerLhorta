// Captures per a les botigues (App Store i Google Play).
//
// Obri la app de veres contra Supabase, entra amb un compte de prova, va a l'horta de
// Benimaclet i passa per les pantalles principals. A cada pas demana una captura al conductor
// (test_driver/captures.dart), que la fa des del Mac amb `xcrun simctl` (amb barra d'estat)
// o, fora d'iOS, guarda la imatge de Flutter.
//
// El compte de prova entra amb contrasenya (la app només ho fa amb codi): s'ha de crear en
// Supabase → Authentication → Users amb contrasenya i àlies. Vegeu docs/CODEMAGIC.md.
//
//   flutter drive --driver=test_driver/captures.dart --target=integration_test/captures_test.dart \
//     --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_KEY=... \
//     --dart-define=CAPTURES_EMAIL=... --dart-define=CAPTURES_PASSWORD=...
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:observatori_horta/main.dart' as app;
import 'package:supabase_flutter/supabase_flutter.dart';

const _email = String.fromEnvironment('CAPTURES_EMAIL');
const _contrasenya = String.fromEnvironment('CAPTURES_PASSWORD');

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// El mapa no para mai del tot (teseles, animacions): s'espera un temps fix.
  Future<void> esperar(WidgetTester tester, [int segons = 4]) async {
    for (var i = 0; i < segons * 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> captura(WidgetTester tester, String nom) async {
    await esperar(tester, 1);
    await binding.takeScreenshot(nom);
  }

  testWidgets('captures de les botigues', (tester) async {
    expect(_email, isNotEmpty, reason: 'Falta --dart-define=CAPTURES_EMAIL');
    await app.main();
    await Supabase.instance.client.auth.signInWithPassword(email: _email, password: _contrasenya);
    await esperar(tester, 6);

    // 1. El mapa a l'horta de Benimaclet: la posició del simulador la fixa el flux
    //    (xcrun simctl location) i el permís ja està donat.
    await tester.tap(find.byTooltip('La meua posició'));
    await esperar(tester, 10);
    await captura(tester, '01_mapa');

    // 2. La llegenda
    await tester.tap(find.byTooltip('Llegenda'));
    await esperar(tester, 2);
    await captura(tester, '02_llegenda');
    await tester.tapAt(const Offset(20, 120)); // fora del full: es tanca
    await esperar(tester, 2);

    // 3. Aportar: el primer pas
    await tester.tap(find.text('Aporta'));
    await esperar(tester, 3);
    await captura(tester, '03_aporta');
    await tester.binding.handlePopRoute(); // enrere
    await esperar(tester, 2);

    // 4-6. Les altres seccions
    for (final (nom, etiqueta) in [('04_partides', 'Partides'), ('05_avisos', 'Avisos'), ('06_les_meues', 'Les meues')]) {
      await tester.tap(find.text(etiqueta).last);
      await esperar(tester, 4);
      await captura(tester, nom);
    }
  });
}
