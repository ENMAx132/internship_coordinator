class Item {
  String id;
  String name;
  String category;
  String sectorId;
  String description;
  String? imagePath;

  Item({
    required this.id,
    required this.name,
    required this.category,
    required this.sectorId,
    required this.description,
    this.imagePath,
  });
}