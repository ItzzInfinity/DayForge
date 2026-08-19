import 'package:advanced_todo/features/tasks/domain/recurrence.dart';
import 'package:advanced_todo/features/tasks/domain/task.dart';
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
      expect(a1 * notificationSlotsPerTask + notificationSlotsPerTask - 1,
          lessThan(0x7FFFFFFF));
    });
  });

  group('reminder payload', () {
    test('round-trips title, body, minutes and taskId', () {
      final encoded = encodeReminderPayload(
          title: 'DayForge',
          body: 'Tick "Read" today.',
          minutes: 15,
          taskId: 't1');
      final decoded = decodeReminderPayload(encoded);
      expect(decoded, isNotNull);
      expect(decoded!.title, 'DayForge');
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
    test('maps any fired id to the task\'s last reserved slot', () {
      // Every occurrence of a task (intraday slots, Windows day offsets)
      // lands on the same snooze slot, so repeated snoozes replace rather
      // than pile up — and never collide with another task's ids.
      expect(snoozeNotificationId(64 * 7), 64 * 7 + 63);
      expect(snoozeNotificationId(64 * 7 + 5), 64 * 7 + 63);
      expect(snoozeNotificationId(64 * 7 + 63), 64 * 7 + 63);
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

  group('nextReminderInstant', () {
    test('a task not yet done today fires at today\'s remaining time', () {
      final now = DateTime(2026, 8, 17, 7, 0);

      expect(nextReminderInstant(now, 20, 0),
          DateTime(2026, 8, 17, 20, 0));
    });

    test('ticking early skips today and rings again tomorrow', () {
      final now = DateTime(2026, 8, 17, 7, 0);

      expect(nextReminderInstant(now, 20, 0, doneToday: true),
          DateTime(2026, 8, 18, 20, 0));
    });

    test('after the time has passed, the next slot is tomorrow either way', () {
      final now = DateTime(2026, 8, 17, 21, 0);

      expect(nextReminderInstant(now, 20, 0), DateTime(2026, 8, 18, 20, 0));
      expect(nextReminderInstant(now, 20, 0, doneToday: true),
          DateTime(2026, 8, 18, 20, 0));
    });
  });

  group('reminderTimesFor', () {
    Task task({String? reminderTime, Recurrence? recurrence}) => Task(
          id: 't1',
          title: 'Drink water',
          startDate: '2026-08-17',
          durationDays: 21,
          reminderTime: reminderTime,
          recurrence: recurrence ?? const Recurrence.daily(),
          createdAt: DateTime.utc(2026, 8, 17),
          updatedAt: DateTime.utc(2026, 8, 17),
        );

    test('a daily task reminds once, at its time or the default', () {
      expect(reminderTimesFor(task(reminderTime: '06:45')),
          [(hour: 6, minute: 45)]);
      expect(reminderTimesFor(task(), defaultTime: '09:15'),
          [(hour: 9, minute: 15)]);
    });

    test('an intraday task reminds at every slot in its window', () {
      final times = reminderTimesFor(task(
        recurrence: const Recurrence.intraday(
          startTime: '08:00',
          endTime: '11:00',
          intervalMinutes: 90,
        ),
      ));

      expect(times, [
        (hour: 8, minute: 0),
        (hour: 9, minute: 30),
        (hour: 11, minute: 0),
      ]);
    });
  });
}
