import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:observatori_horta/ui/adaptatiu.dart';

Future<bool?> obrir(WidgetTester tester, TargetPlatform plataforma, String boto) async {
  bool? resposta;
  await tester.pumpWidget(MaterialApp(
    theme: ThemeData(platform: plataforma),
    home: Builder(
      builder: (context) => TextButton(
        onPressed: () async => resposta = await confirmar(context, text: 'Segur?', cancelar: 'No', acceptar: 'Sí'),
        child: const Text('obri'),
      ),
    ),
  ));
  await tester.tap(find.text('obri'));
  await tester.pumpAndSettle();
  final apple = plataforma == TargetPlatform.iOS;
  expect(find.byType(CupertinoAlertDialog), apple ? findsOneWidget : findsNothing);
  expect(find.byType(AlertDialog), apple ? findsNothing : findsOneWidget);
  await tester.tap(find.text(boto));
  await tester.pumpAndSettle();
  return resposta;
}

void main() {
  testWidgets('confirmar: alerta de Material en Android', (tester) async {
    expect(await obrir(tester, TargetPlatform.android, 'Sí'), isTrue);
  });

  testWidgets("confirmar: alerta d'Apple en iOS", (tester) async {
    expect(await obrir(tester, TargetPlatform.iOS, 'Sí'), isTrue);
    expect(await obrir(tester, TargetPlatform.iOS, 'No'), isFalse);
  });
}
