import 'account.dart';

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
    this.isPersonal = false,
    this.owner,
    this.assignedUsers = const [],
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

  /// `true` cuando el apartado pertenece al inventario personal de un usuario.
  final bool isPersonal;
  final UserRef? owner;
  final List<UserRef> assignedUsers;

  bool get isAssigned => !isPersonal && assignedUsers.isNotEmpty;

  bool isOwnedBy(int userId) => owner?.id == userId;

  factory Section.fromJson(Map<String, dynamic> json) {
    final owner = json['owner'];
    final assigned = json['assigned_users'];
    return Section(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      icon: json['icon'] as String? ?? '🏢',
      imageUrl: (json['image_url'] ?? json['imageUrl']) as String?,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      spaceCount: (json['space_count'] as num?)?.toInt(),
      itemCount: (json['item_count'] as num?)?.toInt(),
      totalValue: (json['total_value'] as num?)?.toDouble(),
      isPersonal: json['is_personal'] as bool? ??
          (json['owner'] is Map || json['owner_id'] != null),
      owner: owner is Map
          ? UserRef.fromJson(Map<String, dynamic>.from(owner))
          : null,
      assignedUsers: assigned is List
          ? assigned
              .whereType<Map>()
              .map((e) => UserRef.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
    );
  }

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
        'is_personal': isPersonal,
        'owner': owner?.toJson(),
        'assigned_users': assignedUsers.map((e) => e.toJson()).toList(),
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
    bool? isPersonal,
    UserRef? owner,
    List<UserRef>? assignedUsers,
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
        isPersonal: isPersonal ?? this.isPersonal,
        owner: owner ?? this.owner,
        assignedUsers: assignedUsers ?? this.assignedUsers,
      );
}
