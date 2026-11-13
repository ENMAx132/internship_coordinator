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
  final String? imagePath;
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

  /// Normaliza un estado para compararlo sin depender de acentos ni mayúsculas.
  static String normalizarEstado(String estado) {
    return estado
        .trim()
        .toLowerCase()
        .replaceAll('\u00E1', 'a')
        .replaceAll('\u00E9', 'e')
        .replaceAll('\u00ED', 'i')
        .replaceAll('\u00F3', 'o')
        .replaceAll('\u00FA', 'u');
  }

  static bool esEstadoEnRevision(String estado) {
    return normalizarEstado(estado) == 'en revision';
  }

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
    String? imagePath,
  })  : imagePath = imagePath ?? '',
        marca = marca ?? '',
        fechaRegistro = fechaRegistro ?? DateTime.now(),
        fechaEnRevision = fechaEnRevision ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'placa': placa,
        'nombre': nombre,
        'espacioId': espacioId,
        'categoria': categoria,
        'estado': estado,
        'valor': valor,
        'responsable': responsable,
        'imagePath': imagePath,
        'marca': marca,
        'fechaRegistro': fechaRegistro.toIso8601String(),
        'fechaEnRevision': fechaEnRevision.toIso8601String(),
      };

  factory ObjetoInventario.fromJson(Map<String, dynamic> json) =>
      ObjetoInventario(
        id: json['id'] as String? ?? '',
        placa: json['placa'] as String? ?? '',
        nombre: json['nombre'] as String? ?? '',
        espacioId: json['espacioId'] as String? ?? '',
        categoria: json['categoria'] as String? ?? categoriasDisponibles.first,
        estado: json['estado'] as String? ?? estadosDisponibles.first,
        valor: (json['valor'] as num?)?.toDouble() ?? 0.0,
        responsable: json['responsable'] as String? ?? 'Sin asignar',
        imagePath: json['imagePath'] as String?,
        marca: json['marca'] as String?,
        fechaRegistro:
            DateTime.tryParse(json['fechaRegistro'] as String? ?? ''),
        fechaEnRevision:
            DateTime.tryParse(json['fechaEnRevision'] as String? ?? ''),
      );
}
