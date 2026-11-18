import 'package:flutter/material.dart';

import '../core/api_exception.dart';
import '../core/inventory_scope.dart';
import '../data/inventory_store.dart';
import '../models/inventory_item.dart';
import '../models/space.dart';
import '../widgets/dialogos/crear_objeto_dialog.dart';
import '../widgets/dialogos/editar_objeto_dialog.dart';
import '../widgets/dialogos/transferir_dialog.dart';
import '../widgets/icono_widget.dart';
import '../widgets/item_tile.dart';
import '../widgets/offline_banner.dart';

class EspacioScreen extends StatefulWidget {
  final Space space;

  const EspacioScreen({super.key, required this.space});

  @override
  State<EspacioScreen> createState() => _EspacioScreenState();
}

class _EspacioScreenState extends State<EspacioScreen> {
  InventoryStore get _store => InventoryScope.of(context);

  Space get _space => _store.spaceById(widget.space.id) ?? widget.space;

  Future<void> _run(
    Future<void> Function() action, {
    String? success,
  }) async {
    final store = _store;
    try {
      await action();
      if (success != null) _mostrarAviso(success);
    } on ApiException catch (error) {
      store.handleError(error);
      _mostrarAviso(messageForApiError(error));
    } catch (_) {
      _mostrarAviso('Ocurrió un error inesperado.');
    }
  }

  void _mostrarAviso(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }

  Future<void> _dialogoCrearObjeto() async {
    final store = _store;
    var placa = '';
    try {
      placa = await store.nextCode();
    } catch (_) {
      placa = '';
    }
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => CrearObjetoDialog(
        spaces: [_space],
        catalogs: store.catalogs,
        placaInicial: placa,
        onGuardar: (draft) {
          _run(
            () => store.createItem(draft),
            success: 'Objeto agregado correctamente.',
          );
        },
      ),
    );
  }

  void _dialogoTransferir(InventoryItem item) {
    final store = _store;
    final spaces = store.spacesForSection(_space.sectionId);
    showDialog(
      context: context,
      builder: (ctx) => TransferirDialog(
        item: item,
        spaces: spaces,
        onTransferir: (nuevoSpaceId) {
          _run(
            () => store.transferItem(item.id, nuevoSpaceId),
            success: 'Activo transferido exitosamente.',
          );
        },
      ),
    );
  }

  void _dialogoEditarObjeto(InventoryItem item) {
    final store = _store;
    showDialog(
      context: context,
      builder: (ctx) => EditarObjetoDialog(
        item: item,
        spaces: store.spacesForSection(_space.sectionId),
        catalogs: store.catalogs,
        onActualizar: (changes) {
          _run(
            () => store.updateItem(item.id, changes),
            success: 'Objeto actualizado correctamente.',
          );
        },
        onEliminar: () {
          _run(
            () => store.deleteItem(item.id),
            success: 'Objeto eliminado correctamente.',
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = _store;
    final canWrite = store.canWrite && !store.offline;
    final space = _space;
    final items = store.itemsForSpace(space.id);

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
        title: Row(
          children: [
            IconoWidget(
              imageUrl: space.imageUrl,
              emoji: space.emoji,
              fontSize: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                space.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
        actions: [
          if (canWrite)
            IconButton(
              icon: const Icon(Icons.add, color: Color(0xFF6366F1)),
              tooltip: 'Agregar objeto',
              onPressed: _dialogoCrearObjeto,
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (store.offline)
              OfflineBanner(
                message: 'Sin conexión. Los cambios están deshabilitados.',
                onRetry: store.retryConnection,
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: IconoWidget(
                        imageUrl: space.imageUrl,
                        emoji: space.emoji,
                        fontSize: 30,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            space.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            space.description,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Objetos',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    '${items.length} en este espacio',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: items.isEmpty
                  ? _construirListaVacia(canWrite)
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return ItemTile(
                          item: item,
                          space: space,
                          canWrite: canWrite,
                          onTransferir: () => _dialogoTransferir(item),
                          onLongPress: () => _dialogoEditarObjeto(item),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirListaVacia(bool canWrite) {
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      child: Column(
        children: [
          const Text('📦', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 8),
          const Text(
            'Aún no hay objetos en este espacio',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.w600,
            ),
          ),
          if (canWrite) ...[
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
              ),
              onPressed: _dialogoCrearObjeto,
              child: const Text('Agregar primer objeto'),
            ),
          ],
        ],
      ),
    );
  }
}
