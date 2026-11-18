import 'package:flutter/material.dart';

import '../core/api_exception.dart';
import '../core/inventory_scope.dart';
import '../data/inventory_store.dart';
import '../models/catalog.dart';
import '../models/inventory_item.dart';
import '../widgets/icono_widget.dart';
import '../widgets/offline_banner.dart';

class VerRevisionScreen extends StatefulWidget {
  const VerRevisionScreen({super.key});

  @override
  State<VerRevisionScreen> createState() => _VerRevisionScreenState();
}

class _VerRevisionScreenState extends State<VerRevisionScreen> {
  final TextEditingController _filtroTextoCtrl = TextEditingController();
  final List<int> _order = [];

  InventoryStore get _store => InventoryScope.of(context);

  List<InventoryItem> _ordenados(InventoryStore store) {
    final items = store.itemsInReview;
    final ids = items.map((item) => item.id).toSet();
    _order.removeWhere((id) => !ids.contains(id));
    for (final item in items) {
      if (!_order.contains(item.id)) _order.add(item.id);
    }
    final positions = <int, int>{
      for (var i = 0; i < _order.length; i++) _order[i]: i,
    };
    final lista = [...items]
      ..sort((a, b) {
        final posA = positions[a.id] ?? 1 << 30;
        final posB = positions[b.id] ?? 1 << 30;
        return posA.compareTo(posB);
      });
    return lista;
  }

  List<InventoryItem> _filtrados(InventoryStore store) {
    final q = _filtroTextoCtrl.text.trim().toLowerCase();
    final lista = _ordenados(store);
    if (q.isEmpty) return lista;
    return lista
        .where(
          (item) =>
              item.name.toLowerCase().contains(q) ||
              item.code.toLowerCase().contains(q) ||
              item.brand.toLowerCase().contains(q),
        )
        .toList();
  }

  void _reordenar(int oldIndex, int newIndex) {
    final store = _store;
    final visibles = _filtrados(store);
    if (oldIndex < 0 || oldIndex >= visibles.length) return;
    final idsVisibles = visibles.map((item) => item.id).toList();
    final movido = idsVisibles.removeAt(oldIndex);
    idsVisibles.insert(newIndex.clamp(0, idsVisibles.length), movido);

    setState(() {
      final visiblesSet = idsVisibles.toSet();
      var j = 0;
      for (var i = 0; i < _order.length; i++) {
        if (visiblesSet.contains(_order[i])) {
          _order[i] = idsVisibles[j++];
        }
      }
    });
  }

  Future<void> _editarEstado(InventoryItem item) async {
    final store = _store;
    if (!store.canWrite || store.offline) return;
    final seleccionado = await showDialog<CatalogEntry>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Cambiar estado',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: store.catalogs.statuses.map((status) {
              final activo = item.status.code == status.code;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  activo
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: activo
                      ? const Color(0xFF6366F1)
                      : const Color(0xFF94A3B8),
                ),
                title: Text(status.name),
                onTap: () => Navigator.pop(ctx, status),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
    if (seleccionado == null || seleccionado.code == item.status.code) return;

    try {
      await store.updateItemStatus(
        item.id,
        statusCode: seleccionado.code,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Estado actualizado correctamente.')),
      );
    } on ApiException catch (error) {
      store.handleError(error);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(messageForApiError(error))),
      );
    }
  }

  String _formatearFecha(DateTime fecha) {
    final local = fecha.toLocal();
    final dia = local.day.toString().padLeft(2, '0');
    final mes = local.month.toString().padLeft(2, '0');
    final hora = local.hour.toString().padLeft(2, '0');
    final minuto = local.minute.toString().padLeft(2, '0');
    return '$dia/$mes/${local.year} $hora:$minuto';
  }

  @override
  void dispose() {
    _filtroTextoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = _store;
    final objetos = _filtrados(store);
    final canWrite = store.canWrite && !store.offline;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF0F172A),
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'En Revisión',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Color(0xFF0F172A),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (store.offline)
              OfflineBanner(
                message: 'Sin conexión. Los cambios están deshabilitados.',
                onRetry: store.retryConnection,
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: TextField(
                controller: _filtroTextoCtrl,
                onChanged: (val) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Buscar por nombre, placa o marca...',
                  prefixIcon: Icon(Icons.search, color: Color(0xFF94A3B8)),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.build_outlined,
                    size: 16,
                    color: Color(0xFF6366F1),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${objetos.length} objeto${objetos.length == 1 ? '' : 's'} '
                      'en revisión • Arrastra para ordenar por importancia',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: objetos.isEmpty
                  ? const Center(
                      child: Text('No hay objetos en revisión'),
                    )
                  : ReorderableListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      itemCount: objetos.length,
                      buildDefaultDragHandles: false,
                      onReorder: _reordenar,
                      itemBuilder: (context, index) {
                        return _construirItem(
                          store,
                          objetos[index],
                          index,
                          canWrite,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirItem(
    InventoryStore store,
    InventoryItem item,
    int index,
    bool canWrite,
  ) {
    final space = store.spaceById(item.spaceId);
    final prioridad = index + 1;
    return GestureDetector(
      key: ValueKey(item.id),
      onLongPress: canWrite ? () => _editarEstado(item) : null,
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
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Color(0xFFEEF2FF),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$prioridad',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6366F1),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                borderRadius: BorderRadius.all(Radius.circular(12)),
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
                    '${item.category.name} • ${item.brand}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    space != null
                        ? store.spacePath(space.id)
                        : item.spaceName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _formatearFecha(item.inReviewAt ?? item.registeredAt),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${item.value.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6366F1),
                  ),
                ),
                const SizedBox(height: 3),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.status.name,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFB45309),
                    ),
                  ),
                ),
              ],
            ),
            if (canWrite)
              ReorderableDragStartListener(
                index: index,
                child: Container(
                  width: 36,
                  height: 44,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.drag_indicator,
                    color: Color(0xFF94A3B8),
                    size: 22,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
