import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../core/config.dart';
import '../core/tema_app.dart';
import '../data/remote/api_observatori.dart';
import '../data/revisio.dart';
import '../l10n/app_localizations.dart';
import '../services/cataleg.dart';
import '../services/paquets.dart';
import '../services/sessio.dart';
import '../services/sincronitzacio.dart';
import 'accio_revisio.dart';
import 'capes_mapa.dart';
import 'fitxa_mapa.dart';
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

  /// Partidas que apadrinas: en sus elementos, la ficha deja revisar
  Set<int> _apadrinades = const {};

  late final Sincronitzacio _sinc;
  late int _reconnexions;

  @override
  void initState() {
    super.initState();
    _sinc = context.read<Sincronitzacio>();
    _reconnexions = _sinc.reconnexions;
    _sinc.addListener(_xarxa);
    _carregarApadrinades();
  }

  /// Al volver la red se recarga lo que se vio sin ella
  void _xarxa() {
    if (_sinc.reconnexions == _reconnexions) return;
    _reconnexions = _sinc.reconnexions;
    _carregarApadrinades();
    _carregarElements();
  }

  Future<void> _carregarApadrinades() async {
    final api = context.read<ApiObservatori>();
    final paquets = context.read<Paquets>();
    Set<int>? ids;
    try {
      ids = {for (final f in (await api.lesMeuesPartidesJson()).cast<Map<String, dynamic>>()) f['id'] as int};
    } catch (_) {
      ids = (await paquets.llistaPartides())?.map((p) => p.id).toSet(); // sin red: la última lista guardada
    }
    if (mounted && ids != null) setState(() => _apadrinades = ids!);
  }

  @override
  void dispose() {
    _sinc.removeListener(_xarxa);
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

  void _obrirFitxa(Map<String, dynamic> prop, LatLng punt) {
    final temes = context.read<Cataleg>().temes;
    final tema = temes.where((x) => x.id == prop['tema_id']).firstOrNull;
    final partidaId = prop['partida_id'] as int?;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => FitxaMapa(
        prop: prop,
        color: colorDesDeHex(tema?.color),
        esPadri: partidaId != null && _apadrinades.contains(partidaId),
        pendent: context.read<Sincronitzacio>().revisions.any((r) => r.elementId == prop['id'] && r.error == null),
        onRevisar: (resultat) async {
          Navigator.of(ctx).pop();
          await enviarRevisio(
            context,
            elementId: prop['id'] as String,
            partidaId: partidaId!,
            resultat: resultat,
            substitut: _substitut(prop, punt),
          );
          _programarCarrega();
        },
        onCanviat: () async {
          Navigator.of(ctx).pop();
          await context.push('/aportar', extra: _substitut(prop, punt));
          _programarCarrega();
        },
        onObrirPartida: partidaId == null
            ? null
            : () {
                Navigator.of(ctx).pop();
                context.push('/partides/$partidaId');
              },
      ),
    );
  }

  AportacioSubstitut _substitut(Map<String, dynamic> prop, LatLng punt) => AportacioSubstitut(
    substitueixId: prop['id'] as String,
    variableId: prop['variable_id'] as int,
    punt: punt,
    nom: prop['variable'] as String?,
  );

  void _obrirPerfil() {
    final t = L.of(context);
    final sessio = context.read<Sessio>();
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(ctx).colorScheme.primaryContainer,
                  foregroundColor: Theme.of(ctx).colorScheme.onPrimaryContainer,
                  child: Text(_inicial(sessio.alies), style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
                title: Text(sessio.alies ?? ''),
                subtitle: Text(sessio.email ?? ''),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: Text(t.perfilLlicencies),
                onTap: () {
                  Navigator.of(ctx).pop();
                  showLicensePage(context: context, applicationName: "L'observatori ciutadà de l'horta");
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: Text(t.mapaEixir),
                onTap: () {
                  Navigator.of(ctx).pop();
                  sessio.eixir();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final sessio = context.watch<Sessio>();
    final temes = context.watch<Cataleg>().temes;
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
          punts.add(
            Marker(
              point: _ll(coord),
              width: 24,
              height: 24,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _obrirFitxa(prop, _ll(coord)),
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
            ),
          );
        case 'LineString':
          linies.add(
            Polyline(points: [for (final c in coord) _ll(c as List)], color: color, strokeWidth: 4, hitValue: prop),
          );
        case 'Polygon':
          poligons.add(_poligon(coord, color, validat, prop));
        case 'MultiPolygon':
          for (final p in coord) {
            poligons.add(_poligon(p as List, color, validat, prop));
          }
      }
    }

    return Scaffold(
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
              capaFons(_fons, locals: context.read<Paquets>().teseles),
              GestureDetector(
                onTap: () {
                  final hit = _toc.value;
                  if (hit != null && hit.hitValues.isNotEmpty) _obrirFitxa(hit.hitValues.first, hit.coordinate);
                },
                child: PolygonLayer<Map<String, dynamic>>(polygons: poligons, hitNotifier: _toc),
              ),
              GestureDetector(
                onTap: () {
                  final hit = _toc.value;
                  if (hit != null && hit.hitValues.isNotEmpty) _obrirFitxa(hit.hitValues.first, hit.coordinate);
                },
                child: PolylineLayer<Map<String, dynamic>>(polylines: linies, hitNotifier: _toc),
              ),
              MarkerLayer(markers: punts),
              if (_posicio != null)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: _posicio!,
                      radius: 8,
                      color: Colors.blueAccent,
                      borderColor: Colors.white,
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),
              SimpleAttributionWidget(source: Text(atribucio(_fons))),
            ],
          ),
          // Barra flotante: marca, capas y perfil
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _Flotant(
                          child: Row(
                            children: [
                              const SizedBox(width: 12),
                              Image.asset('assets/simbol.png', height: 30, semanticLabel: "L'observatori"),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "L'observatori",
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              PopupMenuButton<Fons>(
                                icon: const Icon(Icons.layers_outlined),
                                tooltip: t.mapaFons,
                                initialValue: _fons,
                                onSelected: (f) => setState(() => _fons = f),
                                itemBuilder: (_) => [
                                  for (final f in Fons.values) PopupMenuItem(value: f, child: Text(nomFons(t, f))),
                                ],
                              ),
                              const SizedBox(width: 4),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _Flotant(
                        circular: true,
                        child: IconButton(
                          tooltip: t.perfilTitol,
                          onPressed: _obrirPerfil,
                          icon: Text(
                            _inicial(sessio.alies),
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_massaLluny || _error) ...[
                    const SizedBox(height: 8),
                    _Flotant(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          _error ? t.mapaSenseDades : t.mapaAcosta,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      // Por encima de la atribución del mapa de fondo, que debe leerse
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 28),
        child: Column(
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
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              onPressed: () async {
                await context.push('/aportar');
                _programarCarrega();
              },
              icon: const Icon(Icons.add),
              label: Text(t.mapaAportar),
            ),
          ],
        ),
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

String _inicial(String? alies) => (alies == null || alies.isEmpty) ? '?' : alies.characters.first.toUpperCase();

/// Pastilla con sombra sobre el mapa.
class _Flotant extends StatelessWidget {
  const _Flotant({required this.child, this.circular = false});

  final Widget child;
  final bool circular;

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surface,
    elevation: 4,
    shadowColor: Colors.black45,
    shape: circular ? const CircleBorder() : const StadiumBorder(),
    child: SizedBox(
      height: 52,
      width: circular ? 52 : null,
      child: Center(widthFactor: 1, child: child),
    ),
  );
}
