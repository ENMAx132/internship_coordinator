import 'package:flutter/material.dart';

import '../../models/drafts.dart';
import '../../models/section.dart';
import '../../models/space.dart';
import '../../widgets/seleccionar_imagen_icono.dart';

class EditarEspacioDialog extends StatefulWidget {
  final Space space;
  final ValueChanged<SpaceDraft> onActualizar;
  final VoidCallback onEliminar;
  final List<Section> sections;
  final List<String> emojis;

  const EditarEspacioDialog({
    super.key,
    required this.space,
    required this.onActualizar,
    required this.onEliminar,
    required this.sections,
    this.emojis = const ['🏢', '💻', '📊', '📦', '🤝', '☕', '🔬', '🛋️'],
  });

  @override
  State<EditarEspacioDialog> createState() => _EditarEspacioDialogState();
}

class _EditarEspacioDialogState extends State<EditarEspacioDialog> {
  late final TextEditingController nombreCtrl;
  late final TextEditingController descCtrl;
  late String emojiSelec;
  String? localImagePath;
  late int sectionIdSelec;

  List<String> get _emojis => widget.emojis.isEmpty
      ? const ['🏢', '💻', '📊', '📦']
      : widget.emojis;

  @override
  void initState() {
    super.initState();
    nombreCtrl = TextEditingController(text: widget.space.name);
    descCtrl = TextEditingController(text: widget.space.description);
    emojiSelec = widget.space.emoji;
    sectionIdSelec = widget.space.sectionId;
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
        title: const Text('Eliminar espacio'),
        content: Text(
          '¿Seguro que quieres eliminar "${widget.space.name}"? '
          'También se eliminarán sus objetos.',
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
        'Editar Espacio',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SelectorImagenIcono(
              emoji: emojiSelec,
              imageUrl: widget.space.imageUrl,
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
                  const InputDecoration(labelText: 'Nombre del espacio'),
            ),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Descripción breve'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<int>(
              initialValue: sectionIdSelec,
              decoration: const InputDecoration(labelText: 'Apartado'),
              items: widget.sections.map((e) {
                return DropdownMenuItem(
                  value: e.id,
                  child: Text('${e.icon} ${e.name}'),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => sectionIdSelec = val);
              },
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
                SpaceDraft(
                  sectionId: sectionIdSelec,
                  name: nombreCtrl.text.trim(),
                  description: descCtrl.text.trim().isEmpty
                      ? 'Área de trabajo'
                      : descCtrl.text.trim(),
                  emoji: emojiSelec,
                  imageUrl: widget.space.imageUrl,
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
