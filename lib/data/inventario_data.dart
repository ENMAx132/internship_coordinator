import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/apartado.dart';
import '../models/espacio.dart';
import '../models/objeto_inventario.dart';
import '../models/registro_revision.dart';
import 'app_settings.dart';

final ValueNotifier<int> inventarioVersion = ValueNotifier<int>(0);

final List<Apartado> apartadosIniciales = [];

final List<Espacio> espaciosIniciales = [];

final List<ObjetoInventario> objetosIniciales = [];

final List<RegistroRevision> historialRevisiones = [];

Future<void> _guardadoEnCurso = Future<void>.value();

Future<File> _archivoInventario() async {
  final Directory directorio = await getApplicationDocumentsDirectory();
  return File('${directorio.path}${Platform.pathSeparator}inventario.json');
}

Future<void> cargarInventario() async {
  try {
    final File archivo = await _archivoInventario();
    if (!await archivo.exists()) {
      tutorialCompletado.value = false;
      return;
    }
    final String contenido = await archivo.readAsString();
    if (contenido.trim().isEmpty) {
      tutorialCompletado.value = false;
      return;
    }
    final dynamic data = jsonDecode(contenido);
    if (data is! Map) {
      tutorialCompletado.value = false;
      return;
    }

    final dynamic tutorialValor = data['tutorialCompletado'];
    tutorialCompletado.value = tutorialValor is bool ? tutorialValor : true;

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
    historialRevisiones
      ..clear()
      ..addAll(
        ((data['historialRevisiones'] as List?) ?? const [])
            .whereType<Map>()
            .map((e) => RegistroRevision.fromJson(Map<String, dynamic>.from(e))),
      );
    _sincronizarHistorialRevision();
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
      'historialRevisiones':
          historialRevisiones.map((e) => e.toJson()).toList(),
      'tutorialCompletado': tutorialCompletado.value,
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

void _sincronizarHistorialRevision() {
  final idsEnRevision = objetosIniciales
      .where((o) => o.estado.toLowerCase() == 'en revisión')
      .map((o) => o.id)
      .toSet();

  for (final objeto in objetosIniciales) {
    if (!idsEnRevision.contains(objeto.id)) continue;
    final tieneRegistroActivo = historialRevisiones.any(
      (r) => r.objetoId == objeto.id && r.fechaSalida == null,
    );
    if (!tieneRegistroActivo) {
      historialRevisiones.add(
        RegistroRevision(
          id: '${DateTime.now().microsecondsSinceEpoch}-${objeto.id}',
          objetoId: objeto.id,
          nombre: objeto.nombre,
          placa: objeto.placa,
          espacioId: objeto.espacioId,
          imagePath: objeto.imagePath,
          fechaEntrada: objeto.fechaEnRevision,
        ),
      );
    }
  }

  final ahora = DateTime.now();
  for (final registro in historialRevisiones) {
    if (registro.fechaSalida == null &&
        !idsEnRevision.contains(registro.objetoId)) {
      registro.fechaSalida = ahora;
    }
  }
}

void notificarCambioInventario() {
  _sincronizarHistorialRevision();
  inventarioVersion.value++;
  guardarInventario();
}

void marcarTutorialCompletado() {
  tutorialCompletado.value = true;
  guardarInventario();
}
