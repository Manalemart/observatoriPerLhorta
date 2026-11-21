import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:observatori_horta/l10n/app_localizations.dart';
import 'package:observatori_horta/ui/guia.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('la guia es veu una vegada i es pot recórrer fins al final', (tester) async {
    SharedPreferences.setMockInitialValues({});
    expect(await guiaVista(), isFalse);

    await tester.pumpWidget(MaterialApp(
      locale: const Locale('ca'),
      supportedLocales: L.supportedLocales,
      localizationsDelegates: L.localizationsDelegates,
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(onPressed: () => mostrarGuia(context), child: const Text('obri')),
        ),
      ),
    ));
    await tester.tap(find.text('obri'));
    await tester.pumpAndSettle();

    expect(find.text("BENVINGUDA A L'OBSERVATORI"), findsOneWidget);
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('Següent'));
      await tester.pumpAndSettle();
    }
    expect(find.text('DADES OBERTES'), findsOneWidget);
    expect(find.text('Salta'), findsNothing);

    await tester.tap(find.text('Comença'));
    await tester.pumpAndSettle();
    expect(find.text('obri'), findsOneWidget);
    expect(await guiaVista(), isTrue);
  });
}
