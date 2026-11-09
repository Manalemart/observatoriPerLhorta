// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cola_drift.dart';

// ignore_for_file: type=lint
class $AportacionsColaTable extends AportacionsCola
    with TableInfo<$AportacionsColaTable, AportacionsColaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AportacionsColaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _variableIdMeta = const VerificationMeta(
    'variableId',
  );
  @override
  late final GeneratedColumn<int> variableId = GeneratedColumn<int>(
    'variable_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titolMeta = const VerificationMeta('titol');
  @override
  late final GeneratedColumn<String> titol = GeneratedColumn<String>(
    'titol',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _creadaEnMeta = const VerificationMeta(
    'creadaEn',
  );
  @override
  late final GeneratedColumn<DateTime> creadaEn = GeneratedColumn<DateTime>(
    'creada_en',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoriaIdMeta = const VerificationMeta(
    'categoriaId',
  );
  @override
  late final GeneratedColumn<int> categoriaId = GeneratedColumn<int>(
    'categoria_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _textLliureMeta = const VerificationMeta(
    'textLliure',
  );
  @override
  late final GeneratedColumn<String> textLliure = GeneratedColumn<String>(
    'text_lliure',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _descripcioMeta = const VerificationMeta(
    'descripcio',
  );
  @override
  late final GeneratedColumn<String> descripcio = GeneratedColumn<String>(
    'descripcio',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _geomJsonMeta = const VerificationMeta(
    'geomJson',
  );
  @override
  late final GeneratedColumn<String> geomJson = GeneratedColumn<String>(
    'geom_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _parcelaLatMeta = const VerificationMeta(
    'parcelaLat',
  );
  @override
  late final GeneratedColumn<double> parcelaLat = GeneratedColumn<double>(
    'parcela_lat',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _parcelaLngMeta = const VerificationMeta(
    'parcelaLng',
  );
  @override
  late final GeneratedColumn<double> parcelaLng = GeneratedColumn<double>(
    'parcela_lng',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recinteRefMeta = const VerificationMeta(
    'recinteRef',
  );
  @override
  late final GeneratedColumn<String> recinteRef = GeneratedColumn<String>(
    'recinte_ref',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recinteDnPkMeta = const VerificationMeta(
    'recinteDnPk',
  );
  @override
  late final GeneratedColumn<int> recinteDnPk = GeneratedColumn<int>(
    'recinte_dn_pk',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _errorMeta = const VerificationMeta('error');
  @override
  late final GeneratedColumn<String> error = GeneratedColumn<String>(
    'error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    variableId,
    titol,
    creadaEn,
    categoriaId,
    textLliure,
    descripcio,
    geomJson,
    parcelaLat,
    parcelaLng,
    recinteRef,
    recinteDnPk,
    error,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'aportacions_cola';
  @override
  VerificationContext validateIntegrity(
    Insertable<AportacionsColaData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('variable_id')) {
      context.handle(
        _variableIdMeta,
        variableId.isAcceptableOrUnknown(data['variable_id']!, _variableIdMeta),
      );
    } else if (isInserting) {
      context.missing(_variableIdMeta);
    }
    if (data.containsKey('titol')) {
      context.handle(
        _titolMeta,
        titol.isAcceptableOrUnknown(data['titol']!, _titolMeta),
      );
    } else if (isInserting) {
      context.missing(_titolMeta);
    }
    if (data.containsKey('creada_en')) {
      context.handle(
        _creadaEnMeta,
        creadaEn.isAcceptableOrUnknown(data['creada_en']!, _creadaEnMeta),
      );
    } else if (isInserting) {
      context.missing(_creadaEnMeta);
    }
    if (data.containsKey('categoria_id')) {
      context.handle(
        _categoriaIdMeta,
        categoriaId.isAcceptableOrUnknown(
          data['categoria_id']!,
          _categoriaIdMeta,
        ),
      );
    }
    if (data.containsKey('text_lliure')) {
      context.handle(
        _textLliureMeta,
        textLliure.isAcceptableOrUnknown(data['text_lliure']!, _textLliureMeta),
      );
    }
    if (data.containsKey('descripcio')) {
      context.handle(
        _descripcioMeta,
        descripcio.isAcceptableOrUnknown(data['descripcio']!, _descripcioMeta),
      );
    }
    if (data.containsKey('geom_json')) {
      context.handle(
        _geomJsonMeta,
        geomJson.isAcceptableOrUnknown(data['geom_json']!, _geomJsonMeta),
      );
    }
    if (data.containsKey('parcela_lat')) {
      context.handle(
        _parcelaLatMeta,
        parcelaLat.isAcceptableOrUnknown(data['parcela_lat']!, _parcelaLatMeta),
      );
    }
    if (data.containsKey('parcela_lng')) {
      context.handle(
        _parcelaLngMeta,
        parcelaLng.isAcceptableOrUnknown(data['parcela_lng']!, _parcelaLngMeta),
      );
    }
    if (data.containsKey('recinte_ref')) {
      context.handle(
        _recinteRefMeta,
        recinteRef.isAcceptableOrUnknown(data['recinte_ref']!, _recinteRefMeta),
      );
    }
    if (data.containsKey('recinte_dn_pk')) {
      context.handle(
        _recinteDnPkMeta,
        recinteDnPk.isAcceptableOrUnknown(
          data['recinte_dn_pk']!,
          _recinteDnPkMeta,
        ),
      );
    }
    if (data.containsKey('error')) {
      context.handle(
        _errorMeta,
        error.isAcceptableOrUnknown(data['error']!, _errorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AportacionsColaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AportacionsColaData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      variableId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}variable_id'],
      )!,
      titol: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}titol'],
      )!,
      creadaEn: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}creada_en'],
      )!,
      categoriaId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}categoria_id'],
      ),
      textLliure: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text_lliure'],
      ),
      descripcio: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}descripcio'],
      ),
      geomJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}geom_json'],
      ),
      parcelaLat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}parcela_lat'],
      ),
      parcelaLng: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}parcela_lng'],
      ),
      recinteRef: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recinte_ref'],
      ),
      recinteDnPk: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}recinte_dn_pk'],
      ),
      error: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error'],
      ),
    );
  }

  @override
  $AportacionsColaTable createAlias(String alias) {
    return $AportacionsColaTable(attachedDatabase, alias);
  }
}

class AportacionsColaData extends DataClass
    implements Insertable<AportacionsColaData> {
  final String id;
  final int variableId;
  final String titol;
  final DateTime creadaEn;
  final int? categoriaId;
  final String? textLliure;
  final String? descripcio;
  final String? geomJson;
  final double? parcelaLat;
  final double? parcelaLng;
  final String? recinteRef;
  final int? recinteDnPk;
  final String? error;
  const AportacionsColaData({
    required this.id,
    required this.variableId,
    required this.titol,
    required this.creadaEn,
    this.categoriaId,
    this.textLliure,
    this.descripcio,
    this.geomJson,
    this.parcelaLat,
    this.parcelaLng,
    this.recinteRef,
    this.recinteDnPk,
    this.error,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['variable_id'] = Variable<int>(variableId);
    map['titol'] = Variable<String>(titol);
    map['creada_en'] = Variable<DateTime>(creadaEn);
    if (!nullToAbsent || categoriaId != null) {
      map['categoria_id'] = Variable<int>(categoriaId);
    }
    if (!nullToAbsent || textLliure != null) {
      map['text_lliure'] = Variable<String>(textLliure);
    }
    if (!nullToAbsent || descripcio != null) {
      map['descripcio'] = Variable<String>(descripcio);
    }
    if (!nullToAbsent || geomJson != null) {
      map['geom_json'] = Variable<String>(geomJson);
    }
    if (!nullToAbsent || parcelaLat != null) {
      map['parcela_lat'] = Variable<double>(parcelaLat);
    }
    if (!nullToAbsent || parcelaLng != null) {
      map['parcela_lng'] = Variable<double>(parcelaLng);
    }
    if (!nullToAbsent || recinteRef != null) {
      map['recinte_ref'] = Variable<String>(recinteRef);
    }
    if (!nullToAbsent || recinteDnPk != null) {
      map['recinte_dn_pk'] = Variable<int>(recinteDnPk);
    }
    if (!nullToAbsent || error != null) {
      map['error'] = Variable<String>(error);
    }
    return map;
  }

  AportacionsColaCompanion toCompanion(bool nullToAbsent) {
    return AportacionsColaCompanion(
      id: Value(id),
      variableId: Value(variableId),
      titol: Value(titol),
      creadaEn: Value(creadaEn),
      categoriaId: categoriaId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoriaId),
      textLliure: textLliure == null && nullToAbsent
          ? const Value.absent()
          : Value(textLliure),
      descripcio: descripcio == null && nullToAbsent
          ? const Value.absent()
          : Value(descripcio),
      geomJson: geomJson == null && nullToAbsent
          ? const Value.absent()
          : Value(geomJson),
      parcelaLat: parcelaLat == null && nullToAbsent
          ? const Value.absent()
          : Value(parcelaLat),
      parcelaLng: parcelaLng == null && nullToAbsent
          ? const Value.absent()
          : Value(parcelaLng),
      recinteRef: recinteRef == null && nullToAbsent
          ? const Value.absent()
          : Value(recinteRef),
      recinteDnPk: recinteDnPk == null && nullToAbsent
          ? const Value.absent()
          : Value(recinteDnPk),
      error: error == null && nullToAbsent
          ? const Value.absent()
          : Value(error),
    );
  }

  factory AportacionsColaData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AportacionsColaData(
      id: serializer.fromJson<String>(json['id']),
      variableId: serializer.fromJson<int>(json['variableId']),
      titol: serializer.fromJson<String>(json['titol']),
      creadaEn: serializer.fromJson<DateTime>(json['creadaEn']),
      categoriaId: serializer.fromJson<int?>(json['categoriaId']),
      textLliure: serializer.fromJson<String?>(json['textLliure']),
      descripcio: serializer.fromJson<String?>(json['descripcio']),
      geomJson: serializer.fromJson<String?>(json['geomJson']),
      parcelaLat: serializer.fromJson<double?>(json['parcelaLat']),
      parcelaLng: serializer.fromJson<double?>(json['parcelaLng']),
      recinteRef: serializer.fromJson<String?>(json['recinteRef']),
      recinteDnPk: serializer.fromJson<int?>(json['recinteDnPk']),
      error: serializer.fromJson<String?>(json['error']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'variableId': serializer.toJson<int>(variableId),
      'titol': serializer.toJson<String>(titol),
      'creadaEn': serializer.toJson<DateTime>(creadaEn),
      'categoriaId': serializer.toJson<int?>(categoriaId),
      'textLliure': serializer.toJson<String?>(textLliure),
      'descripcio': serializer.toJson<String?>(descripcio),
      'geomJson': serializer.toJson<String?>(geomJson),
      'parcelaLat': serializer.toJson<double?>(parcelaLat),
      'parcelaLng': serializer.toJson<double?>(parcelaLng),
      'recinteRef': serializer.toJson<String?>(recinteRef),
      'recinteDnPk': serializer.toJson<int?>(recinteDnPk),
      'error': serializer.toJson<String?>(error),
    };
  }

  AportacionsColaData copyWith({
    String? id,
    int? variableId,
    String? titol,
    DateTime? creadaEn,
    Value<int?> categoriaId = const Value.absent(),
    Value<String?> textLliure = const Value.absent(),
    Value<String?> descripcio = const Value.absent(),
    Value<String?> geomJson = const Value.absent(),
    Value<double?> parcelaLat = const Value.absent(),
    Value<double?> parcelaLng = const Value.absent(),
    Value<String?> recinteRef = const Value.absent(),
    Value<int?> recinteDnPk = const Value.absent(),
    Value<String?> error = const Value.absent(),
  }) => AportacionsColaData(
    id: id ?? this.id,
    variableId: variableId ?? this.variableId,
    titol: titol ?? this.titol,
    creadaEn: creadaEn ?? this.creadaEn,
    categoriaId: categoriaId.present ? categoriaId.value : this.categoriaId,
    textLliure: textLliure.present ? textLliure.value : this.textLliure,
    descripcio: descripcio.present ? descripcio.value : this.descripcio,
    geomJson: geomJson.present ? geomJson.value : this.geomJson,
    parcelaLat: parcelaLat.present ? parcelaLat.value : this.parcelaLat,
    parcelaLng: parcelaLng.present ? parcelaLng.value : this.parcelaLng,
    recinteRef: recinteRef.present ? recinteRef.value : this.recinteRef,
    recinteDnPk: recinteDnPk.present ? recinteDnPk.value : this.recinteDnPk,
    error: error.present ? error.value : this.error,
  );
  AportacionsColaData copyWithCompanion(AportacionsColaCompanion data) {
    return AportacionsColaData(
      id: data.id.present ? data.id.value : this.id,
      variableId: data.variableId.present
          ? data.variableId.value
          : this.variableId,
      titol: data.titol.present ? data.titol.value : this.titol,
      creadaEn: data.creadaEn.present ? data.creadaEn.value : this.creadaEn,
      categoriaId: data.categoriaId.present
          ? data.categoriaId.value
          : this.categoriaId,
      textLliure: data.textLliure.present
          ? data.textLliure.value
          : this.textLliure,
      descripcio: data.descripcio.present
          ? data.descripcio.value
          : this.descripcio,
      geomJson: data.geomJson.present ? data.geomJson.value : this.geomJson,
      parcelaLat: data.parcelaLat.present
          ? data.parcelaLat.value
          : this.parcelaLat,
      parcelaLng: data.parcelaLng.present
          ? data.parcelaLng.value
          : this.parcelaLng,
      recinteRef: data.recinteRef.present
          ? data.recinteRef.value
          : this.recinteRef,
      recinteDnPk: data.recinteDnPk.present
          ? data.recinteDnPk.value
          : this.recinteDnPk,
      error: data.error.present ? data.error.value : this.error,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AportacionsColaData(')
          ..write('id: $id, ')
          ..write('variableId: $variableId, ')
          ..write('titol: $titol, ')
          ..write('creadaEn: $creadaEn, ')
          ..write('categoriaId: $categoriaId, ')
          ..write('textLliure: $textLliure, ')
          ..write('descripcio: $descripcio, ')
          ..write('geomJson: $geomJson, ')
          ..write('parcelaLat: $parcelaLat, ')
          ..write('parcelaLng: $parcelaLng, ')
          ..write('recinteRef: $recinteRef, ')
          ..write('recinteDnPk: $recinteDnPk, ')
          ..write('error: $error')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    variableId,
    titol,
    creadaEn,
    categoriaId,
    textLliure,
    descripcio,
    geomJson,
    parcelaLat,
    parcelaLng,
    recinteRef,
    recinteDnPk,
    error,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AportacionsColaData &&
          other.id == this.id &&
          other.variableId == this.variableId &&
          other.titol == this.titol &&
          other.creadaEn == this.creadaEn &&
          other.categoriaId == this.categoriaId &&
          other.textLliure == this.textLliure &&
          other.descripcio == this.descripcio &&
          other.geomJson == this.geomJson &&
          other.parcelaLat == this.parcelaLat &&
          other.parcelaLng == this.parcelaLng &&
          other.recinteRef == this.recinteRef &&
          other.recinteDnPk == this.recinteDnPk &&
          other.error == this.error);
}

class AportacionsColaCompanion extends UpdateCompanion<AportacionsColaData> {
  final Value<String> id;
  final Value<int> variableId;
  final Value<String> titol;
  final Value<DateTime> creadaEn;
  final Value<int?> categoriaId;
  final Value<String?> textLliure;
  final Value<String?> descripcio;
  final Value<String?> geomJson;
  final Value<double?> parcelaLat;
  final Value<double?> parcelaLng;
  final Value<String?> recinteRef;
  final Value<int?> recinteDnPk;
  final Value<String?> error;
  final Value<int> rowid;
  const AportacionsColaCompanion({
    this.id = const Value.absent(),
    this.variableId = const Value.absent(),
    this.titol = const Value.absent(),
    this.creadaEn = const Value.absent(),
    this.categoriaId = const Value.absent(),
    this.textLliure = const Value.absent(),
    this.descripcio = const Value.absent(),
    this.geomJson = const Value.absent(),
    this.parcelaLat = const Value.absent(),
    this.parcelaLng = const Value.absent(),
    this.recinteRef = const Value.absent(),
    this.recinteDnPk = const Value.absent(),
    this.error = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AportacionsColaCompanion.insert({
    required String id,
    required int variableId,
    required String titol,
    required DateTime creadaEn,
    this.categoriaId = const Value.absent(),
    this.textLliure = const Value.absent(),
    this.descripcio = const Value.absent(),
    this.geomJson = const Value.absent(),
    this.parcelaLat = const Value.absent(),
    this.parcelaLng = const Value.absent(),
    this.recinteRef = const Value.absent(),
    this.recinteDnPk = const Value.absent(),
    this.error = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       variableId = Value(variableId),
       titol = Value(titol),
       creadaEn = Value(creadaEn);
  static Insertable<AportacionsColaData> custom({
    Expression<String>? id,
    Expression<int>? variableId,
    Expression<String>? titol,
    Expression<DateTime>? creadaEn,
    Expression<int>? categoriaId,
    Expression<String>? textLliure,
    Expression<String>? descripcio,
    Expression<String>? geomJson,
    Expression<double>? parcelaLat,
    Expression<double>? parcelaLng,
    Expression<String>? recinteRef,
    Expression<int>? recinteDnPk,
    Expression<String>? error,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (variableId != null) 'variable_id': variableId,
      if (titol != null) 'titol': titol,
      if (creadaEn != null) 'creada_en': creadaEn,
      if (categoriaId != null) 'categoria_id': categoriaId,
      if (textLliure != null) 'text_lliure': textLliure,
      if (descripcio != null) 'descripcio': descripcio,
      if (geomJson != null) 'geom_json': geomJson,
      if (parcelaLat != null) 'parcela_lat': parcelaLat,
      if (parcelaLng != null) 'parcela_lng': parcelaLng,
      if (recinteRef != null) 'recinte_ref': recinteRef,
      if (recinteDnPk != null) 'recinte_dn_pk': recinteDnPk,
      if (error != null) 'error': error,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AportacionsColaCompanion copyWith({
    Value<String>? id,
    Value<int>? variableId,
    Value<String>? titol,
    Value<DateTime>? creadaEn,
    Value<int?>? categoriaId,
    Value<String?>? textLliure,
    Value<String?>? descripcio,
    Value<String?>? geomJson,
    Value<double?>? parcelaLat,
    Value<double?>? parcelaLng,
    Value<String?>? recinteRef,
    Value<int?>? recinteDnPk,
    Value<String?>? error,
    Value<int>? rowid,
  }) {
    return AportacionsColaCompanion(
      id: id ?? this.id,
      variableId: variableId ?? this.variableId,
      titol: titol ?? this.titol,
      creadaEn: creadaEn ?? this.creadaEn,
      categoriaId: categoriaId ?? this.categoriaId,
      textLliure: textLliure ?? this.textLliure,
      descripcio: descripcio ?? this.descripcio,
      geomJson: geomJson ?? this.geomJson,
      parcelaLat: parcelaLat ?? this.parcelaLat,
      parcelaLng: parcelaLng ?? this.parcelaLng,
      recinteRef: recinteRef ?? this.recinteRef,
      recinteDnPk: recinteDnPk ?? this.recinteDnPk,
      error: error ?? this.error,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (variableId.present) {
      map['variable_id'] = Variable<int>(variableId.value);
    }
    if (titol.present) {
      map['titol'] = Variable<String>(titol.value);
    }
    if (creadaEn.present) {
      map['creada_en'] = Variable<DateTime>(creadaEn.value);
    }
    if (categoriaId.present) {
      map['categoria_id'] = Variable<int>(categoriaId.value);
    }
    if (textLliure.present) {
      map['text_lliure'] = Variable<String>(textLliure.value);
    }
    if (descripcio.present) {
      map['descripcio'] = Variable<String>(descripcio.value);
    }
    if (geomJson.present) {
      map['geom_json'] = Variable<String>(geomJson.value);
    }
    if (parcelaLat.present) {
      map['parcela_lat'] = Variable<double>(parcelaLat.value);
    }
    if (parcelaLng.present) {
      map['parcela_lng'] = Variable<double>(parcelaLng.value);
    }
    if (recinteRef.present) {
      map['recinte_ref'] = Variable<String>(recinteRef.value);
    }
    if (recinteDnPk.present) {
      map['recinte_dn_pk'] = Variable<int>(recinteDnPk.value);
    }
    if (error.present) {
      map['error'] = Variable<String>(error.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AportacionsColaCompanion(')
          ..write('id: $id, ')
          ..write('variableId: $variableId, ')
          ..write('titol: $titol, ')
          ..write('creadaEn: $creadaEn, ')
          ..write('categoriaId: $categoriaId, ')
          ..write('textLliure: $textLliure, ')
          ..write('descripcio: $descripcio, ')
          ..write('geomJson: $geomJson, ')
          ..write('parcelaLat: $parcelaLat, ')
          ..write('parcelaLng: $parcelaLng, ')
          ..write('recinteRef: $recinteRef, ')
          ..write('recinteDnPk: $recinteDnPk, ')
          ..write('error: $error, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FotosColaTable extends FotosCola
    with TableInfo<$FotosColaTable, FotosColaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FotosColaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _aportacioIdMeta = const VerificationMeta(
    'aportacioId',
  );
  @override
  late final GeneratedColumn<String> aportacioId = GeneratedColumn<String>(
    'aportacio_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES aportacions_cola (id)',
    ),
  );
  static const VerificationMeta _bytesMeta = const VerificationMeta('bytes');
  @override
  late final GeneratedColumn<Uint8List> bytes = GeneratedColumn<Uint8List>(
    'bytes',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, aportacioId, bytes];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'fotos_cola';
  @override
  VerificationContext validateIntegrity(
    Insertable<FotosColaData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('aportacio_id')) {
      context.handle(
        _aportacioIdMeta,
        aportacioId.isAcceptableOrUnknown(
          data['aportacio_id']!,
          _aportacioIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_aportacioIdMeta);
    }
    if (data.containsKey('bytes')) {
      context.handle(
        _bytesMeta,
        bytes.isAcceptableOrUnknown(data['bytes']!, _bytesMeta),
      );
    } else if (isInserting) {
      context.missing(_bytesMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FotosColaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FotosColaData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      aportacioId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}aportacio_id'],
      )!,
      bytes: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}bytes'],
      )!,
    );
  }

  @override
  $FotosColaTable createAlias(String alias) {
    return $FotosColaTable(attachedDatabase, alias);
  }
}

class FotosColaData extends DataClass implements Insertable<FotosColaData> {
  final int id;
  final String aportacioId;
  final Uint8List bytes;
  const FotosColaData({
    required this.id,
    required this.aportacioId,
    required this.bytes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['aportacio_id'] = Variable<String>(aportacioId);
    map['bytes'] = Variable<Uint8List>(bytes);
    return map;
  }

  FotosColaCompanion toCompanion(bool nullToAbsent) {
    return FotosColaCompanion(
      id: Value(id),
      aportacioId: Value(aportacioId),
      bytes: Value(bytes),
    );
  }

  factory FotosColaData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FotosColaData(
      id: serializer.fromJson<int>(json['id']),
      aportacioId: serializer.fromJson<String>(json['aportacioId']),
      bytes: serializer.fromJson<Uint8List>(json['bytes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'aportacioId': serializer.toJson<String>(aportacioId),
      'bytes': serializer.toJson<Uint8List>(bytes),
    };
  }

  FotosColaData copyWith({int? id, String? aportacioId, Uint8List? bytes}) =>
      FotosColaData(
        id: id ?? this.id,
        aportacioId: aportacioId ?? this.aportacioId,
        bytes: bytes ?? this.bytes,
      );
  FotosColaData copyWithCompanion(FotosColaCompanion data) {
    return FotosColaData(
      id: data.id.present ? data.id.value : this.id,
      aportacioId: data.aportacioId.present
          ? data.aportacioId.value
          : this.aportacioId,
      bytes: data.bytes.present ? data.bytes.value : this.bytes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FotosColaData(')
          ..write('id: $id, ')
          ..write('aportacioId: $aportacioId, ')
          ..write('bytes: $bytes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, aportacioId, $driftBlobEquality.hash(bytes));
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FotosColaData &&
          other.id == this.id &&
          other.aportacioId == this.aportacioId &&
          $driftBlobEquality.equals(other.bytes, this.bytes));
}

class FotosColaCompanion extends UpdateCompanion<FotosColaData> {
  final Value<int> id;
  final Value<String> aportacioId;
  final Value<Uint8List> bytes;
  const FotosColaCompanion({
    this.id = const Value.absent(),
    this.aportacioId = const Value.absent(),
    this.bytes = const Value.absent(),
  });
  FotosColaCompanion.insert({
    this.id = const Value.absent(),
    required String aportacioId,
    required Uint8List bytes,
  }) : aportacioId = Value(aportacioId),
       bytes = Value(bytes);
  static Insertable<FotosColaData> custom({
    Expression<int>? id,
    Expression<String>? aportacioId,
    Expression<Uint8List>? bytes,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (aportacioId != null) 'aportacio_id': aportacioId,
      if (bytes != null) 'bytes': bytes,
    });
  }

  FotosColaCompanion copyWith({
    Value<int>? id,
    Value<String>? aportacioId,
    Value<Uint8List>? bytes,
  }) {
    return FotosColaCompanion(
      id: id ?? this.id,
      aportacioId: aportacioId ?? this.aportacioId,
      bytes: bytes ?? this.bytes,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (aportacioId.present) {
      map['aportacio_id'] = Variable<String>(aportacioId.value);
    }
    if (bytes.present) {
      map['bytes'] = Variable<Uint8List>(bytes.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FotosColaCompanion(')
          ..write('id: $id, ')
          ..write('aportacioId: $aportacioId, ')
          ..write('bytes: $bytes')
          ..write(')'))
        .toString();
  }
}

abstract class _$BdCola extends GeneratedDatabase {
  _$BdCola(QueryExecutor e) : super(e);
  $BdColaManager get managers => $BdColaManager(this);
  late final $AportacionsColaTable aportacionsCola = $AportacionsColaTable(
    this,
  );
  late final $FotosColaTable fotosCola = $FotosColaTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    aportacionsCola,
    fotosCola,
  ];
}

typedef $$AportacionsColaTableCreateCompanionBuilder =
    AportacionsColaCompanion Function({
      required String id,
      required int variableId,
      required String titol,
      required DateTime creadaEn,
      Value<int?> categoriaId,
      Value<String?> textLliure,
      Value<String?> descripcio,
      Value<String?> geomJson,
      Value<double?> parcelaLat,
      Value<double?> parcelaLng,
      Value<String?> recinteRef,
      Value<int?> recinteDnPk,
      Value<String?> error,
      Value<int> rowid,
    });
typedef $$AportacionsColaTableUpdateCompanionBuilder =
    AportacionsColaCompanion Function({
      Value<String> id,
      Value<int> variableId,
      Value<String> titol,
      Value<DateTime> creadaEn,
      Value<int?> categoriaId,
      Value<String?> textLliure,
      Value<String?> descripcio,
      Value<String?> geomJson,
      Value<double?> parcelaLat,
      Value<double?> parcelaLng,
      Value<String?> recinteRef,
      Value<int?> recinteDnPk,
      Value<String?> error,
      Value<int> rowid,
    });

final class $$AportacionsColaTableReferences
    extends
        BaseReferences<_$BdCola, $AportacionsColaTable, AportacionsColaData> {
  $$AportacionsColaTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$FotosColaTable, List<FotosColaData>>
  _fotosColaRefsTable(_$BdCola db) => MultiTypedResultKey.fromTable(
    db.fotosCola,
    aliasName: $_aliasNameGenerator(
      db.aportacionsCola.id,
      db.fotosCola.aportacioId,
    ),
  );

  $$FotosColaTableProcessedTableManager get fotosColaRefs {
    final manager = $$FotosColaTableTableManager(
      $_db,
      $_db.fotosCola,
    ).filter((f) => f.aportacioId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_fotosColaRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AportacionsColaTableFilterComposer
    extends Composer<_$BdCola, $AportacionsColaTable> {
  $$AportacionsColaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get variableId => $composableBuilder(
    column: $table.variableId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get titol => $composableBuilder(
    column: $table.titol,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get creadaEn => $composableBuilder(
    column: $table.creadaEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get categoriaId => $composableBuilder(
    column: $table.categoriaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get textLliure => $composableBuilder(
    column: $table.textLliure,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get descripcio => $composableBuilder(
    column: $table.descripcio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get geomJson => $composableBuilder(
    column: $table.geomJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get parcelaLat => $composableBuilder(
    column: $table.parcelaLat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get parcelaLng => $composableBuilder(
    column: $table.parcelaLng,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recinteRef => $composableBuilder(
    column: $table.recinteRef,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get recinteDnPk => $composableBuilder(
    column: $table.recinteDnPk,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get error => $composableBuilder(
    column: $table.error,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> fotosColaRefs(
    Expression<bool> Function($$FotosColaTableFilterComposer f) f,
  ) {
    final $$FotosColaTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.fotosCola,
      getReferencedColumn: (t) => t.aportacioId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FotosColaTableFilterComposer(
            $db: $db,
            $table: $db.fotosCola,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AportacionsColaTableOrderingComposer
    extends Composer<_$BdCola, $AportacionsColaTable> {
  $$AportacionsColaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get variableId => $composableBuilder(
    column: $table.variableId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get titol => $composableBuilder(
    column: $table.titol,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get creadaEn => $composableBuilder(
    column: $table.creadaEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get categoriaId => $composableBuilder(
    column: $table.categoriaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get textLliure => $composableBuilder(
    column: $table.textLliure,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get descripcio => $composableBuilder(
    column: $table.descripcio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get geomJson => $composableBuilder(
    column: $table.geomJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get parcelaLat => $composableBuilder(
    column: $table.parcelaLat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get parcelaLng => $composableBuilder(
    column: $table.parcelaLng,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recinteRef => $composableBuilder(
    column: $table.recinteRef,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get recinteDnPk => $composableBuilder(
    column: $table.recinteDnPk,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get error => $composableBuilder(
    column: $table.error,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AportacionsColaTableAnnotationComposer
    extends Composer<_$BdCola, $AportacionsColaTable> {
  $$AportacionsColaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get variableId => $composableBuilder(
    column: $table.variableId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get titol =>
      $composableBuilder(column: $table.titol, builder: (column) => column);

  GeneratedColumn<DateTime> get creadaEn =>
      $composableBuilder(column: $table.creadaEn, builder: (column) => column);

  GeneratedColumn<int> get categoriaId => $composableBuilder(
    column: $table.categoriaId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get textLliure => $composableBuilder(
    column: $table.textLliure,
    builder: (column) => column,
  );

  GeneratedColumn<String> get descripcio => $composableBuilder(
    column: $table.descripcio,
    builder: (column) => column,
  );

  GeneratedColumn<String> get geomJson =>
      $composableBuilder(column: $table.geomJson, builder: (column) => column);

  GeneratedColumn<double> get parcelaLat => $composableBuilder(
    column: $table.parcelaLat,
    builder: (column) => column,
  );

  GeneratedColumn<double> get parcelaLng => $composableBuilder(
    column: $table.parcelaLng,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recinteRef => $composableBuilder(
    column: $table.recinteRef,
    builder: (column) => column,
  );

  GeneratedColumn<int> get recinteDnPk => $composableBuilder(
    column: $table.recinteDnPk,
    builder: (column) => column,
  );

  GeneratedColumn<String> get error =>
      $composableBuilder(column: $table.error, builder: (column) => column);

  Expression<T> fotosColaRefs<T extends Object>(
    Expression<T> Function($$FotosColaTableAnnotationComposer a) f,
  ) {
    final $$FotosColaTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.fotosCola,
      getReferencedColumn: (t) => t.aportacioId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FotosColaTableAnnotationComposer(
            $db: $db,
            $table: $db.fotosCola,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AportacionsColaTableTableManager
    extends
        RootTableManager<
          _$BdCola,
          $AportacionsColaTable,
          AportacionsColaData,
          $$AportacionsColaTableFilterComposer,
          $$AportacionsColaTableOrderingComposer,
          $$AportacionsColaTableAnnotationComposer,
          $$AportacionsColaTableCreateCompanionBuilder,
          $$AportacionsColaTableUpdateCompanionBuilder,
          (AportacionsColaData, $$AportacionsColaTableReferences),
          AportacionsColaData,
          PrefetchHooks Function({bool fotosColaRefs})
        > {
  $$AportacionsColaTableTableManager(_$BdCola db, $AportacionsColaTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AportacionsColaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AportacionsColaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AportacionsColaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> variableId = const Value.absent(),
                Value<String> titol = const Value.absent(),
                Value<DateTime> creadaEn = const Value.absent(),
                Value<int?> categoriaId = const Value.absent(),
                Value<String?> textLliure = const Value.absent(),
                Value<String?> descripcio = const Value.absent(),
                Value<String?> geomJson = const Value.absent(),
                Value<double?> parcelaLat = const Value.absent(),
                Value<double?> parcelaLng = const Value.absent(),
                Value<String?> recinteRef = const Value.absent(),
                Value<int?> recinteDnPk = const Value.absent(),
                Value<String?> error = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AportacionsColaCompanion(
                id: id,
                variableId: variableId,
                titol: titol,
                creadaEn: creadaEn,
                categoriaId: categoriaId,
                textLliure: textLliure,
                descripcio: descripcio,
                geomJson: geomJson,
                parcelaLat: parcelaLat,
                parcelaLng: parcelaLng,
                recinteRef: recinteRef,
                recinteDnPk: recinteDnPk,
                error: error,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int variableId,
                required String titol,
                required DateTime creadaEn,
                Value<int?> categoriaId = const Value.absent(),
                Value<String?> textLliure = const Value.absent(),
                Value<String?> descripcio = const Value.absent(),
                Value<String?> geomJson = const Value.absent(),
                Value<double?> parcelaLat = const Value.absent(),
                Value<double?> parcelaLng = const Value.absent(),
                Value<String?> recinteRef = const Value.absent(),
                Value<int?> recinteDnPk = const Value.absent(),
                Value<String?> error = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AportacionsColaCompanion.insert(
                id: id,
                variableId: variableId,
                titol: titol,
                creadaEn: creadaEn,
                categoriaId: categoriaId,
                textLliure: textLliure,
                descripcio: descripcio,
                geomJson: geomJson,
                parcelaLat: parcelaLat,
                parcelaLng: parcelaLng,
                recinteRef: recinteRef,
                recinteDnPk: recinteDnPk,
                error: error,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AportacionsColaTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({fotosColaRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (fotosColaRefs) db.fotosCola],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (fotosColaRefs)
                    await $_getPrefetchedData<
                      AportacionsColaData,
                      $AportacionsColaTable,
                      FotosColaData
                    >(
                      currentTable: table,
                      referencedTable: $$AportacionsColaTableReferences
                          ._fotosColaRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$AportacionsColaTableReferences(
                            db,
                            table,
                            p0,
                          ).fotosColaRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.aportacioId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$AportacionsColaTableProcessedTableManager =
    ProcessedTableManager<
      _$BdCola,
      $AportacionsColaTable,
      AportacionsColaData,
      $$AportacionsColaTableFilterComposer,
      $$AportacionsColaTableOrderingComposer,
      $$AportacionsColaTableAnnotationComposer,
      $$AportacionsColaTableCreateCompanionBuilder,
      $$AportacionsColaTableUpdateCompanionBuilder,
      (AportacionsColaData, $$AportacionsColaTableReferences),
      AportacionsColaData,
      PrefetchHooks Function({bool fotosColaRefs})
    >;
typedef $$FotosColaTableCreateCompanionBuilder =
    FotosColaCompanion Function({
      Value<int> id,
      required String aportacioId,
      required Uint8List bytes,
    });
typedef $$FotosColaTableUpdateCompanionBuilder =
    FotosColaCompanion Function({
      Value<int> id,
      Value<String> aportacioId,
      Value<Uint8List> bytes,
    });

final class $$FotosColaTableReferences
    extends BaseReferences<_$BdCola, $FotosColaTable, FotosColaData> {
  $$FotosColaTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AportacionsColaTable _aportacioIdTable(_$BdCola db) =>
      db.aportacionsCola.createAlias(
        $_aliasNameGenerator(db.fotosCola.aportacioId, db.aportacionsCola.id),
      );

  $$AportacionsColaTableProcessedTableManager get aportacioId {
    final $_column = $_itemColumn<String>('aportacio_id')!;

    final manager = $$AportacionsColaTableTableManager(
      $_db,
      $_db.aportacionsCola,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_aportacioIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$FotosColaTableFilterComposer
    extends Composer<_$BdCola, $FotosColaTable> {
  $$FotosColaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get bytes => $composableBuilder(
    column: $table.bytes,
    builder: (column) => ColumnFilters(column),
  );

  $$AportacionsColaTableFilterComposer get aportacioId {
    final $$AportacionsColaTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.aportacioId,
      referencedTable: $db.aportacionsCola,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AportacionsColaTableFilterComposer(
            $db: $db,
            $table: $db.aportacionsCola,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FotosColaTableOrderingComposer
    extends Composer<_$BdCola, $FotosColaTable> {
  $$FotosColaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get bytes => $composableBuilder(
    column: $table.bytes,
    builder: (column) => ColumnOrderings(column),
  );

  $$AportacionsColaTableOrderingComposer get aportacioId {
    final $$AportacionsColaTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.aportacioId,
      referencedTable: $db.aportacionsCola,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AportacionsColaTableOrderingComposer(
            $db: $db,
            $table: $db.aportacionsCola,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FotosColaTableAnnotationComposer
    extends Composer<_$BdCola, $FotosColaTable> {
  $$FotosColaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<Uint8List> get bytes =>
      $composableBuilder(column: $table.bytes, builder: (column) => column);

  $$AportacionsColaTableAnnotationComposer get aportacioId {
    final $$AportacionsColaTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.aportacioId,
      referencedTable: $db.aportacionsCola,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AportacionsColaTableAnnotationComposer(
            $db: $db,
            $table: $db.aportacionsCola,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FotosColaTableTableManager
    extends
        RootTableManager<
          _$BdCola,
          $FotosColaTable,
          FotosColaData,
          $$FotosColaTableFilterComposer,
          $$FotosColaTableOrderingComposer,
          $$FotosColaTableAnnotationComposer,
          $$FotosColaTableCreateCompanionBuilder,
          $$FotosColaTableUpdateCompanionBuilder,
          (FotosColaData, $$FotosColaTableReferences),
          FotosColaData,
          PrefetchHooks Function({bool aportacioId})
        > {
  $$FotosColaTableTableManager(_$BdCola db, $FotosColaTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FotosColaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FotosColaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FotosColaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> aportacioId = const Value.absent(),
                Value<Uint8List> bytes = const Value.absent(),
              }) => FotosColaCompanion(
                id: id,
                aportacioId: aportacioId,
                bytes: bytes,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String aportacioId,
                required Uint8List bytes,
              }) => FotosColaCompanion.insert(
                id: id,
                aportacioId: aportacioId,
                bytes: bytes,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$FotosColaTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({aportacioId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (aportacioId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.aportacioId,
                                referencedTable: $$FotosColaTableReferences
                                    ._aportacioIdTable(db),
                                referencedColumn: $$FotosColaTableReferences
                                    ._aportacioIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$FotosColaTableProcessedTableManager =
    ProcessedTableManager<
      _$BdCola,
      $FotosColaTable,
      FotosColaData,
      $$FotosColaTableFilterComposer,
      $$FotosColaTableOrderingComposer,
      $$FotosColaTableAnnotationComposer,
      $$FotosColaTableCreateCompanionBuilder,
      $$FotosColaTableUpdateCompanionBuilder,
      (FotosColaData, $$FotosColaTableReferences),
      FotosColaData,
      PrefetchHooks Function({bool aportacioId})
    >;

class $BdColaManager {
  final _$BdCola _db;
  $BdColaManager(this._db);
  $$AportacionsColaTableTableManager get aportacionsCola =>
      $$AportacionsColaTableTableManager(_db, _db.aportacionsCola);
  $$FotosColaTableTableManager get fotosCola =>
      $$FotosColaTableTableManager(_db, _db.fotosCola);
}
