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
      // No explicit goal ⇒ every nudge counts.
      expect(water.targetPerDay, 9);
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
      expect(withTarget(99).targetPerDay, 5);
      expect(withTarget(0).targetPerDay, 5);
      expect(withTarget(null).targetPerDay, 5);
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
      expect(restored.summary, 'Every 2 hours, 07:30–21:30 · 5× a day');
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
