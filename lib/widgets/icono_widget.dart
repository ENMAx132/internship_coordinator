import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/app_config.dart';
import '../core/image_headers.dart';
import '../core/inventory_scope.dart';

/// Muestra la imagen remota de un icono si existe y el emoji como respaldo.
class IconoWidget extends StatelessWidget {
  final String? imageUrl;
  final String emoji;
  final double fontSize;
  final double? size;
  final BorderRadius? borderRadius;

  const IconoWidget({
    super.key,
    required this.emoji,
    this.imageUrl,
    this.fontSize = 24,
    this.size,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final diametro = size ?? fontSize * 2.2;
    final url = AppConfig.resolveImageUrl(imageUrl);
    Widget contenido;
    if (url != null) {
      contenido = Image.network(
        url,
        fit: BoxFit.cover,
        headers: _headersFor(context, url),
        errorBuilder: (context, error, stackTrace) {
          if (kDebugMode) {
            debugPrint('No se pudo cargar el icono $url: $error');
          }
          return _construirFallback();
        },
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return _construirFallback();
        },
      );
    } else {
      contenido = _construirFallback();
    }
    return Container(
      width: diametro,
      height: diametro,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: borderRadius,
      ),
      child: borderRadius == null
          ? ClipOval(child: contenido)
          : ClipRRect(borderRadius: borderRadius!, child: contenido),
    );
  }

  Map<String, String>? _headersFor(BuildContext context, String url) {
    final token = InventoryScope.maybeOf(context)?.session.token;
    return imageRequestHeaders(url, token);
  }

  Widget _construirFallback() {
    return Center(
      child: Text(
        emoji,
        style: TextStyle(fontSize: fontSize),
        textAlign: TextAlign.center,
      ),
    );
  }
}
