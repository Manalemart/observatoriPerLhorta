import 'package:latlong2/latlong.dart';

import 'models.dart' show RevisioLocal;

/// Una partida apadrinada, como la resume `resum_les_meues_partides()`.
class PartidaApadrinada {
  const PartidaApadrinada({
    required this.id,
    required this.nom,
    required this.municipi,
    required this.areaHa,
    required this.validats,
    required this.pendents,
  });

  factory PartidaApadrinada.fromJson(Map<String, dynamic> j) => PartidaApadrinada(
        id: j['partida_id'] as int,
        nom: j['partida'] as String,
        municipi: j['municipi'] as String,
        areaHa: (j['area_ha'] as num).toDouble(),
        validats: (j['validats'] as num).toInt(),
        pendents: (j['pendents'] as num).toInt(),
      );

  final int id;
  final String nom;
  final String municipi;
  final double areaHa;
  final int validats;
  final int pendents;
}

/// Cómo está un elemento respecto a la revisión del inventario.
enum EstatRevisio {
  /// Del inventario de 2018 y nadie lo ha vuelto a mirar.
  perRevisar,

  /// Confirmado: continúa igual.
  igual,

  /// Ha cambiado: hay (o habrá) una aportación nueva que lo sustituye.
  canviat,

  /// Aportado después de 2018: no forma parte de la revisión.
  nou,
}

/// Un elemento de la partida tal como lo devuelve `full_de_camp()`: con su número y su
/// cuadro, los mismos que en el Full de revisió en papel.
class ElementRevisio {
  const ElementRevisio({
    required this.id,
    required this.numero,
    required this.quadre,
    required this.temaId,
    required this.tema,
    required this.color,
    required this.variableId,
    required this.variable,
    required this.categoria,
    required this.estat,
    required this.origen,
    required this.perRevisar,
    required this.darreraRevisio,
    required this.dataRevisio,
    required this.substitucioPendent,
    required this.geometria,
    required this.etiqueta,
  });

  factory ElementRevisio.fromJson(Map<String, dynamic> j) {
    final d = j['darrera_revisio'] as Map<String, dynamic>?;
    final e = j['etiqueta'] as List;
    return ElementRevisio(
      id: j['id'] as String,
      numero: (j['numero'] as num).toInt(),
      quadre: j['quadre'] as String,
      temaId: j['tema_id'] as int,
      tema: j['tema'] as String,
      color: j['color'] as String?,
      variableId: j['variable_id'] as int,
      variable: j['variable'] as String,
      categoria: j['categoria'] as String?,
      estat: j['estat'] as String,
      origen: j['origen'] as String,
      perRevisar: j['per_revisar'] as bool,
      darreraRevisio: d?['resultat'] as String?,
      dataRevisio: d == null ? null : DateTime.parse(d['data'] as String),
      substitucioPendent: j['substitucio_pendent'] as bool? ?? false,
      geometria: j['geometria'] as Map<String, dynamic>,
      etiqueta: LatLng((e[1] as num).toDouble(), (e[0] as num).toDouble()),
    );
  }

  final String id;
  final int numero;
  final String quadre;
  final int temaId;
  final String tema;
  final String? color;
  final int variableId;
  final String variable;
  final String? categoria;
  final String estat;
  final String origen;
  final bool perRevisar;
  final String? darreraRevisio;
  final DateTime? dataRevisio;
  final bool substitucioPendent;
  final Map<String, dynamic> geometria;
  final LatLng etiqueta;

  bool get del2018 => origen == 'legacy_2018';

  /// Como quedará cuando llegue al servidor una revisión hecha en el campo.
  ElementRevisio ambResultat(String resultat, DateTime data) => ElementRevisio(
        id: id, numero: numero, quadre: quadre, temaId: temaId, tema: tema, color: color,
        variableId: variableId, variable: variable, categoria: categoria, estat: estat, origen: origen,
        perRevisar: false, darreraRevisio: resultat, dataRevisio: data,
        substitucioPendent: substitucioPendent, geometria: geometria, etiqueta: etiqueta,
      );

  /// Solo se revisa lo de 2018 ya validado.
  bool get revisable => del2018 && estat == 'validat';

  EstatRevisio get estatRevisio {
    if (!del2018) return EstatRevisio.nou;
    if (darreraRevisio == 'canviat' || substitucioPendent) return EstatRevisio.canviat;
    if (!perRevisar) return EstatRevisio.igual;
    return EstatRevisio.perRevisar;
  }
}

class PartidaRevisio {
  const PartidaRevisio({
    required this.id,
    required this.nom,
    required this.municipi,
    required this.areaHa,
    required this.esPadri,
    required this.contorn,
    required this.elements,
  });

  factory PartidaRevisio.fromJson(Map<String, dynamic> j) {
    final p = j['partida'] as Map<String, dynamic>;
    return PartidaRevisio(
      id: p['id'] as int,
      nom: p['nom'] as String,
      municipi: p['municipi'] as String,
      areaHa: (p['area_ha'] as num).toDouble(),
      esPadri: p['es_padri'] as bool? ?? false,
      contorn: p['geometria'] as Map<String, dynamic>,
      elements: [
        for (final e in (j['elements'] as List).cast<Map<String, dynamic>>()) ElementRevisio.fromJson(e),
      ],
    );
  }

  final int id;
  final String nom;
  final String municipi;
  final double areaHa;
  final bool esPadri;
  final Map<String, dynamic> contorn;
  final List<ElementRevisio> elements;

  /// Lo que entra en la revisión: lo de 2018 validado.
  Iterable<ElementRevisio> get revisables => elements.where((e) => e.revisable);

  int get revisats => revisables.where((e) => e.estatRevisio != EstatRevisio.perRevisar).length;

  /// Con lo revisado en el campo que aún no ha llegado al servidor. «No el trobe» lo
  /// quita del plano, como hará la baja.
  PartidaRevisio ambRevisionsLocals(Iterable<RevisioLocal> revisions) {
    final per = {for (final r in revisions) r.elementId: r};
    if (per.isEmpty) return this;
    return PartidaRevisio(
      id: id, nom: nom, municipi: municipi, areaHa: areaHa, esPadri: esPadri, contorn: contorn,
      elements: [
        for (final e in elements)
          if (per[e.id] == null)
            e
          else if (per[e.id]!.resultat != 'no_trobat')
            e.ambResultat(per[e.id]!.resultat, per[e.id]!.creadaEn),
      ],
    );
  }
}

/// Para abrir el formulario de aportar desde «Ha canviat»: el nuevo sustituirá al antiguo.
class AportacioSubstitut {
  const AportacioSubstitut({required this.substitueixId, required this.numero, required this.variableId, required this.punt});

  final String substitueixId;
  final int numero;
  final int variableId;
  final LatLng punt;
}

/// Un recinto SIGPAC para dibujar (ver Sigpac.recintesEnCaixa).
class RecinteDibuix {
  const RecinteDibuix({required this.anells, required this.parcela, required this.recinto});

  final List<List<LatLng>> anells;
  final int parcela;
  final int recinto;
}
