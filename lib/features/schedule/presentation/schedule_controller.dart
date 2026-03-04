import 'package:flutter/foundation.dart';

import '../../notifications/data/notification_service.dart';
import '../data/schedule_repository.dart';
import '../domain/schedule_item.dart';

class ScheduleController extends ChangeNotifier {
  ScheduleController(
    this._repository, {
    NotificationService? notificationService,
    bool notificationsEnabled = true,
  }) : _notificationService = notificationService ?? NotificationService.instance,
       _notificationsEnabled = notificationsEnabled;

  final ScheduleRepository _repository;
  final NotificationService _notificationService;
  bool _notificationsEnabled;
  final List<ScheduleItem> _items = <ScheduleItem>[];
  bool _isLoading = true;

  static const List<String> days = <String>[
    'Lunes',
    'Martes',
    'Miercoles',
    'Jueves',
    'Viernes',
    'Sabado',
    'Domingo',
  ];

  List<ScheduleItem> get items => List.unmodifiable(_items);
  bool get isLoading => _isLoading;

  Future<void> load() async {
    final loaded = await _repository.loadSchedules();
    _items
      ..clear()
      ..addAll(loaded);
    if (_notificationsEnabled) {
      await _notificationService.syncSchedules(_items);
    } else {
      await _notificationService.cancelAll();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addItem(ScheduleItem item) async {
    _items.add(item);
    notifyListeners();
    await _repository.saveSchedules(_items);
    if (_notificationsEnabled) {
      await _notificationService.scheduleForItem(item);
    }
  }

  Future<void> deleteItem(String itemId) async {
    _items.removeWhere((item) => item.id == itemId);
    notifyListeners();
    await _repository.saveSchedules(_items);
    await _notificationService.cancelForItem(itemId);
  }

  Future<void> clearAllItems() async {
    _items.clear();
    notifyListeners();
    await _repository.saveSchedules(_items);
    await _notificationService.cancelAll();
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    if (enabled) {
      await _notificationService.syncSchedules(_items);
      return;
    }
    await _notificationService.cancelAll();
  }
}
