class Review {
  const Review({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.itemCode,
    required this.spaceId,
    required this.spaceName,
    this.imageUrl,
    required this.enteredAt,
    this.exitedAt,
    this.exitReason,
    required this.isActive,
  });

  final int id;
  final int? itemId;
  final String itemName;
  final String itemCode;
  final int? spaceId;
  final String? spaceName;
  final String? imageUrl;
  final DateTime enteredAt;
  final DateTime? exitedAt;
  final String? exitReason;
  final bool isActive;

  factory Review.fromJson(Map<String, dynamic> json) => Review(
        id: (json['id'] as num).toInt(),
        itemId: (json['item_id'] as num?)?.toInt(),
        itemName: json['item_name'] as String? ?? '',
        itemCode: json['item_code'] as String? ?? '',
        spaceId: (json['space_id'] as num?)?.toInt(),
        spaceName: json['space_name'] as String?,
        imageUrl: (json['image_url'] ?? json['imageUrl']) as String?,
        enteredAt: DateTime.tryParse(
              json['entered_at'] as String? ?? '',
            ) ??
            DateTime.now(),
        exitedAt: json['exited_at'] == null
            ? null
            : DateTime.tryParse(json['exited_at'] as String),
        exitReason: json['exit_reason'] as String?,
        isActive: json['is_active'] as bool? ?? json['exited_at'] == null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'item_id': itemId,
        'item_name': itemName,
        'item_code': itemCode,
        'space_id': spaceId,
        'space_name': spaceName,
        'image_url': imageUrl,
        'entered_at': enteredAt.toUtc().toIso8601String(),
        'exited_at': exitedAt?.toUtc().toIso8601String(),
        'exit_reason': exitReason,
        'is_active': isActive,
      };
}
