import 'package:flutter/material.dart';

import '../../models/drafts.dart';
import '../../models/section.dart';
import '../../widgets/seleccionar_imagen_icono.dart';

class EditarApartadoDialog extends StatefulWidget {
  final Section section;
  final ValueChanged<SectionDraft> onActualizar;
  final VoidCallback onEliminar;
  final List<String> emojis;

  const EditarApartadoDialog({
    super.key,
    required this.section,
    required this.onActualizar,
    required this.onEliminar,
    this.emojis = const ['🏢', '💻', '📊', '📦', '🤝', '☕', '🔬', '🛋️'],
  });

  @override
  State<EditarApartadoDialog> createState() => _EditarApartadoDialogState();
}

class _EditarApartadoDialogState extends State<EditarApartadoDialog> {
  late final TextEditingController nombreCtrl;
  late final TextEditingController descCtrl;
  late String emojiSelec;
  String? localImagePath;

  List<String> get _emojis => widget.emojis.isEmpty
      ? const ['🏢', '💻', '📊', '📦']
      : widget.emojis;

  @override
  void initState() {
    super.initState();
    nombreCtrl = TextEditingController(text: widget.section.name);
    descCtrl = TextEditingController(text: widget.section.description);
    emojiSelec = widget.section.icon;
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
          '¿Seguro que quieres eliminar "${widget.section.name}"? '
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
      widget.onEliminar();
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
              imageUrl: widget.section.imageUrl,
              localImagePath: localImagePath,
              emojis: _emojis,
              size: 104,
              onImagePicked: (p) => setState(() => localImagePath = p),
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
                SectionDraft(
                  name: nombreCtrl.text.trim(),
                  icon: emojiSelec,
                  imageUrl: widget.section.imageUrl,
                  description: descCtrl.text.trim().isEmpty
                      ? 'Nuevo apartado'
                      : descCtrl.text.trim(),
                  localImagePath: localImagePath,
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
