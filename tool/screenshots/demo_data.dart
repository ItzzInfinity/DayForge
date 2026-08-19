// The task list the screenshots are taken against.
//
// Invented, but deliberately plausible: a mix of streak lengths, one task
// mid-run and one nearly finished, a couple of remarks, and one intraday
// task sitting *below* its majority target so the counter tile has something
// to show. Screenshots of an empty app sell nothing.
import '../../test/helpers/fakes.dart';

/// The day every screenshot is taken on — matches currentDateProvider below.
const today = '2026-08-19';
const uid = 'demo';

DateTime _at(int daysAgo) => DateTime(2026, 8, 19 - daysAgo, 9, 0);

String _key(int daysAgo) {
  final d = DateTime(2026, 8, 19).subtract(Duration(days: daysAgo));
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

void _task(
  FakeFirestoreGateway gateway, {
  required String id,
  required String title,
  String? description,
  List<String> categories = const [],
  required int startedDaysAgo,
  required int durationDays,
  String? reminderTime,
  Map<String, dynamic>? recurrence,
  String completionMode = 'fixedWindow',
  int? targetDays,
  String status = 'active',
}) {
  gateway.docs['users/$uid/tasks/$id'] = {
    'title': title,
    'description': description,
    'categories': categories,
    'startDate': _key(startedDaysAgo),
    'durationDays': durationDays,
    'reminderTime': reminderTime,
    'recurrence': recurrence,
    'completionMode': completionMode,
    'targetDays': targetDays,
    'status': status,
    'createdAt': _at(startedDaysAgo),
    'updatedAt': _at(0),
  };
}

void _log(
  FakeFirestoreGateway gateway, {
  required String taskId,
  required int daysAgo,
  bool completed = true,
  int? count,
  String remark = '',
}) {
  final date = _key(daysAgo);
  gateway.docs['users/$uid/tasks/$taskId/daily_logs/$date'] = {
    'date': date,
    'completed': completed,
    'count': count ?? (completed ? 1 : 0),
    'remark': remark,
    'completedAt': completed ? _at(daysAgo) : null,
    'updatedAt': _at(daysAgo),
  };
}

/// Fills [gateway] with the demo account.
void seedDemo(FakeFirestoreGateway gateway) {
  gateway.docs['users/$uid'] = {'email': 'you@example.com'};

  // A long, healthy streak — the headline task.
  _task(gateway,
      id: 'read',
      title: 'Read 20 pages',
      categories: ['Habit', 'Learning'],
      startedDaysAgo: 34,
      durationDays: 60,
      reminderTime: '21:30');
  for (var d = 1; d <= 34; d++) {
    if (d == 9 || d == 22) continue; // two honest misses
    _log(gateway,
        taskId: 'read',
        daysAgo: d,
        remark: switch (d) {
          2 => 'Finished part two.',
          14 => 'Slow chapter, pushed through.',
          _ => '',
        });
  }

  // Target-days rule, most of the way there.
  _task(gateway,
      id: 'run',
      title: 'Morning run',
      categories: ['Fitness'],
      startedDaysAgo: 25,
      durationDays: 30,
      reminderTime: '06:15',
      completionMode: 'targetDays',
      targetDays: 21);
  for (var d = 1; d <= 25; d++) {
    if (d % 4 == 0) continue;
    _log(gateway, taskId: 'run', daysAgo: d, remark: d == 3 ? '5k, felt easy.' : '');
  }

  // Intraday: 9 slots, majority target 5, sitting at 3 so the counter reads
  // 3/5 and the +1 button is live.
  _task(gateway,
      id: 'water',
      title: 'Drink water',
      categories: ['Health'],
      startedDaysAgo: 12,
      durationDays: 90,
      recurrence: {
        'kind': 'intraday',
        'startTime': '08:00',
        'endTime': '20:00',
        'intervalMinutes': 90,
        'targetPerDay': null,
      });
  for (var d = 1; d <= 12; d++) {
    _log(gateway, taskId: 'water', daysAgo: d, count: d.isEven ? 7 : 5);
  }
  _log(gateway, taskId: 'water', daysAgo: 0, completed: false, count: 3);

  // Freshly started, nothing ticked today — an unchecked box on Today.
  _task(gateway,
      id: 'german',
      title: 'German — 15 minutes',
      description: 'Duolingo streak plus one podcast episode.',
      categories: ['Learning', 'Skill'],
      startedDaysAgo: 6,
      durationDays: 21,
      reminderTime: '19:00');
  for (var d = 1; d <= 6; d++) {
    if (d == 4) continue;
    _log(gateway, taskId: 'german', daysAgo: d);
  }

  _task(gateway,
      id: 'stretch',
      title: 'Stretch before bed',
      categories: ['Health'],
      startedDaysAgo: 3,
      durationDays: 30,
      reminderTime: '22:45');
  _log(gateway, taskId: 'stretch', daysAgo: 1);
  _log(gateway, taskId: 'stretch', daysAgo: 2, completed: false, remark: 'Too tired.');

  // One finished run, so the Tasks tab has a Completed chip worth tapping.
  _task(gateway,
      id: 'coldshower',
      title: '30 days of cold showers',
      categories: ['Habit'],
      startedDaysAgo: 40,
      durationDays: 30,
      status: 'completed');
}
