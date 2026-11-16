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

  await sincronitzacio.carregar();
  // Al recuperar la red se envía lo pendiente. Sin sesión no se puede: se espera a entrar
  Connectivity().onConnectivityChanged.listen((r) {
    if (!r.contains(ConnectivityResult.none) && sessio.entrada) {
      sincronitzacio.enviar();
      avisos.carregar();
    }
  });
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
      ChangeNotifierProvider.value(value: sessio),
      ChangeNotifierProvider.value(value: cataleg),
      ChangeNotifierProvider.value(value: sincronitzacio),
      ChangeNotifierProvider.value(value: paquets),
      ChangeNotifierProvider.value(value: avisos),
    ],
    child: ObservatoriApp(sessio: sessio),
  ));
}
