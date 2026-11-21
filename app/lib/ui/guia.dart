import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/tema_app.dart';
import '../l10n/app_localizations.dart';
import 'adaptatiu.dart';

// Guia de benvinguda: quatre pàgines la primera vegada que s'entra (després de triar l'àlies).
// Es pot tornar a veure des del perfil («Com funciona»).

const _clauVista = 'guia.vista';

Future<bool> guiaVista() async => (await SharedPreferences.getInstance()).getBool(_clauVista) ?? false;

Future<void> mostrarGuia(BuildContext context) async {
  await Navigator.of(context, rootNavigator: true).push(MaterialPageRoute<void>(
    fullscreenDialog: true,
    builder: (_) => const PantallaGuia(),
  ));
  await (await SharedPreferences.getInstance()).setBool(_clauVista, true);
}

class _Pagina {
  const _Pagina(this.icona, this.titol, this.text);
  final IconData icona;
  final String titol;
  final String text;
}

class PantallaGuia extends StatefulWidget {
  const PantallaGuia({super.key});

  @override
  State<PantallaGuia> createState() => _PantallaGuiaState();
}

class _PantallaGuiaState extends State<PantallaGuia> {
  final _pagines = PageController();
  int _actual = 0;

  @override
  void dispose() {
    _pagines.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final cs = Theme.of(context).colorScheme;
    final pagines = [
      _Pagina(Icons.map_outlined, t.guiaMapaTitol, t.guiaMapaText),
      _Pagina(Icons.add_location_alt_outlined, t.guiaAportaTitol, t.guiaAportaText),
      _Pagina(Icons.fact_check_outlined, t.guiaPartidaTitol, t.guiaPartidaText),
      _Pagina(Icons.public, t.guiaObertTitol, t.guiaObertText),
    ];
    final darrera = _actual == pagines.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: ampladaFormulari),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                    child: darrera
                        ? const SizedBox(height: 48)
                        : TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(t.guiaSalta)),
                  ),
                ),
                Expanded(
                  child: PageView(
                    controller: _pagines,
                    onPageChanged: (i) => setState(() => _actual = i),
                    children: [
                      for (final (i, p) in pagines.indexed)
                        Semantics(
                          label: t.guiaPagina(i + 1, pagines.length),
                          child: _VistaPagina(pagina: p, marca: i == 0),
                        ),
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < pagines.length; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: i == _actual ? 22 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _actual ? cs.primary : cs.outlineVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                      onPressed: () => darrera
                          ? Navigator.of(context).pop()
                          : _pagines.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut),
                      child: Text(darrera ? t.guiaComenca : t.guiaSeguent),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VistaPagina extends StatelessWidget {
  const _VistaPagina({required this.pagina, this.marca = false});

  final _Pagina pagina;

  /// La primera pàgina porta el símbol de l'Observatori en lloc de la icona.
  final bool marca;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      child: Column(
        children: [
          const SizedBox(height: 24),
          if (marca)
            Image.asset('assets/simbol.png', height: 120, excludeFromSemantics: true)
          else
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(color: cs.primaryContainer, shape: BoxShape.circle),
              child: Icon(pagina.icona, size: 56, color: cs.onPrimaryContainer),
            ),
          const SizedBox(height: 32),
          Text(
            pagina.titol.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Text(pagina.text, textAlign: TextAlign.center, style: estilProsa(context).copyWith(fontSize: 18, height: 1.45)),
        ],
      ),
    );
  }
}
