import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Estudio',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

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

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _storageKey = 'study_schedules';
  final List<ScheduleItem> _items = [];
  bool _loading = true;

  static const List<String> _days = [
    'Lunes',
    'Martes',
    'Miercoles',
    'Jueves',
    'Viernes',
    'Sabado',
    'Domingo',
  ];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null && raw.isNotEmpty) {
      final decoded = jsonDecode(raw) as List<dynamic>;
      _items
        ..clear()
        ..addAll(decoded
            .whereType<Map<String, dynamic>>()
            .map(ScheduleItem.fromJson));
    }

    if (!mounted) return;
    setState(() {
      _loading = false;
    });
  }

  Future<void> _saveItems() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_items.map((item) => item.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  Future<void> _openAddDialog() async {
    final subjectController = TextEditingController();
    final notesController = TextEditingController();
    String selectedDay = _days.first;
    TimeOfDay? startTime;
    TimeOfDay? endTime;
    String subject = '';
    String notes = '';

    Future<void> pickTime({required bool isStart}) async {
      final picked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (!context.mounted) return;
      if (picked == null) return;
      if (isStart) {
        startTime = picked;
      } else {
        endTime = picked;
      }
    }

    bool? saved;
    try {
      saved = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (dialogContext, setDialogState) {
              return AlertDialog(
                title: const Text('Nuevo horario'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: subjectController,
                        decoration: const InputDecoration(
                          labelText: 'Materia',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedDay,
                        items: _days
                            .map((day) => DropdownMenuItem(
                                  value: day,
                                  child: Text(day),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setDialogState(() {
                            selectedDay = value;
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: 'Dia',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                await pickTime(isStart: true);
                                if (!dialogContext.mounted) return;
                                setDialogState(() {});
                              },
                              icon: const Icon(Icons.schedule),
                              label: Text(startTime == null
                                  ? 'Hora inicio'
                                  : startTime!.format(context)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                await pickTime(isStart: false);
                                if (!dialogContext.mounted) return;
                                setDialogState(() {});
                              },
                              icon: const Icon(Icons.schedule_outlined),
                              label: Text(endTime == null
                                  ? 'Hora fin'
                                  : endTime!.format(context)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notas (opcional)',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: const Text('Cancelar'),
                  ),
                  FilledButton(
                    onPressed: () {
                      final subject = subjectController.text.trim();
                      if (subject.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Escribe una materia.'),
                          ),
                        );
                        return;
                      }
                      if (startTime == null || endTime == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Selecciona hora inicio y fin.'),
                          ),
                        );
                        return;
                      }
                      final startMinutes =
                          startTime!.hour * 60 + startTime!.minute;
                      final endMinutes = endTime!.hour * 60 + endTime!.minute;
                      if (endMinutes <= startMinutes) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('La hora fin debe ser despues de inicio.'),
                          ),
                        );
                        return;
                      }
                      Navigator.of(dialogContext).pop(true);
                    },
                    child: const Text('Guardar'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      subject = subjectController.text.trim();
      notes = notesController.text.trim();
      FocusManager.instance.primaryFocus?.unfocus();
      await Future<void>.delayed(Duration.zero);
      subjectController.dispose();
      notesController.dispose();
    }

    if (saved != true || startTime == null || endTime == null) return;
    if (!mounted) return;

    final item = ScheduleItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      subject: subject,
      day: selectedDay,
      startHour: startTime!.hour,
      startMinute: startTime!.minute,
      endHour: endTime!.hour,
      endMinute: endTime!.minute,
      notes: notes,
    );

    setState(() {
      _items.add(item);
    });
    await _saveItems();
  }

  Future<void> _deleteItem(ScheduleItem item) async {
    if (!mounted) return;
    setState(() {
      _items.removeWhere((element) => element.id == item.id);
    });
    await _saveItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Horario de Estudio'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(
                  child: Text(
                    'No hay horarios aun.\nAgrega uno con el boton +',
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return Card(
                      child: ListTile(
                        title: Text(item.subject),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('${item.day} • ${item.startLabel} - ${item.endLabel}'),
                            if (item.notes.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(item.notes),
                            ],
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _deleteItem(item),
                        ),
                      ),
                    );
                  },
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemCount: _items.length,
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
