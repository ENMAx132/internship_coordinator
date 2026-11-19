import 'package:flutter/material.dart';

import '../models/section.dart';
import 'icono_widget.dart';
import 'inventory_badge.dart';

class ApartadoCard extends StatelessWidget {
  final Section section;
  final int spaces;
  final int objects;
  final VoidCallback onTap;

  const ApartadoCard({
    super.key,
    required this.section,
    required this.spaces,
    required this.objects,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: IconoWidget(
                      imageUrl: section.imageUrl,
                      emoji: section.icon,
                      fontSize: 24,
                    ),
                  ),
                  const Spacer(),
                  if (section.isPersonal)
                    InventoryBadge.personal()
                  else if (section.isAssigned)
                    InventoryBadge.assigned(),
                  const SizedBox(width: 5),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Color(0xFF94A3B8),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                section.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                section.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _construirEtiqueta('$spaces espacios'),
                  const SizedBox(width: 6),
                  _construirEtiqueta('$objects objs'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _construirEtiqueta(String texto) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          texto,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}
