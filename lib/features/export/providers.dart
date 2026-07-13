import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../daily/data/daily_log_repository.dart';
import '../settings/domain/app_settings.dart';
import '../tasks/data/task_repository.dart';
import 'data/export_saver.dart';
import 'domain/exporters.dart';

final exportSaverProvider = Provider<ExportSaver>((ref) {
  if (!kIsWeb && Platform.isAndroid) return ShareExportSaver();
  return DesktopExportSaver();
});

/// Reads the user's full dataset once. Deliberately not a provider: exports
/// must always hit the repositories fresh, never a cached snapshot.
Future<ExportBundle> gatherExportBundle({
  required TaskRepository taskRepository,
  required DailyLogRepository dailyLogRepository,
  required AppSettings settings,
  required DateTime now,
}) async {
  final tasks = await taskRepository.getAll();
  return ExportBundle(
    exportedAt: now,
    settings: settings,
    entries: [
      for (final task in tasks)
        TaskExport(
          task: task,
          logs: await dailyLogRepository.getAllForTask(task.id),
        ),
    ],
  );
}
