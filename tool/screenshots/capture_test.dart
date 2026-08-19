// Renders the real app against seeded demo data and writes the README's
// screenshots to docs/screenshots/.
//
// Do not run this directly — use tool/screenshots/capture.sh, which drives it
// one scene per process. Each test name is exactly the PNG it produces.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:advanced_todo/app/app.dart';
import 'package:advanced_todo/core/providers.dart';
import 'package:advanced_todo/features/auth/domain/app_user.dart';
import 'package:advanced_todo/features/auth/providers.dart';
import 'package:advanced_todo/features/export/providers.dart';
import 'package:advanced_todo/features/onboarding/providers.dart';
import 'package:advanced_todo/services/firestore/providers.dart';
import 'package:advanced_todo/services/notifications/providers.dart';

import '../../test/helpers/fakes.dart';
import 'demo_data.dart';
import 'harness.dart';

Widget demoApp(FakeFirestoreGateway gateway, {bool signedIn = true}) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(
        FakeAuthRepository(
          initialUser: signedIn
              ? const AppUser(uid: uid, email: 'you@example.com')
              : null,
        ),
      ),
      firestoreGatewayProvider.overrideWithValue(gateway),
      reminderSchedulerProvider.overrideWithValue(FakeReminderScheduler()),
      exportSaverProvider.overrideWithValue(FakeExportSaver()),
      tutorialStoreProvider.overrideWithValue(FakeTutorialStore()),
      deviceSoundPickerProvider
          .overrideWithValue(FakeDeviceSoundPicker(isSupported: false)),
      currentDateProvider.overrideWithValue(DateTime(2026, 8, 19)),
    ],
    child: capturable(const AdvancedTodoApp()),
  );
}

Future<FakeFirestoreGateway> openDemo(
  WidgetTester tester, {
  bool signedIn = true,
  String theme = 'light',
}) async {
  final gateway = FakeFirestoreGateway();
  seedDemo(gateway);
  gateway.docs['users/$uid/settings/app'] = {'themeMode': theme};
  await usePhoneSurface(tester);
  await tester.pumpWidget(demoApp(gateway, signedIn: signedIn));
  await settle(tester, frames: 20);
  return gateway;
}

Future<void> goTo(WidgetTester tester, String tab) async {
  await tester.tap(find.text(tab));
  await settle(tester);
}

void main() {
  setUpAll(loadRealFonts);

  testWidgets('01-today', (tester) async {
    await openDemo(tester);
    await capture(tester, '01-today');
  });

  testWidgets('02-tasks', (tester) async {
    await openDemo(tester);
    await goTo(tester, 'Tasks');
    await capture(tester, '02-tasks');
  });

  testWidgets('03-progress', (tester) async {
    await openDemo(tester);
    await goTo(tester, 'Progress');
    await capture(tester, '03-progress');
  });

  testWidgets('04-task-detail', (tester) async {
    await openDemo(tester);
    await goTo(tester, 'Progress');
    // Progress lists newest-started first, so pick a card that is on screen
    // without scrolling — and one with enough history to be worth showing.
    await tester.tap(find.text('German — 15 minutes').first);
    await settle(tester);
    await capture(tester, '04-task-detail');
  });

  testWidgets('05-add-task', (tester) async {
    await openDemo(tester);
    // Open it from Tasks: every tab lives in one IndexedStack, so the Today
    // tab's FAB is not the only 'add-task' in the tree.
    await goTo(tester, 'Tasks');
    await tester.tap(find.byKey(const Key('add-task')));
    await settle(tester);
    await tester.enterText(find.byKey(const Key('task-title')), 'Drink water');
    await tester.dragUntilVisible(
      find.byKey(const Key('task-repeat')),
      find.byType(Scrollable).first,
      const Offset(0, -120),
    );
    await settle(tester);
    await tester.tap(find.text('Many times a day'));
    await settle(tester);
    await capture(tester, '05-add-task');
  });

  testWidgets('06-settings', (tester) async {
    await openDemo(tester);
    await goTo(tester, 'Settings');
    await capture(tester, '06-settings');
  });

  testWidgets('07-today-dark', (tester) async {
    await openDemo(tester, theme: 'dark');
    await capture(tester, '07-today-dark');
  });

  testWidgets('08-sign-in', (tester) async {
    await openDemo(tester, signedIn: false);
    // The sign-in screen is the only one with an Image.asset. Decoding is
    // real async work, and the fake clock a test body runs under never lets
    // it finish — so without this the logo is a blank gap in the screenshot.
    await tester.runAsync(() async {
      await precacheImage(
        const AssetImage('assets/icon/dayforge.png'),
        tester.element(find.byType(Image).first),
      );
    });
    await settle(tester);
    await capture(tester, '08-sign-in');
  });

  // ---------------------------------------------------------------- films
  // Frame sequences that tool/screenshots/make_gifs.sh assembles into GIFs.
  //
  // One test — and so one process — per *frame*, replaying the interaction
  // from the start each time. Capturing twice in one test does not work: the
  // runner wedges on the first capture, so the second never runs.

  for (var frame = 0; frame <= 3; frame++) {
    testWidgets('film-tick-0$frame', (tester) async {
      await openDemo(tester);
      // Drink water sits at 3 of its 5-tick majority target. Three taps take
      // it over the line and on past it, which is the whole point of the rule.
      for (var i = 0; i < frame; i++) {
        // Reaching the target re-sorts the card, so make sure the button is
        // still on screen before reaching for it again.
        await tester.ensureVisible(find.byKey(const ValueKey('tick-water')));
        await settle(tester, frames: 4);
        await tester.tap(find.byKey(const ValueKey('tick-water')));
        await settle(tester, frames: 8);
      }
      // Let the encouragement snackbar time out — otherwise it sits across
      // the bottom of the frame for the whole GIF.
      if (frame > 0) await settle(tester, frames: 90);
      await capture(tester, 'film/tick-0$frame');
    });
  }

  const tabs = ['Today', 'Tasks', 'Progress', 'Settings'];
  for (var frame = 0; frame < tabs.length; frame++) {
    testWidgets('film-tabs-0$frame', (tester) async {
      await openDemo(tester);
      if (frame > 0) await goTo(tester, tabs[frame]);
      await capture(tester, 'film/tabs-0$frame');
    });
  }
}
