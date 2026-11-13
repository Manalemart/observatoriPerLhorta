import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../core/tema_app.dart';
import '../data/models.dart';
import '../data/remote/api_observatori.dart';
import '../data/revisio.dart';
import '../l10n/app_localizations.dart';
import '../services/paquets.dart';
import '../services/sigpac.dart';
import '../services/sincronitzacio.dart';
import 'capes_mapa.dart';

const _verd = Color(0xFF215C00);
const _verdIgual = Color(0xFF2C7A00);
const _ambre = Color(0xFFB36A00);
const _blauNou = Color(0xFF51606F);
const _groguSigpac = Color(0xFFFFD400);
const _ocreSigpac = Color(0xFFB86E00);

/// Revisión de una partida en el campo: el plano con los mismos números que el Full de
/// revisió y, en cada elemento, «Igual / Ha canviat / No el trobe». Sin cobertura funciona
/// con el paquete descargado (Paquets) y las revisiones esperan en la cola del móvil.
class RevisioScreen extends StatefulWidget {
  const RevisioScreen({super.key, required this.partidaId});

  final int partidaId;

  @override
  State<RevisioScreen> createState() => _RevisioScreenState();
}

class _RevisioScreenState extends State<RevisioScreen> {
  final _mapa = MapController();
  PartidaRevisio? _p;
  Object? _error;
  List<RecinteDibuix>? _sigpac;
  bool _errorSigpac = false;
  Fons _fons = Fons.pnoa;
  bool _nomesPerRevisar = false;
  LatLng? _posicio;

  /// Si no hay red y se trabaja con el paquete: cuándo se descargó.
  DateTime? _dadesDe;

  @override
  void initState() {
    super.initState();
    _carregar(primera: true);
  }

  Future<void> _carregar({bool primera = false}) async {
    final paquets = context.read<Paquets>();
    PartidaRevisio p;
    DateTime? dadesDe;
    try {
      final j = await context.read<ApiObservatori>().fullDeCamp(widget.partidaId);
      await paquets.actualitzarPartida(widget.partidaId, j);
      p = PartidaRevisio.fromJson(j);
    } catch (e) {
      final local = await paquets.partidaLocal(widget.partidaId);
      if (local == null) {
        if (mounted) setState(() => _error = e);
        return;
      }
      p = local;
      dadesDe = paquets.info(widget.partidaId)?.descarregat;
    }
    if (!mounted) return;
    setState(() {
      _p = p;
      _dadesDe = dadesDe;
      _error = null;
    });
    if (primera) _carregarSigpac(p);
  }

  Future<void> _carregarSigpac(PartidaRevisio p) async {
    final local = await context.read<Paquets>().sigpacLocal(widget.partidaId);
    if (local != null) {
      if (mounted) setState(() => _sigpac = local);
      return;
    }
    if (!mounted) return;
    final b = LatLngBounds.fromPoints(_punts(p.contorn));
    try {
      final r = await context.read<Sigpac>().recintesEnCaixa(b.west, b.south, b.east, b.north);
      if (mounted) setState(() => _sigpac = r);
    } catch (_) {
      if (mounted) setState(() => _errorSigpac = true);
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
    _mapa.move(p, 18);
  }

  /// El elemento sin revisar más cercano a donde se está (o al centro del mapa).
  /// La partida tal como se ve: con lo revisado aquí que aún no ha llegado al servidor.
  PartidaRevisio? get _vista {
    final p = _p;
    if (p == null) return null;
    final sinc = context.read<Sincronitzacio>();
    return p.ambRevisionsLocals(sinc.revisions.where((r) => r.partidaId == widget.partidaId && r.error == null));
  }

  void _elMesProper() {
    final p = _vista;
    if (p == null) return;
    final des = _posicio ?? _mapa.camera.center;
    const d = Distance();
    ElementRevisio? millor;
    double? min;
    for (final e in p.revisables.where((e) => e.estatRevisio == EstatRevisio.perRevisar)) {
      final x = d.as(LengthUnit.Meter, des, e.etiqueta);
      if (min == null || x < min) {
        min = x;
        millor = e;
      }
    }
    if (millor == null) return;
    _mapa.move(millor.etiqueta, 18.5);
    _obrirFitxa(millor);
  }

  Future<void> _revisar(ElementRevisio e, String resultat, String nota) async {
    final t = L.of(context);
    final avis = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final sinc = context.read<Sincronitzacio>();
    // Primero al móvil: en el campo puede no haber cobertura. Se envía en cuanto la haya
    final r = RevisioLocal(
      id: const Uuid().v4(),
      elementId: e.id,
      partidaId: widget.partidaId,
      resultat: resultat,
      creadaEn: DateTime.now(),
      nota: nota.trim().isEmpty ? null : nota.trim(),
    );
    try {
      await sinc.revisar(r);
    } catch (_) {
      avis.showSnackBar(SnackBar(content: Text(t.revisioError)));
      return;
    }
    final queda = sinc.revisions.where((x) => x.id == r.id).firstOrNull;
    if (queda?.error != null) {
      // El servidor la ha rechazado (p. ej. ya no es padrí): no tiene sentido guardarla
      await sinc.esborrarRevisio(r.id);
      avis.showSnackBar(SnackBar(content: Text(t.revisioRebutjada(queda!.error!))));
      return;
    }
    avis.showSnackBar(SnackBar(content: Text(queda == null ? t.revisioFet : t.revisioGuardadaMobil)));
    if (resultat == 'canviat') {
      await router.push('/aportar', extra: AportacioSubstitut(
        substitueixId: e.id, numero: e.numero, variableId: e.variableId, punt: e.etiqueta,
      ));
    }
    await _carregar();
  }

  void _obrirFitxa(ElementRevisio e) {
    final p = _p!;
    final pendent = context.read<Sincronitzacio>().revisions.any((r) => r.elementId == e.id && r.error == null);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => _FitxaRevisio(
        element: e,
        pendent: pendent,
        potRevisar: p.esPadri && e.revisable && !pendent,
        onResultat: (resultat, nota) async {
          Navigator.of(ctx).pop();
          await _revisar(e, resultat, nota);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    context.watch<Sincronitzacio>(); // lo revisado aquí cambia el plano
    final p = _vista;
    if (p == null) {
      return Scaffold(
        appBar: AppBar(title: Text(t.revisioTitol)),
        body: Center(
          child: _error == null
              ? const CircularProgressIndicator()
              : Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(t.revisioErrorCarrega),
                  const SizedBox(height: 12),
                  FilledButton.tonal(onPressed: () => _carregar(primera: true), child: Text(t.comuTornarAProvar)),
                ]),
        ),
      );
    }

    final contorn = _anells(p.contorn);
    final total = p.revisables.length;
    final fets = p.revisats;
    final visibles = p.elements.where((e) => !_nomesPerRevisar || e.estatRevisio == EstatRevisio.perRevisar).toList();
    final orto = _fons == Fons.pnoa;

    final poligons = <Polygon>[];
    final linies = <Polyline>[];
    for (final e in visibles) {
      final color = colorDesDeHex(e.color);
      final patro = e.estatRevisio == EstatRevisio.perRevisar
          ? StrokePattern.dashed(segments: const [10, 6])
          : const StrokePattern.solid();
      final g = e.geometria;
      if (g['type'] == 'Polygon' || g['type'] == 'MultiPolygon') {
        for (final anells in g['type'] == 'Polygon' ? [g['coordinates'] as List] : (g['coordinates'] as List)) {
          final a = _llistaAnells(anells as List);
          poligons.add(Polygon(
            points: a.first,
            holePointsList: a.skip(1).toList(),
            color: color.withValues(alpha: 0.16),
            borderColor: color,
            borderStrokeWidth: 2.2,
            pattern: patro,
          ));
        }
      } else if (g['type'] == 'LineString') {
        linies.add(Polyline(points: [for (final c in g['coordinates'] as List) _ll(c as List)], color: color, strokeWidth: 4, pattern: patro));
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(p.nom),
          Text(t.revisioProgres(fets, total), style: Theme.of(context).textTheme.bodySmall),
        ]),
        actions: [
          IconButton(
            tooltip: t.revisioNomesPerRevisar,
            isSelected: _nomesPerRevisar,
            onPressed: () => setState(() => _nomesPerRevisar = !_nomesPerRevisar),
            icon: const Icon(Icons.filter_alt_outlined),
            selectedIcon: const Icon(Icons.filter_alt),
          ),
          PopupMenuButton<Fons>(
            icon: const Icon(Icons.layers_outlined),
            tooltip: t.mapaFons,
            initialValue: _fons,
            onSelected: (f) => setState(() => _fons = f),
            itemBuilder: (_) => [for (final f in Fons.values) PopupMenuItem(value: f, child: Text(nomFons(t, f)))],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(value: total == 0 ? 1 : fets / total, color: _verdIgual),
        ),
      ),
      body: Stack(children: [
        FlutterMap(
          mapController: _mapa,
          options: MapOptions(
            initialCameraFit: CameraFit.bounds(bounds: LatLngBounds.fromPoints(contorn.expand((a) => a).toList()), padding: const EdgeInsets.all(24)),
            interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
          ),
          children: [
            capaFons(_fons, locals: context.read<Paquets>().teseles),
            if (_sigpac != null)
              PolygonLayer(polygons: [
                for (final r in _sigpac!)
                  Polygon(
                    points: r.anells.first,
                    holePointsList: r.anells.skip(1).toList(),
                    color: Colors.transparent,
                    borderColor: orto ? _groguSigpac : _ocreSigpac,
                    borderStrokeWidth: 1.2,
                  ),
              ]),
            PolygonLayer(polygons: poligons),
            PolylineLayer(polylines: linies),
            // Contorno de la partida: blanco debajo para que se vea sobre la ortofoto
            PolylineLayer(polylines: [
              for (final a in contorn) Polyline(points: a, color: Colors.white, strokeWidth: 6),
              for (final a in contorn) Polyline(points: a, color: _verd, strokeWidth: 3),
            ]),
            MarkerLayer(markers: [
              for (final e in visibles)
                Marker(
                  point: e.etiqueta,
                  width: 34,
                  height: 34,
                  child: Semantics(
                    button: true,
                    label: t.revisioNumero(e.numero, e.quadre),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _obrirFitxa(e),
                      child: Center(child: _NumeroElement(element: e)),
                    ),
                  ),
                ),
            ]),
            if (_posicio != null)
              CircleLayer(circles: [
                CircleMarker(point: _posicio!, radius: 8, color: Colors.blueAccent, borderColor: Colors.white, borderStrokeWidth: 2),
              ]),
            SimpleAttributionWidget(source: Text('${atribucio(_fons)}${_sigpac != null ? ' · SIGPAC © FEGA' : ''}')),
          ],
        ),
        if (_dadesDe != null)
          Positioned(
            top: 8, left: 8, right: 8,
            child: Center(
              child: Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.cloud_off, size: 16),
                    const SizedBox(width: 6),
                    Text(t.revisioSenseXarxa(DateFormat('d/M/yyyy', 'ca').format(_dadesDe!))),
                  ]),
                ),
              ),
            ),
          ),
        if (_errorSigpac)
          Positioned(
            top: 8, left: 8, right: 8,
            child: Center(
              child: Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(16),
                child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), child: Text(t.revisioSenseSigpac)),
              ),
            ),
          ),
      ]),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.small(heroTag: 'posicio', tooltip: t.mapaLaMeuaPosicio, onPressed: _anarAPosicio, child: const Icon(Icons.my_location)),
          const SizedBox(height: 12),
          if (fets < total) ...[
            FloatingActionButton.small(heroTag: 'proper', tooltip: t.revisioElMesProper, onPressed: _elMesProper, child: const Icon(Icons.near_me)),
            const SizedBox(height: 12),
          ],
          FloatingActionButton.extended(
            heroTag: 'aportar',
            onPressed: () async {
              await context.push('/aportar');
              await _carregar();
            },
            icon: const Icon(Icons.add),
            label: Text(t.mapaAportar),
          ),
        ],
      ),
    );
  }
}

/// El número del elemento, con un aro del color de su estado de revisión.
class _NumeroElement extends StatelessWidget {
  const _NumeroElement({required this.element});

  final ElementRevisio element;

  @override
  Widget build(BuildContext context) {
    final e = element;
    final (vora, fons, text) = switch (e.estatRevisio) {
      EstatRevisio.perRevisar => (colorDesDeHex(e.color), Colors.white, const Color(0xFF3B352F)),
      EstatRevisio.igual => (_verdIgual, _verdIgual, Colors.white),
      EstatRevisio.canviat => (_ambre, _ambre, Colors.white),
      EstatRevisio.nou => (_blauNou, Colors.white, _blauNou),
    };
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fons,
        shape: BoxShape.circle,
        border: Border.all(color: vora, width: 3),
        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 3)],
      ),
      child: Text('${e.numero}', style: TextStyle(color: text, fontWeight: FontWeight.w800, fontSize: e.numero >= 100 ? 10 : 12)),
    );
  }
}

class _FitxaRevisio extends StatefulWidget {
  const _FitxaRevisio({required this.element, required this.pendent, required this.potRevisar, required this.onResultat});

  final ElementRevisio element;
  final bool pendent;
  final bool potRevisar;
  final Future<void> Function(String resultat, String nota) onResultat;

  @override
  State<_FitxaRevisio> createState() => _FitxaRevisioState();
}

class _FitxaRevisioState extends State<_FitxaRevisio> {
  final _nota = TextEditingController();
  bool _enviant = false;

  @override
  void dispose() {
    _nota.dispose();
    super.dispose();
  }

  Future<void> _fer(String resultat) async {
    if (resultat == 'no_trobat') {
      final t = L.of(context);
      final segur = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          content: Text(t.revisioConfirmarNoTrobat),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: Text(t.comuCancelar)),
            FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(t.revisioNoTrobat)),
          ],
        ),
      );
      if (segur != true) return;
    }
    setState(() => _enviant = true);
    await widget.onResultat(resultat, _nota.text);
  }

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final e = widget.element;
    final estat = switch (e.estatRevisio) {
      EstatRevisio.perRevisar => t.revisioEstatPerRevisar,
      EstatRevisio.igual => t.revisioEstatIgual,
      EstatRevisio.canviat => t.revisioEstatCanviat,
      EstatRevisio.nou => t.revisioEstatNou,
    };
    final detall = [if (e.categoria != null && e.categoria != 'Sense categoria') e.categoria!, e.tema].join(' · ');
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.revisioNumero(e.numero, e.quadre), style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          Text(e.variable, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          Text(detall),
          const SizedBox(height: 8),
          Text(widget.pendent ? '$estat · ${t.revisioPendentEnviar}' : estat, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          if (!widget.potRevisar)
            Text(e.revisable ? t.revisioNomesPadri : t.revisioNoRevisable)
          else ...[
            TextField(
              controller: _nota,
              enabled: !_enviant,
              maxLines: 2,
              decoration: InputDecoration(labelText: t.revisioNota),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: _verdIgual, minimumSize: const Size.fromHeight(52)),
              onPressed: _enviant ? null : () => _fer('igual'),
              icon: const Icon(Icons.check),
              label: Text(t.revisioIgual),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: _ambre, minimumSize: const Size.fromHeight(52)),
              onPressed: _enviant ? null : () => _fer('canviat'),
              icon: const Icon(Icons.swap_horiz),
              label: Text(t.revisioCanviat),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              onPressed: _enviant ? null : () => _fer('no_trobat'),
              icon: const Icon(Icons.search_off),
              label: Text(t.revisioNoTrobat),
            ),
          ],
        ],
      ),
    );
  }
}

LatLng _ll(List c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble());

List<List<LatLng>> _llistaAnells(List anells) => [for (final a in anells) [for (final c in a as List) _ll(c as List)]];

List<List<LatLng>> _anells(Map<String, dynamic> g) => switch (g['type']) {
      'Polygon' => _llistaAnells(g['coordinates'] as List),
      'MultiPolygon' => [for (final p in g['coordinates'] as List) ..._llistaAnells(p as List)],
      _ => const [],
    };

List<LatLng> _punts(Map<String, dynamic> g) => _anells(g).expand((a) => a).toList();
