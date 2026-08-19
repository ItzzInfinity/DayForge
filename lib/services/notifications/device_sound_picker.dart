import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/services.dart';

/// Opens the platform's own sound picker so a reminder can use a ringtone
/// already installed on the device. Android only — the desktop notification
/// servers have no equivalent chooser, so [isSupported] is false there and
/// Settings hides the option.
abstract interface class DeviceSoundPicker {
  bool get isSupported;

  /// Returns the picked sound, or null if the user cancelled (or chose the
  /// picker's own "Silent" entry — DayForge models silence as its own
  /// setting, so that is treated as a cancel).
  Future<({String uri, String label})?> pick({String? currentUri});
}

class MethodChannelDeviceSoundPicker implements DeviceSoundPicker {
  const MethodChannelDeviceSoundPicker();

  static const _channel = MethodChannel('dayforge/sound_picker');

  @override
  bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<({String uri, String label})?> pick({String? currentUri}) async {
    if (!isSupported) return null;
    final picked = await _channel.invokeMapMethod<String, dynamic>(
      'pickSound',
      {'currentUri': currentUri},
    );
    final uri = picked?['uri'] as String?;
    if (uri == null) return null;
    return (uri: uri, label: picked?['label'] as String? ?? 'Device sound');
  }
}
