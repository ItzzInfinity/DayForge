import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/content_width.dart';
import '../../../core/widgets/error_retry.dart';
import '../domain/task.dart';
import '../providers.dart';

/// Archived tasks live here (reached from Settings), out of the way of the
/// main Tasks list. Restore brings a task back as active; delete is final.
class ArchiveScreen extends ConsumerWidget {
  const ArchiveScreen({super.key});

  Future<void> _restore(WidgetRef ref, Task task) async {
    await ref.read(taskRepositoryProvider)?.setStatus(
          task.id, TaskStatus.active);
    ref.invalidate(tasksProvider);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete "${task.title}"?'),
        content: const Text(
            'This also deletes its daily history and cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('confirm-delete'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(taskRepositoryProvider)?.delete(task.id);
    ref.invalidate(tasksProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Archived tasks')),
      body: ContentWidth(
          child: tasksAsync.when(
        data: (tasks) {
          final archived = [
            for (final task in tasks)
              if (task.status == TaskStatus.archived) task
          ];
          if (archived.isEmpty) {
            return const Center(
              child: Text(
                'Nothing archived.\n'
                'Archive a task from its menu on the Tasks tab.',
                textAlign: TextAlign.center,
              ),
            );
          }
          return ListView.builder(
            itemCount: archived.length,
            itemBuilder: (context, index) {
              final task = archived[index];
              return ListTile(
                key: ValueKey('archived-tile-${task.id}'),
                title: Text(task.title),
                subtitle: Text(
                  '${task.startDate} → ${task.endDate} · '
                  '${task.durationDays} days'
                  '${task.category != null ? ' · ${task.category}' : ''}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      key: ValueKey('restore-${task.id}'),
                      icon: const Icon(Icons.unarchive_outlined),
                      tooltip: 'Restore to active',
                      onPressed: () => _restore(ref, task),
                    ),
                    IconButton(
                      key: ValueKey('archive-delete-${task.id}'),
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Delete forever',
                      onPressed: () => _delete(context, ref, task),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorRetry(
          message: 'Could not load archived tasks.',
          error: error,
          onRetry: () => ref.invalidate(tasksProvider),
        ),
      )),
    );
  }
}
