import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../schedule/domain/schedule_item.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();
  static const int _maxNotificationId = 2147483647;
  static const String _androidChannelId = 'study_schedule_channel';
  static const String _androidChannelName = 'Recordatorios de estudio';
  static const String _androidChannelDescription =
      'Notificaciones al inicio y fin de una tarea';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _available = true;

  Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Madrid'));

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    try {
      await _plugin.initialize(initSettings);
    } on MissingPluginException {
      // Puede ocurrir tras agregar el plugin y hacer hot restart.
      _available = false;
      _initialized = true;
      return;
    }

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();

    const channel = AndroidNotificationChannel(
      _androidChannelId,
      _androidChannelName,
      description: _androidChannelDescription,
      importance: Importance.high,
    );
    await androidPlugin?.createNotificationChannel(channel);

    _initialized = true;
  }

  Future<void> syncSchedules(List<ScheduleItem> items) async {
    await initialize();
    if (!_available) return;
    await _plugin.cancelAll();
    for (final item in items) {
      await scheduleForItem(item);
    }
  }

  Future<void> scheduleForItem(ScheduleItem item) async {
    await initialize();
    if (!_available) return;
    await _scheduleOne(
      id: _startNotificationId(item.id),
      title: 'Tu tarea ha comenzado',
      body: '${item.subject} (${item.startLabel} - ${item.endLabel})',
      day: item.day,
      hour: item.startHour,
      minute: item.startMinute,
    );
    await _scheduleOne(
      id: _endNotificationId(item.id),
      title: 'Tu tarea ha terminado',
      body: '${item.subject} (${item.startLabel} - ${item.endLabel})',
      day: item.day,
      hour: item.endHour,
      minute: item.endMinute,
    );
  }

  Future<void> cancelForItem(String itemId) async {
    await initialize();
    if (!_available) return;
    await _plugin.cancel(_startNotificationId(itemId));
    await _plugin.cancel(_endNotificationId(itemId));
  }

  Future<void> cancelAll() async {
    await initialize();
    if (!_available) return;
    await _plugin.cancelAll();
  }

  Future<void> _scheduleOne({
    required int id,
    required String title,
    required String body,
    required String day,
    required int hour,
    required int minute,
  }) async {
    final scheduledDate = _nextWeekdayTime(day, hour, minute);
    const androidDetails = AndroidNotificationDetails(
      _androidChannelId,
      _androidChannelName,
      channelDescription: _androidChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  tz.TZDateTime _nextWeekdayTime(String day, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    final targetWeekday = _weekdayFromSpanish(day);

    var daysToAdd = (targetWeekday - now.weekday) % 7;
    var candidate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day + daysToAdd,
      hour,
      minute,
    );

    if (!candidate.isAfter(now)) {
      candidate = candidate.add(const Duration(days: 7));
    }

    return candidate;
  }

  int _weekdayFromSpanish(String day) {
    switch (day.toLowerCase()) {
      case 'lunes':
        return DateTime.monday;
      case 'martes':
        return DateTime.tuesday;
      case 'miercoles':
      case 'miércoles':
        return DateTime.wednesday;
      case 'jueves':
        return DateTime.thursday;
      case 'viernes':
        return DateTime.friday;
      case 'sabado':
      case 'sábado':
        return DateTime.saturday;
      case 'domingo':
        return DateTime.sunday;
      default:
        return DateTime.monday;
    }
  }

  int _stableBaseId(String raw) {
    var hash = 0;
    for (final unit in raw.codeUnits) {
      hash = (hash * 31 + unit) % _maxNotificationId;
    }
    return hash == 0 ? 1 : hash;
  }

  int _startNotificationId(String itemId) {
    return (_stableBaseId(itemId) * 2) % _maxNotificationId;
  }

  int _endNotificationId(String itemId) {
    return (_stableBaseId(itemId) * 2 + 1) % _maxNotificationId;
  }
}
