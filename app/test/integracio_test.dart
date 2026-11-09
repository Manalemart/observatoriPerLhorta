// Contra Supabase local. Se salta si no se le pasan las claves:
//   SUPABASE_KEY=... SUPABASE_SERVICE_KEY=... flutter test test/integracio_test.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart' show expect, isEmpty, isTrue, setUpAll, tearDownAll, test, throwsA, isA, group, equals, hasLength;
import 'package:observatori_horta/data/local/cola.dart';
import 'package:observatori_horta/data/models.dart';
import 'package:observatori_horta/data/remote/api_observatori.dart';
import 'package:observatori_horta/services/sincronitzacio.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient, AdminUserAttributes;
import 'package:uuid/uuid.dart';

const _url = 'http://127.0.0.1:64321';

void main() {
  final clau = Platform.environment['SUPABASE_KEY'];
  final clauServei = Platform.environment['SUPABASE_SERVICE_KEY'];
  final salta = clau == null || clauServei == null ? 'Falten SUPABASE_KEY i SUPABASE_SERVICE_KEY' : null;

  group('Integració', () {
    late SupabaseClient admin;
    late SupabaseClient client;
    late ApiObservatori api;
    late String uid;
    late int variablePunt;

    Map<String, dynamic> fila(String id, {double lng = -0.3585, double lat = 39.4265}) => {
          'id': id,
          'variable_id': variablePunt,
          'geom': {'type': 'Point', 'coordinates': [lng, lat]},
          'origen': 'app',
        };

    setUpAll(() async {
      admin = SupabaseClient(_url, clauServei!);
      client = SupabaseClient(_url, clau!);
      api = ApiObservatori(client);
      const email = 'integracio-app@test.local', contrasenya = 'prova-integracio-app';
      final creat = await admin.auth.admin.createUser(AdminUserAttributes(email: email, password: contrasenya, emailConfirm: true));
      uid = creat.user!.id;
      await client.auth.signInWithPassword(email: email, password: contrasenya);
      final v = await client.from('variables').select('id').eq('geometria', 'punt').limit(1).single();
      variablePunt = v['id'] as int;
    });

    tearDownAll(() async {
      final fotos = await admin.from('element_fotos').select('storage_path').eq('autor_id', uid);
      if (fotos.isNotEmpty) {
        await admin.storage.from('fotos').remove([for (final f in fotos) f['storage_path'] as String]);
      }
      await admin.from('elements').delete().eq('autor_id', uid);
      await admin.auth.admin.deleteUser(uid);
      await client.dispose();
      await admin.dispose();
    });

    test('reenviar el mateix element no el duplica', () async {
      final id = const Uuid().v4();
      await api.inserirElement(fila(id));
      await api.inserirElement(fila(id));
      final files = await client.from('elements').select('id, origen, estat, autor_id').eq('id', id);
      expect(files, hasLength(1));
      expect(files.single['origen'], 'app');
      expect(files.single['estat'], 'pendent');
      expect(files.single['autor_id'], uid);
    });

    test('fora de l\'àmbit: rebuig definitiu, amb el missatge del servidor', () async {
      expect(
        () => api.inserirElement(fila(const Uuid().v4(), lng: 2.0, lat: 41.0)),
        throwsA(isA<RebuigServidor>()),
      );
    });

    test('pujar la mateixa foto dues vegades no falla ni duplica', () async {
      final id = const Uuid().v4();
      await api.inserirElement(fila(id));
      final bytes = Uint8List.fromList(List.filled(32, 7));
      await api.pujarFoto(id, 0, bytes);
      await api.pujarFoto(id, 0, bytes);
      final fotos = await client.from('element_fotos').select('storage_path').eq('element_id', id);
      expect(fotos, hasLength(1));
      expect(fotos.single['storage_path'], equals('$uid/$id/0.jpg'));
    });

    test('la sincronització buida la cua i l\'element apareix en les meues aportacions', () async {
      final id = const Uuid().v4();
      final cola = ColaMemoria();
      final s = Sincronitzacio(cola: cola, api: api, recinte: (_) async => null, missatgeSenseRecinte: 'x');
      await s.afegir(Aportacio(
        id: id,
        variableId: variablePunt,
        titol: 'Prova',
        creadaEn: DateTime.now(),
        geom: {'type': 'Point', 'coordinates': [-0.3585, 39.4265]},
        fotos: [Uint8List.fromList(List.filled(16, 1))],
      ));
      expect(await cola.totes(), isEmpty);
      expect((await api.lesMeues()).any((a) => a.id == id), isTrue);
    });
  }, skip: salta);
}
