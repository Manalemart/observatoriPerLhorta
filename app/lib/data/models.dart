import 'dart:typed_data';

import 'package:latlong2/latlong.dart';

import '../core/localitzacio.dart';

class Categoria {
  const Categoria({required this.id, required this.nom, this.nomEs, this.nomEn});
  factory Categoria.fromJson(Map<String, dynamic> j) => Categoria(
        id: j['id'] as int,
        nom: j['nom'] as String,
        nomEs: j['nom_es'] as String?,
        nomEn: j['nom_en'] as String?,
      );

  final int id;

  /// En valencià: és la clau (simbologia, exportacions). Per a mostrar, [nomVisible].
  final String nom;
  final String? nomEs;
  final String? nomEn;

  String get nomVisible => nomEnIdioma(nom, nomEs, nomEn);

  Map<String, dynamic> toJson() => {'id': id, 'nom': nom, 'nom_es': nomEs, 'nom_en': nomEn, 'actiu': true};
}

enum GeometriaVariable { punt, linia, poligon, parcela }

class Variable {
  const Variable({
    required this.id,
    required this.nom,
    this.nomEs,
    this.nomEn,
    required this.geometria,
    required this.textLliure,
    required this.categories,
  });

  factory Variable.fromJson(Map<String, dynamic> j) => Variable(
        id: j['id'] as int,
        nom: j['nom'] as String,
        nomEs: j['nom_es'] as String?,
        nomEn: j['nom_en'] as String?,
        geometria: GeometriaVariable.values.byName(j['geometria'] as String),
        textLliure: j['text_lliure'] as bool,
        categories: [
          for (final c in (j['categories'] as List).cast<Map<String, dynamic>>())
            if (c['actiu'] as bool) Categoria.fromJson(c),
        ],
      );

  final int id;
  final String nom;
  final String? nomEs;
  final String? nomEn;
  String get nomVisible => nomEnIdioma(nom, nomEs, nomEn);
  final GeometriaVariable geometria;
  final bool textLliure;
  final List<Categoria> categories;

  Map<String, dynamic> toJson() => {
        'id': id,
        'nom': nom,
        'nom_es': nomEs,
        'nom_en': nomEn,
        'geometria': geometria.name,
        'text_lliure': textLliure,
        'actiu': true,
        'categories': [for (final c in categories) c.toJson()],
      };
}

class Tema {
  const Tema({required this.id, required this.nom, this.nomEs, this.nomEn, required this.color, required this.variables});

  factory Tema.fromJson(Map<String, dynamic> j) => Tema(
        id: j['id'] as int,
        nom: j['nom'] as String,
        nomEs: j['nom_es'] as String?,
        nomEn: j['nom_en'] as String?,
        color: j['color'] as String?,
        variables: [
          for (final v in (j['variables'] as List).cast<Map<String, dynamic>>())
            if (v['actiu'] as bool) Variable.fromJson(v),
        ],
      );

  final int id;
  final String nom;
  final String? nomEs;
  final String? nomEn;
  String get nomVisible => nomEnIdioma(nom, nomEs, nomEn);
  final String? color;
  final List<Variable> variables;

  Map<String, dynamic> toJson() => {
        'id': id,
        'nom': nom,
        'nom_es': nomEs,
        'nom_en': nomEn,
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
    this.descripcio,
  });

  factory AportacioRemota.fromJson(Map<String, dynamic> j) => AportacioRemota(
        id: j['id'] as String,
        titol: (j['text_lliure'] as String?) ?? _nomJson(j['variable'] as Map<String, dynamic>),
        estat: j['estat'] as String,
        creadaEn: DateTime.parse(j['created_at'] as String),
        motiuRebuig: j['motiu_rebuig'] as String?,
        descripcio: j['descripcio'] as String?,
      );

  final String id;
  final String titol;
  final String estat;
  final DateTime creadaEn;
  final String? motiuRebuig;
  final String? descripcio;

  /// Encara no s'ha publicat: qui l'ha feta la pot corregir o retirar.
  bool get editable => estat != 'validat';
}

/// «Igual / Ha canviat / No el trobe» hecho en el campo: se guarda en el móvil y se envía
/// con `revisar_element()` al recuperar la red.
class RevisioLocal {
  const RevisioLocal({
    required this.id,
    required this.elementId,
    required this.partidaId,
    required this.resultat,
    required this.creadaEn,
    this.nota,
    this.error,
    this.fotos = const [],
  });

  final String id;
  final String elementId;
  final int partidaId;

  /// igual, canviat o no_trobat
  final String resultat;
  final DateTime creadaEn;
  final String? nota;
  final String? error;

  /// Ya reducidas y sin GPS (prepararFoto). Se suben antes de revisar_element().
  final List<Uint8List> fotos;
}

/// Un lloc del buscador del mapa (cercar_llocs): municipi o partida, amb la seua caixa.
class Lloc {
  const Lloc({
    required this.tipus,
    required this.id,
    required this.nom,
    this.municipi,
    required this.oest,
    required this.sud,
    required this.est,
    required this.nord,
  });

  factory Lloc.fromJson(Map<String, dynamic> j) => Lloc(
        tipus: j['tipus'] as String,
        id: j['id'] as int,
        nom: j['nom'] as String,
        municipi: j['municipi'] as String?,
        oest: (j['oest'] as num).toDouble(),
        sud: (j['sud'] as num).toDouble(),
        est: (j['est'] as num).toDouble(),
        nord: (j['nord'] as num).toDouble(),
      );

  /// 'municipi' | 'partida'
  final String tipus;
  final int id;
  final String nom;
  final String? municipi;
  final double oest, sud, est, nord;

  bool get esMunicipi => tipus == 'municipi';
}

/// El nom d'una fila del catàleg ({nom, nom_es, nom_en}) en l'idioma actual.
String _nomJson(Map<String, dynamic> j) => nomEnIdioma(j['nom'] as String, j['nom_es'] as String?, j['nom_en'] as String?);

/// Igual, per a qui el necessite fora d'este fitxer (avisos).
String nomCatalegJson(Map<String, dynamic>? j) => j == null ? '' : _nomJson(j);
