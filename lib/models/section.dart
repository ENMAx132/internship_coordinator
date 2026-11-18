class Section {
  const Section({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    this.imageUrl,
    required this.sortOrder,
    this.spaceCount,
    this.itemCount,
    this.totalValue,
  });

  final int id;
  final String name;
  final String description;
  final String icon;
  final String? imageUrl;
  final int sortOrder;
  final int? spaceCount;
  final int? itemCount;
  final double? totalValue;

  factory Section.fromJson(Map<String, dynamic> json) => Section(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String? ?? '',
        description: json['description'] as String? ?? '',
        icon: json['icon'] as String? ?? '🏢',
        imageUrl: (json['image_url'] ?? json['imageUrl']) as String?,
        sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
        spaceCount: (json['space_count'] as num?)?.toInt(),
        itemCount: (json['item_count'] as num?)?.toInt(),
        totalValue: (json['total_value'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'icon': icon,
        'image_url': imageUrl,
        'sort_order': sortOrder,
        'space_count': spaceCount,
        'item_count': itemCount,
        'total_value': totalValue,
      };

  Section copyWith({
    int? id,
    String? name,
    String? description,
    String? icon,
    String? imageUrl,
    int? sortOrder,
    int? spaceCount,
    int? itemCount,
    double? totalValue,
  }) =>
      Section(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        icon: icon ?? this.icon,
        imageUrl: imageUrl ?? this.imageUrl,
        sortOrder: sortOrder ?? this.sortOrder,
        spaceCount: spaceCount ?? this.spaceCount,
        itemCount: itemCount ?? this.itemCount,
        totalValue: totalValue ?? this.totalValue,
      );
}
