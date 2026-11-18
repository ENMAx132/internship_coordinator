class InventorySettings {
  const InventorySettings({
    required this.tutorialCompleted,
    required this.startSectionId,
  });

  final bool tutorialCompleted;
  final int? startSectionId;

  factory InventorySettings.fromJson(Map<String, dynamic> json) =>
      InventorySettings(
        tutorialCompleted: json['tutorial_completed'] as bool? ?? false,
        startSectionId: (json['start_section_id'] as num?)?.toInt(),
      );

  Map<String, dynamic> toJson() => {
        'tutorial_completed': tutorialCompleted,
        'start_section_id': startSectionId,
      };

  InventorySettings copyWith({
    bool? tutorialCompleted,
    int? startSectionId,
  }) =>
      InventorySettings(
        tutorialCompleted: tutorialCompleted ?? this.tutorialCompleted,
        startSectionId: startSectionId ?? this.startSectionId,
      );

  static const defaults = InventorySettings(
    tutorialCompleted: false,
    startSectionId: null,
  );
}
