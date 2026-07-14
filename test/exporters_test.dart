import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:advanced_todo/features/daily/domain/daily_log.dart';
import 'package:advanced_todo/features/export/domain/exporters.dart';
import 'package:advanced_todo/features/settings/domain/app_settings.dart';
import 'package:advanced_todo/features/tasks/domain/task.dart';

void main() {
  final created = DateTime.utc(2026, 7, 1, 8);
  final meditate = Task(
    id: 't1',
    title: 'Meditate',
    description: 'Ten minutes',
    categories: const ['Health', 'Habit'],
    startDate: '2026-07-01',
    durationDays: 21,
    reminderTime: '07:30',
    createdAt: created,
    updatedAt: created,
  );
  final tricky = Task(
    id: 't2',
    title: 'Read, "deeply"',
    startDate: '2026-07-10',
    durationDays: 5,
    createdAt: created,
    updatedAt: created,
  );
  final logs = [
    DailyLog(
      date: '2026-07-01',
      completed: true,
      remark: 'Felt calm',
      completedAt: DateTime.utc(2026, 7, 1, 7, 35),
      updatedAt: DateTime.utc(2026, 7, 1, 7, 35),
    ),
    DailyLog(
      date: '2026-07-02',
      remark: 'Skipped, travel | busy',
      updatedAt: DateTime.utc(2026, 7, 2, 22),
    ),
  ];
  final bundle = ExportBundle(
    exportedAt: DateTime.utc(2026, 7, 13, 10),
    settings: const AppSettings(defaultDurationDays: 30),
    entries: [
      TaskExport(task: meditate, logs: logs),
      TaskExport(task: tricky, logs: const []),
    ],
  );

  group('exportToJson', () {
    test('is valid JSON carrying settings, tasks and logs', () {
      final parsed = jsonDecode(exportToJson(bundle)) as Map<String, dynamic>;

      expect(parsed['app'], 'dayforge');
      expect(parsed['formatVersion'], 1);
      expect(parsed['exportedAt'], '2026-07-13T10:00:00.000Z');
      expect((parsed['settings'] as Map)['defaultDurationDays'], 30);

      final tasks = parsed['tasks'] as List;
      expect(tasks, hasLength(2));
      final first = tasks.first as Map<String, dynamic>;
      expect(first['id'], 't1');
      expect(first['endDate'], '2026-07-21');
      expect(first['createdAt'], '2026-07-01T08:00:00.000Z');
      final firstLogs = first['dailyLogs'] as List;
      expect(firstLogs, hasLength(2));
      expect((firstLogs.first as Map)['completedAt'],
          '2026-07-01T07:35:00.000Z');
      expect((firstLogs.last as Map)['completedAt'], isNull);
      expect((tasks.last as Map)['dailyLogs'], isEmpty);
    });
  });

  group('exportToCsv', () {
    test('one row per log, one row for log-less tasks, quoted specials', () {
      final lines = exportToCsv(bundle).split('\r\n');

      expect(lines, hasLength(4)); // header + 2 logs + 1 log-less task
      expect(lines.first, startsWith('taskId,title,categories,status'));
      expect(lines[1],
          startsWith('t1,Meditate,"Health, Habit",active,2026-07-01,2026-07-21,21,'));
      expect(lines[1], contains('2026-07-01,true,2026-07-01T07:35:00.000Z'));
      expect(lines[2], contains(',false,,'));
      // Comma and quotes in the title must be escaped, log columns empty.
      expect(lines[3], startsWith('t2,"Read, ""deeply""",,active,'));
      expect(lines[3], endsWith(',,,,'));
    });
  });

  group('exportToMarkdown', () {
    test('section per task with history table; pipes escaped', () {
      final md = exportToMarkdown(bundle);

      expect(md, contains('## Meditate'));
      expect(md, contains('- Runs: 2026-07-01 → 2026-07-21 (21 days)'));
      expect(md, contains('- Categories: Health, Habit'));
      expect(md, contains('| 2026-07-01 | ✓ | Felt calm |'));
      expect(md, contains(r'| 2026-07-02 | ○ | Skipped, travel \| busy |'));
      expect(md, contains('## Read, "deeply"'));
      expect(md, contains('_No daily history recorded._'));
    });

    test('empty bundle still renders a valid document', () {
      final empty = ExportBundle(
        exportedAt: DateTime.utc(2026, 7, 13),
        settings: const AppSettings(),
        entries: const [],
      );
      expect(exportToMarkdown(empty), contains('_No tasks._'));
    });
  });

  test('exportFileName embeds the export date and format extension', () {
    expect(exportFileName(bundle, ExportFormat.json),
        'dayforge_export_2026-07-13.json');
    expect(exportFileName(bundle, ExportFormat.markdown),
        'dayforge_export_2026-07-13.md');
  });
}
