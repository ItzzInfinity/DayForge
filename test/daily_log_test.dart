import 'package:flutter_test/flutter_test.dart';

import 'package:advanced_todo/features/daily/data/daily_log_repository.dart';
import 'package:advanced_todo/features/daily/domain/daily_log.dart';

import 'helpers/fakes.dart';

void main() {
  group('DailyLog model', () {
    test('toMap/fromMap round-trips', () {
      final log = DailyLog(
        date: '2026-07-13',
        completed: true,
        remark: 'felt great',
        completedAt: DateTime.utc(2026, 7, 13, 9),
        updatedAt: DateTime.utc(2026, 7, 13, 9),
      );
      final restored = DailyLog.fromMap('2026-07-13', log.toMap());
      expect(restored.date, log.date);
      expect(restored.completed, isTrue);
      expect(restored.remark, 'felt great');
      expect(restored.completedAt, log.completedAt);
    });

    test('falls back to the doc id when date field is missing', () {
      final restored = DailyLog.fromMap('2026-07-13', {'completed': true});
      expect(restored.date, '2026-07-13');
      expect(restored.remark, '');
    });
  });

  group('DailyLogRepository', () {
    late FakeFirestoreGateway gateway;
    late DailyLogRepository repo;

    setUp(() {
      gateway = FakeFirestoreGateway();
      repo = DailyLogRepository(gateway, 'u1');
    });

    test('ticking creates the log with the date as the doc id', () async {
      await repo.setCompleted('t1', '2026-07-13', completed: true);

      expect(
        gateway.docs.keys.single,
        'users/u1/tasks/t1/daily_logs/2026-07-13',
      );
      final log = await repo.get('t1', '2026-07-13');
      expect(log!.completed, isTrue);
      expect(log.completedAt, isNotNull);
    });

    test('unticking clears completedAt', () async {
      await repo.setCompleted('t1', '2026-07-13', completed: true);
      await repo.setCompleted('t1', '2026-07-13', completed: false);

      final log = await repo.get('t1', '2026-07-13');
      expect(log!.completed, isFalse);
      expect(log.completedAt, isNull);
    });

    test('remark and checkbox merge without clobbering each other', () async {
      await repo.setRemark('t1', '2026-07-13', 'only half done');
      await repo.setCompleted('t1', '2026-07-13', completed: true);

      final log = await repo.get('t1', '2026-07-13');
      expect(log!.remark, 'only half done');
      expect(log.completed, isTrue);
    });

    test('remark on a skipped day needs no completion', () async {
      await repo.setRemark('t1', '2026-07-14', 'was travelling');

      final log = await repo.get('t1', '2026-07-14');
      expect(log!.completed, isFalse);
      expect(log.remark, 'was travelling');
    });

    test('getAllForTask returns logs oldest first', () async {
      await repo.setCompleted('t1', '2026-07-14', completed: true);
      await repo.setCompleted('t1', '2026-07-13', completed: true);
      await repo.setRemark('t2', '2026-07-13', 'other task');

      final logs = await repo.getAllForTask('t1');
      expect(logs.map((l) => l.date).toList(), ['2026-07-13', '2026-07-14']);
    });
  });
}
