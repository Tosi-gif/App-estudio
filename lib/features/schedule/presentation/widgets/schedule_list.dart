import 'package:flutter/material.dart';

import '../../domain/schedule_item.dart';

class ScheduleList extends StatefulWidget {
  const ScheduleList({
    super.key,
    required this.items,
    required this.onDelete,
    required this.onToggleCompleted,
    required this.onEdit,
    required this.use24HourFormat,
  });

  final List<ScheduleItem> items;
  final Future<void> Function(ScheduleItem) onDelete;
  final Future<void> Function(ScheduleItem, bool) onToggleCompleted;
  final Future<void> Function(ScheduleItem) onEdit;
  final bool use24HourFormat;

  @override
  State<ScheduleList> createState() => _ScheduleListState();
}

class _ScheduleListState extends State<ScheduleList> {
  final Map<String, double> _swipeProgress = <String, double>{};
  final Set<String> _deletingByTap = <String>{};

  Future<void> _deleteWithTapAnimation(ScheduleItem item) async {
    if (_deletingByTap.contains(item.id)) return;
    setState(() {
      _deletingByTap.add(item.id);
      _swipeProgress[item.id] = 1;
    });
    await Future<void>.delayed(const Duration(milliseconds: 240));
    await widget.onDelete(item);
    if (!mounted) return;
    setState(() {
      _deletingByTap.remove(item.id);
      _swipeProgress.remove(item.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final item = widget.items[index];
        final progress = _swipeProgress[item.id] ?? 0;
        final removingByTap = _deletingByTap.contains(item.id);
        return Dismissible(
          key: ValueKey('dismiss-${item.id}'),
          direction: DismissDirection.horizontal,
          dismissThresholds: const <DismissDirection, double>{
            DismissDirection.startToEnd: 0.32,
            DismissDirection.endToStart: 0.32,
          },
          onUpdate: (details) {
            setState(() {
              _swipeProgress[item.id] = details.progress.clamp(0, 1);
            });
          },
          onDismissed: (direction) async {
            if (direction == DismissDirection.endToStart) {
              await widget.onDelete(item);
            } else {
              await widget.onToggleCompleted(item, !item.isCompleted);
            }
            if (!mounted) return;
            setState(() {
              _swipeProgress.remove(item.id);
              _deletingByTap.remove(item.id);
            });
          },
          background: _CompleteBackground(
            progress: progress,
            completed: item.isCompleted,
          ),
          secondaryBackground: _DeleteBackground(
            progress: progress,
            alignLeft: false,
          ),
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeInOut,
            offset: removingByTap ? const Offset(-1.1, 0) : Offset.zero,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 220),
              opacity: removingByTap ? 0.0 : 1.0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                color: Color.lerp(
                  Colors.transparent,
                  Colors.red.shade200,
                  progress.clamp(0, 1),
                ),
                child: Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.menu_book_rounded,
                        size: 18,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    title: Text(
                      item.subject,
                      style: TextStyle(
                        decoration: item.isCompleted
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        color: item.isCompleted
                            ? Theme.of(context).textTheme.bodySmall?.color
                            : null,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          '${item.dayLabel} - ${item.formattedStart(use24HourFormat: widget.use24HourFormat)} - ${item.formattedEnd(use24HourFormat: widget.use24HourFormat)}',
                        ),
                        const SizedBox(height: 6),
                        _PriorityBadge(priority: item.priority),
                        if (item.notes.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(item.notes),
                        ],
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          tooltip: 'Editar',
                          onPressed: () => widget.onEdit(item),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          tooltip: 'Eliminar',
                          onPressed: () => _deleteWithTapAnimation(item),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemCount: widget.items.length,
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge({required this.priority});

  final String priority;

  @override
  Widget build(BuildContext context) {
    final normalized = priority.toLowerCase();
    final (label, color) = switch (normalized) {
      'alta' => ('Alta', Colors.red.shade600),
      'baja' => ('Baja', Colors.blue.shade600),
      _ => ('Media', Colors.orange.shade700),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        'Prioridad: $label',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground({required this.progress, required this.alignLeft});

  final double progress;
  final bool alignLeft;

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    return Container(
      decoration: BoxDecoration(
        color: Color.lerp(Colors.red.shade200, Colors.red.shade700, clamped),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: alignLeft ? Alignment.centerLeft : Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: const Icon(Icons.delete, color: Colors.white),
    );
  }
}

class _CompleteBackground extends StatelessWidget {
  const _CompleteBackground({required this.progress, required this.completed});

  final double progress;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    final startColor = completed ? Colors.blue.shade200 : Colors.green.shade200;
    final endColor = completed ? Colors.blue.shade700 : Colors.green.shade700;
    return Container(
      decoration: BoxDecoration(
        color: Color.lerp(startColor, endColor, clamped),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            completed ? Icons.undo : Icons.check,
            color: Colors.white,
          ),
          const SizedBox(width: 8),
          Text(
            completed ? 'Restaurar' : 'Completar',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
