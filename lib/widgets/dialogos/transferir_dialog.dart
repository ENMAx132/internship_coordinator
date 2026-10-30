import 'package:flutter/material.dart';

import '../../models/espacio.dart';
import '../../models/objeto_inventario.dart';

class TransferirDialog extends StatelessWidget {
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
  Widget build(BuildContext context) {
    String nuevoEspacioId = espacios.firstWhere(
      (e) => e.id != objeto.espacioId,
      orElse: () => espacios.first,
    ).id;

    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Transferir Activo', style: TextStyle(fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mover "${objeto.nombre}" a otra sala:'),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: nuevoEspacioId,
            items: espacios
                .where((e) => e.id != objeto.espacioId)
                .map((e) => DropdownMenuItem(
                  value: e.id,
                  child: Text('${e.emoji} ${e.nombre}'),
                ))
                .toList(),
            onChanged: (val) {
              if (val != null) onTransferir(val);
            },
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
          onPressed: () {
            Navigator.pop(context);
            onTransferir(nuevoEspacioId);
          },
          child: const Text('Transferir'),
        ),
      ],
    );
  }
}
