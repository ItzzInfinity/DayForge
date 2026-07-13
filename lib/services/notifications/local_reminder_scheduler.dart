import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../core/utils/date_utils.dart';
import '../../features/tasks/domain/task.dart';
import 'reminder_scheduler.dart';

/// Handles the Snooze action while the app process is NOT running
/// (Android only: actions with showsUserInterface=false arrive in a
/// background isolate). Schedules a one-shot repeat of the reminder.
@pragma('vm:entry-point')
void notificationActionBackground(NotificationResponse response) {
  if (response.actionId != snoozeActionId) return;
  final payload = decodeSnoozePayload(response.payload);
  if (payload == null) return;
  tzdata.initializeTimeZones();
  FlutterLocalNotificationsPlugin().zonedSchedule(
    id: snoozeNotificationId(response.id ?? 0),
    title: payload.title,
    body: payload.body,
    scheduledDate: tz.TZDateTime.now(tz.UTC)
        .add(Duration(minutes: payload.minutes)),
    notificationDetails:
        LocalReminderScheduler.detailsWithSnooze(payload.minutes),
    payload: response.payload,
    androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
  );
}

/// [ReminderScheduler] backed by flutter_local_notifications.
///
/// Times are scheduled as absolute UTC instants; in DST-observing zones a
/// repeating Android reminder can drift an hour until the next app launch
/// re-syncs it (no DST in IST, so not user-visible here).
class LocalReminderScheduler implements ReminderScheduler {
  final _plugin = FlutterLocalNotificationsPlugin();
  final _linuxTimers = <int, Timer>{};
  bool _initialized = false;

  static const _windowsDaysAhead = 7;

  Future<void> _init() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      linux: LinuxInitializationSettings(defaultActionName: 'Open'),
      windows: WindowsInitializationSettings(
        appName: 'Advanced To-Do',
        appUserModelId: 'com.sisirradar.advancedTodo',
        guid: '7f8a1e5c-4b2d-4f9a-9c3e-6d5b8a7c2e10',
      ),
    );
    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _onResponse,
      onDidReceiveBackgroundNotificationResponse:
          notificationActionBackground,
    );
    _initialized = true;
  }

  /// Snooze action tapped while the app runs (always the case on Linux,
  /// where reminders only exist in-process; possible on Android too).
  Future<void> _onResponse(NotificationResponse response) async {
    if (response.actionId != snoozeActionId) return;
    final payload = decodeSnoozePayload(response.payload);
    if (payload == null) return;
    final id = snoozeNotificationId(response.id ?? 0);
    debugPrint('reminders: snoozing id ${response.id} for '
        '${payload.minutes} min');
    if (Platform.isLinux) {
      // No OS scheduling on Linux — an in-app timer re-shows it.
      _linuxTimers[id]?.cancel();
      _linuxTimers[id] = Timer(Duration(minutes: payload.minutes), () {
        _plugin.show(
          id: id,
          title: payload.title,
          body: payload.body,
          notificationDetails: detailsWithSnooze(payload.minutes),
          payload: response.payload,
        );
      });
    } else {
      await _plugin.zonedSchedule(
        id: id,
        title: payload.title,
        body: payload.body,
        scheduledDate: tz.TZDateTime.now(tz.UTC)
            .add(Duration(minutes: payload.minutes)),
        notificationDetails: detailsWithSnooze(payload.minutes),
        payload: response.payload,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  @override
  Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    await _init();
    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      return await android?.requestNotificationsPermission() ?? false;
    }
    return true; // Windows/Linux have no runtime notification permission.
  }

  /// Reminder details incl. a Snooze button (Android + Linux; the Windows
  /// plugin has no action support, so toasts there are snooze-less).
  static NotificationDetails detailsWithSnooze(int snoozeMinutes) =>
      NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminders',
          'Daily reminders',
          channelDescription: 'Reminds you to tick your daily tasks',
          importance: Importance.high,
          priority: Priority.high,
          actions: [
            AndroidNotificationAction(
              snoozeActionId,
              'Snooze $snoozeMinutes min',
              showsUserInterface: false,
              cancelNotification: true,
            ),
          ],
        ),
        linux: LinuxNotificationDetails(
          actions: [
            LinuxNotificationAction(
              key: snoozeActionId,
              label: 'Snooze $snoozeMinutes min',
            ),
          ],
        ),
        windows: const WindowsNotificationDetails(),
      );

  /// Plain details for one-off notifications (test notification).
  NotificationDetails get _details => const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminders',
          'Daily reminders',
          channelDescription: 'Reminds you to tick your daily tasks',
          importance: Importance.high,
          priority: Priority.high,
        ),
        linux: LinuxNotificationDetails(),
        windows: WindowsNotificationDetails(),
      );

  String _bodyFor(Task task) => 'Time to tick "${task.title}" for today.';

  @override
  Future<void> showNow({required String title, required String body}) async {
    await _init();
    await _plugin.show(
      id: 1, // fixed id: repeated tests replace rather than pile up
      title: title,
      body: body,
      notificationDetails: _details,
    );
  }

  @override
  Future<void> sync(
    List<Task> tasks,
    DateTime now, {
    String defaultTime = defaultReminderTime,
    int snoozeMinutes = defaultSnoozeMinutes,
  }) async {
    await _init();
    // Small task counts: clearing and re-adding is the simplest way to stay
    // correct across edits, archives, and expired tasks.
    await _plugin.cancelAll();
    for (final timer in _linuxTimers.values) {
      timer.cancel();
    }
    _linuxTimers.clear();

    final todayKey = toDateKey(now);
    for (final task in tasks) {
      if (task.status != TaskStatus.active) continue;
      if (task.endDate.compareTo(todayKey) < 0) continue;
      final time = parseHhMm(task.reminderTime ?? defaultTime);
      final baseId = stableNotificationId(task.id) * 10;
      final payload = encodeSnoozePayload(
        title: 'Advanced To-Do',
        body: _bodyFor(task),
        minutes: snoozeMinutes,
      );

      if (Platform.isAndroid) {
        await _plugin.zonedSchedule(
          id: baseId,
          title: 'Advanced To-Do',
          body: _bodyFor(task),
          scheduledDate: tz.TZDateTime.from(
            nextOccurrence(now, time.hour, time.minute).toUtc(),
            tz.UTC,
          ),
          notificationDetails: detailsWithSnooze(snoozeMinutes),
          payload: payload,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } else if (Platform.isWindows) {
        // No repeating toasts on Windows: schedule the coming week and
        // refresh on every launch/sync.
        var when = nextOccurrence(now, time.hour, time.minute);
        for (var i = 0; i < _windowsDaysAhead; i++) {
          if (toDateKey(when).compareTo(task.endDate) > 0) break;
          await _plugin.zonedSchedule(
            id: baseId + i,
            title: 'Advanced To-Do',
            body: _bodyFor(task),
            scheduledDate: tz.TZDateTime.from(when.toUtc(), tz.UTC),
            notificationDetails: detailsWithSnooze(snoozeMinutes),
            payload: payload,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          );
          when = when.add(const Duration(days: 1));
        }
      } else if (Platform.isLinux) {
        _scheduleLinuxTimer(task, time.hour, time.minute, baseId,
            snoozeMinutes, payload);
      }
      debugPrint(
        'reminders: armed "${task.title}" daily at '
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} '
        '(id $baseId, until ${task.endDate}, snooze ${snoozeMinutes}m)',
      );
    }
  }

  /// Linux has no OS-level scheduling; fire from an in-app timer while the
  /// app is running, then re-arm for the next day.
  void _scheduleLinuxTimer(Task task, int hour, int minute, int id,
      int snoozeMinutes, String payload) {
    final now = DateTime.now();
    final next = nextOccurrence(now, hour, minute);
    if (toDateKey(next).compareTo(task.endDate) > 0) return;
    _linuxTimers[id] = Timer(next.difference(now), () async {
      try {
        await _plugin.show(
          id: id,
          title: 'Advanced To-Do',
          body: _bodyFor(task),
          notificationDetails: detailsWithSnooze(snoozeMinutes),
          payload: payload,
        );
        debugPrint('reminders: fired "${task.title}" (id $id)');
      } catch (e) {
        debugPrint('reminders: show failed for "${task.title}": $e');
      } finally {
        _scheduleLinuxTimer(task, hour, minute, id, snoozeMinutes, payload);
      }
    });
  }
}
