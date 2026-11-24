import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../core/config.dart';
import '../core/tema_app.dart';
import '../data/models.dart';
import '../data/revisio.dart';
import '../l10n/app_localizations.dart';
import '../services/cataleg.dart';
import '../services/fotos.dart';
import '../services/paquets.dart';
import '../services/sigpac.dart';
import '../services/sincronitzacio.dart';
import 'adaptatiu.dart';
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

/// Dónde estaba el mapa desde el que se abre «Aporta»: se empieza ahí, no en la vista general.
class VistaMapa {
  const VistaMapa(this.centre, this.zoom);
  final LatLng centre;
  final double zoom;
}

class AportarScreen extends StatefulWidget {
  const AportarScreen({super.key, this.substitut, this.vista});

  /// Desde «Ha canviat» en la revisión: tipo y lugar ya puestos, y el nuevo sustituirá al antiguo.
  final AportacioSubstitut? substitut;

  final VistaMapa? vista;

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
      titol: text.isNotEmpty ? text : v.nomVisible,
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

  /// 0: què has vist · 1: on és · 2: foto i detalls.
  /// Primero el qué: de él depende cómo se marca en el mapa (punto, línea, polígono o parcela).
  int _pas = 0;

  bool get _queLlest {
    final v = _variable;
    if (v == null) return false;
    if (v.categories.isNotEmpty && _categoria == null) return false;
    if (v.textLliure && _text.text.trim().isEmpty) return false;
    return true;
  }

  bool get _onLlest {
    final v = _variable;
    if (v == null || _cercantRecinte) return false;
    if (v.geometria == GeometriaVariable.parcela) return _recinte != null || _punts.isNotEmpty;
    return geometriaDePunts(v.geometria, _punts) != null;
  }

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final cs = Theme.of(context).colorScheme;
    final titols = [t.aportarPasQue, t.aportarPasOn, t.aportarPasDetalls];
    final potSeguir = switch (_pas) { 0 => _queLlest, 1 => _onLlest, _ => _llest };

    return PopScope(
      canPop: _pas == 0,
      onPopInvokedWithResult: (fet, _) {
        if (!fet) setState(() => _pas--);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            TitolBarra(t.aportarTitol),
            Text(
              '${t.aportarPas(_pas + 1)} · ${titols[_pas]}',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0, color: cs.onSurfaceVariant),
            ),
          ]),
          actions: [
            if (_pas == 1)
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
            child: LinearProgressIndicator(
              value: (_pas + 1) / 3,
              minHeight: 4,
              color: cs.primary,
              backgroundColor: cs.outlineVariant,
            ),
          ),
          shape: const Border(),
        ),
        body: IndexedStack(index: _pas, children: [_pasQue(t), _pasOn(t), _pasDetalls(t)]),
        bottomNavigationBar: DecoratedBox(
          decoration: BoxDecoration(color: cs.surface, border: Border(top: BorderSide(color: cs.outlineVariant))),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Flotant(alineacio: Alignment.center, maxim: ampladaFormulari - 32, child: Row(children: [
                if (_pas > 0) ...[
                  OutlinedButton(onPressed: () => setState(() => _pas--), child: Text(t.comuEnrere)),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: FilledButton(
                    onPressed: !potSeguir ? null : (_pas < 2 ? () => setState(() => _pas++) : _guardar),
                    child: Text(_pas < 2 ? t.comuContinua : t.aportarGuardar),
                  ),
                ),
              ])),
            ),
          ),
        ),
      ),
    );
  }

  Widget _pasQue(L t) {
    final temes = context.watch<Cataleg>().temes;
    final v = _variable;
    return Centrat(
      maxim: ampladaFormulari,
      base: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      builder: (context, farciment) => ListView(
      padding: farciment,
      children: [
        if (widget.substitut != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Card(
              child: ListTile(
                leading: const Icon(Icons.swap_horiz),
                title: Text(widget.substitut!.numero != null
                    ? t.revisioSubstitueix(widget.substitut!.numero!)
                    : t.revisioSubstitueixNom(widget.substitut!.nom ?? '')),
                subtitle: Text(t.revisioSubstitueixNota),
              ),
            ),
          ),
        EtiquetaSeccio(t.aportarTema, padding: const EdgeInsets.fromLTRB(4, 20, 4, 10)),
        if (temes.isEmpty) Text(t.aportarSenseCataleg),
        LayoutBuilder(builder: (context, c) {
          final ample = (c.maxWidth - 10) / 2;
          return Wrap(spacing: 10, runSpacing: 10, children: [
            for (final x in temes)
              SizedBox(
                width: ample,
                child: _TargetaTema(
                  nom: x.nomVisible,
                  color: colorDesDeHex(x.color),
                  triat: _tema?.id == x.id,
                  onTap: () => setState(() {
                    if (_tema?.id == x.id) return;
                    _tema = x;
                    _variable = null;
                    _categoria = null;
                    _reiniciarDibuix();
                  }),
                ),
              ),
          ]);
        }),
        if (_tema != null) ...[
          EtiquetaSeccio(t.aportarVariable, padding: const EdgeInsets.fromLTRB(4, 24, 4, 10)),
          DropdownButtonFormField<Variable>(
            key: ValueKey('variable-${_tema!.id}'),
            initialValue: _variable,
            isExpanded: true,
            hint: Text(t.comuTria),
            items: [for (final x in _tema!.variables) DropdownMenuItem(value: x, child: Text(x.nomVisible))],
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
            items: [for (final x in v.categories) DropdownMenuItem(value: x, child: Text(x.nomVisible))],
            onChanged: (x) => setState(() => _categoria = x),
          ),
        ],
        if (v != null && v.textLliure) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _text,
            maxLength: 120,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(labelText: t.aportarQuin),
          ),
        ],
      ],
    ));
  }

  Widget _pasOn(L t) {
    final cs = Theme.of(context).colorScheme;
    final v = _variable;
    final esParcela = v?.geometria == GeometriaVariable.parcela;
    final instruccio = switch (v?.geometria) {
      GeometriaVariable.punt => t.aportarInstruccioPunt,
      GeometriaVariable.linia => t.aportarInstruccioLinia,
      GeometriaVariable.poligon => t.aportarInstruccioPoligon,
      GeometriaVariable.parcela => t.aportarInstruccioParcela,
      null => '',
    };
    final estat = [
      if (v?.geometria == GeometriaVariable.linia || v?.geometria == GeometriaVariable.poligon) t.aportarVertexs(_punts.length),
      if (_cercantRecinte) t.aportarCercant,
      if (_recinte != null) t.aportarRecinte(_recinte!.ref),
      ?_avisRecinte,
    ];
    return Stack(children: [
      FlutterMap(
        mapController: _mapa,
        options: MapOptions(
          initialCenter: widget.substitut?.punt ?? widget.vista?.centre ?? Config.centreInicial,
          initialZoom: widget.substitut != null ? 18 : widget.vista?.zoom ?? Config.zoomInicial,
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
      // Instrucciones arriba y acciones abajo, sobre el mapa
      Positioned(
        top: 12,
        left: 12,
        right: 12,
        child: Flotant(child: Material(
          color: cs.surface,
          elevation: 3,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(instruccio, style: const TextStyle(fontWeight: FontWeight.w700)),
              for (final e in estat) ...[
                const SizedBox(height: 4),
                Text(e, style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
              ],
            ]),
          ),
        )),
      ),
      Positioned(
        left: 12,
        right: 12,
        bottom: 40,
        child: Row(children: [
          FloatingActionButton.extended(
            heroTag: 'posicio-aportar',
            onPressed: _obtenintPosicio ? null : _usarPosicio,
            icon: _obtenintPosicio
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5))
                : const Icon(Icons.my_location),
            label: Text(t.aportarUsarPosicio),
          ),
          const Spacer(),
          if (_punts.isNotEmpty)
            FloatingActionButton.small(
              heroTag: 'desfer-aportar',
              tooltip: t.aportarDesfer,
              onPressed: () => setState(() {
                _punts.removeLast();
                _recinte = null;
                _avisRecinte = null;
              }),
              child: const Icon(Icons.undo),
            ),
        ]),
      ),
    ]);
  }

  Widget _pasDetalls(L t) {
    final cs = Theme.of(context).colorScheme;
    final ple = _fotos.length >= Config.maxFotos;
    return Centrat(
      maxim: ampladaFormulari,
      base: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      builder: (context, farciment) => ListView(
      padding: farciment,
      children: [
        EtiquetaSeccio(t.aportarFotosTitol, padding: const EdgeInsets.fromLTRB(4, 20, 4, 10)),
        SizedBox(
          height: 96,
          child: ListView(scrollDirection: Axis.horizontal, children: [
            _BotoFoto(icona: Icons.photo_camera_outlined, text: t.aportarFerFoto, onTap: ple ? null : () => _afegirFoto(ImageSource.camera)),
            const SizedBox(width: 10),
            _BotoFoto(icona: Icons.photo_library_outlined, text: t.aportarGaleria, onTap: ple ? null : () => _afegirFoto(ImageSource.gallery)),
            for (final (i, f) in _fotos.indexed) ...[
              const SizedBox(width: 10),
              Stack(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.memory(f, width: 96, height: 96, fit: BoxFit.cover),
                ),
                Positioned(
                  top: 2,
                  right: 2,
                  child: IconButton.filledTonal(
                    visualDensity: VisualDensity.compact,
                    tooltip: t.revisioTreureFoto,
                    onPressed: () => setState(() => _fotos.removeAt(i)),
                    icon: const Icon(Icons.close, size: 16),
                  ),
                ),
              ]),
            ],
          ]),
        ),
        const SizedBox(height: 6),
        Text(t.aportarFotos(_fotos.length), style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
        EtiquetaSeccio(t.aportarDescripcio, padding: const EdgeInsets.fromLTRB(4, 20, 4, 10)),
        TextField(
          controller: _descripcio,
          maxLines: 4,
          maxLength: 2000,
        ),
        const SizedBox(height: 8),
        Text(t.aportarLlicencia, style: TextStyle(fontSize: 12, height: 1.45, color: cs.onSurfaceVariant)),
      ],
    ));
  }
}

/// Tema como tarjeta con su color (en vez de un desplegable).
class _TargetaTema extends StatelessWidget {
  const _TargetaTema({required this.nom, required this.color, required this.triat, required this.onTap});

  final String nom;
  final Color color;
  final bool triat;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      selected: triat,
      button: true,
      child: Material(
        color: triat ? cs.primaryContainer : cs.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: triat ? cs.primary : cs.outlineVariant, width: 2),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(children: [
                Container(width: 16, height: 16, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
                const SizedBox(width: 10),
                Expanded(child: Text(nom, style: const TextStyle(fontWeight: FontWeight.w700))),
                if (triat) Icon(Icons.check_circle, size: 20, color: cs.primary),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _BotoFoto extends StatelessWidget {
  const _BotoFoto({required this.icona, required this.text, required this.onTap});

  final IconData icona;
  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: 120,
      child: Material(
        color: cs.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: cs.outline, width: 1.5)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Opacity(
            opacity: onTap == null ? 0.4 : 1,
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icona),
              const SizedBox(height: 6),
              Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
      ),
    );
  }
}
