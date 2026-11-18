/// Configuración global de la app.
///
/// La URL se puede sobreescribir en tiempo de compilación:
/// `flutter run --dart-define=API_BASE_URL=https://mi-api.com/api`
class AppConfig {
  AppConfig._();

  static const String _rawApiRoot = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api-attendance-v2.simgulary.io/api',
  );

  static const Set<String> _localHosts = {
    'localhost',
    '127.0.0.1',
    '10.0.2.2',
    '::1',
  };

  /// Raíz de la API, por ejemplo `https://host/api`.
  ///
  /// Si se configura un host remoto por HTTP, se sube a HTTPS porque el
  /// servidor de producción redirige HTTP -> HTTPS (301). Los hosts locales
  /// se dejan intactos para desarrollo.
  static String get apiRoot {
    var value = _rawApiRoot.trim();
    if (value.isEmpty) return value;
    if (value.endsWith('/')) {
      value = value.substring(0, value.length - 1);
    }
    if (value.startsWith('http://')) {
      final uri = Uri.tryParse(value);
      if (uri != null && !_localHosts.contains(uri.host)) {
        value = 'https://${value.substring('http://'.length)}';
      }
    }
    return value;
  }

  /// Origen de la API (esquema, host y puerto) sin la ruta.
  ///
  /// Por ejemplo, de `https://api.example.com/api` devuelve
  /// `https://api.example.com`.
  static String get apiOrigin {
    final uri = Uri.tryParse(apiRoot);
    if (uri == null || uri.host.isEmpty) return apiRoot;
    final port = uri.hasPort ? ':${uri.port}' : '';
    return '${uri.scheme}://${uri.host}$port';
  }

  /// Convierte una URL de imagen (posiblemente relativa) en absoluta.
  ///
  /// La API puede devolver `/storage/inventory/foo.jpg` o
  /// `inventory/foo.jpg`; `Image.network` necesita una URL absoluta.
  static String? resolveImageUrl(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) return null;

    final lower = value.toLowerCase();
    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      return value;
    }
    if (value.startsWith('//')) {
      final scheme = Uri.tryParse(apiRoot)?.scheme ?? 'https';
      return '$scheme:$value';
    }

    final origin = apiOrigin;
    if (origin.isEmpty) return value;
    return value.startsWith('/') ? '$origin$value' : '$origin/$value';
  }

  /// Indica si [url] pertenece al mismo origen que la API.
  static bool isApiOrigin(String url) {
    final target = Uri.tryParse(url);
    final base = Uri.tryParse(apiRoot);
    if (target == null || base == null) return false;
    return target.scheme == base.scheme &&
        target.host == base.host &&
        target.port == base.port;
  }

  /// Base del módulo de inventario.
  static String get inventoryBaseUrl => '$apiRoot/inventory';

  /// Endpoint de login existente.
  static String get loginUrl => '$apiRoot/login';
}
