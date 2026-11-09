import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

const _costatMax = 1600;
const _qualitat = 80;

/// Reduce la foto y la recodifica en JPEG. Pesa menos y, sobre todo, se queda sin EXIF ni
/// GPS: image_picker los conserva aunque redimensione. Decodificar es lento: va en un isolate.
Future<Uint8List> prepararFoto(Uint8List original) => compute(prepararFotoSync, original);

/// Público para los tests. Lanza FormatException si no es una imagen.
Uint8List prepararFotoSync(Uint8List original) {
  final decodificada = img.decodeImage(original);
  if (decodificada == null) throw const FormatException('No és una imatge');
  // Aplica la orientación EXIF a los píxeles antes de descartar los metadatos
  var foto = img.bakeOrientation(decodificada);
  final costat = foto.width > foto.height ? foto.width : foto.height;
  if (costat > _costatMax) {
    foto = foto.width >= foto.height ? img.copyResize(foto, width: _costatMax) : img.copyResize(foto, height: _costatMax);
  }
  foto.exif = img.ExifData();
  return img.encodeJpg(foto, quality: _qualitat);
}
