import 'account.dart';
import 'catalog.dart';

class InventoryItem {
  const InventoryItem({
    required this.id,
    required this.code,
    required this.name,
    required this.spaceId,
    required this.spaceName,
    required this.spaceEmoji,
    required this.sectionId,
    required this.sectionName,
    required this.sectionIcon,
    required this.category,
    required this.status,
    required this.value,
    required this.responsible,
    required this.brand,
    this.imageUrl,
    required this.registeredAt,
    this.inReviewAt,
    this.isPersonal = false,
    this.responsibleUser,
    this.assignedUsers = const [],
  });

  final int id;
  final String code;
  final String name;
  final int spaceId;
  final String spaceName;
  final String spaceEmoji;
  final int sectionId;
  final String sectionName;
  final String sectionIcon;
  final CatalogEntry category;
  final CatalogEntry status;
  final double value;
  final String responsible;
  final String brand;
  final String? imageUrl;
  final DateTime registeredAt;
  final DateTime? inReviewAt;
  final bool isPersonal;
  final UserRef? responsibleUser;
  final List<UserRef> assignedUsers;

  bool get isInReview => status.isInReview;

  bool get isAssigned =>
      !isPersonal && (assignedUsers.isNotEmpty || responsibleUser != null);

  /// Nombre a mostrar como responsable, priorizando la cuenta vinculada.
  String get displayResponsible =>
      responsibleUser?.name ??
      (responsible.trim().isEmpty ? 'Sin asignar' : responsible);

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    final space = json['space'];
    final section = json['section'];
    final spaceMap = space is Map ? Map<String, dynamic>.from(space) : null;
    final sectionMap =
        section is Map ? Map<String, dynamic>.from(section) : null;
    final responsibleUser = json['responsible_user'];
    final assigned = json['assigned_users'];
    return InventoryItem(
      id: (json['id'] as num).toInt(),
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      spaceId: (json['space_id'] as num).toInt(),
      spaceName: spaceMap?['name'] as String? ?? '',
      spaceEmoji: spaceMap?['emoji'] as String? ?? '🏢',
      sectionId: (json['section_id'] as num?)?.toInt() ??
          (sectionMap?['id'] as num?)?.toInt() ??
          0,
      sectionName: sectionMap?['name'] as String? ?? '',
      sectionIcon: sectionMap?['icon'] as String? ?? '🏢',
      category: CatalogEntry.fromJson(
        Map<String, dynamic>.from(json['category'] as Map),
      ),
      status: CatalogEntry.fromJson(
        Map<String, dynamic>.from(json['status'] as Map),
      ),
      value: (json['value'] as num?)?.toDouble() ?? 0,
      responsible: json['responsible'] as String? ?? 'Sin asignar',
      brand: json['brand'] as String? ?? '',
      imageUrl: (json['image_url'] ?? json['imageUrl']) as String?,
      registeredAt: DateTime.tryParse(
            json['registered_at'] as String? ?? '',
          ) ??
          DateTime.now(),
      inReviewAt: json['in_review_at'] == null
          ? null
          : DateTime.tryParse(json['in_review_at'] as String),
      isPersonal: json['is_personal'] as bool? ?? false,
      responsibleUser: responsibleUser is Map
          ? UserRef.fromJson(Map<String, dynamic>.from(responsibleUser))
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
        'code': code,
        'name': name,
        'space_id': spaceId,
        'space': {'id': spaceId, 'name': spaceName, 'emoji': spaceEmoji},
        'section_id': sectionId,
        'section': {
          'id': sectionId,
          'name': sectionName,
          'icon': sectionIcon,
        },
        'category': category.toJson(),
        'status': status.toJson(),
        'value': value,
        'responsible': responsible,
        'brand': brand,
        'image_url': imageUrl,
        'registered_at': registeredAt.toUtc().toIso8601String(),
        'in_review_at': inReviewAt?.toUtc().toIso8601String(),
        'is_personal': isPersonal,
        'responsible_user': responsibleUser?.toJson(),
        'assigned_users': assignedUsers.map((e) => e.toJson()).toList(),
      };

  InventoryItem copyWith({
    int? id,
    String? code,
    String? name,
    int? spaceId,
    String? spaceName,
    String? spaceEmoji,
    int? sectionId,
    String? sectionName,
    String? sectionIcon,
    CatalogEntry? category,
    CatalogEntry? status,
    double? value,
    String? responsible,
    String? brand,
    String? imageUrl,
    DateTime? registeredAt,
    DateTime? inReviewAt,
    bool? isPersonal,
    UserRef? responsibleUser,
    List<UserRef>? assignedUsers,
  }) =>
      InventoryItem(
        id: id ?? this.id,
        code: code ?? this.code,
        name: name ?? this.name,
        spaceId: spaceId ?? this.spaceId,
        spaceName: spaceName ?? this.spaceName,
        spaceEmoji: spaceEmoji ?? this.spaceEmoji,
        sectionId: sectionId ?? this.sectionId,
        sectionName: sectionName ?? this.sectionName,
        sectionIcon: sectionIcon ?? this.sectionIcon,
        category: category ?? this.category,
        status: status ?? this.status,
        value: value ?? this.value,
        responsible: responsible ?? this.responsible,
        brand: brand ?? this.brand,
        imageUrl: imageUrl ?? this.imageUrl,
        registeredAt: registeredAt ?? this.registeredAt,
        inReviewAt: inReviewAt ?? this.inReviewAt,
        isPersonal: isPersonal ?? this.isPersonal,
        responsibleUser: responsibleUser ?? this.responsibleUser,
        assignedUsers: assignedUsers ?? this.assignedUsers,
      );
}
