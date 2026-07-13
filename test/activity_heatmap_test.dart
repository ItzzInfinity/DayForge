import 'package:flutter_test/flutter_test.dart';

import 'package:advanced_todo/features/daily/domain/daily_log.dart';
import 'package:advanced_todo/features/progress/domain/activity_heatmap.dart';

DailyLog log(String date, {bool completed = true}) => DailyLog(
      date: date,
      completed: completed,
      updatedAt: DateTime.utc(2026, 7, 13),
    );

void main() {
  group('dailyTickCounts', () {
    test('sums completed logs per day across tasks', () {
      final counts = dailyTickCounts([
        [log('2026-07-12'), log('2026-07-13')],
        [log('2026-07-13'), log('2026-07-11', completed: false)],
      ]);
      expect(counts, {'2026-07-12': 1, '2026-07-13': 2});
    });

    test('empty input → empty map', () {
      expect(dailyTickCounts(const []), isEmpty);
      expect(dailyTickCounts([const []]), isEmpty);
    });
  });

  group('heatLevel', () {
    test('0 ticks is always level 0', () {
      expect(heatLevel(0, 0), 0);
      expect(heatLevel(0, 5), 0);
    });

    test('busiest day reaches full brightness, others scale relatively', () {
      // One daily habit: every ticked day is the busiest → level 4.
      expect(heatLevel(1, 1), 4);
      // Four tasks: 1..4 ticks map to levels 1..4.
      expect(heatLevel(1, 4), 1);
      expect(heatLevel(2, 4), 2);
      expect(heatLevel(3, 4), 3);
      expect(heatLevel(4, 4), 4);
      // Rounds up so a single tick is never invisible.
      expect(heatLevel(1, 8), 1);
    });
  });

  group('heatmapWeeks', () {
    test('20 Monday-first columns of 7 ending with today\'s week', () {
      // 2026-07-13 is a Monday.
      final weeks = heatmapWeeks(DateTime(2026, 7, 13));
      expect(weeks.length, 20);
      expect(weeks.every((w) => w.length == 7), isTrue);
      expect(weeks.last.first, '2026-07-13'); // today starts the last column
      expect(weeks.last.last, '2026-07-19'); // trailing future days included
      expect(weeks.first.first, '2026-03-02'); // 19 weeks earlier, a Monday
    });

    test('mid-week today still lands in the final column', () {
      final weeks = heatmapWeeks(DateTime(2026, 7, 16)); // a Thursday
      expect(weeks.last.contains('2026-07-16'), isTrue);
      expect(weeks.last.first, '2026-07-13'); // that week's Monday
    });
  });
}
