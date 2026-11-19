import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../services/simbologia.dart';

// ─── Agrupació de punts ────────────────────────────────────────────────────
// Quan diverses icones de la mateixa categoria es trepitgen, se'n pinta una sola amb el
// nombre d'elements. Categories diferents no s'agrupen mai: cada grup porta la icona de la
// guia que li toca. Es recalcula amb el zoom (la capa viu dins del mapa).

/// A partir d'este zoom no s'agrupa: les icones ja no es trepitgen (o són al mateix lloc).
const zoomSenseAgrupar = 18.0;

/// Distància en píxels per davall de la qual dues icones es trepitgen.
const distanciaAgrupar = 30.0;

/// Un element puntual del mapa.
class PuntMapa {
  const PuntMapa({
    required this.punt,
    required this.clau,
    required this.simbol,
    required this.prop,
    required this.validat,
    required this.perRevisar,
  });

  final LatLng punt;

  /// Només s'agrupen punts amb la mateixa clau (variable i categoria).
  final String clau;
  final SimbolPunt simbol;
  final Map<String, dynamic> prop;
  final bool validat;
  final bool perRevisar;
}

/// Punts de la mateixa categoria que, a un zoom, es trepitgen.
class GrupPunts {
  GrupPunts(PuntMapa primer, this._x, this._y) : punts = [primer];

  final List<PuntMapa> punts;
  double _x, _y; // centre en píxels del zoom on s'ha agrupat

  PuntMapa get primer => punts.first;

  LatLng get centre => LatLng(
        punts.map((p) => p.punt.latitude).reduce((a, b) => a + b) / punts.length,
        punts.map((p) => p.punt.longitude).reduce((a, b) => a + b) / punts.length,
      );

  void _afegir(PuntMapa p, double x, double y) {
    punts.add(p);
    // centre mitjà, perquè el grup no depenga només del primer punt
    _x += (x - _x) / punts.length;
    _y += (y - _y) / punts.length;
  }
}

/// Agrupa [punts] de la mateixa clau que, a [zoom], queden a menys de [distancia] píxels.
/// [projectar] passa d'un punt a píxels (en el mapa, la projecció de la càmera).
List<GrupPunts> agruparPunts(
  List<PuntMapa> punts,
  double zoom,
  math.Point<double> Function(LatLng punt, double zoom) projectar, {
  double distancia = distanciaAgrupar,
}) {
  if (zoom >= zoomSenseAgrupar) {
    return [for (final p in punts) GrupPunts(p, 0, 0)];
  }
  final d2 = distancia * distancia;
  final perClau = <String, List<GrupPunts>>{};
  final grups = <GrupPunts>[];
  for (final p in punts) {
    final xy = projectar(p.punt, zoom);
    final mateixos = perClau.putIfAbsent(p.clau, () => []);
    GrupPunts? proper;
    var millor = d2;
    for (final g in mateixos) {
      final dx = g._x - xy.x, dy = g._y - xy.y;
      final dd = dx * dx + dy * dy;
      if (dd < millor) {
        millor = dd;
        proper = g;
      }
    }
    if (proper != null) {
      proper._afegir(p, xy.x, xy.y);
    } else {
      final g = GrupPunts(p, xy.x, xy.y);
      mateixos.add(g);
      grups.add(g);
    }
  }
  return grups;
}

/// Capa de punts del mapa, agrupats segons el zoom actual.
class CapaPunts extends StatefulWidget {
  const CapaPunts({super.key, required this.punts, required this.obrir});

  final List<PuntMapa> punts;

  /// Toc en un punt sol: obri la seua fitxa.
  final void Function(PuntMapa p) obrir;

  @override
  State<CapaPunts> createState() => _CapaPuntsState();
}

class _CapaPuntsState extends State<CapaPunts> {
  // L'agrupació només canvia amb el zoom (a escalons de 0,25) o amb els punts.
  List<PuntMapa>? _punts;
  double? _zoom;
  List<GrupPunts> _grups = const [];

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);
    final zoom = (camera.zoom * 4).floorToDouble() / 4;
    if (!identical(_punts, widget.punts) || _zoom != zoom) {
      _punts = widget.punts;
      _zoom = zoom;
      _grups = agruparPunts(widget.punts, zoom, (p, z) {
        final o = camera.crs.latLngToOffset(p, z);
        return math.Point(o.dx, o.dy);
      });
    }
    return MarkerLayer(
      markers: [
        for (final g in _grups)
          Marker(
            point: g.punts.length == 1 ? g.primer.punt : g.centre,
            width: 44,
            height: 44,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => g.punts.length == 1 ? widget.obrir(g.primer) : _apropar(context, g),
              child: g.punts.length == 1 ? _Icona(g.primer) : _Grup(g),
            ),
          ),
      ],
    );
  }

  /// Toc en un grup: s'acosta fins que els seus punts se separen.
  void _apropar(BuildContext context, GrupPunts g) {
    final controller = MapController.of(context);
    final camera = MapCamera.of(context);
    final limits = LatLngBounds.fromPoints([for (final p in g.punts) p.punt]);
    final ajust = CameraFit.bounds(bounds: limits, padding: const EdgeInsets.all(80), maxZoom: zoomSenseAgrupar);
    var desti = ajust.fit(camera);
    // si l'ajust no acosta prou (punts molt junts), com a mínim dos nivells més
    if (desti.zoom < camera.zoom + 1) {
      desti = camera.withPosition(center: g.centre, zoom: math.min(camera.zoom + 2, zoomSenseAgrupar));
    }
    controller.move(desti.center, desti.zoom);
  }
}

/// Icona de la guia. Lo de 2018 sense revisar, més pàl·lid; lo no validat, amb anell negre.
class _Icona extends StatelessWidget {
  const _Icona(this.p);

  final PuntMapa p;

  @override
  Widget build(BuildContext context) => Stack(
        alignment: Alignment.center,
        children: [
          if (!p.validat)
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.6),
                border: Border.all(color: Colors.black, width: 2),
              ),
            ),
          Opacity(
            opacity: p.perRevisar ? 0.6 : 1,
            child: Image.asset(p.simbol.asset, width: 30, height: 30, fit: BoxFit.contain, filterQuality: FilterQuality.medium),
          ),
        ],
      );
}

/// Grup: la icona de la categoria, un poc més gran, amb el nombre d'elements en una pastilla
/// del color de la família.
class _Grup extends StatelessWidget {
  const _Grup(this.g);

  final GrupPunts g;

  @override
  Widget build(BuildContext context) {
    final s = g.primer.simbol;
    final totsPerRevisar = g.punts.every((p) => p.perRevisar);
    final algunNoValidat = g.punts.any((p) => !p.validat);
    final n = g.punts.length;
    return Semantics(
      label: '$n',
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.85),
              border: Border.all(color: algunNoValidat ? Colors.black : s.color, width: 2),
            ),
          ),
          Opacity(
            opacity: totsPerRevisar ? 0.6 : 1,
            child: Image.asset(s.asset, width: 30, height: 30, fit: BoxFit.contain, filterQuality: FilterQuality.medium),
          ),
          Positioned(
            right: -6,
            top: -6,
            child: Container(
              constraints: const BoxConstraints(minWidth: 20),
              height: 20,
              padding: const EdgeInsets.symmetric(horizontal: 5),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: s.color,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Text(
                n > 99 ? '99+' : '$n',
                style: TextStyle(color: _tinta(s.color), fontSize: 11, fontWeight: FontWeight.w800, height: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Blanc damunt dels colors foscos; damunt del taronja de construccions, text fosc.
Color _tinta(Color fons) =>
    ThemeData.estimateBrightnessForColor(fons) == Brightness.dark ? Colors.white : const Color(0xFF2B2520);
