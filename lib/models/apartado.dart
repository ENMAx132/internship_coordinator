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
}
