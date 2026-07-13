import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/widgets/content_width.dart';
import '../../../core/widgets/error_retry.dart';
import '../../daily/providers.dart';
import '../../tasks/domain/task.dart';
import '../../tasks/providers.dart';
import '../domain/progress_calculator.dart';
import 'task_detail_screen.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      body: ContentWidth(
          child: tasksAsync.when(
        data: (tasks) {
          final tracked = [
            for (final task in tasks)
              if (task.status != TaskStatus.archived) task
          ];
          if (tracked.isEmpty) {
            return const Center(
              child: Text(
                'No tasks to track yet.\nAdd one from the Tasks tab.',
                textAlign: TextAlign.center,
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(8),
            children: [
              for (final task in tracked) _ProgressCard(task: task),
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

class _ProgressCard extends ConsumerWidget {
  const _ProgressCard({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(taskLogsProvider(task.id));
    final today = ref.watch(currentDateProvider);
    return Card(
      key: ValueKey('progress-card-${task.id}'),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => TaskDetailScreen(task: task),
          ),
        ),
        child: Padding(
        padding: const EdgeInsets.all(16),
        child: logsAsync.when(
          data: (logs) {
            final progress =
                calculateProgress(task: task, logs: logs, today: today);
            final percent = (progress.completionPercent * 100).round();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        task.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    if (progress.currentStreak > 0)
                      Chip(
                        key: ValueKey('streak-${task.id}'),
                        avatar: const Text('🔥'),
                        label: Text('${progress.currentStreak} day'
                            '${progress.currentStreak == 1 ? '' : 's'}'),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${task.startDate} → ${task.endDate}'
                  '${task.status == TaskStatus.completed ? ' · completed' : ''}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: progress.completionPercent,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 6),
                Text(
                  key: ValueKey('completion-${task.id}'),
                  progress.elapsedDays == 0
                      ? 'Starts ${task.startDate}'
                      : '${progress.completedDays} of ${progress.elapsedDays} '
                          'days done · $percent%',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            );
          },
          loading: () => const SizedBox(
            height: 48,
            child: Center(
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          error: (error, _) => Row(
            children: [
              Expanded(
                child: Text('Could not load history. '
                    '${friendlyError(error)}'),
              ),
              IconButton(
                key: ValueKey('retry-logs-${task.id}'),
                icon: const Icon(Icons.refresh),
                tooltip: 'Retry',
                onPressed: () => ref.invalidate(taskLogsProvider(task.id)),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }
}
