import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../core/config.dart';
import '../l10n/app_localizations.dart';

enum Fons { topo, pnoa, osm }

String _wmts(String servei, String capa) =>
    'https://www.ign.es/wmts/$servei?service=WMTS&request=GetTile&version=1.0.0&layer=$capa'
    '&style=default&format=image/jpeg&tilematrixset=GoogleMapsCompatible'
    '&tilematrix={z}&tilerow={y}&tilecol={x}';

Widget capaFons(Fons fons) => switch (fons) {
      Fons.topo => TileLayer(
          urlTemplate: _wmts('mapa-raster', 'MTN'),
          userAgentPackageName: Config.paquet,
          maxNativeZoom: 17,
        ),
      Fons.pnoa => TileLayer(
          urlTemplate: _wmts('pnoa-ma', 'OI.OrthoimageCoverage'),
          userAgentPackageName: Config.paquet,
          maxNativeZoom: 19,
        ),
      Fons.osm => TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: Config.paquet,
          maxNativeZoom: 19,
        ),
    };

String atribucio(Fons fons) => switch (fons) {
      Fons.topo => '© Instituto Geográfico Nacional',
      Fons.pnoa => 'PNOA © Instituto Geográfico Nacional',
      Fons.osm => '© OpenStreetMap contributors',
    };

String nomFons(L t, Fons f) => switch (f) {
      Fons.topo => t.fonsTopo,
      Fons.pnoa => t.fonsPnoa,
      Fons.osm => t.fonsOsm,
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
