/// Modelo de datos para un Objeto del Inventario
class ObjetoInventario {
  final String id;
  final String placa;
  final String nombre;
  String espacioId;
  final String categoria;
  final String estado;
  final double valor;
  final String responsable;
  final String marca;
  final DateTime fechaRegistro;
  final DateTime fechaEnRevision;

  static const List<String> estadosDisponibles = [
    'Excelente',
    'Bueno',
    'Operativo',
    'En uso',
    'En revisi\u00F3n',
    'Da\u00F1ado',
  ];

  static const List<String> categoriasDisponibles = [
    'General',
    'C\u00F3mputo & IT',
    'Electr\u00F3nica',
    'Mobiliario',
    'Audiovisual',
    'Audio',
    'Gaming',
    'Ropa',
    'Colecci\u00F3n',
    'Insumos',
    'Suministros',
  ];

  ObjetoInventario({
    required this.id,
    required this.placa,
    required this.nombre,
    required this.espacioId,
    required this.categoria,
    required this.estado,
    required this.valor,
    required this.responsable,
    String? marca,
    DateTime? fechaRegistro,
    DateTime? fechaEnRevision,
  })  : marca = marca ?? '',
        fechaRegistro = fechaRegistro ?? DateTime.now(),
        fechaEnRevision = fechaEnRevision ?? DateTime.now();
}