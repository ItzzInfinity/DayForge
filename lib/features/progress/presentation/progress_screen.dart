import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/widgets/content_width.dart';
import '../../../core/widgets/error_retry.dart';
import '../../../core/utils/date_utils.dart';
import '../../daily/providers.dart';
import '../../tasks/domain/task.dart';
import '../../tasks/presentation/add_task_fab.dart';
import '../../tasks/providers.dart';
import '../domain/activity_heatmap.dart';
import '../domain/progress_calculator.dart';
import 'task_detail_screen.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  /// null = all categories; otherwise only tasks carrying this label are
  /// shown — heatmap included, so the grid reflects the same slice.
  String? _categoryFilter;

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      floatingActionButton: const AddTaskFab(
          key: Key('add-task-progress'), heroTag: 'fab-progress'),
      body: ContentWidth(
          child: tasksAsync.when(
        data: (tasks) {
          final tracked = [
            for (final task in tasks)
              if (task.status != TaskStatus.archived) task
          ];
          if (tracked.isEmpty) {
            return const Center(
              child: Text(
                'No tasks to track yet.\nAdd one from the Tasks tab.',
                textAlign: TextAlign.center,
              ),
            );
          }
          final categories = {
            for (final task in tracked) ...task.categories,
          }.toList()
            ..sort();
          final visible = [
            for (final task in tracked)
              if (_categoryFilter == null ||
                  task.categories.contains(_categoryFilter))
                task
          ];
          // Top third of the screen: the GitHub-style activity grid; the
          // per-task cards scroll below it.
          return LayoutBuilder(
            builder: (context, constraints) => Column(
              children: [
                if (categories.isNotEmpty)
                  SizedBox(
                    height: 48,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: [
                        for (final category in categories)
                          Padding(
                            padding: const EdgeInsets.only(right: 8, top: 8),
                            child: FilterChip(
                              key: Key('progress-cat-$category'),
                              label: Text(category),
                              selected: _categoryFilter == category,
                              onSelected: (selected) => setState(() =>
                                  _categoryFilter =
                                      selected ? category : null),
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                      ],
                    ),
                  ),
                SizedBox(
                  height: (constraints.maxHeight / 3).clamp(150.0, 280.0),
                  child: _ActivityHeatmap(tasks: visible),
                ),
                Expanded(
                  child: visible.isEmpty
                      ? const Center(
                          child: Text('No tasks in this category.'))
                      : ListView(
                          padding: const EdgeInsets.all(8),
                          children: [
                            for (final task in visible)
                              _ProgressCard(task: task),
                          ],
                        ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorRetry(
          message: 'Could not load your tasks.',
          error: error,
          onRetry: () => ref.invalidate(tasksProvider),
        ),
      )),
    );
  }
}

/// GitHub-style contribution grid: one cell per day (Monday-first columns,
/// one column per week, newest at the right), brighter the more tasks were
/// ticked that day.
class _ActivityHeatmap extends ConsumerWidget {
  const _ActivityHeatmap({required this.tasks});

  final List<Task> tasks;

  static const _weekdayLabels = ['M', '', 'W', '', 'F', '', 'S'];

  Color _cellColor(ColorScheme scheme, int level) => switch (level) {
        0 => scheme.surfaceContainerHighest,
        1 => scheme.primary.withValues(alpha: 0.30),
        2 => scheme.primary.withValues(alpha: 0.55),
        3 => scheme.primary.withValues(alpha: 0.78),
        _ => scheme.primary,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(currentDateProvider);
    final todayKey = toDateKey(today);
    // Renders progressively: each task's history fills in as it loads.
    final counts = dailyTickCounts([
      for (final task in tasks)
        ref.watch(taskLogsProvider(task.id)).value ?? const [],
    ]);
    final maxTicks =
        counts.values.fold(0, (max, c) => c > max ? c : max);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      key: const Key('activity-heatmap'),
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Activity', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // A slot is one day's total footprint (cell + margins).
                  // Size it from the height (7 rows must fit exactly), then
                  // show as many whole weeks as the width takes at that size
                  // — big cells that fill a desktop card, and on narrow
                  // phones the cells shrink instead so nothing overflows or
                  // needs to scroll.
                  const labelW = 16.0;
                  final gridW = math.max(0.0, constraints.maxWidth - labelW);
                  final maxSlot =
                      (constraints.maxHeight / 7).clamp(8.0, 36.0);
                  final weekCount =
                      (gridW / maxSlot).floor().clamp(8, 53);
                  final slot = math.min(gridW / weekCount, maxSlot);
                  final cell = slot - 2;
                  final weeks = heatmapWeeks(today, weeks: weekCount);
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          for (final label in _weekdayLabels)
                            SizedBox(
                              height: slot,
                              width: labelW,
                              child: Text(
                                label,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontSize: (cell * 0.55).clamp(6.0, 11.0),
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                        ],
                      ),
                      for (final week in weeks)
                        Column(
                          children: [
                            for (final dateKey in week)
                              dateKey.compareTo(todayKey) > 0
                                  ? SizedBox(width: slot, height: slot)
                                  : _heatCell(
                                      scheme,
                                      cell,
                                      dateKey,
                                      counts[dateKey] ?? 0,
                                      maxTicks,
                                      dateKey == todayKey,
                                    ),
                          ],
                        ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('Less ',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: scheme.onSurfaceVariant)),
                for (final level in const [0, 1, 2, 3, 4])
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _cellColor(scheme, level),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                Text(' More',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: scheme.onSurfaceVariant)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _heatCell(ColorScheme scheme, double size, String dateKey,
      int ticks, int maxTicks, bool isToday) {
    final level = heatLevel(ticks, maxTicks);
    return Tooltip(
      message: '$ticks done · $dateKey',
      waitDuration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey('heat-$dateKey'),
        width: size,
        height: size,
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: _cellColor(scheme, level),
          borderRadius: BorderRadius.circular(2),
          border: isToday
              ? Border.all(color: scheme.primary, width: 1)
              : null,
        ),
      ),
    );
  }
}

class _ProgressCard extends ConsumerWidget {
  const _ProgressCard({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(taskLogsProvider(task.id));
    final today = ref.watch(currentDateProvider);
    return Card(
      key: ValueKey('progress-card-${task.id}'),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => TaskDetailScreen(task: task),
          ),
        ),
        child: Padding(
        padding: const EdgeInsets.all(16),
        child: logsAsync.when(
          data: (logs) {
            final progress =
                calculateProgress(task: task, logs: logs, today: today);
            final percent = (progress.completionPercent * 100).round();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        task.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    if (progress.currentStreak > 0)
                      Chip(
                        key: ValueKey('streak-${task.id}'),
                        avatar: const Text('🔥'),
                        label: Text('${progress.currentStreak} day'
                            '${progress.currentStreak == 1 ? '' : 's'}'),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${task.startDate} → ${task.endDate}'
                  '${task.status == TaskStatus.completed ? ' · completed' : ''}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: progress.completionPercent,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 6),
                Text(
                  key: ValueKey('completion-${task.id}'),
                  progress.elapsedDays == 0
                      ? 'Starts ${task.startDate}'
                      : '${progress.completedDays} of ${progress.elapsedDays} '
                          'days done · $percent%',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            );
          },
          loading: () => const SizedBox(
            height: 48,
            child: Center(
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          error: (error, _) => Row(
            children: [
              Expanded(
                child: Text('Could not load history. '
                    '${friendlyError(error)}'),
              ),
              IconButton(
                key: ValueKey('retry-logs-${task.id}'),
                icon: const Icon(Icons.refresh),
                tooltip: 'Retry',
                onPressed: () => ref.invalidate(taskLogsProvider(task.id)),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }
}
