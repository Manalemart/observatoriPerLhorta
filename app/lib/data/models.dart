import 'dart:typed_data';

import 'package:latlong2/latlong.dart';

class Categoria {
  const Categoria({required this.id, required this.nom});
  factory Categoria.fromJson(Map<String, dynamic> j) => Categoria(id: j['id'] as int, nom: j['nom'] as String);

  final int id;
  final String nom;

  Map<String, dynamic> toJson() => {'id': id, 'nom': nom, 'actiu': true};
}

enum GeometriaVariable { punt, linia, poligon, parcela }

class Variable {
  const Variable({
    required this.id,
    required this.nom,
    required this.geometria,
    required this.textLliure,
    required this.categories,
  });

  factory Variable.fromJson(Map<String, dynamic> j) => Variable(
        id: j['id'] as int,
        nom: j['nom'] as String,
        geometria: GeometriaVariable.values.byName(j['geometria'] as String),
        textLliure: j['text_lliure'] as bool,
        categories: [
          for (final c in (j['categories'] as List).cast<Map<String, dynamic>>())
            if (c['actiu'] as bool) Categoria.fromJson(c),
        ],
      );

  final int id;
  final String nom;
  final GeometriaVariable geometria;
  final bool textLliure;
  final List<Categoria> categories;

  Map<String, dynamic> toJson() => {
        'id': id,
        'nom': nom,
        'geometria': geometria.name,
        'text_lliure': textLliure,
        'actiu': true,
        'categories': [for (final c in categories) c.toJson()],
      };
}

class Tema {
  const Tema({required this.id, required this.nom, required this.color, required this.variables});

  factory Tema.fromJson(Map<String, dynamic> j) => Tema(
        id: j['id'] as int,
        nom: j['nom'] as String,
        color: j['color'] as String?,
        variables: [
          for (final v in (j['variables'] as List).cast<Map<String, dynamic>>())
            if (v['actiu'] as bool) Variable.fromJson(v),
        ],
      );

  final int id;
  final String nom;
  final String? color;
  final List<Variable> variables;

  Map<String, dynamic> toJson() => {
        'id': id,
        'nom': nom,
        'color': color,
        'variables': [for (final v in variables) v.toJson()],
      };
}

/// Recinto SIGPAC bajo un punto (ver services/sigpac.dart).
class Recinte {
  const Recinte({required this.ref, required this.dnPk, required this.geometria});

  final String ref;
  final int dnPk;
  final Map<String, dynamic> geometria; // GeoJSON Polygon
}

enum EstatCola { pendent, error }

/// Aportación guardada en el móvil hasta que se envía. El id se genera aquí: si la
/// respuesta del servidor se pierde, reintentar con el mismo id no la duplica.
class Aportacio {
  const Aportacio({
    required this.id,
    required this.variableId,
    required this.titol,
    required this.creadaEn,
    this.categoriaId,
    this.textLliure,
    this.descripcio,
    this.geom,
    this.puntParcela,
    this.recinteRef,
    this.recinteDnPk,
    this.estat = EstatCola.pendent,
    this.error,
    this.fotos = const [],
    this.substitueixId,
  });

  final String id;
  final int variableId;

  /// Para mostrarla en la lista sin depender del catálogo.
  final String titol;
  final DateTime creadaEn;
  final int? categoriaId;
  final String? textLliure;
  final String? descripcio;

  /// GeoJSON. Null si es una parcela tomada sin red: se resuelve al enviar, con [puntParcela].
  final Map<String, dynamic>? geom;
  final LatLng? puntParcela;
  final String? recinteRef;
  final int? recinteDnPk;
  final EstatCola estat;
  final String? error;
  final List<Uint8List> fotos;

  /// «Ha canviat» en la revisión: el elemento antiguo que este sustituirá al validarse.
  final String? substitueixId;
}

/// Una aportación ya enviada, tal como la devuelve el servidor.
class AportacioRemota {
  const AportacioRemota({
    required this.id,
    required this.titol,
    required this.estat,
    required this.creadaEn,
    this.motiuRebuig,
  });

  factory AportacioRemota.fromJson(Map<String, dynamic> j) => AportacioRemota(
        id: j['id'] as String,
        titol: (j['text_lliure'] as String?) ?? (j['variable'] as Map<String, dynamic>)['nom'] as String,
        estat: j['estat'] as String,
        creadaEn: DateTime.parse(j['created_at'] as String),
        motiuRebuig: j['motiu_rebuig'] as String?,
      );

  final String id;
  final String titol;
  final String estat;
  final DateTime creadaEn;
  final String? motiuRebuig;
}
