import 'package:flutter/foundation.dart' show debugPrint;

import '../../../core/utils/date_utils.dart';
import '../../daily/data/daily_log_repository.dart';
import '../domain/rollover.dart';
import '../domain/task.dart';
import 'task_repository.dart';

/// Moves the end date of "target days" tasks forward when completed days lag
/// behind. Runs on every task-list load (cheap: only target-days tasks are
/// read, and each has at most a few dozen log documents) and writes only the
/// tasks that actually changed.
///
/// Returns the tasks it rewrote, so callers can log or refresh.
Future<List<Task>> applyRollovers({
  required List<Task> tasks,
  required TaskRepository taskRepository,
  required DailyLogRepository dailyLogRepository,
  required DateTime now,
}) async {
  final todayKey = toDateKey(now);
  final rolled = <Task>[];
  for (final task in tasks) {
    if (task.completionMode != CompletionMode.targetDays) continue;
    if (task.status != TaskStatus.active) continue;
    if (todayKey.compareTo(task.startDate) < 0) continue;

    final logs = await dailyLogRepository.getAllForTask(task.id);
    final completedDays = logs.where((log) => log.completed).length;
    final durationDays = rolloverDurationDays(
      task: task,
      completedDays: completedDays,
      todayKey: todayKey,
    );
    if (durationDays == null) continue;

    final updated = await taskRepository.save(
      // Pin the goal: it defaults to durationDays, which the extension is
      // about to change — leaving it derived would move the target every
      // time and the task would never finish.
      task.copyWith(
        durationDays: durationDays,
        targetDays: () => task.targetDays,
      ),
    );
    rolled.add(updated);
    debugPrint('rollover: "${task.title}" now runs to ${updated.endDate} '
        '($completedDays/${task.targetDays} days done)');
  }
  return rolled;
}
