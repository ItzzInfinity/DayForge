import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers.dart';
import '../core/widgets/error_retry.dart';
import '../features/auth/presentation/sign_in_screen.dart';
import '../features/auth/providers.dart';
import '../features/settings/domain/app_settings.dart';
import '../features/settings/providers.dart';
import '../features/tasks/providers.dart';
import '../services/notifications/providers.dart';
import 'home_shell.dart';
import 'theme.dart';

class AdvancedTodoApp extends ConsumerWidget {
  const AdvancedTodoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = switch (ref.watch(appSettingsProvider).value?.themeMode) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    return MaterialApp(
      title: 'Advanced To-Do',
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: themeMode,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // First sign-in creates the users/{uid} profile doc. Fire-and-forget:
    // offline failures are fine, it retries on the next sign-in event.
    ref.listen(authStateProvider, (previous, next) {
      final user = next.value;
      if (user != null && previous?.value == null) {
        ref
            .read(profileRepositoryProvider)
            .ensureProfile(user)
            .catchError((Object e) => debugPrint('profile sync failed: $e'));
      }
    });
    // Keep OS reminders matching the task list and notification settings
    // (initial load and every change). Fire-and-forget; a failed sync
    // self-heals on the next one.
    Future<void> syncReminders() async {
      final tasks = ref.read(tasksProvider).value;
      if (tasks == null) return;
      final settings =
          ref.read(appSettingsProvider).value ?? const AppSettings();
      final scheduler = ref.read(reminderSchedulerProvider);
      await scheduler.requestPermission();
      await scheduler.sync(
        settings.notificationsEnabled ? tasks : const [],
        ref.read(currentDateProvider),
        defaultTime: settings.defaultReminderTime,
      );
    }

    void onChange(Object? previous, Object? next) {
      syncReminders()
          .catchError((Object e) => debugPrint('reminder sync failed: $e'));
    }

    ref.listen(tasksProvider, onChange);
    ref.listen(appSettingsProvider, onChange);
    final authState = ref.watch(authStateProvider);
    return authState.when(
      data: (user) =>
          user == null ? const SignInScreen() : const HomeShell(),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        body: ErrorRetry(
          message: 'Could not load your session.',
          error: error,
          onRetry: () => ref.invalidate(authStateProvider),
        ),
      ),
    );
  }
}
