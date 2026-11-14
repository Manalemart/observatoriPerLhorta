import 'package:flutter/foundation.dart';

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
      titol: (e?['text_lliure'] as String?) ?? ((e?['variable'] as Map<String, dynamic>?)?['nom'] as String?) ?? '',
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
}

/// Avisos del usuario. Se cargan al entrar, al recuperar la red y al abrir la app; sin
/// red se queda con lo último que tenía.
class Avisos extends ChangeNotifier {
  Avisos(this.api);

  final ApiAvisos api;
  List<Avis> _items = const [];

  List<Avis> get items => _items;
  int get noLlegits => _items.where((a) => !a.llegit).length;

  Future<void> carregar() async {
    try {
      _items = [for (final j in await api.avisos()) Avis.fromJson(j)];
      notifyListeners();
    } catch (e) {
      debugPrint('Avisos sense carregar: $e');
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
    notifyListeners();
  }
}
