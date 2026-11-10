import 'dart:io';

import 'package:flutter/material.dart';

class EntityImage extends StatelessWidget {
  final String? imagePath;
  final String fallbackIcon;
  final double size;
  final double iconSize;

  const EntityImage({
    super.key,
    this.imagePath,
    required this.fallbackIcon,
    this.size = 48,
    this.iconSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imagePath != null && imagePath!.trim().isNotEmpty;
    final fallback = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(size / 2),
      ),
      alignment: Alignment.center,
      child: Text(
        fallbackIcon,
        style: TextStyle(fontSize: iconSize, color: const Color(0xFF6366F1)),
      ),
    );

    if (!hasImage) {
      return fallback;
    }

    return ClipOval(
      child: Image.file(
        File(imagePath!),
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }
}
