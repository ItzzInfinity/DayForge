# QA Checklist

Two layers: automated checks run after every task, and device verification
done by the user (tracked in [`../manual-task.md`](../manual-task.md)).

## Automated (run after every change)
```
export PATH="$HOME/development/flutter/bin:$PATH"
flutter analyze          # must be clean
flutter test             # 156 tests as of 2026-08-17, all must pass
flutter build linux --release
flutter build apk --debug   # only needed when pubspec/native code changed
```
Conventions the tests rely on:
- Widget keys: `email`/`password`/`submit`, `add-task`, `task-*` form fields,
  `tick-{taskId}`, `remark-{taskId}`, `filter-*`, `task-menu-{id}`,
  `confirm-delete`, `retry`, `export-*`, settings tile keys, `cal-{date}`,
  `history-{date}`, `onboarding-add-task`, `reminder-sound`/`sound-*`,
  `alarm-volume`, `forgot-password`/`reset-email`/`send-reset`,
  `task-repeat`/`task-window-*`/`task-interval`/`task-target`,
  `task-repeat-by`/`task-reps` (the "N times a day" mode; scroll to them —
  the add-task form is taller than the 800×600 test viewport),
  `rule-fixedWindow`/`rule-targetDays`, `counter-{id}`/`count-{id}`/
  `untick-{id}` (intraday tiles use `tick-{id}` as the +1 button).
- Settings is a long list: widget tests use `scrollToKey` before tapping a
  tile below the fold.
- Fakes live in `test/helpers/fakes.dart`; the app harness is
  `appWith(...)` in `test/widget_test.dart` (fixed date 2026-07-13).

## Device verification (user)
- **M6** — Android: install APK, reminder arrives with app closed. ✓ 2026-07-13
- **M7** — Linux end-to-end: sign-up → add task → tick → remark → Firestore
  console shows the docs → persistence across restart → reminder → sign-out/in.
  ✓ 2026-07-13
- **M13** — Feedback round 4: sounds (incl. Android device pick), no
  reminder after an early tick, intraday reminders + counter, password
  reset, both rollover rules. See manual-task.md.
- **M14** — Password-reset email template/sender in the Firebase console.
- **M8** — Final acceptance sweep: cross-device sync, offline behavior,
  export, theme, onboarding, security. See manual-task.md.

## Known platform caveats (by design, documented in architecture.md)
- Linux reminders fire only while the app is running (no OS scheduler).
- Linux is online-only (REST gateway, no offline cache); failures show a
  friendly retry, and daily writes are idempotent so retries are safe.
- Windows target builds from the same codebase but has not been run on real
  Windows hardware yet (M8·7, optional).
- Custom notification audio on Windows only works from an MSIX package, so
  the bundled tones map onto the closest built-in toast sounds there.
- "Pick from device" is Android-only (system ringtone picker); the desktop
  notification servers have no equivalent chooser.
- Android notification channels are immutable, so each sound gets its own
  channel id — changing the sound creates a new channel rather than editing
  the old one.
