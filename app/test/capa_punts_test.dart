import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:observatori_horta/services/simbologia.dart';
import 'package:observatori_horta/ui/capa_punts.dart';

const _s = SimbolPunt(color: Colors.orange, icona: 'casa', contorn: Colors.white);

PuntMapa _p(double x, String clau) =>
    PuntMapa(punt: LatLng(0, x), clau: clau, simbol: _s, prop: const {}, validat: true, perRevisar: false);

// Projecció de prova: la longitud, en píxels
math.Point<double> _proj(LatLng p, double z) => math.Point(p.longitude, 0);

void main() {
  test('agrupa els punts de la mateixa categoria que es trepitgen', () {
    final g = agruparPunts([_p(0, 'a'), _p(10, 'a'), _p(100, 'a')], 14, _proj);
    expect(g.map((x) => x.punts.length), [2, 1]);
  });

  test('categories diferents no s\'agrupen encara que es trepitgen', () {
    final g = agruparPunts([_p(0, 'a'), _p(5, 'b'), _p(8, 'a')], 14, _proj);
    expect(g.length, 2);
    expect(g.firstWhere((x) => x.primer.clau == 'a').punts.length, 2);
    expect(g.firstWhere((x) => x.primer.clau == 'b').punts.length, 1);
  });

  test('de molt prop no agrupa', () {
    final g = agruparPunts([_p(0, 'a'), _p(1, 'a')], zoomSenseAgrupar, _proj);
    expect(g.length, 2);
  });
}
