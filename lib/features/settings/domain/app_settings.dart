import '../../../services/notifications/reminder_scheduler.dart'
    as notifications;
import '../../../services/notifications/reminder_sound.dart';

/// Firestore doc: `users/{uid}/settings/app` (docs/data-model.md).
/// Constructor defaults double as the values for users who never touched
/// the settings screen.
class AppSettings {
  const AppSettings({
    this.defaultDurationDays = 21,
    this.defaultReminderTime = notifications.defaultReminderTime,
    this.notificationsEnabled = true,
    this.snoozeMinutes = 10,
    this.reminderSoundId = 'alarm',
    this.deviceSoundUri,
    this.deviceSoundLabel,
    this.alarmVolume = true,
    this.themeMode = 'system',
  });

  final int defaultDurationDays;

  /// `HH:mm`; used when a task has no reminderTime of its own.
  final String defaultReminderTime;

  final bool notificationsEnabled;

  /// How long the reminder notification's Snooze button postpones it.
  final int snoozeMinutes;

  /// Id from [ReminderSound] ('alarm', 'chime', …, or 'device').
  final String reminderSoundId;

  /// `content://…` sound picked from the phone; only used when
  /// [reminderSoundId] is `device`.
  final String? deviceSoundUri;

  /// Display name of [deviceSoundUri].
  final String? deviceSoundLabel;

  /// Play reminders at alarm volume rather than notification volume.
  final bool alarmVolume;

  /// `system` / `light` / `dark`.
  final String themeMode;

  /// The sound settings the scheduler needs, in one object.
  ReminderSoundChoice get soundChoice => ReminderSoundChoice(
        sound: ReminderSound.byId(reminderSoundId),
        deviceUri: deviceSoundUri,
        deviceLabel: deviceSoundLabel,
        alarmVolume: alarmVolume,
      );

  Map<String, dynamic> toMap() => {
        'defaultDurationDays': defaultDurationDays,
        'defaultReminderTime': defaultReminderTime,
        'notificationsEnabled': notificationsEnabled,
        'snoozeMinutes': snoozeMinutes,
        'reminderSoundId': reminderSoundId,
        'deviceSoundUri': deviceSoundUri,
        'deviceSoundLabel': deviceSoundLabel,
        'alarmVolume': alarmVolume,
        'themeMode': themeMode,
      };

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    const defaults = AppSettings();
    return AppSettings(
      defaultDurationDays:
          map['defaultDurationDays'] as int? ?? defaults.defaultDurationDays,
      defaultReminderTime: map['defaultReminderTime'] as String? ??
          defaults.defaultReminderTime,
      notificationsEnabled: map['notificationsEnabled'] as bool? ??
          defaults.notificationsEnabled,
      snoozeMinutes: map['snoozeMinutes'] as int? ?? defaults.snoozeMinutes,
      reminderSoundId:
          map['reminderSoundId'] as String? ?? defaults.reminderSoundId,
      deviceSoundUri: map['deviceSoundUri'] as String?,
      deviceSoundLabel: map['deviceSoundLabel'] as String?,
      alarmVolume: map['alarmVolume'] as bool? ?? defaults.alarmVolume,
      themeMode: map['themeMode'] as String? ?? defaults.themeMode,
    );
  }

  AppSettings copyWith({
    int? defaultDurationDays,
    String? defaultReminderTime,
    bool? notificationsEnabled,
    int? snoozeMinutes,
    String? reminderSoundId,
    String? Function()? deviceSoundUri,
    String? Function()? deviceSoundLabel,
    bool? alarmVolume,
    String? themeMode,
  }) {
    return AppSettings(
      defaultDurationDays: defaultDurationDays ?? this.defaultDurationDays,
      defaultReminderTime: defaultReminderTime ?? this.defaultReminderTime,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
      reminderSoundId: reminderSoundId ?? this.reminderSoundId,
      deviceSoundUri:
          deviceSoundUri != null ? deviceSoundUri() : this.deviceSoundUri,
      deviceSoundLabel: deviceSoundLabel != null
          ? deviceSoundLabel()
          : this.deviceSoundLabel,
      alarmVolume: alarmVolume ?? this.alarmVolume,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}
