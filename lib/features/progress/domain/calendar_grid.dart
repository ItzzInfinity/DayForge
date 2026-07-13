import '../../../core/utils/date_utils.dart';
import '../../tasks/domain/task.dart';

/// How one calendar day relates to a task's run.
enum DayStatus {
  completed,
  missed,

  /// Today, in range, not ticked yet — not a miss until the day ends.
  pending,
  future,
  outOfRange,
}

DayStatus dayStatus({
  required String dateKey,
  required Task task,
  required Set<String> completedDates,
  required String todayKey,
}) {
  if (dateKey.compareTo(task.startDate) < 0 ||
      dateKey.compareTo(task.endDate) > 0) {
    return DayStatus.outOfRange;
  }
  if (completedDates.contains(dateKey)) return DayStatus.completed;
  if (dateKey.compareTo(todayKey) > 0) return DayStatus.future;
  if (dateKey == todayKey) return DayStatus.pending;
  return DayStatus.missed;
}

/// Every (year, month) a task's range touches, in order.
List<({int year, int month})> monthsInRange(String startKey, String endKey) {
  final start = fromDateKey(startKey);
  final end = fromDateKey(endKey);
  final months = <({int year, int month})>[];
  var year = start.year;
  var month = start.month;
  while (year < end.year || (year == end.year && month <= end.month)) {
    months.add((year: year, month: month));
    month++;
    if (month == 13) {
      month = 1;
      year++;
    }
  }
  return months;
}

/// Cells for a Monday-first month grid: leading nulls pad the first week,
/// then one UTC-midnight DateTime per day of the month.
List<DateTime?> monthCells(int year, int month) {
  final first = DateTime.utc(year, month, 1);
  final daysInMonth = DateTime.utc(year, month + 1, 0).day;
  return [
    for (var i = 0; i < first.weekday - 1; i++) null,
    for (var day = 1; day <= daysInMonth; day++)
      DateTime.utc(year, month, day),
  ];
}

const monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];
