import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/tema_app.dart';
import 'data/revisio.dart';
import 'l10n/app_localizations.dart';
import 'services/avisos.dart';
import 'services/sessio.dart';
import 'services/sincronitzacio.dart';
import 'ui/aportacions_screen.dart';
import 'ui/aportar_screen.dart';
import 'ui/avisos_screen.dart';
import 'ui/entrada_screen.dart';
import 'ui/mapa_screen.dart';
import 'ui/partides_screen.dart';
import 'ui/revisio_screen.dart';

final _arrel = GlobalKey<NavigatorState>();

class ObservatoriApp extends StatefulWidget {
  const ObservatoriApp({super.key, required this.sessio});

  final Sessio sessio;

  @override
  State<ObservatoriApp> createState() => _ObservatoriAppState();
}

class _ObservatoriAppState extends State<ObservatoriApp> {
  late final GoRouter _router = GoRouter(
    navigatorKey: _arrel,
    refreshListenable: widget.sessio,
    redirect: (context, estat) {
      final enEntrada = estat.matchedLocation == '/entrada';
      if (!widget.sessio.entrada) return enEntrada ? null : '/entrada';
      return enEntrada ? '/' : null;
    },
    routes: [
      GoRoute(path: '/entrada', builder: (_, _) => const EntradaScreen()),
      // Pantallas a pantalla completa, sin la barra de abajo
      GoRoute(
        path: '/aportar',
        parentNavigatorKey: _arrel,
        builder: (_, estat) => AportarScreen(substitut: estat.extra as AportacioSubstitut?),
      ),
      GoRoute(
        path: '/partides/:id',
        parentNavigatorKey: _arrel,
        builder: (_, estat) => RevisioScreen(partidaId: int.parse(estat.pathParameters['id']!)),
      ),
      // Las cuatro secciones, cada una con su historial (como las pestañas de iOS y Android)
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => _Seccions(shell: shell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/', builder: (_, _) => const MapaScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/partides', builder: (_, _) => const PartidesScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/avisos', builder: (_, _) => const AvisosScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/aportacions', builder: (_, _) => const AportacionsScreen())]),
        ],
      ),
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

/// Barra de navegación inferior con las cuatro secciones.
/// Toda la navegación principal pasa por aquí: en iOS se cambiaría solo este widget.
class _Seccions extends StatelessWidget {
  const _Seccions({required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final noLlegits = context.watch<Avisos>().noLlegits;
    final pendents = context.watch<Sincronitzacio>().pendents;
    Widget ambInsignia(IconData icona, int n) =>
        Badge(isLabelVisible: n > 0, label: Text('$n'), child: Icon(icona));
    return Scaffold(
      body: shell,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant))),
        child: NavigationBar(
          selectedIndex: shell.currentIndex,
          // Tocar la sección en la que ya estás vuelve a su pantalla principal
          onDestinationSelected: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
          destinations: [
            NavigationDestination(icon: const Icon(Icons.map_outlined), selectedIcon: const Icon(Icons.map), label: t.navMapa),
            NavigationDestination(
              icon: const Icon(Icons.fact_check_outlined),
              selectedIcon: const Icon(Icons.fact_check),
              label: t.navPartides,
            ),
            NavigationDestination(
              icon: ambInsignia(Icons.notifications_outlined, noLlegits),
              selectedIcon: ambInsignia(Icons.notifications, noLlegits),
              label: t.navAvisos,
            ),
            NavigationDestination(
              icon: ambInsignia(Icons.inventory_2_outlined, pendents),
              selectedIcon: ambInsignia(Icons.inventory_2, pendents),
              label: t.navLesMeues,
            ),
          ],
        ),
      ),
    );
  }
}
