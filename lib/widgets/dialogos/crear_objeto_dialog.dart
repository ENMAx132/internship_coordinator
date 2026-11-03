import 'package:flutter/material.dart';

import '../../models/espacio.dart';
import '../../models/objeto_inventario.dart';

class CrearObjetoDialog extends StatefulWidget {
  final List<Espacio> espacios;
  final String placaInicial;
  final ValueChanged<ObjetoInventario> onGuardar;

  const CrearObjetoDialog({
    super.key,
    required this.espacios,
    required this.placaInicial,
    required this.onGuardar,
  });

  @override
  State<CrearObjetoDialog> createState() => _CrearObjetoDialogState();
}

class _CrearObjetoDialogState extends State<CrearObjetoDialog> {
  late final TextEditingController nombreCtrl;
  late final TextEditingController placaCtrl;
  late final TextEditingController marcaCtrl;
  late final TextEditingController respCtrl;
  late final TextEditingController valorCtrl;
  late String espacioIdSelec;
  late String categoriaSelec;
  late String estadoSelec;

  @override
  void initState() {
    super.initState();
    nombreCtrl = TextEditingController();
    placaCtrl = TextEditingController(text: widget.placaInicial);
    marcaCtrl = TextEditingController();
    respCtrl = TextEditingController();
    valorCtrl = TextEditingController(text: '0');
    espacioIdSelec = widget.espacios.isNotEmpty ? widget.espacios.first.id : '';
    categoriaSelec = ObjetoInventario.categoriasDisponibles.first;
    estadoSelec = ObjetoInventario.estadosDisponibles.first;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Registrar Objeto', style: TextStyle(fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nombreCtrl,
              decoration: const InputDecoration(labelText: 'Nombre del objeto'),
            ),
            TextField(
              controller: placaCtrl,
              decoration: const InputDecoration(labelText: 'C\u00F3digo / Placa'),
            ),
            TextField(
              controller: marcaCtrl,
              decoration: const InputDecoration(labelText: 'Marca'),
            ),
            TextField(
              controller: respCtrl,
              decoration: const InputDecoration(labelText: 'Responsable'),
            ),
            TextField(
              controller: valorCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Precio'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: categoriaSelec,
              decoration: const InputDecoration(labelText: 'Tipo'),
              items: ObjetoInventario.categoriasDisponibles.map((c) {
                return DropdownMenuItem(
                  value: c,
                  child: Text(c),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => categoriaSelec = val);
              },
            ),
            DropdownButtonFormField<String>(
              value: estadoSelec,
              decoration: const InputDecoration(labelText: 'Estado'),
              items: ObjetoInventario.estadosDisponibles.map((e) {
                return DropdownMenuItem(
                  value: e,
                  child: Text(e),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => estadoSelec = val);
              },
            ),
            DropdownButtonFormField<String>(
              value: espacioIdSelec,
              decoration: const InputDecoration(labelText: 'Espacio / Sala'),
              items: widget.espacios.map((e) {
                return DropdownMenuItem(
                  value: e.id,
                  child: Text('${e.emoji} ${e.nombre}'),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => espacioIdSelec = val);
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
              widget.onGuardar(
                ObjetoInventario(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  placa: placaCtrl.text.trim(),
                  nombre: nombreCtrl.text.trim(),
                  espacioId: espacioIdSelec,
                  categoria: categoriaSelec,
                  estado: estadoSelec,
                  valor: double.tryParse(valorCtrl.text.replaceAll(',', '.')) ?? 0.0,
                  responsable: respCtrl.text.trim().isEmpty
                      ? 'Sin asignar'
                      : respCtrl.text.trim(),
                  marca: marcaCtrl.text.trim(),
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