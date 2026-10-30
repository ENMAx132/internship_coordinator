import 'package:flutter/material.dart';

import '../../models/apartado.dart';

class CrearApartadoDialog extends StatefulWidget {
  final ValueChanged<Apartado> onCrear;

  const CrearApartadoDialog({super.key, required this.onCrear});

  @override
  State<CrearApartadoDialog> createState() => _CrearApartadoDialogState();
}

class _CrearApartadoDialogState extends State<CrearApartadoDialog> {
  final nombreCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  String emojiSelec = '🏢';
  final emojis = ['🏢', '💻', '📊', '📦', '🤝', '☕', '🔬', '🛋️', '🏠', '🎮', '📚', '🔥'];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Nuevo Apartado', style: TextStyle(fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              spacing: 8,
              children: emojis.map((e) {
                return ChoiceChip(
                  label: Text(e, style: const TextStyle(fontSize: 18)),
                  selected: emojiSelec == e,
                  onSelected: (sel) {
                    if (sel) setState(() => emojiSelec = e);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: nombreCtrl,
              decoration: const InputDecoration(labelText: 'Nombre del apartado'),
            ),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Descripción breve'),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
      actions: [
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
              widget.onCrear(
                Apartado(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  nombre: nombreCtrl.text.trim(),
                  icono: emojiSelec,
                  descripcion: descCtrl.text.trim().isEmpty ? 'Nuevo apartado' : descCtrl.text.trim(),
                ),
              );
              Navigator.pop(context);
            }
          },
          child: const Text('Crear Apartado'),
        ),
      ],
    );
  }
}
