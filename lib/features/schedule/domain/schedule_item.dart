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
  });

  final String id;
  final String subject;
  final String day;
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;
  final String notes;

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
    );
  }

  String get startLabel => _formatTime(startHour, startMinute);
  String get endLabel => _formatTime(endHour, endMinute);

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
    );
  }

  static String _formatTime(int hour, int minute) {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
