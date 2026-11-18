import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/tutorial_pending.dart';

/// Persistencia local del tutorial: datos pendientes y bandera de completado.
class TutorialStore {
  static const _pendingKey = 'inventory_tutorial_pending';
  static const _completedKey = 'inventory_tutorial_completed_local';

  Future<TutorialPending?> loadPending() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pendingKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return TutorialPending.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      await prefs.remove(_pendingKey);
      return null;
    }
  }

  Future<void> savePending(TutorialPending pending) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingKey, jsonEncode(pending.toJson()));
  }

  Future<void> clearPending() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingKey);
  }

  Future<bool> isCompletedLocally() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_completedKey) ?? false;
  }

  Future<void> markCompletedLocally() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_completedKey, true);
  }

  Future<void> clearCompletedLocally() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_completedKey);
  }
}
