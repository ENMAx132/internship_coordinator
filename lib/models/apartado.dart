class Apartado {
  final String id;
  final String nombre;
  final String icono;
  final String descripcion;
  final String? imagePath;

  Apartado({
    required this.id,
    required this.nombre,
    required this.icono,
    required this.descripcion,
    this.imagePath,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'icono': icono,
        'descripcion': descripcion,
        'imagePath': imagePath,
      };

  factory Apartado.fromJson(Map<String, dynamic> json) => Apartado(
        id: json['id'] as String? ?? '',
        nombre: json['nombre'] as String? ?? '',
        icono: json['icono'] as String? ?? '🏢',
        descripcion: json['descripcion'] as String? ?? '',
        imagePath: json['imagePath'] as String?,
      );
}
