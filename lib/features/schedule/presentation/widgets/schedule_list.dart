import 'package:flutter/material.dart';

import '../../domain/schedule_item.dart';

class ScheduleList extends StatelessWidget {
  const ScheduleList({super.key, required this.items, required this.onDelete});

  final List<ScheduleItem> items;
  final ValueChanged<ScheduleItem> onDelete;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final item = items[index];
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
              onPressed: () => onDelete(item),
            ),
          ),
        );
      },
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemCount: items.length,
    );
  }
}
