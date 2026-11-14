import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../services/avisos.dart';

/// La campana: lo que ha pasado con lo que has aportado y en las partidas que apadrinas.
class AvisosScreen extends StatefulWidget {
  const AvisosScreen({super.key});

  @override
  State<AvisosScreen> createState() => _AvisosScreenState();
}

class _AvisosScreenState extends State<AvisosScreen> {
  @override
  void initState() {
    super.initState();
    context.read<Avisos>().carregar();
  }

  String _accio(L t, Avis a) => switch (a.accio) {
        'validat' => t.avisValidat,
        'rebutjat' => t.avisRebutjat,
        'reobert' => t.avisReobert,
        'nova_aportacio' => t.avisNovaAportacio,
        'revisat' => t.avisRevisat,
        _ => a.accio,
      };

  String? _detall(L t, Avis a) => switch (a.accio) {
        'nova_aportacio' => t.avisValidarAWeb,
        'revisat' => switch (a.motiu) {
            'igual' => t.revisioEstatIgual,
            'canviat' => t.revisioEstatCanviat,
            'no_trobat' => t.avisNoTrobat,
            _ => null,
          },
        _ => a.motiu,
      };

  Future<void> _obrir(Avis a) async {
    final avisos = context.read<Avisos>();
    final router = GoRouter.of(context);
    try {
      await avisos.marcarLlegits([a]);
    } catch (_) {
      // Sin red: se queda sin leer, no pasa nada
    }
    if (a.dePartida && a.partidaId != null) {
      await router.push('/partides/${a.partidaId}');
    } else if (!a.dePartida) {
      await router.push('/aportacions');
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final avisos = context.watch<Avisos>();
    final data = DateFormat('d/M/yyyy', 'ca');
    return Scaffold(
      appBar: AppBar(
        title: Text(t.avisosTitol),
        actions: [
          if (avisos.noLlegits > 0)
            TextButton(
              onPressed: () => avisos.marcarLlegits(avisos.items).catchError((_) {}),
              child: Text(t.avisosMarcarTots),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: avisos.carregar,
        child: avisos.items.isEmpty
            ? ListView(children: [Padding(padding: const EdgeInsets.all(32), child: Text(t.avisosBuit, textAlign: TextAlign.center))])
            : ListView.separated(
                itemCount: avisos.items.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final a = avisos.items[i];
                  final detall = _detall(t, a);
                  return ListTile(
                    leading: Icon(
                      switch (a.accio) {
                        'validat' => Icons.check_circle_outline,
                        'rebutjat' => Icons.cancel_outlined,
                        'nova_aportacio' => Icons.add_location_alt_outlined,
                        'revisat' => Icons.fact_check_outlined,
                        _ => Icons.history,
                      },
                      color: a.llegit ? null : Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(a.titol, style: TextStyle(fontWeight: a.llegit ? FontWeight.normal : FontWeight.w700)),
                    subtitle: Text([
                      _accio(t, a),
                      if (a.partida != null && a.dePartida) a.partida!,
                      data.format(a.creat.toLocal()),
                      if (detall != null && detall.isNotEmpty) '\n$detall',
                    ].join(' · ').replaceAll(' · \n', '\n')),
                    isThreeLine: detall != null && detall.isNotEmpty,
                    onTap: () => _obrir(a),
                  );
                },
              ),
      ),
    );
  }
}
