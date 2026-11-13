import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../core/config.dart';
import '../core/tema_app.dart';
import '../data/remote/api_observatori.dart';
import '../l10n/app_localizations.dart';
import '../services/cataleg.dart';
import '../services/sessio.dart';
import '../services/sincronitzacio.dart';
import 'capes_mapa.dart';
import 'entrada_screen.dart';

const _esperaMoviment = Duration(milliseconds: 400);

class MapaScreen extends StatefulWidget {
  const MapaScreen({super.key});

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  final _mapa = MapController();
  final _toc = LayerHitNotifier<Map<String, dynamic>>(null);
  Timer? _espera;
  Fons _fons = Fons.pnoa; // por defecto, la ortofoto
  List<Map<String, dynamic>> _elements = const [];
  bool _massaLluny = true;
  bool _error = false;
  LatLng? _posicio;
  bool _dialegAlies = false;

  @override
  void dispose() {
    _espera?.cancel();
    _toc.dispose();
    super.dispose();
  }

  void _programarCarrega() {
    _espera?.cancel();
    _espera = Timer(_esperaMoviment, _carregarElements);
  }

  Future<void> _carregarElements() async {
    if (!mounted) return;
    final cam = _mapa.camera;
    if (cam.zoom < Config.zoomMinimElements) {
      setState(() {
        _massaLluny = true;
        _elements = const [];
      });
      return;
    }
    final b = cam.visibleBounds;
    try {
      final elements = await context.read<ApiObservatori>().elementsBbox(b.west, b.south, b.east, b.north);
      if (mounted) {
        setState(() {
          _massaLluny = false;
          _error = false;
          _elements = elements;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _error = true); // sin red: se mantiene lo último que se vio
    }
  }

  Future<void> _anarAPosicio() async {
    final t = L.of(context);
    final avis = ScaffoldMessenger.of(context);
    final p = await posicioActual();
    if (!mounted) return;
    if (p == null) {
      avis.showSnackBar(SnackBar(content: Text(t.gpsNoDisponible)));
      return;
    }
    setState(() => _posicio = p);
    _mapa.move(p, 16);
  }

  void _obrirFitxa(Map<String, dynamic> prop) {
    final t = L.of(context);
    final estat = switch (prop['estat']) {
      'validat' => t.estatValidat,
      'rebutjat' => t.estatRebutjat,
      _ => t.estatPendent,
    };
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          title: Text(prop['variable'] as String),
          subtitle: Text([prop['tema'], prop['categoria'], '${t.fitxaEstat}: $estat'].whereType<String>().join('\n')),
          isThreeLine: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final sessio = context.watch<Sessio>();
    final temes = context.watch<Cataleg>().temes;
    final pendents = context.watch<Sincronitzacio>().pendents;
    final colors = {for (final x in temes) x.id: colorDesDeHex(x.color)};

    if (sessio.necessitaAlies && !_dialegAlies) {
      _dialegAlies = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await demanarAlies(context);
        _dialegAlies = false;
      });
    }

    final poligons = <Polygon<Map<String, dynamic>>>[];
    final linies = <Polyline<Map<String, dynamic>>>[];
    final punts = <Marker>[];
    for (final f in _elements) {
      final geo = f['geometry'] as Map<String, dynamic>;
      final prop = f['properties'] as Map<String, dynamic>;
      final color = colors[prop['tema_id']] ?? Colors.grey;
      final validat = prop['estat'] == 'validat';
      final coord = geo['coordinates'] as List;
      switch (geo['type']) {
        case 'Point':
          punts.add(Marker(
            point: _ll(coord),
            width: 24,
            height: 24,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _obrirFitxa(prop),
              child: Center(
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: validat ? Colors.white : Colors.black, width: 2),
                  ),
                ),
              ),
            ),
          ));
        case 'LineString':
          linies.add(Polyline(points: [for (final c in coord) _ll(c as List)], color: color, strokeWidth: 4, hitValue: prop));
        case 'Polygon':
          poligons.add(_poligon(coord, color, validat, prop));
        case 'MultiPolygon':
          for (final p in coord) {
            poligons.add(_poligon(p as List, color, validat, prop));
          }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Observatori'),
        actions: [
          PopupMenuButton<Fons>(
            icon: const Icon(Icons.layers_outlined),
            tooltip: t.mapaFons,
            initialValue: _fons,
            onSelected: (f) => setState(() => _fons = f),
            itemBuilder: (_) => [for (final f in Fons.values) PopupMenuItem(value: f, child: Text(nomFons(t, f)))],
          ),
          IconButton(
            tooltip: t.partidesTitol,
            onPressed: () => context.push('/partides'),
            icon: const Icon(Icons.fact_check_outlined),
          ),
          IconButton(
            tooltip: t.mapaAportacions,
            onPressed: () => context.push('/aportacions'),
            icon: Badge(
              isLabelVisible: pendents > 0,
              label: Text('$pendents'),
              child: const Icon(Icons.list_alt),
            ),
          ),
          IconButton(tooltip: t.mapaEixir, onPressed: sessio.eixir, icon: const Icon(Icons.logout)),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapa,
            options: MapOptions(
              initialCenter: Config.centreInicial,
              initialZoom: Config.zoomInicial,
              onMapReady: _programarCarrega,
              onPositionChanged: (_, _) => _programarCarrega(),
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
            ),
            children: [
              capaFons(_fons),
              GestureDetector(
                onTap: () {
                  final hit = _toc.value;
                  if (hit != null && hit.hitValues.isNotEmpty) _obrirFitxa(hit.hitValues.first);
                },
                child: PolygonLayer<Map<String, dynamic>>(polygons: poligons, hitNotifier: _toc),
              ),
              GestureDetector(
                onTap: () {
                  final hit = _toc.value;
                  if (hit != null && hit.hitValues.isNotEmpty) _obrirFitxa(hit.hitValues.first);
                },
                child: PolylineLayer<Map<String, dynamic>>(polylines: linies, hitNotifier: _toc),
              ),
              MarkerLayer(markers: punts),
              if (_posicio != null)
                CircleLayer(circles: [
                  CircleMarker(
                    point: _posicio!,
                    radius: 8,
                    color: Colors.blueAccent,
                    borderColor: Colors.white,
                    borderStrokeWidth: 2,
                  ),
                ]),
              SimpleAttributionWidget(source: Text(atribucio(_fons))),
            ],
          ),
          if (_massaLluny || _error)
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: Center(
                child: Material(
                  color: Theme.of(context).colorScheme.surface,
                  elevation: 2,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Text(_error ? t.mapaSenseDades : t.mapaAcosta),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'posicio',
            tooltip: t.mapaLaMeuaPosicio,
            onPressed: _anarAPosicio,
            child: const Icon(Icons.my_location),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'aportar',
            onPressed: () async {
              await context.push('/aportar');
              _programarCarrega();
            },
            icon: const Icon(Icons.add),
            label: Text(t.mapaAportar),
          ),
        ],
      ),
    );
  }

  Polygon<Map<String, dynamic>> _poligon(List anells, Color color, bool validat, Map<String, dynamic> prop) => Polygon(
        points: [for (final c in anells.first as List) _ll(c as List)],
        holePointsList: [
          for (final forat in anells.skip(1)) [for (final c in forat as List) _ll(c as List)],
        ],
        color: color.withValues(alpha: validat ? 0.4 : 0.2),
        borderColor: validat ? color : Colors.black,
        borderStrokeWidth: 1.5,
        hitValue: prop,
      );
}

LatLng _ll(List c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble());
