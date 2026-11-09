import 'dart:convert';

import 'package:flutter/foundation.dart';
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
