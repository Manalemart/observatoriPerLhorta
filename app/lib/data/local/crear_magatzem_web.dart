import 'magatzem.dart';

/// La web es solo vista previa de desarrollo: los paquetes no sobreviven a recargar.
Future<Magatzem> crearMagatzem() async => MagatzemMemoria();
