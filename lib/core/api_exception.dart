/// Error producido por la API o por falta de conectividad.
class ApiException implements Exception {
  ApiException({
    required this.statusCode,
    required this.message,
    this.errorCode,
    this.description,
    this.fieldErrors = const {},
    this.isNetworkError = false,
    this.rawBody,
    this.endpoint,
  });

  final int statusCode;
  final String message;
  final String? errorCode;
  final String? description;
  final Map<String, List<String>> fieldErrors;
  final bool isNetworkError;
  final String? rawBody;
  final String? endpoint;

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isValidation => statusCode == 422;
  bool get isTooManyRequests => statusCode == 429;
  bool get isServerError => statusCode >= 500;
  bool get isRedirect => statusCode >= 300 && statusCode < 400;

  /// Detalle técnico para el panel de diagnóstico del login.
  String get technicalDetails {
    final lines = <String>[];
    if (endpoint != null && endpoint!.isNotEmpty) {
      lines.add('Endpoint: $endpoint');
    }
    lines.add('HTTP: $statusCode');
    if (errorCode != null && errorCode!.isNotEmpty) {
      lines.add('Código: $errorCode');
    }
    if (description != null &&
        description!.isNotEmpty &&
        description != message) {
      lines.add('Descripción: $description');
    }
    if (message.isNotEmpty) {
      lines.add('Mensaje: $message');
    }
    if (fieldErrors.isNotEmpty) {
      lines.add('Campos:');
      fieldErrors.forEach((field, messages) {
        lines.add('  $field: ${messages.join(', ')}');
      });
    }
    if (rawBody != null && rawBody!.trim().isNotEmpty) {
      lines.add('Respuesta:');
      lines.add(rawBody!.trim());
    }
    return lines.join('\n');
  }

  @override
  String toString() {
    final code = errorCode == null ? '' : ' [$errorCode]';
    return 'ApiException($statusCode)$code: $message';
  }
}

/// Mensaje amigable en español para mostrar al usuario.
String messageForApiError(ApiException error) {
  switch (error.errorCode) {
    case 'EI001':
      return 'Ya existe un objeto con esa placa.';
    case 'EI002':
      return 'Solo puedes mover el objeto a un espacio del mismo apartado.';
    case 'EI003':
      return 'El objeto ya tiene una revisión activa.';
    case 'EI004':
      return 'La imagen está en uso y no se puede eliminar.';
    case 'EI005':
      return 'La imagen supera los 5 MB.';
    case 'EI006':
      return 'Formato no permitido. Usa JPG, PNG o WebP.';
    case 'EI007':
      return 'La imagen ya no existe.';
    case 'EI008':
      return 'Debes enviar todos los apartados al reordenar.';
    case 'EA001':
      return 'Correo o contraseña incorrectos.';
  }

  if (error.isNetworkError) {
    return 'No hay conexión con el servidor.';
  }
  if (error.isUnauthorized) {
    return 'Tu sesión expiró. Vuelve a iniciar sesión.';
  }
  if (error.isForbidden) {
    return 'No tienes permiso para esta acción.';
  }
  if (error.isNotFound) {
    return 'El recurso ya no existe.';
  }
  if (error.isValidation) {
    if (error.fieldErrors.isNotEmpty) {
      return error.fieldErrors.values.first.first;
    }
    return error.message;
  }
  return error.message.isEmpty ? 'Ocurrió un error inesperado.' : error.message;
}

/// Mensaje específico para el flujo de login.
String messageForLoginError(ApiException error) {
  switch (error.errorCode) {
    case 'EA001':
    case 'ERR_401':
      return 'Correo o contraseña incorrectos.';
  }

  if (error.isNetworkError) {
    return 'No hay conexión con el servidor.';
  }
  if (error.statusCode == 401) {
    return 'Correo o contraseña incorrectos.';
  }
  if (error.statusCode == 419) {
    return 'La sesión o el token CSRF expiró. Recarga e intenta de nuevo.';
  }
  if (error.isTooManyRequests) {
    return 'Demasiados intentos. Espera un momento.';
  }
  if (error.isRedirect) {
    return 'El servidor redirigió el login. Usa HTTPS en la URL de la API.';
  }
  if (error.isServerError) {
    return 'Error del servidor (${error.statusCode}).';
  }
  if (error.isValidation) {
    if (error.fieldErrors.isNotEmpty) {
      return error.fieldErrors.values.first.first;
    }
    return error.message;
  }
  if (error.isForbidden) {
    return 'No tienes permiso para iniciar sesión.';
  }
  if (error.isNotFound) {
    return 'El endpoint de login no existe. Verifica la URL de la API.';
  }
  return error.message.isEmpty ? 'No se pudo iniciar sesión.' : error.message;
}
