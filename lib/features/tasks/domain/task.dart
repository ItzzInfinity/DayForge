import '../../../core/utils/date_utils.dart';

/// Firestore doc: `users/{uid}/tasks/{taskId}` (docs/data-model.md).
enum TaskStatus { active, completed, archived }

class Task {
  Task({
    required this.id,
    required this.title,
    this.description,
    this.categories = const [],
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

  /// Zero or more user-facing labels ("Health", "Learning", …). Older docs
  /// stored a single `category` string — [Task.fromMap] migrates it.
  final List<String> categories;

  /// Display form of [categories]; null when the task has none.
  String? get categoryLabel =>
      categories.isEmpty ? null : categories.join(', ');

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
        'categories': categories,
        'startDate': startDate,
        'durationDays': durationDays,
        'reminderTime': reminderTime,
        'status': status.name,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  factory Task.fromMap(String id, Map<String, dynamic> map) {
    // Docs written before multi-category support hold a single `category`
    // string; treat it as a one-element list.
    final legacy = map['category'] as String?;
    return Task(
      id: id,
      title: map['title'] as String? ?? '',
      description: map['description'] as String?,
      categories: switch (map['categories']) {
        final List list => [for (final c in list) c as String],
        _ => [if (legacy != null && legacy.isNotEmpty) legacy],
      },
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
    List<String>? categories,
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
      categories: categories ?? this.categories,
      startDate: startDate ?? this.startDate,
      durationDays: durationDays ?? this.durationDays,
      reminderTime: reminderTime != null ? reminderTime() : this.reminderTime,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
