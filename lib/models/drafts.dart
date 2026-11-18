class SectionDraft {
  const SectionDraft({
    required this.name,
    required this.description,
    required this.icon,
    this.imageUrl,
    this.localImagePath,
  });

  final String name;
  final String description;
  final String icon;
  final String? imageUrl;
  final String? localImagePath;
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
  });

  final int sectionId;
  final String name;
  final String description;
  final String emoji;
  final int? parentSpaceId;
  final String? imageUrl;
  final String? localImagePath;
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
    this.imageUrl,
    this.localImagePath,
  });

  final int spaceId;
  final String name;
  final String code;
  final String categoryCode;
  final String statusCode;
  final double value;
  final String responsible;
  final String brand;
  final String? imageUrl;
  final String? localImagePath;
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
}
