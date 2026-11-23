import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/tema_app.dart';
import '../data/models.dart';
import '../l10n/app_localizations.dart';

// Filtres del mapa de la app: quins temes es veuen i de quina època (com «Capes i filtres»
// de la web). Es guarden en el dispositiu: en tornar a obrir la app, el mapa es veu igual.

enum EpocaFiltre { tot, inventari2018, noves }

@immutable
class FiltresMapa {
  const FiltresMapa({this.temesAmagats = const {}, this.epoca = EpocaFiltre.tot});

  final Set<int> temesAmagats;
  final EpocaFiltre epoca;

  bool get actius => temesAmagats.isNotEmpty || epoca != EpocaFiltre.tot;

  /// [temaId] i [perRevisar] són les propietats de l'element (tema_id i per_revisar).
  bool mostra(int? temaId, bool perRevisar) {
    if (temaId != null && temesAmagats.contains(temaId)) return false;
    return switch (epoca) {
      EpocaFiltre.tot => true,
      EpocaFiltre.inventari2018 => perRevisar,
      EpocaFiltre.noves => !perRevisar,
    };
  }

  FiltresMapa copyWith({Set<int>? temesAmagats, EpocaFiltre? epoca}) =>
      FiltresMapa(temesAmagats: temesAmagats ?? this.temesAmagats, epoca: epoca ?? this.epoca);

  static const _clauTemes = 'filtres.temes_amagats';
  static const _clauEpoca = 'filtres.epoca';

  static Future<FiltresMapa> carregar() async {
    final p = await SharedPreferences.getInstance();
    return FiltresMapa(
      temesAmagats: {for (final s in p.getStringList(_clauTemes) ?? const <String>[]) ?int.tryParse(s)},
      epoca: EpocaFiltre.values.asNameMap()[p.getString(_clauEpoca)] ?? EpocaFiltre.tot,
    );
  }

  Future<void> desar() async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList(_clauTemes, [for (final id in temesAmagats) '$id']);
    await p.setString(_clauEpoca, epoca.name);
  }
}

/// Full de filtres. [onCanvi] rep cada canvi al moment: el mapa es redibuixa darrere.
Future<void> mostrarFiltres(
  BuildContext context, {
  required List<Tema> temes,
  required FiltresMapa inicial,
  required ValueChanged<FiltresMapa> onCanvi,
}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        var f = inicial;
        return StatefulBuilder(builder: (ctx, setState) {
          final t = L.of(ctx);
          final cs = Theme.of(ctx).colorScheme;
          void canvi(FiltresMapa nou) {
            setState(() => f = nou);
            onCanvi(nou);
          }

          return SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.8),
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                children: [
                  Row(children: [
                    Expanded(child: Text(t.filtresTitol, style: Theme.of(ctx).textTheme.titleLarge)),
                    if (f.actius)
                      TextButton(onPressed: () => canvi(const FiltresMapa()), child: Text(t.filtresTot)),
                  ]),
                  const SizedBox(height: 12),
                  EtiquetaSeccio(t.filtresTemes, padding: EdgeInsets.zero),
                  for (final tema in temes)
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: !f.temesAmagats.contains(tema.id),
                      onChanged: (v) => canvi(f.copyWith(
                        temesAmagats: v == true
                            ? ({...f.temesAmagats}..remove(tema.id))
                            : {...f.temesAmagats, tema.id},
                      )),
                      secondary: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(color: colorDesDeHex(tema.color), borderRadius: BorderRadius.circular(4)),
                      ),
                      title: Text(tema.nomVisible),
                    ),
                  const SizedBox(height: 16),
                  EtiquetaSeccio(t.filtresEpoca, padding: EdgeInsets.zero),
                  const SizedBox(height: 8),
                  SegmentedButton<EpocaFiltre>(
                    segments: [
                      ButtonSegment(value: EpocaFiltre.tot, label: Text(t.filtresEpocaTot)),
                      ButtonSegment(value: EpocaFiltre.inventari2018, label: Text(t.filtresEpoca2018)),
                      ButtonSegment(value: EpocaFiltre.noves, label: Text(t.filtresEpocaNoves)),
                    ],
                    selected: {f.epoca},
                    showSelectedIcon: false,
                    onSelectionChanged: (s) => canvi(f.copyWith(epoca: s.first)),
                  ),
                  const SizedBox(height: 8),
                  Text(t.filtresEpocaNota, style: Theme.of(ctx).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                ],
              ),
            ),
          );
        });
      },
    );
