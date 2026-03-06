import 'package:flutter/foundation.dart';

import '../../notifications/data/notification_service.dart';
import '../data/schedule_repository.dart';
import '../domain/schedule_item.dart';

class ScheduleController extends ChangeNotifier {
  ScheduleController(
    this._repository, {
    NotificationService? notificationService,
  }) : _notificationService = notificationService ?? NotificationService.instance;

  final ScheduleRepository _repository;
  final NotificationService _notificationService;
  final List<ScheduleItem> _items = <ScheduleItem>[];
  bool _isLoading = true;

  List<ScheduleItem> get items => List.unmodifiable(_items);
  bool get isLoading => _isLoading;

  Future<void> load() async {
    final loaded = await _repository.loadSchedules();
    _items
      ..clear()
      ..addAll(loaded);
    final pendingItems = _items.where((item) => !item.isCompleted).toList();
    await _notificationService.syncTaskEndAlarms(pendingItems);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addItem(ScheduleItem item) async {
    _items.add(item);
    notifyListeners();
    await _repository.saveSchedules(_items);
    if (!item.isCompleted) {
      await _notificationService.scheduleTaskEnd(item);
    }
  }

  Future<void> updateItem(ScheduleItem updatedItem) async {
    final index = _items.indexWhere((item) => item.id == updatedItem.id);
    if (index == -1) return;
    _items[index] = updatedItem;
    notifyListeners();
    await _repository.saveSchedules(_items);
    await _notificationService.cancelForItem(updatedItem.id);
    if (!updatedItem.isCompleted) {
      await _notificationService.scheduleTaskEnd(updatedItem);
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

  Future<void> setCompleted(String itemId, bool completed) async {
    final index = _items.indexWhere((item) => item.id == itemId);
    if (index == -1) return;
    final current = _items[index];
    final updated = current.copyWith(
      isCompleted: completed,
      completedAtIso: completed ? DateTime.now().toIso8601String() : null,
      clearCompletedAt: !completed,
    );
    _items[index] = updated;
    notifyListeners();
    await _repository.saveSchedules(_items);
    if (completed) {
      await _notificationService.cancelForItem(itemId);
      return;
    }
    await _notificationService.scheduleTaskEnd(updated);
  }
}
