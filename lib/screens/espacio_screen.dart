import 'package:flutter/material.dart';

import '../core/api_exception.dart';
import '../core/inventory_scope.dart';
import '../data/inventory_store.dart';
import '../models/inventory_item.dart';
import '../models/space.dart';
import '../widgets/dialogos/crear_espacio_dialog.dart';
import '../widgets/dialogos/crear_objeto_dialog.dart';
import '../widgets/dialogos/editar_espacio_dialog.dart';
import '../widgets/dialogos/editar_objeto_dialog.dart';
import '../widgets/dialogos/transferir_dialog.dart';
import '../widgets/icono_widget.dart';
import '../widgets/item_tile.dart';
import '../widgets/offline_banner.dart';
import '../widgets/sector_card.dart';

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

  void _dialogoCrearSubespacio() {
    final store = _store;
    final section = store.sectionById(_space.sectionId);
    showDialog(
      context: context,
      builder: (ctx) => CrearEspacioDialog(
        sections: section != null ? [section] : store.sections,
        spaces: store.spaces,
        emojis: store.catalogs.spaceEmojis,
        initialSectionId: _space.sectionId,
        initialParentSpaceId: _space.id,
        title: 'Nuevo subespacio',
        onCrear: (draft) {
          _run(
            () => store.createSpace(draft),
            success: 'Subespacio creado correctamente.',
          );
        },
      ),
    );
  }

  void _dialogoEditarEspacio(Space space, {bool cerrarPantalla = false}) {
    final store = _store;
    showDialog(
      context: context,
      builder: (ctx) => EditarEspacioDialog(
        space: space,
        sections: store.sections,
        spaces: store.spaces,
        emojis: store.catalogs.spaceEmojis,
        onActualizar: (draft) {
          _run(
            () => store.updateSpace(space.id, draft),
            success: 'Espacio actualizado con éxito.',
          );
        },
        onEliminar: () {
          _run(
            () async {
              await store.deleteSpace(space.id);
              if (cerrarPantalla && mounted) Navigator.pop(context);
            },
            success: 'Espacio eliminado correctamente.',
          );
        },
      ),
    );
  }

  void _abrirSubespacio(Space space) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EspacioScreen(space: space),
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
    final parent = space.parentIn(store.spaces);
    final subspaces = store.subspacesOf(space.id);
    final items = store.itemsForSpace(space.id);
    final totalItems = store.itemsForSpaceTree(space.id);

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
          if (canWrite) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Color(0xFF6366F1)),
              tooltip: 'Editar espacio',
              onPressed: () =>
                  _dialogoEditarEspacio(space, cerrarPantalla: true),
            ),
            IconButton(
              icon: const Icon(
                Icons.create_new_folder_outlined,
                color: Color(0xFF6366F1),
              ),
              tooltip: 'Agregar subespacio',
              onPressed: _dialogoCrearSubespacio,
            ),
            IconButton(
              icon: const Icon(Icons.add, color: Color(0xFF6366F1)),
              tooltip: 'Agregar objeto',
              onPressed: _dialogoCrearObjeto,
            ),
          ],
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            if (store.offline)
              OfflineBanner(
                message: 'Sin conexión. Los cambios están deshabilitados.',
                onRetry: store.retryConnection,
              ),
            _construirCabecera(
              space: space,
              parent: parent,
              itemsDirectos: items.length,
              subespacios: subspaces.length,
              itemsTotales: totalItems.length,
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Subespacios',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  '${subspaces.length} en este espacio',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (subspaces.isEmpty)
              _construirSubespaciosVacio(canWrite)
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.15,
                ),
                itemCount: subspaces.length,
                itemBuilder: (context, index) {
                  final sub = subspaces[index];
                  return SectorCard(
                    space: sub,
                    count: store.itemsForSpace(sub.id).length,
                    subspaces: store.subspacesOf(sub.id).length,
                    isSelected: false,
                    onTap: () => _abrirSubespacio(sub),
                    onLongPress: canWrite
                        ? () => _dialogoEditarEspacio(sub)
                        : () {},
                  );
                },
              ),
            const SizedBox(height: 20),
            Row(
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
                  '${items.length} directos · ${totalItems.length} en total',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (items.isEmpty)
              _construirListaVacia(canWrite)
            else
              for (final item in items)
                ItemTile(
                  item: item,
                  space: space,
                  canWrite: canWrite,
                  onTransferir: () => _dialogoTransferir(item),
                  onLongPress: () => _dialogoEditarObjeto(item),
                ),
          ],
        ),
      ),
    );
  }

  Widget _construirCabecera({
    required Space space,
    required Space? parent,
    required int itemsDirectos,
    required int subespacios,
    required int itemsTotales,
  }) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
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
                    if (parent != null) ...[
                      Text(
                        'En: ${parent.pathLabel(_store.spaces)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6366F1),
                        ),
                      ),
                      const SizedBox(height: 2),
                    ],
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
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _construirEtiqueta('$itemsDirectos objetos directos'),
              _construirEtiqueta('$subespacios subespacios'),
              _construirEtiqueta('$itemsTotales objetos en total'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _construirEtiqueta(String texto) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        texto,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF64748B),
        ),
      ),
    );
  }

  Widget _construirSubespaciosVacio(bool canWrite) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          const Text('🗂️', style: TextStyle(fontSize: 34)),
          const SizedBox(height: 8),
          const Text(
            'Aún no hay subespacios aquí',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.w600,
            ),
          ),
          if (canWrite) ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
              ),
              onPressed: _dialogoCrearSubespacio,
              icon: const Icon(Icons.create_new_folder_outlined, size: 18),
              label: const Text('Agregar subespacio'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _construirListaVacia(bool canWrite) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          const Text('📦', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 8),
          const Text(
            'Aún no hay objetos en este espacio',
            textAlign: TextAlign.center,
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
