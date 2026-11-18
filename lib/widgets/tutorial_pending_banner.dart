import 'package:flutter/material.dart';

import '../models/tutorial_pending.dart';

class TutorialPendingBanner extends StatelessWidget {
  const TutorialPendingBanner({
    super.key,
    required this.pending,
    required this.syncing,
    this.error,
    required this.onRetry,
    this.onDiscard,
  });

  final TutorialPending pending;
  final bool syncing;
  final String? error;
  final Future<void> Function() onRetry;
  final Future<void> Function()? onDiscard;

  @override
  Widget build(BuildContext context) {
    final isKeep = pending.isKeep;
    final title = isKeep
        ? 'Datos del tutorial pendientes de sincronizar'
        : 'Eliminación del tutorial pendiente';
    final background =
        isKeep ? const Color(0xFFEEF2FF) : const Color(0xFFFEF3C7);
    final foreground =
        isKeep ? const Color(0xFF4F46E5) : const Color(0xFFB45309);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      color: background,
      child: Row(
        children: [
          Icon(
            syncing
                ? Icons.sync
                : isKeep
                    ? Icons.cloud_upload_outlined
                    : Icons.delete_outline,
            size: 18,
            color: foreground,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: foreground,
                  ),
                ),
                if (syncing)
                  Text(
                    'Sincronizando…',
                    style: TextStyle(fontSize: 11, color: foreground),
                  )
                else if (error != null && error!.isNotEmpty)
                  Text(
                    error!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFFB91C1C),
                    ),
                  ),
              ],
            ),
          ),
          if (syncing)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else ...[
            if (onDiscard != null)
              TextButton(
                onPressed: () => onDiscard!(),
                style: TextButton.styleFrom(
                  foregroundColor: foreground,
                  minimumSize: const Size(0, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: const Text(
                  'Descartar',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            TextButton(
              onPressed: () => onRetry(),
              style: TextButton.styleFrom(
                foregroundColor: foreground,
                minimumSize: const Size(0, 32),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: const Text(
                'Reintentar',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
