import 'package:flutter/material.dart';

import '../core/api_exception.dart';
import '../core/inventory_scope.dart';
import '../data/inventory_store.dart';
import '../models/section.dart';
import '../models/space.dart';
import '../widgets/dialogos/crear_espacio_dialog.dart';
import '../widgets/dialogos/editar_apartado_dialog.dart';
import '../widgets/dialogos/editar_espacio_dialog.dart';
import '../widgets/icono_widget.dart';
import '../widgets/offline_banner.dart';
import '../widgets/sector_card.dart';
import 'espacio_screen.dart';

class ApartadoScreen extends StatefulWidget {
  final Section section;

  const ApartadoScreen({super.key, required this.section});

  @override
  State<ApartadoScreen> createState() => _ApartadoScreenState();
}

class _ApartadoScreenState extends State<ApartadoScreen> {
  InventoryStore get _store => InventoryScope.of(context);

  Section get _section =>
      _store.sectionById(widget.section.id) ?? widget.section;

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

  void _abrirEspacio(Space space) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EspacioScreen(space: space),
      ),
    );
  }

  void _dialogoEditarApartado() {
    final store = _store;
    showDialog(
      context: context,
      builder: (ctx) => EditarApartadoDialog(
        section: _section,
        onActualizar: (draft) {
          _run(
            () => store.updateSection(_section.id, draft),
            success: 'Apartado actualizado con éxito.',
          );
        },
        onEliminar: () {
          _run(() async {
            await store.deleteSection(_section.id);
            if (mounted) Navigator.pop(context);
          }, success: 'Apartado eliminado correctamente.');
        },
      ),
    );
  }

  void _dialogoCrearEspacio() {
    final store = _store;
    showDialog(
      context: context,
      builder: (ctx) => CrearEspacioDialog(
        sections: [_section],
        emojis: store.catalogs.spaceEmojis,
        onCrear: (draft) {
          _run(
            () => store.createSpace(draft),
            success: 'Espacio creado correctamente.',
          );
        },
      ),
    );
  }

  void _dialogoEditarEspacio(Space space) {
    final store = _store;
    showDialog(
      context: context,
      builder: (ctx) => EditarEspacioDialog(
        space: space,
        sections: store.sections,
        emojis: store.catalogs.spaceEmojis,
        onActualizar: (draft) {
          _run(
            () => store.updateSpace(space.id, draft),
            success: 'Espacio actualizado con éxito.',
          );
        },
        onEliminar: () {
          _run(
            () => store.deleteSpace(space.id),
            success: 'Espacio eliminado correctamente.',
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = _store;
    final canWrite = store.canWrite && !store.offline;
    final section = _section;
    final spaces = store.spacesForSection(section.id);
    final itemCount = store.itemsForSection(section.id).length;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(section.name),
        actions: [
          if (canWrite)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Editar apartado',
              onPressed: _dialogoEditarApartado,
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
                        imageUrl: section.imageUrl,
                        emoji: section.icon,
                        fontSize: 30,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            section.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            section.description,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${spaces.length} espacios • $itemCount objetos',
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
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Espacios',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  if (canWrite)
                    InkWell(
                      onTap: _dialogoCrearEspacio,
                      borderRadius: BorderRadius.circular(50),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: Color(0xFF6366F1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: spaces.isEmpty
                  ? _construirEspacioVacio(canWrite)
                  : GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 1.15,
                      ),
                      itemCount: spaces.length,
                      itemBuilder: (context, index) {
                        final space = spaces[index];
                        return SectorCard(
                          space: space,
                          count: store.itemsForSpace(space.id).length,
                          isSelected: false,
                          onTap: () => _abrirEspacio(space),
                          onLongPress: canWrite
                              ? () => _dialogoEditarEspacio(space)
                              : () {},
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirEspacioVacio(bool canWrite) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🗂️', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 10),
          const Text(
            'Aún no hay espacios en este apartado',
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
              onPressed: _dialogoCrearEspacio,
              child: const Text('Agregar espacio'),
            ),
          ],
        ],
      ),
    );
  }
}
