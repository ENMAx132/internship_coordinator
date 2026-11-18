import 'package:flutter/material.dart';

import '../core/inventory_scope.dart';
import '../data/inventory_store.dart';
import '../models/inventory_item.dart';
import '../models/review.dart';
import '../widgets/icono_widget.dart';
import '../widgets/offline_banner.dart';

class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key, required this.onLogout});

  final VoidCallback onLogout;

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  int _vista = 0;

  InventoryStore get _store => InventoryScope.of(context);

  InventoryItem? _itemDe(InventoryStore store, int? id) {
    if (id == null) return null;
    for (final item in store.items) {
      if (item.id == id) return item;
    }
    return null;
  }

  String _formatearFecha(DateTime fecha) {
    final local = fecha.toLocal();
    final dia = local.day.toString().padLeft(2, '0');
    final mes = local.month.toString().padLeft(2, '0');
    final hora = local.hour.toString().padLeft(2, '0');
    final minuto = local.minute.toString().padLeft(2, '0');
    return '$dia/$mes/${local.year} · $hora:$minuto';
  }

  Future<void> _refrescar(InventoryStore store) async {
    try {
      await store.refreshReviews();
      await store.refreshItems();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo actualizar el historial.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = _store;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (store.offline)
            OfflineBanner(
              message: 'Sin conexión. Mostrando el historial guardado.',
              onRetry: store.retryConnection,
            ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Historial',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _vista == 0
                          ? 'Objetos que han pasado por revisión'
                          : 'Objetos agregados y su fecha de registro',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _refrescar(store),
                tooltip: 'Actualizar',
                icon: const Icon(
                  Icons.refresh,
                  size: 20,
                  color: Color(0xFF94A3B8),
                ),
              ),
              IconButton(
                onPressed: widget.onLogout,
                tooltip: 'Cerrar sesión',
                icon: const Icon(
                  Icons.logout,
                  size: 20,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _construirChip(
                  'Revisiones',
                  _vista == 0,
                  () => setState(() => _vista = 0),
                ),
                const SizedBox(width: 8),
                _construirChip(
                  'Registros',
                  _vista == 1,
                  () => setState(() => _vista = 1),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: _vista == 0
                ? _construirRevisiones(store)
                : _construirRegistros(store),
          ),
        ],
      ),
    );
  }

  Widget _construirChip(String texto, bool seleccionado, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: seleccionado ? const Color(0xFF6366F1) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          texto,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: seleccionado ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _construirRevisiones(InventoryStore store) {
    final revisiones = [...store.reviews]
      ..sort((a, b) => b.enteredAt.compareTo(a.enteredAt));

    if (revisiones.isEmpty) {
      return _construirVacio(
        '🛠️',
        'Aún no hay objetos que hayan pasado por revisión',
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: revisiones.length,
      itemBuilder: (context, index) {
        return _construirRegistroRevision(store, revisiones[index]);
      },
    );
  }

  Widget _construirRegistroRevision(InventoryStore store, Review review) {
    final item = _itemDe(store, review.itemId);
    final space = item != null ? store.spaceById(item.spaceId) : null;
    final nombre = item?.name ?? review.itemName;
    final placa = item?.code ?? review.itemCode;
    final spaceName =
        space?.name ?? review.spaceName ?? item?.spaceName ?? 'Sin espacio';
    final emoji = space?.emoji ?? item?.spaceEmoji ?? '📍';
    final imageUrl = item?.imageUrl ?? review.imageUrl;
    final activo = review.isActive;

    return Container(
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
              imageUrl: imageUrl,
              emoji: emoji,
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        nombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: activo
                            ? const Color(0xFFFEF3C7)
                            : const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        activo ? 'En revisión' : 'Finalizada',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: activo
                              ? const Color(0xFFB45309)
                              : const Color(0xFF15803D),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '$placa · $spaceName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.login,
                      size: 12,
                      color: Color(0xFF6366F1),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Ingresó ${_formatearFecha(review.enteredAt)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6366F1),
                        ),
                      ),
                    ),
                  ],
                ),
                if (review.exitedAt != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.logout,
                        size: 12,
                        color: Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Salió ${_formatearFecha(review.exitedAt!)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (review.exitReason != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 12,
                        color: Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Motivo: ${review.exitReason}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirRegistros(InventoryStore store) {
    final objetos = [...store.items]
      ..sort((a, b) => b.registeredAt.compareTo(a.registeredAt));

    if (objetos.isEmpty) {
      return _construirVacio('🕘', 'Aún no hay objetos registrados');
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: objetos.length,
      itemBuilder: (context, index) {
        return _construirRegistroObjeto(store, objetos[index]);
      },
    );
  }

  Widget _construirRegistroObjeto(InventoryStore store, InventoryItem item) {
    final space = store.spaceById(item.spaceId);
    return Container(
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
              imageUrl: item.imageUrl ?? space?.imageUrl,
              emoji: space?.emoji ?? item.spaceEmoji,
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${item.code} · ${space?.name ?? item.spaceName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatearFecha(item.registeredAt),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6366F1),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirVacio(String emoji, String mensaje) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 10),
          Text(
            mensaje,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
