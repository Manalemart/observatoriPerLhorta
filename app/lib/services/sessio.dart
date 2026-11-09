import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Sesión y alias. Avisa a go_router cuando cambian.
class Sessio extends ChangeNotifier {
  Sessio(this._client) {
    _sub = _client.auth.onAuthStateChange.listen((_) => _recarregarAlies());
    _recarregarAlies();
  }

  final SupabaseClient _client;
  late final StreamSubscription<AuthState> _sub;

  bool _aliesCarregat = false;
  String? _alies;

  bool get entrada => _client.auth.currentUser != null;
  String? get alies => _alies;

  /// Sin red no se puede comprobar: no se bloquea a quien ya tenía sesión.
  bool get necessitaAlies => entrada && _aliesCarregat && (_alies == null || _alies!.isEmpty);

  Future<void> _recarregarAlies() async {
    final uid = _client.auth.currentUser?.id;
    _aliesCarregat = false;
    _alies = null;
    if (uid != null) {
      try {
        final f = await _client.from('perfils').select('nom_public').eq('id', uid).single();
        _alies = f['nom_public'] as String?;
        _aliesCarregat = true;
      } catch (e) {
        debugPrint('Àlies sense carregar: $e');
      }
    }
    notifyListeners();
  }

  Future<void> demanarCodi(String email) => _client.auth.signInWithOtp(email: email);

  Future<void> verificarCodi(String email, String codi) =>
      _client.auth.verifyOTP(type: OtpType.email, email: email, token: codi);

  Future<void> desarAlies(String alies) async {
    await _client.from('perfils').update({'nom_public': alies}).eq('id', _client.auth.currentUser!.id);
    await _recarregarAlies();
  }

  Future<void> eixir() => _client.auth.signOut();

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
