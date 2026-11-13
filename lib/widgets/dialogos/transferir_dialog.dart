import 'package:flutter/material.dart';

import '../../models/espacio.dart';
import '../../models/objeto_inventario.dart';

class TransferirDialog extends StatefulWidget {
  final ObjetoInventario objeto;
  final List<Espacio> espacios;
  final ValueChanged<String> onTransferir;

  const TransferirDialog({
    super.key,
    required this.objeto,
    required this.espacios,
    required this.onTransferir,
  });

  @override
  State<TransferirDialog> createState() => _TransferirDialogState();
}

class _TransferirDialogState extends State<TransferirDialog> {
  String? _nuevoEspacioId;

  List<Espacio> get _destinos =>
      widget.espacios.where((e) => e.id != widget.objeto.espacioId).toList();

  @override
  void initState() {
    super.initState();
    final destinos = _destinos;
    _nuevoEspacioId = destinos.isNotEmpty ? destinos.first.id : null;
  }

  @override
  Widget build(BuildContext context) {
    final destinos = _destinos;
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Transferir Activo',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mover "${widget.objeto.nombre}" a otra sala:'),
          const SizedBox(height: 12),
          if (destinos.isEmpty)
            const Text(
              'No hay otro espacio disponible en este apartado.',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            )
          else
            DropdownButtonFormField<String>(
              initialValue: _nuevoEspacioId,
              items: destinos
                  .map(
                    (e) => DropdownMenuItem(
                      value: e.id,
                      child: Text('${e.emoji} ${e.nombre}'),
                    ),
                  )
                  .toList(),
              onChanged: (val) => setState(() => _nuevoEspacioId = val),
            ),
        ],
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
          onPressed: _nuevoEspacioId == null
              ? null
              : () {
                  final destino = _nuevoEspacioId!;
                  Navigator.pop(context);
                  widget.onTransferir(destino);
                },
          child: const Text('Transferir'),
        ),
      ],
    );
  }
}
