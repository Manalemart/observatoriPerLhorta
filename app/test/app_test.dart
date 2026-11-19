import 'dart:async';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:latlong2/latlong.dart';
import 'package:observatori_horta/data/local/cola.dart';
import 'package:observatori_horta/data/local/cola_drift.dart';
import 'package:observatori_horta/data/local/magatzem.dart';
import 'package:observatori_horta/data/models.dart';
import 'package:observatori_horta/data/revisio.dart';
import 'package:observatori_horta/data/remote/api_observatori.dart';
import 'package:observatori_horta/services/avisos.dart';
import 'package:observatori_horta/services/fotos.dart';
import 'package:observatori_horta/services/paquets.dart';
import 'package:observatori_horta/services/sigpac.dart';
import 'package:observatori_horta/services/sincronitzacio.dart';
import 'package:observatori_horta/ui/aportar_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

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

  final revisions = <String>[];
  Object? errorRevisar;

  final fotosRevisio = <String>[];

  @override
  Future<void> revisarElement(String elementId, String resultat, {String? nota, List<Uint8List> fotos = const [], String? id}) async {
    if (errorRevisar != null) throw errorRevisar!;
    revisions.add('$elementId:$resultat');
    for (var i = 0; i < fotos.length; i++) {
      fotosRevisio.add('$id/$i');
    }
  }
}

RevisioLocal revisio(String id, String element, String resultat, {List<Uint8List> fotos = const []}) => RevisioLocal(
      id: id, elementId: element, partidaId: 89, resultat: resultat, creadaEn: DateTime(2026, 11, 13), fotos: fotos);

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
  test('error del servidor o falta de red: el missatge ha de dir el que passa', () {
    expect(esErrorServidor(const PostgrestException(message: 'no existeix la funció')), isTrue);
    expect(esErrorServidor(RebuigServidor("fora de l'àmbit")), isTrue);
    expect(esErrorServidor(TimeoutException('sense resposta')), isFalse);
    expect(esErrorServidor(Exception('sense xarxa')), isFalse);
  });

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

    test("una revisió sense xarxa es guarda i s'envia en tornar, abans que les aportacions", () async {
      final s = sinc(cola, api);
      api.errorRevisar = Exception('sense xarxa');
      api.errorInserir = Exception('sense xarxa');
      await s.revisar(revisio('r1', 'e1', 'canviat'));
      await s.afegir(aportacio('a'));
      expect(s.pendents, 2);
      expect(s.revisions.single.elementId, 'e1');

      api.errorRevisar = null;
      api.errorInserir = null;
      await s.enviar();
      expect(api.revisions, ['e1:canviat']);
      expect(api.files.single['id'], 'a');
      expect(s.pendents, 0);
      expect(s.revisions, isEmpty);
    });

    test('la revisió envia les seues fotos i el seu id', () async {
      final s = sinc(cola, api);
      await s.revisar(revisio('r1', 'e1', 'igual', fotos: [Uint8List(1), Uint8List(1)]));
      expect(api.fotosRevisio, ['r1/0', 'r1/1']);
    });

    test('una revisió rebutjada queda marcada i no bloqueja', () async {
      final s = sinc(cola, api);
      api.errorRevisar = RebuigServidor('Ja està de baixa');
      await s.revisar(revisio('r1', 'e1', 'no_trobat'));
      expect(s.revisions.single.error, 'Ja està de baixa');
      expect(s.pendents, 0);

      api.errorRevisar = null;
      await s.revisar(revisio('r2', 'e2', 'igual'));
      expect(api.revisions, ['e2:igual']);
      await s.esborrarRevisio('r1');
      expect(s.revisions, isEmpty);
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

    test('revisions: guarda, marca error i esborra', () async {
      await cola.afegirRevisio(revisio('r1', 'e1', 'igual', fotos: [Uint8List.fromList([7, 8])]));
      final r = (await cola.revisions()).single;
      expect([r.elementId, r.partidaId, r.resultat], ['e1', 89, 'igual']);
      expect(r.fotos.single.toList(), [7, 8]);
      await cola.errorRevisio('r1', 'motiu');
      expect((await cola.revisions()).single.error, 'motiu');
      await cola.esborrarRevisio('r1');
      expect(await cola.revisions(), isEmpty);
      expect(await bd.select(bd.fotosRevisioCola).get(), isEmpty);
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

  test('revisar no espera més del compte si la xarxa va lenta', () async {
    final api = _ApiLenta();
    final s = sinc(ColaMemoria(), api);
    await s.revisar(revisio('r1', 'e1', 'igual'), espera: const Duration(milliseconds: 50));
    // Ha tornat sense enviar-la: queda pendent i l'enviament segueix de fons
    expect(s.pendents, 1);
    api.solta.complete();
    await s.enviar();
    expect(s.pendents, 0);
  });

  test('en tornar la xarxa avisa les pantalles i envia el pendent', () async {
    final api = ApiFalsa()..errorRevisar = Exception('sense xarxa');
    final s = sinc(ColaMemoria(), api);
    await s.revisar(revisio('r1', 'e1', 'igual'));
    expect(s.pendents, 1);
    var avisos = 0;
    s.addListener(() => avisos++);
    final abans = s.reconnexions;
    api.errorRevisar = null;
    await s.xarxaRecuperada();
    expect(s.reconnexions, abans + 1);
    expect(avisos, greaterThan(0));
    expect(api.revisions, ['e1:igual']);
    expect(s.pendents, 0);
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

  group('Paquets sense connexió', () {
    // Un triangle d'uns 1,7 × 2,2 km
    const triangle = {
      'type': 'Polygon',
      'coordinates': [[[-0.36, 39.47], [-0.34, 39.47], [-0.36, 39.49], [-0.36, 39.47]]],
    };
    Map<String, dynamic> fullDeCamp(int id, Map<String, dynamic> geom) => {
          'partida': {'id': id, 'nom': 'Partida $id', 'municipi': 'M', 'area_ha': 10, 'es_padri': true, 'geometria': geom},
          'elements': [
            {
              'id': 'e1', 'numero': 1, 'quadre': 'A1', 'tema_id': 1, 'tema': 'T', 'color': '#1f5fb0', 'variable_id': 7,
              'variable': 'Alqueria', 'categoria': null, 'estat': 'validat', 'origen': 'legacy_2018', 'per_revisar': true,
              'darrera_revisio': null, 'substitucio_pendent': false,
              'geometria': {'type': 'Point', 'coordinates': [-0.355, 39.475]}, 'etiqueta': [-0.355, 39.475],
            },
          ],
        };
    int x19(double lon) => ((lon + 180) / 360 * (1 << 19)).floor();
    Paquets senseXarxa(Magatzem m) => Paquets(
          magatzem: m,
          partida: (_) => throw Exception(),
          sigpac: (_, _, _, _) => throw Exception(),
          tesela: (_) => throw Exception(),
        );

    test('teseles: cobreix la partida amb marge, però no tota la caixa', () {
      final t = teselesDe(triangle, 14, 19);
      expect(t.toSet().length, t.length, reason: 'sense repetides');
      expect(t.map((e) => e.z).toSet(), {14, 15, 16, 17, 18, 19});
      final z19 = t.where((e) => e.z == 19).toList();
      final xs = z19.map((e) => e.x).toList()..sort();
      final ys = z19.map((e) => e.y).toList()..sort();
      expect(xs.first, x19(-0.36) - 1, reason: 'una de marge');
      // La cantonada nord-est de la caixa queda fora del triangle
      expect(z19.any((e) => e.x == xs.last - 2 && e.y == ys.first + 2), isFalse);
      // Molt menys que la caixa sencera
      final caixa = (xs.last - xs.first + 1) * (ys.last - ys.first + 1);
      expect(z19.length, lessThan(caixa * 0.7));
    });

    test('baixa, es llig sense xarxa i esborra només les teseles pròpies', () async {
      final m = MagatzemMemoria();
      const quadratA = {'type': 'Polygon', 'coordinates': [[[-0.350, 39.480], [-0.348, 39.480], [-0.348, 39.482], [-0.350, 39.482], [-0.350, 39.480]]]};
      const quadratB = {'type': 'Polygon', 'coordinates': [[[-0.348, 39.480], [-0.346, 39.480], [-0.346, 39.482], [-0.348, 39.482], [-0.348, 39.480]]]};
      var baixades = 0;
      final paquets = Paquets(
        magatzem: m,
        partida: (id) async => fullDeCamp(id, id == 1 ? quadratA : quadratB),
        sigpac: (w, s, e, n) async => [
          const RecinteDibuix(parcela: 66, recinto: 2, anells: [[LatLng(39.48, -0.35), LatLng(39.481, -0.349), LatLng(39.48, -0.35)]]),
        ],
        tesela: (t) async {
          baixades++;
          return Uint8List.fromList([1, 2, 3]);
        },
      );
      final a = await paquets.preparar(1);
      await paquets.descarregar(a);
      expect(baixades, a.teseles.length);
      expect(paquets.info(1)!.teseles, a.teseles.length);

      final b = await paquets.preparar(2);
      await paquets.descarregar(b);
      final compartides = a.teseles.toSet().intersection(b.teseles.toSet());
      expect(compartides, isNotEmpty);
      expect(baixades, a.teseles.length + b.teseles.length - compartides.length, reason: 'les compartides no es tornen a baixar');

      // Sense xarxa: la partida i el SIGPAC, del mòbil; i l'índex sobreviu a reobrir
      final p = await paquets.partidaLocal(1);
      expect(p!.elements.single.numero, 1);
      expect((await paquets.sigpacLocal(1))!.single.parcela, 66);
      final reoberts = senseXarxa(m);
      await reoberts.carregar();
      expect(reoberts.info(2)!.nom, 'Partida 2');

      final t0 = a.teseles.firstWhere((t) => !compartides.contains(t));
      expect(m.imatge('teseles/${t0.z}/${t0.x}/${t0.y}.jpg'), isNotNull);

      await paquets.esborrar(1);
      expect(paquets.info(1), isNull);
      expect(await paquets.partidaLocal(1), isNull);
      expect(m.imatge('teseles/${t0.z}/${t0.x}/${t0.y}.jpg'), isNull);
      final c = compartides.first;
      expect(m.imatge('teseles/${c.z}/${c.x}/${c.y}.jpg'), isNotNull, reason: 'la partida 2 encara la fa servir');
    });

    test('si fallen teseles, el que ha baixat es queda i es pot completar', () async {
      var falla = true;
      var baixades = 0;
      final paquets = Paquets(
        magatzem: MagatzemMemoria(),
        partida: (id) async => fullDeCamp(id, triangle),
        sigpac: (_, _, _, _) async => const [],
        tesela: (t) async {
          if (falla && t.z == 19 && t.x.isEven) throw Exception('sense xarxa');
          baixades++;
          return Uint8List(1);
        },
        zoomMin: 17,
        espera: Duration.zero,
      );
      final prep = await paquets.preparar(1);
      await expectLater(paquets.descarregar(prep), throwsA(isA<TeselesSenseBaixar>()));
      expect(paquets.info(1), isNull);
      final primeres = baixades;
      falla = false;
      await paquets.descarregar(prep);
      expect(paquets.info(1)!.teseles, prep.teseles.length);
      expect(baixades, prep.teseles.length, reason: 'només es baixen les que faltaven');
      expect(primeres, greaterThan(0));
    });

    test('la llista de partides es guarda per a obrir-la sense xarxa', () async {
      final paquets = senseXarxa(MagatzemMemoria());
      expect(await paquets.llistaPartides(), isNull);
      await paquets.desarLlistaPartides([
        {'partida_id': 89, 'partida': 'Séquia de Picanya', 'municipi': 'Paiporta', 'area_ha': 12.5, 'validats': 30, 'pendents': 2},
      ]);
      expect((await paquets.llistaPartides())!.single.nom, 'Séquia de Picanya');
    });

    test('les revisions pendents es veuen al plànol', () {
      final base = (fullDeCamp(1, triangle)['elements'] as List).single as Map<String, dynamic>;
      final p = PartidaRevisio.fromJson({
        ...fullDeCamp(1, triangle),
        'elements': [for (final id in ['e1', 'e2', 'e3']) {...base, 'id': id}],
      });
      final v = p.ambRevisionsLocals([revisio('r1', 'e1', 'igual'), revisio('r2', 'e2', 'no_trobat')]);
      expect(v.elements.map((e) => e.id), ['e1', 'e3'], reason: 'el que no es troba desapareix');
      expect(v.elements.first.estatRevisio, EstatRevisio.igual);
      expect(v.revisats, 1);
    });
  });

  group('Avisos', () {
    Map<String, dynamic> fila(int id, String accio, {bool llegida = false, String? motiu}) => {
          'id': id, 'element_id': 'e$id', 'accio': accio, 'motiu': motiu, 'llegida': llegida,
          'created_at': '2026-11-14T09:00:00Z',
          'element': {
            'text_lliure': null, 'partida_id': 89,
            'variable': {'nom': 'Alqueria'}, 'partida': {'nom': 'Séquia de Picanya'},
          },
        };

    test('llig l\'element i la partida', () {
      final a = Avis.fromJson(fila(1, 'revisat', motiu: 'no_trobat'));
      expect([a.titol, a.partida, a.partidaId, a.motiu], ['Alqueria', 'Séquia de Picanya', 89, 'no_trobat']);
      expect(a.dePartida, isTrue);
      expect(Avis.fromJson(fila(2, 'validat')).dePartida, isFalse);
      expect(Avis.fromJson({...fila(3, 'validat'), 'element': null}).titol, '', reason: 'sense element visible no peta');
    });

    test("sense xarxa no diu que no n'hi ha: diu que no s'han pogut carregar", () async {
      final api = _ApiAvisosFalsa([fila(1, 'validat')])..error = true;
      final avisos = Avisos(api);
      await avisos.carregar();
      expect([avisos.carregats, avisos.senseConnexio, avisos.items.length], [false, true, 0]);
      api.error = false;
      await avisos.carregar();
      expect([avisos.carregats, avisos.senseConnexio, avisos.items.length], [true, false, 1]);
      api.error = true;
      await avisos.carregar();
      expect([avisos.senseConnexio, avisos.items.length], [true, 1], reason: 'es queda amb els últims');
      avisos.buidar();
      expect([avisos.carregats, avisos.senseConnexio], [false, false]);
    });

    test('compta els no llegits i els marca', () async {
      final api = _ApiAvisosFalsa([fila(1, 'nova_aportacio'), fila(2, 'validat', llegida: true), fila(3, 'revisat')]);
      final avisos = Avisos(api);
      await avisos.carregar();
      expect(avisos.noLlegits, 2);
      await avisos.marcarLlegits(avisos.items);
      expect(api.marcats, [1, 3]);
      expect(avisos.noLlegits, 0);
    });

    test('el resum per correu es llig i es desa', () async {
      final api = _ApiAvisosFalsa([fila(1, 'nova_aportacio')]);
      final avisos = Avisos(api);
      expect(avisos.resumCorreu, isNull, reason: 'abans de carregar no es mostra');
      await avisos.carregar();
      expect(avisos.resumCorreu, isTrue);
      await avisos.canviarResumCorreu(false);
      expect([avisos.resumCorreu, api.resum], [false, false]);
      avisos.buidar();
      expect(avisos.resumCorreu, isNull);
    });

    test('si no es pot desar el resum torna enrere', () async {
      final api = _ApiAvisosFalsa([]);
      final avisos = Avisos(api);
      await avisos.carregar();
      api.error = true;
      await expectLater(avisos.canviarResumCorreu(false), throwsException);
      expect(avisos.resumCorreu, isTrue);
    });

    test('sense la columna a la base de dades no es mostra', () async {
      final api = _ApiAvisosFalsa([fila(1, 'revisat')])..errorResum = true;
      final avisos = Avisos(api);
      await avisos.carregar();
      expect([avisos.noLlegits, avisos.resumCorreu], [1, null]);
    });

    test('sense xarxa es queda amb el que tenia', () async {
      final api = _ApiAvisosFalsa([fila(1, 'nova_aportacio')]);
      final avisos = Avisos(api);
      await avisos.carregar();
      api.error = true;
      await avisos.carregar();
      expect(avisos.noLlegits, 1);
    });
  });
}

class _ApiAvisosFalsa implements ApiAvisos {
  _ApiAvisosFalsa(this.files);

  final List<Map<String, dynamic>> files;
  final marcats = <int>[];
  bool error = false;

  @override
  Future<List<Map<String, dynamic>>> avisos() async {
    if (error) throw Exception('sense xarxa');
    return [for (final f in files) {...f, 'llegida': (f['llegida'] as bool) || marcats.contains(f['id'])}];
  }

  @override
  Future<void> marcarLlegits(List<int> ids) async => marcats.addAll(ids);

  bool resum = true;
  bool errorResum = false;

  @override
  Future<bool> resumCorreu() async {
    if (error || errorResum) throw Exception('sense resum');
    return resum;
  }

  @override
  Future<void> desarResumCorreu(bool valor) async {
    if (error) throw Exception('sense xarxa');
    resum = valor;
  }
}

/// Revisar no acaba fins que es solta: com una connexió que no arriba a fallar
class _ApiLenta extends ApiFalsa {
  final solta = Completer<void>();

  @override
  Future<void> revisarElement(String elementId, String resultat, {String? nota, List<Uint8List> fotos = const [], String? id}) async {
    await solta.future;
    return super.revisarElement(elementId, resultat, nota: nota, fotos: fotos, id: id);
  }
}
