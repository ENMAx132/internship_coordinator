/// Modelo de datos para un Espacio / Sala
class Espacio {
  final String id;
  final String nombre;
  final String descripcion;
  final String emoji;
  final String apartadoId;

  Espacio({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.emoji,
    required this.apartadoId,
  });
}
