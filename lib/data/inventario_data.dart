import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/apartado.dart';
import '../models/espacio.dart';
import '../models/objeto_inventario.dart';

final ValueNotifier<int> inventarioVersion = ValueNotifier<int>(0);

final List<Apartado> apartadosIniciales = [];

final List<Espacio> espaciosIniciales = [];

final List<ObjetoInventario> objetosIniciales = [];

Future<void> _guardadoEnCurso = Future<void>.value();

Future<File> _archivoInventario() async {
  final Directory directorio = await getApplicationDocumentsDirectory();
  return File('${directorio.path}${Platform.pathSeparator}inventario.json');
}

Future<void> cargarInventario() async {
  try {
    final File archivo = await _archivoInventario();
    if (!await archivo.exists()) return;
    final String contenido = await archivo.readAsString();
    if (contenido.trim().isEmpty) return;
    final dynamic data = jsonDecode(contenido);
    if (data is! Map) return;

    apartadosIniciales
      ..clear()
      ..addAll(
        ((data['apartados'] as List?) ?? const [])
            .whereType<Map>()
            .map((e) => Apartado.fromJson(Map<String, dynamic>.from(e))),
      );
    espaciosIniciales
      ..clear()
      ..addAll(
        ((data['espacios'] as List?) ?? const [])
            .whereType<Map>()
            .map((e) => Espacio.fromJson(Map<String, dynamic>.from(e))),
      );
    objetosIniciales
      ..clear()
      ..addAll(
        ((data['objetos'] as List?) ?? const [])
            .whereType<Map>()
            .map((e) => ObjetoInventario.fromJson(Map<String, dynamic>.from(e))),
      );
    inventarioVersion.value++;
  } catch (_) {
    // Si el archivo no existe o está dañado, se mantiene el inventario vacío.
  }
}

Future<void> _escribirInventario() async {
  try {
    final File archivo = await _archivoInventario();
    final Map<String, dynamic> data = {
      'apartados': apartadosIniciales.map((e) => e.toJson()).toList(),
      'espacios': espaciosIniciales.map((e) => e.toJson()).toList(),
      'objetos': objetosIniciales.map((e) => e.toJson()).toList(),
    };
    await archivo.writeAsString(jsonEncode(data), flush: true);
  } catch (_) {
    // Ignorar errores de escritura para no interrumpir la aplicación.
  }
}

Future<void> guardarInventario() {
  _guardadoEnCurso = _guardadoEnCurso.then((_) => _escribirInventario());
  return _guardadoEnCurso;
}

void notificarCambioInventario() {
  inventarioVersion.value++;
  guardarInventario();
}
