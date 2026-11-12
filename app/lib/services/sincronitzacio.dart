import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../data/local/cola.dart';
import '../data/models.dart';
import '../data/remote/api_observatori.dart';

typedef CercaRecinte = Future<Recinte?> Function(LatLng punt);

/// Envía la cola. Sin red no pasa nada: lo que no sale, se queda para la próxima.
class Sincronitzacio extends ChangeNotifier {
  Sincronitzacio({required this.cola, required this.api, required this.recinte, required this.missatgeSenseRecinte});

  final ColaAportacions cola;
  final ApiAportacions api;
  final CercaRecinte recinte;
  final String missatgeSenseRecinte;

  List<Aportacio> _items = const [];
  bool _enviant = false;
  Future<void>? _enCurs;

  List<Aportacio> get items => _items;
  bool get enviant => _enviant;
  int get pendents => _items.where((a) => a.estat == EstatCola.pendent).length;

  Future<void> carregar() async {
    _items = await cola.totes();
    notifyListeners();
  }

  Future<void> afegir(Aportacio a) async {
    await cola.afegir(a);
    await carregar();
    await enviar();
  }

  Future<void> esborrar(String id) async {
    await cola.esborrar(id);
    await carregar();
  }

  Future<void> reintentar(String id) async {
    await cola.marcarPendent(id);
    await carregar();
    await enviar();
  }

  /// Dos llamadas seguidas (guardar + volver la red) comparten el mismo envío.
  Future<void> enviar() => _enCurs ??= _enviarTot().whenComplete(() => _enCurs = null);

  Future<void> _enviarTot() async {
    _enviant = true;
    notifyListeners();
    try {
      for (final a in await cola.totes()) {
        if (a.estat != EstatCola.pendent) continue;
        try {
          await _enviarUna(a);
          await cola.esborrar(a.id);
        } on RebuigServidor catch (e) {
          await cola.marcarError(a.id, e.missatge); // reintentar no serviría: que lo vea el usuario
        } catch (e) {
          debugPrint('Sense enviar ${a.id}: $e');
          break; // lo más probable es que no haya red: no tiene sentido probar con las demás
        }
      }
    } finally {
      _enviant = false;
      await carregar();
    }
  }

  Future<void> _enviarUna(Aportacio a) async {
    var geom = a.geom;
    var ref = a.recinteRef;
    var dnPk = a.recinteDnPk;
    if (geom == null) {
      // Parcela tomada sin red: el recinto se busca ahora
      final r = await recinte(a.puntParcela!);
      if (r == null) throw RebuigServidor(missatgeSenseRecinte);
      geom = r.geometria;
      ref = r.ref;
      dnPk = r.dnPk;
    }
    await api.inserirElement({
      'id': a.id,
      'variable_id': a.variableId,
      'categoria_id': a.categoriaId,
      'text_lliure': a.textLliure,
      'descripcio': a.descripcio,
      'geom': geom,
      'origen': 'app',
      'sigpac_ref': ref,
      'sigpac_dn_pk': dnPk,
      'sigpac_data': ref == null ? null : DateTime.now().toIso8601String().substring(0, 10),
      if (a.substitueixId != null) 'substitueix_id': a.substitueixId,
    });
    for (var i = 0; i < a.fotos.length; i++) {
      await api.pujarFoto(a.id, i, a.fotos[i]);
    }
  }
}
