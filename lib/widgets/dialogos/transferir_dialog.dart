import 'package:flutter/material.dart';

import '../../models/inventory_item.dart';
import '../../models/space.dart';

class TransferirDialog extends StatefulWidget {
  final InventoryItem item;
  final List<Space> spaces;
  final ValueChanged<int> onTransferir;

  const TransferirDialog({
    super.key,
    required this.item,
    required this.spaces,
    required this.onTransferir,
  });

  @override
  State<TransferirDialog> createState() => _TransferirDialogState();
}

class _TransferirDialogState extends State<TransferirDialog> {
  int? _nuevoSpaceId;

  List<Space> get _destinos => widget.spaces
      .where(
        (space) =>
            space.sectionId == widget.item.sectionId &&
            space.id != widget.item.spaceId,
      )
      .toList();

  @override
  void initState() {
    super.initState();
    final destinos = _destinos;
    _nuevoSpaceId = destinos.isNotEmpty ? destinos.first.id : null;
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
          Text('Mover "${widget.item.name}" a otro espacio o subespacio:'),
          const SizedBox(height: 12),
          if (destinos.isEmpty)
            const Text(
              'No hay otro espacio disponible en este apartado.',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            )
          else
            DropdownButtonFormField<int>(
              initialValue: _nuevoSpaceId,
              isExpanded: true,
              items: destinos
                  .map(
                    (e) => DropdownMenuItem(
                      value: e.id,
                      child: Text(
                        '${e.emoji} ${e.pathLabel(widget.spaces)}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (val) => setState(() => _nuevoSpaceId = val),
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
          onPressed: _nuevoSpaceId == null
              ? null
              : () {
                  final destino = _nuevoSpaceId!;
                  Navigator.pop(context);
                  widget.onTransferir(destino);
                },
          child: const Text('Transferir'),
        ),
      ],
    );
  }
}
