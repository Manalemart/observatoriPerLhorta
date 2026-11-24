import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config.dart';

// Avisos al mòbil (push) amb Firebase Cloud Messaging. Vegeu docs/PUSH.md.
//
// · Firebase es configura en compilar (--dart-define=FIREBASE_*). Sense configuració, la app
//   funciona igual i no hi ha avisos push (els avisos continuen en la pantalla «Avisos»).
// · En entrar es demana permís i es registra el token del mòbil (registrar_dispositiu); en
//   eixir s'oblida (oblidar_dispositiu) i s'esborra el token de Firebase.
// · Tocar un avís obri la pantalla «Avisos» ([onObrir]).
// · Es fa servir el token d'FCM (getToken / onTokenRefresh / deleteToken), que és el destí que
//   accepta l'API HTTP v1 de la funció enviar-push. firebase_messaging 17 el marca com a
//   obsolet en favor de register() / onRegistered (identificador d'instal·lació): quan l'API
//   d'enviament el documente com a destí, es canvia ací i en la funció.
// ignore_for_file: deprecated_member_use

class AvisosPush {
  AvisosPush(this._client, {required this.onObrir});

  final SupabaseClient _client;

  /// En tocar un avís (app tancada o de fons).
  final VoidCallback onObrir;

  bool _actiu = false;
  String? _token;
  StreamSubscription<String>? _refresc;

  /// Firebase està configurat en esta compilació.
  static bool get configurat => Config.firebaseAppId.isNotEmpty;

  Future<void> iniciar() async {
    if (!configurat || kIsWeb) return;
    try {
      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: Config.firebaseApiKey,
          appId: Config.firebaseAppId,
          messagingSenderId: Config.firebaseSenderId,
          projectId: Config.firebaseProjectId,
        ),
      );
      _actiu = true;
      FirebaseMessaging.onMessageOpenedApp.listen((_) => onObrir());
      final inicial = await FirebaseMessaging.instance.getInitialMessage();
      if (inicial != null) onObrir();
    } catch (e) {
      debugPrint('Push sense iniciar: $e');
    }
  }

  /// En entrar (o en obrir la app amb sessió): permís i registre del token.
  Future<void> registrar({required String idioma}) async {
    if (!_actiu || _client.auth.currentUser == null) return;
    try {
      final m = FirebaseMessaging.instance;
      final permis = await m.requestPermission();
      if (permis.authorizationStatus == AuthorizationStatus.denied) return;
      // Amb l'app oberta, que també es veja (en iOS; en Android ho pinta el sistema)
      await m.setForegroundNotificationPresentationOptions(alert: true, badge: true, sound: true);
      _token = await m.getToken();
      if (_token != null) await _desar(_token!, idioma);
      await _refresc?.cancel();
      _refresc = m.onTokenRefresh.listen((t) {
        _token = t;
        _desar(t, idioma);
      });
    } catch (e) {
      debugPrint('Push sense registrar: $e');
    }
  }

  Future<void> _desar(String token, String idioma) => _client.rpc('registrar_dispositiu', params: {
        'p_token': token,
        'p_plataforma': defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
        'p_idioma': idioma,
      });

  /// Abans d'eixir: este mòbil ja no ha de rebre els avisos d'este compte.
  Future<void> oblidar() async {
    if (!_actiu) return;
    await _refresc?.cancel();
    _refresc = null;
    try {
      final t = _token ?? await FirebaseMessaging.instance.getToken();
      if (t != null && _client.auth.currentUser != null) {
        await _client.rpc('oblidar_dispositiu', params: {'p_token': t});
      }
      await FirebaseMessaging.instance.deleteToken();
    } catch (e) {
      debugPrint('Push sense oblidar: $e');
    }
    _token = null;
  }

  // ─── Preferència del perfil ────────────────────────────────────────────

  Future<bool> actius() async {
    final r = await _client.from('perfils').select('avisos_push').eq('id', _client.auth.currentUser!.id).single();
    return r['avisos_push'] as bool;
  }

  Future<void> desarActius(bool valor) =>
      _client.from('perfils').update({'avisos_push': valor}).eq('id', _client.auth.currentUser!.id);
}
