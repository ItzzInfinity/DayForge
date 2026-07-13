# Checkpoints — Resume Notes

> Resume protocol: read this file first, continue from **Next step**, do not redo completed work, always run the self-check after each task.

## Current state — 2026-07-13 (session 5) — Phase 3: local notifications COMPLETE

- **Current phase:** Phase 4 — Progress tracking
- **Last completed task:** Task detail screen (calendar view + history timeline)
- **Next task:** Task filtering by category/status + search + archive/delete actions (Tasks tab)

### Calendar/history summary (2026-07-13, session 6)
- `lib/features/progress/domain/calendar_grid.dart` — pure helpers: `DayStatus{completed,missed,pending,future,outOfRange}` (`pending` = today unticked), `dayStatus()`, `monthsInRange()` (handles year boundary), `monthCells()` (Monday-first, leading nulls), `monthNames` (no intl dep).
- `lib/features/progress/presentation/task_detail_screen.dart` — per-task: summary (streak chip + X of Y · Z%), month grids (7-col GridView, circular day cells colored by status, tap → dialog with completed/missed/pending + remark; keys `cal-{dateKey}`), History section newest-first (✓/○ icon, date, remark; keys `history-{date}`).
- Navigation: Tasks tile (key `task-tile-{id}`) and Progress card (key `progress-card-{id}`) both push TaskDetailScreen.
- Tests: +6 (5 grid unit incl. weekday padding + year boundary; 1 detail widget test — gotcha: history rows are below the fold, use `tester.scrollUntilVisible(..., scrollable: find.byType(Scrollable).last)`). 62 total passing.
- Validation: analyze clean, 62 tests pass, Linux release rebuilt (Dart-only).

### Streaks/completion summary (2026-07-13, session 6)
- `lib/features/progress/domain/progress_calculator.dart` — pure `calculateProgress(task, logs, today)` → `TaskProgress{currentStreak, completedDays, elapsedDays, completionPercent}`. Semantics: streak = consecutive completed days ending today OR yesterday (unticked today doesn't zero it mid-day); elapsed = startDate..min(today, endDate) inclusive, 0 for future tasks; % = completed/elapsed.
- `taskLogsProvider` family added in `lib/features/daily/providers.dart` (getAllForTask); Today screen invalidates it alongside `todayLogProvider` on tick/remark writes.
- Progress screen rebuilt: per non-archived task a card with 🔥 streak chip (key `streak-{id}`), date range, LinearProgressIndicator, "X of Y days done · Z%" (key `completion-{id}`), "Starts <date>" for future tasks.
- Tests: +10 (9 calculator edge cases — incl. remark-only days don't count, ended task caps window — and 1 Progress-tab widget test). 56 total passing. (Lesson: gap test initially asserted wrong semantics — streak ending yesterday survives.)
- Validation: analyze clean, 56 tests pass, Linux release rebuilt (Dart-only).

### Settings summary (2026-07-13, session 6)
- M6+M7 fully verified by user: reminders fired simultaneously on Android phone and Ubuntu ✓.
- `lib/features/settings/domain/app_settings.dart` — `AppSettings` (defaultDurationDays 21, defaultReminderTime '08:00', notificationsEnabled true, themeMode 'system'); note: import const with `as notifications` prefix (field name shadows it).
- `lib/features/settings/data/settings_repository.dart` — get (defaults when doc missing) / save (merge) at `users/{uid}/settings/app`.
- `lib/features/settings/providers.dart` — `settingsRepositoryProvider`, `appSettingsProvider` (FutureProvider; invalidate after save).
- Settings screen controls (keys): `notifications-enabled` switch, `default-reminder-time` picker, `default-duration` dialog (`default-duration-field`/`default-duration-save`), `theme-mode` dropdown, plus existing `test-notification`, `sign-out`.
- Wiring: `AdvancedTodoApp` is now a ConsumerWidget → themeMode from settings; `AuthGate` listens to BOTH tasksProvider and appSettingsProvider → `syncReminders()` (disabled ⇒ sync empty list = cancel all; passes `defaultTime`); `ReminderScheduler.sync` gained `{String defaultTime}` param; add-task duration pre-fills from settings.
- Tests: +7 (settings model/repo unit ×4-in-2-groups, reminders-off cancels, theme applies+persists, duration pre-fill). 46 total passing.
- Validation: analyze clean, 46 tests pass, Linux release rebuilt (Dart-only change).

### Linux notification investigation (2026-07-13)
- User reported M7 step 7 failure (no Linux notification). Diagnosis: NOT a code bug. Verified bottom-up: GNOME daemon alive (gdbus GetServerInformation), raw D-Bus Notify accepted, and a probe app (`tool/notify_probe.dart` — kept for future debugging) proved plugin initialize/cancelAll/show/timer-show all work on this machine. Root cause: test-timing — the reminder time set in checklist step 2 had already passed by step 7 (app was also closed/reopened in step 6), so the scheduler correctly armed it for the next day; Linux only fires while the app runs.
- Hardening added: `ReminderScheduler.showNow()` + Settings tile `test-notification` ("Send test notification") for instant device verification on all platforms; debugPrint diagnostics in sync/fire paths (visible when running from a terminal). +1 widget test (39 total). M6 confirmed: real Android device notification received ✓.
- NOTE: building with `-t tool/notify_probe.dart` overwrites the debug bundle — rebuild `flutter build linux --debug` afterwards (done).

### Local notifications summary
- Deps: `flutter_local_notifications 22.0.1` (+linux 8.0.1, +windows 3.1.1), `timezone 0.11.1`. **v22 API note: `initialize(settings: ...)` is a named param.**
- `lib/services/notifications/reminder_scheduler.dart` — `ReminderScheduler` interface + pure helpers: `parseHhMm`, `stableNotificationId` (FNV-1a, 26-bit, ×10 leaves sub-id room), `nextOccurrence`; `defaultReminderTime = '08:00'`.
- `lib/services/notifications/local_reminder_scheduler.dart` — platform strategies (Linux plugin has NO zonedSchedule — verified in package source):
  - Android: `zonedSchedule` + `matchDateTimeComponents.time` daily repeat, `inexactAllowWhileIdle` (avoids exact-alarm permission), survives reboot via boot receiver.
  - Windows: one-shot toasts for next 7 days per task (ids baseId+i), refreshed each sync.
  - Linux: in-app `Timer` per task → `show()` via D-Bus, re-arms daily; only fires while app runs (documented limitation).
  - Times scheduled as absolute UTC instants (DST zones can drift 1h until next sync; IST unaffected). Sync = cancelAll + re-add; skips non-active and ended tasks (endDate < today).
- Wiring: `reminderSchedulerProvider`; `AuthGate` `ref.listen(tasksProvider)` → requestPermission + sync on initial load and every task change (create → invalidate → re-sync chain works).
- Android: manifest adds POST_NOTIFICATIONS + RECEIVE_BOOT_COMPLETED + ScheduledNotificationReceiver/BootReceiver; `android/app/build.gradle.kts` adds **core library desugaring** (`isCoreLibraryDesugaringEnabled = true` + `coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")`) — plugin build fails without it.
- Tests: +6 (parseHhMm, stable ids, nextOccurrence boundaries ×3, reminder re-sync after task creation via `FakeReminderScheduler` in helpers). 38 total passing.
- Validation: analyze clean, Linux debug build OK, APK debug build OK. NOT yet manually verified on a physical Android device (needs user hardware).

### Today screen summary
- `lib/core/providers.dart` — `currentDateProvider` moved here from today_screen.dart (daily providers need it; avoids provider→screen import cycle). add_task_screen + tests import updated.
- `lib/features/daily/providers.dart` — added `todayLogProvider` (`FutureProvider.family<DailyLog?, String>` by taskId, keyed off `currentDateProvider`); invalidate after each write (same pattern as tasksProvider).
- `lib/features/daily/presentation/today_screen.dart` — rebuilt: lists tasks where `isActiveOn(today)`; per task a Card with `CheckboxListTile` (key `tick-{taskId}`, optimistic toggle with revert+snackbar on failure, subtitle "Day X of N · category") and an inline remark `TextField` (key `remark-{taskId}`, saves on submit AND focus loss, only when text changed, `_savedRemark` dedupe). Entry widget keyed `entry-{taskId}-{dateKey}` so typing survives provider refreshes. Empty state directs to Tasks tab.
- Tests: +4 (active-only filtering incl. future task hidden; tick→doc `daily_logs/2026-07-13` completed+completedAt, untick clears completedAt; remark persists via keyboard done action; pre-seeded log renders checked + remark shown). Gotcha: fake gateway replaces stored maps on merge writes — re-read `gateway.docs` after each write, don't hold references.
- Validation: analyze clean, 32 tests pass, Linux debug build OK (Dart-only).

**The FSD core loop now works end to end: add task with duration → tick daily → remark per day → synced to Firestore.**

### Add-task summary
- `lib/features/tasks/presentation/add_task_screen.dart` — form: title* (validated), description, category, duration* (int ≥1, default 21 via `defaultDurationDays` const), start-date picker (defaults to `currentDateProvider`), optional reminder time picker (stored "HH:mm"). Keys: `task-title`, `task-description`, `task-category`, `task-duration`, `task-start-date`, `task-reminder`, `task-submit`. On create: `ref.invalidate(tasksProvider)` so the polling (Linux) gateway shows the new task immediately, then pops.
- `lib/features/tasks/presentation/tasks_screen.dart` — real list from `tasksProvider` (title, `start → end · N days · category`, status chip for non-active), FAB key `add-task`, empty state.
- Tests: +2 (create flow incl. persistence under `users/{uid}/tasks/`; validation errors). Gotcha: gateway also holds the sign-in profile doc — filter by path prefix in assertions.
- Validation: analyze clean, 28 tests pass, Linux debug build OK (Dart-only).

### Daily log summary (new files)
- `lib/features/daily/domain/daily_log.dart` — `DailyLog` (date=doc id, completed, remark, completedAt?, updatedAt).
- `lib/features/daily/data/daily_log_repository.dart` — `setCompleted` (sets/clears completedAt), `setRemark`, `get`, `getAllForTask` (oldest first), `watchForTask`, `watch(taskId,date)`. All writes merge, so checkbox and remark never clobber each other across devices.
- `lib/features/daily/providers.dart` — `dailyLogRepositoryProvider` (null when signed out).
- Tests: `test/daily_log_test.dart` (7 tests: round-trip, id fallback, tick/untick, merge safety, skipped-day remark, sorting).
- Validation: analyze clean, 26 tests pass, Linux debug build OK (Dart-only).

### Task model summary (new files)
- `lib/core/utils/date_utils.dart` — added `fromDateKey` (UTC midnight, DST-safe) and `addDaysToKey`.
- `lib/core/utils/id_generator.dart` — `newDocId()` client-side ids (REST gateway has no server-side id allocation); time-prefixed base36.
- `lib/features/tasks/domain/task.dart` — `Task`, `TaskStatus{active,completed,archived}`; `endDate`, `coversDate`, `isActiveOn`; `toMap`/`fromMap` (DateTime fields — gateways normalize); `copyWith` with `String? Function()?` for nullable fields.
- `lib/features/tasks/data/task_repository.dart` — create/save (fresh updatedAt)/setStatus (merge)/delete/getById/getAll/watchAll, newest-first sort.
- `lib/features/tasks/providers.dart` — `taskRepositoryProvider` (null when signed out), `tasksProvider` (StreamProvider).
- Tests: `test/task_test.dart` (10 tests: date utils, range boundaries, round-trip, repo CRUD vs FakeFirestoreGateway); fakes extracted to `test/helpers/fakes.dart` (shared FakeAuthRepository + FakeFirestoreGateway).
- Validation: analyze clean, 19 tests pass, Linux debug build OK (Dart-only change, no APK rebuild needed).

### Phase 1 summary (all done, all validated)
1. Flutter 3.44.6 project at repo root (`advanced_todo`, org `com.sisirradar`, android/windows/linux). SDK at `~/development/flutter` (export PATH each session). flutter doctor all green; Android SDK registered from `~/android-sdk`.
2. Riverpod 3 (`flutter_riverpod`), layered `lib/` (app/ core/ features/ services/).
3. Theme + navigation: `lib/app/theme.dart` (seed teal, light+dark, `themeMode: system`); `lib/app/home_shell.dart` — adaptive shell, breakpoint 640px (NavigationRail wide / NavigationBar narrow), tabs Today·Tasks·Progress·Settings via IndexedStack; placeholder screens in `features/{tasks,progress,settings}/presentation/`; sign-out lives in Settings (key `sign-out`).
4. Firebase config: project `advanced-todo-infinite` (user account pcinfinitesolutions@gmail.com), `lib/firebase_options.dart`, android + windows(web-type) apps. CLIs: firebase-tools (npm), flutterfire_cli (`~/.pub-cache/bin`). **Linux caveat:** no native SDK → REST fallbacks (documented in docs/architecture.md).
5. Auth: `AuthRepository` (native `firebase_auth` for Android/Windows, REST identitytoolkit for Linux with SharedPreferences session), SignInScreen (keys: email/password/submit/toggle-mode), AuthGate. Live-verified.
6. Firestore: rules deployed (owner-only `users/{uid}/**`, live-verified incl. 403s); `FirestoreGateway` interface + native impl (persistence on) + REST impl (codec, pagination, merge, 10s polling watch); `ProfileRepository.ensureProfile` creates `users/{uid}` on first sign-in (wired in AuthGate via ref.listen).

Deps: flutter_riverpod, firebase_core, firebase_auth, cloud_firestore, http, shared_preferences.
Tests: 9 passing (`test/widget_test.dart` — auth flow, profile doc, navigation, adaptive layout; `test/firestore_value_codec_test.dart`). Debug builds verified: Linux + APK.

### Partially done
- Nothing.

### Blocked
- Nothing. Manual items M1–M5 all complete; no new manual items open.

### Next step (exact)
1. `export PATH="$HOME/development/flutter/bin:$PATH"`
2. Tasks tab management: filter chips by status (active/completed/archived) and category (distinct categories from tasks), a search TextField filtering by title/description, and per-task actions (popup menu on tile: mark completed / archive / delete with confirm dialog) using `TaskRepository.setStatus`/`delete` + `ref.invalidate(tasksProvider)`. Widget tests for filter, search, archive, delete.
3. That completes Phase 4 → then Phase 5 (offline/conflict already largely covered by design; export JSON/CSV/Markdown; error/retry states).
4. Validate: analyze + test + linux build.

### Assumptions
- Sign-out moved from Today appbar to Settings (better daily UX; Today stays minimal).
- IndexedStack keeps tab state; fine at this scale.
- Theme follows system; a user-facing toggle arrives with the settings doc (Phase 6 / data-model `themeMode`).

### Self-check (Task 3)
- Output matches goal: adaptive nav + theme, daily flow still 1 tap deep ✓
- No self-hosting ✓ · Linux build ✓ · Android/Windows preserved (Dart-only change) ✓
- Consistent with data model: no data changes ✓
- Resumable: this file + roadmap updated ✓
