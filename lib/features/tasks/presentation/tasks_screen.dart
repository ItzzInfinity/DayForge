import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/content_width.dart';
import '../../../core/widgets/error_retry.dart';
import '../../../services/notifications/reminder_scheduler.dart'
    as notifications;
import '../../progress/presentation/task_detail_screen.dart';
import '../../settings/providers.dart';
import '../domain/rollover.dart';
import '../domain/task.dart';
import '../providers.dart';
import 'add_task_fab.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  String _query = '';
  TaskStatus? _statusFilter = TaskStatus.active;
  String? _categoryFilter;

  List<Task> _filtered(List<Task> tasks) {
    final query = _query.trim().toLowerCase();
    return [
      for (final task in tasks)
        if ((_statusFilter == null || task.status == _statusFilter) &&
            (_categoryFilter == null ||
                task.categories.contains(_categoryFilter)) &&
            (query.isEmpty ||
                task.title.toLowerCase().contains(query) ||
                (task.description?.toLowerCase().contains(query) ?? false)))
          task
    ];
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Tasks')),
      floatingActionButton:
          const AddTaskFab(key: Key('add-task'), heroTag: 'fab-tasks'),
      body: ContentWidth(
          child: tasksAsync.when(
        data: (allTasks) {
          // Archived tasks live in Settings → Archived tasks, never here.
          final tasks = [
            for (final task in allTasks)
              if (task.status != TaskStatus.archived) task
          ];
          if (tasks.isEmpty) {
            return const Center(
              child: Text('No tasks yet.\nTap + to add your first one.',
                  textAlign: TextAlign.center),
            );
          }
          final categories = {
            for (final t in tasks) ...t.categories,
          }.toList()
            ..sort();
          final visible = _filtered(tasks);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: TextField(
                  key: const Key('task-search'),
                  decoration: const InputDecoration(
                    hintText: 'Search tasks…',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    for (final (label, status) in [
                      ('All', null),
                      ('Active', TaskStatus.active),
                      ('Completed', TaskStatus.completed),
                    ])
                      Padding(
                        padding: const EdgeInsets.only(right: 8, top: 8),
                        child: ChoiceChip(
                          key: Key('filter-${label.toLowerCase()}'),
                          label: Text(label),
                          selected: _statusFilter == status,
                          // Tapping the already-selected chip resets to All.
                          onSelected: (_) => setState(() => _statusFilter =
                              _statusFilter == status ? null : status),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    if (categories.isNotEmpty)
                      const Padding(
                        padding: EdgeInsets.only(right: 8, top: 8),
                        child: SizedBox(height: 32, child: VerticalDivider()),
                      ),
                    for (final category in categories)
                      Padding(
                        padding: const EdgeInsets.only(right: 8, top: 8),
                        child: FilterChip(
                          key: Key('filter-cat-$category'),
                          label: Text(category),
                          selected: _categoryFilter == category,
                          onSelected: (selected) => setState(
                            () =>
                                _categoryFilter = selected ? category : null,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: visible.isEmpty
                    ? const Center(child: Text('No tasks match your filters.'))
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 80),
                        itemCount: visible.length,
                        itemBuilder: (context, index) =>
                            _TaskTile(task: visible[index]),
                      ),
              ),
            ],
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

class _TaskTile extends ConsumerWidget {
  const _TaskTile({required this.task});

  final Task task;

  Future<void> _setStatus(
    BuildContext context,
    WidgetRef ref,
    TaskStatus status,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(taskRepositoryProvider)?.setStatus(task.id, status);
    ref.invalidate(tasksProvider);
    if (status == TaskStatus.archived) {
      messenger.showSnackBar(const SnackBar(
        content: Text('Archived — find it under Settings → Archived tasks.'),
      ));
    }
  }

  /// Changing the time re-syncs scheduled notifications automatically: the
  /// AuthGate listens to tasksProvider and re-arms reminders on every change.
  Future<void> _changeReminder(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final defaultTime =
        ref.read(appSettingsProvider).value?.defaultReminderTime ??
            notifications.defaultReminderTime;
    const pick = '__pick__';
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Reminder time'),
        children: [
          SimpleDialogOption(
            key: const Key('reminder-pick'),
            onPressed: () => Navigator.of(context).pop(pick),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.alarm),
              title: const Text('Pick a time…'),
              subtitle: Text('Currently ${task.reminderTime ?? defaultTime}'),
            ),
          ),
          if (task.reminderTime != null)
            SimpleDialogOption(
              key: const Key('reminder-clear'),
              onPressed: () => Navigator.of(context).pop('clear'),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.restore),
                title: Text('Use the default ($defaultTime)'),
              ),
            ),
        ],
      ),
    );
    if (choice == null) return;

    String? Function()? newTime;
    if (choice == pick) {
      if (!context.mounted) return;
      final parts = notifications
          .parseHhMm(task.reminderTime ?? defaultTime);
      final picked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: parts.hour, minute: parts.minute),
      );
      if (picked == null) return;
      final formatted = '${picked.hour.toString().padLeft(2, '0')}:'
          '${picked.minute.toString().padLeft(2, '0')}';
      newTime = () => formatted;
    } else {
      newTime = () => null;
    }

    final repo = ref.read(taskRepositoryProvider);
    if (repo == null) return;
    final saved = await repo.save(task.copyWith(reminderTime: newTime));
    ref.invalidate(tasksProvider);
    messenger.showSnackBar(SnackBar(
      content: Text(saved.reminderTime == null
          ? 'Reminder follows the default time ($defaultTime).'
          : 'Reminder set to ${saved.reminderTime}.'),
    ));
  }

  /// Deadline = last active day. Picking a new one recomputes durationDays
  /// from the (unchanged) start date; streaks, calendars and reminders all
  /// derive from the task doc, so they follow automatically.
  Future<void> _changeDeadline(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final start = fromDateKey(task.startDate);
    final current = fromDateKey(task.endDate);
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: start,
      lastDate: start.add(const Duration(days: 5 * 365)),
      helpText: 'Last day of "${task.title}"',
    );
    if (picked == null) return;
    final newDuration = fromDateKey(toDateKey(picked))
            .difference(fromDateKey(task.startDate))
            .inDays +
        1;
    if (newDuration == task.durationDays) return;

    final repo = ref.read(taskRepositoryProvider);
    if (repo == null) return;
    final saved = await repo.save(task.copyWith(durationDays: newDuration));
    ref.invalidate(tasksProvider);
    messenger.showSnackBar(SnackBar(
      content: Text(
          'Deadline moved to ${saved.endDate} (${saved.durationDays} days).'),
    ));
  }

  /// Switches between the two ways a run can end. Turning target-days on
  /// pins the goal at the days completed so far plus what is left of the
  /// current window — i.e. the number the user originally asked for.
  Future<void> _changeCompletionRule(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final picked = await showDialog<CompletionMode>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Completion rule'),
        children: [
          ListTile(
            key: const Key('rule-fixedWindow'),
            title: const Text('Fixed window'),
            subtitle: Text('Ends on ${task.endDate}, whatever happens'),
            selected: task.completionMode == CompletionMode.fixedWindow,
            onTap: () =>
                Navigator.of(context).pop(CompletionMode.fixedWindow),
          ),
          ListTile(
            key: const Key('rule-targetDays'),
            title: const Text('Target days'),
            subtitle: Text('Runs until ${task.targetDays} days are actually '
                'completed — missed days move the end date forward'),
            selected: task.completionMode == CompletionMode.targetDays,
            onTap: () => Navigator.of(context).pop(CompletionMode.targetDays),
          ),
        ],
      ),
    );
    if (picked == null || picked == task.completionMode) return;
    final repo = ref.read(taskRepositoryProvider);
    if (repo == null) return;
    await repo.save(task.copyWith(
      completionMode: picked,
      // Fixed window has no goal to keep; target days pins today's duration
      // as the goal so later extensions cannot move it.
      targetDays: () =>
          picked == CompletionMode.targetDays ? task.targetDays : null,
    ));
    ref.invalidate(tasksProvider);
    messenger.showSnackBar(SnackBar(
      content: Text(picked == CompletionMode.targetDays
          ? 'Runs until ${task.targetDays} days are completed.'
          : 'Ends on ${task.endDate}.'),
    ));
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete "${task.title}"?'),
        content: const Text(
            'This also deletes its daily history and cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('confirm-delete'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(taskRepositoryProvider)?.delete(task.id);
    ref.invalidate(tasksProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      key: ValueKey('task-tile-${task.id}'),
      title: Text(task.title),
      subtitle: Text(
        '${task.startDate} → ${task.endDate} · ${task.durationDays} days'
        '${task.completionMode == CompletionMode.targetDays ? ' · target ${task.targetDays} done' : ''}'
        '${task.recurrence.isIntraday ? ' · ${task.recurrence.targetPerDay}×/day' : ''}'
        '${task.categoryLabel != null ? ' · ${task.categoryLabel}' : ''}',
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => TaskDetailScreen(task: task),
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (task.status != TaskStatus.active)
            Chip(
              label: Text(task.status.name),
              visualDensity: VisualDensity.compact,
            ),
          PopupMenuButton<String>(
            key: ValueKey('task-menu-${task.id}'),
            onSelected: (action) => switch (action) {
              'complete' => _setStatus(context, ref, TaskStatus.completed),
              'reactivate' => _setStatus(context, ref, TaskStatus.active),
              'reminder' => _changeReminder(context, ref),
              'deadline' => _changeDeadline(context, ref),
              'rule' => _changeCompletionRule(context, ref),
              'archive' => _setStatus(context, ref, TaskStatus.archived),
              'delete' => _delete(context, ref),
              _ => Future<void>.value(),
            },
            itemBuilder: (context) => [
              if (task.status == TaskStatus.active)
                const PopupMenuItem(
                  value: 'complete',
                  child: Text('Mark completed'),
                )
              else
                const PopupMenuItem(
                  value: 'reactivate',
                  child: Text('Reactivate'),
                ),
              if (task.status == TaskStatus.active) ...const [
                PopupMenuItem(
                  value: 'reminder',
                  child: Text('Change reminder time'),
                ),
                PopupMenuItem(
                  value: 'deadline',
                  child: Text('Change deadline'),
                ),
                PopupMenuItem(
                  value: 'rule',
                  child: Text('Completion rule'),
                ),
              ],
              const PopupMenuItem(value: 'archive', child: Text('Archive')),
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
    );
  }
}
