/// Formats a date as the local-date key used across the app and in
/// Firestore `daily_logs` document IDs (see docs/data-model.md).
String toDateKey(DateTime date) {
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '${date.year}-$m-$d';
}

/// Parses a `YYYY-MM-DD` key into a UTC midnight [DateTime], so day
/// arithmetic is immune to DST shifts.
DateTime fromDateKey(String key) {
  final parts = key.split('-');
  return DateTime.utc(
    int.parse(parts[0]),
    int.parse(parts[1]),
    int.parse(parts[2]),
  );
}

/// The date key [days] after [key].
String addDaysToKey(String key, int days) =>
    toDateKey(fromDateKey(key).add(Duration(days: days)));
