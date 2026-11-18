class CatalogEntry {
  const CatalogEntry({
    required this.id,
    required this.code,
    required this.name,
    this.isInReview = false,
  });

  final int id;
  final String code;
  final String name;
  final bool isInReview;

  factory CatalogEntry.fromJson(Map<String, dynamic> json) => CatalogEntry(
        id: (json['id'] as num).toInt(),
        code: json['code'] as String? ?? '',
        name: json['name'] as String? ?? '',
        isInReview: json['is_in_review'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'name': name,
        'is_in_review': isInReview,
      };
}

class Catalogs {
  const Catalogs({
    required this.categories,
    required this.statuses,
    required this.sectionEmojis,
    required this.spaceEmojis,
  });

  final List<CatalogEntry> categories;
  final List<CatalogEntry> statuses;
  final List<String> sectionEmojis;
  final List<String> spaceEmojis;

  factory Catalogs.fromJson(Map<String, dynamic> json) => Catalogs(
        categories: ((json['categories'] as List?) ?? const [])
            .whereType<Map>()
            .map((e) => CatalogEntry.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        statuses: ((json['statuses'] as List?) ?? const [])
            .whereType<Map>()
            .map((e) => CatalogEntry.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        sectionEmojis: ((json['section_emojis'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
        spaceEmojis: ((json['space_emojis'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'categories': categories.map((e) => e.toJson()).toList(),
        'statuses': statuses.map((e) => e.toJson()).toList(),
        'section_emojis': sectionEmojis,
        'space_emojis': spaceEmojis,
      };

  CatalogEntry categoryById(int id) => categories.firstWhere(
        (c) => c.id == id,
        orElse: () => categories.isEmpty
            ? const CatalogEntry(id: 0, code: 'general', name: 'General')
            : categories.first,
      );

  CatalogEntry statusById(int id) => statuses.firstWhere(
        (s) => s.id == id,
        orElse: () => statuses.isEmpty
            ? const CatalogEntry(
                id: 0,
                code: 'excellent',
                name: 'Excelente',
              )
            : statuses.first,
      );

  CatalogEntry? categoryByCode(String code) {
    for (final category in categories) {
      if (category.code == code) return category;
    }
    return null;
  }

  CatalogEntry? statusByCode(String code) {
    for (final status in statuses) {
      if (status.code == code) return status;
    }
    return null;
  }

  CatalogEntry get inReviewStatus => statuses.firstWhere(
        (s) => s.isInReview,
        orElse: () => statuses.isEmpty
            ? const CatalogEntry(
                id: 0,
                code: 'in_review',
                name: 'En revisión',
                isInReview: true,
              )
            : statuses.first,
      );

  static const empty = Catalogs(
    categories: [],
    statuses: [],
    sectionEmojis: [],
    spaceEmojis: [],
  );
}
