import 'package:flutter/foundation.dart';

import '../data/schedule_repository.dart';
import '../domain/schedule_item.dart';

class ScheduleController extends ChangeNotifier {
  ScheduleController(this._repository);

  final ScheduleRepository _repository;
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
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addItem(ScheduleItem item) async {
    _items.add(item);
    notifyListeners();
    await _repository.saveSchedules(_items);
  }

  Future<void> deleteItem(String itemId) async {
    _items.removeWhere((item) => item.id == itemId);
    notifyListeners();
    await _repository.saveSchedules(_items);
  }
}
