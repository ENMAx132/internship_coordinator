import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../core/session.dart';
import '../models/catalog.dart';
import 'inventory_repository.dart';

/// Migra `inventario.json` (formato local anterior) a la API.
///
/// Es idempotente: reutiliza apartados por nombre, espacios por nombre dentro
/// del apartado y objetos por placa.
class LegacyMigrator {
  LegacyMigrator({
    required this.repository,
    required this.catalogs,
    required this.sessionStore,
  });

  final InventoryRepository repository;
  final Catalogs catalogs;
  final SessionStore sessionStore;

  static const _legacyFileName = 'inventario.json';

  Future<bool> migrateIfNeeded({
    void Function(String message)? onProgress,
  }) async {
    if (await sessionStore.isLegacyMigrationDone()) return false;

    final directory = await getApplicationDocumentsDirectory();
    final file = File(
      '${directory.path}${Platform.pathSeparator}$_legacyFileName',
    );
    if (!await file.exists()) {
      await sessionStore.markLegacyMigrationDone();
      return false;
    }

    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map) {
      await sessionStore.markLegacyMigrationDone();
      return false;
    }
    final data = Map<String, dynamic>.from(decoded);

    onProgress?.call('Preparando migración…');

    final existingSections = await repository.fetchSections();
    final sectionsByName = {
      for (final section in existingSections)
        _normalize(section.name): section,
    };

    final sectionIdByLegacyId = <String, int>{};
    final legacySections = _asList(data['apartados']);
    for (var index = 0; index < legacySections.length; index++) {
      final raw = legacySections[index];
      final name = (raw['nombre'] as String? ?? '').trim();
      if (name.isEmpty) continue;
      final key = _normalize(name);
      var section = sectionsByName[key];
      if (section == null) {
        onProgress?.call('Migrando apartado "$name"…');
        section = await repository.createSection(
          name: name,
          description: raw['descripcion'] as String? ?? '',
          icon: raw['icono'] as String? ?? '🏢',
          imageUrl: await _uploadLegacyImage(raw['imagePath'] as String?),
          sortOrder: index,
        );
        sectionsByName[key] = section;
      }
      sectionIdByLegacyId[raw['id']?.toString() ?? ''] = section.id;
    }

    final existingSpaces = <int, List<dynamic>>{};
    final spaceIdByLegacyId = <String, int>{};
    final legacySpaces = _asList(data['espacios']);
    for (final raw in legacySpaces) {
      final legacySectionId = raw['apartadoId']?.toString() ?? '';
      final sectionId = sectionIdByLegacyId[legacySectionId];
      if (sectionId == null) continue;
      final name = (raw['nombre'] as String? ?? '').trim();
      if (name.isEmpty) continue;

      final spaces = existingSpaces[sectionId] ??=
          await repository.fetchSpaces(sectionId);
      final key = _normalize(name);
      var space = _findSpace(spaces, key);
      if (space == null) {
        onProgress?.call('Migrando espacio "$name"…');
        space = await repository.createSpace(
          sectionId: sectionId,
          name: name,
          description: raw['descripcion'] as String? ?? '',
          emoji: raw['emoji'] as String? ?? '🏢',
          imageUrl: await _uploadLegacyImage(raw['imagePath'] as String?),
        );
        spaces.add(space);
      }
      spaceIdByLegacyId[raw['id']?.toString() ?? ''] = space.id;
    }

    final existingItems = await repository.fetchItems();
    final itemCodes = {
      for (final item in existingItems) item.code.trim().toLowerCase(),
    };

    final legacyItems = _asList(data['objetos']);
    for (final raw in legacyItems) {
      final legacySpaceId = raw['espacioId']?.toString() ?? '';
      final spaceId = spaceIdByLegacyId[legacySpaceId];
      if (spaceId == null) continue;
      final code = (raw['placa'] as String? ?? '').trim();
      if (code.isEmpty) continue;
      if (itemCodes.contains(code.toLowerCase())) continue;

      final name = (raw['nombre'] as String? ?? '').trim();
      if (name.isEmpty) continue;

      onProgress?.call('Migrando objeto "$name"…');
      await repository.createItem(
        name: name,
        spaceId: spaceId,
        code: code,
        category: _categoryCode(raw['categoria'] as String?),
        status: _statusCode(raw['estado'] as String?),
        value: (raw['valor'] as num?)?.toDouble() ?? 0,
        responsible: raw['responsable'] as String? ?? 'Sin asignar',
        brand: raw['marca'] as String? ?? '',
        imageUrl: await _uploadLegacyImage(raw['imagePath'] as String?),
      );
      itemCodes.add(code.toLowerCase());
    }

    final tutorialCompleted = data['tutorialCompletado'] as bool?;
    if (tutorialCompleted == true) {
      await repository.updateSettings(tutorialCompleted: true);
    }

    await sessionStore.markLegacyMigrationDone();
    try {
      final migrated = File(
        '${directory.path}${Platform.pathSeparator}inventario.migrated.json',
      );
      if (await migrated.exists()) {
        await migrated.delete();
      }
      await file.rename(migrated.path);
    } catch (_) {
      // Si no se puede renombrar, se deja el archivo original.
    }

    onProgress?.call('Migración completada.');
    return true;
  }

  Future<String?> _uploadLegacyImage(String? path) async {
    if (path == null || path.trim().isEmpty) return null;
    final file = File(path);
    if (!await file.exists()) return null;
    try {
      return await repository.uploadImage(file.path);
    } catch (_) {
      return null;
    }
  }

  String _categoryCode(String? name) {
    return _codeForName(catalogs.categories, name) ?? 'general';
  }

  String _statusCode(String? name) {
    return _codeForName(catalogs.statuses, name) ?? 'excellent';
  }

  String? _codeForName(List<CatalogEntry> entries, String? name) {
    if (name == null) return null;
    final target = _normalize(name);
    for (final entry in entries) {
      if (_normalize(entry.name) == target || entry.code == target) {
        return entry.code;
      }
    }
    return null;
  }

  dynamic _findSpace(List<dynamic> spaces, String normalizedName) {
    for (final space in spaces) {
      if (_normalize(space.name as String? ?? '') == normalizedName) {
        return space;
      }
    }
    return null;
  }

  List<Map<String, dynamic>> _asList(Object? value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
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
