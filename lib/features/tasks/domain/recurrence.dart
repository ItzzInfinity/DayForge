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

  /// The majority rule: a day counts as done once *more than half* its
  /// reminders are ticked. 9 nudges need 5, 8 need 5, 2 need 2, 1 needs 1 —
  /// always a strict majority, never an exact half.
  ///
  /// This is the default a task gets when the user does not name a target,
  /// because a day where you drank 6 of 9 glasses is a day you kept the
  /// habit, and marking it missed is the thing that breaks streaks people
  /// were actually keeping.
  static int majorityTarget(int occurrences) =>
      occurrences <= 1 ? 1 : (occurrences ~/ 2) + 1;

  /// The interval that fits exactly [occurrences] reminders into a window of
  /// [windowMinutes], for the "N times a day" way of describing a task
  /// (the inverse of picking an interval and counting what lands).
  ///
  /// Floor division alone can overshoot on short windows — a 5-minute window
  /// asked for 4 reminders yields a 1-minute step and six of them — so the
  /// step is widened until the count is right.
  static int intervalForOccurrences({
    required int windowMinutes,
    required int occurrences,
  }) {
    if (occurrences <= 1 || windowMinutes <= 0) return windowMinutes + 1;
    var step = windowMinutes ~/ (occurrences - 1);
    if (step < 1) step = 1;
    while (step < windowMinutes && windowMinutes ~/ step + 1 > occurrences) {
      step++;
    }
    return step;
  }

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

  /// Ticks needed for the day to count as completed. Defaults to the
  /// [majorityTarget] — more than half the day's reminders — and the user may
  /// override it in either direction ("all 9, no excuses" or "3 is plenty").
  int get targetPerDay {
    if (!isIntraday) return 1;
    final target = _targetPerDay;
    if (target == null || target < 1) return majorityTarget(occurrencesPerDay);
    return target > occurrencesPerDay ? occurrencesPerDay : target;
  }

  /// Ticks the day can hold at all. You may keep ticking past [targetPerDay]
  /// — hitting the target completes the day, it does not close the counter.
  int get maxPerDay => isIntraday ? occurrencesPerDay : 1;

  /// True when the day completes on a strict majority rather than an explicit
  /// number the user chose. Used by the UI to explain where the target came
  /// from instead of showing a bare digit.
  bool get usesMajorityRule =>
      isIntraday && (_targetPerDay == null || _targetPerDay < 1);

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
    final goal = targetPerDay == occurrencesPerDay
        ? '$occurrencesPerDay× a day'
        : '$targetPerDay of $occurrencesPerDay a day'
            '${usesMajorityRule ? ' (over half)' : ''}';
    return 'Every $every, $startTime–$endTime · $goal';
  }
}
