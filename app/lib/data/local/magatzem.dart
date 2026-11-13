import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';

export 'crear_magatzem_web.dart' if (dart.library.io) 'crear_magatzem_io.dart';

/// Ficheros de los paquetes sin conexión, con rutas relativas («89/partida.json»,
/// «teseles/19/1234/5678.jpg»). En el móvil, una carpeta de la app; en la web (solo vista
/// previa) y en los tests, memoria.
abstract class Magatzem {
  Future<Uint8List?> llegir(String ruta);
  Future<void> escriure(String ruta, Uint8List bytes);
  Future<bool> existeix(String ruta);
  Future<void> esborrar(String ruta);

  /// Para el mapa: tiene que ser síncrono. Null si no está.
  ImageProvider? imatge(String ruta);

  Future<String?> llegirText(String ruta) async {
    final b = await llegir(ruta);
    return b == null ? null : utf8.decode(b);
  }

  Future<void> escriureText(String ruta, String text) => escriure(ruta, Uint8List.fromList(utf8.encode(text)));
}

class MagatzemMemoria extends Magatzem {
  final fitxers = <String, Uint8List>{};

  @override
  Future<Uint8List?> llegir(String ruta) async => fitxers[ruta];

  @override
  Future<void> escriure(String ruta, Uint8List bytes) async => fitxers[ruta] = bytes;

  @override
  Future<bool> existeix(String ruta) async => fitxers.containsKey(ruta);

  @override
  Future<void> esborrar(String ruta) async => fitxers.remove(ruta);

  @override
  ImageProvider? imatge(String ruta) {
    final b = fitxers[ruta];
    return b == null ? null : MemoryImage(b);
  }
}
