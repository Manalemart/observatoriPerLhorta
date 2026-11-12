import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/remote/api_observatori.dart';
import '../data/revisio.dart';
import '../l10n/app_localizations.dart';

/// Las partidas que apadrina quien ha entrado: desde aquí se revisan en el campo.
class PartidesScreen extends StatefulWidget {
  const PartidesScreen({super.key});

  @override
  State<PartidesScreen> createState() => _PartidesScreenState();
}

class _PartidesScreenState extends State<PartidesScreen> {
  late Future<List<PartidaApadrinada>> _partides = context.read<ApiObservatori>().lesMeuesPartides();

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final ha = NumberFormat.decimalPattern('ca');
    return Scaffold(
      appBar: AppBar(title: Text(t.partidesTitol)),
      body: FutureBuilder<List<PartidaApadrinada>>(
        future: _partides,
        builder: (context, s) {
          if (s.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (s.hasError) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(t.partidesError),
                const SizedBox(height: 12),
                FilledButton.tonal(
                  onPressed: () => setState(() => _partides = context.read<ApiObservatori>().lesMeuesPartides()),
                  child: Text(t.comuTornarAProvar),
                ),
              ]),
            );
          }
          final llista = s.data!;
          if (llista.isEmpty) {
            return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(t.partidesBuit, textAlign: TextAlign.center)));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: llista.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final p = llista[i];
              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  title: Text(p.nom, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(t.partidesResum(p.municipi, ha.format(p.areaHa), p.validats)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/partides/${p.id}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
