import 'package:flutter/material.dart';

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
    Widget contenido;
    if (imageUrl != null && imageUrl!.trim().isNotEmpty) {
      contenido = Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _construirFallback(),
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
