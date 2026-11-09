import '../models.dart';

/// Aportaciones pendientes de enviar. Sobreviven a cerrar la app y a quedarse sin red.
abstract class ColaAportacions {
  Future<List<Aportacio>> totes();
  Future<void> afegir(Aportacio a);
  Future<void> marcarError(String id, String missatge);
  Future<void> marcarPendent(String id);
  Future<void> esborrar(String id);
}

/// Sin persistencia: para los tests y para la vista previa web, donde no hay SQLite.
class ColaMemoria implements ColaAportacions {
  final _items = <String, Aportacio>{};

  @override
  Future<List<Aportacio>> totes() async => _items.values.toList();

  @override
  Future<void> afegir(Aportacio a) async => _items[a.id] = a;

  Aportacio _amb(Aportacio a, EstatCola estat, String? error) => Aportacio(
        id: a.id,
        variableId: a.variableId,
        titol: a.titol,
        creadaEn: a.creadaEn,
        categoriaId: a.categoriaId,
        textLliure: a.textLliure,
        descripcio: a.descripcio,
        geom: a.geom,
        puntParcela: a.puntParcela,
        recinteRef: a.recinteRef,
        recinteDnPk: a.recinteDnPk,
        fotos: a.fotos,
        estat: estat,
        error: error,
      );

  @override
  Future<void> marcarError(String id, String missatge) async =>
      _items[id] = _amb(_items[id]!, EstatCola.error, missatge);

  @override
  Future<void> marcarPendent(String id) async => _items[id] = _amb(_items[id]!, EstatCola.pendent, null);

  @override
  Future<void> esborrar(String id) async => _items.remove(id);
}
