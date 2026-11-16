import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:observatori_horta/core/tema_app.dart';
import 'package:observatori_horta/l10n/app_localizations.dart';
import 'package:observatori_horta/ui/fitxa_mapa.dart';

Widget _app(Widget fill) => MaterialApp(
      theme: temaApp(Brightness.light),
      locale: const Locale('ca'),
      supportedLocales: L.supportedLocales,
      localizationsDelegates: L.localizationsDelegates,
      home: Scaffold(body: fill),
    );

const _del2018 = {
  'id': 'e1',
  'tema': 'Construccions',
  'variable': 'Alqueria',
  'estat': 'validat',
  'per_revisar': true,
  'partida_id': 7,
};

void main() {
  setUpAll(() => initializeDateFormatting('ca'));

  testWidgets('el padrí pot dir que continua igual', (tester) async {
    final resultats = <String>[];
    await tester.pumpWidget(_app(FitxaMapa(
      prop: _del2018,
      color: Colors.blue,
      esPadri: true,
      pendent: false,
      onRevisar: resultats.add,
      onCanviat: () => resultats.add('aportacio'),
      onObrirPartida: () {},
    )));
    expect(find.text('És encara així?'), findsOneWidget);
    await tester.tap(find.text('Sí, igual'));
    await tester.tap(find.text('Ha canviat'));
    expect(resultats, ['igual', 'canviat']);
    expect(find.text('Obre la revisió de la partida'), findsOneWidget);
  });

  testWidgets('qui no és padrí només pot proposar una aportació nova', (tester) async {
    final resultats = <String>[];
    await tester.pumpWidget(_app(FitxaMapa(
      prop: _del2018,
      color: Colors.blue,
      esPadri: false,
      pendent: false,
      onRevisar: resultats.add,
      onCanviat: () => resultats.add('aportacio'),
    )));
    expect(find.text('Sí, igual'), findsNothing);
    expect(find.text('Ha canviat?'), findsOneWidget);
    await tester.tap(find.text('Ha canviat'));
    expect(resultats, ['aportacio']);
  });

  testWidgets('el que no està validat no es pot substituir', (tester) async {
    await tester.pumpWidget(_app(FitxaMapa(
      prop: {..._del2018, 'estat': 'pendent', 'per_revisar': false},
      color: Colors.blue,
      esPadri: true,
      pendent: false,
      onRevisar: (_) {},
      onCanviat: () {},
    )));
    expect(find.text('Ha canviat'), findsNothing);
    expect(find.text('Pendent de validar'), findsOneWidget);
  });
}
