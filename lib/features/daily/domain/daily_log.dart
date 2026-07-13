/// Firestore doc: `users/{uid}/tasks/{taskId}/daily_logs/{YYYY-MM-DD}`
/// (docs/data-model.md). The document id IS the date key, which makes
/// daily writes idempotent and range reads trivial.
class DailyLog {
  const DailyLog({
    required this.date,
    this.completed = false,
    this.remark = '',
    this.completedAt,
    required this.updatedAt,
  });

  /// `YYYY-MM-DD` local date key (duplicated from the doc id for queries).
  final String date;

  /// The daily checkbox.
  final bool completed;

  /// Short note; allowed on completed and skipped days alike.
  final String remark;

  final DateTime? completedAt;
  final DateTime updatedAt;

  Map<String, dynamic> toMap() => {
        'date': date,
        'completed': completed,
        'remark': remark,
        'completedAt': completedAt,
        'updatedAt': updatedAt,
      };

  factory DailyLog.fromMap(String id, Map<String, dynamic> map) {
    return DailyLog(
      date: map['date'] as String? ?? id,
      completed: map['completed'] as bool? ?? false,
      remark: map['remark'] as String? ?? '',
      completedAt: map['completedAt'] as DateTime?,
      updatedAt: map['updatedAt'] as DateTime? ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }
}
