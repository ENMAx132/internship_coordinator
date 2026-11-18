import 'package:flutter/foundation.dart';

import 'app_config.dart';

/// Cabeceras para cargar imágenes protegidas por la API.
///
/// Solo se envía el token si la imagen vive en el mismo origen que la API,
/// para no filtrarlo a CDNs externos. En web se omite porque las etiquetas de
/// imagen no permiten cabeceras y forzarían un preflight CORS.
Map<String, String>? imageRequestHeaders(String url, String? token) {
  if (kIsWeb) return null;
  final value = token?.trim();
  if (value == null || value.isEmpty) return null;
  if (!AppConfig.isApiOrigin(url)) return null;
  return {'Authorization': 'Bearer $value'};
}
