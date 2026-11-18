import 'package:flutter/material.dart';

import '../models/inventory_item.dart';
import '../models/space.dart';
import 'icono_widget.dart';

class ItemTile extends StatelessWidget {
  final InventoryItem item;
  final Space space;
  final VoidCallback onTransferir;
  final VoidCallback onLongPress;
  final bool canWrite;

  const ItemTile({
    super.key,
    required this.item,
    required this.space,
    required this.onTransferir,
    required this.onLongPress,
    this.canWrite = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: canWrite ? onLongPress : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
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
              child: IconoWidget(
                imageUrl: item.imageUrl ?? space.imageUrl,
                emoji: space.emoji,
                fontSize: 20,
                size: 42,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${item.code} • ${space.name} • '
                    '${item.displayResponsible}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            if (canWrite)
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
