import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/remote/api_observatori.dart';
import '../data/revisio.dart';
import '../l10n/app_localizations.dart';
import '../services/paquets.dart';

/// Las partidas que apadrina quien ha entrado: desde aquí se revisan en el campo y se
/// preparan para trabajar sin cobertura.
class PartidesScreen extends StatefulWidget {
  const PartidesScreen({super.key});

  @override
  State<PartidesScreen> createState() => _PartidesScreenState();
}

class _PartidesScreenState extends State<PartidesScreen> {
  late Future<List<PartidaApadrinada>> _partides = _carregar();
  bool _senseXarxa = false;
  int? _preparant;

  Future<List<PartidaApadrinada>> _carregar() async {
    final paquets = context.read<Paquets>();
    try {
      final files = await context.read<ApiObservatori>().lesMeuesPartidesJson();
      await paquets.desarLlistaPartides(files);
      _senseXarxa = false;
      return [for (final f in files.cast<Map<String, dynamic>>()) PartidaApadrinada.fromJson(f)];
    } catch (_) {
      // Sin red: la última lista guardada, si la hay
      final guardada = await paquets.llistaPartides();
      if (guardada == null) rethrow;
      _senseXarxa = true;
      return guardada;
    }
  }

  Future<void> _preparar(PartidaApadrinada p) async {
    final t = L.of(context);
    final paquets = context.read<Paquets>();
    final avis = ScaffoldMessenger.of(context);
    setState(() => _preparant = p.id);
    PreparacioPaquet prep;
    try {
      prep = await paquets.preparar(p.id);
    } catch (_) {
      avis.showSnackBar(SnackBar(content: Text(t.paquetError)));
      return;
    } finally {
      if (mounted) setState(() => _preparant = null);
    }
    if (!mounted) return;
    final segur = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(p.nom),
        content: Text(t.paquetConfirmar(prep.teseles.length, _mida(prep.bytesEstimats))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(t.comuCancelar)),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(t.paquetBaixar)),
        ],
      ),
    );
    if (segur != true) return;
    try {
      await paquets.descarregar(prep);
    } on TeselesSenseBaixar catch (e) {
      avis.showSnackBar(SnackBar(content: Text(t.paquetIncomplet(e.n))));
    } catch (_) {
      avis.showSnackBar(SnackBar(content: Text(t.paquetError)));
    }
  }

  Future<void> _esborrar(PartidaApadrinada p) async {
    final t = L.of(context);
    final paquets = context.read<Paquets>();
    final segur = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(p.nom),
        content: Text(t.paquetConfirmarEsborrar),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(t.comuCancelar)),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(t.paquetEsborrar)),
        ],
      ),
    );
    if (segur == true) await paquets.esborrar(p.id);
  }

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
                  onPressed: () => setState(() => _partides = _carregar()),
                  child: Text(t.comuTornarAProvar),
                ),
              ]),
            );
          }
          final llista = s.data!;
          if (llista.isEmpty) {
            return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(t.partidesBuit, textAlign: TextAlign.center)));
          }
          return RefreshIndicator(
            onRefresh: () async {
              final f = _carregar();
              setState(() => _partides = f);
              await f;
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: llista.length + (_senseXarxa ? 1 : 0),
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                if (_senseXarxa && i == 0) {
                  return Row(children: [
                    const Icon(Icons.cloud_off, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(t.partidesSenseXarxa)),
                  ]);
                }
                final p = llista[i - (_senseXarxa ? 1 : 0)];
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    ListTile(
                      contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      title: Text(p.nom, style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(t.partidesResum(p.municipi, ha.format(p.areaHa), p.validats)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/partides/${p.id}'),
                    ),
                    _EstatPaquet(
                      partida: p,
                      preparant: _preparant == p.id,
                      onPreparar: () => _preparar(p),
                      onEsborrar: () => _esborrar(p),
                    ),
                  ]),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

String _mida(int bytes) {
  final mb = bytes / 1e6;
  return mb < 1 ? '< 1 MB' : '${NumberFormat('0.#', 'ca').format(mb)} MB';
}

/// Debajo de cada partida: si está en el móvil para trabajar sin cobertura.
class _EstatPaquet extends StatelessWidget {
  const _EstatPaquet({required this.partida, required this.preparant, required this.onPreparar, required this.onEsborrar});

  final PartidaApadrinada partida;
  final bool preparant;
  final VoidCallback onPreparar;
  final VoidCallback onEsborrar;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final paquets = context.watch<Paquets>();
    final progres = paquets.progres(partida.id);
    final info = paquets.info(partida.id);

    if (progres != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t.paquetBaixant((progres * 100).round())),
          const SizedBox(height: 6),
          LinearProgressIndicator(value: progres),
        ]),
      );
    }
    if (info == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
        child: Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: preparant ? null : onPreparar,
            icon: preparant
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.download_for_offline_outlined),
            label: Text(t.paquetPreparar),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 4, 4),
      child: Row(children: [
        Icon(Icons.offline_pin, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(child: Text(t.paquetPreparat(_mida(info.bytes), DateFormat('d/M/yyyy', 'ca').format(info.descarregat)))),
        PopupMenuButton<String>(
          enabled: !preparant,
          onSelected: (v) => v == 'actualitzar' ? onPreparar() : onEsborrar(),
          itemBuilder: (_) => [
            PopupMenuItem(value: 'actualitzar', child: Text(t.paquetActualitzar)),
            PopupMenuItem(value: 'esborrar', child: Text(t.paquetEsborrar)),
          ],
        ),
      ]),
    );
  }
}
