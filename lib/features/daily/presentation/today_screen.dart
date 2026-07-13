import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/content_width.dart';
import '../../../core/widgets/error_retry.dart';
import '../../tasks/domain/task.dart';
import '../../tasks/presentation/add_task_screen.dart';
import '../../tasks/providers.dart';
import '../domain/daily_log.dart';
import '../providers.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(currentDateProvider);
    final dateKey = toDateKey(date);
    final tasksAsync = ref.watch(tasksProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Today · $dateKey')),
      body: ContentWidth(
          child: tasksAsync.when(
        data: (tasks) {
          if (tasks.isEmpty) return const _OnboardingEmpty();
          final active = [
            for (final task in tasks)
              if (task.isActiveOn(date)) task
          ];
          if (active.isEmpty) {
            return const Center(
              child: Text(
                'Nothing scheduled for today.\n'
                'Your tasks have ended, start later, or are paused — '
                'see the Tasks tab.',
                textAlign: TextAlign.center,
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(8),
            children: [
              for (final task in active)
                _TodayCard(task: task, dateKey: dateKey),
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

/// First-run experience: a brand-new account lands here, so this is where
/// the core loop gets explained.
class _OnboardingEmpty extends StatelessWidget {
  const _OnboardingEmpty();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.flag_outlined,
                size: 48, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text('Build a habit in three steps',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            for (final step in const [
              '1.  Add a task and choose how many days it should run.',
              '2.  Tick it off here every day — with an optional note.',
              '3.  Watch your streak grow on the Progress tab.',
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(step,
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center),
              ),
            const SizedBox(height: 16),
            FilledButton.icon(
              key: const Key('onboarding-add-task'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                    builder: (_) => const AddTaskScreen()),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Add your first task'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayCard extends ConsumerWidget {
  const _TodayCard({required this.task, required this.dateKey});

  final Task task;
  final String dateKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logAsync = ref.watch(todayLogProvider(task.id));
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: logAsync.when(
        data: (log) => _TodayEntry(
          // Stable per task+day so typing state survives provider refreshes.
          key: ValueKey('entry-${task.id}-$dateKey'),
          task: task,
          dateKey: dateKey,
          log: log,
        ),
        loading: () => ListTile(
          title: Text(task.title),
          trailing: const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        error: (error, _) => ListTile(
          title: Text(task.title),
          subtitle: Text(
              'Could not load today\'s entry. ${friendlyError(error)}'),
          trailing: IconButton(
            key: ValueKey('retry-log-${task.id}'),
            icon: const Icon(Icons.refresh),
            tooltip: 'Retry',
            onPressed: () => ref.invalidate(todayLogProvider(task.id)),
          ),
        ),
      ),
    );
  }
}

class _TodayEntry extends ConsumerStatefulWidget {
  const _TodayEntry({
    super.key,
    required this.task,
    required this.dateKey,
    required this.log,
  });

  final Task task;
  final String dateKey;
  final DailyLog? log;

  @override
  ConsumerState<_TodayEntry> createState() => _TodayEntryState();
}

class _TodayEntryState extends ConsumerState<_TodayEntry> {
  late bool _completed = widget.log?.completed ?? false;
  late final TextEditingController _remark =
      TextEditingController(text: widget.log?.remark ?? '');
  late String _savedRemark = widget.log?.remark ?? '';

  @override
  void dispose() {
    _remark.dispose();
    super.dispose();
  }

  int get _dayNumber =>
      fromDateKey(widget.dateKey)
          .difference(fromDateKey(widget.task.startDate))
          .inDays +
      1;

  Future<void> _toggle(bool value) async {
    setState(() => _completed = value);
    final repo = ref.read(dailyLogRepositoryProvider);
    if (repo == null) return;
    try {
      await repo.setCompleted(widget.task.id, widget.dateKey,
          completed: value);
      ref.invalidate(todayLogProvider(widget.task.id));
      ref.invalidate(taskLogsProvider(widget.task.id));
    } catch (_) {
      if (!mounted) return;
      setState(() => _completed = !value);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save. Try again.')),
      );
    }
  }

  Future<void> _saveRemark() async {
    final text = _remark.text.trim();
    if (text == _savedRemark) return;
    final repo = ref.read(dailyLogRepositoryProvider);
    if (repo == null) return;
    try {
      await repo.setRemark(widget.task.id, widget.dateKey, text);
      _savedRemark = text;
      ref.invalidate(todayLogProvider(widget.task.id));
      ref.invalidate(taskLogsProvider(widget.task.id));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save the remark. Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CheckboxListTile(
          key: ValueKey('tick-${widget.task.id}'),
          value: _completed,
          onChanged: (v) => _toggle(v ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          title: Text(widget.task.title),
          subtitle: Text(
            'Day $_dayNumber of ${widget.task.durationDays}'
            '${widget.task.category != null ? ' · ${widget.task.category}' : ''}',
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Focus(
            onFocusChange: (focused) {
              if (!focused) _saveRemark();
            },
            child: TextField(
              key: ValueKey('remark-${widget.task.id}'),
              controller: _remark,
              decoration: const InputDecoration(
                hintText: 'Optional note for today (how did it go?)',
                isDense: true,
                border: UnderlineInputBorder(),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _saveRemark(),
            ),
          ),
        ),
      ],
    );
  }
}
