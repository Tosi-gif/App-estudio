import '../domain/schedule_item.dart';

abstract class ScheduleRepository {
  Future<List<ScheduleItem>> loadSchedules();
  Future<void> saveSchedules(List<ScheduleItem> items);
}
