import 'package:flutter/material.dart';

import '../../models/espacio.dart';
import '../../models/objeto_inventario.dart';

class EditarObjetoDialog extends StatefulWidget {
  final ObjetoInventario objeto;
  final List<Espacio> espacios;
  final ValueChanged<ObjetoInventario> onActualizar;
  final ValueChanged<ObjetoInventario> onEliminar;

  const EditarObjetoDialog({
    super.key,
    required this.objeto,
    required this.espacios,
    required this.onActualizar,
    required this.onEliminar,
  });

  @override
  State<EditarObjetoDialog> createState() => _EditarObjetoDialogState();
}

class _EditarObjetoDialogState extends State<EditarObjetoDialog> {
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
    nombreCtrl = TextEditingController(text: widget.objeto.nombre);
    placaCtrl = TextEditingController(text: widget.objeto.placa);
    marcaCtrl = TextEditingController(text: widget.objeto.marca);
    respCtrl = TextEditingController(text: widget.objeto.responsable);
    valorCtrl = TextEditingController(text: widget.objeto.valor.toString());
    espacioIdSelec = widget.objeto.espacioId;
    categoriaSelec = widget.objeto.categoria;
    estadoSelec = widget.objeto.estado;
  }

  @override
  Widget build(BuildContext context) {
    final categorias = <String>{
      ...ObjetoInventario.categoriasDisponibles,
      widget.objeto.categoria,
    };
    final estados = <String>{
      ...ObjetoInventario.estadosDisponibles,
      widget.objeto.estado,
    };

    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Editar Objeto',
          style: TextStyle(fontWeight: FontWeight.bold)),
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
              initialValue: categoriaSelec,
              decoration: const InputDecoration(labelText: 'Tipo'),
              items: categorias.map((c) {
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
              initialValue: estadoSelec,
              decoration: const InputDecoration(labelText: 'Estado'),
              items: estados.map((e) {
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
              initialValue: espacioIdSelec,
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
          onPressed: () {
            Navigator.pop(context);
            widget.onEliminar(widget.objeto);
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
            final valor = double.tryParse(valorCtrl.text.replaceAll(',', '.'));
            widget.onActualizar(
              ObjetoInventario(
                id: widget.objeto.id,
                placa: placaCtrl.text.trim(),
                nombre: nombreCtrl.text.trim(),
                espacioId: espacioIdSelec,
                categoria: categoriaSelec,
                estado: estadoSelec,
                valor: valor ?? widget.objeto.valor,
                responsable: respCtrl.text.trim().isEmpty
                    ? widget.objeto.responsable
                    : respCtrl.text.trim(),
                marca: marcaCtrl.text.trim().isEmpty
                    ? widget.objeto.marca
                    : marcaCtrl.text.trim(),
                fechaRegistro: widget.objeto.fechaRegistro,
                fechaEnRevision: estadoSelec == 'En revisión'
                    ? DateTime.now()
                    : widget.objeto.fechaEnRevision,
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