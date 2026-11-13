import 'package:flutter/material.dart';

import '../../models/apartado.dart';
import '../../widgets/seleccionar_imagen_icono.dart';

class EditarApartadoDialog extends StatefulWidget {
  final Apartado apartado;
  final ValueChanged<Apartado> onActualizar;
  final ValueChanged<Apartado> onEliminar;

  const EditarApartadoDialog({
    super.key,
    required this.apartado,
    required this.onActualizar,
    required this.onEliminar,
  });

  @override
  State<EditarApartadoDialog> createState() => _EditarApartadoDialogState();
}

class _EditarApartadoDialogState extends State<EditarApartadoDialog> {
  late final TextEditingController nombreCtrl;
  late final TextEditingController descCtrl;
  late String emojiSelec;
  late String? imagePathSelec;
  final emojis = [
    '🏢',
    '💻',
    '📊',
    '📦',
    '🤝',
    '☕',
    '🔬',
    '🛋️',
    '🏠',
    '🎮',
    '📚',
    '🔥',
  ];

  @override
  void initState() {
    super.initState();
    nombreCtrl = TextEditingController(text: widget.apartado.nombre);
    descCtrl = TextEditingController(text: widget.apartado.descripcion);
    emojiSelec = widget.apartado.icono;
    imagePathSelec = widget.apartado.imagePath;
  }

  @override
  void dispose() {
    nombreCtrl.dispose();
    descCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirmarEliminar() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Eliminar apartado'),
        content: Text(
          '¿Seguro que quieres eliminar "${widget.apartado.nombre}"? '
          'También se eliminarán sus espacios y objetos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmado == true && mounted) {
      Navigator.pop(context);
      widget.onEliminar(widget.apartado);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Editar Apartado',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SelectorImagenIcono(
              emoji: emojiSelec,
              imagePath: imagePathSelec,
              emojis: emojis,
              size: 104,
              onImagePicked: (p) => setState(() => imagePathSelec = p),
              onEmojiChange: (e) => setState(() => emojiSelec = e),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: nombreCtrl,
              decoration:
                  const InputDecoration(labelText: 'Nombre del apartado'),
            ),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Descripción breve'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _confirmarEliminar,
          child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            if (nombreCtrl.text.trim().isNotEmpty) {
              widget.onActualizar(
                Apartado(
                  id: widget.apartado.id,
                  nombre: nombreCtrl.text.trim(),
                  icono: emojiSelec,
                  imagePath: imagePathSelec,
                  descripcion: descCtrl.text.trim().isEmpty
                      ? 'Nuevo apartado'
                      : descCtrl.text.trim(),
                ),
              );
              Navigator.pop(context);
            }
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
