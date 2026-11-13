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

const int _esquemaVersion = 1;

/// Genera una placa libre con el formato ACT-001 para un objeto nuevo.
String generarPlacaUnica() {
  final usadas =
      objetosIniciales.map((o) => o.placa.trim().toUpperCase()).toSet();
  var numero = objetosIniciales.length + 1;
  String placa;
  do {
    placa = 'ACT-${numero.toString().padLeft(3, '0')}';
    numero++;
  } while (usadas.contains(placa));
  return placa;
}

Future<void> _guardadoEnCurso = Future<void>.value();

Future<File> _archivoInventario() async {
  final Directory directorio = await getApplicationDocumentsDirectory();
  return File('${directorio.path}${Platform.pathSeparator}inventario.json');
}

Future<File> _archivoRespaldo() async {
  final Directory directorio = await getApplicationDocumentsDirectory();
  return File(
    '${directorio.path}${Platform.pathSeparator}inventario.backup.json',
  );
}

Map<String, dynamic>? _decodificar(String contenido) {
  if (contenido.trim().isEmpty) return null;
  final dynamic data = jsonDecode(contenido);
  if (data is! Map) return null;
  return Map<String, dynamic>.from(data);
}

Future<Map<String, dynamic>?> _leerMapa(File archivo) async {
  if (!await archivo.exists()) return null;
  return _decodificar(await archivo.readAsString());
}

Future<void> cargarInventario() async {
  Map<String, dynamic>? data;
  try {
    data = await _leerMapa(await _archivoInventario());
  } catch (e) {
    debugPrint('No se pudo leer inventario.json: $e');
  }
  if (data == null) {
    try {
      data = await _leerMapa(await _archivoRespaldo());
      if (data != null) {
        debugPrint('Inventario recuperado desde el respaldo.');
      }
    } catch (e) {
      debugPrint('No se pudo leer el respaldo del inventario: $e');
    }
  }
  if (data == null) {
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
}

Future<void> _escribirInventario() async {
  final File archivo = await _archivoInventario();
  final Map<String, dynamic> data = {
    'version': _esquemaVersion,
    'apartados': apartadosIniciales.map((e) => e.toJson()).toList(),
    'espacios': espaciosIniciales.map((e) => e.toJson()).toList(),
    'objetos': objetosIniciales.map((e) => e.toJson()).toList(),
    'historialRevisiones': historialRevisiones.map((e) => e.toJson()).toList(),
    'tutorialCompletado': tutorialCompletado.value,
  };
  try {
    if (await archivo.exists()) {
      final File respaldo = await _archivoRespaldo();
      await archivo.copy(respaldo.path);
    }
    final File temporal = File('${archivo.path}.tmp');
    await temporal.writeAsString(jsonEncode(data), flush: true);
    try {
      await temporal.rename(archivo.path);
    } on FileSystemException {
      if (await archivo.exists()) {
        await archivo.delete();
      }
      await temporal.rename(archivo.path);
    }
  } catch (e) {
    debugPrint('No se pudo guardar el inventario: $e');
  }
}

Future<void> guardarInventario() {
  _guardadoEnCurso = _guardadoEnCurso.then((_) => _escribirInventario());
  return _guardadoEnCurso;
}

void _sincronizarHistorialRevision() {
  final idsEnRevision = objetosIniciales
      .where((o) => ObjetoInventario.esEstadoEnRevision(o.estado))
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

/// Marca como eliminados los registros de revisión activos de los objetos
/// indicados, para que el historial refleje el motivo de la salida.
void registrarEliminacionEnHistorial(Set<String> objetoIds) {
  if (objetoIds.isEmpty) return;
  final ahora = DateTime.now();
  for (final registro in historialRevisiones) {
    if (objetoIds.contains(registro.objetoId) && registro.fechaSalida == null) {
      registro.fechaSalida = ahora;
      registro.motivoSalida = 'Objeto eliminado';
    }
  }
}

/// Elimina una imagen creada por la app si ya no está referenciada por
/// ningún apartado, espacio u objeto.
void eliminarImagenHuerfana(String? imagePath) {
  if (imagePath == null || imagePath.trim().isEmpty) return;
  if (!imagePath.contains('icono_')) return;
  final enUso = <String>{
    ...apartadosIniciales.map((a) => a.imagePath).whereType<String>(),
    ...espaciosIniciales.map((e) => e.imagePath).whereType<String>(),
    ...objetosIniciales.map((o) => o.imagePath).whereType<String>(),
  };
  if (enUso.contains(imagePath)) return;
  try {
    final File archivo = File(imagePath);
    if (archivo.existsSync()) {
      archivo.deleteSync();
    }
  } catch (e) {
    debugPrint('No se pudo eliminar la imagen $imagePath: $e');
  }
}

void eliminarImagenesHuerfanas(Iterable<String?> rutas) {
  for (final ruta in rutas.toSet()) {
    eliminarImagenHuerfana(ruta);
  }
}
