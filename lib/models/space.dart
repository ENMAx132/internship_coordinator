import 'account.dart';

class Space {
  const Space({
    required this.id,
    required this.sectionId,
    required this.name,
    required this.description,
    required this.emoji,
    this.parentSpaceId,
    this.imageUrl,
    this.itemCount,
    this.sectionName,
    this.sectionIcon,
    this.subspaceCount,
    this.totalItemCount,
    this.isPersonal = false,
    this.assignedUsers = const [],
  });

  final int id;
  final int sectionId;
  final String name;
  final String description;
  final String emoji;
  final int? parentSpaceId;
  final String? imageUrl;
  final int? itemCount;
  final String? sectionName;
  final String? sectionIcon;

  /// Número de subespacios directos informado por la API.
  final int? subspaceCount;

  /// Objetos del espacio y de todos sus subespacios, según la API.
  final int? totalItemCount;

  final bool isPersonal;
  final List<UserRef> assignedUsers;

  bool get isRoot => parentSpaceId == null;

  bool get isAssigned => !isPersonal && assignedUsers.isNotEmpty;

  factory Space.fromJson(Map<String, dynamic> json) {
    final section = json['section'];
    final sectionMap =
        section is Map ? Map<String, dynamic>.from(section) : null;
    final parent = json['parent'];
    final parentMap = parent is Map ? Map<String, dynamic>.from(parent) : null;
    final parentSpaceId = ((json['parent_space_id'] ??
            json['parentSpaceId'] ??
            parentMap?['id']) as num?)
        ?.toInt();
    final assigned = json['assigned_users'];
    return Space(
      id: (json['id'] as num).toInt(),
      sectionId: (json['section_id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      emoji: json['emoji'] as String? ?? '🏢',
      parentSpaceId: parentSpaceId == 0 ? null : parentSpaceId,
      imageUrl: (json['image_url'] ?? json['imageUrl']) as String?,
      itemCount: (json['item_count'] as num?)?.toInt(),
      sectionName: sectionMap?['name'] as String?,
      sectionIcon: sectionMap?['icon'] as String?,
      subspaceCount: (json['subspace_count'] as num?)?.toInt(),
      totalItemCount: (json['total_item_count'] as num?)?.toInt(),
      isPersonal: json['is_personal'] as bool? ?? false,
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
        'section_id': sectionId,
        'name': name,
        'description': description,
        'emoji': emoji,
        'parent_space_id': parentSpaceId,
        'image_url': imageUrl,
        'item_count': itemCount,
        'subspace_count': subspaceCount,
        'total_item_count': totalItemCount,
        'is_personal': isPersonal,
        'assigned_users': assignedUsers.map((e) => e.toJson()).toList(),
        if (sectionName != null || sectionIcon != null)
          'section': {
            'id': sectionId,
            'name': sectionName,
            'icon': sectionIcon,
          },
      };

  Space copyWith({
    int? id,
    int? sectionId,
    String? name,
    String? description,
    String? emoji,
    int? parentSpaceId,
    bool clearParent = false,
    String? imageUrl,
    int? itemCount,
    String? sectionName,
    String? sectionIcon,
    int? subspaceCount,
    int? totalItemCount,
    bool? isPersonal,
    List<UserRef>? assignedUsers,
  }) =>
      Space(
        id: id ?? this.id,
        sectionId: sectionId ?? this.sectionId,
        name: name ?? this.name,
        description: description ?? this.description,
        emoji: emoji ?? this.emoji,
        parentSpaceId:
            clearParent ? null : (parentSpaceId ?? this.parentSpaceId),
        imageUrl: imageUrl ?? this.imageUrl,
        itemCount: itemCount ?? this.itemCount,
        sectionName: sectionName ?? this.sectionName,
        sectionIcon: sectionIcon ?? this.sectionIcon,
        subspaceCount: subspaceCount ?? this.subspaceCount,
        totalItemCount: totalItemCount ?? this.totalItemCount,
        isPersonal: isPersonal ?? this.isPersonal,
        assignedUsers: assignedUsers ?? this.assignedUsers,
      );

  Space? parentIn(List<Space> allSpaces) {
    final parentId = parentSpaceId;
    if (parentId == null) return null;
    for (final space in allSpaces) {
      if (space.id == parentId) return space;
    }
    return null;
  }

  /// Ruta completa del espacio, por ejemplo `Sala 1 / Cajón A / Caja 3`.
  String pathLabel(List<Space> allSpaces, {String separator = ' / '}) {
    final names = <String>[name];
    final seen = <int>{id};
    var current = parentIn(allSpaces);
    while (current != null && seen.add(current.id)) {
      names.insert(0, current.name);
      current = current.parentIn(allSpaces);
    }
    return names.join(separator);
  }

  /// Indica si este espacio está dentro de [ancestorId].
  bool isDescendantOf(int ancestorId, List<Space> allSpaces) {
    final seen = <int>{id};
    var current = parentIn(allSpaces);
    while (current != null && seen.add(current.id)) {
      if (current.id == ancestorId) return true;
      current = current.parentIn(allSpaces);
    }
    return false;
  }

  /// IDs de todos los espacios que dependen de [spaceId], sin importar el nivel.
  static Set<int> descendantIdsOf(int spaceId, List<Space> allSpaces) {
    final result = <int>{};
    var changed = true;
    while (changed) {
      changed = false;
      for (final space in allSpaces) {
        if (space.id == spaceId) continue;
        final parentId = space.parentSpaceId;
        if (parentId == null) continue;
        if (result.contains(space.id)) continue;
        if (parentId == spaceId || result.contains(parentId)) {
          result.add(space.id);
          changed = true;
        }
      }
    }
    return result;
  }
}
