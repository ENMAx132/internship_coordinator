import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/api_exception.dart';
import '../core/session.dart';
import '../models/catalog.dart';
import '../models/drafts.dart';
import '../models/inventory_item.dart';
import '../models/inventory_metrics.dart';
import '../models/inventory_settings.dart';
import '../models/review.dart';
import '../models/section.dart';
import '../models/space.dart';
import '../models/tutorial_pending.dart';
import 'inventory_repository.dart';
import 'legacy_migrator.dart';
import 'local_inventory_cache.dart';
import 'tutorial_store.dart';
import 'tutorial_sync_service.dart';

class InventoryStore extends ChangeNotifier {
  InventoryStore({
    required this.repository,
    required this.cache,
    required this.session,
    required this.sessionStore,
    required this.tutorialStore,
    this.onUnauthorized,
  });

  final InventoryRepository repository;
  final LocalInventoryCache cache;
  final Session session;
  final SessionStore sessionStore;
  final TutorialStore tutorialStore;
  final VoidCallback? onUnauthorized;

  TutorialSyncService get _tutorialSync =>
      TutorialSyncService(repository: repository, store: tutorialStore);

  Catalogs catalogs = Catalogs.empty;
  InventorySettings settings = InventorySettings.defaults;
  List<Section> sections = [];
  List<Space> spaces = [];
  List<InventoryItem> items = [];
  List<Review> reviews = [];
  InventoryMetrics metrics = InventoryMetrics.empty;

  bool loading = false;
  bool initialized = false;
  bool offline = false;
  String? lastError;
  String loadingMessage = 'Cargando inventario…';
  bool _disposed = false;

  TutorialPending? pendingTutorial;
  bool tutorialSyncing = false;
  String? tutorialSyncError;
  bool localTutorialCompleted = false;

  bool get canRead => session.user.canAccessInventory;
  bool get canWrite => session.user.canWrite;

  /// Todos los espacios del apartado, incluidos los subespacios.
  List<Space> spacesForSection(int sectionId) =>
      spaces.where((space) => space.sectionId == sectionId).toList();

  /// Solo los espacios raíz (sin espacio padre).
  List<Space> rootSpacesForSection(int sectionId) => spaces
      .where((space) => space.sectionId == sectionId && space.isRoot)
      .toList();

  /// Subespacios directos de [spaceId], sin importar cuántos niveles existan.
  List<Space> subspacesOf(int spaceId) =>
      spaces.where((space) => space.parentSpaceId == spaceId).toList();

  Set<int> descendantSpaceIds(int spaceId) =>
      Space.descendantIdsOf(spaceId, spaces);

  List<InventoryItem> itemsForSection(int sectionId) =>
      items.where((item) => item.sectionId == sectionId).toList();

  /// Objetos guardados directamente en el espacio.
  List<InventoryItem> itemsForSpace(int spaceId) =>
      items.where((item) => item.spaceId == spaceId).toList();

  /// Objetos del espacio y de todos sus subespacios.
  List<InventoryItem> itemsForSpaceTree(int spaceId) {
    final ids = <int>{spaceId, ...Space.descendantIdsOf(spaceId, spaces)};
    return items.where((item) => ids.contains(item.spaceId)).toList();
  }

  String spacePath(int spaceId) =>
      spaceById(spaceId)?.pathLabel(spaces) ?? '';

  List<InventoryItem> get itemsInReview =>
      items.where((item) => item.isInReview).toList();

  Section? sectionById(int id) {
    for (final section in sections) {
      if (section.id == id) return section;
    }
    return null;
  }

  Space? spaceById(int id) {
    for (final space in spaces) {
      if (space.id == id) return space;
    }
    return null;
  }

  bool get showPendingTutorial =>
      pendingTutorial != null && pendingTutorial!.isKeep;

  Section? get tutorialSection {
    final pending = pendingTutorial;
    if (pending == null || !pending.isKeep) return null;
    if (pending.remoteSectionId != null &&
        sectionById(pending.remoteSectionId!) != null) {
      return null;
    }
    return pending.toSection();
  }

  Space? get tutorialSpace {
    final pending = pendingTutorial;
    if (pending == null || !pending.isKeep) return null;
    if (pending.remoteSpaceId != null &&
        spaceById(pending.remoteSpaceId!) != null) {
      return null;
    }
    return pending.toSpace();
  }

  InventoryItem? get tutorialItem {
    final pending = pendingTutorial;
    if (pending == null || !pending.isKeep) return null;
    if (pending.remoteItemId != null &&
        items.any((item) => item.id == pending.remoteItemId)) {
      return null;
    }
    return pending.toItem(catalogs);
  }

  Future<void> bootstrap() async {
    loading = true;
    loadingMessage = 'Cargando inventario…';
    notifyListeners();

    pendingTutorial = await tutorialStore.loadPending();
    localTutorialCompleted = await tutorialStore.isCompletedLocally();
    notifyListeners();

    var hasData = false;
    final cached = await cache.load();
    if (cached != null) {
      _applySnapshot(cached);
      hasData = true;
      notifyListeners();
    }

    try {
      await _loadFromApi();
      offline = false;
      lastError = null;
      hasData = true;

      if (session.user.canWrite) {
        try {
          final migrated = await LegacyMigrator(
            repository: repository,
            catalogs: catalogs,
            sessionStore: sessionStore,
          ).migrateIfNeeded(onProgress: (message) {
            loadingMessage = message;
            notifyListeners();
          });
          if (migrated) {
            await _loadFromApi();
          }
        } catch (_) {
          // La migración no debe impedir usar la app.
        }
      }

      await _retryTutorialSettings();
      if (pendingTutorial != null) {
        unawaited(syncPendingTutorial());
      }
    } on ApiException catch (error) {
      offline = hasData || error.isNetworkError;
      lastError = messageForApiError(error);
      if (error.isUnauthorized) onUnauthorized?.call();
    } catch (_) {
      offline = hasData;
      lastError = 'No se pudo cargar el inventario.';
    } finally {
      loading = false;
      initialized = hasData;
      notifyListeners();
    }
  }

  Future<void> retryConnection() async {
    loading = true;
    loadingMessage = 'Reconectando…';
    notifyListeners();
    try {
      await _loadFromApi();
      offline = false;
      lastError = null;
      initialized = true;
      await _retryTutorialSettings();
      if (pendingTutorial != null) {
        unawaited(syncPendingTutorial());
      }
    } on ApiException catch (error) {
      offline = sections.isNotEmpty || items.isNotEmpty || error.isNetworkError;
      lastError = messageForApiError(error);
      if (error.isUnauthorized) onUnauthorized?.call();
      if (sections.isEmpty && items.isEmpty) {
        initialized = false;
      }
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> _retryTutorialSettings() async {
    if (!localTutorialCompleted) return;
    if (settings.tutorialCompleted) {
      await tutorialStore.clearCompletedLocally();
      localTutorialCompleted = false;
      return;
    }
    try {
      settings = await repository.updateSettings(tutorialCompleted: true);
      await tutorialStore.clearCompletedLocally();
      localTutorialCompleted = false;
      notifyListeners();
    } catch (_) {
      // Se reintentará en el próximo arranque o reconexión.
    }
  }

  Future<TutorialFinishResult> finishTutorial(
    TutorialPending pending,
  ) async {
    localTutorialCompleted = true;
    await tutorialStore.markCompletedLocally();
    notifyListeners();

    if (!offline) {
      try {
        settings = await repository.updateSettings(tutorialCompleted: true);
        await tutorialStore.clearCompletedLocally();
        localTutorialCompleted = false;
      } catch (_) {
        // Queda pendiente para reintentar.
      }
    }

    if (!pending.isKeep) {
      pendingTutorial = null;
      tutorialSyncError = null;
      await tutorialStore.clearPending();
      notifyListeners();
      return TutorialFinishResult.deleted;
    }

    pendingTutorial = pending;
    tutorialSyncError = null;
    await tutorialStore.savePending(pending);
    notifyListeners();

    if (offline) return TutorialFinishResult.pending;
    final synced = await syncPendingTutorial();
    return synced
        ? TutorialFinishResult.synced
        : TutorialFinishResult.pending;
  }

  Future<bool> syncPendingTutorial() async {
    final pending = pendingTutorial;
    if (pending == null) return true;
    if (tutorialSyncing) return false;

    tutorialSyncing = true;
    tutorialSyncError = null;
    notifyListeners();

    try {
      if (pending.isKeep) {
        final updated = await _tutorialSync.sync(
          pending,
          onProgress: (progress) {
            pendingTutorial = progress;
            notifyListeners();
          },
        );
        pendingTutorial = updated;

        // Refresca primero; si falla, conserva el pendiente con IDs remotos
        // para que el overlay siga visible y solo se reintente la lista.
        try {
          await _loadFromApi();
          pendingTutorial = null;
          tutorialSyncError = null;
          await tutorialStore.clearPending();
        } on ApiException catch (error) {
          offline = true;
          lastError = messageForApiError(error);
          tutorialSyncError =
              'Datos guardados. Reintenta para actualizar la lista.';
        }
        tutorialSyncing = false;
        notifyListeners();
        return true;
      }

      await _tutorialSync.deleteRemote(pending);
      pendingTutorial = null;
      tutorialSyncError = null;
      await tutorialStore.clearPending();
      tutorialSyncing = false;
      notifyListeners();

      try {
        await _loadFromApi();
      } on ApiException catch (error) {
        offline = true;
        lastError = messageForApiError(error);
      }
      notifyListeners();
      return true;
    } on ApiException catch (error) {
      tutorialSyncing = false;
      tutorialSyncError = messageForApiError(error);
      handleError(error);
      notifyListeners();
      return false;
    } catch (_) {
      tutorialSyncing = false;
      tutorialSyncError = 'No se pudo sincronizar el tutorial.';
      notifyListeners();
      return false;
    }
  }

  Future<void> discardPendingTutorial() async {
    final pending = pendingTutorial;
    if (pending == null) return;

    final hasRemote = pending.remoteSectionId != null ||
        pending.remoteSpaceId != null ||
        pending.remoteItemId != null;
    if (!hasRemote) {
      pendingTutorial = null;
      tutorialSyncError = null;
      await tutorialStore.clearPending();
      notifyListeners();
      return;
    }

    final deletePending = pending.copyWith(
      decision: TutorialDecision.delete,
    );
    pendingTutorial = deletePending;
    tutorialSyncError = null;
    await tutorialStore.savePending(deletePending);
    notifyListeners();

    if (offline) return;
    await syncPendingTutorial();
  }

  Future<void> _loadFromApi() async {
    catalogs = await repository.getCatalogs();
    settings = await repository.getSettings();
    sections = await repository.fetchSections();

    final spacesLists = await Future.wait(
      sections.map((section) async {
        try {
          return await repository.fetchSpaces(section.id);
        } on ApiException catch (error) {
          if (error.isNotFound) return <Space>[];
          rethrow;
        }
      }),
    );
    spaces = spacesLists.expand((list) => list).toList();
    items = await repository.fetchItems();
    reviews = await repository.fetchReviews();
    metrics = await repository.getMetrics();
    await _saveCache();
  }

  Future<void> refreshSections() async {
    sections = await repository.fetchSections();
    metrics = await repository.getMetrics();
    await _saveCache();
    notifyListeners();
  }

  Future<void> refreshSpacesForSection(int sectionId) async {
    final updated = await repository.fetchSpaces(sectionId);
    spaces = [
      ...spaces.where((space) => space.sectionId != sectionId),
      ...updated,
    ];
    await _saveCache();
    notifyListeners();
  }

  Future<void> refreshItems() async {
    items = await repository.fetchItems();
    metrics = await repository.getMetrics();
    await _saveCache();
    notifyListeners();
  }

  Future<void> refreshReviews() async {
    reviews = await repository.fetchReviews();
    await _saveCache();
    notifyListeners();
  }

  Future<void> refreshMetrics() async {
    metrics = await repository.getMetrics();
    await _saveCache();
    notifyListeners();
  }

  Future<void> updateSettings({
    bool? tutorialCompleted,
    bool updateStartSection = false,
    int? startSectionId,
  }) async {
    final updated = await repository.updateSettings(
      tutorialCompleted: tutorialCompleted,
      updateStartSection: updateStartSection,
      startSectionId: startSectionId,
    );
    settings = updated;
    await _saveCache();
    notifyListeners();
  }

  Future<void> markTutorialCompleted() =>
      updateSettings(tutorialCompleted: true);

  // --- Apartados ------------------------------------------------------------
  Future<Section> createSection(SectionDraft draft) async {
    final imageUrl = await _resolveImage(draft.localImagePath, draft.imageUrl);
    final created = await repository.createSection(
      name: draft.name,
      description: draft.description,
      icon: draft.icon,
      imageUrl: imageUrl,
    );
    await refreshSections();
    return created;
  }

  Future<void> updateSection(int id, SectionDraft draft) async {
    final imageUrl = await _resolveImage(draft.localImagePath, draft.imageUrl);
    await repository.updateSection(id, {
      'name': draft.name,
      'description': draft.description,
      'icon': draft.icon,
      'image_url': imageUrl,
    });
    await refreshSections();
  }

  Future<void> deleteSection(int id) async {
    await repository.deleteSection(id);
    sections = sections.where((section) => section.id != id).toList();
    final spaceIds = spaces
        .where((space) => space.sectionId == id)
        .map((space) => space.id)
        .toSet();
    spaces = spaces.where((space) => space.sectionId != id).toList();
    items = items
        .where((item) => !spaceIds.contains(item.spaceId))
        .toList();
    await _saveCache();
    await refreshSections();
    await refreshReviews();
  }

  Future<void> reorderSections(List<int> ids) async {
    await repository.reorderSections(ids);
    final order = <int, int>{};
    for (var i = 0; i < ids.length; i++) {
      order[ids[i]] = i;
    }
    sections = [
      for (final section in sections)
        section.copyWith(sortOrder: order[section.id] ?? section.sortOrder),
    ]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    await _saveCache();
    notifyListeners();
  }

  // --- Espacios -------------------------------------------------------------
  Future<Space> createSpace(SpaceDraft draft) async {
    _validarEspacioPadre(
      spaceId: null,
      sectionId: draft.sectionId,
      parentSpaceId: draft.parentSpaceId,
    );
    final imageUrl = await _resolveImage(draft.localImagePath, draft.imageUrl);
    final created = await repository.createSpace(
      sectionId: draft.sectionId,
      name: draft.name,
      description: draft.description,
      emoji: draft.emoji,
      parentSpaceId: draft.parentSpaceId,
      imageUrl: imageUrl,
    );
    await refreshSpacesForSection(draft.sectionId);
    await refreshSections();
    return created;
  }

  Future<void> updateSpace(int id, SpaceDraft draft) async {
    final actual = spaceById(id);
    final previousSectionId = actual?.sectionId;
    final parentChanged = actual == null ||
        actual.parentSpaceId != draft.parentSpaceId;
    _validarEspacioPadre(
      spaceId: id,
      sectionId: draft.sectionId,
      parentSpaceId: draft.parentSpaceId,
    );
    final imageUrl = await _resolveImage(draft.localImagePath, draft.imageUrl);
    await repository.updateSpace(id, {
      'section_id': draft.sectionId,
      'name': draft.name,
      'description': draft.description,
      'emoji': draft.emoji,
      if (parentChanged) 'parent_space_id': draft.parentSpaceId,
      'image_url': imageUrl,
    });
    await refreshSpacesForSection(draft.sectionId);
    if (previousSectionId != null && previousSectionId != draft.sectionId) {
      await refreshSpacesForSection(previousSectionId);
    }
    await refreshSections();
  }

  Future<void> deleteSpace(int id) async {
    final sectionId = spaceById(id)?.sectionId;
    final ids = <int>{id, ...Space.descendantIdsOf(id, spaces)};
    await repository.deleteSpace(id);
    spaces = spaces.where((space) => !ids.contains(space.id)).toList();
    items = items.where((item) => !ids.contains(item.spaceId)).toList();
    if (sectionId != null) {
      await refreshSpacesForSection(sectionId);
    }
    await refreshSections();
    await refreshReviews();
  }

  void _validarEspacioPadre({
    required int? spaceId,
    required int sectionId,
    required int? parentSpaceId,
  }) {
    if (parentSpaceId == null) return;
    if (spaceId != null && parentSpaceId == spaceId) {
      throw ApiException(
        statusCode: 400,
        message: 'Un espacio no puede ser su propio espacio padre.',
      );
    }
    final parent = spaceById(parentSpaceId);
    if (parent == null) {
      throw ApiException(
        statusCode: 400,
        message: 'El espacio padre seleccionado ya no existe.',
      );
    }
    if (parent.sectionId != sectionId) {
      throw ApiException(
        statusCode: 400,
        message: 'El espacio padre debe pertenecer al mismo apartado.',
      );
    }
    if (spaceId != null &&
        Space.descendantIdsOf(spaceId, spaces).contains(parentSpaceId)) {
      throw ApiException(
        statusCode: 400,
        message: 'No puedes mover un espacio dentro de uno de sus subespacios.',
      );
    }
  }

  // --- Objetos --------------------------------------------------------------
  Future<InventoryItem> createItem(ItemDraft draft) async {
    final imageUrl = await _resolveImage(draft.localImagePath, draft.imageUrl);
    final created = await repository.createItem(
      name: draft.name,
      spaceId: draft.spaceId,
      code: draft.code,
      category: draft.categoryCode,
      status: draft.statusCode,
      value: draft.value,
      responsible: draft.responsible,
      brand: draft.brand,
      imageUrl: imageUrl,
    );
    await refreshItems();
    final space = spaceById(draft.spaceId);
    if (space != null) {
      await refreshSpacesForSection(space.sectionId);
      await refreshSections();
    }
    await refreshReviews();
    return created;
  }

  Future<void> updateItem(int id, ItemChanges changes) async {
    final imageUrl = await _resolveImage(
      changes.localImagePath,
      changes.imageUrl,
    );
    await repository.updateItem(id, {
      if (changes.spaceId != null) 'space_id': changes.spaceId,
      if (changes.name != null) 'name': changes.name,
      if (changes.code != null) 'code': changes.code,
      if (changes.categoryCode != null) 'category': changes.categoryCode,
      if (changes.statusCode != null) 'status': changes.statusCode,
      if (changes.value != null) 'value': changes.value,
      if (changes.responsible != null) 'responsible': changes.responsible,
      if (changes.brand != null) 'brand': changes.brand,
      if (imageUrl != null) 'image_url': imageUrl,
      if (changes.exitReason != null) 'exit_reason': changes.exitReason,
    });
    await refreshItems();
    await refreshReviews();
    await refreshSections();
  }

  Future<void> updateItemStatus(
    int id, {
    required String statusCode,
    String? exitReason,
  }) async {
    await repository.updateStatus(
      id,
      status: statusCode,
      exitReason: exitReason,
    );
    await refreshItems();
    await refreshReviews();
    await refreshSections();
  }

  Future<void> transferItem(int id, int spaceId) async {
    await repository.transfer(id, spaceId);
    await refreshItems();
    final space = spaceById(spaceId);
    if (space != null) {
      await refreshSpacesForSection(space.sectionId);
    }
    await refreshSections();
  }

  Future<void> deleteItem(int id) async {
    InventoryItem? item;
    for (final element in items) {
      if (element.id == id) {
        item = element;
        break;
      }
    }
    await repository.deleteItem(id);
    items = items.where((element) => element.id != id).toList();
    if (item != null) {
      await refreshSpacesForSection(item.sectionId);
    }
    await refreshSections();
    await refreshReviews();
  }

  Future<String> nextCode() => repository.getNextCode();

  Future<String?> _resolveImage(
    String? localImagePath,
    String? existingImageUrl,
  ) async {
    if (localImagePath != null && localImagePath.trim().isNotEmpty) {
      final uploaded = await repository.uploadImage(localImagePath);
      if (uploaded.trim().isEmpty) {
        throw ApiException(
          statusCode: 201,
          message: 'La imagen se subió pero la API no devolvió una URL.',
          description: 'No se puede guardar la imagen sin una URL válida.',
          endpoint: '/inventory/uploads/images',
        );
      }
      return uploaded;
    }
    final existing = existingImageUrl?.trim();
    return existing == null || existing.isEmpty ? null : existing;
  }

  void _applySnapshot(InventoryCacheSnapshot snapshot) {
    settings = snapshot.settings;
    catalogs = snapshot.catalogs;
    sections = snapshot.sections;
    spaces = snapshot.spaces;
    items = snapshot.items;
    reviews = snapshot.reviews;
    metrics = snapshot.metrics;
  }

  void handleError(Object error) {
    if (error is! ApiException) return;
    if (error.isUnauthorized) {
      onUnauthorized?.call();
      return;
    }
    if (error.isNetworkError) {
      offline = true;
      lastError = messageForApiError(error);
      notifyListeners();
    }
  }

  Future<void> _saveCache() async {
    offline = false;
    lastError = null;
    await cache.save(
      settings: settings,
      catalogs: catalogs,
      sections: sections,
      spaces: spaces,
      items: items,
      reviews: reviews,
      metrics: metrics,
    );
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    repository.dispose();
    super.dispose();
  }
}
