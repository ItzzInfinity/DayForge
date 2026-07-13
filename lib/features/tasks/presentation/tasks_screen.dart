import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/task.dart';
import '../providers.dart';
import 'add_task_screen.dart';

class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(tasksProvider);
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
      body: tasks.when(
        data: (list) => list.isEmpty
            ? const Center(
                child: Text('No tasks yet.\nTap + to add your first one.',
                    textAlign: TextAlign.center),
              )
            : ListView.builder(
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: list.length,
                itemBuilder: (context, index) =>
                    _TaskTile(task: list[index]),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Could not load tasks: $error')),
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(task.title),
      subtitle: Text(
        '${task.startDate} → ${task.endDate} · ${task.durationDays} days'
        '${task.category != null ? ' · ${task.category}' : ''}',
      ),
      trailing: task.status == TaskStatus.active
          ? null
          : Chip(label: Text(task.status.name)),
    );
  }
}
