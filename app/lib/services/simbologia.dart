import 'dart:convert';

import 'package:flutter/services.dart';

import '../core/tema_app.dart';

// Simbologia de la guia de disseny (docs/simbologia). assets/simbologia.json el genera
// docs/simbologia/generar.py, que també en fa la còpia de la web: no editar a mà.

sealed class Simbol {
  const Simbol(this.color);
  final Color color;
}

class SimbolPunt extends Simbol {
  const SimbolPunt({required Color color, required this.icona, required this.contorn}) : super(color);

  /// `assets/simbols/<icona>.png`
  final String icona;
  final Color contorn;

  String get asset => 'assets/simbols/$icona.png';

  @override
  bool operator ==(Object other) => other is SimbolPunt && other.icona == icona && other.color == color && other.contorn == contorn;
  @override
  int get hashCode => Object.hash(icona, color, contorn);
}

/// patro: continua | discontinua | puntejada | punt_ratlla | doble | cap (només el glif)
/// glif (al llarg de la línia): fletxa | quadrat | travesser | mur | x | ziga | ona
class SimbolLinia extends Simbol {
  const SimbolLinia({required Color color, required this.amplada, required this.patro, this.glif}) : super(color);
  final double amplada;
  final String patro;
  final String? glif;

  @override
  bool operator ==(Object other) =>
      other is SimbolLinia && other.color == color && other.amplada == amplada && other.patro == patro && other.glif == glif;
  @override
  int get hashCode => Object.hash(color, amplada, patro, glif);
}

/// trama: ratlles | punts (en blanc damunt del color), o cap
class SimbolParcela extends Simbol {
  const SimbolParcela({required Color color, required this.contorn, this.trama}) : super(color);
  final Color contorn;
  final String? trama;

  @override
  bool operator ==(Object other) => other is SimbolParcela && other.color == color && other.contorn == contorn && other.trama == trama;
  @override
  int get hashCode => Object.hash(color, contorn, trama);
}

class _Regles {
  Map<String, dynamic>? general;
  final cats = <String, Map<String, dynamic>>{};
}

Map<String, _Regles> _perVariable(List regles) {
  final m = <String, _Regles>{};
  for (final r in regles.cast<Map<String, dynamic>>()) {
    final e = m.putIfAbsent(r['variable'] as String, _Regles.new);
    final cat = r['categoria'] as String?;
    if (cat == null) {
      e.general = r;
    } else {
      e.cats[cat] = r;
    }
  }
  return m;
}

/// Quin símbol porta cada element, segons la variable i (en reg, serveis, línies i
/// parcel·les) la categoria. Les regles van per nom, com les dona el servidor.
class Simbologia {
  Simbologia._(Map<String, dynamic> j)
      : _families = (j['families'] as Map).cast<String, Map<String, dynamic>>(),
        _familiaTema = (j['familiaTema'] as Map).cast<String, String>(),
        _estilsLinia = (j['estilsLinia'] as Map).cast<String, Map<String, dynamic>>(),
        _estilsParcela = (j['estilsParcela'] as Map).cast<String, Map<String, dynamic>>(),
        _punts = _perVariable(j['punts'] as List),
        _linies = _perVariable(j['linies'] as List),
        _parceles = _perVariable(j['parceles'] as List);

  factory Simbologia.desDeJson(String text) => Simbologia._(jsonDecode(text) as Map<String, dynamic>);

  static Future<Simbologia> carregar() async => Simbologia.desDeJson(await rootBundle.loadString('assets/simbologia.json'));

  final Map<String, Map<String, dynamic>> _families;
  final Map<String, String> _familiaTema;
  final Map<String, Map<String, dynamic>> _estilsLinia;
  final Map<String, Map<String, dynamic>> _estilsParcela;
  final Map<String, _Regles> _punts;
  final Map<String, _Regles> _linies;
  final Map<String, _Regles> _parceles;
  final _cache = <String, Simbol>{};

  static Map<String, dynamic>? _regla(Map<String, _Regles> regles, String? variable, String? categoria) {
    final e = regles[variable];
    return (categoria == null ? null : e?.cats[categoria]) ?? e?.general;
  }

  SimbolPunt _punt(String familia, [String? icona]) {
    final f = _families[familia] ?? _families['serveis']!;
    return SimbolPunt(
      color: colorDesDeHex(f['color'] as String),
      icona: icona ?? f['icona'] as String,
      contorn: colorDesDeHex(f['contorn'] as String),
    );
  }

  /// [geometria]: el tipus GeoJSON (Point, LineString, Polygon, MultiPolygon).
  /// [colorTema]: per si la variable no té cap regla (no hauria de passar).
  Simbol simbol({required String geometria, String? variable, String? categoria, String? tema, String? colorTema}) {
    final clau = '$geometria|$variable|$categoria|$tema';
    return _cache[clau] ??= _resoldre(geometria, variable, categoria, tema, colorTema);
  }

  Simbol _resoldre(String geometria, String? variable, String? categoria, String? tema, String? colorTema) {
    final familiaTema = _familiaTema[tema] ?? 'serveis';
    final perDefecte = colorDesDeHex(colorTema);
    switch (geometria) {
      case 'Point':
        final r = _regla(_punts, variable, categoria);
        return r == null ? _punt(familiaTema) : _punt(r['familia'] as String? ?? familiaTema, r['icona'] as String?);
      case 'LineString':
        final e = _estilsLinia[_regla(_linies, variable, categoria)?['estil']];
        if (e == null) return SimbolLinia(color: perDefecte, amplada: 2, patro: 'continua');
        return SimbolLinia(
          color: colorDesDeHex(e['color'] as String),
          amplada: (e['amplada'] as num).toDouble(),
          patro: e['patro'] as String,
          glif: e['glif'] as String?,
        );
      default:
        final e = _estilsParcela[_regla(_parceles, variable, categoria)?['estil']];
        if (e == null) return SimbolParcela(color: perDefecte, contorn: const Color(0xFF574F46));
        return SimbolParcela(
          color: colorDesDeHex(e['color'] as String),
          contorn: colorDesDeHex(e['contorn'] as String),
          trama: e['trama'] as String?,
        );
    }
  }
}

/// Glifs que es dibuixen com a trama contínua (ja porten la línia base, si en tenen)
const glifsTrama = {'quadrat', 'travesser', 'mur', 'x', 'ziga', 'ona'};
