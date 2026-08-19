import 'dart:convert';

import '../../features/tasks/domain/task.dart';
import 'reminder_sound.dart';

export 'reminder_sound.dart';

/// Global default reminder time until the user-editable settings doc ships.
const defaultReminderTime = '08:00';

/// Action id of the notification "Snooze" button.
const snoozeActionId = 'snooze';

/// Action id of the notification "Mark completed" button.
const markDoneActionId = 'mark-done';

/// Default snooze duration; user-configurable via AppSettings.snoozeMinutes.
const defaultSnoozeMinutes = 10;

/// Everything a sync needs from the user's settings. Bundled into one object
/// so adding a knob doesn't widen [ReminderScheduler.sync] again.
class ReminderOptions {
  const ReminderOptions({
    this.defaultTime = defaultReminderTime,
    this.snoozeMinutes = defaultSnoozeMinutes,
    this.sound = const ReminderSoundChoice(),
    this.completedToday = const <String>{},
  });

  /// Reminder time for tasks that carry none of their own.
  final String defaultTime;

  /// How far the notification's Snooze button postpones it.
  final int snoozeMinutes;

  final ReminderSoundChoice sound;

  /// Ids of tasks already ticked for today. Their reminder for *today* is
  /// skipped — ticking a task early must not summon its own reminder later
  /// the same day (the daily repeat resumes tomorrow).
  final Set<String> completedToday;
}

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
  /// `options.defaultTime`). Reminders carry a Snooze button and play
  /// `options.sound`.
  Future<void> sync(
    List<Task> tasks,
    DateTime now, {
    ReminderOptions options = const ReminderOptions(),
  });

  /// Fires a notification immediately, so the user can verify notifications
  /// work on this device (and hear the chosen sound) without waiting for a
  /// reminder time.
  Future<void> showNow({
    required String title,
    required String body,
    ReminderSoundChoice sound = const ReminderSoundChoice(),
  });

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

/// Notification ids per task: one slot per intraday occurrence (or per
/// Windows day), plus the last slot reserved for the snoozed one-shot.
const notificationSlotsPerTask = 64;

/// Deterministic 24-bit notification id for a task (String.hashCode is not
/// stable across runs). 24 bits × [notificationSlotsPerTask] stays inside a
/// signed 32-bit int, which is all Android accepts.
int stableNotificationId(String taskId) {
  var hash = 0x811c9dc5; // FNV-1a
  for (final unit in taskId.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash & 0xFFFFFF;
}

/// The next wall-clock occurrence of [hour]:[minute] strictly after [now].
DateTime nextOccurrence(DateTime now, int hour, int minute) {
  var candidate = DateTime(now.year, now.month, now.day, hour, minute);
  if (!candidate.isAfter(now)) {
    candidate = candidate.add(const Duration(days: 1));
  }
  return candidate;
}

/// When a task's reminder should next fire. [doneToday] pushes it past
/// today's occurrence, so a task ticked at 07:00 stays quiet at its 20:00
/// reminder and rings again tomorrow.
DateTime nextReminderInstant(
  DateTime now,
  int hour,
  int minute, {
  bool doneToday = false,
}) {
  final next = nextOccurrence(now, hour, minute);
  if (!doneToday) return next;
  final isStillToday = next.year == now.year &&
      next.month == now.month &&
      next.day == now.day;
  return isStillToday ? nextOccurrence(next, hour, minute) : next;
}

/// Every wall-clock time [task] should remind at, in order: one entry for a
/// plain daily task, one per window slot for an intraday one.
List<({int hour, int minute})> reminderTimesFor(
  Task task, {
  String defaultTime = defaultReminderTime,
}) {
  if (!task.recurrence.isIntraday) {
    return [parseHhMm(task.reminderTime ?? defaultTime)];
  }
  return [
    for (final minutes in task.recurrence.occurrenceMinutes)
      (hour: minutes ~/ 60, minute: minutes % 60),
  ];
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
  ReminderSoundChoice sound = const ReminderSoundChoice(),
  int target = 1,
}) =>
    jsonEncode({
      'title': title,
      'body': body,
      'minutes': minutes,
      'taskId': taskId,
      'target': target,
      'soundId': sound.sound.id,
      'soundUri': sound.deviceUri,
      'soundLabel': sound.deviceLabel,
      'alarmVolume': sound.alarmVolume,
    });

({
  String title,
  String body,
  int minutes,
  String taskId,
  int target,
  ReminderSoundChoice sound,
})? decodeReminderPayload(String? payload) {
  if (payload == null || payload.isEmpty) return null;
  try {
    final map = jsonDecode(payload) as Map<String, dynamic>;
    return (
      title: map['title'] as String,
      body: map['body'] as String,
      minutes: map['minutes'] as int,
      taskId: map['taskId'] as String,
      // Ticks needed for the day; 1 for every non-intraday task.
      target: map['target'] as int? ?? 1,
      // Payloads written before sounds shipped carry no sound keys; the
      // defaults below then reproduce the previous behavior.
      sound: ReminderSoundChoice(
        sound: ReminderSound.byId(map['soundId'] as String?),
        deviceUri: map['soundUri'] as String?,
        deviceLabel: map['soundLabel'] as String?,
        alarmVolume: map['alarmVolume'] as bool? ?? true,
      ),
    );
  } catch (_) {
    return null;
  }
}

/// Id for the snoozed one-shot: the task's last reserved slot (base ids are
/// multiples of [notificationSlotsPerTask]), so repeats replace themselves
/// and never collide with another task's reminders.
int snoozeNotificationId(int firedId) =>
    (firedId ~/ notificationSlotsPerTask) * notificationSlotsPerTask +
    notificationSlotsPerTask -
    1;
