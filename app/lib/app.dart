import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'core/tema_app.dart';
import 'l10n/app_localizations.dart';
import 'services/sessio.dart';
import 'ui/aportacions_screen.dart';
import 'ui/aportar_screen.dart';
import 'ui/entrada_screen.dart';
import 'ui/mapa_screen.dart';

class ObservatoriApp extends StatefulWidget {
  const ObservatoriApp({super.key, required this.sessio});

  final Sessio sessio;

  @override
  State<ObservatoriApp> createState() => _ObservatoriAppState();
}

class _ObservatoriAppState extends State<ObservatoriApp> {
  late final GoRouter _router = GoRouter(
    refreshListenable: widget.sessio,
    redirect: (context, estat) {
      final enEntrada = estat.matchedLocation == '/entrada';
      if (!widget.sessio.entrada) return enEntrada ? null : '/entrada';
      return enEntrada ? '/' : null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, _) => const MapaScreen()),
      GoRoute(path: '/entrada', builder: (_, _) => const EntradaScreen()),
      GoRoute(path: '/aportar', builder: (_, _) => const AportarScreen()),
      GoRoute(path: '/aportacions', builder: (_, _) => const AportacionsScreen()),
    ],
  );

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        title: "Observatori de l'Horta",
        theme: temaApp(Brightness.light),
        darkTheme: temaApp(Brightness.dark),
        locale: const Locale('ca'),
        supportedLocales: L.supportedLocales,
        localizationsDelegates: const [
          L.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: _router,
      );
}
