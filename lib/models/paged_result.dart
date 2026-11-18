class PagedResult<T> {
  const PagedResult({
    required this.items,
    required this.total,
    required this.page,
    required this.perPage,
    required this.lastPage,
  });

  final List<T> items;
  final int total;
  final int page;
  final int perPage;
  final int lastPage;

  bool get hasMore => page < lastPage;

  factory PagedResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) parse,
  ) {
    final meta = json['meta'] is Map
        ? Map<String, dynamic>.from(json['meta'] as Map)
        : const <String, dynamic>{};
    final data = (json['data'] as List?) ?? const [];
    return PagedResult(
      items: data
          .whereType<Map>()
          .map((e) => parse(Map<String, dynamic>.from(e)))
          .toList(),
      total: (meta['total'] as num?)?.toInt() ?? data.length,
      page: (meta['current_page'] as num?)?.toInt() ?? 1,
      perPage: (meta['per_page'] as num?)?.toInt() ?? data.length,
      lastPage: (meta['last_page'] as num?)?.toInt() ?? 1,
    );
  }
}
