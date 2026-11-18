import 'package:flutter/material.dart';

/// Etiqueta compacta de propiedad para apartados, espacios y objetos.
class InventoryBadge extends StatelessWidget {
  const InventoryBadge({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
    this.icon,
  });

  final String label;
  final Color background;
  final Color foreground;
  final IconData? icon;

  factory InventoryBadge.personal() => const InventoryBadge(
        label: 'Personal',
        background: Color(0xFFE0E7FF),
        foreground: Color(0xFF4338CA),
        icon: Icons.person_outline,
      );

  factory InventoryBadge.assigned() => const InventoryBadge(
        label: 'Asignado',
        background: Color(0xFFDCFCE7),
        foreground: Color(0xFF15803D),
        icon: Icons.people_outline,
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: foreground),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}
