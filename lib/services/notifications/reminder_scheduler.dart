import 'dart:convert';

import '../../features/tasks/domain/task.dart';

/// Global default reminder time until the user-editable settings doc ships.
const defaultReminderTime = '08:00';

/// Action id of the notification "Snooze" button.
const snoozeActionId = 'snooze';

/// Action id of the notification "Mark completed" button.
const markDoneActionId = 'mark-done';

/// Default snooze duration; user-configurable via AppSettings.snoozeMinutes.
const defaultSnoozeMinutes = 10;

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
  /// [defaultTime] from the user's settings). Reminders carry a Snooze
  /// button that postpones them by [snoozeMinutes].
  Future<void> sync(
    List<Task> tasks,
    DateTime now, {
    String defaultTime = defaultReminderTime,
    int snoozeMinutes = defaultSnoozeMinutes,
  });

  /// Fires a notification immediately, so the user can verify notifications
  /// work on this device without waiting for a reminder time.
  Future<void> showNow({required String title, required String body});

  /// Invoked when the user taps a reminder's "Mark completed" action while
  /// the app process is running. Set by the app shell to write today's
  /// daily log (the background-isolate path writes to Firestore directly).
  set onMarkCompleted(Future<void> Function(String taskId)? handler);
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

/// Notification payload carried by a reminder so its actions know what task
/// it belongs to, what to re-show on Snooze and how long to wait — including
/// in the Android background isolate, where only the payload string is
/// available.
String encodeReminderPayload({
  required String title,
  required String body,
  required int minutes,
  required String taskId,
}) =>
    jsonEncode({
      'title': title,
      'body': body,
      'minutes': minutes,
      'taskId': taskId,
    });

({String title, String body, int minutes, String taskId})?
    decodeReminderPayload(String? payload) {
  if (payload == null || payload.isEmpty) return null;
  try {
    final map = jsonDecode(payload) as Map<String, dynamic>;
    return (
      title: map['title'] as String,
      body: map['body'] as String,
      minutes: map['minutes'] as int,
      taskId: map['taskId'] as String,
    );
  } catch (_) {
    return null;
  }
}

/// Id for the snoozed one-shot: the task's reserved `+9` slot (base ids are
/// multiples of 10; Windows uses +0..+6), so repeats replace themselves and
/// never collide with another task's reminders.
int snoozeNotificationId(int firedId) => (firedId ~/ 10) * 10 + 9;
