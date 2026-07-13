import '../../../core/utils/date_utils.dart';

/// Firestore doc: `users/{uid}/tasks/{taskId}` (docs/data-model.md).
enum TaskStatus { active, completed, archived }

class Task {
  Task({
    required this.id,
    required this.title,
    this.description,
    this.category,
    required this.startDate,
    required this.durationDays,
    this.reminderTime,
    this.status = TaskStatus.active,
    required this.createdAt,
    required this.updatedAt,
  }) : assert(durationDays >= 1, 'durationDays must be at least 1');

  final String id;
  final String title;
  final String? description;
  final String? category;

  /// `YYYY-MM-DD` local date key of the first active day.
  final String startDate;

  /// The task runs startDate .. startDate + durationDays - 1.
  final int durationDays;

  /// `HH:mm`, null = use the global default reminder time.
  final String? reminderTime;

  final TaskStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Date key of the last active day.
  String get endDate => addDaysToKey(startDate, durationDays - 1);

  /// Whether [date] falls inside this task's run. Date keys compare
  /// correctly as strings, so no DateTime math is needed here.
  bool coversDate(DateTime date) {
    final key = toDateKey(date);
    return startDate.compareTo(key) <= 0 && key.compareTo(endDate) <= 0;
  }

  /// Whether the task should appear on the Today screen for [date].
  bool isActiveOn(DateTime date) =>
      status == TaskStatus.active && coversDate(date);

  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'category': category,
        'startDate': startDate,
        'durationDays': durationDays,
        'reminderTime': reminderTime,
        'status': status.name,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  factory Task.fromMap(String id, Map<String, dynamic> map) {
    return Task(
      id: id,
      title: map['title'] as String? ?? '',
      description: map['description'] as String?,
      category: map['category'] as String?,
      startDate: map['startDate'] as String,
      durationDays: map['durationDays'] as int,
      reminderTime: map['reminderTime'] as String?,
      status: TaskStatus.values.asNameMap()[map['status']] ??
          TaskStatus.active,
      createdAt: map['createdAt'] as DateTime,
      updatedAt: map['updatedAt'] as DateTime,
    );
  }

  Task copyWith({
    String? title,
    String? Function()? description,
    String? Function()? category,
    String? startDate,
    int? durationDays,
    String? Function()? reminderTime,
    TaskStatus? status,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      description: description != null ? description() : this.description,
      category: category != null ? category() : this.category,
      startDate: startDate ?? this.startDate,
      durationDays: durationDays ?? this.durationDays,
      reminderTime: reminderTime != null ? reminderTime() : this.reminderTime,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
