import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../data/local/magatzem.dart';
import '../data/revisio.dart';

/// Una tesela del mapa (esquema XYZ / GoogleMapsCompatible).
typedef Tesela = ({int z, int x, int y});

/// Lo que se sabe de un paquete descargado.
class InfoPaquet {
  const InfoPaquet({required this.partidaId, required this.nom, required this.descarregat, required this.teseles, required this.bytes});

  factory InfoPaquet.fromJson(Map<String, dynamic> j) => InfoPaquet(
        partidaId: j['partida_id'] as int,
        nom: j['nom'] as String,
        descarregat: DateTime.parse(j['descarregat'] as String),
        teseles: j['teseles'] as int,
        bytes: j['bytes'] as int,
      );

  Map<String, dynamic> toJson() =>
      {'partida_id': partidaId, 'nom': nom, 'descarregat': descarregat.toIso8601String(), 'teseles': teseles, 'bytes': bytes};

  final int partidaId;
  final String nom;
  final DateTime descarregat;
  final int teseles;
  final int bytes;
}

/// Lo necesario para decidir si se descarga: la partida ya leída y cuántas teselas son.
class PreparacioPaquet {
  const PreparacioPaquet({required this.partidaId, required this.partida, required this.teseles});

  final int partidaId;
  final Map<String, dynamic> partida;
  final List<Tesela> teseles;

  String get nom => (partida['partida'] as Map<String, dynamic>)['nom'] as String;

  /// Una tesela de ortofoto de huerta pesa unos 25 kB de media.
  int get bytesEstimats => teseles.length * Paquets.bytesPerTesela;
}

/// Paquetes para trabajar sin cobertura en una partida: sus elementos numerados (los del
/// Full de revisió), los recintos SIGPAC y la ortofoto del PNOA de z14 a z19.
///
/// Las teselas se guardan una sola vez («teseles/z/x/y.jpg») aunque dos partidas vecinas
/// las compartan; al borrar un paquete solo se van las que nadie más usa.
class Paquets extends ChangeNotifier {
  Paquets({
    required this.magatzem,
    required this.partida,
    required this.sigpac,
    required this.tesela,
    this.zoomMin = 14,
    this.zoomMax = 19,
    this.espera = const Duration(milliseconds: 400),
  });

  final Magatzem magatzem;

  /// `full_de_camp()` tal cual
  final Future<Map<String, dynamic>> Function(int partidaId) partida;
  final Future<List<RecinteDibuix>> Function(double w, double s, double e, double n) sigpac;
  final Future<Uint8List> Function(Tesela t) tesela;
  final int zoomMin;
  final int zoomMax;

  /// Entre reintentos de una tesela (se dobla en el segundo)
  final Duration espera;

  static const bytesPerTesela = 25000;
  static const _index = 'index.json';
  static const _llista = 'partides.json';

  Map<int, InfoPaquet> _info = {};
  final _progres = <int, double>{};
  late final teseles = TeselesLocals(magatzem);

  InfoPaquet? info(int partidaId) => _info[partidaId];

  /// 0–1 mientras se descarga; null si no.
  double? progres(int partidaId) => _progres[partidaId];

  Future<void> carregar() async {
    final s = await magatzem.llegirText(_index);
    if (s == null) return;
    _info = {
      for (final j in (jsonDecode(s) as List).cast<Map<String, dynamic>>()) j['partida_id'] as int: InfoPaquet.fromJson(j),
    };
    notifyListeners();
  }

  Future<void> _desarIndex() => magatzem.escriureText(_index, jsonEncode([for (final i in _info.values) i.toJson()]));

  /// Lee la partida (hace falta red) y cuenta lo que habría que bajar.
  Future<PreparacioPaquet> preparar(int partidaId) async {
    final p = await partida(partidaId);
    final contorn = (p['partida'] as Map<String, dynamic>)['geometria'] as Map<String, dynamic>;
    return PreparacioPaquet(partidaId: partidaId, partida: p, teseles: teselesDe(contorn, zoomMin, zoomMax));
  }

  /// Descarga (o completa: lo que ya está no se vuelve a bajar). Si fallan teselas, lo
  /// bajado se queda y la excepción dice cuántas faltan: se puede volver a intentar.
  Future<void> descarregar(PreparacioPaquet prep) async {
    final id = prep.partidaId;
    if (_progres.containsKey(id)) return;
    _progres[id] = 0;
    notifyListeners();
    try {
      await magatzem.escriureText('$id/partida.json', jsonEncode(prep.partida));
      final b = _caixa(_anellsExteriors(_contorn(prep.partida)));
      final recintes = await sigpac(b.w, b.s, b.e, b.n);
      await magatzem.escriureText('$id/sigpac.json', jsonEncode([for (final r in recintes) _recinteAJson(r)]));

      var fetes = 0;
      var bytes = 0;
      var errors = 0;
      var seguides = 0; // fallos seguidos: muchos = se ha ido la red, no se insiste
      final pendents = [...prep.teseles];
      Future<void> treballador() async {
        while (pendents.isNotEmpty) {
          final t = pendents.removeLast();
          final ruta = _rutaTesela(t);
          if (!await magatzem.existeix(ruta)) {
            Uint8List? dades;
            for (var intent = 0; intent < 3 && dades == null; intent++) {
              try {
                dades = await tesela(t);
              } catch (_) {
                if (intent < 2) await Future<void>.delayed(espera * (intent + 1));
              }
            }
            if (dades == null) {
              errors++;
              if (++seguides >= 12) {
                errors += pendents.length;
                pendents.clear();
              }
            } else {
              seguides = 0;
              await magatzem.escriure(ruta, dades);
              bytes += dades.length;
            }
          } else {
            bytes += bytesPerTesela; // ya estaba (de una partida vecina o de otro intento)
          }
          fetes++;
          if (fetes % 16 == 0 || pendents.isEmpty) {
            _progres[id] = fetes / prep.teseles.length;
            notifyListeners();
          }
        }
      }

      await Future.wait([for (var i = 0; i < 6; i++) treballador()]);
      if (errors > 0) throw TeselesSenseBaixar(errors);

      _info[id] = InfoPaquet(partidaId: id, nom: prep.nom, descarregat: DateTime.now(), teseles: prep.teseles.length, bytes: bytes);
      await _desarIndex();
    } finally {
      _progres.remove(id);
      notifyListeners();
    }
  }

  Future<void> esborrar(int partidaId) async {
    final p = await _partidaJson(partidaId);
    if (p != null) {
      final altres = <Tesela>{};
      for (final altra in _info.keys.where((k) => k != partidaId)) {
        final q = await _partidaJson(altra);
        if (q != null) altres.addAll(teselesDe(_contorn(q), zoomMin, zoomMax));
      }
      for (final t in teselesDe(_contorn(p), zoomMin, zoomMax)) {
        if (!altres.contains(t)) await magatzem.esborrar(_rutaTesela(t));
      }
    }
    await magatzem.esborrar('$partidaId/partida.json');
    await magatzem.esborrar('$partidaId/sigpac.json');
    _info.remove(partidaId);
    await _desarIndex();
    notifyListeners();
  }

  /// Con red, se refresca la copia del paquete para que sin red se vea lo último.
  Future<void> actualitzarPartida(int partidaId, Map<String, dynamic> p) async {
    if (_info.containsKey(partidaId)) await magatzem.escriureText('$partidaId/partida.json', jsonEncode(p));
  }

  Future<PartidaRevisio?> partidaLocal(int partidaId) async {
    final p = await _partidaJson(partidaId);
    return p == null ? null : PartidaRevisio.fromJson(p);
  }

  Future<List<RecinteDibuix>?> sigpacLocal(int partidaId) async {
    final s = await magatzem.llegirText('$partidaId/sigpac.json');
    if (s == null) return null;
    return [for (final j in (jsonDecode(s) as List).cast<Map<String, dynamic>>()) _recinteDeJson(j)];
  }

  /// La lista de «Les meues partides», para abrirla sin red.
  Future<void> desarLlistaPartides(List<dynamic> files) => magatzem.escriureText(_llista, jsonEncode(files));

  Future<List<PartidaApadrinada>?> llistaPartides() async {
    final s = await magatzem.llegirText(_llista);
    if (s == null) return null;
    return [for (final f in (jsonDecode(s) as List).cast<Map<String, dynamic>>()) PartidaApadrinada.fromJson(f)];
  }

  Future<Map<String, dynamic>?> _partidaJson(int id) async {
    final s = await magatzem.llegirText('$id/partida.json');
    return s == null ? null : jsonDecode(s) as Map<String, dynamic>;
  }
}

class TeselesSenseBaixar implements Exception {
  const TeselesSenseBaixar(this.n);
  final int n;
  @override
  String toString() => 'Falten $n teseles';
}

/// Ortofoto: primero lo descargado, si no, la red.
class TeselesLocals extends TileProvider {
  TeselesLocals(this.magatzem);

  final Magatzem magatzem;
  final _xarxa = NetworkTileProvider(silenceExceptions: true);

  @override
  bool get supportsCancelLoading => true;

  @override
  ImageProvider getImageWithCancelLoadingSupport(TileCoordinates coordinates, TileLayer options, Future<void> cancelLoading) =>
      magatzem.imatge(_rutaTesela((z: coordinates.z, x: coordinates.x, y: coordinates.y))) ??
      _xarxa.getImageWithCancelLoadingSupport(coordinates, options, cancelLoading);

  // Una sola instancia para toda la app: que un mapa al cerrarse no la deje inservible
  @override
  void dispose() {}
}

String _rutaTesela(Tesela t) => 'teseles/${t.z}/${t.x}/${t.y}.jpg';

// ── Geometría de teselas

Map<String, dynamic> _contorn(Map<String, dynamic> p) => (p['partida'] as Map<String, dynamic>)['geometria'] as Map<String, dynamic>;

/// Anillos exteriores en [lon, lat]. Los huecos no se descuentan: sobra poco.
List<List<List<double>>> _anellsExteriors(Map<String, dynamic> g) {
  List<List<double>> anell(List a) => [for (final c in a) [(c[0] as num).toDouble(), (c[1] as num).toDouble()]];
  return switch (g['type']) {
    'Polygon' => [anell((g['coordinates'] as List).first as List)],
    'MultiPolygon' => [for (final p in g['coordinates'] as List) anell((p as List).first as List)],
    _ => const [],
  };
}

({double w, double s, double e, double n}) _caixa(List<List<List<double>>> anells) {
  var w = 180.0, s = 90.0, e = -180.0, n = -90.0;
  for (final a in anells) {
    for (final c in a) {
      w = math.min(w, c[0]);
      e = math.max(e, c[0]);
      s = math.min(s, c[1]);
      n = math.max(n, c[1]);
    }
  }
  return (w: w, s: s, e: e, n: n);
}

double _xDeLon(double lon, int z) => (lon + 180) / 360 * (1 << z);
double _yDeLat(double lat, int z) {
  final r = lat * math.pi / 180;
  return (1 - math.log(math.tan(r) + 1 / math.cos(r)) / math.pi) / 2 * (1 << z);
}

double _lonDeX(double x, int z) => x / (1 << z) * 360 - 180;
double _latDeY(double y, int z) {
  final n = math.pi * (1 - 2 * y / (1 << z));
  return 180 / math.pi * math.atan((math.exp(n) - math.exp(-n)) / 2);
}

bool _dins(List<List<double>> anell, double lon, double lat) {
  var dins = false;
  for (var i = 0, j = anell.length - 1; i < anell.length; j = i++) {
    final a = anell[i], b = anell[j];
    if ((a[1] > lat) != (b[1] > lat) && lon < (b[0] - a[0]) * (lat - a[1]) / (b[1] - a[1]) + a[0]) dins = !dins;
  }
  return dins;
}

/// Teselas que cubren la partida de [zMin] a [zMax]. Se decide en el zoom máximo (la
/// tesela toca la partida, más una de margen alrededor para los elementos del borde) y los
/// zooms menores son sus «padres».
@visibleForTesting
List<Tesela> teselesDe(Map<String, dynamic> contorn, int zMin, int zMax) {
  final anells = _anellsExteriors(contorn);
  if (anells.isEmpty) return const [];
  final b = _caixa(anells);
  final z = zMax;
  final x0 = _xDeLon(b.w, z).floor(), x1 = _xDeLon(b.e, z).floor();
  final y0 = _yDeLat(b.n, z).floor(), y1 = _yDeLat(b.s, z).floor();

  final toca = <(int, int)>{};
  // Teselas con algún vértice del contorno
  for (final a in anells) {
    for (final c in a) {
      toca.add((_xDeLon(c[0], z).floor(), _yDeLat(c[1], z).floor()));
    }
  }
  // Teselas con una esquina o el centro dentro de la partida
  for (var x = x0; x <= x1; x++) {
    for (var y = y0; y <= y1; y++) {
      if (toca.contains((x, y))) continue;
      for (final (dx, dy) in const [(0.0, 0.0), (1.0, 0.0), (0.0, 1.0), (1.0, 1.0), (0.5, 0.5)]) {
        final lon = _lonDeX(x + dx, z), lat = _latDeY(y + dy, z);
        if (anells.any((a) => _dins(a, lon, lat))) {
          toca.add((x, y));
          break;
        }
      }
    }
  }
  // Una de margen
  final ambMarge = <(int, int)>{
    for (final (x, y) in toca)
      for (var dx = -1; dx <= 1; dx++)
        for (var dy = -1; dy <= 1; dy++) (x + dx, y + dy),
  };

  final r = <Tesela>[];
  for (var zz = zMax; zz >= zMin; zz--) {
    final d = zMax - zz;
    r.addAll({for (final (x, y) in ambMarge) (x >> d, y >> d)}.map((t) => (z: zz, x: t.$1, y: t.$2)));
  }
  return r;
}

Map<String, dynamic> _recinteAJson(RecinteDibuix r) => {
      'p': r.parcela,
      'r': r.recinto,
      'a': [
        for (final a in r.anells) [for (final c in a) [c.longitude, c.latitude]],
      ],
    };

RecinteDibuix _recinteDeJson(Map<String, dynamic> j) => RecinteDibuix(
      parcela: j['p'] as int,
      recinto: j['r'] as int,
      anells: [
        for (final a in j['a'] as List)
          [for (final c in a as List) LatLng(((c as List)[1] as num).toDouble(), (c[0] as num).toDouble())],
      ],
    );
