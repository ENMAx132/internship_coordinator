import 'package:flutter/material.dart';

import '../../data/inventario_data.dart';
import '../../models/espacio.dart';
import '../../models/objeto_inventario.dart';
import '../../widgets/seleccionar_imagen_icono.dart';

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
  late String? imagePathSelec;
  bool _nombreInvalido = false;
  bool _placaInvalida = false;
  bool _valorInvalido = false;

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
    imagePathSelec = widget.objeto.imagePath;
  }

  void _guardar() {
    final nombre = nombreCtrl.text.trim();
    final placa = placaCtrl.text.trim();
    final valorTexto = valorCtrl.text.trim();
    final valor = valorTexto.isEmpty
        ? 0.0
        : double.tryParse(valorTexto.replaceAll(',', '.'));
    final placaDuplicada = objetosIniciales.any(
      (o) =>
          o.id != widget.objeto.id &&
          o.placa.trim().toLowerCase() == placa.toLowerCase(),
    );

    final nombreInvalido = nombre.isEmpty;
    final placaInvalida = placa.isEmpty || placaDuplicada;
    final valorInvalido = valor == null || valor < 0;

    setState(() {
      _nombreInvalido = nombreInvalido;
      _placaInvalida = placaInvalida;
      _valorInvalido = valorInvalido;
    });
    if (nombreInvalido || placaInvalida || valorInvalido) return;

    widget.onActualizar(
      ObjetoInventario(
        id: widget.objeto.id,
        placa: placa,
        nombre: nombre,
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
        fechaEnRevision: ObjetoInventario.esEstadoEnRevision(estadoSelec)
            ? DateTime.now()
            : widget.objeto.fechaEnRevision,
        imagePath: imagePathSelec,
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
          '¿Seguro que quieres eliminar "${widget.objeto.nombre}"?',
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
      widget.onEliminar(widget.objeto);
    }
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
            SelectorImagenIcono(
              emoji: widget.espacios.isNotEmpty ? widget.espacios.first.emoji : '📦',
              imagePath: imagePathSelec,
              onImagePicked: (p) => setState(() => imagePathSelec = p),
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
                errorText:
                    _nombreInvalido ? 'El nombre es obligatorio' : null,
              ),
            ),
            TextField(
              controller: placaCtrl,
              onChanged: (value) {
                if (_placaInvalida) {
                  setState(() => _placaInvalida = false);
                }
              },
              decoration: InputDecoration(
                labelText: 'C\u00F3digo / Placa',
                errorText:
                    _placaInvalida ? 'Placa vacía o ya registrada' : null,
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