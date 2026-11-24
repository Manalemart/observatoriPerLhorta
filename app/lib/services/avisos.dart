import 'package:flutter/foundation.dart';

import '../data/models.dart' show nomCatalegJson;

/// Un aviso de la campana (tabla `notificacions`, la misma que en la web).
class Avis {
  const Avis({
    required this.id,
    required this.accio,
    required this.llegit,
    required this.creat,
    required this.elementId,
    required this.titol,
    this.motiu,
    this.partidaId,
    this.partida,
  });

  factory Avis.fromJson(Map<String, dynamic> j) {
    final e = j['element'] as Map<String, dynamic>?;
    final p = e?['partida'] as Map<String, dynamic>?;
    return Avis(
      id: j['id'] as int,
      accio: j['accio'] as String,
      motiu: j['motiu'] as String?,
      llegit: j['llegida'] as bool,
      creat: DateTime.parse(j['created_at'] as String),
      elementId: j['element_id'] as String,
      titol: (e?['text_lliure'] as String?) ?? nomCatalegJson(e?['variable'] as Map<String, dynamic>?),
      partidaId: e?['partida_id'] as int?,
      partida: p?['nom'] as String?,
    );
  }

  final int id;

  /// validat, rebutjat, reobert (de lo que has aportado) · nova_aportacio, revisat (en tu partida)
  final String accio;

  /// El motivo del rechazo, o el resultado de la revisión (igual / canviat / no_trobat)
  final String? motiu;
  final bool llegit;
  final DateTime creat;
  final String elementId;
  final String titol;
  final int? partidaId;
  final String? partida;

  /// De la partida que apadrinas (no de lo que has aportado tú)
  bool get dePartida => accio == 'nova_aportacio' || accio == 'revisat';
}

abstract class ApiAvisos {
  Future<List<Map<String, dynamic>>> avisos();
  Future<void> marcarLlegits(List<int> ids);

  /// Si recibe el resumen diario por correo (perfils.resum_correu)
  Future<bool> resumCorreu();
  Future<void> desarResumCorreu(bool valor);
}

/// Avisos del usuario. Se cargan al entrar, al recuperar la red y al abrir la app; sin
/// red se queda con lo último que tenía.
class Avisos extends ChangeNotifier {
  Avisos(this.api);

  final ApiAvisos api;
  List<Avis> _items = const [];
  bool? _resumCorreu;
  bool _carregant = false;
  bool _carregats = false;
  bool _senseConnexio = false;

  /// Con poca cobertura la consulta puede tardar mucho en fallar: mejor avisar antes.
  static const espera = Duration(seconds: 15);

  List<Avis> get items => _items;

  bool get carregant => _carregant;

  /// Si se han podido cargar alguna vez en esta sesión: si no, una lista vacía no quiere decir
  /// que no haya avisos.
  bool get carregats => _carregats;

  /// La última carga ha fallado: lo que se ve (si hay algo) puede no estar al día.
  bool get senseConnexio => _senseConnexio;
  int get noLlegits => _items.where((a) => !a.llegit).length;

  /// null mientras no se sabe (sin red, o la base de datos aún no lo tiene): no se muestra
  bool? get resumCorreu => _resumCorreu;

  Future<void> carregar() async {
    _carregant = true;
    notifyListeners();
    try {
      _items = [for (final j in await api.avisos().timeout(espera)) Avis.fromJson(j)];
      _carregats = true;
      _senseConnexio = false;
    } catch (e) {
      debugPrint('Avisos sense carregar: $e');
      _senseConnexio = true;
    } finally {
      _carregant = false;
      notifyListeners();
    }
    try {
      _resumCorreu = await api.resumCorreu().timeout(espera);
      notifyListeners();
    } catch (e) {
      debugPrint('Preferència del resum sense carregar: $e');
    }
  }

  /// Se ve el cambio enseguida; si no se puede desar, vuelve atrás y lanza el error.
  Future<void> canviarResumCorreu(bool valor) async {
    final abans = _resumCorreu;
    _resumCorreu = valor;
    notifyListeners();
    try {
      await api.desarResumCorreu(valor);
    } catch (_) {
      _resumCorreu = abans;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> marcarLlegits(Iterable<Avis> avisos) async {
    final ids = [for (final a in avisos) if (!a.llegit) a.id];
    if (ids.isEmpty) return;
    await api.marcarLlegits(ids);
    await carregar();
  }

  /// Al salir de la sesión
  void buidar() {
    _items = const [];
    _resumCorreu = null;
    _carregats = false;
    _senseConnexio = false;
    notifyListeners();
  }
}
