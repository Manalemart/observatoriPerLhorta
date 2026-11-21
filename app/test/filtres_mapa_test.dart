import 'package:flutter_test/flutter_test.dart';
import 'package:observatori_horta/ui/filtres_mapa.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('sense filtres es veu tot', () {
    const f = FiltresMapa();
    expect(f.actius, isFalse);
    expect(f.mostra(1, true), isTrue);
    expect(f.mostra(2, false), isTrue);
  });

  test('un tema amagat no es veu; els altres sí', () {
    const f = FiltresMapa(temesAmagats: {1});
    expect(f.actius, isTrue);
    expect(f.mostra(1, false), isFalse);
    expect(f.mostra(2, false), isTrue);
  });

  test('època: de 2018 només el que està per revisar; noves, la resta', () {
    const de2018 = FiltresMapa(epoca: EpocaFiltre.inventari2018);
    expect(de2018.mostra(1, true), isTrue);
    expect(de2018.mostra(1, false), isFalse);
    const noves = FiltresMapa(epoca: EpocaFiltre.noves);
    expect(noves.mostra(1, true), isFalse);
    expect(noves.mostra(1, false), isTrue);
  });

  test('es guarden en el dispositiu', () async {
    SharedPreferences.setMockInitialValues({});
    await const FiltresMapa(temesAmagats: {3, 5}, epoca: EpocaFiltre.noves).desar();
    final f = await FiltresMapa.carregar();
    expect(f.temesAmagats, {3, 5});
    expect(f.epoca, EpocaFiltre.noves);
  });
}
