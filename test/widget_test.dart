import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:advanced_todo/app/app.dart';
import 'package:advanced_todo/features/auth/domain/app_user.dart';
import 'package:advanced_todo/features/auth/domain/auth_repository.dart';
import 'package:advanced_todo/core/providers.dart';
import 'package:advanced_todo/features/auth/providers.dart';
import 'package:advanced_todo/services/firestore/providers.dart';
import 'package:advanced_todo/services/notifications/providers.dart';

import 'helpers/fakes.dart';

Widget appWith(
  AuthRepository repo, {
  FakeFirestoreGateway? gateway,
  FakeReminderScheduler? scheduler,
}) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(repo),
      firestoreGatewayProvider.overrideWithValue(
        gateway ?? FakeFirestoreGateway(),
      ),
      reminderSchedulerProvider.overrideWithValue(
        scheduler ?? FakeReminderScheduler(),
      ),
      currentDateProvider.overrideWithValue(DateTime(2026, 7, 13)),
    ],
    child: const AdvancedTodoApp(),
  );
}

void main() {
  testWidgets('signed out: shows the sign-in screen', (tester) async {
    await tester.pumpWidget(appWith(FakeAuthRepository()));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('email')), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });

  testWidgets(
      'signing in navigates to Today and creates the profile document',
      (tester) async {
    final gateway = FakeFirestoreGateway();
    await tester.pumpWidget(appWith(FakeAuthRepository(), gateway: gateway));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('email')), 'a@b.com');
    await tester.enterText(find.byKey(const Key('password')), 'secret1');
    await tester.tap(find.byKey(const Key('submit')));
    await tester.pumpAndSettle();

    expect(find.text('Today · 2026-07-13'), findsOneWidget);
    expect(gateway.docs['users/test-uid']?['email'], 'a@b.com');
  });

  testWidgets('already signed in: goes straight to Today; sign-out returns',
      (tester) async {
    final repo =
        FakeAuthRepository(initialUser: const AppUser(uid: 'u', email: 'a@b.com'));
    await tester.pumpWidget(appWith(repo));
    await tester.pumpAndSettle();

    expect(find.text('Today · 2026-07-13'), findsOneWidget);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('a@b.com'), findsOneWidget);

    await tester.tap(find.byKey(const Key('sign-out')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('email')), findsOneWidget);
  });

  testWidgets('all navigation destinations reach their screens',
      (tester) async {
    final repo =
        FakeAuthRepository(initialUser: const AppUser(uid: 'u', email: 'a@b.com'));
    await tester.pumpWidget(appWith(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tasks'));
    await tester.pumpAndSettle();
    expect(find.textContaining('No tasks yet'), findsOneWidget);

    await tester.tap(find.text('Progress'));
    await tester.pumpAndSettle();
    expect(find.textContaining('No tasks to track yet'), findsOneWidget);

    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();
    expect(find.text('Today · 2026-07-13'), findsOneWidget);
  });

  testWidgets('add-task flow: form creates a task that shows in the list',
      (tester) async {
    final repo =
        FakeAuthRepository(initialUser: const AppUser(uid: 'u', email: 'a@b.com'));
    final gateway = FakeFirestoreGateway();
    await tester.pumpWidget(appWith(repo, gateway: gateway));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tasks'));
    await tester.pumpAndSettle();
    expect(find.textContaining('No tasks yet'), findsOneWidget);

    await tester.tap(find.byKey(const Key('add-task')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('task-title')), 'Meditate');
    await tester.enterText(find.byKey(const Key('task-duration')), '7');
    await tester.tap(find.byKey(const Key('task-submit')));
    await tester.pumpAndSettle();

    // Back on the Tasks tab with the new task listed.
    expect(find.text('Meditate'), findsOneWidget);
    expect(find.textContaining('2026-07-13 → 2026-07-19 · 7 days'),
        findsOneWidget);

    // And it was persisted under the signed-in user (the gateway also
    // holds the users/u profile doc created on sign-in).
    final taskDoc = gateway.docs.entries
        .singleWhere((e) => e.key.startsWith('users/u/tasks/'));
    expect(taskDoc.value['title'], 'Meditate');
    expect(taskDoc.value['durationDays'], 7);
  });

  testWidgets('creating a task re-syncs reminders with the new task',
      (tester) async {
    final repo =
        FakeAuthRepository(initialUser: const AppUser(uid: 'u', email: 'a@b.com'));
    final scheduler = FakeReminderScheduler();
    await tester.pumpWidget(appWith(repo, scheduler: scheduler));
    await tester.pumpAndSettle();

    // Initial task-list load triggers a sync (empty list).
    expect(scheduler.syncedTaskLists, isNotEmpty);
    expect(scheduler.syncedTaskLists.last, isEmpty);
    expect(scheduler.permissionRequests, greaterThan(0));

    await tester.tap(find.text('Tasks'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-task')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('task-title')), 'Stretch');
    await tester.tap(find.byKey(const Key('task-submit')));
    await tester.pumpAndSettle();

    expect(scheduler.syncedTaskLists.last.map((t) => t.title), ['Stretch']);
  });

  group('Settings preferences', () {
    testWidgets(
        'toggling reminders off persists and cancels scheduled reminders',
        (tester) async {
      final repo = FakeAuthRepository(
          initialUser: const AppUser(uid: 'u', email: 'a@b.com'));
      final gateway = FakeFirestoreGateway();
      gateway.docs['users/u/tasks/t1'] = {
        'title': 'Meditate',
        'startDate': '2026-07-13',
        'durationDays': 7,
        'status': 'active',
        'createdAt': DateTime.utc(2026, 7, 1),
        'updatedAt': DateTime.utc(2026, 7, 1),
      };
      final scheduler = FakeReminderScheduler();
      await tester
          .pumpWidget(appWith(repo, gateway: gateway, scheduler: scheduler));
      await tester.pumpAndSettle();

      // Initial sync includes the active task.
      expect(scheduler.syncedTaskLists.last, hasLength(1));

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('notifications-enabled')));
      await tester.pumpAndSettle();

      expect(
          gateway.docs['users/u/settings/app']?['notificationsEnabled'], false);
      expect(scheduler.syncedTaskLists.last, isEmpty);
    });

    testWidgets('theme mode selection applies to MaterialApp and persists',
        (tester) async {
      final repo = FakeAuthRepository(
          initialUser: const AppUser(uid: 'u', email: 'a@b.com'));
      final gateway = FakeFirestoreGateway();
      await tester.pumpWidget(appWith(repo, gateway: gateway));
      await tester.pumpAndSettle();

      MaterialApp app() => tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app().themeMode, ThemeMode.system);

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('theme-mode')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dark').last);
      await tester.pumpAndSettle();

      expect(gateway.docs['users/u/settings/app']?['themeMode'], 'dark');
      expect(app().themeMode, ThemeMode.dark);
    });

    testWidgets('saved default duration pre-fills the add-task form',
        (tester) async {
      final repo = FakeAuthRepository(
          initialUser: const AppUser(uid: 'u', email: 'a@b.com'));
      final gateway = FakeFirestoreGateway();
      gateway.docs['users/u/settings/app'] = {
        'defaultDurationDays': 30,
        'defaultReminderTime': '08:00',
        'notificationsEnabled': true,
        'themeMode': 'system',
      };
      await tester.pumpWidget(appWith(repo, gateway: gateway));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tasks'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('add-task')));
      await tester.pumpAndSettle();

      final field = tester.widget<TextFormField>(
          find.byKey(const Key('task-duration')));
      expect(field.controller!.text, '30');
    });
  });

  testWidgets('settings test-notification tile fires an immediate one',
      (tester) async {
    final repo =
        FakeAuthRepository(initialUser: const AppUser(uid: 'u', email: 'a@b.com'));
    final scheduler = FakeReminderScheduler();
    await tester.pumpWidget(appWith(repo, scheduler: scheduler));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('test-notification')));
    await tester.pumpAndSettle();

    expect(scheduler.shownNow, hasLength(1));
    expect(scheduler.shownNow.single, contains('Test notification'));
  });

  testWidgets('add-task form rejects a missing title and bad duration',
      (tester) async {
    final repo =
        FakeAuthRepository(initialUser: const AppUser(uid: 'u', email: 'a@b.com'));
    await tester.pumpWidget(appWith(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tasks'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-task')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('task-duration')), '0');
    await tester.tap(find.byKey(const Key('task-submit')));
    await tester.pumpAndSettle();

    expect(find.text('Enter a title'), findsOneWidget);
    expect(find.text('Enter a number of days (1 or more)'), findsOneWidget);
  });

  group('Today screen', () {
    Map<String, dynamic> seedTask(String title, String startDate, int days) =>
        {
          'title': title,
          'description': null,
          'category': null,
          'startDate': startDate,
          'durationDays': days,
          'reminderTime': null,
          'status': 'active',
          'createdAt': DateTime.utc(2026, 7, 1),
          'updatedAt': DateTime.utc(2026, 7, 1),
        };

    late FakeFirestoreGateway gateway;

    setUp(() {
      gateway = FakeFirestoreGateway();
      gateway.docs['users/u/tasks/t1'] =
          seedTask('Meditate', '2026-07-13', 7);
      gateway.docs['users/u/tasks/t2'] =
          seedTask('Future task', '2026-08-01', 7);
    });

    Future<void> pumpSignedIn(WidgetTester tester) async {
      final repo = FakeAuthRepository(
          initialUser: const AppUser(uid: 'u', email: 'a@b.com'));
      await tester.pumpWidget(appWith(repo, gateway: gateway));
      await tester.pumpAndSettle();
    }

    testWidgets('lists only tasks active today', (tester) async {
      await pumpSignedIn(tester);

      expect(find.text('Meditate'), findsOneWidget);
      expect(find.text('Day 1 of 7'), findsOneWidget);
      expect(find.text('Future task'), findsNothing);
    });

    testWidgets('ticking the checkbox persists the daily log',
        (tester) async {
      await pumpSignedIn(tester);

      await tester.tap(find.byKey(const ValueKey('tick-t1')));
      await tester.pumpAndSettle();

      final log = gateway.docs['users/u/tasks/t1/daily_logs/2026-07-13'];
      expect(log, isNotNull);
      expect(log!['completed'], isTrue);
      expect(log['completedAt'], isNotNull);

      // Unticking clears completedAt but keeps the doc. (Re-read: the fake
      // gateway replaces the stored map on every merge write.)
      await tester.tap(find.byKey(const ValueKey('tick-t1')));
      await tester.pumpAndSettle();
      final unticked =
          gateway.docs['users/u/tasks/t1/daily_logs/2026-07-13'];
      expect(unticked!['completed'], isFalse);
      expect(unticked['completedAt'], isNull);
      expect(unticked['date'], '2026-07-13');
    });

    testWidgets('submitting a remark persists it beside the checkbox',
        (tester) async {
      await pumpSignedIn(tester);

      await tester.enterText(
          find.byKey(const ValueKey('remark-t1')), 'went well');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      final log = gateway.docs['users/u/tasks/t1/daily_logs/2026-07-13'];
      expect(log!['remark'], 'went well');
    });

    testWidgets('Progress tab shows streak and completion for a task',
        (tester) async {
      // 2 completed days ending today, 1 elapsed day missed (Jul 11).
      gateway.docs['users/u/tasks/t1/daily_logs/2026-07-12'] = {
        'date': '2026-07-12',
        'completed': true,
        'updatedAt': DateTime.utc(2026, 7, 12),
      };
      gateway.docs['users/u/tasks/t1/daily_logs/2026-07-13'] = {
        'date': '2026-07-13',
        'completed': true,
        'updatedAt': DateTime.utc(2026, 7, 13),
      };
      await pumpSignedIn(tester);

      await tester.tap(find.text('Progress'));
      await tester.pumpAndSettle();

      // Task started 2026-07-13 (day 1), so elapsed=1... this task starts
      // today per seedTask; streak counts both ticked days.
      expect(find.byKey(const ValueKey('streak-t1')), findsOneWidget);
      expect(find.text('2 days'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('completion-t1')),
        findsOneWidget,
      );
      // Future task appears too (not archived), showing its start date.
      expect(find.text('Starts 2026-08-01'), findsOneWidget);
    });

    testWidgets('task detail shows the calendar and remark history',
        (tester) async {
      gateway.docs['users/u/tasks/t1/daily_logs/2026-07-13'] = {
        'date': '2026-07-13',
        'completed': true,
        'remark': 'went well',
        'updatedAt': DateTime.utc(2026, 7, 13),
      };
      await pumpSignedIn(tester);

      await tester.tap(find.text('Tasks'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('task-tile-t1')));
      await tester.pumpAndSettle();

      // Calendar month for the task range (Jul 13–19) is shown.
      expect(find.text('July 2026'), findsOneWidget);

      // Tapping the completed day shows the remark.
      await tester.tap(find.byKey(const ValueKey('cal-2026-07-13')));
      await tester.pumpAndSettle();
      expect(find.text('Completed — went well'), findsOneWidget);
      await tester.tapAt(const Offset(10, 10)); // dismiss dialog
      await tester.pumpAndSettle();

      // History list (below the calendar) shows the logged day + remark.
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('history-2026-07-13')),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.byKey(const ValueKey('history-2026-07-13')), findsOneWidget);
      expect(find.text('went well'), findsOneWidget);
    });

    testWidgets('existing log state is shown on load', (tester) async {
      gateway.docs['users/u/tasks/t1/daily_logs/2026-07-13'] = {
        'date': '2026-07-13',
        'completed': true,
        'remark': 'done early',
        'completedAt': DateTime.utc(2026, 7, 13, 6),
        'updatedAt': DateTime.utc(2026, 7, 13, 6),
      };
      await pumpSignedIn(tester);

      final checkbox = tester.widget<CheckboxListTile>(
          find.byKey(const ValueKey('tick-t1')));
      expect(checkbox.value, isTrue);
      expect(find.text('done early'), findsOneWidget);
    });
  });

  testWidgets('wide layout uses a navigation rail, narrow uses a bottom bar',
      (tester) async {
    final repo =
        FakeAuthRepository(initialUser: const AppUser(uid: 'u', email: 'a@b.com'));

    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(appWith(repo));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    tester.view.physicalSize = const Size(400, 800);
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
  });

  testWidgets('invalid form input is rejected before hitting the repo',
      (tester) async {
    await tester.pumpWidget(appWith(FakeAuthRepository()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('email')), 'not-an-email');
    await tester.enterText(find.byKey(const Key('password')), '123');
    await tester.tap(find.byKey(const Key('submit')));
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid email'), findsOneWidget);
    expect(find.text('Password must be at least 6 characters'), findsOneWidget);
  });
}
