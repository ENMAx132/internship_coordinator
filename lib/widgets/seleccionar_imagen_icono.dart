import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Permite elegir el icono de un producto con una imagen de la galería o la
/// cámara. Devuelve la ruta local elegida; el store la sube a la API.
class SelectorImagenIcono extends StatefulWidget {
  final String? imageUrl;
  final String? localImagePath;
  final String emoji;
  final List<String>? emojis;
  final ValueChanged<String?> onImagePicked;
  final ValueChanged<String>? onEmojiChange;
  final ValueChanged<bool>? onEmojisVisibilityChanged;
  final double size;

  const SelectorImagenIcono({
    super.key,
    required this.emoji,
    required this.onImagePicked,
    this.onEmojiChange,
    this.onEmojisVisibilityChanged,
    this.imageUrl,
    this.localImagePath,
    this.emojis,
    this.size = 104,
  });

  @override
  State<SelectorImagenIcono> createState() => _SelectorImagenIconoState();
}

class _SelectorImagenIconoState extends State<SelectorImagenIcono> {
  late String _emoji;
  String? _localPath;
  String? _remoteUrl;
  final ImagePicker _picker = ImagePicker();
  bool _procesando = false;
  bool _mostrarEmojis = false;

  @override
  void initState() {
    super.initState();
    _emoji = widget.emoji;
    _localPath = widget.localImagePath;
    _remoteUrl = widget.imageUrl;
  }

  @override
  void didUpdateWidget(covariant SelectorImagenIcono oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imageUrl != oldWidget.imageUrl ||
        widget.localImagePath != oldWidget.localImagePath) {
      setState(() {
        _remoteUrl = widget.imageUrl;
        _localPath = widget.localImagePath;
      });
    }
  }

  void _alternarEmojis() {
    setState(() => _mostrarEmojis = !_mostrarEmojis);
    widget.onEmojisVisibilityChanged?.call(_mostrarEmojis);
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
            setState(() {
              _localPath = copia.path;
              _remoteUrl = null;
            });
            widget.onImagePicked(copia.path);
          } else {
            setState(() {
              _localPath = imagen.path;
              _remoteUrl = null;
            });
            widget.onImagePicked(imagen.path);
          }
        } catch (_) {
          setState(() {
            _localPath = imagen.path;
            _remoteUrl = null;
          });
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
    return '${directorio.path}${Platform.pathSeparator}'
        'icono_${DateTime.now().millisecondsSinceEpoch}.jpg';
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
            child: _construirImagen(),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            _boton(Icons.photo_library_outlined, 'Galeria', () {
              _elegirImagen(ImageSource.gallery);
            }),
            _boton(Icons.camera_alt_outlined, 'Tomar foto', () {
              _elegirImagen(ImageSource.camera);
            }),
            if (widget.emojis != null)
              _boton(
                Icons.emoji_emotions_outlined,
                'Emojis',
                _alternarEmojis,
                activo: _mostrarEmojis,
              ),
          ],
        ),
        if (_mostrarEmojis && widget.emojis != null) ...[
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

  Widget _construirImagen() {
    if (_localPath != null && _localPath!.trim().isNotEmpty) {
      return Image.file(
        File(_localPath!),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _construirFallback(),
      );
    }
    if (_remoteUrl != null && _remoteUrl!.trim().isNotEmpty) {
      return Image.network(
        _remoteUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _construirFallback(),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return _construirFallback();
        },
      );
    }
    return _construirFallback();
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

  Widget _boton(
    IconData icono,
    String etiqueta,
    VoidCallback onTap, {
    bool activo = false,
  }) {
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
        backgroundColor: activo ? const Color(0xFFEEF2FF) : null,
        side: const BorderSide(color: Color(0xFF6366F1)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
    );
  }
}
