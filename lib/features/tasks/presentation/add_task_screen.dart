import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/utils/date_utils.dart';
import '../../settings/providers.dart';
import '../providers.dart';

class AddTaskScreen extends ConsumerStatefulWidget {
  const AddTaskScreen({super.key});

  @override
  ConsumerState<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends ConsumerState<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _category = TextEditingController();
  late final _duration = TextEditingController(
    text: (ref.read(appSettingsProvider).value?.defaultDurationDays ?? 21)
        .toString(),
  );
  late DateTime _startDate = ref.read(currentDateProvider);
  TimeOfDay? _reminder;
  bool _busy = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _category.dispose();
    _duration.dispose();
    super.dispose();
  }

  String? _trimmedOrNull(TextEditingController controller) {
    final text = controller.text.trim();
    return text.isEmpty ? null : text;
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
      await repo.create(
        title: _title.text.trim(),
        description: _trimmedOrNull(_description),
        category: _trimmedOrNull(_category),
        startDate: toDateKey(_startDate),
        durationDays: int.parse(_duration.text.trim()),
        reminderTime: _reminder == null
            ? null
            : '${_reminder!.hour.toString().padLeft(2, '0')}:'
                '${_reminder!.minute.toString().padLeft(2, '0')}',
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
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextFormField(
                  key: const Key('task-title'),
                  controller: _title,
                  decoration: const InputDecoration(
                    labelText: 'Title *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Enter a title' : null,
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
                TextFormField(
                  key: const Key('task-category'),
                  controller: _category,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
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
                ListTile(
                  key: const Key('task-reminder'),
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.alarm),
                  title: const Text('Reminder time'),
                  subtitle: Text(
                    _reminder == null
                        ? 'None (uses the global default once reminders ship)'
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
    );
  }
}
