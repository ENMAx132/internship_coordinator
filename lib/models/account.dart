/// Referencia mínima a un usuario que devuelve la API dentro de otro recurso.
class UserRef {
  const UserRef({
    required this.id,
    required this.name,
    this.role = '',
  });

  final int id;
  final String name;
  final String role;

  factory UserRef.fromJson(Map<String, dynamic> json) => UserRef(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: json['name'] as String? ?? '',
        role: (json['role'] as String? ?? '').toUpperCase(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (role.isNotEmpty) 'role': role,
      };
}

/// Cuenta de usuario del inventario (`GET /inventory/accounts`).
class Account {
  const Account({
    required this.id,
    required this.name,
    this.email = '',
    this.role = '',
    this.status = '',
  });

  final int id;
  final String name;
  final String email;
  final String role;
  final String status;

  factory Account.fromJson(Map<String, dynamic> json) => Account(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        role: (json['role'] as String? ?? '').toUpperCase(),
        status: (json['status'] as String? ?? '').toUpperCase(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'status': status,
      };

  UserRef toRef() => UserRef(id: id, name: name, role: role);

  String get roleLabel => switch (role) {
        'ADMIN' => 'Administrador',
        'SUPERVISOR' => 'Supervisor',
        'USER' => 'Colaborador',
        _ => role,
      };
}
