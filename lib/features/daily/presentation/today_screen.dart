import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/utils/date_utils.dart';
import '../../tasks/domain/task.dart';
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
      body: tasksAsync.when(
        data: (tasks) {
          final active = [
            for (final task in tasks)
              if (task.isActiveOn(date)) task
          ];
          if (active.isEmpty) {
            return const Center(
              child: Text(
                'Nothing scheduled for today.\nAdd a task from the Tasks tab.',
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
        error: (error, _) =>
            Center(child: Text('Could not load tasks: $error')),
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
          subtitle: Text('Could not load today\'s log: $error'),
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
                hintText: 'Add a remark for today…',
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
