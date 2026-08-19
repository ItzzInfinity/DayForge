import 'package:advanced_todo/features/daily/data/daily_log_repository.dart';
import 'package:advanced_todo/features/tasks/data/rollover_service.dart';
import 'package:advanced_todo/features/tasks/data/task_repository.dart';
import 'package:advanced_todo/features/tasks/domain/rollover.dart';
import 'package:advanced_todo/features/tasks/domain/task.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fakes.dart';

Task buildTask({
  CompletionMode mode = CompletionMode.targetDays,
  int durationDays = 3,
  int? targetDays,
  String startDate = '2026-08-17',
  TaskStatus status = TaskStatus.active,
}) =>
    Task(
      id: 't1',
      title: 'Meditate',
      startDate: startDate,
      durationDays: durationDays,
      completionMode: mode,
      // Real tasks pin the goal at creation (TaskRepository.create does it).
      targetDays: targetDays ?? durationDays,
      status: status,
      createdAt: DateTime.utc(2026, 8, 17),
      updatedAt: DateTime.utc(2026, 8, 17),
    );

void main() {
  group('rolloverDurationDays', () {
    test('a fixed-window task never moves', () {
      expect(
        rolloverDurationDays(
          task: buildTask(mode: CompletionMode.fixedWindow),
          completedDays: 0,
          todayKey: '2026-08-25',
        ),
        isNull,
      );
    });

    test('on track: nothing changes', () {
      // Day 2 of 3, one day already done ⇒ two days left, two still needed.
      expect(
        rolloverDurationDays(
          task: buildTask(),
          completedDays: 1,
          todayKey: '2026-08-18',
        ),
        isNull,
      );
    });

    test('a missed day pushes the end date out by exactly one day', () {
      // Day 2 of 3 with nothing completed: 3 days still needed, and only
      // today + tomorrow remain ⇒ the run must reach 2026-08-20 (4 days).
      expect(
        rolloverDurationDays(
          task: buildTask(),
          completedDays: 0,
          todayKey: '2026-08-18',
        ),
        4,
      );
    });

    test('is idempotent — re-running the same day changes nothing', () {
      // The state left behind by the previous test: extended to 4 days,
      // still aiming for 3 completions.
      final task = buildTask(durationDays: 4, targetDays: 3);

      expect(
        rolloverDurationDays(
          task: task,
          completedDays: 0,
          todayKey: '2026-08-18',
        ),
        isNull,
      );
    });

    test('a long gap rolls forward once, not per missed day', () {
      // Nothing done and today is well past the original window: three days
      // are still needed, so the run ends two days from today.
      expect(
        rolloverDurationDays(
          task: buildTask(),
          completedDays: 0,
          todayKey: '2026-09-01',
        ),
        // 2026-08-17 → 2026-09-03 inclusive.
        18,
      );
    });

    test('target reached: the task stops extending', () {
      expect(
        rolloverDurationDays(
          task: buildTask(),
          completedDays: 3,
          todayKey: '2026-09-01',
        ),
        isNull,
      );
    });

    test('archived and not-yet-started tasks are left alone', () {
      expect(
        rolloverDurationDays(
          task: buildTask(status: TaskStatus.archived),
          completedDays: 0,
          todayKey: '2026-09-01',
        ),
        isNull,
      );
      expect(
        rolloverDurationDays(
          task: buildTask(startDate: '2026-09-01'),
          completedDays: 0,
          todayKey: '2026-08-18',
        ),
        isNull,
      );
    });
  });

  group('applyRollovers', () {
    test('rewrites only the tasks that fell behind', () async {
      final gateway = FakeFirestoreGateway();
      final taskRepo = TaskRepository(gateway, 'u');
      final logRepo = DailyLogRepository(gateway, 'u');
      final behind = buildTask();
      final fixed = Task(
        id: 't2',
        title: 'Read',
        startDate: '2026-08-17',
        durationDays: 3,
        createdAt: DateTime.utc(2026, 8, 17),
        updatedAt: DateTime.utc(2026, 8, 17),
      );
      gateway.docs['users/u/tasks/t1'] = behind.toMap();
      gateway.docs['users/u/tasks/t2'] = fixed.toMap();

      final rolled = await applyRollovers(
        tasks: [behind, fixed],
        taskRepository: taskRepo,
        dailyLogRepository: logRepo,
        now: DateTime(2026, 8, 18),
      );

      expect(rolled.map((t) => t.id), ['t1']);
      expect(gateway.docs['users/u/tasks/t1']!['durationDays'], 4);
      expect(gateway.docs['users/u/tasks/t2']!['durationDays'], 3);
    });

    test('counts completed logs, so a caught-up task is left alone', () async {
      final gateway = FakeFirestoreGateway();
      final task = buildTask();
      gateway.docs['users/u/tasks/t1'] = task.toMap();
      gateway.docs['users/u/tasks/t1/daily_logs/2026-08-17'] = {
        'date': '2026-08-17',
        'completed': true,
        'updatedAt': DateTime.utc(2026, 8, 17),
      };

      final rolled = await applyRollovers(
        tasks: [task],
        taskRepository: TaskRepository(gateway, 'u'),
        dailyLogRepository: DailyLogRepository(gateway, 'u'),
        now: DateTime(2026, 8, 18),
      );

      expect(rolled, isEmpty);
      expect(gateway.docs['users/u/tasks/t1']!['durationDays'], 3);
    });
  });
}
