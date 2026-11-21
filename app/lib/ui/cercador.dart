import 'dart:async';

import 'package:flutter/material.dart';

import '../data/models.dart';
import '../l10n/app_localizations.dart';

// Buscador del mapa: municipis i partides per nom (cercar_llocs, en el servidor; vegeu
// supabase/migrations/20261121000001_cercar_llocs.sql). El mateix que en la web.

typedef CercaLlocs = Future<List<Lloc>> Function(String text);

class CercadorLlocs extends SearchDelegate<Lloc?> {
  CercadorLlocs({required this.cercar, required String etiqueta})
    : super(searchFieldLabel: etiqueta);

  final CercaLlocs cercar;

  // Una consulta per text: en tornar a construir-se (teclat, tema) no es repetix
  String? _ultim;
  Future<List<Lloc>>? _resultat;

  Future<List<Lloc>> _cerca(String q) {
    if (q != _ultim) {
      _ultim = q;
      _resultat = cercar(q).timeout(const Duration(seconds: 10));
    }
    return _resultat!;
  }

  @override
  List<Widget> buildActions(BuildContext context) => [
    if (query.isNotEmpty)
      IconButton(
        icon: const Icon(Icons.clear),
        tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
        onPressed: () => query = '',
      ),
  ];

  @override
  Widget buildLeading(BuildContext context) =>
      BackButton(onPressed: () => close(context, null));

  @override
  Widget buildResults(BuildContext context) => buildSuggestions(context);

  @override
  Widget buildSuggestions(BuildContext context) {
    final t = L.of(context);
    final q = query.trim();
    if (q.length < 2) {
      return _Missatge(t.cercadorAjuda);
    }
    return FutureBuilder<List<Lloc>>(
      future: _cerca(q),
      builder: (context, s) {
        if (s.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (s.hasError) return _Missatge(t.cercadorError);
        final llocs = s.data ?? const [];
        if (llocs.isEmpty) return _Missatge(t.cercadorCap);
        return ListView.separated(
          itemCount: llocs.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final l = llocs[i];
            return ListTile(
              leading: Icon(
                l.esMunicipi
                    ? Icons.location_city_outlined
                    : Icons.grass_outlined,
              ),
              title: Text(l.nom),
              subtitle: Text(
                l.esMunicipi
                    ? t.cercadorMunicipi
                    : t.cercadorPartida(l.municipi ?? ''),
              ),
              onTap: () => close(context, l),
            );
          },
        );
      },
    );
  }
}

class _Missatge extends StatelessWidget {
  const _Missatge(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Text(
      text,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );
}
