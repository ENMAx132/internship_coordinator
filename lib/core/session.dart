import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SessionUser {
  const SessionUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  final int id;
  final String name;
  final String email;
  final String role;

  bool get isAdmin => role == 'ADMIN';
  bool get isSupervisor => role == 'SUPERVISOR';
  bool get isCollaborator => role == 'USER';

  /// Roles con acceso al módulo de inventario (`SHOWQR` queda fuera).
  bool get canAccessInventory => isAdmin || isSupervisor || isCollaborator;

  /// Solo ADMIN y USER pueden crear/editar; SUPERVISOR es de solo lectura.
  bool get canWrite => isAdmin || isCollaborator;

  /// ADMIN y SUPERVISOR ven todo el inventario y el historial.
  bool get canViewAll => isAdmin || isSupervisor;

  bool get canViewHistory => canViewAll;

  bool get canManageAssignments => isAdmin;

  bool get canReorderSections => isAdmin;

  factory SessionUser.fromJson(Map<String, dynamic> json) => SessionUser(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        role: (json['role'] as String? ?? '').toUpperCase(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
      };
}

class Session {
  const Session({
    required this.token,
    required this.tokenType,
    required this.user,
  });

  final String token;
  final String tokenType;
  final SessionUser user;

  factory Session.fromLoginResponse(Map<String, dynamic> json) {
    final user = json['user'];
    return Session(
      token: json['access_token'] as String? ?? '',
      tokenType: json['token_type'] as String? ?? 'bearer',
      user: SessionUser.fromJson(
        user is Map<String, dynamic>
            ? user
            : Map<String, dynamic>.from(user as Map),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'access_token': token,
        'token_type': tokenType,
        'user': user.toJson(),
      };

  factory Session.fromJson(Map<String, dynamic> json) => Session(
        token: json['access_token'] as String? ?? '',
        tokenType: json['token_type'] as String? ?? 'bearer',
        user: SessionUser.fromJson(
          Map<String, dynamic>.from(json['user'] as Map),
        ),
      );
}

class SessionStore {
  static const _sessionKey = 'inventory_session';
  static const _migrationKey = 'inventory_legacy_migration_done';

  Future<Session?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_sessionKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return Session.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      await prefs.remove(_sessionKey);
      return null;
    }
  }

  Future<void> save(Session session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, jsonEncode(session.toJson()));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }

  Future<bool> isLegacyMigrationDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_migrationKey) ?? false;
  }

  Future<void> markLegacyMigrationDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_migrationKey, true);
  }
}
