import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/models.dart';
import '../data/remote/api_observatori.dart';
import '../l10n/app_localizations.dart';
import '../services/sincronitzacio.dart';

class AportacionsScreen extends StatefulWidget {
  const AportacionsScreen({super.key});

  @override
  State<AportacionsScreen> createState() => _AportacionsScreenState();
}

class _AportacionsScreenState extends State<AportacionsScreen> {
  List<AportacioRemota>? _enviades;
  bool _errorEnviades = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final api = context.read<ApiObservatori>();
    try {
      final r = await api.lesMeues();
      if (mounted) {
        setState(() {
          _enviades = r;
          _errorEnviades = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _errorEnviades = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final sinc = context.watch<Sincronitzacio>();
    final data = DateFormat.yMd('ca');
    final perEnviar = sinc.items;
    final enviades = _enviades ?? const <AportacioRemota>[];

    return Scaffold(
      appBar: AppBar(title: Text(t.mapaAportacions)),
      body: RefreshIndicator(
        onRefresh: () async {
          await sinc.enviar();
          await _carregar();
        },
        child: ListView(
          children: [
            if (perEnviar.isNotEmpty) ...[
              ListTile(
                title: Text(t.llistaPerEnviar, style: Theme.of(context).textTheme.titleSmall),
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
            ListTile(title: Text(t.llistaEnviades, style: Theme.of(context).textTheme.titleSmall)),
            if (_errorEnviades) ListTile(title: Text(t.llistaSenseConnexio)),
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
              ),
          ],
        ),
      ),
    );
  }
}
