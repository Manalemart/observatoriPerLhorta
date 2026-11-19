import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config.dart';
import 'data/local/crear_cola.dart';
import 'data/local/magatzem.dart';
import 'data/remote/api_observatori.dart';
import 'services/avisos.dart';
import 'services/cataleg.dart';
import 'services/paquets.dart';
import 'services/sessio.dart';
import 'services/simbologia.dart';
import 'services/sigpac.dart';
import 'services/sincronitzacio.dart';
import 'ui/capes_mapa.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Licencias de las fuentes (OFL), en la pantalla de licencias
  LicenseRegistry.addLicense(() async* {
    for (final (nom, fitxer) in [('Montserrat', 'OFL-Montserrat.txt'), ('Source Serif 4', 'OFL-SourceSerif4.txt')]) {
      yield LicenseEntryWithLineBreaks([nom], await rootBundle.loadString('assets/fonts/$fitxer'));
    }
  });
  await Supabase.initialize(url: Config.supabaseUrl, publishableKey: Config.supabaseKey);
  final client = Supabase.instance.client;

  final api = ApiObservatori(client);
  final sigpac = Sigpac();
  final sessio = Sessio(client);
  final cataleg = Cataleg(api);
  final avisos = Avisos(api);
  final sincronitzacio = Sincronitzacio(
    cola: crearCola(),
    api: api,
    recinte: sigpac.recinteEnPunt,
    missatgeSenseRecinte: 'Ací no hi ha cap recinte SIGPAC.',
  );
  final clientTeseles = http.Client();
  final paquets = Paquets(
    magatzem: await crearMagatzem(),
    partida: api.fullDeCamp,
    sigpac: sigpac.recintesEnCaixa,
    tesela: (t) => baixarTesela(clientTeseles, t),
  );
  await paquets.carregar();
  final simbologia = await Simbologia.carregar();

  await sincronitzacio.carregar();
  // Al recuperar la red se envía lo pendiente y se recargan las pantallas. Sin sesión no se puede
  void ambXarxa(List<ConnectivityResult> r) {
    if (!r.contains(ConnectivityResult.none) && sessio.entrada) {
      sincronitzacio.xarxaRecuperada();
      avisos.carregar();
    }
  }

  final connectivitat = Connectivity();
  connectivitat.onConnectivityChanged.listen(ambXarxa);
  // iOS suspende la app poco después de salir de ella: si la red vuelve mientras tanto, el aviso
  // de cambio puede no llegar. Al volver a la app se comprueba igualmente (en Android no sobra)
  AppLifecycleListener(onResume: () async => ambXarxa(await connectivitat.checkConnectivity()));
  sessio.addListener(() {
    if (sessio.entrada) {
      cataleg.carregar();
      sincronitzacio.enviar();
      avisos.carregar();
    } else {
      avisos.buidar();
    }
  });
  if (sessio.entrada) {
    cataleg.carregar();
    sincronitzacio.enviar();
    avisos.carregar();
  }

  runApp(MultiProvider(
    providers: [
      Provider.value(value: api),
      Provider.value(value: sigpac),
      Provider.value(value: simbologia),
      ChangeNotifierProvider.value(value: sessio),
      ChangeNotifierProvider.value(value: cataleg),
      ChangeNotifierProvider.value(value: sincronitzacio),
      ChangeNotifierProvider.value(value: paquets),
      ChangeNotifierProvider.value(value: avisos),
    ],
    child: ObservatoriApp(sessio: sessio),
  ));
}
