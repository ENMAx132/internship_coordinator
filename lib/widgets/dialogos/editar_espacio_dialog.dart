import 'package:flutter/material.dart';

import '../../models/apartado.dart';
import '../../models/espacio.dart';

class EditarEspacioDialog extends StatefulWidget {
  final Espacio espacio;
  final ValueChanged<Espacio> onActualizar;
  final ValueChanged<Espacio> onEliminar;
  final List<Apartado> apartados;

  const EditarEspacioDialog({
    super.key,
    required this.espacio,
    required this.onActualizar,
    required this.onEliminar,
    required this.apartados,
  });

  @override
  State<EditarEspacioDialog> createState() => _EditarEspacioDialogState();
}

class _EditarEspacioDialogState extends State<EditarEspacioDialog> {
  late final TextEditingController nombreCtrl;
  late final TextEditingController descCtrl;
  late String emojiSelec;
  late final List<String> emojis;
  late String apartadoIdSelec;

  @override
  void initState() {
    super.initState();
    nombreCtrl = TextEditingController(text: widget.espacio.nombre);
    descCtrl = TextEditingController(text: widget.espacio.descripcion);
    emojiSelec = widget.espacio.emoji;
    apartadoIdSelec = widget.espacio.apartadoId;
    emojis = ['🏢', '💻', '📊', '📦', '🤝', '☕', '🔬', '🛋️'];
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Editar Espacio', style: TextStyle(fontWeight: FontWeight.bold)),
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
              decoration: const InputDecoration(labelText: 'Nombre del espacio'),
            ),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Descripción breve'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: apartadoIdSelec,
              decoration: const InputDecoration(labelText: 'Apartado'),
              items: widget.apartados.map((e) {
                return DropdownMenuItem(
                  value: e.id,
                  child: Text('${e.icono} ${e.nombre}'),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => apartadoIdSelec = val);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            widget.onEliminar(widget.espacio);
          },
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
                Espacio(
                  id: widget.espacio.id,
                  nombre: nombreCtrl.text.trim(),
                  descripcion: descCtrl.text.trim().isEmpty
                      ? 'Área de trabajo'
                      : descCtrl.text.trim(),
                  emoji: emojiSelec,
                  apartadoId: apartadoIdSelec,
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