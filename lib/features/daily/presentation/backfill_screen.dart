import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/content_width.dart';
import '../../../core/widgets/error_retry.dart';
import '../../tasks/domain/task.dart';
import '../../tasks/providers.dart';
import '../providers.dart';

/// Settings → Advanced → Backfill task history.
///
/// For habits the user was already doing before adding them to the app:
/// pick a task and tick any past day up to today. Writes the same merge-safe
/// daily-log documents as the Today screen, so streaks and calendars update.
class BackfillScreen extends ConsumerStatefulWidget {
  const BackfillScreen({super.key});

  @override
  ConsumerState<BackfillScreen> createState() => _BackfillScreenState();
}

class _BackfillScreenState extends ConsumerState<BackfillScreen> {
  String? _taskId;

  /// Local ticks layered over the fetched logs so checkboxes respond
  /// instantly while the write and re-read are in flight.
  final _overrides = <String, bool>{};

  Future<void> _setDay(String taskId, String dateKey, bool completed) async {
    setState(() => _overrides[dateKey] = completed);
    final repo = ref.read(dailyLogRepositoryProvider);
    if (repo == null) return;
    try {
      await repo.setCompleted(taskId, dateKey, completed: completed);
      ref.invalidate(taskLogsProvider(taskId));
      ref.invalidate(todayLogProvider(taskId));
    } catch (_) {
      if (!mounted) return;
      setState(() => _overrides[dateKey] = !completed);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save. Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksProvider);
    final today = toDateKey(ref.watch(currentDateProvider));

    return Scaffold(
      appBar: AppBar(title: const Text('Backfill task history')),
      body: ContentWidth(
        child: tasksAsync.when(
          data: (tasks) {
            final selectable = [
              for (final task in tasks)
                if (task.status != TaskStatus.archived) task
            ];
            if (selectable.isEmpty) {
              return const Center(
                child: Text('No tasks to backfill yet.\n'
                    'Add one from the Tasks tab first.'),
              );
            }
            final task = selectable
                .where((t) => t.id == _taskId)
                .firstOrNull;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: DropdownButtonFormField<String>(
                    key: const Key('backfill-task'),
                    initialValue: task?.id,
                    decoration: const InputDecoration(
                      labelText: 'Task',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final t in selectable)
                        DropdownMenuItem(value: t.id, child: Text(t.title)),
                    ],
                    onChanged: (id) => setState(() {
                      _taskId = id;
                      _overrides.clear();
                    }),
                  ),
                ),
                if (task == null)
                  const Expanded(
                    child: Center(
                      child: Text('Pick a task to see its days.'),
                    ),
                  )
                else
                  Expanded(child: _DayList(
                    task: task,
                    today: today,
                    overrides: _overrides,
                    onChanged: (dateKey, v) => _setDay(task.id, dateKey, v),
                  )),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ErrorRetry(
            message: 'Could not load your tasks.',
            error: error,
            onRetry: () => ref.invalidate(tasksProvider),
          ),
        ),
      ),
    );
  }
}

class _DayList extends ConsumerWidget {
  const _DayList({
    required this.task,
    required this.today,
    required this.overrides,
    required this.onChanged,
  });

  final Task task;
  final String today;
  final Map<String, bool> overrides;
  final void Function(String dateKey, bool completed) onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(taskLogsProvider(task.id));
    return logsAsync.when(
      data: (logs) {
        if (task.startDate.compareTo(today) > 0) {
          return const Center(
            child: Text('This task has not started yet — '
                'there are no days to backfill.'),
          );
        }
        final completedDays = {
          for (final log in logs)
            if (log.completed) log.date,
        };
        // Newest first: the days someone wants to backfill are usually the
        // recent ones just before they added the task.
        final last = task.endDate.compareTo(today) < 0 ? task.endDate : today;
        final dayCount =
            fromDateKey(last).difference(fromDateKey(task.startDate)).inDays +
                1;
        return ListView.builder(
          itemCount: dayCount,
          itemBuilder: (context, index) {
            final dateKey = addDaysToKey(last, -index);
            final dayNumber = dayCount - index;
            final completed =
                overrides[dateKey] ?? completedDays.contains(dateKey);
            return CheckboxListTile(
              key: ValueKey('backfill-$dateKey'),
              value: completed,
              onChanged: (v) => onChanged(dateKey, v ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(dateKey == today ? '$dateKey · today' : dateKey),
              subtitle: Text('Day $dayNumber of ${task.durationDays}'),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => ErrorRetry(
        message: 'Could not load this task\'s history.',
        error: error,
        onRetry: () => ref.invalidate(taskLogsProvider(task.id)),
      ),
    );
  }
}
