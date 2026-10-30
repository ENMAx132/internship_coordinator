import 'package:flutter/material.dart';

import '../../models/apartado.dart';
import '../../models/espacio.dart';

class CrearEspacioDialog extends StatefulWidget {
  final ValueChanged<Espacio> onCrear;
  final List<Apartado> apartados;

  const CrearEspacioDialog({super.key, required this.onCrear, required this.apartados});

  @override
  State<CrearEspacioDialog> createState() => _CrearEspacioDialogState();
}

class _CrearEspacioDialogState extends State<CrearEspacioDialog> {
  final nombreCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  String emojiSelec = '🏢';
  final emojis = ['🏢', '💻', '📊', '📦', '🤝', '☕', '🔬', '🛋️'];
  late String apartadoIdSelec;

  @override
  void initState() {
    super.initState();
    apartadoIdSelec = widget.apartados.isNotEmpty ? widget.apartados.first.id : '';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Nuevo Espacio', style: TextStyle(fontWeight: FontWeight.bold)),
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
                Espacio(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
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
          child: const Text('Crear Espacio'),
        ),
      ],
    );
  }
}