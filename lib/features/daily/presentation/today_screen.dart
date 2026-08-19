import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/content_width.dart';
import '../../../core/widgets/error_retry.dart';
import '../../quotes/domain/quotes.dart';
import '../../quotes/providers.dart';
import '../../tasks/domain/task.dart';
import '../../tasks/presentation/add_task_fab.dart';
import '../../tasks/presentation/add_task_screen.dart';
import '../../tasks/providers.dart';
import '../domain/daily_log.dart';
import '../providers.dart';

class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  /// Completed tasks stay hidden behind the `^` toggle so the screen is
  /// about what's left (or the celebration once everything is done).
  bool _showCompleted = false;

  @override
  Widget build(BuildContext context) {
    final date = ref.watch(currentDateProvider);
    final dateKey = toDateKey(date);
    final tasksAsync = ref.watch(tasksProvider);

    final theme = Theme.of(context);
    return Scaffold(
      // Brand top-left: the app name with today's date tucked under it.
      appBar: AppBar(
        toolbarHeight: 68,
        centerTitle: false,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('DayForge', style: theme.textTheme.titleLarge),
            Text(
              'Today · $dateKey',
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
      floatingActionButton:
          const AddTaskFab(key: Key('add-task-today'), heroTag: 'fab-today'),
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
          // Ticked tasks sink below the pending ones so the focus stays on
          // what's left; a banner celebrates when everything is done.
          final logs = {
            for (final task in active)
              task.id: ref.watch(todayLogProvider(task.id)),
          };
          bool done(Task task) => logs[task.id]?.value?.completed ?? false;
          final pending = [
            for (final task in active)
              if (!done(task)) task
          ];
          final completed = [
            for (final task in active)
              if (done(task)) task
          ];
          final allDone = pending.isEmpty &&
              logs.values.every((log) => log.hasValue);

          final completedSection = <Widget>[
            if (completed.isNotEmpty)
              _CompletedHeader(
                count: completed.length,
                expanded: _showCompleted,
                onToggle: () =>
                    setState(() => _showCompleted = !_showCompleted),
              ),
            if (_showCompleted)
              for (final task in completed)
                _TodayCard(task: task, dateKey: dateKey),
          ];

          if (allDone) {
            // Everything ticked: celebrate front and centre; the completed
            // cards stay tucked behind the toggle.
            if (!_showCompleted) {
              return Column(
                children: [
                  const _DailyQuoteCard(),
                  const Expanded(
                    child: Center(
                      child: SingleChildScrollView(child: _AllDoneBanner()),
                    ),
                  ),
                  ...completedSection,
                  const SizedBox(height: 8),
                ],
              );
            }
            return ListView(
              padding: const EdgeInsets.all(8),
              children: [
                const _DailyQuoteCard(),
                const _AllDoneBanner(),
                ...completedSection,
              ],
            );
          }

          return ListView(
            padding: const EdgeInsets.all(8),
            children: [
              const _DailyQuoteCard(),
              for (final task in pending)
                _TodayCard(task: task, dateKey: dateKey),
              ...completedSection,
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

/// A fresh motivational quote each day from the bundled rotation.
class _DailyQuoteCard extends ConsumerWidget {
  const _DailyQuoteCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quote = ref.watch(dailyQuoteProvider);
    final theme = Theme.of(context);
    return Padding(
      key: const Key('daily-quote'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '“${quote.text}”',
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontStyle: FontStyle.italic),
          ),
          if (quote.author.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '— ${quote.author}',
                textAlign: TextAlign.right,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
        ],
      ),
    );
  }
}

/// Collapsible "Completed today (N)" row. Collapsed it shows `^` — tapping
/// reveals the ticked tasks; tapping again hides them.
class _CompletedHeader extends StatelessWidget {
  const _CompletedHeader({
    required this.count,
    required this.expanded,
    required this.onToggle,
  });

  final int count;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: const Key('completed-toggle'),
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Row(
          children: [
            Text(
              'Completed today ($count)',
              key: const Key('completed-header'),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const Spacer(),
            Icon(
              expanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown once every task active today is ticked — a small celebration so
/// finishing the day feels like something.
class _AllDoneBanner extends StatelessWidget {
  const _AllDoneBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TweenAnimationBuilder<double>(
      key: const Key('all-done-banner'),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (context, value, child) => Transform.scale(
        scale: 0.8 + 0.2 * value,
        child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        color: theme.colorScheme.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Text('🎉', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 8),
              Text(
                'All done for today!',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Every task is ticked. Enjoy the rest of your day — '
                'your streaks thank you.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
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
  late int _count = widget.log?.count ?? (_completed ? 1 : 0);
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
      if (value && mounted) {
        final quote = encouragementQuote();
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(
            content: Text('✓ ${quote.text}'
                '${quote.author.isEmpty ? '' : ' — ${quote.author}'}'),
          ));
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _completed = !value);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save. Try again.')),
      );
    }
  }

  /// Intraday tasks count ticks instead of flipping a checkbox: +1 per
  /// glass of water, and the day completes when the target is reached.
  Future<void> _tick(int delta) async {
    final target = widget.task.targetPerDay;
    final previous = _count;
    final optimistic = (_count + delta).clamp(0, target);
    setState(() {
      _count = optimistic;
      _completed = optimistic >= target;
    });
    final repo = ref.read(dailyLogRepositoryProvider);
    if (repo == null) return;
    try {
      await repo.addTick(widget.task.id, widget.dateKey,
          target: target, delta: delta);
      ref.invalidate(todayLogProvider(widget.task.id));
      ref.invalidate(taskLogsProvider(widget.task.id));
      if (delta > 0 && mounted) _showEncouragement();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _count = previous;
        _completed = previous >= target;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save. Try again.')),
      );
    }
  }

  void _showEncouragement() {
    final quote = encouragementQuote();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text('✓ ${quote.text}'
            '${quote.author.isEmpty ? '' : ' — ${quote.author}'}'),
      ));
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

  String get _subtitle =>
      'Day $_dayNumber of ${widget.task.durationDays}'
      '${widget.task.categoryLabel != null ? ' · ${widget.task.categoryLabel}' : ''}';

  /// Intraday tile: n/target with −1 and +1, and a check once the day's
  /// target is reached.
  Widget _counterTile(BuildContext context) {
    final theme = Theme.of(context);
    final target = widget.task.targetPerDay;
    return ListTile(
      key: ValueKey('counter-${widget.task.id}'),
      leading: Icon(
        _completed ? Icons.check_circle : Icons.repeat,
        color: _completed ? theme.colorScheme.primary : null,
      ),
      title: Text(widget.task.title),
      subtitle: Text('$_subtitle · ${widget.task.recurrence.summary}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            key: ValueKey('untick-${widget.task.id}'),
            icon: const Icon(Icons.remove),
            tooltip: 'Undo one',
            onPressed: _count == 0 ? null : () => _tick(-1),
          ),
          Text(
            '$_count/$target',
            key: ValueKey('count-${widget.task.id}'),
            style: theme.textTheme.titleMedium,
          ),
          IconButton(
            key: ValueKey('tick-${widget.task.id}'),
            icon: const Icon(Icons.add),
            tooltip: 'Record one',
            onPressed: _count >= target ? null : () => _tick(1),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.task.recurrence.isIntraday)
          _counterTile(context)
        else
          CheckboxListTile(
            key: ValueKey('tick-${widget.task.id}'),
            value: _completed,
            onChanged: (v) => _toggle(v ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(widget.task.title),
            subtitle: Text(_subtitle),
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
