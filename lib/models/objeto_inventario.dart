/// Modelo de datos para un Objeto del Inventario
class ObjetoInventario {
  final String id;
  final String placa;
  final String nombre;
  String espacioId;
  final String categoria;
  final String estado; // Excelente, Operativo, Mantenimiento
  final double valor;
  final String responsable;
  final DateTime fechaRegistro;

  ObjetoInventario({
    required this.id,
    required this.placa,
    required this.nombre,
    required this.espacioId,
    required this.categoria,
    required this.estado,
    required this.valor,
    required this.responsable,
    DateTime? fechaRegistro,
  }) : fechaRegistro = fechaRegistro ?? DateTime.now();
}
