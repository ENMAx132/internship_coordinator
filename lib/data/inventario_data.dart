import 'package:flutter/foundation.dart';

import '../models/apartado.dart';
import '../models/espacio.dart';
import '../models/objeto_inventario.dart';

final List<Apartado> apartadosIniciales = [];

final List<Espacio> espaciosIniciales = [];

final List<ObjetoInventario> objetosIniciales = [];

final ValueNotifier<int> inventarioVersion = ValueNotifier<int>(0);

void notificarCambioInventario() {
  inventarioVersion.value++;
}
