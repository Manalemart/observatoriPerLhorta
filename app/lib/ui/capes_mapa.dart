import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../core/config.dart';
import '../l10n/app_localizations.dart';
import '../services/paquets.dart';

// Sin OpenStreetMap: sus servidores públicos no admiten el tráfico de una app en producción
enum Fons { pnoa, topo }

String _wmts(String servei, String capa) =>
    'https://www.ign.es/wmts/$servei?service=WMTS&request=GetTile&version=1.0.0&layer=$capa'
    '&style=default&format=image/jpeg&tilematrixset=GoogleMapsCompatible'
    '&tilematrix={z}&tilerow={y}&tilecol={x}';

String urlTesela(Fons fons) => switch (fons) {
      Fons.topo => _wmts('mapa-raster', 'MTN'),
      Fons.pnoa => _wmts('pnoa-ma', 'OI.OrthoimageCoverage'),
    };

/// [locals]: la ortofoto descargada para el campo (Paquets.teseles); lo que falte, de la red.
Widget capaFons(Fons fons, {TileProvider? locals}) => switch (fons) {
      Fons.topo => TileLayer(
          urlTemplate: _wmts('mapa-raster', 'MTN'),
          userAgentPackageName: Config.paquet,
          maxNativeZoom: 17,
        ),
      Fons.pnoa => TileLayer(
          urlTemplate: _wmts('pnoa-ma', 'OI.OrthoimageCoverage'),
          userAgentPackageName: Config.paquet,
          tileProvider: locals,
          maxNativeZoom: 19,
        ),
    };

String atribucio(Fons fons) => switch (fons) {
      Fons.topo => '© Instituto Geográfico Nacional',
      Fons.pnoa => 'PNOA © Instituto Geográfico Nacional',
    };

String nomFons(L t, Fons f) => switch (f) {
      Fons.topo => t.fonsTopo,
      Fons.pnoa => t.fonsPnoa,
    };

/// Posición actual, pidiendo permiso si hace falta. Null si no se puede obtener.
Future<LatLng?> posicioActual() async {
  try {
    var permis = await Geolocator.checkPermission();
    if (permis == LocationPermission.denied) permis = await Geolocator.requestPermission();
    if (permis == LocationPermission.denied || permis == LocationPermission.deniedForever) return null;
    final p = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 20)),
    );
    return LatLng(p.latitude, p.longitude);
  } catch (_) {
    return null;
  }
}

/// Una tesela de ortofoto para el paquete sin conexión.
Future<Uint8List> baixarTesela(http.Client client, Tesela t) async {
  final url = urlTesela(Fons.pnoa).replaceAll('{z}', '${t.z}').replaceAll('{x}', '${t.x}').replaceAll('{y}', '${t.y}');
  final r = await client.get(Uri.parse(url), headers: {'User-Agent': Config.paquet}).timeout(const Duration(seconds: 30));
  if (r.statusCode != 200 || !(r.headers['content-type'] ?? '').startsWith('image/')) {
    throw Exception('Tesela ${t.z}/${t.x}/${t.y}: HTTP ${r.statusCode}');
  }
  return r.bodyBytes;
}
