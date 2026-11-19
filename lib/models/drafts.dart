class SectionDraft {
  const SectionDraft({
    required this.name,
    required this.description,
    required this.icon,
    this.imageUrl,
    this.localImagePath,
    this.assignedUserIds = const [],
  });

  final String name;
  final String description;
  final String icon;
  final String? imageUrl;
  final String? localImagePath;
  final List<int> assignedUserIds;
}

class SpaceDraft {
  const SpaceDraft({
    required this.sectionId,
    required this.name,
    required this.description,
    required this.emoji,
    this.parentSpaceId,
    this.imageUrl,
    this.localImagePath,
    this.assignedUserIds = const [],
  });

  final int sectionId;
  final String name;
  final String description;
  final String emoji;
  final int? parentSpaceId;
  final String? imageUrl;
  final String? localImagePath;
  final List<int> assignedUserIds;
}

class ItemDraft {
  const ItemDraft({
    required this.spaceId,
    required this.name,
    required this.code,
    required this.categoryCode,
    required this.statusCode,
    required this.value,
    required this.responsible,
    required this.brand,
    this.responsibleUserId,
    this.imageUrl,
    this.localImagePath,
    this.assignedUserIds = const [],
  });

  final int spaceId;
  final String name;
  final String code;
  final String categoryCode;
  final String statusCode;
  final double value;
  final String responsible;
  final String brand;
  final int? responsibleUserId;
  final String? imageUrl;
  final String? localImagePath;
  final List<int> assignedUserIds;
}

class ItemChanges {
  const ItemChanges({
    this.spaceId,
    this.name,
    this.code,
    this.categoryCode,
    this.statusCode,
    this.value,
    this.responsible,
    this.brand,
    this.imageUrl,
    this.localImagePath,
    this.exitReason,
    this.assignedUserIds,
    this.responsibleUserId,
    this.updateResponsible = false,
  });

  final int? spaceId;
  final String? name;
  final String? code;
  final String? categoryCode;
  final String? statusCode;
  final double? value;
  final String? responsible;
  final String? brand;
  final String? imageUrl;
  final String? localImagePath;
  final String? exitReason;

  /// `null` significa no tocar las asignaciones.
  final List<int>? assignedUserIds;
  final int? responsibleUserId;
  final bool updateResponsible;
}
