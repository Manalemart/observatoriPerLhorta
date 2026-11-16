import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../data/models.dart';
import '../data/revisio.dart';
import '../l10n/app_localizations.dart';
import '../services/sincronitzacio.dart';

/// Revisión de un elemento por su padrí, desde la pantalla de revisión o desde la ficha del mapa.
/// Primero se guarda en el móvil (en el campo puede no haber cobertura) y se envía en cuanto la haya.
/// Con «canviat» abre después la aportación que lo sustituirá. Devuelve si ha quedado registrada.
Future<bool> enviarRevisio(
  BuildContext context, {
  required String elementId,
  required int partidaId,
  required String resultat,
  String nota = '',
  List<Uint8List> fotos = const [],
  AportacioSubstitut? substitut,
}) async {
  final t = L.of(context);
  final avis = ScaffoldMessenger.of(context);
  final router = GoRouter.of(context);
  final sinc = context.read<Sincronitzacio>();
  final r = RevisioLocal(
    id: const Uuid().v4(),
    elementId: elementId,
    partidaId: partidaId,
    resultat: resultat,
    creadaEn: DateTime.now(),
    nota: nota.trim().isEmpty ? null : nota.trim(),
    fotos: fotos,
  );
  try {
    await sinc.revisar(r);
  } catch (_) {
    avis.showSnackBar(SnackBar(content: Text(t.revisioError)));
    return false;
  }
  final queda = sinc.revisions.where((x) => x.id == r.id).firstOrNull;
  if (queda?.error != null) {
    // El servidor la ha rechazado (p. ej. ya no es padrí): no tiene sentido guardarla
    await sinc.esborrarRevisio(r.id);
    avis.showSnackBar(SnackBar(content: Text(t.revisioRebutjada(queda!.error!))));
    return false;
  }
  avis.showSnackBar(SnackBar(content: Text(queda == null ? t.revisioFet : t.revisioGuardadaMobil)));
  if (resultat == 'canviat' && substitut != null) {
    await router.push('/aportar', extra: substitut);
  }
  return true;
}
