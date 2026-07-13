import '../../../core/utils/date_utils.dart';
import '../../daily/domain/daily_log.dart';

/// Pure logic for the GitHub-style activity heatmap on the Progress screen:
/// one cell per day, brighter the more tasks were ticked that day.

/// How many tasks were ticked on each day, across every task's logs.
Map<String, int> dailyTickCounts(Iterable<List<DailyLog>> logsByTask) {
  final counts = <String, int>{};
  for (final logs in logsByTask) {
    for (final log in logs) {
      if (log.completed) {
        counts[log.date] = (counts[log.date] ?? 0) + 1;
      }
    }
  }
  return counts;
}

/// GitHub-style intensity bucket 0..4, relative to the busiest day (so one
/// daily task still reaches full brightness on its ticked days).
int heatLevel(int ticks, int maxTicks) {
  if (ticks <= 0 || maxTicks <= 0) return 0;
  return ((ticks * 4) / maxTicks).ceil().clamp(1, 4);
}

/// Monday-first week columns of date keys, oldest week first, ending with
/// the week that contains [today]. Every column holds exactly 7 keys; the
/// trailing ones may lie after [today] (the widget renders those as blank).
List<List<String>> heatmapWeeks(DateTime today, {int weeks = 20}) {
  final day = fromDateKey(toDateKey(today));
  final thisMonday = day.subtract(Duration(days: day.weekday - 1));
  final firstMonday = thisMonday.subtract(Duration(days: 7 * (weeks - 1)));
  return [
    for (var w = 0; w < weeks; w++)
      [
        for (var d = 0; d < 7; d++)
          toDateKey(firstMonday.add(Duration(days: 7 * w + d))),
      ],
  ];
}
