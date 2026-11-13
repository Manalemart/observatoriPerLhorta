import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../core/config.dart';
import '../data/models.dart';
import '../data/revisio.dart';
import '../l10n/app_localizations.dart';
import '../services/cataleg.dart';
import '../services/fotos.dart';
import '../services/paquets.dart';
import '../services/sigpac.dart';
import '../services/sincronitzacio.dart';
import 'capes_mapa.dart';

/// Geometría GeoJSON a partir de los puntos marcados; null si aún no hay bastantes.
/// Pública para los tests.
Map<String, dynamic>? geometriaDePunts(GeometriaVariable tipus, List<LatLng> punts) {
  List<double> c(LatLng p) => [p.longitude, p.latitude];
  return switch (tipus) {
    GeometriaVariable.punt => punts.isEmpty ? null : {'type': 'Point', 'coordinates': c(punts.first)},
    GeometriaVariable.linia => punts.length < 2 ? null : {'type': 'LineString', 'coordinates': punts.map(c).toList()},
    GeometriaVariable.poligon => punts.length < 3
        ? null
        : {
            'type': 'Polygon',
            'coordinates': [
              [...punts.map(c), c(punts.first)],
            ],
          },
    GeometriaVariable.parcela => null, // viene de SIGPAC
  };
}

class AportarScreen extends StatefulWidget {
  const AportarScreen({super.key, this.substitut});

  /// Desde «Ha canviat» en la revisión: tipo y lugar ya puestos, y el nuevo sustituirá al antiguo.
  final AportacioSubstitut? substitut;

  @override
  State<AportarScreen> createState() => _AportarScreenState();
}

class _AportarScreenState extends State<AportarScreen> {
  final _mapa = MapController();
  final _text = TextEditingController();
  final _descripcio = TextEditingController();
  final _picker = ImagePicker();

  Tema? _tema;
  Variable? _variable;
  Categoria? _categoria;
  Fons _fons = Fons.pnoa;
  final _punts = <LatLng>[];
  final _fotos = <Uint8List>[];
  Recinte? _recinte;
  bool _cercantRecinte = false;
  String? _avisRecinte;
  bool _obtenintPosicio = false;
  bool _guardant = false;

  @override
  void initState() {
    super.initState();
    final s = widget.substitut;
    if (s == null) return;
    // Mismo tipo que el elemento antiguo (se puede cambiar) y, si es un punto, en el mismo sitio
    for (final tema in context.read<Cataleg>().temes) {
      for (final v in tema.variables) {
        if (v.id == s.variableId) {
          _tema = tema;
          _variable = v;
          if (v.geometria == GeometriaVariable.punt) _punts.add(s.punt);
        }
      }
    }
  }

  @override
  void dispose() {
    _text.dispose();
    _descripcio.dispose();
    super.dispose();
  }

  void _reiniciarDibuix() {
    _punts.clear();
    _recinte = null;
    _avisRecinte = null;
  }

  Future<void> _marcar(LatLng p) async {
    final v = _variable;
    if (v == null) return;
    setState(() {
      if (v.geometria == GeometriaVariable.punt) _punts.clear();
      _punts.add(p);
    });
    if (v.geometria == GeometriaVariable.parcela) await _cercarRecinte(p);
  }

  Future<void> _cercarRecinte(LatLng p) async {
    final t = L.of(context);
    final sigpac = context.read<Sigpac>();
    setState(() {
      _punts
        ..clear()
        ..add(p);
      _recinte = null;
      _avisRecinte = null;
      _cercantRecinte = true;
    });
    try {
      final r = await sigpac.recinteEnPunt(p);
      if (!mounted) return;
      setState(() {
        _recinte = r;
        if (r == null) {
          _punts.clear();
          _avisRecinte = t.aportarSenseRecinte;
        }
      });
    } catch (_) {
      // Sin red: se guarda el punto y el recinto se busca al enviar
      if (mounted) setState(() => _avisRecinte = t.aportarRecinteOffline);
    } finally {
      if (mounted) setState(() => _cercantRecinte = false);
    }
  }

  Future<void> _usarPosicio() async {
    final t = L.of(context);
    final avis = ScaffoldMessenger.of(context);
    setState(() => _obtenintPosicio = true);
    final p = await posicioActual();
    if (!mounted) return;
    setState(() => _obtenintPosicio = false);
    if (p == null) {
      avis.showSnackBar(SnackBar(content: Text(t.gpsNoDisponible)));
      return;
    }
    _mapa.move(p, 18);
    await _marcar(p);
  }

  Future<void> _afegirFoto(ImageSource origen) async {
    final t = L.of(context);
    final avis = ScaffoldMessenger.of(context);
    try {
      final f = await _picker.pickImage(source: origen);
      if (f == null) return;
      final foto = await prepararFoto(await f.readAsBytes());
      if (mounted) setState(() => _fotos.add(foto));
    } catch (_) {
      avis.showSnackBar(SnackBar(content: Text(t.comuError)));
    }
  }

  bool get _llest {
    final v = _variable;
    if (v == null || _guardant || _cercantRecinte) return false;
    if (v.categories.isNotEmpty && _categoria == null) return false;
    if (v.textLliure && _text.text.trim().isEmpty) return false;
    if (v.geometria == GeometriaVariable.parcela) return _recinte != null || _punts.isNotEmpty;
    return geometriaDePunts(v.geometria, _punts) != null;
  }

  Future<void> _guardar() async {
    final t = L.of(context);
    final v = _variable!;
    final avis = ScaffoldMessenger.of(context);
    final tornar = GoRouter.of(context);
    final sincronitzacio = context.read<Sincronitzacio>();
    final esParcela = v.geometria == GeometriaVariable.parcela;
    final text = _text.text.trim();
    final descripcio = _descripcio.text.trim();
    setState(() => _guardant = true);
    final aportacio = Aportacio(
      id: const Uuid().v4(),
      variableId: v.id,
      titol: text.isNotEmpty ? text : v.nom,
      creadaEn: DateTime.now(),
      categoriaId: _categoria?.id,
      textLliure: text.isEmpty ? null : text,
      descripcio: descripcio.isEmpty ? null : descripcio,
      geom: esParcela ? _recinte?.geometria : geometriaDePunts(v.geometria, _punts),
      puntParcela: esParcela && _recinte == null ? _punts.first : null,
      recinteRef: _recinte?.ref,
      recinteDnPk: _recinte?.dnPk,
      fotos: List.of(_fotos),
      substitueixId: widget.substitut?.substitueixId,
    );
    // No se espera al envío: en el campo puede tardar o no haber red
    sincronitzacio.afegir(aportacio);
    avis.showSnackBar(SnackBar(content: Text(t.aportarGuardat)));
    tornar.pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final temes = context.watch<Cataleg>().temes;
    final v = _variable;
    final esParcela = v?.geometria == GeometriaVariable.parcela;

    final instruccio = switch (v?.geometria) {
      GeometriaVariable.punt => t.aportarInstruccioPunt,
      GeometriaVariable.linia => t.aportarInstruccioLinia,
      GeometriaVariable.poligon => t.aportarInstruccioPoligon,
      GeometriaVariable.parcela => t.aportarInstruccioParcela,
      null => null,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(t.aportarTitol),
        actions: [
          PopupMenuButton<Fons>(
            icon: const Icon(Icons.layers_outlined),
            tooltip: t.mapaFons,
            initialValue: _fons,
            onSelected: (f) => setState(() => _fons = f),
            itemBuilder: (_) => [for (final f in Fons.values) PopupMenuItem(value: f, child: Text(nomFons(t, f)))],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 4,
              child: FlutterMap(
                mapController: _mapa,
                options: MapOptions(
                  initialCenter: widget.substitut?.punt ?? Config.centreInicial,
                  initialZoom: widget.substitut == null ? Config.zoomInicial : 18,
                  onTap: (_, p) => _marcar(p),
                  interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
                ),
                children: [
                  capaFons(_fons, locals: context.read<Paquets>().teseles),
                  if (_recinte != null)
                    PolygonLayer(polygons: [
                      Polygon(
                        points: [
                          for (final c in (_recinte!.geometria['coordinates'] as List).first as List)
                            LatLng(((c as List)[1] as num).toDouble(), (c[0] as num).toDouble()),
                        ],
                        color: Colors.white.withValues(alpha: 0.35),
                        borderColor: Colors.black,
                        borderStrokeWidth: 3,
                      ),
                    ]),
                  if (_punts.length > 1 && !esParcela)
                    PolylineLayer(polylines: [
                      Polyline(points: _punts, color: Colors.black, strokeWidth: 3),
                    ]),
                  CircleLayer(circles: [
                    for (final p in _punts)
                      CircleMarker(point: p, radius: 7, color: Colors.white, borderColor: Colors.black, borderStrokeWidth: 3),
                  ]),
                  SimpleAttributionWidget(source: Text(atribucio(_fons))),
                ],
              ),
            ),
            Expanded(
              flex: 5,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (widget.substitut != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Card(
                        child: ListTile(
                          leading: const Icon(Icons.swap_horiz),
                          title: Text(t.revisioSubstitueix(widget.substitut!.numero)),
                          subtitle: Text(t.revisioSubstitueixNota),
                        ),
                      ),
                    ),
                  if (temes.isEmpty) Text(t.aportarSenseCataleg),
                  DropdownButtonFormField<Tema>(
                    initialValue: _tema,
                    isExpanded: true,
                    decoration: InputDecoration(labelText: t.aportarTema),
                    hint: Text(t.comuTria),
                    items: [for (final x in temes) DropdownMenuItem(value: x, child: Text(x.nom))],
                    onChanged: (x) => setState(() {
                      _tema = x;
                      _variable = null;
                      _categoria = null;
                      _reiniciarDibuix();
                    }),
                  ),
                  if (_tema != null) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<Variable>(
                      key: ValueKey('variable-${_tema!.id}'),
                      initialValue: _variable,
                      isExpanded: true,
                      decoration: InputDecoration(labelText: t.aportarVariable),
                      hint: Text(t.comuTria),
                      items: [for (final x in _tema!.variables) DropdownMenuItem(value: x, child: Text(x.nom))],
                      onChanged: (x) => setState(() {
                        _variable = x;
                        _categoria = null;
                        _reiniciarDibuix();
                      }),
                    ),
                  ],
                  if (v != null && v.categories.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<Categoria>(
                      key: ValueKey('categoria-${v.id}'),
                      initialValue: _categoria,
                      isExpanded: true,
                      decoration: InputDecoration(labelText: t.aportarCategoria),
                      hint: Text(t.comuTria),
                      items: [for (final x in v.categories) DropdownMenuItem(value: x, child: Text(x.nom))],
                      onChanged: (x) => setState(() => _categoria = x),
                    ),
                  ],
                  if (v != null) ...[
                    const SizedBox(height: 12),
                    Text(instruccio!),
                    if (v.geometria == GeometriaVariable.linia || v.geometria == GeometriaVariable.poligon)
                      Text(t.aportarVertexs(_punts.length)),
                    if (_cercantRecinte) Text(t.aportarCercant),
                    if (_recinte != null) Text(t.aportarRecinte(_recinte!.ref)),
                    if (_avisRecinte != null) Text(_avisRecinte!),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _obtenintPosicio ? null : _usarPosicio,
                          icon: const Icon(Icons.my_location),
                          label: Text(t.aportarUsarPosicio),
                        ),
                        if (_punts.isNotEmpty)
                          TextButton(
                            onPressed: () => setState(() {
                              _punts.removeLast();
                              _recinte = null;
                              _avisRecinte = null;
                            }),
                            child: Text(t.aportarDesfer),
                          ),
                      ],
                    ),
                    if (v.textLliure) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _text,
                        maxLength: 120,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(labelText: t.aportarQuin),
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextField(
                      controller: _descripcio,
                      maxLines: 3,
                      maxLength: 2000,
                      decoration: InputDecoration(labelText: t.aportarDescripcio),
                    ),
                    Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        FilledButton.tonalIcon(
                          onPressed: _fotos.length >= Config.maxFotos ? null : () => _afegirFoto(ImageSource.camera),
                          icon: const Icon(Icons.photo_camera),
                          label: Text(t.aportarFerFoto),
                        ),
                        OutlinedButton.icon(
                          onPressed: _fotos.length >= Config.maxFotos ? null : () => _afegirFoto(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library),
                          label: Text(t.aportarGaleria),
                        ),
                        Text(t.aportarFotos(_fotos.length)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(t.aportarLlicencia, style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 12),
                    FilledButton(onPressed: _llest ? _guardar : null, child: Text(t.aportarGuardar)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
