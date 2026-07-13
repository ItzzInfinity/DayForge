import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/notifications/providers.dart';
import '../../../services/notifications/reminder_scheduler.dart';
import '../../auth/providers.dart';
import '../domain/app_settings.dart';
import '../providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _update(
    WidgetRef ref,
    AppSettings Function(AppSettings) change,
  ) async {
    final repo = ref.read(settingsRepositoryProvider);
    if (repo == null) return;
    final current = ref.read(appSettingsProvider).value ?? const AppSettings();
    await repo.save(change(current));
    ref.invalidate(appSettingsProvider);
  }

  Future<void> _pickDefaultReminderTime(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
  ) async {
    final parts = parseHhMm(settings.defaultReminderTime);
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: parts.hour, minute: parts.minute),
    );
    if (picked == null) return;
    final formatted = '${picked.hour.toString().padLeft(2, '0')}:'
        '${picked.minute.toString().padLeft(2, '0')}';
    await _update(ref, (s) => s.copyWith(defaultReminderTime: formatted));
  }

  Future<void> _pickDefaultDuration(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
  ) async {
    final controller =
        TextEditingController(text: settings.defaultDurationDays.toString());
    final days = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Default task duration'),
        content: TextField(
          key: const Key('default-duration-field'),
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(suffixText: 'days'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('default-duration-save'),
            onPressed: () =>
                Navigator.of(context).pop(int.tryParse(controller.text.trim())),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (days == null || days < 1) return;
    await _update(ref, (s) => s.copyWith(defaultDurationDays: days));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final settings =
        ref.watch(appSettingsProvider).value ?? const AppSettings();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.account_circle),
            title: Text(user?.email ?? 'Not signed in'),
            subtitle: const Text('Signed-in account'),
          ),
          const Divider(),
          SwitchListTile(
            key: const Key('notifications-enabled'),
            secondary: const Icon(Icons.notifications_outlined),
            title: const Text('Daily reminders'),
            subtitle: const Text('Notify me to tick my tasks'),
            value: settings.notificationsEnabled,
            onChanged: (v) =>
                _update(ref, (s) => s.copyWith(notificationsEnabled: v)),
          ),
          ListTile(
            key: const Key('default-reminder-time'),
            enabled: settings.notificationsEnabled,
            leading: const Icon(Icons.alarm),
            title: const Text('Default reminder time'),
            subtitle: Text(settings.defaultReminderTime),
            onTap: () => _pickDefaultReminderTime(context, ref, settings),
          ),
          ListTile(
            key: const Key('default-duration'),
            leading: const Icon(Icons.event_repeat),
            title: const Text('Default task duration'),
            subtitle: Text('${settings.defaultDurationDays} days'),
            onTap: () => _pickDefaultDuration(context, ref, settings),
          ),
          ListTile(
            leading: const Icon(Icons.brightness_6_outlined),
            title: const Text('Theme'),
            trailing: DropdownButton<String>(
              key: const Key('theme-mode'),
              value: settings.themeMode,
              onChanged: (v) {
                if (v != null) _update(ref, (s) => s.copyWith(themeMode: v));
              },
              items: const [
                DropdownMenuItem(value: 'system', child: Text('System')),
                DropdownMenuItem(value: 'light', child: Text('Light')),
                DropdownMenuItem(value: 'dark', child: Text('Dark')),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            key: const Key('test-notification'),
            leading: const Icon(Icons.notifications_active_outlined),
            title: const Text('Send test notification'),
            subtitle: const Text(
                'Fires one immediately so you can confirm they work here'),
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              try {
                await ref.read(reminderSchedulerProvider).showNow(
                      title: 'Advanced To-Do',
                      body: 'Test notification — reminders can reach you '
                          'on this device.',
                    );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Could not send: $e')),
                );
              }
            },
          ),
          const Divider(),
          ListTile(
            key: const Key('sign-out'),
            leading: const Icon(Icons.logout),
            title: const Text('Sign out'),
            onTap: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
    );
  }
}
