import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../core/config.dart';
import '../core/tema_app.dart';
import '../l10n/app_localizations.dart';
import 'adaptatiu.dart';

/// Ficha de un elemento tocado en el mapa, con «És encara així?».
/// El padrí de la partida lo revisa desde aquí; el resto puede proponer una aportación que lo sustituya
/// (la validará el padrí).
class FitxaMapa extends StatelessWidget {
  const FitxaMapa({
    super.key,
    required this.prop,
    required this.color,
    required this.esPadri,
    required this.pendent,
    required this.onRevisar,
    required this.onCanviat,
    this.onObrirPartida,
  });

  /// Propiedades de elements_bbox
  final Map<String, dynamic> prop;
  final Color color;
  final bool esPadri;
  /// Ya hay una revisión suya en la cola del móvil
  final bool pendent;
  final void Function(String resultat) onRevisar;
  final VoidCallback onCanviat;
  final VoidCallback? onObrirPartida;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final cs = Theme.of(context).colorScheme;
    final data = DateFormat.yMMMd(Localitzacio.codi);
    final perRevisar = prop['per_revisar'] == true;
    final validat = prop['estat'] == 'validat';
    final revisat = DateTime.tryParse(prop['revisat_at'] as String? ?? '');
    final creat = DateTime.tryParse(prop['created_at'] as String? ?? '');
    final estat = perRevisar
        ? t.fitxaPerRevisar
        : switch (prop['estat']) {
            'validat' => t.estatValidat,
            'rebutjat' => t.estatRebutjat,
            _ => t.estatPendent,
          };
    final dataText = revisat != null
        ? t.fitxaRevisat(data.format(revisat.toLocal()))
        : (!perRevisar && creat != null ? t.fitxaAportat(data.format(creat.toLocal())) : null);
    final potRevisar = esPadri && perRevisar && validat;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(spacing: 8, runSpacing: 8, children: [
              if (prop['tema'] != null) _Pastilla(color: color, text: prop['tema'] as String),
              _Pastilla(text: estat, icona: perRevisar ? Icons.event_note_outlined : null),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: Text(prop['variable'] as String? ?? '', style: Theme.of(context).textTheme.headlineSmall)),
              if (validat && Config.urlWeb.isNotEmpty && prop['id'] != null)
                Builder(
                  // El seu context fa d'origen del full de compartir en iPad
                  builder: (b) => IconButton(
                    icon: Icon(Theme.of(context).platform == TargetPlatform.iOS ? Icons.ios_share : Icons.share_outlined),
                    tooltip: t.fitxaCompartir,
                    onPressed: () {
                      final caixa = b.findRenderObject() as RenderBox?;
                      final nom = prop['variable'] as String? ?? '';
                      SharePlus.instance.share(ShareParams(
                        uri: Uri.parse('${Config.urlWeb}/mapa?element=${prop['id']}'),
                        subject: t.fitxaCompartirText(nom),
                        sharePositionOrigin: caixa == null ? null : caixa.localToGlobal(Offset.zero) & caixa.size,
                      ));
                    },
                  ),
                ),
            ]),
            if (prop['categoria'] != null) ...[
              const SizedBox(height: 4),
              Text(prop['categoria'] as String, style: TextStyle(fontWeight: FontWeight.w600, color: cs.onSurfaceVariant)),
            ],
            if (dataText != null) ...[
              const SizedBox(height: 8),
              Text(dataText, style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
            ],
            if (validat) ...[
              const SizedBox(height: 16),
              DecoratedBox(
                decoration: BoxDecoration(color: cs.surfaceContainerLow, borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Text(potRevisar ? t.fitxaEsEncara : t.fitxaHaCanviatPregunta,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text(
                      pendent ? t.revisioPendentEnviar : (potRevisar ? t.fitxaEsEncaraPadri : t.fitxaAvisansDetall),
                      style: estilProsa(context).copyWith(fontSize: 15),
                    ),
                    if (!pendent) ...[
                      const SizedBox(height: 12),
                      Row(children: [
                        if (potRevisar) ...[
                          Expanded(child: OutlinedButton(onPressed: () => onRevisar('igual'), child: Text(t.fitxaSiIgual))),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: FilledButton(
                            style: FilledButton.styleFrom(backgroundColor: Marca.lima, foregroundColor: Marca.sobreLima),
                            onPressed: potRevisar ? () => onRevisar('canviat') : onCanviat,
                            child: Text(t.revisioCanviat),
                          ),
                        ),
                      ]),
                    ],
                  ]),
                ),
              ),
            ],
            if (esPadri && onObrirPartida != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: onObrirPartida,
                  icon: const Icon(Icons.fact_check_outlined),
                  label: Text(t.fitxaObrirPartida),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Pastilla extends StatelessWidget {
  const _Pastilla({required this.text, this.color, this.icona});

  final String text;
  final Color? color;
  final IconData? icona;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outline, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (color != null) ...[
            Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
          ],
          if (icona != null) ...[Icon(icona, size: 14), const SizedBox(width: 5)],
          Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}
