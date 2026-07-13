import 'package:flutter_test/flutter_test.dart';

import 'package:advanced_todo/services/notifications/reminder_scheduler.dart';

void main() {
  group('parseHhMm', () {
    test('parses hours and minutes', () {
      expect(parseHhMm('08:00'), (hour: 8, minute: 0));
      expect(parseHhMm('21:45'), (hour: 21, minute: 45));
    });
  });

  group('stableNotificationId', () {
    test('is deterministic and fits with room for sub-ids', () {
      final a1 = stableNotificationId('task-abc');
      final a2 = stableNotificationId('task-abc');
      final b = stableNotificationId('task-xyz');
      expect(a1, a2);
      expect(a1, isNot(b));
      expect(a1 * 10 + 9, lessThan(0x7FFFFFFF));
    });
  });

  group('reminder payload', () {
    test('round-trips title, body, minutes and taskId', () {
      final encoded = encodeReminderPayload(
          title: 'Advanced To-Do',
          body: 'Tick "Read" today.',
          minutes: 15,
          taskId: 't1');
      final decoded = decodeReminderPayload(encoded);
      expect(decoded, isNotNull);
      expect(decoded!.title, 'Advanced To-Do');
      expect(decoded.body, 'Tick "Read" today.');
      expect(decoded.minutes, 15);
      expect(decoded.taskId, 't1');
    });

    test('rejects null, empty and malformed payloads', () {
      expect(decodeReminderPayload(null), isNull);
      expect(decodeReminderPayload(''), isNull);
      expect(decodeReminderPayload('not json'), isNull);
      expect(decodeReminderPayload('{"title":"x"}'), isNull);
    });
  });

  group('snoozeNotificationId', () {
    test('maps any fired id to the task\'s reserved +9 slot', () {
      // Base reminder (Android/Linux) and Windows day offsets all land on
      // the same slot, so repeated snoozes replace rather than pile up.
      expect(snoozeNotificationId(420), 429);
      expect(snoozeNotificationId(426), 429);
      expect(snoozeNotificationId(429), 429);
    });
  });

  group('nextOccurrence', () {
    test('same day when the time is still ahead', () {
      final now = DateTime(2026, 7, 13, 6, 30);
      expect(nextOccurrence(now, 8, 0), DateTime(2026, 7, 13, 8, 0));
    });

    test('next day when the time already passed', () {
      final now = DateTime(2026, 7, 13, 9, 0);
      expect(nextOccurrence(now, 8, 0), DateTime(2026, 7, 14, 8, 0));
    });

    test('exactly now rolls to tomorrow', () {
      final now = DateTime(2026, 7, 13, 8, 0);
      expect(nextOccurrence(now, 8, 0), DateTime(2026, 7, 14, 8, 0));
    });
  });
}
