import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Idioma de la app: valencià (principal), castellà o anglés. Sense triar, el del dispositiu:
/// valencià si està en català o valencià, castellà si està en castellà i anglés per a la resta.
class Idioma extends ChangeNotifier {
  Idioma._(this._triat);

  static const _clau = 'idioma';
  static const valencia = Locale('ca');
  static const castella = Locale('es');
  static const angles = Locale('en');

  /// null: el del dispositiu.
  Locale? _triat;
  Locale? get triat => _triat;

  static Future<Idioma> carregar() async {
    final codi = (await SharedPreferences.getInstance()).getString(_clau);
    return Idioma._(switch (codi) {
      'ca' => valencia,
      'es' => castella,
      'en' => angles,
      _ => null,
    });
  }

  Future<void> triar(Locale? l) async {
    _triat = l;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    if (l == null) {
      await p.remove(_clau);
    } else {
      await p.setString(_clau, l.languageCode);
    }
  }

  /// Per a MaterialApp.localeResolutionCallback quan no s'ha triat.
  static Locale resoldre(Locale? dispositiu) => switch (dispositiu?.languageCode) {
        'ca' => valencia,
        'es' => castella,
        _ => angles,
      };
}
