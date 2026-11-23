import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:observatori_horta/l10n/app_localizations.dart';
import 'package:observatori_horta/services/idioma.dart';
import 'package:observatori_horta/ui/guia.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('sense triar: castellà si el dispositiu ho està; per a la resta, valencià', () {
    expect(Idioma.resoldre(const Locale('es', 'ES')), Idioma.castella);
    expect(Idioma.resoldre(const Locale('ca')), Idioma.valencia);
    expect(Idioma.resoldre(const Locale('en')), Idioma.valencia);
    expect(Idioma.resoldre(null), Idioma.valencia);
  });

  test("l'idioma triat es recorda", () async {
    SharedPreferences.setMockInitialValues({});
    expect((await Idioma.carregar()).triat, isNull);
    await (await Idioma.carregar()).triar(Idioma.castella);
    expect((await Idioma.carregar()).triat, Idioma.castella);
    await (await Idioma.carregar()).triar(null);
    expect((await Idioma.carregar()).triat, isNull);
  });

  testWidgets('la guia es veu en castellà', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(MaterialApp(
      locale: Idioma.castella,
      supportedLocales: L.supportedLocales,
      localizationsDelegates: L.localizationsDelegates,
      home: const PantallaGuia(),
    ));
    await tester.pumpAndSettle();
    expect(find.text('BIENVENIDA AL OBSERVATORIO'), findsOneWidget);
    expect(find.text('Siguiente'), findsOneWidget);
    expect(find.text('Salta'), findsOneWidget);
  });
}
