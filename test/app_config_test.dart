import 'package:flutter_test/flutter_test.dart';
import 'package:inventario_pasantes/core/app_config.dart';

void main() {
  group('resolveImageUrl', () {
    test('deja intactas las URLs absolutas', () {
      expect(
        AppConfig.resolveImageUrl('https://cdn.example.com/a.jpg'),
        'https://cdn.example.com/a.jpg',
      );
    });

    test('antepone el origen de la API a rutas absolutas', () {
      expect(
        AppConfig.resolveImageUrl('/storage/inventory/a.jpg'),
        '${AppConfig.apiOrigin}/storage/inventory/a.jpg',
      );
    });

    test('antepone el origen de la API a rutas relativas', () {
      expect(
        AppConfig.resolveImageUrl('storage/inventory/a.jpg'),
        '${AppConfig.apiOrigin}/storage/inventory/a.jpg',
      );
    });

    test('usa HTTPS para URLs de protocolo relativo', () {
      expect(
        AppConfig.resolveImageUrl('//cdn.example.com/a.jpg'),
        'https://cdn.example.com/a.jpg',
      );
    });

    test('devuelve null para valores vacíos', () {
      expect(AppConfig.resolveImageUrl(null), isNull);
      expect(AppConfig.resolveImageUrl('   '), isNull);
    });
  });
}
