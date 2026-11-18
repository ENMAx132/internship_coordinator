import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'api_exception.dart';
import 'app_config.dart';

/// Cliente HTTP del módulo de inventario.
///
/// La API usa snake_case, respuestas planas para recursos y el envoltorio
/// `{data, links, meta}` para listas paginadas.
class ApiClient {
  ApiClient({
    String? apiRoot,
    this.token,
    http.Client? client,
    this.timeout = const Duration(seconds: 20),
  })  : apiRoot = (apiRoot ?? AppConfig.apiRoot),
        _client = client ?? http.Client();

  final String apiRoot;
  final String? token;
  final http.Client _client;
  final Duration timeout;

  String get _inventoryBase {
    final root = apiRoot.endsWith('/')
        ? apiRoot.substring(0, apiRoot.length - 1)
        : apiRoot;
    return '$root/inventory';
  }

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        if (token != null && token!.isNotEmpty)
          'Authorization': 'Bearer $token',
      };

  Map<String, String> get _jsonHeaders => {
        ..._headers,
        'Content-Type': 'application/json',
      };

  Uri _inventoryUri(String path, [Map<String, dynamic>? query]) {
    final normalized = path.startsWith('/') ? path : '/$path';
    final base = Uri.parse('$_inventoryBase$normalized');
    if (query == null || query.isEmpty) return base;
    return base.replace(
      queryParameters: query.map((key, value) => MapEntry(key, '$value')),
    );
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    final uri = _inventoryUri(path, query);
    final response = await _send(
      () => _client.get(uri, headers: _headers),
      endpoint: uri.toString(),
    );
    return _decode(response, endpoint: uri.toString());
  }

  Future<Map<String, dynamic>> post(String path, {Object? body}) async {
    final uri = _inventoryUri(path);
    final response = await _send(
      () => _client.post(
        uri,
        headers: _jsonHeaders,
        body: body == null ? null : jsonEncode(body),
      ),
      endpoint: uri.toString(),
    );
    return _decode(response, endpoint: uri.toString());
  }

  Future<Map<String, dynamic>> patch(String path, {Object? body}) async {
    final uri = _inventoryUri(path);
    final response = await _send(
      () => _client.patch(
        uri,
        headers: _jsonHeaders,
        body: body == null ? null : jsonEncode(body),
      ),
      endpoint: uri.toString(),
    );
    return _decode(response, endpoint: uri.toString());
  }

  Future<Map<String, dynamic>> put(String path, {Object? body}) async {
    final uri = _inventoryUri(path);
    final response = await _send(
      () => _client.put(
        uri,
        headers: _jsonHeaders,
        body: body == null ? null : jsonEncode(body),
      ),
      endpoint: uri.toString(),
    );
    return _decode(response, endpoint: uri.toString());
  }

  Future<void> delete(String path, {Object? body}) async {
    final uri = _inventoryUri(path);
    final response = await _send(
      () => _client.delete(
        uri,
        headers: _jsonHeaders,
        body: body == null ? null : jsonEncode(body),
      ),
      endpoint: uri.toString(),
    );
    _throwIfError(response, endpoint: uri.toString());
  }

  Future<Map<String, dynamic>> uploadImage(String filePath) async {
    final uri = Uri.parse('$_inventoryBase/uploads/images');
    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll(_headers);
    request.files.add(await http.MultipartFile.fromPath('file', filePath));

    final streamed = await _sendStream(
      () => request.send(),
      endpoint: uri.toString(),
    );
    final response = await http.Response.fromStream(streamed);
    final json = _decode(response, endpoint: uri.toString());
    if (kDebugMode) {
      debugPrint('UPLOAD IMAGE ${uri.toString()} -> ${jsonEncode(json)}');
    }
    return json;
  }

  /// Login contra la API existente (`POST /api/login`).
  Future<Map<String, dynamic>> postLogin({
    required String email,
    required String password,
  }) async {
    final root = apiRoot.endsWith('/')
        ? apiRoot.substring(0, apiRoot.length - 1)
        : apiRoot;
    final uri = Uri.parse('$root/login');
    final request = http.Request('POST', uri)
      ..headers.addAll(_jsonHeaders)
      ..body = jsonEncode({'email': email, 'password': password})
      ..followRedirects = false;

    final streamed = await _sendStream(
      () => _client.send(request),
      endpoint: uri.toString(),
    );
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode >= 300 && response.statusCode < 400) {
      throw ApiException(
        statusCode: response.statusCode,
        message: 'Redirección inesperada',
        description:
            'Location: ${response.headers['location'] ?? 'desconocido'}',
        endpoint: uri.toString(),
        rawBody: _snippet(response.body),
      );
    }

    final json = _decode(response, endpoint: uri.toString());
    final accessToken = json['access_token'];
    if (accessToken is! String || accessToken.isEmpty) {
      throw ApiException(
        statusCode: response.statusCode,
        message: 'Respuesta de login inválida',
        description: 'La respuesta no incluye un access_token válido.',
        endpoint: uri.toString(),
        rawBody: _snippet(response.body, max: 2000),
      );
    }
    if (json['user'] is! Map) {
      throw ApiException(
        statusCode: response.statusCode,
        message: 'Respuesta de login inválida',
        description: 'La respuesta no incluye el objeto user.',
        endpoint: uri.toString(),
        rawBody: _snippet(response.body, max: 2000),
      );
    }
    return json;
  }

  Future<http.Response> _send(
    Future<http.Response> Function() request, {
    String? endpoint,
  }) async {
    try {
      return await request().timeout(timeout);
    } on TimeoutException {
      throw ApiException(
        statusCode: 0,
        message: 'La conexión tardó demasiado.',
        isNetworkError: true,
        endpoint: endpoint,
      );
    } on http.ClientException catch (error) {
      throw ApiException(
        statusCode: 0,
        message: error.message,
        isNetworkError: true,
        endpoint: endpoint,
      );
    } catch (error) {
      throw ApiException(
        statusCode: 0,
        message: error.toString(),
        isNetworkError: true,
        endpoint: endpoint,
      );
    }
  }

  Future<http.StreamedResponse> _sendStream(
    Future<http.StreamedResponse> Function() request, {
    String? endpoint,
  }) async {
    try {
      return await request().timeout(timeout);
    } on TimeoutException {
      throw ApiException(
        statusCode: 0,
        message: 'La conexión tardó demasiado.',
        isNetworkError: true,
        endpoint: endpoint,
      );
    } on http.ClientException catch (error) {
      throw ApiException(
        statusCode: 0,
        message: error.message,
        isNetworkError: true,
        endpoint: endpoint,
      );
    } catch (error) {
      throw ApiException(
        statusCode: 0,
        message: error.toString(),
        isNetworkError: true,
        endpoint: endpoint,
      );
    }
  }

  Map<String, dynamic> _decode(
    http.Response response, {
    String? endpoint,
  }) {
    _throwIfError(response, endpoint: endpoint);
    if (response.body.trim().isEmpty) return const {};
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      if (decoded is List) return {'data': decoded};
      return {'data': decoded};
    } on FormatException {
      throw ApiException(
        statusCode: response.statusCode,
        message: 'La respuesta del servidor no es JSON.',
        description: 'Se esperaba JSON pero se recibió otro formato.',
        endpoint: endpoint ?? response.request?.url.toString(),
        rawBody: _snippet(response.body, max: 2000),
      );
    }
  }

  void _throwIfError(http.Response response, {String? endpoint}) {
    if (response.statusCode < 400) return;

    final rawBody = _snippet(response.body, max: 2000);
    Map<String, dynamic> body = const {};
    var isJson = false;
    if (response.body.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          body = decoded;
          isJson = true;
        } else if (decoded is Map) {
          body = Map<String, dynamic>.from(decoded);
          isJson = true;
        }
      } catch (_) {
        // El cuerpo no es JSON (por ejemplo, HTML de Laravel/nginx).
      }
    }

    final fieldErrors = <String, List<String>>{};
    final errors = body['errors'];
    if (errors is Map) {
      for (final entry in errors.entries) {
        final value = entry.value;
        if (value is List) {
          fieldErrors[entry.key.toString()] =
              value.map((e) => e.toString()).toList();
        } else if (value != null) {
          fieldErrors[entry.key.toString()] = [value.toString()];
        }
      }
    }

    final serverDescription = body['description'] as String?;
    final serverMessage = body['message'] as String?;
    final message = fieldErrors.isNotEmpty
        ? fieldErrors.values.first.first
        : (serverDescription ??
            serverMessage ??
            (isJson
                ? 'Error ${response.statusCode}'
                : 'Respuesta no JSON (HTTP ${response.statusCode})'));

    final resolvedEndpoint =
        endpoint ?? response.request?.url.toString();

    if (kDebugMode) {
      debugPrint(
        'API ERROR ${response.statusCode} ${resolvedEndpoint ?? ''}',
      );
      if (response.body.trim().isNotEmpty) {
        debugPrint(_snippet(response.body, max: 2000) ?? '');
      }
    }

    throw ApiException(
      statusCode: response.statusCode,
      message: message,
      errorCode: body['error_code'] as String?,
      description: serverDescription ??
          (isJson ? null : 'El servidor no devolvió JSON.'),
      fieldErrors: fieldErrors,
      rawBody: rawBody,
      endpoint: resolvedEndpoint,
    );
  }

  static String? _snippet(String body, {int max = 500}) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.length <= max) return trimmed;
    return '${trimmed.substring(0, max)}…';
  }

  void dispose() => _client.close();
}
