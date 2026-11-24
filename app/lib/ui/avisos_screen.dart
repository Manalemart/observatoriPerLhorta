import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/tema_app.dart';
import '../l10n/app_localizations.dart';
import '../services/avisos.dart';
import '../services/avisos_push.dart';

import 'adaptatiu.dart';

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
    // Después del primer frame: carregar() avisa enseguida y la barra de abajo también escucha
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<Avisos>().carregar();
    });
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

  Future<void> _canviarResum(bool valor) async {
    final missatger = ScaffoldMessenger.of(context);
    final error = L.of(context).avisosResumError;
    try {
      await context.read<Avisos>().canviarResumCorreu(valor);
    } catch (_) {
      missatger.showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final avisos = context.watch<Avisos>();
    final data = DateFormat('d/M/yyyy', Localitzacio.codi);
    return Scaffold(
      appBar: AppBar(
        title: TitolBarra(t.avisosTitol),
        actions: [
          if (avisos.noLlegits > 0)
            TextButton(
              onPressed: () => avisos.marcarLlegits(avisos.items).catchError((_) {}),
              child: Text(t.avisosMarcarTots),
            ),
        ],
      ),
      body: Centrat(
        builder: (context, farciment) => RefreshIndicator(
        onRefresh: avisos.carregar,
        child: ListView(
          padding: farciment,
          children: [
            if (AvisosPush.configurat) const _InterruptorPush(),
            if (avisos.resumCorreu != null) ...[
              SwitchListTile(
                secondary: const Icon(Icons.mail_outline),
                title: Text(t.avisosResumCorreu),
                subtitle: Text(t.avisosResumCorreuDetall),
                value: avisos.resumCorreu!,
                onChanged: _canviarResum,
              ),
              const Divider(height: 1),
            ],
            if (avisos.senseConnexio && avisos.items.isNotEmpty)
              ListTile(leading: const Icon(Icons.cloud_off), title: Text(t.avisosSenseConnexioUltims)),
            if (avisos.items.isEmpty)
              if (!avisos.carregats && avisos.carregant)
                const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
              else
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    avisos.carregats ? t.avisosBuit : t.avisosSenseConnexio,
                    textAlign: TextAlign.center,
                    style: estilProsa(context),
                  ),
                ),
            for (final (i, a) in avisos.items.indexed) ...[
              if (i > 0) const Divider(height: 1),
              Builder(
                builder: (context) {
                  final detall = _detall(t, a);
                  return ListTile(
                    leading: Icon(switch (a.accio) {
                      'validat' => Icons.check_circle_outline,
                      'rebutjat' => Icons.cancel_outlined,
                      'nova_aportacio' => Icons.add_location_alt_outlined,
                      'revisat' => Icons.fact_check_outlined,
                      _ => Icons.history,
                    }, color: a.llegit ? null : Theme.of(context).colorScheme.primary),
                    title: Text(a.titol, style: TextStyle(fontWeight: a.llegit ? FontWeight.normal : FontWeight.w700)),
                    subtitle: Text(
                      [
                        _accio(t, a),
                        if (a.partida != null && a.dePartida) a.partida!,
                        data.format(a.creat.toLocal()),
                        if (detall != null && detall.isNotEmpty) '\n$detall',
                      ].join(' · ').replaceAll(' · \n', '\n'),
                    ),
                    isThreeLine: detall != null && detall.isNotEmpty,
                    onTap: () => _obrir(a),
                  );
                },
              ),
            ],
          ],
        ),
      )),
    );
  }
}

/// «Avisos al mòbil»: si este compte rep avisos push (en tots els seus mòbils).
class _InterruptorPush extends StatefulWidget {
  const _InterruptorPush();

  @override
  State<_InterruptorPush> createState() => _InterruptorPushState();
}

class _InterruptorPushState extends State<_InterruptorPush> {
  bool? _valor;

  @override
  void initState() {
    super.initState();
    context.read<AvisosPush>().actius().then((v) {
      if (mounted) setState(() => _valor = v);
    }).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    if (_valor == null) return const SizedBox.shrink();
    return SwitchListTile(
      secondary: const Icon(Icons.notifications_active_outlined),
      title: Text(t.avisosPush),
      subtitle: Text(t.avisosPushDetall),
      value: _valor!,
      onChanged: (v) async {
        final abans = _valor;
        final push = context.read<AvisosPush>();
        final avis = ScaffoldMessenger.of(context);
        setState(() => _valor = v);
        try {
          await push.desarActius(v);
        } catch (_) {
          if (!mounted) return;
          setState(() => _valor = abans);
          avis.showSnackBar(SnackBar(content: Text(t.avisosResumError)));
        }
      },
    );
  }
}
