class MetricTotals {
  const MetricTotals({
    required this.sections,
    required this.spaces,
    required this.items,
    required this.totalValue,
    required this.inReview,
  });

  final int sections;
  final int spaces;
  final int items;
  final double totalValue;
  final int inReview;

  factory MetricTotals.fromJson(Map<String, dynamic> json) => MetricTotals(
        sections: (json['sections'] as num?)?.toInt() ?? 0,
        spaces: (json['spaces'] as num?)?.toInt() ?? 0,
        items: (json['items'] as num?)?.toInt() ?? 0,
        totalValue: (json['total_value'] as num?)?.toDouble() ?? 0,
        inReview: (json['in_review'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'sections': sections,
        'spaces': spaces,
        'items': items,
        'total_value': totalValue,
        'in_review': inReview,
      };
}

class SectionMetric {
  const SectionMetric({
    required this.sectionId,
    required this.name,
    required this.icon,
    required this.spaces,
    required this.items,
    required this.totalValue,
    required this.inReview,
  });

  final int sectionId;
  final String name;
  final String icon;
  final int spaces;
  final int items;
  final double totalValue;
  final int inReview;

  factory SectionMetric.fromJson(Map<String, dynamic> json) => SectionMetric(
        sectionId: (json['section_id'] as num?)?.toInt() ?? 0,
        name: json['name'] as String? ?? '',
        icon: json['icon'] as String? ?? '🏢',
        spaces: (json['spaces'] as num?)?.toInt() ?? 0,
        items: (json['items'] as num?)?.toInt() ?? 0,
        totalValue: (json['total_value'] as num?)?.toDouble() ?? 0,
        inReview: (json['in_review'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'section_id': sectionId,
        'name': name,
        'icon': icon,
        'spaces': spaces,
        'items': items,
        'total_value': totalValue,
        'in_review': inReview,
      };
}

class InventoryMetrics {
  const InventoryMetrics({required this.totals, required this.bySection});

  final MetricTotals totals;
  final List<SectionMetric> bySection;

  factory InventoryMetrics.fromJson(Map<String, dynamic> json) =>
      InventoryMetrics(
        totals: MetricTotals.fromJson(
          json['totals'] is Map
              ? Map<String, dynamic>.from(json['totals'] as Map)
              : const {},
        ),
        bySection: ((json['by_section'] as List?) ?? const [])
            .whereType<Map>()
            .map((e) => SectionMetric.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'totals': totals.toJson(),
        'by_section': bySection.map((e) => e.toJson()).toList(),
      };

  static const empty = InventoryMetrics(
    totals: MetricTotals(
      sections: 0,
      spaces: 0,
      items: 0,
      totalValue: 0,
      inReview: 0,
    ),
    bySection: [],
  );
}
