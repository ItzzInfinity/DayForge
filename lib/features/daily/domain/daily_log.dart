/// Firestore doc: `users/{uid}/tasks/{taskId}/daily_logs/{YYYY-MM-DD}`
/// (docs/data-model.md). The document id IS the date key, which makes
/// daily writes idempotent and range reads trivial.
class DailyLog {
  const DailyLog({
    required this.date,
    this.completed = false,
    this.count = 0,
    this.remark = '',
    this.completedAt,
    required this.updatedAt,
  });

  /// `YYYY-MM-DD` local date key (duplicated from the doc id for queries).
  final String date;

  /// The daily checkbox. For an intraday task this means "the day's target
  /// was reached" — every screen and every stat keeps reading this one flag.
  final bool completed;

  /// Ticks recorded today; only meaningful for intraday tasks (a plain daily
  /// task is 0 or 1 and reads [completed] instead).
  final int count;

  /// Short note; allowed on completed and skipped days alike.
  final String remark;

  final DateTime? completedAt;
  final DateTime updatedAt;

  Map<String, dynamic> toMap() => {
        'date': date,
        'completed': completed,
        'count': count,
        'remark': remark,
        'completedAt': completedAt,
        'updatedAt': updatedAt,
      };

  factory DailyLog.fromMap(String id, Map<String, dynamic> map) {
    return DailyLog(
      date: map['date'] as String? ?? id,
      completed: map['completed'] as bool? ?? false,
      // Logs written before intraday tasks existed have no count: a ticked
      // day counts as one.
      count: map['count'] as int? ??
          ((map['completed'] as bool? ?? false) ? 1 : 0),
      remark: map['remark'] as String? ?? '',
      completedAt: map['completedAt'] as DateTime?,
      updatedAt: map['updatedAt'] as DateTime? ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }
}
