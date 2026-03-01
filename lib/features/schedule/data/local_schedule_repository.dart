import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/schedule_item.dart';
import 'schedule_repository.dart';

class LocalScheduleRepository implements ScheduleRepository {
  LocalScheduleRepository({SharedPreferences? preferences})
    : _preferences = preferences;

  static const String _storageKey = 'study_schedules';
  final SharedPreferences? _preferences;

  @override
  Future<List<ScheduleItem>> loadSchedules() async {
    final prefs = _preferences ?? await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return [];
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(ScheduleItem.fromJson)
        .toList();
  }

  @override
  Future<void> saveSchedules(List<ScheduleItem> items) async {
    final prefs = _preferences ?? await SharedPreferences.getInstance();
    final encoded = jsonEncode(items.map((item) => item.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }
}
