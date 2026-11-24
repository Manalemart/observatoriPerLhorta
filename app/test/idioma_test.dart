import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:observatori_horta/l10n/app_localizations.dart';
import 'package:observatori_horta/services/idioma.dart';
import 'package:observatori_horta/ui/guia.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('sense triar: valencià, castellà o, per a la resta, anglés', () {
    expect(Idioma.resoldre(const Locale('es', 'ES')), Idioma.castella);
    expect(Idioma.resoldre(const Locale('ca')), Idioma.valencia);
    expect(Idioma.resoldre(const Locale('en')), Idioma.angles);
    expect(Idioma.resoldre(const Locale('fr')), Idioma.angles);
    expect(Idioma.resoldre(null), Idioma.angles);
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

  testWidgets('la guia es veu en anglés', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(MaterialApp(
      locale: Idioma.angles,
      supportedLocales: L.supportedLocales,
      localizationsDelegates: L.localizationsDelegates,
      home: const PantallaGuia(),
    ));
    await tester.pumpAndSettle();
    expect(find.text('WELCOME TO THE OBSERVATORY'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
  });
}
