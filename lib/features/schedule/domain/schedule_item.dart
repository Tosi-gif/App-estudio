class ScheduleItem {
  ScheduleItem({
    required this.id,
    required this.subject,
    required this.day,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    required this.notes,
    required this.isCompleted,
    this.completedAtIso,
    required this.priority,
  });

  final String id;
  final String subject;
  final String day;
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;
  final String notes;
  final bool isCompleted;
  final String? completedAtIso;
  final String priority;

  factory ScheduleItem.create({
    required String subject,
    required String day,
    required int startHour,
    required int startMinute,
    required int endHour,
    required int endMinute,
    required String notes,
  }) {
    return ScheduleItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      subject: subject,
      day: day,
      startHour: startHour,
      startMinute: startMinute,
      endHour: endHour,
      endMinute: endMinute,
      notes: notes,
      isCompleted: false,
      completedAtIso: null,
      priority: 'media',
    );
  }

  ScheduleItem copyWith({
    String? id,
    String? subject,
    String? day,
    int? startHour,
    int? startMinute,
    int? endHour,
    int? endMinute,
    String? notes,
    bool? isCompleted,
    String? completedAtIso,
    bool clearCompletedAt = false,
    String? priority,
  }) {
    return ScheduleItem(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      day: day ?? this.day,
      startHour: startHour ?? this.startHour,
      startMinute: startMinute ?? this.startMinute,
      endHour: endHour ?? this.endHour,
      endMinute: endMinute ?? this.endMinute,
      notes: notes ?? this.notes,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAtIso: clearCompletedAt
          ? null
          : (completedAtIso ?? this.completedAtIso),
      priority: priority ?? this.priority,
    );
  }

  String get startLabel => _formatTime(startHour, startMinute);
  String get endLabel => _formatTime(endHour, endMinute);
  String get dayLabel => _formatStoredDay(day);
  String formattedStart({required bool use24HourFormat}) =>
      _formatTime(startHour, startMinute, use24HourFormat: use24HourFormat);
  String formattedEnd({required bool use24HourFormat}) =>
      _formatTime(endHour, endMinute, use24HourFormat: use24HourFormat);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subject': subject,
      'day': day,
      'startHour': startHour,
      'startMinute': startMinute,
      'endHour': endHour,
      'endMinute': endMinute,
      'notes': notes,
      'isCompleted': isCompleted,
      'completedAtIso': completedAtIso,
      'priority': priority,
    };
  }

  static ScheduleItem fromJson(Map<String, dynamic> json) {
    return ScheduleItem(
      id: json['id'] as String,
      subject: json['subject'] as String,
      day: json['day'] as String,
      startHour: json['startHour'] as int,
      startMinute: json['startMinute'] as int,
      endHour: json['endHour'] as int,
      endMinute: json['endMinute'] as int,
      notes: json['notes'] as String? ?? '',
      isCompleted: json['isCompleted'] as bool? ?? false,
      completedAtIso: json['completedAtIso'] as String?,
      priority: _normalizePriority(json['priority'] as String?),
    );
  }

  static String _normalizePriority(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'alta':
        return 'alta';
      case 'baja':
        return 'baja';
      default:
        return 'media';
    }
  }

  static String _formatTime(
    int hour,
    int minute, {
    bool use24HourFormat = true,
  }) {
    if (!use24HourFormat) {
      final period = hour >= 12 ? 'PM' : 'AM';
      final normalized = hour % 12 == 0 ? 12 : hour % 12;
      final m = minute.toString().padLeft(2, '0');
      return '$normalized:$m $period';
    }
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  static String toIsoDate(DateTime value) {
    final y = value.year.toString().padLeft(4, '0');
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static DateTime? tryParseIsoDate(String value) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
    if (match == null) return null;
    final year = int.tryParse(match.group(1)!);
    final month = int.tryParse(match.group(2)!);
    final day = int.tryParse(match.group(3)!);
    if (year == null || month == null || day == null) return null;
    return DateTime(year, month, day);
  }

  static String _formatStoredDay(String value) {
    final parsed = tryParseIsoDate(value);
    if (parsed == null) return value;
    final d = parsed.day.toString().padLeft(2, '0');
    final m = parsed.month.toString().padLeft(2, '0');
    return '$d/$m/${parsed.year}';
  }
}
