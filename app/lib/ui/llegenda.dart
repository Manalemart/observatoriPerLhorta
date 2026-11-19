import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/tema_app.dart';
import '../data/models.dart';
import '../l10n/app_localizations.dart';
import '../services/cataleg.dart';
import '../services/simbologia.dart';
import 'capa_simbologia.dart';

String _geometria(GeometriaVariable g) => switch (g) {
      GeometriaVariable.punt => 'Point',
      GeometriaVariable.linia => 'LineString',
      _ => 'Polygon',
    };

/// Llegenda del mapa: per a cada tema, el símbol de cada variable i, si en tenen de propis
/// (reg, serveis, línies, parcel·les), el de les seues categories.
Future<void> mostrarLlegenda(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _Llegenda(),
    );

class _Llegenda extends StatelessWidget {
  const _Llegenda();

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final temes = context.watch<Cataleg>().temes;
    final simbologia = context.read<Simbologia>();
    final cs = Theme.of(context).colorScheme;

    Simbol simbol(Tema tema, Variable v, [Categoria? c]) => simbologia.simbol(
          geometria: _geometria(v.geometria),
          variable: v.nom,
          categoria: c?.nom,
          tema: tema.nom,
          colorTema: tema.color,
        );

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (context, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          Text(t.llegendaTitol, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(t.llegendaExplicacio, style: TextStyle(color: cs.onSurfaceVariant)),
          for (final tema in temes) ...[
            const SizedBox(height: 18),
            Row(children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: colorDesDeHex(tema.color), borderRadius: BorderRadius.circular(3)),
              ),
              const SizedBox(width: 8),
              EtiquetaSeccio(tema.nom, padding: EdgeInsets.zero),
            ]),
            for (final v in tema.variables) ...[
              _Fila(simbol: simbol(tema, v), text: v.nom),
              // Si alguna categoria té símbol propi, totes (així cada símbol té el seu nom)
              if (v.categories.any((c) => simbol(tema, v, c) != simbol(tema, v)))
                for (final c in v.categories)
                  Padding(
                    padding: const EdgeInsets.only(left: 28),
                    child: _Fila(simbol: simbol(tema, v, c), text: c.nom, petit: true),
                  ),
            ],
          ],
        ],
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  const _Fila({required this.simbol, required this.text, this.petit = false});

  final Simbol simbol;
  final String text;
  final bool petit;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.symmetric(vertical: petit ? 3 : 5),
        child: Row(children: [
          SizedBox(width: 36, child: Center(child: MostraSimbol(simbol, mida: petit ? 20 : 26))),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: petit ? TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant) : null,
            ),
          ),
        ]),
      );
}
