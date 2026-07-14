import 'dart:convert';

import '../../daily/domain/daily_log.dart';
import '../../settings/domain/app_settings.dart';
import '../../tasks/domain/task.dart';

/// Everything a user owns, gathered for export. Pure data — the serializers
/// below never touch the network, so they are trivially unit-testable and
/// identical on every platform.
class ExportBundle {
  const ExportBundle({
    required this.exportedAt,
    required this.settings,
    required this.entries,
  });

  final DateTime exportedAt;
  final AppSettings settings;
  final List<TaskExport> entries;
}

class TaskExport {
  const TaskExport({required this.task, required this.logs});

  final Task task;

  /// Oldest first (as returned by DailyLogRepository.getAllForTask).
  final List<DailyLog> logs;
}

/// Formats the user can export to. [extension] doubles as the dialog label.
enum ExportFormat {
  json('json'),
  csv('csv'),
  markdown('md');

  const ExportFormat(this.extension);
  final String extension;
}

String serializeExport(ExportBundle bundle, ExportFormat format) =>
    switch (format) {
      ExportFormat.json => exportToJson(bundle),
      ExportFormat.csv => exportToCsv(bundle),
      ExportFormat.markdown => exportToMarkdown(bundle),
    };

/// Full-fidelity dump; also the future import/restore format.
String exportToJson(ExportBundle bundle) {
  return const JsonEncoder.withIndent('  ').convert({
    'app': 'dayforge',
    'formatVersion': 1,
    'exportedAt': bundle.exportedAt.toIso8601String(),
    'settings': bundle.settings.toMap(),
    'tasks': [
      for (final entry in bundle.entries)
        {
          'id': entry.task.id,
          ..._isoDates(entry.task.toMap()),
          'endDate': entry.task.endDate,
          'dailyLogs': [
            for (final log in entry.logs) _isoDates(log.toMap()),
          ],
        },
    ],
  });
}

/// One row per daily log, task fields repeated per row so the file opens
/// cleanly in a spreadsheet. Tasks without logs still get one row (with the
/// log columns empty) so nothing silently disappears from the export.
String exportToCsv(ExportBundle bundle) {
  const header = [
    'taskId',
    'title',
    'category',
    'status',
    'startDate',
    'endDate',
    'durationDays',
    'logDate',
    'completed',
    'completedAt',
    'remark',
  ];
  final rows = [header];
  for (final entry in bundle.entries) {
    final task = entry.task;
    final taskCells = [
      task.id,
      task.title,
      task.category ?? '',
      task.status.name,
      task.startDate,
      task.endDate,
      '${task.durationDays}',
    ];
    if (entry.logs.isEmpty) {
      rows.add([...taskCells, '', '', '', '']);
    }
    for (final log in entry.logs) {
      rows.add([
        ...taskCells,
        log.date,
        '${log.completed}',
        log.completedAt?.toIso8601String() ?? '',
        log.remark,
      ]);
    }
  }
  return rows.map((cells) => cells.map(_csvCell).join(',')).join('\r\n');
}

/// Human-readable report: one section per task with a history table.
String exportToMarkdown(ExportBundle bundle) {
  final buffer = StringBuffer()
    ..writeln('# DayForge — data export')
    ..writeln()
    ..writeln('Exported: ${bundle.exportedAt.toIso8601String()}')
    ..writeln();
  if (bundle.entries.isEmpty) {
    buffer.writeln('_No tasks._');
  }
  for (final entry in bundle.entries) {
    final task = entry.task;
    buffer
      ..writeln('## ${task.title}')
      ..writeln();
    if (task.description != null && task.description!.isNotEmpty) {
      buffer
        ..writeln(task.description)
        ..writeln();
    }
    buffer
      ..writeln('- Status: ${task.status.name}')
      ..writeln('- Runs: ${task.startDate} → ${task.endDate} '
          '(${task.durationDays} days)');
    if (task.category != null) buffer.writeln('- Category: ${task.category}');
    if (task.reminderTime != null) {
      buffer.writeln('- Reminder: ${task.reminderTime}');
    }
    buffer.writeln();
    if (entry.logs.isEmpty) {
      buffer.writeln('_No daily history recorded._');
    } else {
      buffer
        ..writeln('| Date | Done | Remark |')
        ..writeln('| --- | --- | --- |');
      for (final log in entry.logs) {
        buffer.writeln('| ${log.date} | ${log.completed ? '✓' : '○'} '
            '| ${_mdCell(log.remark)} |');
      }
    }
    buffer.writeln();
  }
  return buffer.toString();
}

/// `dayforge_export_2026-07-13.json` — date from [exportedAt] so the
/// name is stable within a day and sortable across days.
String exportFileName(ExportBundle bundle, ExportFormat format) {
  final d = bundle.exportedAt;
  final date = '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
  return 'dayforge_export_$date.${format.extension}';
}

Map<String, dynamic> _isoDates(Map<String, dynamic> map) => {
      for (final e in map.entries)
        e.key: e.value is DateTime
            ? (e.value as DateTime).toIso8601String()
            : e.value,
    };

String _csvCell(String value) {
  if (value.contains(',') ||
      value.contains('"') ||
      value.contains('\n') ||
      value.contains('\r')) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}

/// Keep table structure intact whatever the user typed in a remark.
String _mdCell(String value) =>
    value.replaceAll('|', r'\|').replaceAll('\n', ' ');
