import 'package:flutter/material.dart';
import '../models/espacio.dart';
import '../models/objeto_inventario.dart';

class ItemTile extends StatelessWidget {
  final ObjetoInventario objeto;
  final Espacio espacioAsoc;
  final VoidCallback onTransferir;
  final VoidCallback onLongPress;

  const ItemTile({
    super.key,
    required this.objeto,
    required this.espacioAsoc,
    required this.onTransferir,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  espacioAsoc.emoji,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    objeto.nombre,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${objeto.placa} • ${espacioAsoc.nombre} • ${objeto.responsable}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.swap_horiz,
                color: Color(0xFF6366F1),
                size: 22,
              ),
              tooltip: 'Transferir de sala',
              onPressed: onTransferir,
            ),
          ],
        ),
      ),
    );
  }
}
