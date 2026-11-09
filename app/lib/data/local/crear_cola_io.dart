import 'package:drift_flutter/drift_flutter.dart';

import 'cola.dart';
import 'cola_drift.dart';

ColaAportacions crearCola() => ColaDrift(BdCola(driftDatabase(name: 'observatori_cola')));
