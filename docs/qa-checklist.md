# QA Checklist

Two layers: automated checks run after every task, and device verification
done by the user (tracked in [`../manual-task.md`](../manual-task.md)).

## Automated (run after every change)
```
export PATH="$HOME/development/flutter/bin:$PATH"
flutter analyze          # must be clean
flutter test             # 80 tests as of 2026-07-13, all must pass
flutter build linux --release
flutter build apk --debug   # only needed when pubspec/native code changed
```
Conventions the tests rely on:
- Widget keys: `email`/`password`/`submit`, `add-task`, `task-*` form fields,
  `tick-{taskId}`, `remark-{taskId}`, `filter-*`, `task-menu-{id}`,
  `confirm-delete`, `retry`, `export-*`, settings tile keys, `cal-{date}`,
  `history-{date}`, `onboarding-add-task`.
- Fakes live in `test/helpers/fakes.dart`; the app harness is
  `appWith(...)` in `test/widget_test.dart` (fixed date 2026-07-13).

## Device verification (user)
- **M6** — Android: install APK, reminder arrives with app closed. ✓ 2026-07-13
- **M7** — Linux end-to-end: sign-up → add task → tick → remark → Firestore
  console shows the docs → persistence across restart → reminder → sign-out/in.
  ✓ 2026-07-13
- **M8** — Final acceptance sweep: cross-device sync, offline behavior,
  export, theme, onboarding, security. See manual-task.md.

## Known platform caveats (by design, documented in architecture.md)
- Linux reminders fire only while the app is running (no OS scheduler).
- Linux is online-only (REST gateway, no offline cache); failures show a
  friendly retry, and daily writes are idempotent so retries are safe.
- Windows target builds from the same codebase but has not been run on real
  Windows hardware yet (M8·7, optional).
