import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Idioma de la app: valencià (principal) o castellà. Sense triar, el del dispositiu
/// (castellà si el dispositiu està en castellà; per a tota la resta, valencià).
class Idioma extends ChangeNotifier {
  Idioma._(this._triat);

  static const _clau = 'idioma';
  static const valencia = Locale('ca');
  static const castella = Locale('es');

  /// null: el del dispositiu.
  Locale? _triat;
  Locale? get triat => _triat;

  static Future<Idioma> carregar() async {
    final codi = (await SharedPreferences.getInstance()).getString(_clau);
    return Idioma._(switch (codi) {
      'ca' => valencia,
      'es' => castella,
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
  static Locale resoldre(Locale? dispositiu) => dispositiu?.languageCode == 'es' ? castella : valencia;
}
