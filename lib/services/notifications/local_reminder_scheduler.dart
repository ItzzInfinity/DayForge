import 'dart:async';
import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/widgets.dart' show WidgetsFlutterBinding;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../core/utils/date_utils.dart';
import '../../features/tasks/domain/task.dart';
import '../../firebase_options.dart';
import 'reminder_scheduler.dart';

/// Handles notification actions while the app process is NOT running
/// (Android only: actions with showsUserInterface=false arrive in a
/// background isolate). Snooze schedules a one-shot repeat; Mark completed
/// writes today's daily log straight to Firestore via the native SDK.
@pragma('vm:entry-point')
Future<void> notificationActionBackground(NotificationResponse response) async {
  final payload = decodeReminderPayload(response.payload);
  if (payload == null) return;
  if (response.actionId == snoozeActionId) {
    tzdata.initializeTimeZones();
    await FlutterLocalNotificationsPlugin().zonedSchedule(
      id: snoozeNotificationId(response.id ?? 0),
      title: payload.title,
      body: payload.body,
      scheduledDate: tz.TZDateTime.now(tz.UTC)
          .add(Duration(minutes: payload.minutes)),
      notificationDetails:
          LocalReminderScheduler.reminderDetails(payload.minutes,
              sound: payload.sound),
      payload: response.payload,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  } else if (response.actionId == markDoneActionId) {
    await markCompletedFromBackground(payload.taskId, target: payload.target);
  }
}

/// Ticks today's log for [taskId] from the Android background isolate:
/// same merge-safe document the Today screen writes, so nothing clobbers.
/// The signed-in user comes from the native Firebase SDK, which persists
/// sessions across processes; offline taps queue via Firestore persistence.
Future<void> markCompletedFromBackground(String taskId,
    {int target = 1}) async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    // A freshly spawned background isolate has no auth state yet: the native
    // SDK restores the persisted session asynchronously, so currentUser is
    // null for a moment right after initializeApp. Reading it immediately
    // would hit the "no user" branch and silently drop the tap. Wait for the
    // first hydrated auth state (bounded, so a genuinely signed-out user
    // still returns promptly).
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser ??
        await auth
            .authStateChanges()
            .firstWhere((u) => u != null)
            .timeout(const Duration(seconds: 5), onTimeout: () => null);
    final uid = user?.uid;
    if (uid == null) {
      debugPrint('reminders: mark-done skipped, no signed-in user');
      return;
    }
    final now = DateTime.now();
    final dateKey = toDateKey(now);
    final doc = FirebaseFirestore.instance
        .doc('users/$uid/tasks/$taskId/daily_logs/$dateKey');
    // Intraday tasks (target > 1) count taps; the day completes on the last
    // one. The payload carries the target, so this isolate never has to read
    // the task document.
    var count = 1;
    if (target > 1) {
      final existing = (await doc.get()).data();
      final previous = (existing?['count'] as int?) ??
          (((existing?['completed'] as bool?) ?? false) ? 1 : 0);
      count = (previous + 1).clamp(0, target);
    }
    final completed = count >= target;
    await doc.set({
      'date': dateKey,
      'count': count,
      'completed': completed,
      'completedAt': completed ? now.toUtc() : null,
      'updatedAt': now.toUtc(),
    }, SetOptions(merge: true));
    debugPrint('reminders: recorded $taskId $count/$target for $dateKey '
        '(background)');
  } catch (e) {
    debugPrint('reminders: background mark-done failed: $e');
  }
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

  /// Set by the app shell (AuthGate); handles Mark completed while the app
  /// runs, so providers refresh and the Today screen updates live.
  @override
  Future<void> Function(String taskId)? onMarkCompleted;

  static const _windowsDaysAhead = 7;

  Future<void> _init() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      linux: LinuxInitializationSettings(defaultActionName: 'Open'),
      windows: WindowsInitializationSettings(
        appName: 'DayForge',
        appUserModelId: 'com.itzzinfinity.advancedTodo',
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

  /// Notification touched or an action tapped while the app runs (always
  /// the case on Linux, where reminders only exist in-process; possible on
  /// Android too).
  Future<void> _onResponse(NotificationResponse response) async {
    // A plain touch dismisses the (persistent) reminder — that's the deal:
    // it stays in the tray until touched or marked completed.
    if (response.actionId == null) {
      if (response.id != null) await _plugin.cancel(id: response.id!);
      return;
    }
    final payload = decodeReminderPayload(response.payload);
    if (payload == null) return;

    if (response.actionId == markDoneActionId) {
      debugPrint('reminders: mark-done tapped for task ${payload.taskId}');
      if (response.id != null) await _plugin.cancel(id: response.id!);
      final handler = onMarkCompleted;
      if (handler != null) {
        await handler(payload.taskId);
      } else if (Platform.isAndroid) {
        await markCompletedFromBackground(payload.taskId,
            target: payload.target);
      }
      return;
    }

    if (response.actionId != snoozeActionId) return;
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
          notificationDetails:
              reminderDetails(payload.minutes, sound: payload.sound),
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
        notificationDetails:
            reminderDetails(payload.minutes, sound: payload.sound),
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

  /// Android sound for [choice]; null means "the channel's default sound".
  static AndroidNotificationSound? _androidSound(ReminderSoundChoice choice) {
    if (choice.usesDeviceSound) {
      return UriAndroidNotificationSound(choice.deviceUri!);
    }
    final resource = choice.sound.resource;
    return resource == null ? null : RawResourceAndroidNotificationSound(resource);
  }

  /// Linux plays the bundled asset directly; a device URI is Android-only, so
  /// Linux falls back to the notification server's own sound.
  static LinuxNotificationSound? _linuxSound(ReminderSoundChoice choice) {
    final asset = choice.sound.assetPath;
    return asset == null ? null : AssetsLinuxSound(asset);
  }

  /// Windows has no custom audio outside MSIX packages, so the bundled tones
  /// map onto the closest built-in toast sounds.
  static WindowsNotificationAudio _windowsAudio(ReminderSoundChoice choice) {
    if (choice.isSilent) return WindowsNotificationAudio.silent();
    final preset = switch (choice.sound.id) {
      'alarm' || 'buzz' => WindowsNotificationSound.alarm2,
      'bell' || 'chime' => WindowsNotificationSound.reminder,
      'beep' => WindowsNotificationSound.im,
      _ => WindowsNotificationSound.defaultSound,
    };
    return WindowsNotificationAudio.preset(sound: preset);
  }

  /// Reminder details: Mark completed + Snooze buttons (Android + Linux;
  /// the Windows plugin has no action support, so toasts there are plain).
  /// On Android the notification is persistent (`ongoing`, no auto-cancel):
  /// it stays in the tray until touched or marked completed.
  ///
  /// The Android channel id varies with the chosen sound ([
  /// ReminderSoundChoice.channelKey]) because channels are immutable once
  /// created — reusing one id would freeze the very first sound forever.
  static NotificationDetails reminderDetails(
    int snoozeMinutes, {
    ReminderSoundChoice sound = const ReminderSoundChoice(),
  }) =>
      NotificationDetails(
        android: AndroidNotificationDetails(
          sound.channelKey,
          'Daily reminders (${sound.label})',
          channelDescription: 'Reminds you to tick your daily tasks',
          importance: Importance.high,
          priority: Priority.high,
          ongoing: true,
          autoCancel: false,
          playSound: !sound.isSilent,
          sound: _androidSound(sound),
          audioAttributesUsage: sound.alarmVolume
              ? AudioAttributesUsage.alarm
              : AudioAttributesUsage.notification,
          actions: [
            AndroidNotificationAction(
              markDoneActionId,
              'Mark completed',
              showsUserInterface: false,
              cancelNotification: true,
            ),
            AndroidNotificationAction(
              snoozeActionId,
              'Snooze $snoozeMinutes min',
              showsUserInterface: false,
              cancelNotification: true,
            ),
          ],
        ),
        linux: LinuxNotificationDetails(
          sound: _linuxSound(sound),
          suppressSound: sound.isSilent,
          actions: [
            LinuxNotificationAction(
              key: markDoneActionId,
              label: 'Mark completed',
            ),
            LinuxNotificationAction(
              key: snoozeActionId,
              label: 'Snooze $snoozeMinutes min',
            ),
          ],
        ),
        windows: WindowsNotificationDetails(audio: _windowsAudio(sound)),
      );

  /// Plain details for one-off notifications (test notification / sound
  /// preview): same channel and sound as a real reminder, without the
  /// persistence and action buttons.
  static NotificationDetails _details(ReminderSoundChoice sound) =>
      NotificationDetails(
        android: AndroidNotificationDetails(
          sound.channelKey,
          'Daily reminders (${sound.label})',
          channelDescription: 'Reminds you to tick your daily tasks',
          importance: Importance.high,
          priority: Priority.high,
          playSound: !sound.isSilent,
          sound: _androidSound(sound),
          audioAttributesUsage: sound.alarmVolume
              ? AudioAttributesUsage.alarm
              : AudioAttributesUsage.notification,
        ),
        linux: LinuxNotificationDetails(
          sound: _linuxSound(sound),
          suppressSound: sound.isSilent,
        ),
        windows: WindowsNotificationDetails(audio: _windowsAudio(sound)),
      );

  String _bodyFor(Task task) => 'Time to tick "${task.title}" for today.';

  @override
  Future<void> showNow({
    required String title,
    required String body,
    ReminderSoundChoice sound = const ReminderSoundChoice(),
  }) async {
    await _init();
    await _plugin.show(
      id: 1, // fixed id: repeated tests replace rather than pile up
      title: title,
      body: body,
      notificationDetails: _details(sound),
    );
  }

  @override
  Future<void> sync(
    List<Task> tasks,
    DateTime now, {
    ReminderOptions options = const ReminderOptions(),
  }) async {
    final defaultTime = options.defaultTime;
    final snoozeMinutes = options.snoozeMinutes;
    final sound = options.sound;
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
      final doneToday = options.completedToday.contains(task.id);
      final baseId = stableNotificationId(task.id) * notificationSlotsPerTask;
      final payload = encodeReminderPayload(
        title: 'DayForge',
        body: _bodyFor(task),
        minutes: snoozeMinutes,
        taskId: task.id,
        sound: sound,
        target: task.targetPerDay,
      );
      // One reminder a day, or every slot of an intraday window. Either way
      // the same per-occurrence scheduling runs below.
      final times = reminderTimesFor(task, defaultTime: defaultTime);
      var slot = 0;

      for (final time in times) {
        // Windows burns a slot per day per occurrence, so it may run out
        // before the week is up; the next launch schedules the rest.
        if (slot >= notificationSlotsPerTask - 1) break;
        final firstAt = nextReminderInstant(now, time.hour, time.minute,
            doneToday: doneToday);
        // Ticked already, or the run ends before this slot comes round again.
        if (toDateKey(firstAt).compareTo(task.endDate) > 0) continue;

        if (Platform.isAndroid) {
          await _plugin.zonedSchedule(
            id: baseId + slot,
            title: 'DayForge',
            body: _bodyFor(task),
            scheduledDate: tz.TZDateTime.from(firstAt.toUtc(), tz.UTC),
            notificationDetails: reminderDetails(snoozeMinutes, sound: sound),
            payload: payload,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.time,
          );
          slot++;
        } else if (Platform.isWindows) {
          // No repeating toasts on Windows: schedule the coming week and
          // refresh on every launch/sync.
          var when = firstAt;
          for (var day = 0; day < _windowsDaysAhead; day++) {
            if (toDateKey(when).compareTo(task.endDate) > 0) break;
            if (slot >= notificationSlotsPerTask - 1) break;
            await _plugin.zonedSchedule(
              id: baseId + slot,
              title: 'DayForge',
              body: _bodyFor(task),
              scheduledDate: tz.TZDateTime.from(when.toUtc(), tz.UTC),
              notificationDetails: reminderDetails(snoozeMinutes, sound: sound),
              payload: payload,
              androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            );
            when = when.add(const Duration(days: 1));
            slot++;
          }
        } else if (Platform.isLinux) {
          _scheduleLinuxTimer(task, time.hour, time.minute, baseId + slot,
              snoozeMinutes, payload, sound,
              doneToday: doneToday);
          slot++;
        }
      }
      debugPrint(
        'reminders: armed "${task.title}" — ${times.length} time(s)/day '
        '(${task.recurrence.summary}, ids $baseId+, until ${task.endDate}, '
        'snooze ${snoozeMinutes}m${doneToday ? ', done today' : ''})',
      );
    }
  }

  /// Linux has no OS-level scheduling; fire from an in-app timer while the
  /// app is running, then re-arm for the next day.
  void _scheduleLinuxTimer(Task task, int hour, int minute, int id,
      int snoozeMinutes, String payload, ReminderSoundChoice sound,
      {bool doneToday = false}) {
    final now = DateTime.now();
    final next = nextReminderInstant(now, hour, minute, doneToday: doneToday);
    if (toDateKey(next).compareTo(task.endDate) > 0) return;
    _linuxTimers[id] = Timer(next.difference(now), () async {
      try {
        await _plugin.show(
          id: id,
          title: 'DayForge',
          body: _bodyFor(task),
          notificationDetails: reminderDetails(snoozeMinutes, sound: sound),
          payload: payload,
        );
        debugPrint('reminders: fired "${task.title}" (id $id)');
      } catch (e) {
        debugPrint('reminders: show failed for "${task.title}": $e');
      } finally {
        _scheduleLinuxTimer(
            task, hour, minute, id, snoozeMinutes, payload, sound);
      }
    });
  }
}
