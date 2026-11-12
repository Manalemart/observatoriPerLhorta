import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:latlong2/latlong.dart';

import '../models.dart' show Aportacio, EstatCola;
import 'cola.dart';

part 'cola_drift.g.dart';

class AportacionsCola extends Table {
  TextColumn get id => text()();
  IntColumn get variableId => integer()();
  TextColumn get titol => text()();
  DateTimeColumn get creadaEn => dateTime()();
  IntColumn get categoriaId => integer().nullable()();
  TextColumn get textLliure => text().nullable()();
  TextColumn get descripcio => text().nullable()();
  TextColumn get geomJson => text().nullable()();
  RealColumn get parcelaLat => real().nullable()();
  RealColumn get parcelaLng => real().nullable()();
  TextColumn get recinteRef => text().nullable()();
  IntColumn get recinteDnPk => integer().nullable()();
  TextColumn get error => text().nullable()();
  TextColumn get substitueixId => text().nullable()();   // v2

  @override
  Set<Column> get primaryKey => {id};
}

class FotosCola extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get aportacioId => text().references(AportacionsCola, #id)();
  BlobColumn get bytes => blob()();
}

@DriftDatabase(tables: [AportacionsCola, FotosCola])
class BdCola extends _$BdCola {
  BdCola(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, de, a) async {
          if (de < 2) await m.addColumn(aportacionsCola, aportacionsCola.substitueixId);
        },
      );
}

class ColaDrift implements ColaAportacions {
  ColaDrift(this._bd);

  final BdCola _bd;

  @override
  Future<List<Aportacio>> totes() async {
    final files = await (_bd.select(_bd.aportacionsCola)..orderBy([(t) => OrderingTerm.asc(t.creadaEn)])).get();
    final fotos = await _bd.select(_bd.fotosCola).get();
    return [
      for (final f in files)
        Aportacio(
          id: f.id,
          variableId: f.variableId,
          titol: f.titol,
          creadaEn: f.creadaEn,
          categoriaId: f.categoriaId,
          textLliure: f.textLliure,
          descripcio: f.descripcio,
          geom: f.geomJson == null ? null : jsonDecode(f.geomJson!) as Map<String, dynamic>,
          puntParcela: f.parcelaLat == null ? null : LatLng(f.parcelaLat!, f.parcelaLng!),
          recinteRef: f.recinteRef,
          recinteDnPk: f.recinteDnPk,
          estat: f.error == null ? EstatCola.pendent : EstatCola.error,
          error: f.error,
          fotos: [for (final x in fotos) if (x.aportacioId == f.id) x.bytes],
          substitueixId: f.substitueixId,
        ),
    ];
  }

  @override
  Future<void> afegir(Aportacio a) => _bd.transaction(() async {
        await _bd.into(_bd.aportacionsCola).insert(AportacionsColaCompanion.insert(
              id: a.id,
              variableId: a.variableId,
              titol: a.titol,
              creadaEn: a.creadaEn,
              categoriaId: Value(a.categoriaId),
              textLliure: Value(a.textLliure),
              descripcio: Value(a.descripcio),
              geomJson: Value(a.geom == null ? null : jsonEncode(a.geom)),
              parcelaLat: Value(a.puntParcela?.latitude),
              parcelaLng: Value(a.puntParcela?.longitude),
              recinteRef: Value(a.recinteRef),
              recinteDnPk: Value(a.recinteDnPk),
              substitueixId: Value(a.substitueixId),
            ));
        for (final f in a.fotos) {
          await _bd.into(_bd.fotosCola).insert(FotosColaCompanion.insert(aportacioId: a.id, bytes: f));
        }
      });

  Future<void> _posarError(String id, String? missatge) =>
      (_bd.update(_bd.aportacionsCola)..where((t) => t.id.equals(id)))
          .write(AportacionsColaCompanion(error: Value(missatge)));

  @override
  Future<void> marcarError(String id, String missatge) => _posarError(id, missatge);

  @override
  Future<void> marcarPendent(String id) => _posarError(id, null);

  @override
  Future<void> esborrar(String id) => _bd.transaction(() async {
        await (_bd.delete(_bd.fotosCola)..where((t) => t.aportacioId.equals(id))).go();
        await (_bd.delete(_bd.aportacionsCola)..where((t) => t.id.equals(id))).go();
      });
}
