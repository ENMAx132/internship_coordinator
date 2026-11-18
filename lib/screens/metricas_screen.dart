import 'package:flutter/material.dart';

import '../core/api_exception.dart';
import '../core/inventory_scope.dart';
import '../data/inventory_store.dart';
import '../models/inventory_item.dart';
import '../models/section.dart';
import '../models/space.dart';
import '../widgets/icono_widget.dart';
import '../widgets/offline_banner.dart';
import 'ver_revision_screen.dart';
import 'ver_todos_objetos_screen.dart';

class MetricasScreen extends StatefulWidget {
  const MetricasScreen({super.key, required this.onLogout});

  final VoidCallback onLogout;

  @override
  State<MetricasScreen> createState() => _MetricasScreenState();
}

class _MetricasScreenState extends State<MetricasScreen> {
  int? _sectionIdSeleccionada;

  InventoryStore get _store => InventoryScope.of(context);

  List<Space> _spaces(InventoryStore store) {
    if (_sectionIdSeleccionada == null) return store.spaces;
    return store.spacesForSection(_sectionIdSeleccionada!);
  }

  List<InventoryItem> _items(InventoryStore store) {
    if (_sectionIdSeleccionada == null) return store.items;
    return store.itemsForSection(_sectionIdSeleccionada!);
  }

  double _valorTotal(List<InventoryItem> items) =>
      items.fold(0.0, (total, item) => total + item.value);

  int _enRevision(List<InventoryItem> items) =>
      items.where((item) => item.isInReview).length;

  List<Space> _spacesDe(InventoryStore store, Section section) =>
      store.spacesForSection(section.id);

  List<InventoryItem> _itemsDe(InventoryStore store, Section section) =>
      store.itemsForSection(section.id);

  Future<void> _reordenar(int oldIndex, int newIndex) async {
    final store = _store;
    if (!store.canWrite || store.offline) return;
    final ids = store.sections.map((section) => section.id).toList();
    if (oldIndex < 0 || oldIndex >= ids.length) return;
    final movido = ids.removeAt(oldIndex);
    ids.insert(newIndex.clamp(0, ids.length), movido);
    try {
      await store.reorderSections(ids);
    } on ApiException catch (error) {
      store.handleError(error);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(messageForApiError(error))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = _store;
    final canWrite = store.canWrite && !store.offline;
    final spaces = _spaces(store);
    final items = _items(store);
    final totalValue = _valorTotal(items);
    final inReview = _enRevision(items);

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        if (store.offline)
          OfflineBanner(
            message: 'Sin conexión. Mostrando métricas guardadas.',
            onRetry: store.retryConnection,
          ),
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Métricas',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Resumen general y por apartado',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
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
              _construirChip('Todos', _sectionIdSeleccionada == null, () {
                setState(() => _sectionIdSeleccionada = null);
              }),
              const SizedBox(width: 8),
              ...store.sections.map(
                (section) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _construirChip(
                    '${section.icon} ${section.name}',
                    _sectionIdSeleccionada == section.id,
                    () {
                      setState(() => _sectionIdSeleccionada = section.id);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _construirMetrica(
                icono: Icons.grid_view_rounded,
                etiqueta: 'Espacios',
                valor: '${spaces.length}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _construirMetrica(
                icono: Icons.inventory_2_outlined,
                etiqueta: 'Objetos',
                valor: '${items.length}',
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VerTodosObjetosScreen(
                        sectionId: _sectionIdSeleccionada,
                      ),
                    ),
                  );
                  if (mounted) setState(() {});
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _construirMetrica(
                icono: Icons.attach_money,
                etiqueta: 'Valor total',
                valor: '\$${totalValue.toStringAsFixed(2)}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _construirMetrica(
                icono: Icons.build_outlined,
                etiqueta: 'En revisión',
                valor: '$inReview',
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const VerRevisionScreen(),
                    ),
                  );
                  if (mounted) setState(() {});
                },
              ),
            ),
          ],
        ),
        if (_sectionIdSeleccionada == null) ...[
          const SizedBox(height: 24),
          const Text(
            'Detalle por apartado',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            canWrite
                ? 'Arrastra desde el ícono para cambiar el orden de los '
                    'apartados en Inicio.'
                : 'Resumen de cada apartado.',
            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 10),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: store.sections.length,
            onReorderItem: _reordenar,
            itemBuilder: (context, index) {
              return _construirApartado(
                store,
                store.sections[index],
                index,
                canWrite,
              );
            },
          ),
        ],
      ],
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

  Widget _construirMetrica({
    required IconData icono,
    required String etiqueta,
    required String valor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icono, size: 20, color: const Color(0xFF6366F1)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    etiqueta,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    valor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirApartado(
    InventoryStore store,
    Section section,
    int index,
    bool canWrite,
  ) {
    final spaces = _spacesDe(store, section);
    final items = _itemsDe(store, section);
    return GestureDetector(
      key: ValueKey(section.id),
      onTap: () {
        setState(() => _sectionIdSeleccionada = section.id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconoWidget(
                  imageUrl: section.imageUrl,
                  emoji: section.icon,
                  fontSize: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    section.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: Color(0xFF94A3B8),
                ),
                if (canWrite) ...[
                  const SizedBox(width: 4),
                  ReorderableDragStartListener(
                    index: index,
                    child: Container(
                      width: 30,
                      height: 32,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.drag_indicator,
                        color: Color(0xFF94A3B8),
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _construirMiniMetrica(
                    '${spaces.length}',
                    'Espacios',
                  ),
                ),
                Expanded(
                  child: _construirMiniMetrica(
                    '${items.length}',
                    'Objetos',
                  ),
                ),
                Expanded(
                  child: _construirMiniMetrica(
                    '\$${_valorTotal(items).toStringAsFixed(0)}',
                    'Valor',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirMiniMetrica(String valor, String etiqueta) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          valor,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF6366F1),
          ),
        ),
        Text(
          etiqueta,
          style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
        ),
      ],
    );
  }
}
