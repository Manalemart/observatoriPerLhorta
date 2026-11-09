import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models.dart';

/// Rechazo definitivo del servidor (fuera del ámbito, geometría no válida...): reintentar
/// no sirve. Cualquier otro error se considera transitorio.
class RebuigServidor implements Exception {
  RebuigServidor(this.missatge);
  final String missatge;
}

/// Lo que necesita la sincronización: en los tests se sustituye por un doble.
abstract class ApiAportacions {
  Future<void> inserirElement(Map<String, dynamic> fila);
  Future<void> pujarFoto(String elementId, int index, Uint8List bytes);
}

class ApiObservatori implements ApiAportacions {
  ApiObservatori(this._client);

  final SupabaseClient _client;

  String get _uid => _client.auth.currentUser!.id;

  Future<List<Tema>> cataleg() async {
    final files = await _client
        .from('temes')
        .select('id, nom, color, variables(id, nom, geometria, text_lliure, actiu, categories(id, nom, actiu))')
        .order('ordre', ascending: true)
        .order('nom', ascending: true, referencedTable: 'variables');
    return [for (final f in files) Tema.fromJson(f)];
  }

  Future<List<Map<String, dynamic>>> elementsBbox(double minx, double miny, double maxx, double maxy) async {
    final r = await _client.rpc('elements_bbox', params: {'p_minx': minx, 'p_miny': miny, 'p_maxx': maxx, 'p_maxy': maxy});
    return ((r as Map<String, dynamic>)['features'] as List).cast<Map<String, dynamic>>();
  }

  @override
  Future<void> inserirElement(Map<String, dynamic> fila) async {
    try {
      await _client.from('elements').insert(fila);
    } on PostgrestException catch (e) {
      // Ya estaba: un envío anterior llegó, pero se perdió la respuesta
      if (e.code == '23505') return;
      // Validación del trigger: el mensaje ya viene en valenciano
      if (e.code == '22023') throw RebuigServidor(e.message);
      rethrow;
    }
  }

  @override
  Future<void> pujarFoto(String elementId, int index, Uint8List bytes) async {
    final elementFoto = '$_uid/$elementId/$index.jpg';
    try {
      await _client.storage.from('fotos').uploadBinary(
            elementFoto,
            bytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );
    } on StorageException catch (e) {
      // Ya subida en un intento anterior. Sin upsert: no hay política de UPDATE
      if (e.statusCode != '409' && e.error != 'Duplicate') rethrow;
    }
    await _client.from('element_fotos').upsert(
      {'element_id': elementId, 'storage_path': elementFoto, 'autor_id': _uid},
      onConflict: 'storage_path',
      ignoreDuplicates: true,
    );
  }

  Future<List<AportacioRemota>> lesMeues() async {
    final files = await _client
        .from('elements')
        .select('id, text_lliure, estat, created_at, motiu_rebuig, variable:variables(nom)')
        .eq('autor_id', _uid)
        .order('created_at', ascending: false)
        .limit(100);
    return [for (final f in files) AportacioRemota.fromJson(f)];
  }
}
