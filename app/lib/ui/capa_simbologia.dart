import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../services/simbologia.dart';

// Lo que flutter_map no dibuixa per si mateix: les trames de les parcel·les i la decoració de
// les línies de la guia de disseny. Les mateixes formes que la web (web/src/features/mapa/simbologia.ts).

/// Mida (amplada, alçada) del tram de cada glif; es repeteix al llarg de la línia.
const midaGlif = <String, Size>{
  'quadrat': Size(9, 8), 'travesser': Size(7, 8), 'mur': Size(14, 8), 'x': Size(8, 10),
  'ziga': Size(10, 8), 'ona': Size(12, 8), 'fletxa': Size(9, 8),
};

/// Distància entre glifs: les trames, seguides; les fletxes de les sèquies, espaiades.
double _pas(String glif) => glif == 'fletxa' ? 70 : midaGlif[glif]!.width;

/// Un tram de la decoració, amb la línia d'esquerra a dreta a mitja alçada (0,0 a dalt a l'esquerra).
void dibuixarGlif(Canvas c, String glif, Color color, Size mida) {
  final w = mida.width, h = mida.height, m = h / 2;
  final traca = Paint()
    ..color = color
    ..strokeWidth = 1.2
    ..style = PaintingStyle.stroke;
  final ple = Paint()..color = color;
  void linia([double y = -1]) => c.drawLine(Offset(0, y < 0 ? m : y), Offset(w, y < 0 ? m : y), traca);
  switch (glif) {
    case 'quadrat':
      c.drawRect(Rect.fromLTWH(1.5, m - 3, 6, 6), traca);
    case 'travesser':
      linia();
      c.drawLine(Offset(w / 2, m - 2.5), Offset(w / 2, m + 2.5), traca);
    case 'mur':
      linia(m - 1.5);
      c.drawRect(Rect.fromLTWH(w / 2 - 1, m - 1.5, 2.2, 4.5), ple);
    case 'x':
      linia(m - 2.5);
      c.drawLine(Offset(w / 2 - 2, m), Offset(w / 2 + 2, m + 4), traca);
      c.drawLine(Offset(w / 2 + 2, m), Offset(w / 2 - 2, m + 4), traca);
    case 'ziga':
      c.drawPath(Path()..moveTo(0, m + 3)..lineTo(w / 2, m - 3)..lineTo(w, m + 3), traca);
    case 'ona':
      c.drawPath(
        Path()
          ..moveTo(0, m + 2)
          ..cubicTo(0, m - 4, w / 2, m - 4, w / 2, m + 2)
          ..cubicTo(w / 2, m + 3, w, m + 3, w, m + 2),
        traca..strokeWidth = 1.5,
      );
    case 'fletxa':
      c.drawPath(
        Path()
          ..moveTo(w - 1, m)
          ..lineTo(1, 1)
          ..lineTo(4, m)
          ..lineTo(1, h - 1)
          ..close(),
        ple,
      );
  }
}

/// Repeteix el glif al llarg del traca (en coordenades de pantalla).
void dibuixarGlifsAlLlarg(Canvas c, Path traca, String glif, Color color) {
  final mida = midaGlif[glif]!;
  final pas = _pas(glif);
  for (final metrica in traca.computeMetrics()) {
    // Les fletxes comencen a mig pas: no s'apilen a l'inici de cada tram curt
    for (var d = glif == 'fletxa' ? pas / 2 : 0.0; d < metrica.length; d += pas) {
      final t = metrica.getTangentForOffset(d);
      if (t == null) continue;
      c.save();
      c.translate(t.position.dx, t.position.dy);
      c.rotate(math.atan2(t.vector.dy, t.vector.dx));
      c.translate(glif == 'fletxa' ? -mida.width / 2 : 0, -mida.height / 2);
      dibuixarGlif(c, glif, color, mida);
      c.restore();
    }
  }
}

/// Trama blanca (ratlles o punts) dins d'un rectangle, alineada amb [origen] perquè no
/// «llisque» en moure el mapa.
void dibuixarTrama(Canvas c, Rect r, String trama, {Offset origen = Offset.zero, double opacitat = 1}) {
  final blanc = Paint()..color = Colors.white.withValues(alpha: opacitat);
  if (trama == 'ratlles') {
    const pas = 9.0;
    blanc
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;
    final inici = ((r.left + r.top + origen.dx + origen.dy) / pas).floor() * pas - origen.dx - origen.dy;
    for (var k = inici - r.height; k < r.right + r.bottom; k += pas) {
      // Diagonal x + y = k (cap amunt cap a la dreta)
      c.drawLine(Offset(k - r.bottom, r.bottom), Offset(k - r.top, r.top), blanc);
    }
  } else {
    const pas = 8.0;
    final x0 = ((r.left + origen.dx) / pas).floor() * pas - origen.dx;
    final y0 = ((r.top + origen.dy) / pas).floor() * pas - origen.dy;
    var fila = ((y0 + origen.dy) / pas).round();
    for (var y = y0; y < r.bottom + pas; y += pas, fila++) {
      for (var x = x0 + (fila.isOdd ? pas / 2 : 0); x < r.right + pas; x += pas) {
        c.drawCircle(Offset(x, y), 1.8, blanc);
      }
    }
  }
}

class ParcelaAmbTrama {
  const ParcelaAmbTrama(this.anells, this.trama, this.opacitat);
  final List<List<LatLng>> anells;
  final String trama;
  final double opacitat;
}

class LiniaAmbGlif {
  const LiniaAmbGlif(this.punts, this.simbol);
  final List<LatLng> punts;
  final SimbolLinia simbol;
}

/// Capa del mapa: trames de parcel·la i/o glifs de línia.
class CapaSimbologia extends StatelessWidget {
  const CapaSimbologia({super.key, this.parceles = const [], this.linies = const []});

  final List<ParcelaAmbTrama> parceles;
  final List<LiniaAmbGlif> linies;

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);
    return MobileLayerTransformer(
      child: CustomPaint(size: camera.size, painter: _Pintor(camera, parceles, linies)),
    );
  }
}

class _Pintor extends CustomPainter {
  _Pintor(this.camera, this.parceles, this.linies);

  final MapCamera camera;
  final List<ParcelaAmbTrama> parceles;
  final List<LiniaAmbGlif> linies;

  Path _cami(List<LatLng> punts, {bool tancat = false}) {
    final p = Path();
    for (var i = 0; i < punts.length; i++) {
      final o = camera.latLngToScreenOffset(punts[i]);
      i == 0 ? p.moveTo(o.dx, o.dy) : p.lineTo(o.dx, o.dy);
    }
    if (tancat) p.close();
    return p;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final pantalla = Offset.zero & size;
    // Les trames, fixes respecte del món (no de la pantalla)
    final origen = camera.pixelOrigin;
    for (final p in parceles) {
      final cami = Path()..fillType = ui.PathFillType.evenOdd;
      for (final anell in p.anells) {
        cami.addPath(_cami(anell, tancat: true), Offset.zero);
      }
      final r = cami.getBounds().intersect(pantalla);
      if (r.isEmpty) continue;
      canvas.save();
      canvas.clipPath(cami);
      dibuixarTrama(canvas, r, p.trama, origen: origen, opacitat: p.opacitat);
      canvas.restore();
    }
    for (final l in linies) {
      final cami = _cami(l.punts);
      if (!cami.getBounds().overlaps(pantalla.inflate(20))) continue;
      dibuixarGlifsAlLlarg(canvas, cami, l.simbol.glif!, l.simbol.color);
    }
  }

  @override
  bool shouldRepaint(_Pintor old) => old.camera != camera || old.parceles != parceles || old.linies != linies;
}

/// El símbol en petit, per a la llegenda: icona, tram de línia o mostra de parcel·la.
class MostraSimbol extends StatelessWidget {
  const MostraSimbol(this.simbol, {super.key, this.mida = 24});

  final Simbol simbol;
  final double mida;

  @override
  Widget build(BuildContext context) => switch (simbol) {
        SimbolPunt s => Image.asset(s.asset, width: mida, height: mida, fit: BoxFit.contain),
        _ => SizedBox(width: mida * 1.3, height: mida * 0.6, child: CustomPaint(painter: _PintorMostra(simbol))),
      };
}

class _PintorMostra extends CustomPainter {
  _PintorMostra(this.simbol);
  final Simbol simbol;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Offset.zero & size;
    switch (simbol) {
      case SimbolParcela s:
        canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(2)), Paint()..color = s.color);
        if (s.trama != null) {
          canvas.save();
          canvas.clipRect(r);
          dibuixarTrama(canvas, r, s.trama!);
          canvas.restore();
        }
        canvas.drawRRect(
          RRect.fromRectAndRadius(r.deflate(0.5), const Radius.circular(2)),
          Paint()
            ..color = s.contorn
            ..style = PaintingStyle.stroke,
        );
      case SimbolLinia s:
        final m = size.height / 2;
        final glif = s.glif;
        if (glif != null && glifsTrama.contains(glif)) {
          dibuixarGlifsAlLlarg(canvas, Path()..moveTo(0, m)..lineTo(size.width, m), glif, s.color);
          return;
        }
        final traca = Paint()
          ..color = s.color
          ..strokeWidth = math.min(s.amplada, 2.5)
          ..style = PaintingStyle.stroke;
        if (s.patro == 'doble') {
          traca.strokeWidth = 1.2;
          canvas.drawLine(Offset(0, m - 2), Offset(size.width, m - 2), traca);
          canvas.drawLine(Offset(0, m + 2), Offset(size.width, m + 2), traca);
        } else {
          // Traç i buit alternats, com el StrokePattern del mapa
          final trams = switch (s.patro) {
            'discontinua' => const [6.0, 4.0],
            'puntejada' => const [1.5, 3.0],
            'punt_ratlla' => const [8.0, 3.0, 1.5, 3.0],
            _ => [size.width],
          };
          var x = 0.0;
          for (var i = 0; x < size.width; i++) {
            final llarg = trams[i % trams.length];
            if (i.isEven) canvas.drawLine(Offset(x, m), Offset(math.min(x + llarg, size.width), m), traca);
            x += llarg;
          }
        }
        if (glif == 'fletxa') {
          canvas.save();
          canvas.translate(size.width - midaGlif['fletxa']!.width, m - midaGlif['fletxa']!.height / 2);
          dibuixarGlif(canvas, 'fletxa', s.color, midaGlif['fletxa']!);
          canvas.restore();
        }
      case SimbolPunt _:
        break;
    }
  }

  @override
  bool shouldRepaint(_PintorMostra old) => old.simbol != simbol;
}
