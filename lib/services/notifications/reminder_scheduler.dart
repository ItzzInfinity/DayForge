import '../../features/tasks/domain/task.dart';

/// Global default reminder time until the user-editable settings doc ships.
const defaultReminderTime = '08:00';

/// Schedules daily "tick your task" reminders. Platform behavior differs
/// (docs/architecture.md → reminders):
/// - Android: OS-level daily repeating notifications, survive reboots.
/// - Windows: one-shot toasts for the coming week, refreshed each launch.
/// - Linux: in-app timers; reminders fire while the app is running.
abstract interface class ReminderScheduler {
  /// Asks the OS for notification permission where needed (Android 13+).
  Future<bool> requestPermission();

  /// Replaces every scheduled reminder so they match [tasks]: one daily
  /// reminder per active, not-yet-ended task at its reminderTime (or
  /// [defaultTime] from the user's settings).
  Future<void> sync(
    List<Task> tasks,
    DateTime now, {
    String defaultTime = defaultReminderTime,
  });

  /// Fires a notification immediately, so the user can verify notifications
  /// work on this device without waiting for a reminder time.
  Future<void> showNow({required String title, required String body});
}

/// Parses `"HH:mm"` → (hour, minute).
({int hour, int minute}) parseHhMm(String time) {
  final parts = time.split(':');
  return (hour: int.parse(parts[0]), minute: int.parse(parts[1]));
}

/// Deterministic 26-bit notification id for a task (String.hashCode is not
/// stable across runs). Leaves room to multiply for per-day sub-ids while
/// staying inside a signed 32-bit int.
int stableNotificationId(String taskId) {
  var hash = 0x811c9dc5; // FNV-1a
  for (final unit in taskId.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash & 0x3FFFFFF;
}

/// The next wall-clock occurrence of [hour]:[minute] strictly after [now].
DateTime nextOccurrence(DateTime now, int hour, int minute) {
  var candidate = DateTime(now.year, now.month, now.day, hour, minute);
  if (!candidate.isAfter(now)) {
    candidate = candidate.add(const Duration(days: 1));
  }
  return candidate;
}
