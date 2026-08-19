import '../../../core/utils/date_utils.dart';
import 'task.dart';

/// What the end date means for a task.
enum CompletionMode {
  /// The task ends on its end date whatever happened — a 21-day window is
  /// 21 calendar days.
  fixedWindow,

  /// The task runs until [Task.targetDays] days have actually been
  /// completed; missed days push the end date forward.
  targetDays,
}

/// New `durationDays` for [task] so it can still reach its target, or null
/// when nothing needs to change.
///
/// The rule is stated as an invariant rather than an end-of-run patch-up, so
/// applying it twice changes nothing: a target-days task always has at least
/// as many days left (counting today) as it still needs completions. Missing
/// today therefore rolls the end date forward by exactly one day.
int? rolloverDurationDays({
  required Task task,
  required int completedDays,
  required String todayKey,
}) {
  if (task.completionMode != CompletionMode.targetDays) return null;
  if (task.status != TaskStatus.active) return null;
  // Nothing to extend before the task has even started.
  if (todayKey.compareTo(task.startDate) < 0) return null;

  final remaining = task.targetDays - completedDays;
  if (remaining <= 0) return null;

  // The last day that still counts if every remaining day is completed.
  final requiredEnd = addDaysToKey(todayKey, remaining - 1);
  if (requiredEnd.compareTo(task.endDate) <= 0) return null;

  return fromDateKey(requiredEnd).difference(fromDateKey(task.startDate)).inDays +
      1;
}
