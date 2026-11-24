import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/tema_app.dart';
import '../data/models.dart';
import '../data/remote/api_observatori.dart';
import '../l10n/app_localizations.dart';
import '../services/sincronitzacio.dart';

import 'adaptatiu.dart';

class AportacionsScreen extends StatefulWidget {
  const AportacionsScreen({super.key});

  @override
  State<AportacionsScreen> createState() => _AportacionsScreenState();
}

class _AportacionsScreenState extends State<AportacionsScreen> {
  List<AportacioRemota>? _enviades;
  bool _errorEnviades = false;
  bool _carregant = false;

  /// Con poca cobertura la consulta puede tardar mucho en fallar: mejor avisar antes.
  static const _espera = Duration(seconds: 15);

  late final Sincronitzacio _sinc;
  late int _reconnexions;
  late bool _enviava;

  @override
  void initState() {
    super.initState();
    _sinc = context.read<Sincronitzacio>();
    _reconnexions = _sinc.reconnexions;
    _enviava = _sinc.enviant;
    _sinc.addListener(_canvi);
    _carregar();
  }

  @override
  void dispose() {
    _sinc.removeListener(_canvi);
    super.dispose();
  }

  /// Recarga las enviadas al volver la red y al acabar un envío (lo enviado pasa a la lista)
  void _canvi() {
    final acabat = _enviava && !_sinc.enviant;
    _enviava = _sinc.enviant;
    if (acabat || _sinc.reconnexions != _reconnexions) {
      _reconnexions = _sinc.reconnexions;
      _carregar();
    }
  }

  Future<void> _carregar() async {
    final api = context.read<ApiObservatori>();
    setState(() => _carregant = true);
    try {
      final r = await api.lesMeues().timeout(_espera);
      if (mounted) {
        setState(() {
          _enviades = r;
          _errorEnviades = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _errorEnviades = true);
    } finally {
      if (mounted) setState(() => _carregant = false);
    }
  }

  Future<void> _corregir(AportacioRemota a) async {
    final t = L.of(context);
    final api = context.read<ApiObservatori>();
    final avis = ScaffoldMessenger.of(context);
    final text = await showDialog<String>(
      context: context,
      builder: (_) => _DialegDescripcio(inicial: a.descripcio ?? '', rebutjada: a.estat == 'rebutjat'),
    );
    if (text == null || !mounted) return;
    try {
      await api.corregirDescripcio(a.id, text.trim().isEmpty ? null : text.trim()).timeout(_espera);
      avis.showSnackBar(SnackBar(content: Text(a.estat == 'rebutjat' ? t.llistaCorregidaRevisio : t.llistaCorregida)));
      await _carregar();
    } catch (_) {
      avis.showSnackBar(SnackBar(content: Text(t.llistaErrorAccio)));
    }
  }

  Future<void> _retirar(AportacioRemota a) async {
    final t = L.of(context);
    final api = context.read<ApiObservatori>();
    final avis = ScaffoldMessenger.of(context);
    final si = await confirmar(
      context,
      titol: t.llistaRetirarTitol,
      text: t.llistaRetirarText(a.titol),
      cancelar: t.comuCancelar,
      acceptar: t.llistaRetirar,
      destructiu: true,
    );
    if (!si || !mounted) return;
    try {
      await api.retirarAportacio(a.id).timeout(_espera);
      avis.showSnackBar(SnackBar(content: Text(t.llistaRetirada)));
      await _carregar();
    } catch (_) {
      avis.showSnackBar(SnackBar(content: Text(t.llistaErrorAccio)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final sinc = context.watch<Sincronitzacio>();
    final data = DateFormat.yMd(Localitzacio.codi);
    final perEnviar = sinc.items;
    final revisions = sinc.revisions;
    final enviades = _enviades ?? const <AportacioRemota>[];

    return Scaffold(
      appBar: AppBar(title: TitolBarra(t.mapaAportacions)),
      body: Centrat(
        builder: (context, farciment) => RefreshIndicator(
        onRefresh: () async {
          await sinc.enviar();
          await _carregar();
        },
        child: ListView(
          padding: farciment,
          children: [
            if (perEnviar.isNotEmpty || revisions.isNotEmpty) ...[
              ListTile(
                title: EtiquetaSeccio(t.llistaPerEnviar, padding: EdgeInsets.zero),
                trailing: TextButton(
                  onPressed: sinc.enviant
                      ? null
                      : () async {
                          await sinc.enviar();
                          await _carregar();
                        },
                  child: Text(t.llistaEnviarAra),
                ),
              ),
              for (final r in revisions)
                ListTile(
                  leading: Icon(r.error != null ? Icons.error_outline : Icons.fact_check_outlined),
                  title: Text(t.llistaRevisio(switch (r.resultat) {
                    'igual' => t.revisioIgual,
                    'canviat' => t.revisioCanviat,
                    _ => t.revisioNoTrobat,
                  })),
                  subtitle: Text(r.error ?? '${data.format(r.creadaEn)} · ${t.llistaEsperant}'),
                  trailing: IconButton(
                    tooltip: t.llistaEsborrar,
                    onPressed: () => sinc.esborrarRevisio(r.id),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ),
              for (final a in perEnviar)
                ListTile(
                  leading: Icon(a.estat == EstatCola.error ? Icons.error_outline : Icons.cloud_upload_outlined),
                  title: Text(a.titol),
                  subtitle: Text(a.error ?? t.llistaEsperant),
                  trailing: a.estat == EstatCola.error
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: t.llistaReintentar,
                              onPressed: () => sinc.reintentar(a.id),
                              icon: const Icon(Icons.refresh),
                            ),
                            IconButton(
                              tooltip: t.llistaEsborrar,
                              onPressed: () => sinc.esborrar(a.id),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        )
                      : null,
                ),
              const Divider(),
            ],
            ListTile(title: EtiquetaSeccio(t.llistaEnviades, padding: EdgeInsets.zero)),
            if (_carregant && _enviades == null)
              const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
            else if (_errorEnviades)
              ListTile(title: Text(t.llistaSenseConnexio)),
            if (!_errorEnviades && _enviades != null && enviades.isEmpty && perEnviar.isEmpty)
              ListTile(title: Text(t.llistaBuit)),
            for (final a in enviades)
              ListTile(
                leading: Icon(switch (a.estat) {
                  'validat' => Icons.check_circle_outline,
                  'rebutjat' => Icons.cancel_outlined,
                  _ => Icons.hourglass_empty,
                }),
                title: Text(a.titol),
                subtitle: Text([
                  '${data.format(a.creadaEn.toLocal())} · ${switch (a.estat) {
                    'validat' => t.estatValidat,
                    'rebutjat' => t.estatRebutjat,
                    _ => t.estatPendent,
                  }}',
                  if (a.motiuRebuig != null) t.llistaMotiu(a.motiuRebuig!),
                ].join('\n')),
                trailing: a.editable
                    ? PopupMenuButton<String>(
                        tooltip: t.llistaAccions,
                        onSelected: (accio) => accio == 'corregir' ? _corregir(a) : _retirar(a),
                        itemBuilder: (_) => [
                          PopupMenuItem(value: 'corregir', child: Text(t.llistaCorregir)),
                          PopupMenuItem(value: 'retirar', child: Text(t.llistaRetirar)),
                        ],
                      )
                    : null,
              ),
          ],
        ),
      )),
    );
  }
}

class _DialegDescripcio extends StatefulWidget {
  const _DialegDescripcio({required this.inicial, required this.rebutjada});
  final String inicial;
  final bool rebutjada;

  @override
  State<_DialegDescripcio> createState() => _DialegDescripcioState();
}

class _DialegDescripcioState extends State<_DialegDescripcio> {
  late final _text = TextEditingController(text: widget.inicial);

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    return AlertDialog(
      title: Text(t.llistaCorregir),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        if (widget.rebutjada) ...[
          Text(t.llistaCorregirRebutjada),
          const SizedBox(height: 12),
        ],
        TextField(
          controller: _text,
          autofocus: true,
          minLines: 3,
          maxLines: 6,
          maxLength: 2000,
          decoration: InputDecoration(labelText: t.aportarDescripcio),
        ),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(t.comuCancelar)),
        FilledButton(onPressed: () => Navigator.of(context).pop(_text.text), child: Text(t.aliesDesar)),
      ],
    );
  }
}
