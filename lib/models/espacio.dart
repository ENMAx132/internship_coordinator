/// Modelo de datos para un Espacio / Sala
class Espacio {
  final String id;
  final String nombre;
  final String descripcion;
  final String emoji;
  final String apartadoId;
  final String? imagePath;

  Espacio({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.emoji,
    required this.apartadoId,
    this.imagePath,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'descripcion': descripcion,
        'emoji': emoji,
        'apartadoId': apartadoId,
        'imagePath': imagePath,
      };

  factory Espacio.fromJson(Map<String, dynamic> json) => Espacio(
        id: json['id'] as String? ?? '',
        nombre: json['nombre'] as String? ?? '',
        descripcion: json['descripcion'] as String? ?? '',
        emoji: json['emoji'] as String? ?? '🏢',
        apartadoId: json['apartadoId'] as String? ?? '',
        imagePath: json['imagePath'] as String?,
      );
}
