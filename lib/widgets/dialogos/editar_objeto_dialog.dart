import 'package:flutter/material.dart';

import '../../models/espacio.dart';
import '../../models/objeto_inventario.dart';

class EditarObjetoDialog extends StatefulWidget {
  final ObjetoInventario objeto;
  final List<Espacio> espacios;
  final ValueChanged<ObjetoInventario> onActualizar;

  const EditarObjetoDialog({
    super.key,
    required this.objeto,
    required this.espacios,
    required this.onActualizar,
  });

  @override
  State<EditarObjetoDialog> createState() => _EditarObjetoDialogState();
}

class _EditarObjetoDialogState extends State<EditarObjetoDialog> {
  late final TextEditingController nombreCtrl;
  late final TextEditingController placaCtrl;
  late final TextEditingController categoriaCtrl;
  late final TextEditingController estadoCtrl;
  late final TextEditingController valorCtrl;
  late final TextEditingController responsableCtrl;
  late String espacioIdSelec;

  @override
  void initState() {
    super.initState();
    nombreCtrl = TextEditingController(text: widget.objeto.nombre);
    placaCtrl = TextEditingController(text: widget.objeto.placa);
    categoriaCtrl = TextEditingController(text: widget.objeto.categoria);
    estadoCtrl = TextEditingController(text: widget.objeto.estado);
    valorCtrl = TextEditingController(text: widget.objeto.valor.toString());
    responsableCtrl = TextEditingController(text: widget.objeto.responsable);
    espacioIdSelec = widget.objeto.espacioId;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Editar Objeto', style: TextStyle(fontWeight: FontWeight.bold)),
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
              decoration: const InputDecoration(labelText: 'Código / Placa'),
            ),
            TextField(
              controller: categoriaCtrl,
              decoration: const InputDecoration(labelText: 'Categoría'),
            ),
            TextField(
              controller: estadoCtrl,
              decoration: const InputDecoration(labelText: 'Estado'),
            ),
            TextField(
              controller: valorCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Valor'),
            ),
            TextField(
              controller: responsableCtrl,
              decoration: const InputDecoration(labelText: 'Responsable'),
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
            final valor = double.tryParse(valorCtrl.text.replaceAll(',', '.'));
            widget.onActualizar(
              ObjetoInventario(
                id: widget.objeto.id,
                placa: placaCtrl.text.trim(),
                nombre: nombreCtrl.text.trim(),
                espacioId: espacioIdSelec,
                categoria: categoriaCtrl.text.trim().isEmpty
                    ? widget.objeto.categoria
                    : categoriaCtrl.text.trim(),
                estado: estadoCtrl.text.trim().isEmpty
                    ? widget.objeto.estado
                    : estadoCtrl.text.trim(),
                valor: valor ?? widget.objeto.valor,
                responsable: responsableCtrl.text.trim().isEmpty
                    ? widget.objeto.responsable
                    : responsableCtrl.text.trim(),
              ),
            );
            Navigator.pop(context);
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
