import 'package:flutter/material.dart';

import '../../domain/schedule_item.dart';

class ScheduleList extends StatefulWidget {
  const ScheduleList({
    super.key,
    required this.items,
    required this.onDelete,
    required this.use24HourFormat,
  });

  final List<ScheduleItem> items;
  final Future<void> Function(ScheduleItem) onDelete;
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
          onDismissed: (_) async {
            await widget.onDelete(item);
            if (!mounted) return;
            setState(() {
              _swipeProgress.remove(item.id);
              _deletingByTap.remove(item.id);
            });
          },
          background: _DeleteBackground(progress: progress, alignLeft: true),
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
                    title: Text(item.subject),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          '${item.day} • ${item.formattedStart(use24HourFormat: widget.use24HourFormat)} - ${item.formattedEnd(use24HourFormat: widget.use24HourFormat)}',
                        ),
                        if (item.notes.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(item.notes),
                        ],
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _deleteWithTapAnimation(item),
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
