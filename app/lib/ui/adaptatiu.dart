import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// ─── Tauletes ──────────────────────────────────────────────────────────────
// Mides de finestra de Material 3: compacta (< 600 dp, mòbil), mitjana (600-839, tauleta
// vertical o pantalla dividida) i expandida (≥ 840, tauleta horitzontal). En iPad i en
// multifinestra la mida canvia en marxa: sempre es mira l'amplada actual, mai el dispositiu.

/// A partir d'ací la pantalla és de tauleta (mitjana o expandida).
const ampladaTauleta = 600.0;

/// Amplada màxima de les llistes (partides, avisos, les meues): les línies no creuen tota la tauleta.
const ampladaLlista = 720.0;

/// Amplada màxima dels formularis (aportar, entrada).
const ampladaFormulari = 600.0;

/// Amplada màxima de les barres i avisos que suren damunt dels mapes: la d'un mòbil.
const ampladaFlotant = 520.0;

bool esTauleta(BuildContext context) => MediaQuery.sizeOf(context).width >= ampladaTauleta;

/// Marge lateral perquè el contingut d'una llista o formulari no passe de [maxim] i quede
/// centrat; [base] és el farciment que ja tenia en mòbil.
EdgeInsets margeCentrat(BoxConstraints c, {double maxim = ampladaLlista, EdgeInsets base = EdgeInsets.zero}) {
  final extra = math.max(0.0, (c.maxWidth - maxim) / 2);
  return EdgeInsets.fromLTRB(base.left + extra, base.top, base.right + extra, base.bottom);
}

/// [builder] rep el farciment per a centrar el contingut (vegeu [margeCentrat]). Es fa servir
/// en lloc d'embolicar la llista, perquè el desplaçament i «estira per a recarregar» ocupen
/// tota l'amplada.
class Centrat extends StatelessWidget {
  const Centrat({super.key, required this.builder, this.maxim = ampladaLlista, this.base = EdgeInsets.zero});

  final Widget Function(BuildContext context, EdgeInsets farciment) builder;
  final double maxim;
  final EdgeInsets base;

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, c) => builder(context, margeCentrat(c, maxim: maxim, base: base)));
}

/// Allò que sura damunt d'un mapa (barra, avís, botons): en tauleta no passa de l'amplada
/// d'un mòbil i s'arrima a [alineacio].
class Flotant extends StatelessWidget {
  const Flotant({super.key, required this.child, this.alineacio = Alignment.topLeft, this.maxim = ampladaFlotant});

  final Widget child;
  final AlignmentGeometry alineacio;
  final double maxim;

  @override
  // heightFactor 1: només l'alçada del contingut (en una barra de baix, si no, ocuparia tota la pantalla)
  Widget build(BuildContext context) => Align(
        alignment: alineacio,
        heightFactor: 1,
        child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxim), child: child),
      );
}

/// En iOS (o en macOS) la app usa los controles que espera un usuario de Apple.
/// Se mira el tema y no `Platform`, así los tests pueden forzar la plataforma.
bool esApple(BuildContext context) => switch (Theme.of(context).platform) {
      TargetPlatform.iOS || TargetPlatform.macOS => true,
      _ => false,
    };

/// Diálogo de confirmación de dos botones: Material en Android, alerta de Apple en iOS.
/// Devuelve true solo si se acepta. [destructiu] pinta en rojo la acción en iOS.
Future<bool> confirmar(
  BuildContext context, {
  String? titol,
  required String text,
  required String cancelar,
  required String acceptar,
  bool destructiu = false,
}) {
  final dialeg = esApple(context)
      ? showCupertinoDialog<bool>(
          context: context,
          builder: (c) => CupertinoAlertDialog(
            title: titol == null ? null : Text(titol),
            content: Text(text),
            actions: [
              CupertinoDialogAction(onPressed: () => Navigator.pop(c, false), child: Text(cancelar)),
              CupertinoDialogAction(
                isDefaultAction: !destructiu,
                isDestructiveAction: destructiu,
                onPressed: () => Navigator.pop(c, true),
                child: Text(acceptar),
              ),
            ],
          ),
        )
      : showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            title: titol == null ? null : Text(titol),
            content: Text(text),
            actions: [
              TextButton(onPressed: () => Navigator.pop(c, false), child: Text(cancelar)),
              FilledButton(
                style: destructiu
                    ? FilledButton.styleFrom(
                        backgroundColor: Theme.of(c).colorScheme.error,
                        foregroundColor: Theme.of(c).colorScheme.onError,
                      )
                    : null,
                onPressed: () => Navigator.pop(c, true),
                child: Text(acceptar),
              ),
            ],
          ),
        );
  return dialeg.then((resposta) => resposta == true);
}

/// Codi d'idioma per a DateFormat i NumberFormat ('ca' o 'es'). El posa l'app en construir-se.
class Localitzacio {
  static String codi = 'ca';
}
