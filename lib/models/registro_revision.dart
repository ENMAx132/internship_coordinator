/// Registro de una entrada de un objeto al estado "En revisión".
class RegistroRevision {
  final String id;
  final String objetoId;
  final String nombre;
  final String placa;
  final String espacioId;
  final String? imagePath;
  final DateTime fechaEntrada;
  DateTime? fechaSalida;
  String? motivoSalida;

  RegistroRevision({
    required this.id,
    required this.objetoId,
    required this.nombre,
    required this.placa,
    required this.espacioId,
    this.imagePath,
    required this.fechaEntrada,
    this.fechaSalida,
    this.motivoSalida,
  });

  bool get enRevision => fechaSalida == null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'objetoId': objetoId,
        'nombre': nombre,
        'placa': placa,
        'espacioId': espacioId,
        'imagePath': imagePath,
        'fechaEntrada': fechaEntrada.toIso8601String(),
        'fechaSalida': fechaSalida?.toIso8601String(),
        'motivoSalida': motivoSalida,
      };

  factory RegistroRevision.fromJson(Map<String, dynamic> json) =>
      RegistroRevision(
        id: json['id'] as String? ?? '',
        objetoId: json['objetoId'] as String? ?? '',
        nombre: json['nombre'] as String? ?? '',
        placa: json['placa'] as String? ?? '',
        espacioId: json['espacioId'] as String? ?? '',
        imagePath: json['imagePath'] as String?,
        fechaEntrada:
            DateTime.tryParse(json['fechaEntrada'] as String? ?? '') ??
                DateTime.now(),
        fechaSalida: DateTime.tryParse(json['fechaSalida'] as String? ?? ''),
        motivoSalida: json['motivoSalida'] as String?,
      );
}
