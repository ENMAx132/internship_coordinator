import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/catalog.dart';
import '../models/inventory_item.dart';
import '../models/inventory_metrics.dart';
import '../models/inventory_settings.dart';
import '../models/review.dart';
import '../models/section.dart';
import '../models/space.dart';

class InventoryCacheSnapshot {
  const InventoryCacheSnapshot({
    required this.settings,
    required this.catalogs,
    required this.sections,
    required this.spaces,
    required this.items,
    required this.reviews,
    required this.metrics,
    required this.savedAt,
  });

  final InventorySettings settings;
  final Catalogs catalogs;
  final List<Section> sections;
  final List<Space> spaces;
  final List<InventoryItem> items;
  final List<Review> reviews;
  final InventoryMetrics metrics;
  final DateTime savedAt;
}

/// Caché local de los datos de la API para el modo sin conexión.
class LocalInventoryCache {
  static const _fileName = 'inventory_cache.json';
  static const _version = 1;
  static Future<void> _writeQueue = Future<void>.value();

  Future<File> _file() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}${Platform.pathSeparator}$_fileName');
  }

  Future<InventoryCacheSnapshot?> load() async {
    try {
      final file = await _file();
      if (!await file.exists()) return null;
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final data = Map<String, dynamic>.from(decoded);

      final settingsRaw = data['settings'];
      final catalogsRaw = data['catalogs'];
      final metricsRaw = data['metrics'];

      return InventoryCacheSnapshot(
        settings: settingsRaw is Map
            ? InventorySettings.fromJson(
                Map<String, dynamic>.from(settingsRaw),
              )
            : InventorySettings.defaults,
        catalogs: catalogsRaw is Map
            ? Catalogs.fromJson(Map<String, dynamic>.from(catalogsRaw))
            : Catalogs.empty,
        sections: _list(data['sections'], Section.fromJson),
        spaces: _list(data['spaces'], Space.fromJson),
        items: _list(data['items'], InventoryItem.fromJson),
        reviews: _list(data['reviews'], Review.fromJson),
        metrics: metricsRaw is Map
            ? InventoryMetrics.fromJson(
                Map<String, dynamic>.from(metricsRaw),
              )
            : InventoryMetrics.empty,
        savedAt: DateTime.tryParse(data['saved_at'] as String? ?? '') ??
            DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> save({
    required InventorySettings settings,
    required Catalogs catalogs,
    required List<Section> sections,
    required List<Space> spaces,
    required List<InventoryItem> items,
    required List<Review> reviews,
    required InventoryMetrics metrics,
  }) {
    final payload = {
      'version': _version,
      'saved_at': DateTime.now().toUtc().toIso8601String(),
      'settings': settings.toJson(),
      'catalogs': catalogs.toJson(),
      'sections': sections.map((e) => e.toJson()).toList(),
      'spaces': spaces.map((e) => e.toJson()).toList(),
      'items': items.map((e) => e.toJson()).toList(),
      'reviews': reviews.map((e) => e.toJson()).toList(),
      'metrics': metrics.toJson(),
    };
    _writeQueue = _writeQueue.then((_) => _write(payload));
    return _writeQueue;
  }

  Future<void> _write(Map<String, dynamic> payload) async {
    try {
      final file = await _file();
      final temp = File('${file.path}.tmp');
      await temp.writeAsString(jsonEncode(payload), flush: true);
      if (await file.exists()) {
        await file.delete();
      }
      await temp.rename(file.path);
    } catch (_) {
      // La caché es best-effort; no debe romper la app.
    }
  }

  static List<T> _list<T>(
    Object? value,
    T Function(Map<String, dynamic>) parse,
  ) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((e) => parse(Map<String, dynamic>.from(e)))
        .toList();
  }
}
