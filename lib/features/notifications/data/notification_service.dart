import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../schedule/domain/schedule_item.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const String _channelId = 'task_end_alarm_channel_v2';
  static const String _channelName = 'Alarmas de fin de tarea';
  static const String _channelDescription =
      'Avisa cuando una tarea llega a su fin';
  static const int _debugNotificationIdNow = 999001;
  static const int _debugNotificationIdDelayed = 999002;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _available = true;

  Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Madrid'));

    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    try {
      await _plugin.initialize(initSettings);
    } on MissingPluginException {
      _available = false;
      _initialized = true;
      return;
    }

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();

    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.max,
      sound: RawResourceAndroidNotificationSound('alarma_fin'),
      playSound: true,
      audioAttributesUsage: AudioAttributesUsage.alarm,
    );
    await androidPlugin?.createNotificationChannel(channel);

    _initialized = true;
  }

  Future<void> syncTaskEndAlarms(List<ScheduleItem> items) async {
    await initialize();
    if (!_available) return;
    await _plugin.cancelAll();
    for (final item in items) {
      await scheduleTaskEnd(item);
    }
  }

  Future<void> scheduleTaskEnd(ScheduleItem item) async {
    await initialize();
    if (!_available) return;

    final date = _resolveDate(item);
    if (date == null) return;

    final scheduled = tz.TZDateTime(
      tz.local,
      date.year,
      date.month,
      date.day,
      item.endHour,
      item.endMinute,
    );

    if (!scheduled.isAfter(tz.TZDateTime.now(tz.local))) return;

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('alarma_fin'),
        audioAttributesUsage: AudioAttributesUsage.alarm,
      ),
      iOS: DarwinNotificationDetails(),
    );

    try {
      await _plugin.zonedSchedule(
        _endNotificationId(item.id),
        'Fin de tarea',
        'La tarea "${item.subject}" ha terminado.',
        scheduled,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } on PlatformException catch (e) {
      // Algunos dispositivos no conceden alarmas exactas.
      // En ese caso hacemos fallback a inexacta para no perder el aviso.
      if (e.code != 'exact_alarms_not_permitted') rethrow;
      await _plugin.zonedSchedule(
        _endNotificationId(item.id),
        'Fin de tarea',
        'La tarea "${item.subject}" ha terminado.',
        scheduled,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  Future<void> cancelForItem(String itemId) async {
    await initialize();
    if (!_available) return;
    await _plugin.cancel(_endNotificationId(itemId));
  }

  Future<void> cancelAll() async {
    await initialize();
    if (!_available) return;
    await _plugin.cancelAll();
  }

  Future<void> showDebugNow() async {
    await initialize();
    if (!_available) return;
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('alarma_fin'),
        audioAttributesUsage: AudioAttributesUsage.alarm,
      ),
      iOS: DarwinNotificationDetails(),
    );
    await _plugin.show(
      _debugNotificationIdNow,
      'Prueba de sonido',
      'Si oyes esto, el mp3 funciona en el canal.',
      details,
    );
  }

  Future<void> scheduleDebugInSeconds(int seconds) async {
    await initialize();
    if (!_available) return;
    final now = tz.TZDateTime.now(tz.local);
    final when = now.add(Duration(seconds: seconds));
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('alarma_fin'),
        audioAttributesUsage: AudioAttributesUsage.alarm,
      ),
      iOS: DarwinNotificationDetails(),
    );
    try {
      await _plugin.zonedSchedule(
        _debugNotificationIdDelayed,
        'Prueba en $seconds s',
        'Si suena en segundo plano, la programación funciona.',
        when,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } on PlatformException catch (e) {
      if (e.code != 'exact_alarms_not_permitted') rethrow;
      await _plugin.zonedSchedule(
        _debugNotificationIdDelayed,
        'Prueba en $seconds s',
        'Si suena en segundo plano, la programación funciona.',
        when,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  Future<List<PendingNotificationRequest>> getPendingRequests() async {
    await initialize();
    if (!_available) return const [];
    return _plugin.pendingNotificationRequests();
  }

  DateTime? _resolveDate(ScheduleItem item) {
    final parsed = ScheduleItem.tryParseIsoDate(item.day);
    if (parsed != null) return parsed;
    return _nextDateFromLegacyWeekday(item.day);
  }

  DateTime? _nextDateFromLegacyWeekday(String day) {
    final weekday = _weekdayFromSpanish(day);
    if (weekday == null) return null;
    final now = DateTime.now();
    final offset = (weekday - now.weekday) % 7;
    return DateTime(now.year, now.month, now.day + offset);
  }

  int? _weekdayFromSpanish(String day) {
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
        return null;
    }
  }

  int _endNotificationId(String itemId) {
    var hash = 7;
    for (final unit in itemId.codeUnits) {
      hash = ((hash * 31) + unit) & 0x7fffffff;
    }
    return hash;
  }
}
