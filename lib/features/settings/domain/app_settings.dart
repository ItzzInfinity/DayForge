import '../../../services/notifications/reminder_scheduler.dart'
    as notifications;

/// Firestore doc: `users/{uid}/settings/app` (docs/data-model.md).
/// Constructor defaults double as the values for users who never touched
/// the settings screen.
class AppSettings {
  const AppSettings({
    this.defaultDurationDays = 21,
    this.defaultReminderTime = notifications.defaultReminderTime,
    this.notificationsEnabled = true,
    this.snoozeMinutes = 10,
    this.themeMode = 'system',
  });

  final int defaultDurationDays;

  /// `HH:mm`; used when a task has no reminderTime of its own.
  final String defaultReminderTime;

  final bool notificationsEnabled;

  /// How long the reminder notification's Snooze button postpones it.
  final int snoozeMinutes;

  /// `system` / `light` / `dark`.
  final String themeMode;

  Map<String, dynamic> toMap() => {
        'defaultDurationDays': defaultDurationDays,
        'defaultReminderTime': defaultReminderTime,
        'notificationsEnabled': notificationsEnabled,
        'snoozeMinutes': snoozeMinutes,
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
      themeMode: map['themeMode'] as String? ?? defaults.themeMode,
    );
  }

  AppSettings copyWith({
    int? defaultDurationDays,
    String? defaultReminderTime,
    bool? notificationsEnabled,
    int? snoozeMinutes,
    String? themeMode,
  }) {
    return AppSettings(
      defaultDurationDays: defaultDurationDays ?? this.defaultDurationDays,
      defaultReminderTime: defaultReminderTime ?? this.defaultReminderTime,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}
