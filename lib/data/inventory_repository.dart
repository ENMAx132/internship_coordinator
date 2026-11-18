import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../core/app_config.dart';
import '../models/catalog.dart';
import '../models/inventory_item.dart';
import '../models/inventory_metrics.dart';
import '../models/inventory_settings.dart';
import '../models/paged_result.dart';
import '../models/review.dart';
import '../models/section.dart';
import '../models/space.dart';

class InventoryRepository {
  InventoryRepository(this._api);

  final ApiClient _api;

  // --- Settings -------------------------------------------------------------
  Future<InventorySettings> getSettings() async =>
      InventorySettings.fromJson(await _api.get('/settings'));

  Future<InventorySettings> updateSettings({
    bool? tutorialCompleted,
    bool updateStartSection = false,
    int? startSectionId,
  }) async =>
      InventorySettings.fromJson(
        await _api.put('/settings', body: {
          if (tutorialCompleted != null)
            'tutorial_completed': tutorialCompleted,
          if (updateStartSection) 'start_section_id': startSectionId,
        }),
      );

  // --- Catálogos ------------------------------------------------------------
  Future<Catalogs> getCatalogs() async =>
      Catalogs.fromJson(await _api.get('/catalogs'));

  // --- Métricas -------------------------------------------------------------
  Future<InventoryMetrics> getMetrics({int? sectionId}) async =>
      InventoryMetrics.fromJson(
        await _api.get('/metrics', query: {
          if (sectionId != null) 'section_id': sectionId,
        }),
      );

  // --- Apartados ------------------------------------------------------------
  Future<List<Section>> fetchSections({
    String? search,
    bool includeCounts = true,
  }) =>
      _fetchAll(
        (page) => _api.get('/sections', query: {
          if (search != null && search.isNotEmpty) 'search': search,
          'include_counts': includeCounts ? 1 : 0,
          'page': page,
          'limit': 100,
        }),
        Section.fromJson,
      );

  Future<Section> getSection(int id) async =>
      Section.fromJson(await _api.get('/sections/$id'));

  Future<Section> createSection({
    required String name,
    String? description,
    String? icon,
    String? imageUrl,
    int? sortOrder,
  }) async =>
      Section.fromJson(
        await _api.post('/sections', body: {
          'name': name,
          if (description != null) 'description': description,
          if (icon != null) 'icon': icon,
          if (imageUrl != null) 'image_url': imageUrl,
          if (sortOrder != null) 'sort_order': sortOrder,
        }),
      );

  Future<Section> updateSection(
    int id,
    Map<String, dynamic> changes,
  ) async =>
      Section.fromJson(await _api.patch('/sections/$id', body: changes));

  Future<void> deleteSection(int id) => _api.delete('/sections/$id');

  Future<void> reorderSections(List<int> ids) =>
      _api.put('/sections/order', body: {'ids': ids});

  // --- Espacios -------------------------------------------------------------
  Future<List<Space>> fetchSpaces(
    int sectionId, {
    String? search,
    bool includeCounts = true,
  }) =>
      _fetchAll(
        (page) => _api.get('/sections/$sectionId/spaces', query: {
          if (search != null && search.isNotEmpty) 'search': search,
          'include_counts': includeCounts ? 1 : 0,
          'page': page,
          'limit': 100,
        }),
        Space.fromJson,
      );

  Future<Space> getSpace(int id) async =>
      Space.fromJson(await _api.get('/spaces/$id'));

  Future<Space> createSpace({
    required int sectionId,
    required String name,
    String? description,
    String? emoji,
    int? parentSpaceId,
    String? imageUrl,
  }) async =>
      Space.fromJson(
        await _api.post('/spaces', body: {
          'section_id': sectionId,
          'name': name,
          if (description != null) 'description': description,
          if (emoji != null) 'emoji': emoji,
          if (parentSpaceId != null) 'parent_space_id': parentSpaceId,
          if (imageUrl != null) 'image_url': imageUrl,
        }),
      );

  Future<Space> updateSpace(int id, Map<String, dynamic> changes) async =>
      Space.fromJson(await _api.patch('/spaces/$id', body: changes));

  Future<void> deleteSpace(int id) => _api.delete('/spaces/$id');

  // --- Objetos --------------------------------------------------------------
  Future<List<InventoryItem>> fetchItems({
    int? sectionId,
    int? spaceId,
    String? search,
    Object? category,
    Object? status,
    String? brand,
    double? minValue,
    double? maxValue,
    String sortBy = 'value',
    String sortDir = 'desc',
  }) =>
      _fetchAll(
        (page) => _api.get('/items', query: {
          if (sectionId != null) 'section_id': sectionId,
          if (spaceId != null) 'space_id': spaceId,
          if (search != null && search.isNotEmpty) 'search': search,
          if (category != null) 'category': category,
          if (status != null) 'status': status,
          if (brand != null && brand.isNotEmpty) 'brand': brand,
          if (minValue != null) 'min_value': minValue,
          if (maxValue != null) 'max_value': maxValue,
          'sort_by': sortBy,
          'sort_dir': sortDir,
          'page': page,
          'limit': 100,
        }),
        InventoryItem.fromJson,
      );

  Future<InventoryItem> getItem(int id) async =>
      InventoryItem.fromJson(await _api.get('/items/$id'));

  Future<String> getNextCode() async {
    final json = await _api.get('/items/next-code');
    return json['code'] as String? ?? '';
  }

  Future<InventoryItem> createItem({
    required String name,
    required int spaceId,
    String? code,
    Object? category,
    Object? status,
    double? value,
    String? responsible,
    String? brand,
    String? imageUrl,
  }) async =>
      InventoryItem.fromJson(
        await _api.post('/items', body: {
          'name': name,
          'space_id': spaceId,
          if (code != null && code.isNotEmpty) 'code': code,
          if (category != null) 'category': category,
          if (status != null) 'status': status,
          if (value != null) 'value': value,
          if (responsible != null) 'responsible': responsible,
          if (brand != null) 'brand': brand,
          if (imageUrl != null) 'image_url': imageUrl,
        }),
      );

  Future<InventoryItem> updateItem(
    int id,
    Map<String, dynamic> changes,
  ) async =>
      InventoryItem.fromJson(await _api.patch('/items/$id', body: changes));

  Future<({InventoryItem item, Review? review})> updateStatus(
    int id, {
    required String status,
    String? exitReason,
  }) async {
    final json = await _api.patch('/items/$id/status', body: {
      'status': status,
      if (exitReason != null) 'exit_reason': exitReason,
    });
    final review = json['review'];
    return (
      item: InventoryItem.fromJson(
        Map<String, dynamic>.from(json['item'] as Map),
      ),
      review: review is Map
          ? Review.fromJson(Map<String, dynamic>.from(review))
          : null,
    );
  }

  Future<InventoryItem> transfer(int id, int spaceId) async =>
      InventoryItem.fromJson(
        await _api.post('/items/$id/transfer', body: {'space_id': spaceId}),
      );

  Future<void> deleteItem(int id) => _api.delete('/items/$id');

  // --- Historial ------------------------------------------------------------
  Future<List<Review>> fetchReviews({
    bool? active,
    int? itemId,
    int? sectionId,
    int? spaceId,
    String? search,
    DateTime? from,
    DateTime? to,
  }) =>
      _fetchAll(
        (page) => _api.get('/history/reviews', query: {
          if (active != null) 'active': active ? 1 : 0,
          if (itemId != null) 'item_id': itemId,
          if (sectionId != null) 'section_id': sectionId,
          if (spaceId != null) 'space_id': spaceId,
          if (search != null && search.isNotEmpty) 'search': search,
          if (from != null) 'from': _date(from),
          if (to != null) 'to': _date(to),
          'page': page,
          'limit': 100,
        }),
        Review.fromJson,
      );

  Future<Review> getReview(int id) async =>
      Review.fromJson(await _api.get('/history/reviews/$id'));

  Future<List<InventoryItem>> fetchRegistrations({
    int? sectionId,
    int? spaceId,
    String? search,
  }) =>
      _fetchAll(
        (page) => _api.get('/history/registrations', query: {
          if (sectionId != null) 'section_id': sectionId,
          if (spaceId != null) 'space_id': spaceId,
          if (search != null && search.isNotEmpty) 'search': search,
          'page': page,
          'limit': 100,
        }),
        InventoryItem.fromJson,
      );

  // --- Imágenes -------------------------------------------------------------
  Future<String> uploadImage(String filePath) async {
    final json = await _api.uploadImage(filePath);
    final url = _extractImageUrl(json);
    if (url == null) {
      throw ApiException(
        statusCode: 201,
        message: 'La API subió la imagen pero no devolvió una URL.',
        description:
            'Respuesta recibida del endpoint de uploads: $json',
        endpoint: '/inventory/uploads/images',
        rawBody: json.toString(),
      );
    }
    return AppConfig.resolveImageUrl(url) ?? url;
  }

  static String? _extractImageUrl(Map<String, dynamic> json) {
    final data = json['data'];
    final dataMap = data is Map
        ? Map<String, dynamic>.from(data)
        : const <String, dynamic>{};
    final candidates = <Object?>[
      json['url'],
      json['image_url'],
      json['location'],
      if (data is String) data,
      dataMap['url'],
      dataMap['image_url'],
      dataMap['location'],
      json['path'],
      dataMap['path'],
    ];
    for (final candidate in candidates) {
      final value = _nonEmpty(candidate);
      if (value != null) return value;
    }
    return null;
  }

  static String? _nonEmpty(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<void> deleteImage(String url) =>
      _api.delete('/uploads/images', body: {'url': url});

  // --- Helpers --------------------------------------------------------------
  Future<List<T>> _fetchAll<T>(
    Future<Map<String, dynamic>> Function(int page) request,
    T Function(Map<String, dynamic>) parse,
  ) async {
    final result = <T>[];
    var page = 1;
    var lastPage = 1;
    do {
      final json = await request(page);
      final paged = PagedResult.fromJson(json, parse);
      result.addAll(paged.items);
      lastPage = paged.lastPage;
      if (paged.items.isEmpty) break;
      page++;
    } while (page <= lastPage && page <= 50);
    return result;
  }

  static String _date(DateTime value) =>
      value.toUtc().toIso8601String().substring(0, 10);

  void dispose() => _api.dispose();
}
