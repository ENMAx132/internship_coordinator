import '../models/inventory_item.dart';
import '../models/section.dart';
import '../models/space.dart';
import '../models/tutorial_pending.dart';
import 'inventory_repository.dart';
import 'tutorial_store.dart';

/// Sincroniza los datos del tutorial con la API de forma idempotente.
///
/// Reutiliza sección/espacio por nombre y objeto por código fijo
/// (`TUTORIAL-001`), guardando los IDs remotos después de cada paso para
/// poder continuar si una sincronización falla a la mitad.
class TutorialSyncService {
  TutorialSyncService({
    required this.repository,
    required this.store,
  });

  final InventoryRepository repository;
  final TutorialStore store;

  Future<TutorialPending> sync(
    TutorialPending pending, {
    void Function(TutorialPending updated)? onProgress,
  }) async {
    var current = pending;

    if (current.remoteSectionId == null) {
      final sections = await repository.fetchSections();
      final existing = _findSection(sections, current.sectionName);
      if (existing != null) {
        current = current.copyWith(
          remoteSectionId: existing.id,
          sectionCreatedByTutorial: false,
        );
      } else {
        final created = await repository.createSection(
          name: current.sectionName,
          description: current.sectionDescription,
          icon: current.sectionIcon,
        );
        current = current.copyWith(
          remoteSectionId: created.id,
          sectionCreatedByTutorial: true,
        );
      }
      await store.savePending(current);
      onProgress?.call(current);
    }

    if (current.remoteSpaceId == null) {
      final spaces = await repository.fetchSpaces(current.remoteSectionId!);
      final existing = _findSpace(spaces, current.spaceName);
      if (existing != null) {
        current = current.copyWith(
          remoteSpaceId: existing.id,
          spaceCreatedByTutorial: false,
        );
      } else {
        final created = await repository.createSpace(
          sectionId: current.remoteSectionId!,
          name: current.spaceName,
          description: current.spaceDescription,
          emoji: current.spaceEmoji,
        );
        current = current.copyWith(
          remoteSpaceId: created.id,
          spaceCreatedByTutorial: true,
        );
      }
      await store.savePending(current);
      onProgress?.call(current);
    }

    if (current.remoteItemId == null) {
      final items = await repository.fetchItems();
      final existing = _findItem(items, current.itemCode);
      if (existing != null) {
        current = current.copyWith(
          remoteItemId: existing.id,
          itemCreatedByTutorial: false,
        );
      } else {
        final created = await repository.createItem(
          name: current.itemName,
          spaceId: current.remoteSpaceId!,
          code: current.itemCode,
          category: current.categoryCode,
          status: current.statusCode,
          value: current.value,
          responsible: current.responsible,
          brand: current.brand,
        );
        current = current.copyWith(
          remoteItemId: created.id,
          itemCreatedByTutorial: true,
        );
      }
      await store.savePending(current);
      onProgress?.call(current);
    }

    return current;
  }

  /// Elimina únicamente los registros que el tutorial creó en la API.
  Future<void> deleteRemote(TutorialPending pending) async {
    if (pending.remoteItemId != null && pending.itemCreatedByTutorial) {
      await repository.deleteItem(pending.remoteItemId!);
    }
    if (pending.remoteSpaceId != null && pending.spaceCreatedByTutorial) {
      await repository.deleteSpace(pending.remoteSpaceId!);
    }
    if (pending.remoteSectionId != null && pending.sectionCreatedByTutorial) {
      await repository.deleteSection(pending.remoteSectionId!);
    }
  }

  Section? _findSection(List<Section> sections, String name) {
    final target = _normalize(name);
    for (final section in sections) {
      if (_normalize(section.name) == target) return section;
    }
    return null;
  }

  Space? _findSpace(List<Space> spaces, String name) {
    final target = _normalize(name);
    for (final space in spaces) {
      if (_normalize(space.name) == target) return space;
    }
    return null;
  }

  InventoryItem? _findItem(List<InventoryItem> items, String code) {
    final target = code.trim().toLowerCase();
    for (final item in items) {
      if (item.code.trim().toLowerCase() == target) return item;
    }
    return null;
  }

  static String _normalize(String value) {
    const accents = {
      'á': 'a',
      'é': 'e',
      'í': 'i',
      'ó': 'o',
      'ú': 'u',
      'ü': 'u',
      'ñ': 'n',
    };
    var result = value.trim().toLowerCase();
    accents.forEach((from, to) => result = result.replaceAll(from, to));
    return result;
  }
}
