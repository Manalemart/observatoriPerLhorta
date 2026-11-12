import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:latlong2/latlong.dart';
import 'package:observatori_horta/data/local/cola.dart';
import 'package:observatori_horta/data/local/cola_drift.dart';
import 'package:observatori_horta/data/models.dart';
import 'package:observatori_horta/data/revisio.dart';
import 'package:observatori_horta/data/remote/api_observatori.dart';
import 'package:observatori_horta/services/fotos.dart';
import 'package:observatori_horta/services/sigpac.dart';
import 'package:observatori_horta/services/sincronitzacio.dart';
import 'package:observatori_horta/ui/aportar_screen.dart';

class ApiFalsa implements ApiAportacions {
  final files = <Map<String, dynamic>>[];
  final fotos = <String>[];
  Object? errorInserir;

  @override
  Future<void> inserirElement(Map<String, dynamic> fila) async {
    if (errorInserir != null) throw errorInserir!;
    files.add(fila);
  }

  @override
  Future<void> pujarFoto(String elementId, int index, Uint8List bytes) async => fotos.add('$elementId/$index');
}

Aportacio aportacio(String id, {Map<String, dynamic>? geom, LatLng? parcela, List<Uint8List> fotos = const []}) => Aportacio(
      id: id,
      variableId: 1,
      titol: 'Prova',
      creadaEn: DateTime(2026, 11, 9),
      geom: geom ?? (parcela == null ? {'type': 'Point', 'coordinates': [-0.35, 39.42]} : null),
      puntParcela: parcela,
      fotos: fotos,
    );

const recinteProva = Recinte(ref: '46:900:0:0:001:00001:0001', dnPk: 7, geometria: {'type': 'Polygon', 'coordinates': []});

Sincronitzacio sinc(ColaAportacions c, ApiAportacions a, {CercaRecinte? recinte}) => Sincronitzacio(
      cola: c,
      api: a,
      recinte: recinte ?? (_) async => recinteProva,
      missatgeSenseRecinte: 'sense recinte',
    );

void main() {
  group('Geometria', () {
    const a = LatLng(39.42, -0.35), b = LatLng(39.43, -0.36), c = LatLng(39.44, -0.34);

    test('el GeoJSON va en lon,lat', () {
      expect(geometriaDePunts(GeometriaVariable.punt, [a]), {'type': 'Point', 'coordinates': [-0.35, 39.42]});
    });
    test('falten punts: no hi ha geometria', () {
      expect(geometriaDePunts(GeometriaVariable.punt, []), isNull);
      expect(geometriaDePunts(GeometriaVariable.linia, [a]), isNull);
      expect(geometriaDePunts(GeometriaVariable.poligon, [a, b]), isNull);
    });
    test('el polígon es tanca', () {
      final anell = (geometriaDePunts(GeometriaVariable.poligon, [a, b, c])!['coordinates'] as List).first as List;
      expect(anell.first, anell.last);
      expect(anell.length, 4);
    });
  });

  group('SIGPAC', () {
    Map<String, dynamic> resposta(List<List<num>> anell) => {
          'features': [
            {
              'geometry': {'type': 'Polygon', 'coordinates': [anell]},
              'properties': {'dn_pk': 9, 'provincia': 46, 'municipio': 90, 'agregado': 0, 'zona': 0, 'poligono': 48, 'parcela': 91, 'recinto': 1},
            },
          ],
        };
    const dins = LatLng(39.5, -0.5);
    final quadrat = <List<num>>[[-0.6, 39.4], [-0.4, 39.4], [-0.4, 39.6], [-0.6, 39.6], [-0.6, 39.4]];

    test('referència en format oficial', () {
      expect(triarRecinte(resposta(quadrat), dins)!.ref, '46:090:0:0:048:00091:0001');
    });
    test('un recinte de la caixa que no conté el punt no compta', () {
      expect(triarRecinte(resposta(quadrat), const LatLng(39.7, -0.5)), isNull);
    });
  });

  group('Fotos', () {
    test('redueix a 1600 px i elimina el GPS', () {
      final original = img.Image(width: 3200, height: 1600);
      original.exif.gpsIfd[2] = img.IfdValueRational(39, 1); // GPSLatitude
      original.exif.imageIfd[0x010F] = img.IfdValueAscii('Prova'); // Make
      final ambExif = Uint8List.fromList(img.encodeJpg(original));
      expect(img.decodeJpg(ambExif)!.exif.gpsIfd.isEmpty, isFalse, reason: 'la prova ha de partir d\'una foto amb GPS');

      final eixida = img.decodeJpg(prepararFotoSync(ambExif))!;
      expect(eixida.width, 1600);
      expect(eixida.height, 800);
      expect(eixida.exif.gpsIfd.isEmpty, isTrue);
      expect(eixida.exif.imageIfd.containsKey(0x010F), isFalse);
    });
    test('un fitxer que no és imatge dona error', () {
      expect(() => prepararFotoSync(Uint8List.fromList([1, 2, 3])), throwsFormatException);
    });
  });

  group('Sincronització', () {
    late ColaMemoria cola;
    late ApiFalsa api;

    setUp(() {
      cola = ColaMemoria();
      api = ApiFalsa();
    });

    test('envia l\'element i les fotos, i buida la cua', () async {
      final s = sinc(cola, api);
      await s.afegir(aportacio('a', fotos: [Uint8List(1), Uint8List(1)]));
      expect(api.files.single['id'], 'a');
      expect(api.files.single['origen'], 'app');
      expect(api.fotos, ['a/0', 'a/1']);
      expect(await cola.totes(), isEmpty);
    });

    test('sense xarxa no es perd res i s\'envia en tornar', () async {
      final s = sinc(cola, api);
      api.errorInserir = Exception('sense xarxa');
      await s.afegir(aportacio('a'));
      await s.afegir(aportacio('b'));
      expect(s.pendents, 2);
      expect(api.files, isEmpty);

      api.errorInserir = null;
      await s.enviar();
      expect(api.files.map((f) => f['id']), ['a', 'b']);
      expect(s.pendents, 0);
    });

    test('un rebuig del servidor queda marcat i no bloqueja la resta', () async {
      final s = sinc(cola, api);
      api.errorInserir = RebuigServidor('Fora de l\'àmbit');
      await s.afegir(aportacio('a'));
      expect(s.items.single.estat, EstatCola.error);
      expect(s.items.single.error, 'Fora de l\'àmbit');

      api.errorInserir = null;
      await s.afegir(aportacio('b'));
      expect(api.files.map((f) => f['id']), ['b']);
      expect(s.items.single.id, 'a', reason: 'la rebutjada queda per a decidir');
    });

    test('una parcel·la presa sense xarxa busca el recinte en enviar-se', () async {
      final s = sinc(cola, api);
      await s.afegir(aportacio('a', parcela: const LatLng(39.42, -0.35)));
      expect(api.files.single['sigpac_ref'], recinteProva.ref);
      expect(api.files.single['sigpac_dn_pk'], recinteProva.dnPk);
      expect(api.files.single['geom'], recinteProva.geometria);
    });

    test('si encara no hi ha xarxa per a SIGPAC, la parcel·la espera', () async {
      final s = sinc(cola, api, recinte: (_) => throw Exception('sense xarxa'));
      await s.afegir(aportacio('a', parcela: const LatLng(39.42, -0.35)));
      expect(api.files, isEmpty);
      expect(s.items.single.estat, EstatCola.pendent);
    });

    test('si no hi ha recinte al punt, queda com a error', () async {
      final s = sinc(cola, api, recinte: (_) async => null);
      await s.afegir(aportacio('a', parcela: const LatLng(39.42, -0.35)));
      expect(s.items.single.estat, EstatCola.error);
      expect(s.items.single.error, 'sense recinte');
    });

    test('dos enviaments alhora no dupliquen', () async {
      final s = sinc(cola, api);
      await cola.afegir(aportacio('a'));
      await Future.wait([s.enviar(), s.enviar()]);
      expect(api.files.length, 1);
    });
  });

  group('Cua en SQLite (Drift)', () {
    late BdCola bd;
    late ColaDrift cola;

    setUp(() {
      bd = BdCola(NativeDatabase.memory());
      cola = ColaDrift(bd);
    });
    tearDown(() => bd.close());

    test('guarda i recupera tots els camps', () async {
      await cola.afegir(aportacio('a', fotos: [Uint8List.fromList([1, 2]), Uint8List.fromList([3])]));
      await cola.afegir(aportacio('b', parcela: const LatLng(39.42, -0.35)));
      final [a, b] = await cola.totes();
      expect(a.geom!['type'], 'Point');
      expect(a.fotos.map((f) => f.toList()), [[1, 2], [3]]);
      expect(b.geom, isNull);
      expect(b.puntParcela, const LatLng(39.42, -0.35));
    });

    test('marca errors i esborra amb les fotos', () async {
      await cola.afegir(aportacio('a', fotos: [Uint8List(1)]));
      await cola.marcarError('a', 'motiu');
      expect((await cola.totes()).single.estat, EstatCola.error);
      await cola.marcarPendent('a');
      expect((await cola.totes()).single.estat, EstatCola.pendent);
      await cola.esborrar('a');
      expect(await cola.totes(), isEmpty);
      expect(await bd.select(bd.fotosCola).get(), isEmpty);
    });
  });

  group('Revisió de partida', () {
    Map<String, dynamic> element({String origen = 'legacy_2018', bool perRevisar = true, Map<String, dynamic>? darrera, bool substitucio = false}) => {
          'id': 'e1', 'numero': 12, 'quadre': 'B2', 'tema_id': 1, 'tema': 'Construccions', 'color': '#1f5fb0',
          'variable_id': 7, 'variable': 'Alqueria', 'categoria': 'Mal conservat', 'estat': 'validat', 'origen': origen,
          'per_revisar': perRevisar, 'darrera_revisio': darrera, 'substitucio_pendent': substitucio,
          'geometria': {'type': 'Point', 'coordinates': [-0.35, 39.48]}, 'etiqueta': [-0.35, 39.48],
        };

    test('llegeix número, quadre i etiqueta (lon, lat → LatLng)', () {
      final e = ElementRevisio.fromJson(element());
      expect(e.numero, 12);
      expect(e.quadre, 'B2');
      expect(e.etiqueta, const LatLng(39.48, -0.35));
    });

    test('estat de revisió', () {
      expect(ElementRevisio.fromJson(element()).estatRevisio, EstatRevisio.perRevisar);
      expect(ElementRevisio.fromJson(element(perRevisar: false, darrera: {'resultat': 'igual', 'data': '2026-11-12T10:00:00Z'})).estatRevisio, EstatRevisio.igual);
      expect(ElementRevisio.fromJson(element(perRevisar: false, darrera: {'resultat': 'canviat', 'data': '2026-11-12T10:00:00Z'})).estatRevisio, EstatRevisio.canviat);
      expect(ElementRevisio.fromJson(element(substitucio: true)).estatRevisio, EstatRevisio.canviat);
      expect(ElementRevisio.fromJson(element(origen: 'app', perRevisar: false)).estatRevisio, EstatRevisio.nou);
    });

    test('el progrés només compta el de 2018', () {
      final p = PartidaRevisio.fromJson({
        'partida': {'id': 1, 'nom': 'P', 'municipi': 'M', 'area_ha': 10, 'es_padri': true, 'geometria': {'type': 'Polygon', 'coordinates': []}},
        'elements': [
          element(),
          element(perRevisar: false, darrera: {'resultat': 'igual', 'data': '2026-11-12T10:00:00Z'}),
          element(origen: 'web', perRevisar: false),
        ],
      });
      expect(p.revisables.length, 2);
      expect(p.revisats, 1);
    });

    test('recintes SIGPAC per a dibuixar', () {
      final r = recintesDeResposta({
        'features': [
          {
            'geometry': {'type': 'Polygon', 'coordinates': [[[-0.35, 39.48], [-0.34, 39.48], [-0.34, 39.49], [-0.35, 39.48]]]},
            'properties': {'parcela': 66, 'recinto': 2},
          },
          {'geometry': null, 'properties': {'parcela': 1, 'recinto': 1}},
        ],
      });
      expect(r.length, 1);
      expect(r.first.parcela, 66);
      expect(r.first.anells.first.first, const LatLng(39.48, -0.35));
    });
  });

  test("l'aportació que substitueix envia substitueix_id", () async {
    final api = ApiFalsa();
    final s = Sincronitzacio(cola: ColaMemoria(), api: api, recinte: (_) async => null, missatgeSenseRecinte: '');
    await s.afegir(Aportacio(
      id: 'a1', variableId: 7, titol: 'Alqueria', creadaEn: DateTime(2026),
      geom: const {'type': 'Point', 'coordinates': [-0.35, 39.48]}, substitueixId: 'antic',
    ));
    await s.enviar();
    expect(api.files.single['substitueix_id'], 'antic');
  });
}
