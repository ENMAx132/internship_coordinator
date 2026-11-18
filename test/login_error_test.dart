import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:inventario_pasantes/core/api_client.dart';
import 'package:inventario_pasantes/core/api_exception.dart';

ApiClient _client(MockClient mock) => ApiClient(
      apiRoot: 'https://example.com/api',
      client: mock,
    );

Future<ApiException> _loginError(http.Response response) async {
  final client = _client(MockClient((_) async => response));
  try {
    await client.postLogin(email: 'a@b.com', password: 'bad');
  } on ApiException catch (error) {
    return error;
  }
  fail('Se esperaba un ApiException');
}

void main() {
  test('401 sin error_code se reporta como credenciales inválidas', () async {
    final error = await _loginError(
      http.Response(
        '{"message":"Invalid credentials"}',
        401,
        headers: {'content-type': 'application/json'},
      ),
    );

    expect(error.statusCode, 401);
    expect(messageForLoginError(error), 'Correo o contraseña incorrectos.');
    expect(error.technicalDetails, contains('HTTP: 401'));
    expect(
      error.technicalDetails,
      contains('Endpoint: https://example.com/api/login'),
    );
  });

  test('401 con EA001 se reporta como credenciales inválidas', () async {
    final error = await _loginError(
      http.Response(
        '{"error_code":"EA001","message":"invalid_credentials",'
        '"description":"Credenciales inválidas"}',
        401,
        headers: {'content-type': 'application/json'},
      ),
    );

    expect(error.errorCode, 'EA001');
    expect(messageForLoginError(error), 'Correo o contraseña incorrectos.');
    expect(error.technicalDetails, contains('Código: EA001'));
    expect(error.technicalDetails, contains('Credenciales inválidas'));
  });

  test('419 HTML se reporta como CSRF y conserva el cuerpo', () async {
    final error = await _loginError(
      http.Response(
        '<html><body>CSRF token mismatch</body></html>',
        419,
        headers: {'content-type': 'text/html'},
      ),
    );

    expect(error.statusCode, 419);
    expect(
      messageForLoginError(error),
      'La sesión o el token CSRF expiró. Recarga e intenta de nuevo.',
    );
    expect(error.technicalDetails, contains('HTTP: 419'));
    expect(error.technicalDetails, contains('CSRF token mismatch'));
    expect(error.rawBody, contains('<html>'));
  });

  test('200 con HTML se reporta como respuesta no JSON', () async {
    final error = await _loginError(
      http.Response(
        '<html><body>Login page</body></html>',
        200,
        headers: {'content-type': 'text/html'},
      ),
    );

    expect(error.statusCode, 200);
    expect(error.message, contains('no es JSON'));
    expect(error.rawBody, contains('Login page'));
  });

  test('200 sin access_token se reporta como respuesta inválida', () async {
    final error = await _loginError(
      http.Response(
        '{"user":{"id":1,"name":"Admin","email":"a@b.com","role":"ADMIN"}}',
        200,
        headers: {'content-type': 'application/json'},
      ),
    );

    expect(error.message, 'Respuesta de login inválida');
    expect(error.technicalDetails, contains('access_token'));
    expect(error.rawBody, contains('"role":"ADMIN"'));
  });

  test('error de red se reporta sin conexión', () async {
    final client = _client(
      MockClient((_) async => throw http.ClientException('Failed host lookup')),
    );

    try {
      await client.postLogin(email: 'a@b.com', password: 'bad');
      fail('Se esperaba un ApiException');
    } on ApiException catch (error) {
      expect(error.isNetworkError, isTrue);
      expect(messageForLoginError(error), 'No hay conexión con el servidor.');
      expect(error.technicalDetails, contains('Failed host lookup'));
      expect(
        error.technicalDetails,
        contains('Endpoint: https://example.com/api/login'),
      );
    }
  });
}
