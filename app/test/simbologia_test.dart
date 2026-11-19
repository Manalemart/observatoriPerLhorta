import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:observatori_horta/services/simbologia.dart';

void main() {
  final text = File('assets/simbologia.json').readAsStringSync();
  final s = Simbologia.desDeJson(text);

  test('cada regla de punt té la seua icona en assets/simbols', () {
    final icones = RegExp(r'"icona": "([a-z_]+)"').allMatches(text).map((m) => m.group(1)!).toSet();
    expect(icones, isNotEmpty);
    for (final i in icones) {
      expect(File('assets/simbols/$i.png').existsSync(), isTrue, reason: i);
    }
  });

  test('punts: la icona depén de la categoria en reg i serveis', () {
    final noria = s.simbol(geometria: 'Point', variable: 'Elements del sistema de reg', categoria: 'Nòria ó sènia', tema: 'Infraestructura');
    expect((noria as SimbolPunt).icona, 'noria');
    expect(noria.color, const Color(0xFF009EE0));

    final torre = s.simbol(geometria: 'Point', variable: 'Abastiments i serveis', categoria: "Torre d'alta tensió", tema: 'Infraestructura');
    expect((torre as SimbolPunt).icona, 'torre_tensio', reason: 'la guia la posa en agressions');
    expect(torre.color, const Color(0xFFE2001A));

    final alqueria = s.simbol(geometria: 'Point', variable: 'Alqueria', categoria: 'Runa', tema: 'Construccions');
    expect((alqueria as SimbolPunt).icona, 'construccio', reason: "l'estat de conservació no canvia el símbol");
  });

  test('sense regla: el símbol general de la família del tema', () {
    final x = s.simbol(geometria: 'Point', variable: 'Variable nova', tema: 'Vegetació');
    expect((x as SimbolPunt).icona, 'vegetacio');
  });

  test('línies i parcel·les: estil de la guia', () {
    final terra = s.simbol(geometria: 'LineString', variable: 'Sèquies', categoria: 'Caixer de terra', tema: 'Infraestructura');
    expect([(terra as SimbolLinia).patro, terra.glif], ['puntejada', 'fletxa']);

    final fruiters = s.simbol(geometria: 'MultiPolygon', variable: 'Parcel·les cultivades', categoria: 'Fruiters', tema: 'Ús del sòl');
    expect([(fruiters as SimbolParcela).color, fruiters.trama], [const Color(0xFF9ED100), 'punts']);

    final determinar = s.simbol(geometria: 'Polygon', variable: 'Parcel·les sense cultivar', categoria: 'Per determinar', tema: 'Ús del sòl');
    expect((determinar as SimbolParcela).contorn, const Color(0xFF000000));
  });

  test('dos símbols iguals són iguals (la llegenda només mostra les categories que canvien)', () {
    final a = s.simbol(geometria: 'LineString', variable: 'Vials', categoria: 'Via pecuària', tema: 'Infraestructura');
    final b = s.simbol(geometria: 'LineString', variable: 'Vials', tema: 'Infraestructura');
    expect(a, equals(b));
    expect(identical(a, b), isFalse);
  });
}
