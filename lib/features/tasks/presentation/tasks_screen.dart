import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/content_width.dart';
import '../../../core/widgets/error_retry.dart';
import '../../progress/presentation/task_detail_screen.dart';
import '../domain/task.dart';
import '../providers.dart';
import 'add_task_screen.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  String _query = '';
  TaskStatus? _statusFilter = TaskStatus.active;
  String? _categoryFilter;

  List<Task> _filtered(List<Task> tasks) {
    final query = _query.trim().toLowerCase();
    return [
      for (final task in tasks)
        if ((_statusFilter == null || task.status == _statusFilter) &&
            (_categoryFilter == null || task.category == _categoryFilter) &&
            (query.isEmpty ||
                task.title.toLowerCase().contains(query) ||
                (task.description?.toLowerCase().contains(query) ?? false)))
          task
    ];
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Tasks')),
      floatingActionButton: FloatingActionButton(
        key: const Key('add-task'),
        tooltip: 'Add task',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const AddTaskScreen()),
        ),
        child: const Icon(Icons.add),
      ),
      body: ContentWidth(
          child: tasksAsync.when(
        data: (tasks) {
          if (tasks.isEmpty) {
            return const Center(
              child: Text('No tasks yet.\nTap + to add your first one.',
                  textAlign: TextAlign.center),
            );
          }
          final categories = {
            for (final t in tasks)
              if (t.category != null) t.category!
          }.toList()
            ..sort();
          final visible = _filtered(tasks);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: TextField(
                  key: const Key('task-search'),
                  decoration: const InputDecoration(
                    hintText: 'Search tasks…',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    for (final (label, status) in [
                      ('All', null),
                      ('Active', TaskStatus.active),
                      ('Completed', TaskStatus.completed),
                      ('Archived', TaskStatus.archived),
                    ])
                      Padding(
                        padding: const EdgeInsets.only(right: 8, top: 8),
                        child: ChoiceChip(
                          key: Key('filter-${label.toLowerCase()}'),
                          label: Text(label),
                          selected: _statusFilter == status,
                          onSelected: (_) =>
                              setState(() => _statusFilter = status),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    if (categories.isNotEmpty)
                      const Padding(
                        padding: EdgeInsets.only(right: 8, top: 8),
                        child: SizedBox(height: 32, child: VerticalDivider()),
                      ),
                    for (final category in categories)
                      Padding(
                        padding: const EdgeInsets.only(right: 8, top: 8),
                        child: FilterChip(
                          key: Key('filter-cat-$category'),
                          label: Text(category),
                          selected: _categoryFilter == category,
                          onSelected: (selected) => setState(
                            () =>
                                _categoryFilter = selected ? category : null,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: visible.isEmpty
                    ? const Center(child: Text('No tasks match your filters.'))
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 80),
                        itemCount: visible.length,
                        itemBuilder: (context, index) =>
                            _TaskTile(task: visible[index]),
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorRetry(
          message: 'Could not load your tasks.',
          error: error,
          onRetry: () => ref.invalidate(tasksProvider),
        ),
      )),
    );
  }
}

class _TaskTile extends ConsumerWidget {
  const _TaskTile({required this.task});

  final Task task;

  Future<void> _setStatus(WidgetRef ref, TaskStatus status) async {
    await ref.read(taskRepositoryProvider)?.setStatus(task.id, status);
    ref.invalidate(tasksProvider);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
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
    return ListTile(
      key: ValueKey('task-tile-${task.id}'),
      title: Text(task.title),
      subtitle: Text(
        '${task.startDate} → ${task.endDate} · ${task.durationDays} days'
        '${task.category != null ? ' · ${task.category}' : ''}',
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => TaskDetailScreen(task: task),
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (task.status != TaskStatus.active)
            Chip(
              label: Text(task.status.name),
              visualDensity: VisualDensity.compact,
            ),
          PopupMenuButton<String>(
            key: ValueKey('task-menu-${task.id}'),
            onSelected: (action) => switch (action) {
              'complete' => _setStatus(ref, TaskStatus.completed),
              'reactivate' => _setStatus(ref, TaskStatus.active),
              'archive' => _setStatus(ref, TaskStatus.archived),
              'delete' => _delete(context, ref),
              _ => Future<void>.value(),
            },
            itemBuilder: (context) => [
              if (task.status == TaskStatus.active)
                const PopupMenuItem(
                  value: 'complete',
                  child: Text('Mark completed'),
                )
              else
                const PopupMenuItem(
                  value: 'reactivate',
                  child: Text('Reactivate'),
                ),
              if (task.status != TaskStatus.archived)
                const PopupMenuItem(value: 'archive', child: Text('Archive')),
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
    );
  }
}
