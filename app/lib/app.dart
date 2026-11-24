import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/tema_app.dart';
import 'data/revisio.dart';
import 'l10n/app_localizations.dart';
import 'services/avisos.dart';
import 'services/idioma.dart';
import 'services/sessio.dart';
import 'services/sincronitzacio.dart';
import 'ui/adaptatiu.dart';
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
        builder: (_, estat) => switch (estat.extra) {
          final AportacioSubstitut s => AportarScreen(substitut: s),
          final VistaMapa v => AportarScreen(vista: v),
          _ => const AportarScreen(),
        },
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
        onGenerateTitle: (c) => L.of(c).appTitol,
        theme: temaApp(Brightness.light),
        darkTheme: temaApp(Brightness.dark),
        locale: context.watch<Idioma>().triat,
        localeResolutionCallback: (dispositiu, _) => Idioma.resoldre(dispositiu),
        supportedLocales: L.supportedLocales,
        localizationsDelegates: const [
          L.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: _router,
        builder: (c, fill) {
          Localitzacio.codi = Localizations.localeOf(c).languageCode;
          return fill ?? const SizedBox.shrink();
        },
      );
}

/// Barra de navegación inferior con las cuatro secciones.
/// Toda la navegación principal pasa por aquí: NavigationBar de Material en Android
/// y barra de pestañas de Apple (CupertinoTabBar) en iOS.
class _Seccions extends StatelessWidget {
  const _Seccions({required this.shell});

  final StatefulNavigationShell shell;

  // Tocar la sección en la que ya estás vuelve a su pantalla principal
  void _anar(int i) => shell.goBranch(i, initialLocation: i == shell.currentIndex);

  @override
  Widget build(BuildContext context) {
    final noLlegits = context.watch<Avisos>().noLlegits;
    final pendents = context.watch<Sincronitzacio>().pendents;
    // Tauleta Android: rail lateral (Material 3). En iPad es queda la barra de pestanyes,
    // que és la navegació que esperen les guies d'Apple també en iPad.
    if (!esApple(context) && esTauleta(context)) {
      return Scaffold(
        body: Row(children: [
          _rail(context, noLlegits, pendents),
          VerticalDivider(width: 1, thickness: 1, color: Theme.of(context).colorScheme.outlineVariant),
          Expanded(child: shell),
        ]),
      );
    }
    return Scaffold(
      body: shell,
      bottomNavigationBar: esApple(context)
          ? _barraApple(context, noLlegits, pendents)
          : _barraMaterial(context, noLlegits, pendents),
    );
  }

  Widget _rail(BuildContext context, int noLlegits, int pendents) {
    final t = L.of(context);
    return SafeArea(
      right: false,
      child: NavigationRail(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: _anar,
        labelType: NavigationRailLabelType.all,
        groupAlignment: -0.85,
        leading: Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 8),
          child: Image.asset('assets/simbol.png', height: 44, semanticLabel: "L'observatori"),
        ),
        destinations: [
          NavigationRailDestination(icon: const Icon(Icons.map_outlined), selectedIcon: const Icon(Icons.map), label: Text(t.navMapa)),
          NavigationRailDestination(
            icon: const Icon(Icons.fact_check_outlined),
            selectedIcon: const Icon(Icons.fact_check),
            label: Text(t.navPartides),
          ),
          NavigationRailDestination(
            icon: _ambInsignia(Icons.notifications_outlined, noLlegits),
            selectedIcon: _ambInsignia(Icons.notifications, noLlegits),
            label: Text(t.navAvisos),
          ),
          NavigationRailDestination(
            icon: _ambInsignia(Icons.inventory_2_outlined, pendents),
            selectedIcon: _ambInsignia(Icons.inventory_2, pendents),
            label: Text(t.navLesMeues),
          ),
        ],
      ),
    );
  }

  static Widget _ambInsignia(IconData icona, int n) =>
      Badge(isLabelVisible: n > 0, label: Text('$n'), child: Icon(icona));

  Widget _barraMaterial(BuildContext context, int noLlegits, int pendents) {
    final t = L.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant))),
      child: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: _anar,
        destinations: [
          NavigationDestination(icon: const Icon(Icons.map_outlined), selectedIcon: const Icon(Icons.map), label: t.navMapa),
          NavigationDestination(
            icon: const Icon(Icons.fact_check_outlined),
            selectedIcon: const Icon(Icons.fact_check),
            label: t.navPartides,
          ),
          NavigationDestination(
            icon: _ambInsignia(Icons.notifications_outlined, noLlegits),
            selectedIcon: _ambInsignia(Icons.notifications, noLlegits),
            label: t.navAvisos,
          ),
          NavigationDestination(
            icon: _ambInsignia(Icons.inventory_2_outlined, pendents),
            selectedIcon: _ambInsignia(Icons.inventory_2, pendents),
            label: t.navLesMeues,
          ),
        ],
      ),
    );
  }

  Widget _barraApple(BuildContext context, int noLlegits, int pendents) {
    final t = L.of(context);
    final c = Theme.of(context).colorScheme;
    return CupertinoTabBar(
      currentIndex: shell.currentIndex,
      onTap: _anar,
      activeColor: c.primary,
      inactiveColor: c.onSurfaceVariant,
      backgroundColor: c.surface.withValues(alpha: 0.94),
      border: Border(top: BorderSide(color: c.outlineVariant, width: 0.5)),
      items: [
        BottomNavigationBarItem(
          icon: const Icon(CupertinoIcons.map),
          activeIcon: const Icon(CupertinoIcons.map_fill),
          label: t.navMapa,
        ),
        BottomNavigationBarItem(
          icon: const Icon(CupertinoIcons.checkmark_seal),
          activeIcon: const Icon(CupertinoIcons.checkmark_seal_fill),
          label: t.navPartides,
        ),
        BottomNavigationBarItem(
          icon: _ambInsignia(CupertinoIcons.bell, noLlegits),
          activeIcon: _ambInsignia(CupertinoIcons.bell_fill, noLlegits),
          label: t.navAvisos,
        ),
        BottomNavigationBarItem(
          icon: _ambInsignia(CupertinoIcons.archivebox, pendents),
          activeIcon: _ambInsignia(CupertinoIcons.archivebox_fill, pendents),
          label: t.navLesMeues,
        ),
      ],
    );
  }
}
