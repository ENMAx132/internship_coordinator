import 'package:flutter/foundation.dart';

import '../models/apartado.dart';
import '../models/espacio.dart';
import '../models/objeto_inventario.dart';

final ValueNotifier<int> inventarioVersion = ValueNotifier<int>(0);

void notificarCambioInventario() {
  inventarioVersion.value++;
}

final List<Apartado> apartadosIniciales = [];

final List<Espacio> espaciosIniciales = [];

final List<ObjetoInventario> objetosIniciales = [];
