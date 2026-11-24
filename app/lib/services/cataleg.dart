import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models.dart';
import '../data/remote/api_observatori.dart';

/// Catálogo de variables con copia local: en el campo hay que poder aportar sin red.
class Cataleg extends ChangeNotifier {
  Cataleg(this._api);

  final ApiObservatori _api;
  static const _clau = 'cataleg_v1';

  List<Tema> _temes = const [];
  List<Tema> get temes => _temes;

  /// Els noms en l'idioma actual a partir dels ids d'un element (tema_id, variable_id,
  /// categoria_id). Si el catàleg encara no ha carregat, [defecte] (el valencià que du l'element).
  String nomTema(Object? id, String? defecte) {
    for (final t in _temes) {
      if (t.id == id) return t.nomVisible;
    }
    return defecte ?? '';
  }

  String nomVariable(Object? id, String? defecte) {
    for (final t in _temes) {
      for (final v in t.variables) {
        if (v.id == id) return v.nomVisible;
      }
    }
    return defecte ?? '';
  }

  String? nomCategoria(Object? id, String? defecte) {
    if (id == null) return defecte;
    for (final t in _temes) {
      for (final v in t.variables) {
        for (final c in v.categories) {
          if (c.id == id) return c.nomVisible;
        }
      }
    }
    return defecte;
  }

  Future<void> carregar() async {
    final prefs = await SharedPreferences.getInstance();
    final desat = prefs.getString(_clau);
    if (desat != null) {
      _temes = [for (final t in (jsonDecode(desat) as List).cast<Map<String, dynamic>>()) Tema.fromJson(t)];
      notifyListeners();
    }
    try {
      _temes = await _api.cataleg();
      await prefs.setString(_clau, jsonEncode([for (final t in _temes) t.toJson()]));
      notifyListeners();
    } catch (e) {
      debugPrint('Catàleg sense actualitzar: $e'); // sin red: sirve la copia
    }
  }
}

/// El catàleg del Provider, si n'hi ha (en alguns tests no).
Cataleg? catalegDe(BuildContext context) {
  try {
    return Provider.of<Cataleg>(context, listen: false);
  } catch (_) {
    return null;
  }
}
