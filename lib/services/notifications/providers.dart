import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'device_sound_picker.dart';
import 'local_reminder_scheduler.dart';
import 'reminder_scheduler.dart';

final reminderSchedulerProvider =
    Provider<ReminderScheduler>((ref) => LocalReminderScheduler());

/// System ringtone picker (Android); reports unsupported elsewhere.
final deviceSoundPickerProvider = Provider<DeviceSoundPicker>(
    (ref) => const MethodChannelDeviceSoundPicker());
