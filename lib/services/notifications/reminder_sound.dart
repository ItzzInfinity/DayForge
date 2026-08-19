/// Reminder sounds the user can pick in Settings.
///
/// The bundled tones are synthesised by `tool/generate_sounds.py` into
/// `assets/sounds/<id>.ogg` (Linux) and `android/app/src/main/res/raw/<id>.ogg`
/// (Android raw resource — hence ids stay lowercase a-z). This file stays free
/// of plugin imports so settings and tests can use it; the mapping to
/// platform-specific notification details lives in LocalReminderScheduler.
library;

class ReminderSound {
  const ReminderSound({
    required this.id,
    required this.label,
    this.resource,
    this.description,
  });

  /// Persisted in `AppSettings.reminderSoundId`.
  final String id;

  final String label;

  /// Base name of the bundled tone; null for the OS default and for silent.
  final String? resource;

  final String? description;

  /// Flutter asset path used by Linux notifications.
  String? get assetPath => resource == null ? null : 'assets/sounds/$resource.ogg';

  static const systemDefault = ReminderSound(
    id: 'default',
    label: 'Default notification sound',
    description: 'Whatever this device uses for notifications',
  );
  static const chime = ReminderSound(
    id: 'chime',
    label: 'Chime',
    resource: 'chime',
    description: 'Two soft bell notes',
  );
  static const beep = ReminderSound(
    id: 'beep',
    label: 'Beep',
    resource: 'beep',
    description: 'Three short beeps',
  );
  static const bell = ReminderSound(
    id: 'bell',
    label: 'Bell',
    resource: 'bell',
    description: 'A single ringing bell',
  );
  static const alarm = ReminderSound(
    id: 'alarm',
    label: 'Alarm (loud)',
    resource: 'alarm',
    description: 'Two-tone alarm — hard to ignore',
  );
  static const buzz = ReminderSound(
    id: 'buzz',
    label: 'Urgent buzz',
    resource: 'buzz',
    description: 'Low insistent buzzing',
  );
  static const silent = ReminderSound(
    id: 'silent',
    label: 'Silent',
    description: 'Notification appears without a sound',
  );

  /// Marks "a sound picked from this device" (Android only, R4.1b). The
  /// actual sound is the URI stored in settings, not anything in this list.
  static const device = ReminderSound(
    id: 'device',
    label: 'Pick from device…',
    description: 'Choose any alarm or ringtone installed on the phone',
  );

  /// Offered in Settings, in this order.
  static const all = [
    systemDefault,
    chime,
    beep,
    bell,
    alarm,
    buzz,
    silent,
  ];

  /// Default for users who never touched the setting: the alarm tone, since
  /// reminders exist to be noticed.
  static const fallback = alarm;

  static ReminderSound byId(String? id) {
    if (id == device.id) return device;
    for (final sound in all) {
      if (sound.id == id) return sound;
    }
    return fallback;
  }
}

/// The user's full sound choice: a catalogue entry, plus the device sound it
/// points at when [ReminderSound.device] is selected.
class ReminderSoundChoice {
  const ReminderSoundChoice({
    this.sound = ReminderSound.fallback,
    this.deviceUri,
    this.deviceLabel,
    this.alarmVolume = true,
  });

  final ReminderSound sound;

  /// `content://…` URI of a sound picked from the device (Android).
  final String? deviceUri;

  /// Human-readable name of [deviceUri], for the settings tile.
  final String? deviceLabel;

  /// Play reminders on the alarm audio channel (alarm volume, audible when
  /// the ringer is down) instead of the quieter notification channel.
  final bool alarmVolume;

  /// A device pick only counts once we actually hold a URI for it.
  bool get usesDeviceSound =>
      sound.id == ReminderSound.device.id && deviceUri != null;

  bool get isSilent => sound.id == ReminderSound.silent.id;

  String get label => usesDeviceSound
      ? (deviceLabel ?? 'Sound from this device')
      : sound.label;

  /// Android notification channels are immutable once created, so a changed
  /// sound needs a *new* channel id. This key identifies the (sound, volume)
  /// pair; bump `v1` if the tones themselves are ever regenerated.
  String get channelKey {
    final base = usesDeviceSound
        ? 'device_${_stableHash(deviceUri!)}'
        : sound.id;
    return 'reminders_v1_$base${alarmVolume ? '_alarm' : ''}';
  }

  ReminderSoundChoice copyWith({
    ReminderSound? sound,
    String? Function()? deviceUri,
    String? Function()? deviceLabel,
    bool? alarmVolume,
  }) =>
      ReminderSoundChoice(
        sound: sound ?? this.sound,
        deviceUri: deviceUri != null ? deviceUri() : this.deviceUri,
        deviceLabel: deviceLabel != null ? deviceLabel() : this.deviceLabel,
        alarmVolume: alarmVolume ?? this.alarmVolume,
      );
}

/// FNV-1a — String.hashCode is not stable across runs, and this value ends up
/// in a persisted Android channel id.
String _stableHash(String value) {
  var hash = 0x811c9dc5;
  for (final unit in value.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash.toRadixString(16);
}
