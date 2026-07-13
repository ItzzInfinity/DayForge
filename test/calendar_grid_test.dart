import 'package:flutter_test/flutter_test.dart';

import 'package:advanced_todo/features/progress/domain/calendar_grid.dart';
import 'package:advanced_todo/features/tasks/domain/task.dart';

void main() {
  final task = Task(
    id: 't1',
    title: 'x',
    startDate: '2026-07-10',
    durationDays: 10, // ends 2026-07-19
    createdAt: DateTime.utc(2026, 7, 1),
    updatedAt: DateTime.utc(2026, 7, 1),
  );

  group('dayStatus', () {
    DayStatus statusOf(String key, {Set<String> done = const {}}) => dayStatus(
        dateKey: key, task: task, completedDates: done, todayKey: '2026-07-13');

    test('covers all branches', () {
      expect(statusOf('2026-07-09'), DayStatus.outOfRange); // before start
      expect(statusOf('2026-07-20'), DayStatus.outOfRange); // after end
      expect(statusOf('2026-07-11', done: {'2026-07-11'}), DayStatus.completed);
      expect(statusOf('2026-07-11'), DayStatus.missed); // past, unticked
      expect(statusOf('2026-07-13'), DayStatus.pending); // today, unticked
      expect(statusOf('2026-07-13', done: {'2026-07-13'}), DayStatus.completed);
      expect(statusOf('2026-07-15'), DayStatus.future);
    });
  });

  group('monthsInRange', () {
    test('single month', () {
      expect(monthsInRange('2026-07-10', '2026-07-19'),
          [(year: 2026, month: 7)]);
    });

    test('spans months and a year boundary', () {
      expect(monthsInRange('2026-11-20', '2027-01-05'), [
        (year: 2026, month: 11),
        (year: 2026, month: 12),
        (year: 2027, month: 1),
      ]);
    });
  });

  group('monthCells', () {
    test('pads to the weekday of the 1st (Monday-first)', () {
      // 2026-07-01 is a Wednesday → 2 leading nulls.
      final cells = monthCells(2026, 7);
      expect(cells.take(2), everyElement(isNull));
      expect(cells[2], DateTime.utc(2026, 7, 1));
      expect(cells.length, 2 + 31);
      expect(cells.last, DateTime.utc(2026, 7, 31));
    });

    test('no padding when the month starts on Monday', () {
      // 2026-06-01 is a Monday.
      final cells = monthCells(2026, 6);
      expect(cells.first, DateTime.utc(2026, 6, 1));
      expect(cells.length, 30);
    });
  });
}
