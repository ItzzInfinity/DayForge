import 'package:advanced_todo/services/notifications/reminder_scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReminderSound catalogue', () {
    test('every bundled tone maps to an asset and a raw-resource-safe id', () {
      for (final sound in ReminderSound.all) {
        expect(RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(sound.id), isTrue,
            reason: '${sound.id} must be a valid Android raw resource name');
        if (sound.resource != null) {
          expect(sound.assetPath, 'assets/sounds/${sound.resource}.ogg');
        }
      }
    });

    test('unknown or missing ids fall back to the alarm tone', () {
      expect(ReminderSound.byId(null).id, ReminderSound.alarm.id);
      expect(ReminderSound.byId('nope').id, ReminderSound.alarm.id);
      expect(ReminderSound.byId('chime').id, ReminderSound.chime.id);
      expect(ReminderSound.byId('device').id, ReminderSound.device.id);
    });
  });

  group('ReminderSoundChoice', () {
    test('channel key changes with the sound and with alarm volume', () {
      const chime = ReminderSoundChoice(sound: ReminderSound.chime);
      const bell = ReminderSoundChoice(sound: ReminderSound.bell);
      const quietChime =
          ReminderSoundChoice(sound: ReminderSound.chime, alarmVolume: false);

      // Android channels are immutable, so a different sound or audio usage
      // must land on a different channel or the old sound sticks forever.
      expect(chime.channelKey, isNot(bell.channelKey));
      expect(chime.channelKey, isNot(quietChime.channelKey));
      expect(chime.channelKey, const ReminderSoundChoice(
        sound: ReminderSound.chime,
      ).channelKey);
    });

    test('a device pick needs a URI before it counts as one', () {
      const noUri = ReminderSoundChoice(sound: ReminderSound.device);
      const picked = ReminderSoundChoice(
        sound: ReminderSound.device,
        deviceUri: 'content://media/alarm/7',
        deviceLabel: 'Oxygen',
      );

      expect(noUri.usesDeviceSound, isFalse);
      expect(picked.usesDeviceSound, isTrue);
      expect(picked.label, 'Oxygen');
      expect(picked.channelKey, isNot(noUri.channelKey));
    });
  });

  group('reminder payload', () {
    test('carries the sound choice into the background isolate', () {
      final payload = encodeReminderPayload(
        title: 'DayForge',
        body: 'Tick it',
        minutes: 10,
        taskId: 't1',
        sound: const ReminderSoundChoice(
          sound: ReminderSound.device,
          deviceUri: 'content://media/alarm/7',
          deviceLabel: 'Oxygen',
          alarmVolume: false,
        ),
      );

      final decoded = decodeReminderPayload(payload)!;
      expect(decoded.taskId, 't1');
      expect(decoded.sound.usesDeviceSound, isTrue);
      expect(decoded.sound.deviceUri, 'content://media/alarm/7');
      expect(decoded.sound.alarmVolume, isFalse);
    });

    test('payloads written before sounds shipped still decode', () {
      const legacy =
          '{"title":"DayForge","body":"Tick it","minutes":10,"taskId":"t1"}';

      final decoded = decodeReminderPayload(legacy)!;
      expect(decoded.minutes, 10);
      expect(decoded.sound.sound.id, ReminderSound.alarm.id);
    });
  });
}
