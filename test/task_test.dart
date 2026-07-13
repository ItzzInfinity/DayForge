import 'package:flutter_test/flutter_test.dart';

import 'package:advanced_todo/core/utils/date_utils.dart';
import 'package:advanced_todo/features/tasks/data/task_repository.dart';
import 'package:advanced_todo/features/tasks/domain/task.dart';

import 'helpers/fakes.dart';

void main() {
  group('date utils', () {
    test('round-trips and does day arithmetic on keys', () {
      expect(toDateKey(DateTime(2026, 7, 13)), '2026-07-13');
      expect(fromDateKey('2026-07-13'), DateTime.utc(2026, 7, 13));
      expect(addDaysToKey('2026-07-13', 20), '2026-08-02');
      expect(addDaysToKey('2026-12-31', 1), '2027-01-01');
    });
  });

  group('Task model', () {
    final task = Task(
      id: 't1',
      title: 'Drink water',
      startDate: '2026-07-13',
      durationDays: 21,
      createdAt: DateTime.utc(2026, 7, 13, 8),
      updatedAt: DateTime.utc(2026, 7, 13, 8),
    );

    test('endDate covers durationDays inclusive of the start day', () {
      expect(task.endDate, '2026-08-02');
    });

    test('isActiveOn respects the date range', () {
      expect(task.isActiveOn(DateTime(2026, 7, 12)), isFalse); // day before
      expect(task.isActiveOn(DateTime(2026, 7, 13)), isTrue); // first day
      expect(task.isActiveOn(DateTime(2026, 8, 2)), isTrue); // last day
      expect(task.isActiveOn(DateTime(2026, 8, 3)), isFalse); // day after
    });

    test('archived tasks are never active', () {
      final archived = task.copyWith(status: TaskStatus.archived);
      expect(archived.isActiveOn(DateTime(2026, 7, 13)), isFalse);
    });

    test('toMap/fromMap round-trips', () {
      final restored = Task.fromMap(task.id, task.toMap());
      expect(restored.title, task.title);
      expect(restored.startDate, task.startDate);
      expect(restored.durationDays, task.durationDays);
      expect(restored.status, task.status);
      expect(restored.createdAt, task.createdAt);
      expect(restored.description, isNull);
      expect(restored.reminderTime, isNull);
    });

    test('unknown status falls back to active', () {
      final map = task.toMap()..['status'] = 'garbage';
      expect(Task.fromMap('x', map).status, TaskStatus.active);
    });
  });

  group('TaskRepository', () {
    late FakeFirestoreGateway gateway;
    late TaskRepository repo;

    setUp(() {
      gateway = FakeFirestoreGateway();
      repo = TaskRepository(gateway, 'u1');
    });

    test('create persists under users/{uid}/tasks and getAll returns it',
        () async {
      final task = await repo.create(
        title: 'Meditate',
        startDate: '2026-07-13',
        durationDays: 7,
      );

      expect(gateway.docs.keys.single, 'users/u1/tasks/${task.id}');
      final all = await repo.getAll();
      expect(all.single.title, 'Meditate');
      expect(all.single.status, TaskStatus.active);
    });

    test('getAll sorts newest first', () async {
      final older = await repo.create(
          title: 'A', startDate: '2026-07-13', durationDays: 1);
      // Force distinct createdAt: rewrite the older doc one hour back.
      await repo.save(older.copyWith(
          updatedAt: DateTime.now().toUtc())); // keep save path exercised
      gateway.docs['users/u1/tasks/${older.id}']!['createdAt'] =
          DateTime.now().toUtc().subtract(const Duration(hours: 1));
      final newer = await repo.create(
          title: 'B', startDate: '2026-07-13', durationDays: 1);

      final all = await repo.getAll();
      expect(all.map((t) => t.id).toList(), [newer.id, older.id]);
    });

    test('setStatus merges without clobbering other fields', () async {
      final task = await repo.create(
        title: 'Run',
        startDate: '2026-07-13',
        durationDays: 30,
      );
      await repo.setStatus(task.id, TaskStatus.archived);

      final loaded = await repo.getById(task.id);
      expect(loaded!.status, TaskStatus.archived);
      expect(loaded.title, 'Run');
      expect(loaded.durationDays, 30);
    });

    test('delete removes the task', () async {
      final task = await repo.create(
        title: 'X',
        startDate: '2026-07-13',
        durationDays: 1,
      );
      await repo.delete(task.id);
      expect(await repo.getById(task.id), isNull);
      expect(await repo.getAll(), isEmpty);
    });
  });
}
