import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config.dart';
import 'data/local/crear_cola.dart';
import 'data/remote/api_observatori.dart';
import 'services/cataleg.dart';
import 'services/sessio.dart';
import 'services/sigpac.dart';
import 'services/sincronitzacio.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: Config.supabaseUrl, publishableKey: Config.supabaseKey);
  final client = Supabase.instance.client;

  final api = ApiObservatori(client);
  final sigpac = Sigpac();
  final sessio = Sessio(client);
  final cataleg = Cataleg(api);
  final sincronitzacio = Sincronitzacio(
    cola: crearCola(),
    api: api,
    recinte: sigpac.recinteEnPunt,
    missatgeSenseRecinte: 'Ací no hi ha cap recinte SIGPAC.',
  );

  await sincronitzacio.carregar();
  // Al recuperar la red se envía lo pendiente. Sin sesión no se puede: se espera a entrar
  Connectivity().onConnectivityChanged.listen((r) {
    if (!r.contains(ConnectivityResult.none) && sessio.entrada) sincronitzacio.enviar();
  });
  sessio.addListener(() {
    if (sessio.entrada) {
      cataleg.carregar();
      sincronitzacio.enviar();
    }
  });
  if (sessio.entrada) {
    cataleg.carregar();
    sincronitzacio.enviar();
  }

  runApp(MultiProvider(
    providers: [
      Provider.value(value: api),
      Provider.value(value: sigpac),
      ChangeNotifierProvider.value(value: sessio),
      ChangeNotifierProvider.value(value: cataleg),
      ChangeNotifierProvider.value(value: sincronitzacio),
    ],
    child: ObservatoriApp(sessio: sessio),
  ));
}
