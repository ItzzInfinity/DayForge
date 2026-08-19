import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/utils/date_utils.dart';
import '../../settings/providers.dart';
import '../domain/recurrence.dart';
import '../domain/rollover.dart';
import '../domain/task.dart';
import '../providers.dart';

class AddTaskScreen extends ConsumerStatefulWidget {
  const AddTaskScreen({super.key});

  @override
  ConsumerState<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends ConsumerState<AddTaskScreen> {
  /// Offered on every new task; the user can add their own beside these.
  static const suggestedCategories = [
    'Learning',
    'Skill',
    'Habit',
    'Health',
    'Fitness',
    'Work',
    'Personal',
  ];

  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _category = TextEditingController();
  final Set<String> _selectedCategories = {};
  final List<String> _customCategories = [];
  late final _duration = TextEditingController(
    text: (ref.read(appSettingsProvider).value?.defaultDurationDays ?? 21)
        .toString(),
  );
  late DateTime _startDate = ref.read(currentDateProvider);
  TimeOfDay? _reminder;
  bool _busy = false;

  CompletionMode _completionMode = CompletionMode.fixedWindow;

  /// Intraday state — only read when [_repeatsIntraday] is true.
  bool _repeatsIntraday = false;
  TimeOfDay _windowStart = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _windowEnd = const TimeOfDay(hour: 20, minute: 0);
  int _intervalMinutes = 90;
  final _target = TextEditingController();

  /// Two ways to say the same schedule. Some habits are naturally a gap
  /// ("every 90 minutes"), others a count ("8 glasses"), and forcing the
  /// second through the first is arithmetic the user should not be doing.
  /// [_byCount] picks which control is shown; the stored recurrence is an
  /// interval either way.
  bool _byCount = false;
  int _repsPerDay = 8;

  /// Intervals offered for "remind me every…".
  static const intervalChoices = [15, 30, 45, 60, 90, 120, 180, 240];

  static String _hhmm(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}';

  /// Minutes between the window's ends; 0 or less when it is misconfigured.
  int get _windowMinutes =>
      (_windowEnd.hour * 60 + _windowEnd.minute) -
      (_windowStart.hour * 60 + _windowStart.minute);

  /// The gap the schedule actually uses: the one picked, or the one that
  /// fits the requested number of repetitions into the window.
  int get _effectiveInterval => _byCount
      ? Recurrence.intervalForOccurrences(
          windowMinutes: _windowMinutes,
          occurrences: _repsPerDay,
        )
      : _intervalMinutes;

  /// The recurrence the form currently describes.
  Recurrence get _recurrence => _repeatsIntraday
      ? Recurrence.intraday(
          startTime: _hhmm(_windowStart),
          endTime: _hhmm(_windowEnd),
          intervalMinutes: _effectiveInterval,
          targetPerDay: int.tryParse(_target.text.trim()),
        )
      : const Recurrence.daily();

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _category.dispose();
    _duration.dispose();
    _target.dispose();
    super.dispose();
  }

  String? _trimmedOrNull(TextEditingController controller) {
    final text = controller.text.trim();
    return text.isEmpty ? null : text;
  }

  /// Everything the chips row offers: the built-in suggestions, categories
  /// already used on the user's other tasks, and this form's custom adds.
  List<String> _allCategories() {
    final existing = {
      for (final task in ref.read(tasksProvider).value ?? const <Task>[])
        ...task.categories,
    };
    final seen = <String>{};
    return [
      for (final c in [
        ...suggestedCategories,
        ...existing.toList()..sort(),
        ..._customCategories,
      ])
        if (seen.add(c)) c,
    ];
  }

  void _addCustomCategory({bool select = true}) {
    final text = _category.text.trim();
    if (text.isEmpty) return;
    // Match an existing chip case-insensitively instead of duplicating it.
    final existing = _allCategories().where(
      (c) => c.toLowerCase() == text.toLowerCase(),
    );
    final name = existing.isEmpty ? text : existing.first;
    setState(() {
      if (existing.isEmpty) _customCategories.add(name);
      if (select) _selectedCategories.add(name);
      _category.clear();
    });
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _pickWindowTime({required bool start}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: start ? _windowStart : _windowEnd,
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        _windowStart = picked;
      } else {
        _windowEnd = picked;
      }
    });
  }

  Future<void> _pickReminder() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminder ?? const TimeOfDay(hour: 8, minute: 0),
    );
    if (picked != null) setState(() => _reminder = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final repo = ref.read(taskRepositoryProvider);
    if (repo == null) return;
    setState(() => _busy = true);
    try {
      // A typed-but-not-added custom category still counts: pressing Create
      // without hitting "+" should not silently drop it.
      _addCustomCategory(select: true);
      await repo.create(
        title: _title.text.trim(),
        description: _trimmedOrNull(_description),
        categories: [
          for (final c in _allCategories())
            if (_selectedCategories.contains(c)) c,
        ],
        startDate: toDateKey(_startDate),
        durationDays: int.parse(_duration.text.trim()),
        reminderTime: _reminder == null ? null : _hhmm(_reminder!),
        recurrence: _recurrence,
        completionMode: _completionMode,
      );
      // The task list stream re-reads on resubscribe; refresh it now so the
      // new task shows immediately even on the polling (Linux) gateway.
      ref.invalidate(tasksProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save the task. Try again.')),
        );
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New task')),
      body: Form(
        key: _formKey,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            // Not a lazy ListView: a Form must keep every field mounted, or
            // validators on fields scrolled out of view silently stop
            // running.
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    key: const Key('task-title'),
                    controller: _title,
                    decoration: const InputDecoration(
                      labelText: 'Title *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Enter a title'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('task-description'),
                    controller: _description,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Categories',
                      helperText: 'Pick one or more, or add your own below',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.all(12),
                    ),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        for (final category in _allCategories())
                          FilterChip(
                            key: Key('cat-$category'),
                            label: Text(category),
                            selected: _selectedCategories.contains(category),
                            onSelected: (selected) => setState(
                              () => selected
                                  ? _selectedCategories.add(category)
                                  : _selectedCategories.remove(category),
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    key: const Key('task-category'),
                    controller: _category,
                    decoration: InputDecoration(
                      labelText: 'Add your own category',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        key: const Key('add-category'),
                        icon: const Icon(Icons.add),
                        tooltip: 'Add category',
                        onPressed: _addCustomCategory,
                      ),
                    ),
                    onFieldSubmitted: (_) => _addCustomCategory(),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('task-duration'),
                    controller: _duration,
                    decoration: const InputDecoration(
                      labelText: 'Duration (days) *',
                      helperText: 'How many days this task should continue',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final days = int.tryParse((v ?? '').trim());
                      if (days == null || days < 1) {
                        return 'Enter a number of days (1 or more)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    key: const Key('task-start-date'),
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Start date'),
                    subtitle: Text(toDateKey(_startDate)),
                    onTap: _pickStartDate,
                  ),
                  const SizedBox(height: 8),
                  InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Completion rule',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.all(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        RadioGroup<CompletionMode>(
                          groupValue: _completionMode,
                          onChanged: (mode) => setState(() =>
                              _completionMode = mode ?? _completionMode),
                          child: const Column(
                            children: [
                              RadioListTile<CompletionMode>(
                                key: Key('rule-fixedWindow'),
                                value: CompletionMode.fixedWindow,
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                title: Text('Fixed window'),
                                subtitle: Text(
                                    'Ends on the end date, whatever happens'),
                              ),
                              RadioListTile<CompletionMode>(
                                key: Key('rule-targetDays'),
                                value: CompletionMode.targetDays,
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                title: Text('Target days'),
                                subtitle: Text('Runs until that many days are '
                                    'actually completed — missed days move '
                                    'the end date forward'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Repeat',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.all(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SegmentedButton<bool>(
                          key: const Key('task-repeat'),
                          segments: const [
                            ButtonSegment(
                              value: false,
                              label: Text('Once a day'),
                              icon: Icon(Icons.today),
                            ),
                            ButtonSegment(
                              value: true,
                              label: Text('Many times a day'),
                              icon: Icon(Icons.repeat),
                            ),
                          ],
                          selected: {_repeatsIntraday},
                          onSelectionChanged: (selection) => setState(
                            () => _repeatsIntraday = selection.first,
                          ),
                        ),
                        if (_repeatsIntraday) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: ListTile(
                                  key: const Key('task-window-start'),
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text('From'),
                                  subtitle: Text(_hhmm(_windowStart)),
                                  onTap: () => _pickWindowTime(start: true),
                                ),
                              ),
                              Expanded(
                                child: ListTile(
                                  key: const Key('task-window-end'),
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text('Until'),
                                  subtitle: Text(_hhmm(_windowEnd)),
                                  onTap: () => _pickWindowTime(start: false),
                                ),
                              ),
                            ],
                          ),
                          SegmentedButton<bool>(
                            key: const Key('task-repeat-by'),
                            segments: const [
                              ButtonSegment(
                                value: false,
                                label: Text('Every…'),
                                icon: Icon(Icons.timelapse),
                              ),
                              ButtonSegment(
                                value: true,
                                label: Text('N times a day'),
                                icon: Icon(Icons.tag),
                              ),
                            ],
                            selected: {_byCount},
                            onSelectionChanged: (selection) =>
                                setState(() => _byCount = selection.first),
                          ),
                          const SizedBox(height: 8),
                          if (_byCount)
                            DropdownButtonFormField<int>(
                              key: const Key('task-reps'),
                              initialValue: _repsPerDay,
                              decoration: const InputDecoration(
                                labelText: 'Times a day',
                                helperText:
                                    'Spread evenly across the window above',
                                border: OutlineInputBorder(),
                              ),
                              items: [
                                for (var n = 1;
                                    n <= Recurrence.maxOccurrencesPerDay;
                                    n++)
                                  DropdownMenuItem(
                                    value: n,
                                    child: Text('$n× a day'),
                                  ),
                              ],
                              onChanged: (v) => setState(
                                () => _repsPerDay = v ?? _repsPerDay,
                              ),
                            )
                          else
                            DropdownButtonFormField<int>(
                              key: const Key('task-interval'),
                              initialValue: _intervalMinutes,
                              decoration: const InputDecoration(
                                labelText: 'Remind me every',
                                border: OutlineInputBorder(),
                              ),
                              items: [
                                for (final minutes in intervalChoices)
                                  DropdownMenuItem(
                                    value: minutes,
                                    child: Text(
                                      minutes < 60
                                          ? '$minutes minutes'
                                          : minutes % 60 == 0
                                          ? '${minutes ~/ 60} hour'
                                                '${minutes == 60 ? '' : 's'}'
                                          : '${minutes ~/ 60}h '
                                                '${minutes % 60}m',
                                    ),
                                  ),
                              ],
                              onChanged: (v) => setState(
                                () => _intervalMinutes = v ?? _intervalMinutes,
                              ),
                            ),
                          const SizedBox(height: 8),
                          TextFormField(
                            key: const Key('task-target'),
                            controller: _target,
                            decoration: InputDecoration(
                              labelText: 'Ticks needed per day',
                              helperText:
                                  'Leave empty for the majority rule: '
                                  '${Recurrence.majorityTarget(_recurrence.occurrencesPerDay)}'
                                  ' of ${_recurrence.occurrencesPerDay} '
                                  'completes the day. Set '
                                  '${_recurrence.occurrencesPerDay} to '
                                  'require them all.',
                              border: const OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                            validator: (v) {
                              final text = (v ?? '').trim();
                              if (text.isEmpty) return null;
                              final target = int.tryParse(text);
                              if (target == null || target < 1) {
                                return 'Enter a number (1 or more)';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _recurrence.summary,
                            key: const Key('task-repeat-summary'),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Intraday tasks take their times from the window above.
                  if (!_repeatsIntraday)
                    ListTile(
                      key: const Key('task-reminder'),
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.alarm),
                      title: const Text('Reminder time'),
                      subtitle: Text(
                        _reminder == null
                            ? 'None (uses the default reminder time)'
                            : _reminder!.format(context),
                      ),
                      onTap: _pickReminder,
                    ),
                  const SizedBox(height: 16),
                  FilledButton(
                    key: const Key('task-submit'),
                    onPressed: _busy ? null : _submit,
                    child: _busy
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Create task'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
