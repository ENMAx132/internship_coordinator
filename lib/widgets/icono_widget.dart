import 'dart:io';

import 'package:flutter/material.dart';

/// Muestra la imagen de un icono si existe y el emoji como respaldo.
class IconoWidget extends StatelessWidget {
  final String? imagePath;
  final String emoji;
  final double fontSize;
  final double? size;
  final BorderRadius? borderRadius;

  const IconoWidget({
    super.key,
    required this.emoji,
    this.imagePath,
    this.fontSize = 24,
    this.size,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final diametro = size ?? fontSize * 2.2;
    Widget contenido;
    if (imagePath != null && imagePath!.trim().isNotEmpty) {
      contenido = Image.file(
        File(imagePath!),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _construirFallback(),
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
