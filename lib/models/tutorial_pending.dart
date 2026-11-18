import 'catalog.dart';
import 'inventory_item.dart';
import 'section.dart';
import 'space.dart';

enum TutorialDecision { keep, delete }

/// Datos de ejemplo creados por el tutorial. Mientras no se sincronizan usan
/// IDs locales negativos; después guardan los IDs reales de la API.
class TutorialPending {
  const TutorialPending({
    required this.sectionName,
    required this.sectionDescription,
    required this.sectionIcon,
    required this.spaceName,
    required this.spaceDescription,
    required this.spaceEmoji,
    required this.itemName,
    required this.itemCode,
    required this.categoryCode,
    required this.statusCode,
    required this.value,
    required this.responsible,
    required this.brand,
    required this.createdAt,
    required this.decision,
    this.remoteSectionId,
    this.remoteSpaceId,
    this.remoteItemId,
    this.sectionCreatedByTutorial = false,
    this.spaceCreatedByTutorial = false,
    this.itemCreatedByTutorial = false,
  });

  static const int localSectionId = -1001;
  static const int localSpaceId = -1002;
  static const int localItemId = -1003;
  static const String fixedItemCode = 'TUTORIAL-001';

  final String sectionName;
  final String sectionDescription;
  final String sectionIcon;
  final String spaceName;
  final String spaceDescription;
  final String spaceEmoji;
  final String itemName;
  final String itemCode;
  final String categoryCode;
  final String statusCode;
  final double value;
  final String responsible;
  final String brand;
  final DateTime createdAt;
  final TutorialDecision decision;

  final int? remoteSectionId;
  final int? remoteSpaceId;
  final int? remoteItemId;

  final bool sectionCreatedByTutorial;
  final bool spaceCreatedByTutorial;
  final bool itemCreatedByTutorial;

  bool get isKeep => decision == TutorialDecision.keep;

  int get sectionId => remoteSectionId ?? localSectionId;
  int get spaceId => remoteSpaceId ?? localSpaceId;
  int get itemId => remoteItemId ?? localItemId;

  factory TutorialPending.fromJson(Map<String, dynamic> json) {
    final decisionName = json['decision'] as String? ?? 'keep';
    final decision = TutorialDecision.values.firstWhere(
      (value) => value.name == decisionName,
      orElse: () => TutorialDecision.keep,
    );
    return TutorialPending(
      sectionName: json['section_name'] as String? ?? 'Apartado de ejemplo',
      sectionDescription:
          json['section_description'] as String? ?? 'Creado por el tutorial',
      sectionIcon: json['section_icon'] as String? ?? '🏢',
      spaceName: json['space_name'] as String? ?? 'Espacio de ejemplo',
      spaceDescription:
          json['space_description'] as String? ?? 'Creado por el tutorial',
      spaceEmoji: json['space_emoji'] as String? ?? '💻',
      itemName: json['item_name'] as String? ?? 'Objeto de ejemplo',
      itemCode: json['item_code'] as String? ?? fixedItemCode,
      categoryCode: json['category_code'] as String? ?? 'general',
      statusCode: json['status_code'] as String? ?? 'in_review',
      value: (json['value'] as num?)?.toDouble() ?? 100,
      responsible: json['responsible'] as String? ?? 'Tutorial',
      brand: json['brand'] as String? ?? 'Demo',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      decision: decision,
      remoteSectionId: (json['remote_section_id'] as num?)?.toInt(),
      remoteSpaceId: (json['remote_space_id'] as num?)?.toInt(),
      remoteItemId: (json['remote_item_id'] as num?)?.toInt(),
      sectionCreatedByTutorial:
          json['section_created_by_tutorial'] as bool? ?? false,
      spaceCreatedByTutorial:
          json['space_created_by_tutorial'] as bool? ?? false,
      itemCreatedByTutorial:
          json['item_created_by_tutorial'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'section_name': sectionName,
        'section_description': sectionDescription,
        'section_icon': sectionIcon,
        'space_name': spaceName,
        'space_description': spaceDescription,
        'space_emoji': spaceEmoji,
        'item_name': itemName,
        'item_code': itemCode,
        'category_code': categoryCode,
        'status_code': statusCode,
        'value': value,
        'responsible': responsible,
        'brand': brand,
        'created_at': createdAt.toUtc().toIso8601String(),
        'decision': decision.name,
        'remote_section_id': remoteSectionId,
        'remote_space_id': remoteSpaceId,
        'remote_item_id': remoteItemId,
        'section_created_by_tutorial': sectionCreatedByTutorial,
        'space_created_by_tutorial': spaceCreatedByTutorial,
        'item_created_by_tutorial': itemCreatedByTutorial,
      };

  TutorialPending copyWith({
    String? sectionName,
    String? sectionDescription,
    String? sectionIcon,
    String? spaceName,
    String? spaceDescription,
    String? spaceEmoji,
    String? itemName,
    String? itemCode,
    String? categoryCode,
    String? statusCode,
    double? value,
    String? responsible,
    String? brand,
    DateTime? createdAt,
    TutorialDecision? decision,
    int? remoteSectionId,
    int? remoteSpaceId,
    int? remoteItemId,
    bool? sectionCreatedByTutorial,
    bool? spaceCreatedByTutorial,
    bool? itemCreatedByTutorial,
  }) =>
      TutorialPending(
        sectionName: sectionName ?? this.sectionName,
        sectionDescription: sectionDescription ?? this.sectionDescription,
        sectionIcon: sectionIcon ?? this.sectionIcon,
        spaceName: spaceName ?? this.spaceName,
        spaceDescription: spaceDescription ?? this.spaceDescription,
        spaceEmoji: spaceEmoji ?? this.spaceEmoji,
        itemName: itemName ?? this.itemName,
        itemCode: itemCode ?? this.itemCode,
        categoryCode: categoryCode ?? this.categoryCode,
        statusCode: statusCode ?? this.statusCode,
        value: value ?? this.value,
        responsible: responsible ?? this.responsible,
        brand: brand ?? this.brand,
        createdAt: createdAt ?? this.createdAt,
        decision: decision ?? this.decision,
        remoteSectionId: remoteSectionId ?? this.remoteSectionId,
        remoteSpaceId: remoteSpaceId ?? this.remoteSpaceId,
        remoteItemId: remoteItemId ?? this.remoteItemId,
        sectionCreatedByTutorial:
            sectionCreatedByTutorial ?? this.sectionCreatedByTutorial,
        spaceCreatedByTutorial:
            spaceCreatedByTutorial ?? this.spaceCreatedByTutorial,
        itemCreatedByTutorial:
            itemCreatedByTutorial ?? this.itemCreatedByTutorial,
      );

  Section toSection() => Section(
        id: sectionId,
        name: sectionName,
        description: sectionDescription,
        icon: sectionIcon,
        sortOrder: 1 << 30,
        spaceCount: 1,
        itemCount: 1,
        totalValue: value,
      );

  Space toSpace() => Space(
        id: spaceId,
        sectionId: sectionId,
        name: spaceName,
        description: spaceDescription,
        emoji: spaceEmoji,
        itemCount: 1,
      );

  InventoryItem toItem(Catalogs catalogs) {
    final category = catalogs.categoryByCode(categoryCode) ??
        const CatalogEntry(id: 0, code: 'general', name: 'General');
    final status = catalogs.statusByCode(statusCode) ??
        const CatalogEntry(
          id: 0,
          code: 'in_review',
          name: 'En revisión',
          isInReview: true,
        );
    return InventoryItem(
      id: itemId,
      code: itemCode,
      name: itemName,
      spaceId: spaceId,
      spaceName: spaceName,
      spaceEmoji: spaceEmoji,
      sectionId: sectionId,
      sectionName: sectionName,
      sectionIcon: sectionIcon,
      category: category,
      status: status,
      value: value,
      responsible: responsible,
      brand: brand,
      registeredAt: createdAt,
      inReviewAt: status.isInReview ? createdAt : null,
    );
  }
}

enum TutorialFinishResult { deleted, synced, pending }
