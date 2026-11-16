import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
              FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(acceptar)),
            ],
          ),
        );
  return dialeg.then((resposta) => resposta == true);
}
