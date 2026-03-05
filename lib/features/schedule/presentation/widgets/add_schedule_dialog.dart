import 'package:flutter/material.dart';

import '../../domain/schedule_item.dart';

Future<ScheduleItem?> showAddScheduleDialog({
  required BuildContext context,
  required bool use24HourFormat,
  ScheduleItem? initialItem,
}) {
  final isEditing = initialItem != null;
  DateTime? selectedDate = initialItem != null
      ? (ScheduleItem.tryParseIsoDate(initialItem.day) ?? DateTime.now())
      : null;
  TimeOfDay? startTime = initialItem != null
      ? TimeOfDay(hour: initialItem.startHour, minute: initialItem.startMinute)
      : null;
  TimeOfDay? endTime = initialItem != null
      ? TimeOfDay(hour: initialItem.endHour, minute: initialItem.endMinute)
      : null;
  String subject = initialItem?.subject ?? '';
  String notes = initialItem?.notes ?? '';
  String priority = initialItem?.priority ?? 'media';

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
            title: Text(isEditing ? 'Editar tarea' : 'Nuevo horario'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: subject,
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
                    initialValue: priority,
                    decoration: const InputDecoration(
                      labelText: 'Prioridad',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'alta', child: Text('Alta')),
                      DropdownMenuItem(value: 'media', child: Text('Media')),
                      DropdownMenuItem(value: 'baja', child: Text('Baja')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() {
                        priority = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final now = DateTime.now();
                      final picked = await showDatePicker(
                        context: dialogContext,
                        firstDate: DateTime(now.year - 1),
                        lastDate: DateTime(now.year + 3),
                        initialDate: selectedDate ?? now,
                        helpText: 'Selecciona el dia',
                      );
                      if (!dialogContext.mounted || picked == null) return;
                      setDialogState(() {
                        selectedDate = picked;
                      });
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      selectedDate == null
                          ? 'Dia del mes'
                          : _formatDate(selectedDate!),
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
                  TextFormField(
                    initialValue: notes,
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
                  if (selectedDate == null) {
                    showError('Selecciona un dia del mes.');
                    return;
                  }
                  final startMinutes = startTime!.hour * 60 + startTime!.minute;
                  final endMinutes = endTime!.hour * 60 + endTime!.minute;
                  if (endMinutes <= startMinutes) {
                    showError('La hora fin debe ser despues de inicio.');
                    return;
                  }
                  FocusManager.instance.primaryFocus?.unfocus();
                  if (isEditing) {
                    Navigator.of(dialogContext).pop(
                      initialItem.copyWith(
                        subject: subject,
                        day: ScheduleItem.toIsoDate(selectedDate!),
                        startHour: startTime!.hour,
                        startMinute: startTime!.minute,
                        endHour: endTime!.hour,
                        endMinute: endTime!.minute,
                        notes: notes,
                        priority: priority,
                      ),
                    );
                    return;
                  }
                  Navigator.of(dialogContext).pop(
                    ScheduleItem.create(
                      subject: subject,
                      day: ScheduleItem.toIsoDate(selectedDate!),
                      startHour: startTime!.hour,
                      startMinute: startTime!.minute,
                      endHour: endTime!.hour,
                      endMinute: endTime!.minute,
                      notes: notes,
                    ).copyWith(priority: priority),
                  );
                },
                child: Text(isEditing ? 'Actualizar' : 'Guardar'),
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

String _formatDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}
