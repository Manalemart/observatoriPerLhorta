import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../core/config.dart';
import '../core/tema_app.dart';
import '../data/models.dart' show Lloc;
import '../data/remote/api_observatori.dart';
import '../data/revisio.dart';
import '../l10n/app_localizations.dart';
import '../services/cataleg.dart';
import '../services/paquets.dart';
import '../services/sessio.dart';
import '../services/simbologia.dart';
import '../services/sincronitzacio.dart';
import 'accio_revisio.dart';
import 'adaptatiu.dart';
import 'aportar_screen.dart' show VistaMapa;
import 'capa_punts.dart';
import 'cercador.dart';
import 'capa_simbologia.dart';
import 'capes_mapa.dart';
import 'fitxa_mapa.dart';
import 'entrada_screen.dart';
import 'filtres_mapa.dart';
import 'guia.dart';
import 'esborrar_compte.dart';
import 'les_meues_dades.dart';
import 'llegenda.dart';

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
  FiltresMapa _filtres = const FiltresMapa();
  bool _guiaComprovada = false;

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
    FiltresMapa.carregar().then((f) {
      if (mounted) setState(() => _filtres = f);
    });
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

  /// La guia de benvinguda, la primera vegada (després de l'àlies).
  Future<void> _guiaSiCal() async {
    _guiaComprovada = true;
    if (await guiaVista() || !mounted) return;
    await mostrarGuia(context);
  }

  /// Busca un municipi o una partida i hi porta el mapa.
  Future<void> _cercar() async {
    final t = L.of(context);
    final api = context.read<ApiObservatori>();
    final lloc = await showSearch<Lloc?>(
      context: context,
      delegate: CercadorLlocs(cercar: api.cercarLlocs, etiqueta: t.cercadorEtiqueta),
    );
    if (lloc == null || !mounted) return;
    _mapa.fitCamera(CameraFit.bounds(
      bounds: LatLngBounds(LatLng(lloc.sud, lloc.oest), LatLng(lloc.nord, lloc.est)),
      padding: const EdgeInsets.fromLTRB(32, 140, 32, 120),
      maxZoom: 17,
    ));
  }

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
                leading: const Icon(Icons.edit_outlined),
                title: Text(t.aliesCanviarTitol),
                onTap: () {
                  Navigator.of(ctx).pop();
                  canviarAlies(context, sessio.alies);
                },
              ),
              Builder(
                // El seu context fa d'origen del full de compartir en iPad
                builder: (fila) => ListTile(
                  leading: const Icon(Icons.download_outlined),
                  title: Text(t.dadesBoto),
                  onTap: () async {
                    await compartirLesMeuesDades(fila);
                    if (ctx.mounted) Navigator.of(ctx).pop();
                  },
                ),
              ),
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: Text(t.guiaPerfil),
                onTap: () {
                  Navigator.of(ctx).pop();
                  mostrarGuia(context);
                },
              ),
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
              ListTile(
                leading: Icon(Icons.delete_forever_outlined, color: Theme.of(ctx).colorScheme.error),
                title: Text(t.compteEsborrarTitol, style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  obrirEsborrarCompte(context);
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
    final simbologia = context.read<Simbologia>();
    final colorTema = {for (final x in temes) x.id: x.color};

    if (sessio.necessitaAlies && !_dialegAlies) {
      _dialegAlies = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await demanarAlies(context);
        _dialegAlies = false;
        if (mounted) _guiaSiCal();
      });
    } else if (!sessio.necessitaAlies && sessio.entrada && !_guiaComprovada) {
      _guiaComprovada = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _guiaSiCal());
    }

    final poligons = <Polygon<Map<String, dynamic>>>[];
    final linies = <Polyline<Map<String, dynamic>>>[];
    final punts = <PuntMapa>[];
    final trames = <ParcelaAmbTrama>[];
    final glifs = <LiniaAmbGlif>[];
    for (final f in _elements) {
      final geo = f['geometry'] as Map<String, dynamic>;
      final prop = f['properties'] as Map<String, dynamic>;
      final validat = prop['estat'] == 'validat';
      final perRevisar = prop['per_revisar'] == true;
      if (!_filtres.mostra(prop['tema_id'] as int?, perRevisar)) continue;
      final coord = geo['coordinates'] as List;
      // Símbol de la guia de disseny segons la variable i la categoria (docs/simbologia)
      final simbol = simbologia.simbol(
        geometria: geo['type'] as String,
        variable: prop['variable'] as String?,
        categoria: prop['categoria'] as String?,
        tema: prop['tema'] as String?,
        colorTema: colorTema[prop['tema_id']],
      );
      switch ((geo['type'], simbol)) {
        case ('Point', final SimbolPunt s):
          punts.add(PuntMapa(
            punt: _ll(coord),
            clau: '${prop['variable']}|${prop['categoria']}',
            simbol: s,
            prop: prop,
            validat: validat,
            perRevisar: perRevisar,
          ));
        case ('LineString', final SimbolLinia s):
          final llista = [for (final c in coord) _ll(c as List)];
          linies.add(_linia(llista, s, prop));
          if (s.glif != null) glifs.add(LiniaAmbGlif(llista, s));
        case ('Polygon' || 'MultiPolygon', final SimbolParcela s):
          final opacitat = !validat ? 0.3 : (perRevisar ? 0.5 : 0.75);
          for (final p in geo['type'] == 'Polygon' ? [coord] : coord) {
            final anells = [
              for (final anell in p as List) [for (final c in anell as List) _ll(c as List)],
            ];
            poligons.add(_poligon(anells, s, opacitat, validat: validat, perRevisar: perRevisar, prop: prop));
            if (s.trama != null) trames.add(ParcelaAmbTrama(anells, s.trama!, opacitat));
          }
        default:
          break;
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
              CapaSimbologia(parceles: trames),
              GestureDetector(
                onTap: () {
                  final hit = _toc.value;
                  if (hit != null && hit.hitValues.isNotEmpty) _obrirFitxa(hit.hitValues.first, hit.coordinate);
                },
                child: PolylineLayer<Map<String, dynamic>>(polylines: linies, hitNotifier: _toc),
              ),
              CapaSimbologia(linies: glifs),
              CapaPunts(punts: punts, obrir: (p) => _obrirFitxa(p.prop, p.punt)),
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
            child: Flotant(
              maxim: ampladaFlotant + 24,
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
                              IconButton(
                                icon: const Icon(Icons.search),
                                tooltip: t.cercadorTitol,
                                onPressed: _cercar,
                              ),
                              IconButton(
                                icon: Badge(
                                  isLabelVisible: _filtres.actius,
                                  smallSize: 9,
                                  child: Icon(_filtres.actius ? Icons.filter_alt : Icons.filter_alt_outlined),
                                ),
                                tooltip: t.filtresTitol,
                                onPressed: () => mostrarFiltres(
                                  context,
                                  temes: temes,
                                  inicial: _filtres,
                                  onCanvi: (f) {
                                    setState(() => _filtres = f);
                                    f.desar();
                                  },
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.format_list_bulleted),
                                tooltip: t.llegendaTitol,
                                onPressed: () => mostrarLlegenda(context),
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
          )),
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
                await context.push('/aportar', extra: VistaMapa(_mapa.camera.center, _mapa.camera.zoom));
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

  /// Parcel·la: el color de la guia (una mica transparent per a veure l'ortofoto), el contorn
  /// de la guia; lo no validat amb contorn negre i lo de 2018 sense revisar, discontinu.
  Polygon<Map<String, dynamic>> _poligon(
    List<List<LatLng>> anells,
    SimbolParcela s,
    double opacitat, {
    required bool validat,
    required bool perRevisar,
    required Map<String, dynamic> prop,
  }) =>
      Polygon(
        points: anells.first,
        holePointsList: anells.skip(1).toList(),
        color: s.color.withValues(alpha: opacitat),
        borderColor: validat ? s.contorn : Colors.black,
        borderStrokeWidth: perRevisar ? 1.5 : 1,
        pattern: perRevisar ? StrokePattern.dashed(segments: const [6, 4]) : const StrokePattern.solid(),
        hitValue: prop,
      );

  /// Línia: traç de la guia. Les que només són glif (paret, tanca mixta, tanca vegetal) es
  /// dibuixen en CapaSimbologia: ací queda un traç transparent per a poder tocar-les.
  Polyline<Map<String, dynamic>> _linia(List<LatLng> punts, SimbolLinia s, Map<String, dynamic> prop) {
    final nomesGlif = s.glif != null && glifsTrama.contains(s.glif);
    if (nomesGlif) return Polyline(points: punts, color: Colors.transparent, strokeWidth: 8, hitValue: prop);
    if (s.patro == 'doble') {
      // Camí: dos traços paral·lels (la vora) amb el centre clar
      return Polyline(
        points: punts,
        color: Colors.white.withValues(alpha: 0.85),
        strokeWidth: 2.5,
        borderColor: s.color,
        borderStrokeWidth: 1.2,
        hitValue: prop,
      );
    }
    return Polyline(
      points: punts,
      color: s.color,
      strokeWidth: s.amplada + 0.5,
      pattern: switch (s.patro) {
        'discontinua' => StrokePattern.dashed(segments: const [6, 4]),
        'puntejada' => const StrokePattern.dotted(spacingFactor: 2),
        'punt_ratlla' => StrokePattern.dashed(segments: const [8, 3, 1.5, 3]),
        _ => const StrokePattern.solid(),
      },
      hitValue: prop,
    );
  }
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
