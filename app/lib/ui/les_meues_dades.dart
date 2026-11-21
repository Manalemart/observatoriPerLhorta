import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/app_localizations.dart';
import '../services/sessio.dart';

// «Descarrega les meues dades» (RGPD art. 15 i 20): tot el que l'Observatori guarda de la
// persona, en JSON (les_meues_dades() en el servidor, el mateix que la web). Es guarda en un
// fitxer i s'obri el full de compartir del sistema: desar-lo, enviar-lo per correu, etc.

Future<void> compartirLesMeuesDades(BuildContext context) async {
  final t = L.of(context);
  final sessio = context.read<Sessio>();
  final avis = ScaffoldMessenger.of(context);
  // En iPad el full de compartir és un globus: necessita saber d'on ix
  final caixa = context.findRenderObject() as RenderBox?;
  final origen = caixa == null ? null : caixa.localToGlobal(Offset.zero) & caixa.size;

  avis.showSnackBar(SnackBar(content: Text(t.dadesPreparant), duration: const Duration(seconds: 2)));
  try {
    final dades = await sessio.lesMeuesDades().timeout(const Duration(seconds: 20));
    final dia = DateTime.now().toIso8601String().substring(0, 10);
    final fitxer = File('${(await getTemporaryDirectory()).path}/observatori-les-meues-dades-$dia.json');
    await fitxer.writeAsString(const JsonEncoder.withIndent('  ').convert(dades));
    await SharePlus.instance.share(ShareParams(
      files: [XFile(fitxer.path, mimeType: 'application/json')],
      subject: t.dadesAssumpte,
      sharePositionOrigin: origen,
    ));
  } catch (e) {
    debugPrint('Les meues dades: $e');
    avis.hideCurrentSnackBar();
    avis.showSnackBar(SnackBar(content: Text(t.dadesError)));
  }
}
