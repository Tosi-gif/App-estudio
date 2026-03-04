import 'package:flutter/material.dart';

import '../../domain/schedule_item.dart';

Future<ScheduleItem?> showAddScheduleDialog({
  required BuildContext context,
  required List<String> days,
  required bool use24HourFormat,
}) {
  String selectedDay = days.first;
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  String subject = '';
  String notes = '';

  Future<void> pickTime({
    required BuildContext dialogContext,
    required bool isStart,
  }) async {
    final picked = await showTimePicker(
      context: dialogContext,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(alwaysUse24HourFormat: use24HourFormat),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (!dialogContext.mounted || picked == null) return;
    if (isStart) {
      startTime = picked;
      return;
    }
    endTime = picked;
  }

  void showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  return showDialog<ScheduleItem>(
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
                    onChanged: (value) {
                      subject = value.trim();
                    },
                    decoration: const InputDecoration(
                      labelText: 'Materia',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedDay,
                    items: days
                        .map(
                          (day) => DropdownMenuItem<String>(
                            value: day,
                            child: Text(day),
                          ),
                        )
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
                            await pickTime(
                              dialogContext: dialogContext,
                              isStart: true,
                            );
                            if (!dialogContext.mounted) return;
                            setDialogState(() {});
                          },
                          icon: const Icon(Icons.schedule),
                          label: Text(
                            startTime == null
                                ? 'Hora inicio'
                                : _formatPickedTime(
                                    startTime!,
                                    use24HourFormat: use24HourFormat,
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await pickTime(
                              dialogContext: dialogContext,
                              isStart: false,
                            );
                            if (!dialogContext.mounted) return;
                            setDialogState(() {});
                          },
                          icon: const Icon(Icons.schedule_outlined),
                          label: Text(
                            endTime == null
                                ? 'Hora fin'
                                : _formatPickedTime(
                                    endTime!,
                                    use24HourFormat: use24HourFormat,
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    onChanged: (value) {
                      notes = value.trim();
                    },
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Notas (opcional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () {
                  if (subject.isEmpty) {
                    showError('Escribe una materia.');
                    return;
                  }
                  if (startTime == null || endTime == null) {
                    showError('Selecciona hora inicio y fin.');
                    return;
                  }
                  final startMinutes = startTime!.hour * 60 + startTime!.minute;
                  final endMinutes = endTime!.hour * 60 + endTime!.minute;
                  if (endMinutes <= startMinutes) {
                    showError('La hora fin debe ser despues de inicio.');
                    return;
                  }
                  FocusManager.instance.primaryFocus?.unfocus();
                  Navigator.of(dialogContext).pop(
                    ScheduleItem.create(
                      subject: subject,
                      day: selectedDay,
                      startHour: startTime!.hour,
                      startMinute: startTime!.minute,
                      endHour: endTime!.hour,
                      endMinute: endTime!.minute,
                      notes: notes,
                    ),
                  );
                },
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      );
    },
  );
}

String _formatPickedTime(
  TimeOfDay value, {
  required bool use24HourFormat,
}) {
  final hour = value.hour;
  final minute = value.minute.toString().padLeft(2, '0');
  if (use24HourFormat) {
    final h = hour.toString().padLeft(2, '0');
    return '$h:$minute';
  }
  final period = hour >= 12 ? 'PM' : 'AM';
  final normalizedHour = hour % 12 == 0 ? 12 : hour % 12;
  return '$normalizedHour:$minute $period';
}
