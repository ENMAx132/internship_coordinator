import 'package:flutter/material.dart';

import '../../models/espacio.dart';
import '../../models/objeto_inventario.dart';

class VerObjetosDialog extends StatelessWidget {
  final Espacio espacio;
  final List<ObjetoInventario> objetos;

  const VerObjetosDialog({
    super.key,
    required this.espacio,
    required this.objetos,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Objetos en ${espacio.nombre}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (objetos.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('No hay objetos registrados en este espacio'),
              )
            else
              ...objetos.map(
                (objeto) => ListTile(
                  title: Text(objeto.nombre),
                  subtitle: Text(
                    '${objeto.placa} • Precio: ${objeto.valor.toStringAsFixed(2)}',
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}
