import '../../../services/notifications/reminder_scheduler.dart'
    show parseHhMm;

/// How often a task asks for attention within a day.
enum RecurrenceKind {
  /// One reminder a day at the task's reminderTime — the original behavior.
  daily,

  /// Several reminders a day inside a window ("drink water 08:00→20:00,
  /// every 90 minutes"), repeating daily.
  intraday,
}

/// Stored on the task as `recurrence` (docs/data-model.md). Tasks written
/// before intraday support carry no field at all and read back as [daily].
class Recurrence {
  const Recurrence.daily()
      : kind = RecurrenceKind.daily,
        startTime = '08:00',
        endTime = '20:00',
        intervalMinutes = 60,
        _targetPerDay = null;

  const Recurrence.intraday({
    required this.startTime,
    required this.endTime,
    required this.intervalMinutes,
    int? targetPerDay,
  })  : kind = RecurrenceKind.intraday,
        // The field is private but the named parameter cannot be, so an
        // initializing formal is not an option here.
        // ignore: prefer_initializing_formals
        _targetPerDay = targetPerDay,
        assert(intervalMinutes >= 1, 'interval must be at least a minute');

  final RecurrenceKind kind;

  /// `HH:mm` first reminder of the day (intraday only).
  final String startTime;

  /// `HH:mm` last possible reminder of the day (intraday only).
  final String endTime;

  /// Gap between reminders in minutes (intraday only).
  final int intervalMinutes;

  final int? _targetPerDay;

  bool get isIntraday => kind == RecurrenceKind.intraday;

  /// Upper bound on reminders a day: keeps notification ids inside a task's
  /// slot budget and stops a 5-minute window from carpet-bombing the tray.
  static const maxOccurrencesPerDay = 48;

  /// Minutes-since-midnight of every reminder in the window, first to last.
  /// A window that ends before it starts yields the single start time rather
  /// than nothing, so a misconfigured task still reminds once.
  List<int> get occurrenceMinutes {
    if (!isIntraday) {
      final t = parseHhMm(startTime);
      return [t.hour * 60 + t.minute];
    }
    final start = parseHhMm(startTime);
    final end = parseHhMm(endTime);
    final first = start.hour * 60 + start.minute;
    final last = end.hour * 60 + end.minute;
    if (last <= first) return [first];
    final minutes = <int>[];
    for (var m = first;
        m <= last && minutes.length < maxOccurrencesPerDay;
        m += intervalMinutes) {
      minutes.add(m);
    }
    return minutes;
  }

  /// How many reminders a full day carries.
  int get occurrencesPerDay => occurrenceMinutes.length;

  /// Ticks needed for the day to count as completed. Defaults to one per
  /// reminder; the user may set a smaller goal ("8 of the 9 nudges is fine").
  int get targetPerDay {
    if (!isIntraday) return 1;
    final target = _targetPerDay;
    if (target == null || target < 1) return occurrencesPerDay;
    return target > occurrencesPerDay ? occurrencesPerDay : target;
  }

  /// The user's explicit target, if they set one (null = derive it).
  int? get rawTargetPerDay => _targetPerDay;

  /// `null` for plain daily tasks, so their documents stay exactly as before.
  Map<String, dynamic>? toMap() => isIntraday
      ? {
          'kind': kind.name,
          'startTime': startTime,
          'endTime': endTime,
          'intervalMinutes': intervalMinutes,
          'targetPerDay': _targetPerDay,
        }
      : null;

  factory Recurrence.fromMap(Map<String, dynamic>? map) {
    if (map == null || map['kind'] != RecurrenceKind.intraday.name) {
      return const Recurrence.daily();
    }
    return Recurrence.intraday(
      startTime: map['startTime'] as String? ?? '08:00',
      endTime: map['endTime'] as String? ?? '20:00',
      intervalMinutes: map['intervalMinutes'] as int? ?? 60,
      targetPerDay: map['targetPerDay'] as int?,
    );
  }

  /// "every 90 min, 08:00–20:00 · 9× a day" for task tiles.
  String get summary {
    if (!isIntraday) return 'Once a day';
    final hours = intervalMinutes ~/ 60;
    final minutes = intervalMinutes % 60;
    final every = switch ((hours, minutes)) {
      (0, final m) => '$m min',
      (final h, 0) => h == 1 ? 'hour' : '$h hours',
      (final h, final m) => '${h}h ${m}m',
    };
    return 'Every $every, $startTime–$endTime · $targetPerDay× a day';
  }
}
