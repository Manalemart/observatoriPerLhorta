import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config.dart';
import '../core/localitzacio.dart';

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

  /// L'idioma que mostra la app i el guardat al perfil (per als correus i els avisos push).
  String? _idiomaApp;
  String? _idiomaPerfil;

  bool get entrada => _client.auth.currentUser != null;
  String? get alies => _alies;
  String? get email => _client.auth.currentUser?.email;

  /// Sin red no se puede comprobar: no se bloquea a quien ya tenía sesión.
  bool get necessitaAlies => entrada && _aliesCarregat && (_alies == null || _alies!.isEmpty);

  Future<void> _recarregarAlies() async {
    final uid = _client.auth.currentUser?.id;
    _aliesCarregat = false;
    _alies = null;
    if (uid != null) {
      try {
        final f = await _client.from('perfils').select('nom_public, idioma').eq('id', uid).single();
        _alies = f['nom_public'] as String?;
        _idiomaPerfil = f['idioma'] as String?;
        _aliesCarregat = true;
        unawaited(_desarIdioma());
      } catch (e) {
        debugPrint('Àlies sense carregar: $e');
      }
    }
    notifyListeners();
  }

  /// La app avisa de l'idioma que mostra (MaterialApp.builder); si no és el del perfil, es guarda
  /// perquè els correus i els avisos push isquen en el mateix idioma.
  void usarIdioma(String codi) {
    if (_idiomaApp == codi) return;
    _idiomaApp = codi;
    unawaited(_desarIdioma());
  }

  Future<void> _desarIdioma() async {
    final uid = _client.auth.currentUser?.id;
    final codi = _idiomaApp;
    if (uid == null || codi == null || !_aliesCarregat || codi == _idiomaPerfil) return;
    if (codi != 'ca' && codi != 'es' && codi != 'en') return;
    _idiomaPerfil = codi;
    try {
      await _client.from('perfils').update({'idioma': codi}).eq('id', uid);
    } catch (e) {
      _idiomaPerfil = null;
      debugPrint('Idioma sense desar: $e');
    }
  }

  /// El correo trae un enlace que vuelve a la app (y, si la plantilla lo incluye, un código).
  /// supabase_flutter recoge el enlace y abre la sesión por su cuenta.
  Future<void> demanarCodi(String email) =>
      _client.auth.signInWithOtp(
        email: email,
        emailRedirectTo: Config.redireccioEntrada,
        // Per a la plantilla del correu (i l'idioma del perfil, si és un compte nou)
        data: {'idioma': Localitzacio.codi},
      );

  /// El compte de revisió de les botigues entra amb contrasenya (vegeu Config.compteRevisio).
  bool esCompteRevisio(String email) =>
      Config.compteRevisio.isNotEmpty && email.trim().toLowerCase() == Config.compteRevisio.toLowerCase();

  Future<void> entrarAmbContrasenya(String email, String contrasenya) =>
      _client.auth.signInWithPassword(email: email.trim(), password: contrasenya);

  Future<void> verificarCodi(String email, String codi) =>
      _client.auth.verifyOTP(type: OtpType.email, email: email, token: codi);

  Future<void> desarAlies(String alies) async {
    await _client.from('perfils').update({'nom_public': alies}).eq('id', _client.auth.currentUser!.id);
    await _recarregarAlies();
  }

  Future<void> eixir() => _client.auth.signOut();

  /// Esborra el compte en el servidor (RGPD art. 17): primer les fotos de Storage que no
  /// són d'elements validats, després el compte (vegeu la migració esborrar_compte).
  /// La sessió es tanca a banda, amb [tancarLocal], quan també s'ha netejat el dispositiu.
  Future<void> esborrarCompte() async {
    final fotos = ((await _client.rpc('fotos_per_esborrar')) as List).cast<String>();
    for (var i = 0; i < fotos.length; i += 1000) {
      await _client.storage.from('fotos').remove(fotos.sublist(i, i + 1000 > fotos.length ? fotos.length : i + 1000));
    }
    await _client.rpc('esborrar_compte');
  }

  /// Tot el que l'Observatori guarda de la persona (RGPD art. 15 i 20).
  Future<Map<String, dynamic>> lesMeuesDades() async =>
      (await _client.rpc('les_meues_dades')) as Map<String, dynamic>;

  /// Tanca la sessió només ací (el compte ja no existeix: el servidor no cal avisar-lo).
  Future<void> tancarLocal() => _client.auth.signOut(scope: SignOutScope.local);

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
