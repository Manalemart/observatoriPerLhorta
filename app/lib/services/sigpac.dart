import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../data/models.dart';

/// Recinto SIGPAC bajo un punto, en vivo desde el OGC API del FEGA (campaña vigente).
class Sigpac {
  Sigpac({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _ogcapi = 'https://sigpac-hubcloud.es/ogcapi/collections/recintos/items';
  static const _margeGraus = 0.00002; // ~2 m: filtra por caja; el punto exacto se comprueba aquí

  Future<Recinte?> recinteEnPunt(LatLng p) async {
    final bbox = [
      p.longitude - _margeGraus,
      p.latitude - _margeGraus,
      p.longitude + _margeGraus,
      p.latitude + _margeGraus,
    ].join(',');
    final res = await _client.get(Uri.parse('$_ogcapi?f=json&limit=50&bbox=$bbox')).timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) throw Exception('SIGPAC: HTTP ${res.statusCode}');
    return triarRecinte(jsonDecode(res.body) as Map<String, dynamic>, p);
  }
}

/// Público para los tests.
Recinte? triarRecinte(Map<String, dynamic> resposta, LatLng p) {
  for (final f in (resposta['features'] as List).cast<Map<String, dynamic>>()) {
    final g = f['geometry'] as Map<String, dynamic>;
    if (g['type'] != 'Polygon' || !_dinsPoligon(p, g['coordinates'] as List)) continue;
    final q = f['properties'] as Map<String, dynamic>;
    return Recinte(ref: _referencia(q), dnPk: q['dn_pk'] as int, geometria: g);
  }
  return null;
}

String _z(Object? n, int ample) => n.toString().padLeft(ample, '0');

// Formato oficial: provincia:municipio:agregado:zona:poligono:parcela:recinto
String _referencia(Map<String, dynamic> q) => [
      _z(q['provincia'], 2),
      _z(q['municipio'], 3),
      q['agregado'],
      q['zona'],
      _z(q['poligono'], 3),
      _z(q['parcela'], 5),
      _z(q['recinto'], 4),
    ].join(':');

bool _dinsAnell(LatLng p, List anell) {
  var dins = false;
  for (var i = 0, j = anell.length - 1; i < anell.length; j = i++) {
    final a = anell[i] as List;
    final b = anell[j] as List;
    final xi = (a[0] as num).toDouble(), yi = (a[1] as num).toDouble();
    final xj = (b[0] as num).toDouble(), yj = (b[1] as num).toDouble();
    if ((yi > p.latitude) != (yj > p.latitude) &&
        p.longitude < (xj - xi) * (p.latitude - yi) / (yj - yi) + xi) {
      dins = !dins;
    }
  }
  return dins;
}

bool _dinsPoligon(LatLng p, List anells) =>
    _dinsAnell(p, anells.first as List) && !anells.skip(1).any((f) => _dinsAnell(p, f as List));
