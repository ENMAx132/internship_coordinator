import 'package:flutter/material.dart';

import '../../models/catalog.dart';
import '../../models/drafts.dart';
import '../../models/inventory_item.dart';
import '../../models/space.dart';
import '../../widgets/seleccionar_imagen_icono.dart';

class EditarObjetoDialog extends StatefulWidget {
  final InventoryItem item;
  final List<Space> spaces;
  final Catalogs catalogs;
  final ValueChanged<ItemChanges> onActualizar;
  final VoidCallback onEliminar;

  const EditarObjetoDialog({
    super.key,
    required this.item,
    required this.spaces,
    required this.catalogs,
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
  late int spaceIdSelec;
  late String categoryCodeSelec;
  late String statusCodeSelec;
  String? localImagePath;
  bool _nombreInvalido = false;
  bool _placaInvalida = false;
  bool _valorInvalido = false;

  @override
  void initState() {
    super.initState();
    nombreCtrl = TextEditingController(text: widget.item.name);
    placaCtrl = TextEditingController(text: widget.item.code);
    marcaCtrl = TextEditingController(text: widget.item.brand);
    respCtrl = TextEditingController(text: widget.item.responsible);
    valorCtrl = TextEditingController(text: widget.item.value.toString());
    spaceIdSelec = widget.item.spaceId;
    categoryCodeSelec = widget.item.category.code;
    statusCodeSelec = widget.item.status.code;
  }

  @override
  void dispose() {
    nombreCtrl.dispose();
    placaCtrl.dispose();
    marcaCtrl.dispose();
    respCtrl.dispose();
    valorCtrl.dispose();
    super.dispose();
  }

  void _guardar() {
    final nombre = nombreCtrl.text.trim();
    final placa = placaCtrl.text.trim();
    final valorTexto = valorCtrl.text.trim();
    final valor = valorTexto.isEmpty
        ? 0.0
        : double.tryParse(valorTexto.replaceAll(',', '.'));

    final nombreInvalido = nombre.isEmpty;
    final placaInvalida = placa.isEmpty;
    final valorInvalido = valor == null || valor < 0;

    setState(() {
      _nombreInvalido = nombreInvalido;
      _placaInvalida = placaInvalida;
      _valorInvalido = valorInvalido;
    });
    if (nombreInvalido || placaInvalida || valorInvalido) return;

    widget.onActualizar(
      ItemChanges(
        spaceId: spaceIdSelec,
        name: nombre,
        code: placa,
        categoryCode: categoryCodeSelec,
        statusCode: statusCodeSelec,
        value: valor,
        responsible: respCtrl.text.trim().isEmpty
            ? widget.item.responsible
            : respCtrl.text.trim(),
        brand: marcaCtrl.text.trim().isEmpty
            ? widget.item.brand
            : marcaCtrl.text.trim(),
        imageUrl: widget.item.imageUrl,
        localImagePath: localImagePath,
      ),
    );
    Navigator.pop(context);
  }

  Future<void> _confirmarEliminar() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Eliminar objeto'),
        content: Text(
          '¿Seguro que quieres eliminar "${widget.item.name}"?',
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
    final categorias = <String, String>{
      for (final category in widget.catalogs.categories)
        category.code: category.name,
      widget.item.category.code: widget.item.category.name,
    };
    final estados = <String, String>{
      for (final status in widget.catalogs.statuses)
        status.code: status.name,
      widget.item.status.code: widget.item.status.name,
    };

    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Editar Objeto',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SelectorImagenIcono(
              emoji: widget.spaces.isNotEmpty
                  ? widget.spaces.first.emoji
                  : '📦',
              imageUrl: widget.item.imageUrl,
              localImagePath: localImagePath,
              onImagePicked: (p) => setState(() => localImagePath = p),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: nombreCtrl,
              onChanged: (value) {
                if (_nombreInvalido && value.trim().isNotEmpty) {
                  setState(() => _nombreInvalido = false);
                }
              },
              decoration: InputDecoration(
                labelText: 'Nombre del objeto',
                errorText: _nombreInvalido ? 'El nombre es obligatorio' : null,
              ),
            ),
            TextField(
              controller: placaCtrl,
              onChanged: (value) {
                if (_placaInvalida && value.trim().isNotEmpty) {
                  setState(() => _placaInvalida = false);
                }
              },
              decoration: InputDecoration(
                labelText: 'Código / Placa',
                errorText: _placaInvalida ? 'La placa es obligatoria' : null,
              ),
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
              onChanged: (value) {
                if (_valorInvalido) {
                  setState(() => _valorInvalido = false);
                }
              },
              decoration: InputDecoration(
                labelText: 'Precio',
                errorText: _valorInvalido
                    ? 'Ingresa un valor válido (mayor o igual a 0)'
                    : null,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: categoryCodeSelec,
              decoration: const InputDecoration(labelText: 'Tipo'),
              items: categorias.entries.map((entry) {
                return DropdownMenuItem(
                  value: entry.key,
                  child: Text(entry.value),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => categoryCodeSelec = val);
              },
            ),
            DropdownButtonFormField<String>(
              initialValue: statusCodeSelec,
              decoration: const InputDecoration(labelText: 'Estado'),
              items: estados.entries.map((entry) {
                return DropdownMenuItem(
                  value: entry.key,
                  child: Text(entry.value),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => statusCodeSelec = val);
              },
            ),
            DropdownButtonFormField<int>(
              initialValue: spaceIdSelec,
              decoration: const InputDecoration(labelText: 'Espacio / Sala'),
              items: widget.spaces.map((e) {
                return DropdownMenuItem(
                  value: e.id,
                  child: Text('${e.emoji} ${e.name}'),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => spaceIdSelec = val);
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
          onPressed: _guardar,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
