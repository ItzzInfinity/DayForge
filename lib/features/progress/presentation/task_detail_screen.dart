import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/content_width.dart';
import '../../../core/widgets/error_retry.dart';
import '../../daily/domain/daily_log.dart';
import '../../daily/providers.dart';
import '../../tasks/domain/task.dart';
import '../domain/calendar_grid.dart';
import '../domain/progress_calculator.dart';

/// Per-task history: calendar of the whole run + chronological remark log.
class TaskDetailScreen extends ConsumerWidget {
  const TaskDetailScreen({super.key, required this.task});

  final Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(taskLogsProvider(task.id));
    final today = ref.watch(currentDateProvider);
    return Scaffold(
      appBar: AppBar(title: Text(task.title)),
      body: ContentWidth(
          child: logsAsync.when(
        data: (logs) => _DetailBody(task: task, logs: logs, today: today),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorRetry(
          message: 'Could not load this task\'s history.',
          error: error,
          onRetry: () => ref.invalidate(taskLogsProvider(task.id)),
        ),
      )),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.task,
    required this.logs,
    required this.today,
  });

  final Task task;
  final List<DailyLog> logs;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final todayKey = toDateKey(today);
    final completedDates = {
      for (final log in logs)
        if (log.completed) log.date,
    };
    final logsByDate = {for (final log in logs) log.date: log};
    final progress =
        calculateProgress(task: task, logs: logs, today: today);
    final percent = (progress.completionPercent * 100).round();
    final months = monthsInRange(task.startDate, task.endDate);
    final history = logs.reversed.toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (task.description != null) ...[
          Text(task.description!),
          const SizedBox(height: 8),
        ],
        Text(
          '${task.startDate} → ${task.endDate} · ${task.durationDays} days'
          '${task.categoryLabel != null ? ' · ${task.categoryLabel}' : ''}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            if (progress.currentStreak > 0) ...[
              Chip(
                avatar: const Text('🔥'),
                label: Text('${progress.currentStreak} day'
                    '${progress.currentStreak == 1 ? '' : 's'}'),
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                progress.elapsedDays == 0
                    ? 'Starts ${task.startDate}'
                    : '${progress.completedDays} of ${progress.elapsedDays} '
                        'days done · $percent%',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        for (final m in months) ...[
          Text(
            '${monthNames[m.month - 1]} ${m.year}',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          // Cap the grid width so day circles keep a readable proportion on
          // wide desktop windows instead of huge circles with tiny numbers.
          Align(
            alignment: Alignment.topLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _WeekdayHeader(),
                  GridView.count(
                    crossAxisCount: 7,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      for (final cell in monthCells(m.year, m.month))
                        cell == null
                            ? const SizedBox.shrink()
                            : _DayCell(
                                dateKey: toDateKey(cell),
                                day: cell.day,
                                status: dayStatus(
                                  dateKey: toDateKey(cell),
                                  task: task,
                                  completedDates: completedDates,
                                  todayKey: todayKey,
                                ),
                                log: logsByDate[toDateKey(cell)],
                              ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        const Divider(),
        Text('History', style: Theme.of(context).textTheme.titleSmall),
        if (history.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('Nothing logged yet.'),
          ),
        for (final log in history)
          ListTile(
            key: ValueKey('history-${log.date}'),
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              log.completed ? Icons.check_circle : Icons.radio_button_unchecked,
              color: log.completed
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline,
            ),
            title: Text(log.date),
            subtitle: log.remark.isEmpty ? null : Text(log.remark),
          ),
      ],
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const labels = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
    return Row(
      children: [
        for (final label in labels)
          Expanded(
            child: Center(
              child: Text(label, style: Theme.of(context).textTheme.labelSmall),
            ),
          ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.dateKey,
    required this.day,
    required this.status,
    required this.log,
  });

  final String dateKey;
  final int day;
  final DayStatus status;
  final DailyLog? log;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (background, foreground, border) = switch (status) {
      DayStatus.completed => (scheme.primary, scheme.onPrimary, null),
      DayStatus.missed => (
          scheme.errorContainer,
          scheme.onErrorContainer,
          null
        ),
      DayStatus.pending => (null, scheme.primary, scheme.primary),
      DayStatus.future => (
          scheme.surfaceContainerHighest,
          scheme.onSurfaceVariant,
          null
        ),
      DayStatus.outOfRange => (null, scheme.outlineVariant, null),
    };
    return Padding(
      padding: const EdgeInsets.all(3),
      child: InkWell(
        key: ValueKey('cal-$dateKey'),
        customBorder: const CircleBorder(),
        onTap: status == DayStatus.outOfRange
            ? null
            : () => showDialog<void>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(dateKey),
                    content: Text(switch ((status, log?.remark ?? '')) {
                      (DayStatus.completed, '') => 'Completed.',
                      (DayStatus.completed, final r) => 'Completed — $r',
                      (DayStatus.missed, '') => 'Missed.',
                      (DayStatus.missed, final r) => 'Missed — $r',
                      (DayStatus.pending, _) => 'Today — not ticked yet.',
                      _ => 'Scheduled.',
                    }),
                  ),
                ),
        child: Ink(
          decoration: BoxDecoration(
            color: background,
            shape: BoxShape.circle,
            border: border == null ? null : Border.all(color: border),
          ),
          // Scale the day number with the circle so it stays readable at
          // any cell size (was a fixed small style lost in big circles).
          child: LayoutBuilder(
            builder: (context, constraints) => Center(
              child: Text(
                '$day',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w500,
                      fontSize:
                          (constraints.maxWidth * 0.4).clamp(12.0, 22.0),
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
