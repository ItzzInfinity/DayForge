import '../../../core/utils/date_utils.dart';
import '../../daily/domain/daily_log.dart';
import '../../tasks/domain/task.dart';

/// Derived, never stored (docs/data-model.md): computed client-side from a
/// task's daily logs (at most durationDays small documents).
class TaskProgress {
  const TaskProgress({
    required this.currentStreak,
    required this.completedDays,
    required this.elapsedDays,
  });

  /// Consecutive completed days ending today — or yesterday, so an
  /// unticked "today" doesn't zero the streak before the day is over.
  final int currentStreak;

  /// Completed days within the task's elapsed window.
  final int completedDays;

  /// Days the task has been running: startDate..min(today, endDate),
  /// inclusive. 0 for tasks that start in the future.
  final int elapsedDays;

  /// 0.0–1.0 of elapsed days that were completed.
  double get completionPercent =>
      elapsedDays == 0 ? 0 : completedDays / elapsedDays;
}

TaskProgress calculateProgress({
  required Task task,
  required List<DailyLog> logs,
  required DateTime today,
}) {
  final todayKey = toDateKey(today);
  final completedDates = {
    for (final log in logs)
      if (log.completed) log.date,
  };

  int elapsedDays;
  if (task.startDate.compareTo(todayKey) > 0) {
    elapsedDays = 0;
  } else {
    final windowEnd =
        task.endDate.compareTo(todayKey) <= 0 ? task.endDate : todayKey;
    elapsedDays = fromDateKey(windowEnd)
            .difference(fromDateKey(task.startDate))
            .inDays +
        1;
  }

  final completedDays = completedDates
      .where((date) =>
          date.compareTo(task.startDate) >= 0 &&
          date.compareTo(todayKey) <= 0)
      .length;

  var streak = 0;
  var cursor =
      completedDates.contains(todayKey) ? todayKey : addDaysToKey(todayKey, -1);
  while (completedDates.contains(cursor)) {
    streak++;
    cursor = addDaysToKey(cursor, -1);
  }

  return TaskProgress(
    currentStreak: streak,
    completedDays: completedDays,
    elapsedDays: elapsedDays,
  );
}
