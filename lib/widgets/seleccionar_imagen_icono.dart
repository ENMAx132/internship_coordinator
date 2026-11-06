import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Permite elegir el icono de un producto con una imagen de la galeria o la camara.
class SelectorImagenIcono extends StatefulWidget {
  final String? imagePath;
  final String emoji;
  final List<String>? emojis;
  final ValueChanged<String?> onImagePicked;
  final ValueChanged<String>? onEmojiChange;
  final double size;

  const SelectorImagenIcono({
    super.key,
    required this.emoji,
    required this.onImagePicked,
    this.onEmojiChange,
    this.imagePath,
    this.emojis,
    this.size = 104,
  });

  @override
  State<SelectorImagenIcono> createState() => _SelectorImagenIconoState();
}

class _SelectorImagenIconoState extends State<SelectorImagenIcono> {
  late String _emoji;
  late String? _imagePath;
  final ImagePicker _picker = ImagePicker();
  bool _procesando = false;

  @override
  void initState() {
    super.initState();
    _emoji = widget.emoji;
    _imagePath = widget.imagePath;
  }

  @override
  void didUpdateWidget(covariant SelectorImagenIcono oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imagePath != oldWidget.imagePath) {
      setState(() => _imagePath = widget.imagePath);
    }
  }

  Future<void> _elegirImagen(ImageSource fuente) async {
    setState(() => _procesando = true);
    try {
      final XFile? imagen = await _picker.pickImage(
        source: fuente,
        imageQuality: 70,
      );
      if (imagen != null) {
        final String destino = await _rutaDestino();
        try {
          final File origen = File(imagen.path);
          if (origen.existsSync()) {
            final File copia = await origen.copy(destino);
            setState(() => _imagePath = copia.path);
            widget.onImagePicked(copia.path);
          } else {
            setState(() => _imagePath = imagen.path);
            widget.onImagePicked(imagen.path);
          }
        } catch (_) {
          setState(() => _imagePath = imagen.path);
          widget.onImagePicked(imagen.path);
        }
      }
    } finally {
      if (mounted) {
        setState(() => _procesando = false);
      }
    }
  }

  Future<String> _rutaDestino() async {
    final Directory directorio = await getApplicationDocumentsDirectory();
    return directorio.path + '/icono_' + DateTime.now().millisecondsSinceEpoch.toString() + '.jpg';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: widget.size,
          height: widget.size,
          decoration: const BoxDecoration(
            color: Color(0xFFF1F5F9),
            shape: BoxShape.circle,
          ),
          child: ClipOval(
            child: _imagePath != null && _imagePath!.trim().isNotEmpty
                ? Image.file(
                    File(_imagePath!),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _construirFallback(),
                  )
                : _construirFallback(),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _boton(Icons.photo_library_outlined, 'Galeria', () {
              _elegirImagen(ImageSource.gallery);
            }),
            const SizedBox(width: 8),
            _boton(Icons.camera_alt_outlined, 'Tomar foto', () {
              _elegirImagen(ImageSource.camera);
            }),
          ],
        ),
        if (widget.emojis != null) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: widget.emojis!.map((e) {
              return ChoiceChip(
                label: Text(e, style: const TextStyle(fontSize: 18)),
                selected: _emoji == e,
                onSelected: (sel) {
                  if (sel) {
                    setState(() => _emoji = e);
                    widget.onEmojiChange?.call(e);
                  }
                },
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _construirFallback() {
    return Center(
      child: Text(
        _emoji,
        style: TextStyle(fontSize: widget.size * 0.45),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _boton(IconData icono, String etiqueta, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: _procesando ? null : onTap,
      icon: Icon(icono, size: 18, color: const Color(0xFF6366F1)),
      label: Text(
        etiqueta,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF6366F1),
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFF6366F1)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
    );
  }
}
