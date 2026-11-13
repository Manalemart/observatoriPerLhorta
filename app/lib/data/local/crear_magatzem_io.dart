import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

import 'magatzem.dart';

Future<Magatzem> crearMagatzem() async {
  // Soporte de la app (no caché): el sistema no lo borra cuando le falta espacio
  final base = await getApplicationSupportDirectory();
  return MagatzemDisc(Directory('${base.path}/paquets'));
}

class MagatzemDisc extends Magatzem {
  MagatzemDisc(this.arrel);

  final Directory arrel;

  File _f(String ruta) => File('${arrel.path}/$ruta');

  @override
  Future<Uint8List?> llegir(String ruta) async {
    final f = _f(ruta);
    return await f.exists() ? f.readAsBytes() : null;
  }

  @override
  Future<void> escriure(String ruta, Uint8List bytes) async {
    final f = _f(ruta);
    await f.parent.create(recursive: true);
    // Primero a un temporal: un corte a medias no deja un fichero roto
    final tmp = File('${f.path}.tmp');
    await tmp.writeAsBytes(bytes, flush: true);
    await tmp.rename(f.path);
  }

  @override
  Future<bool> existeix(String ruta) => _f(ruta).exists();

  @override
  Future<void> esborrar(String ruta) async {
    final f = _f(ruta);
    if (await f.exists()) await f.delete();
  }

  @override
  ImageProvider? imatge(String ruta) {
    final f = _f(ruta);
    return f.existsSync() ? FileImage(f) : null;
  }
}
