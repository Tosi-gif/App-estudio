import 'package:flutter/foundation.dart';

import '../data/schedule_repository.dart';
import '../domain/schedule_item.dart';

class ScheduleController extends ChangeNotifier {
  ScheduleController(this._repository);

  final ScheduleRepository _repository;
  final List<ScheduleItem> _items = <ScheduleItem>[];
  bool _isLoading = true;

  List<ScheduleItem> get items => List.unmodifiable(_items);
  bool get isLoading => _isLoading;

  Future<void> load() async {
    final loaded = await _repository.loadSchedules();
    _items
      ..clear()
      ..addAll(loaded);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addItem(ScheduleItem item) async {
    _items.add(item);
    notifyListeners();
    await _repository.saveSchedules(_items);
  }

  Future<void> updateItem(ScheduleItem updatedItem) async {
    final index = _items.indexWhere((item) => item.id == updatedItem.id);
    if (index == -1) return;
    _items[index] = updatedItem;
    notifyListeners();
    await _repository.saveSchedules(_items);
  }

  Future<void> deleteItem(String itemId) async {
    _items.removeWhere((item) => item.id == itemId);
    notifyListeners();
    await _repository.saveSchedules(_items);
  }

  Future<void> clearAllItems() async {
    _items.clear();
    notifyListeners();
    await _repository.saveSchedules(_items);
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
  }
}
