import 'package:flutter_test/flutter_test.dart';

import 'package:advanced_todo/features/daily/domain/daily_log.dart';
import 'package:advanced_todo/features/progress/domain/progress_calculator.dart';
import 'package:advanced_todo/features/tasks/domain/task.dart';

Task makeTask({String startDate = '2026-07-01', int durationDays = 21}) {
  return Task(
    id: 't1',
    title: 'Meditate',
    startDate: startDate,
    durationDays: durationDays,
    createdAt: DateTime.utc(2026, 7, 1),
    updatedAt: DateTime.utc(2026, 7, 1),
  );
}

DailyLog log(String date, {bool completed = true}) => DailyLog(
      date: date,
      completed: completed,
      updatedAt: DateTime.utc(2026, 7, 1),
    );

void main() {
  final today = DateTime(2026, 7, 13);

  test('no logs: zero streak, zero completion, correct elapsed', () {
    final p = calculateProgress(task: makeTask(), logs: [], today: today);
    expect(p.currentStreak, 0);
    expect(p.completedDays, 0);
    expect(p.elapsedDays, 13); // Jul 1..13 inclusive
    expect(p.completionPercent, 0);
  });

  test('streak of consecutive days ending today', () {
    final p = calculateProgress(
      task: makeTask(),
      logs: [log('2026-07-11'), log('2026-07-12'), log('2026-07-13')],
      today: today,
    );
    expect(p.currentStreak, 3);
    expect(p.completedDays, 3);
  });

  test('unticked today keeps a streak ending yesterday', () {
    final p = calculateProgress(
      task: makeTask(),
      logs: [log('2026-07-11'), log('2026-07-12')],
      today: today,
    );
    expect(p.currentStreak, 2);
  });

  test('a gap breaks the streak', () {
    final p = calculateProgress(
      task: makeTask(),
      logs: [log('2026-07-09'), log('2026-07-10'), log('2026-07-12')],
      today: today,
    );
    // Yesterday (Jul 12) is completed, but the Jul 11 gap cuts the run to 1.
    expect(p.currentStreak, 1);
    expect(p.completedDays, 3);

    // With neither today nor yesterday completed, the streak is 0.
    final stale = calculateProgress(
      task: makeTask(),
      logs: [log('2026-07-09'), log('2026-07-10')],
      today: today,
    );
    expect(stale.currentStreak, 0);
  });

  test('incomplete logs (remark-only days) do not count', () {
    final p = calculateProgress(
      task: makeTask(),
      logs: [log('2026-07-12', completed: false), log('2026-07-13')],
      today: today,
    );
    expect(p.currentStreak, 1);
    expect(p.completedDays, 1);
  });

  test('completion percent uses elapsed days, not full duration', () {
    final p = calculateProgress(
      task: makeTask(startDate: '2026-07-10', durationDays: 21),
      logs: [log('2026-07-10'), log('2026-07-11')],
      today: today,
    );
    expect(p.elapsedDays, 4); // Jul 10..13
    expect(p.completionPercent, closeTo(0.5, 0.001));
  });

  test('ended task caps the window at its end date', () {
    final p = calculateProgress(
      task: makeTask(startDate: '2026-07-01', durationDays: 5), // ends Jul 5
      logs: [for (var d = 1; d <= 5; d++) log('2026-07-0$d')],
      today: today,
    );
    expect(p.elapsedDays, 5);
    expect(p.completionPercent, 1.0);
  });

  test('future task has zero elapsed days', () {
    final p = calculateProgress(
      task: makeTask(startDate: '2026-08-01'),
      logs: [],
      today: today,
    );
    expect(p.elapsedDays, 0);
    expect(p.completionPercent, 0);
  });

  test('task started today with a tick: 1/1 and streak 1', () {
    final p = calculateProgress(
      task: makeTask(startDate: '2026-07-13'),
      logs: [log('2026-07-13')],
      today: today,
    );
    expect(p.elapsedDays, 1);
    expect(p.completionPercent, 1.0);
    expect(p.currentStreak, 1);
  });
}
