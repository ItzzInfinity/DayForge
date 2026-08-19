import 'package:advanced_todo/features/daily/domain/daily_log.dart';
import 'package:advanced_todo/features/tasks/domain/recurrence.dart';
import 'package:advanced_todo/features/tasks/domain/task.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Recurrence', () {
    test('an intraday window expands to one reminder per interval', () {
      const water = Recurrence.intraday(
        startTime: '08:00',
        endTime: '20:00',
        intervalMinutes: 90,
      );

      // 08:00 … 20:00 inclusive, every 90 minutes.
      expect(water.occurrencesPerDay, 9);
      expect(water.occurrenceMinutes.first, 8 * 60);
      expect(water.occurrenceMinutes.last, 20 * 60);
      // No explicit goal ⇒ the majority rule: more than half of 9 is 5.
      expect(water.targetPerDay, 5);
      expect(water.usesMajorityRule, isTrue);
      // The counter still holds all nine, though.
      expect(water.maxPerDay, 9);
    });

    test('the last reminder never overshoots the window', () {
      const r = Recurrence.intraday(
        startTime: '09:00',
        endTime: '10:00',
        intervalMinutes: 45,
      );

      expect(r.occurrenceMinutes, [9 * 60, 9 * 60 + 45]);
    });

    test('target is clamped into 1..occurrences', () {
      Recurrence withTarget(int? target) => Recurrence.intraday(
            startTime: '08:00',
            endTime: '12:00',
            intervalMinutes: 60, // 5 occurrences
            targetPerDay: target,
          );

      expect(withTarget(3).targetPerDay, 3);
      expect(withTarget(5).targetPerDay, 5);
      // Over the top clamps down; an explicit goal is never the majority.
      expect(withTarget(99).targetPerDay, 5);
      expect(withTarget(99).usesMajorityRule, isFalse);
      // Absent or nonsensical ⇒ the majority rule: more than half of 5 is 3.
      expect(withTarget(0).targetPerDay, 3);
      expect(withTarget(null).targetPerDay, 3);
      expect(withTarget(null).usesMajorityRule, isTrue);
    });

    test('the majority rule is a strict majority at every size', () {
      // Never an exact half: 2 of 4 is not "more than 50%".
      expect(Recurrence.majorityTarget(1), 1);
      expect(Recurrence.majorityTarget(2), 2);
      expect(Recurrence.majorityTarget(3), 2);
      expect(Recurrence.majorityTarget(4), 3);
      expect(Recurrence.majorityTarget(8), 5);
      expect(Recurrence.majorityTarget(9), 5);
      expect(Recurrence.majorityTarget(48), 25);
      // Degenerate input still asks for one tick rather than zero.
      expect(Recurrence.majorityTarget(0), 1);
    });

    test('an interval can be derived from a repetition count', () {
      int occurrencesFor(int reps, {int windowMinutes = 720}) {
        final step = Recurrence.intervalForOccurrences(
          windowMinutes: windowMinutes,
          occurrences: reps,
        );
        return Recurrence.intraday(
          startTime: '08:00',
          endTime: '20:00',
          intervalMinutes: step,
        ).occurrencesPerDay;
      }

      // 08:00–20:00 is 720 minutes; asking for N lands exactly N.
      for (final reps in [1, 2, 3, 4, 5, 7, 9, 13, 25]) {
        expect(occurrencesFor(reps), reps, reason: 'asked for \$reps a day');
      }

      // A short window is where floor division overshoots, so check the
      // widening loop actually holds the count down.
      for (final reps in [1, 2, 3, 4]) {
        final step = Recurrence.intervalForOccurrences(
          windowMinutes: 5,
          occurrences: reps,
        );
        final actual = Recurrence.intraday(
          startTime: '09:00',
          endTime: '09:05',
          intervalMinutes: step,
        ).occurrencesPerDay;
        expect(actual, lessThanOrEqualTo(reps),
            reason: 'asked for \$reps in a 5-minute window, got \$actual');
      }
    });

    test('a window that ends before it starts still reminds once', () {
      const r = Recurrence.intraday(
        startTime: '20:00',
        endTime: '08:00',
        intervalMinutes: 60,
      );

      expect(r.occurrenceMinutes, [20 * 60]);
      expect(r.targetPerDay, 1);
    });


    test('a very tight window is capped so the tray is not flooded', () {
      const r = Recurrence.intraday(
        startTime: '00:00',
        endTime: '23:59',
        intervalMinutes: 15,
      );

      expect(r.occurrencesPerDay, Recurrence.maxOccurrencesPerDay);
    });

    test('daily is the default and writes no field', () {
      const daily = Recurrence.daily();

      expect(daily.isIntraday, isFalse);
      expect(daily.targetPerDay, 1);
      expect(daily.toMap(), isNull);
      expect(daily.summary, 'Once a day');
    });

    test('round-trips through a map', () {
      const original = Recurrence.intraday(
        startTime: '07:30',
        endTime: '21:30',
        intervalMinutes: 120,
        targetPerDay: 5,
      );

      final restored = Recurrence.fromMap(original.toMap());
      expect(restored.isIntraday, isTrue);
      expect(restored.startTime, '07:30');
      expect(restored.endTime, '21:30');
      expect(restored.intervalMinutes, 120);
      expect(restored.targetPerDay, 5);
      // 07:30–21:30 every 2h is 8 reminders; an explicit 5 reads as a
      // fraction of them, with no "(over half)" note because it was chosen.
      expect(restored.summary, 'Every 2 hours, 07:30–21:30 · 5 of 8 a day');
    });
  });

  group('Task with recurrence', () {
    Task task({Recurrence? recurrence}) => Task(
          id: 't1',
          title: 'Drink water',
          startDate: '2026-08-17',
          durationDays: 21,
          recurrence: recurrence ?? const Recurrence.daily(),
          createdAt: DateTime.utc(2026, 8, 17),
          updatedAt: DateTime.utc(2026, 8, 17),
        );

    test('tasks written before intraday support read back as daily', () {
      final legacy = Task.fromMap('t1', {
        'title': 'Meditate',
        'startDate': '2026-08-01',
        'durationDays': 21,
        'status': 'active',
        'createdAt': DateTime.utc(2026, 8, 1),
        'updatedAt': DateTime.utc(2026, 8, 1),
      });

      expect(legacy.recurrence.isIntraday, isFalse);
      expect(legacy.targetPerDay, 1);
    });

    test('an intraday task survives a Firestore round-trip', () {
      final original = task(
        recurrence: const Recurrence.intraday(
          startTime: '08:00',
          endTime: '20:00',
          intervalMinutes: 90,
          targetPerDay: 8,
        ),
      );

      final restored = Task.fromMap('t1', original.toMap());
      expect(restored.recurrence.isIntraday, isTrue);
      expect(restored.targetPerDay, 8);
    });
  });

  group('DailyLog count', () {
    test('logs written before counts existed treat a tick as one', () {
      final legacy = DailyLog.fromMap('2026-08-17', {
        'date': '2026-08-17',
        'completed': true,
        'updatedAt': DateTime.utc(2026, 8, 17),
      });

      expect(legacy.count, 1);
      expect(
        DailyLog.fromMap('2026-08-17', {
          'completed': false,
          'updatedAt': DateTime.utc(2026, 8, 17),
        }).count,
        0,
      );
    });

    test('count survives a round-trip', () {
      final log = DailyLog(
        date: '2026-08-17',
        completed: false,
        count: 3,
        updatedAt: DateTime.utc(2026, 8, 17),
      );

      final restored = DailyLog.fromMap('2026-08-17', log.toMap());
      expect(restored.count, 3);
      expect(restored.completed, isFalse);
    });
  });
}
