# Checkpoints — Resume Notes

> Resume protocol: read this file first, continue from **Next step**, do not redo completed work, always run the self-check after each task.

## Current state — 2026-07-14 (session 11) — Rebrand + feedback round 3 COMPLETE (pending M11 user verification)

- **Current phase:** All FSD phases + feedback rounds 1–3 done. App is now **DayForge** (icon `assets/icon/dayforge.png`, generated via flutter_launcher_icons; .deb package `dayforge`).
- **Last completed task:** Feedback round 3 (8 items, see roadmap) + fresh `dist/` artifacts.
- **Next task:** None queued — wait for M10/M11 verification results. Validation: `flutter analyze && flutter test` (112 tests) then `make all`.

### Session 11 summary — 112 tests passing
1. **Rebrand:** every display string/window title/notification → DayForge; Android launcher icon (5 mipmaps) + Windows .ico regenerated; export filenames `dayforge_export_*`, JSON `app: dayforge`; sign-in screen shows the logo.
2. **Identity:** all `sisirradar` → `itzzinfinity`; android applicationId/namespace now `com.itzzinfinity.advanced_todo` — **new Firebase Android app registered** (flutterfire configure; google-services.json + firebase_options.dart regenerated; old client block stripped). Next APK installs as a new app — old one must be uninstalled (M-note in manual-task.md).
3. **+ FAB everywhere but Settings:** shared `AddTaskFab` (unique heroTags — IndexedStack inflates all tabs) on Today/Tasks/Progress.
4. **Heatmap:** cell size from height (≤36px), week count from width (8–53 whole columns); no horizontal scroll; portrait fits exactly.
5. **Change deadline:** Tasks menu → date picker (min = startDate) recomputes durationDays.
6. **Today app bar:** DayForge top-left, `Today · date` beneath (toolbarHeight 68) — tests still find the date text.
7. **Quotes:** zenquotes.io fetch **removed entirely** (its ToS requires the attribution the user wanted gone); bundled 593-quote rotation only; `dailyQuoteProvider` now a sync Provider; `quote_service.dart` deleted.
8. **Categories:** `Task.categories` list (legacy `category` string migrates on read); add-form suggestion chips (Learning/Skill/Habit/Health/Fitness/Work/Personal) + existing-task categories + custom add (key `add-category`, chips `cat-*`); Tasks filter uses contains; Progress has filter chips (`progress-cat-*`) slicing heatmap + cards.

**Gotchas learned this session:**
- A `Form` inside a lazy `ListView` silently skips validators on scrolled-out fields (they unmount) — the add-task form is now `SingleChildScrollView` + `Column`.
- `find.byType(Scrollable).last` inside a form picks a TextField's internal scrollable — use `.first` (outer scroll view comes first in DFS order).

## Previous state — 2026-07-13 (session 9) — Feedback round 1 COMPLETE (pending M8+M9 user verification)

- **Current phase:** All FSD phases done (session 8). Session 9 delivered the user's six feedback features.
- **Last completed task:** Feedback round 1 (all six items) + fresh release builds (Linux bundle + app-release.apk 58 MB) + docs/M9.
- **Next task:** None queued — wait for M8 (final acceptance) and M9 (feedback features) results; fix anything reported. Validation command: `flutter analyze && flutter test && flutter build linux --release`.

### Feedback round 1 summary (2026-07-13, session 9) — 93 tests passing
1. **Filter double-tap → All:** ChoiceChip onSelected now toggles (`_statusFilter == status ? null : status`); Archived chip removed entirely.
2. **Archive hidden:** Tasks tab filters out archived tasks before building categories/list; archiving shows a snackbar pointing to the new `ArchiveScreen` (`lib/features/tasks/presentation/archive_screen.dart`, restore key `restore-{id}`, delete key `archive-delete-{id}`), reached via Settings tile key `archived-tasks`.
3. **Calendar readability:** task-detail month grids wrapped in `ConstrainedBox(maxWidth: 420)`; `_DayCell` uses LayoutBuilder → fontSize `(cellWidth*0.4).clamp(12,22)`, w500.
4. **Today ordering + congrats:** Today watches `todayLogProvider` per active task, splits pending/completed (completed under header key `completed-header`), `_AllDoneBanner` (key `all-done-banner`, elasticOut TweenAnimationBuilder) when every log loaded & completed.
5. **Quotes:** `lib/features/quotes/` — domain (`Quote`, `quoteOfTheDay` day-of-year rotation, `encouragementQuote`), data (`local_quotes.dart` **593 distinct quotes**), `providers.dart` (`dailyQuoteProvider` keyed off `currentDateProvider`; bundled rotation only — the zenquotes.io fetch was removed 2026-07-14 with its attribution). Tick → encouragement snackbar (`✓ quote — author`, clearSnackBars first).
6. **Snooze:** `AppSettings.snoozeMinutes` (default 10, dialog keys `snooze-duration`/`snooze-{5,10,15,30,60}`); `ReminderScheduler.sync` gained `snoozeMinutes` param; reminders carry payload (`encodeSnoozePayload` JSON) + `AndroidNotificationAction`/`LinuxNotificationAction` "Snooze N min"; snoozed one-shot lands on the task's reserved `+9` id slot (`snoozeNotificationId`). Foreground handler `_onResponse` (Linux: in-app Timer → show; Android: zonedSchedule now+N); background (app closed, Android) `notificationActionBackground` top-level `@pragma('vm:entry-point')`. Manifest gained `ActionBroadcastReceiver`. Windows toasts: no action support in the plugin — documented limitation.

**Test gotchas learned this session:**
- `SharedPreferences.getInstance()` in widget tests **hangs forever** (doesn't throw) without `setMockInitialValues` — hence the quote card renders `dailyQuoteProvider.value ?? quoteOfTheDay(date)` so it never depends on that future completing.
- `scrollUntilVisible` stops once the target *exists* (ListView cacheExtent builds it off-screen) — taps then miss. Fix: follow with `tester.ensureVisible(...)` + `pumpAndSettle` (applied to sign-out, export-data, archived-tasks taps).

**Validation:** analyze clean · 93 tests pass (was 80) · Linux release rebuilt · app-release.apk rebuilt (58 MB, pulled nothing new) · release binary smoke-launched 12s without errors.

## Previous state — session 8 — PROJECT COMPLETE (pending M8 user verification)

- **Current phase:** Done. All FSD phases (0–6) complete; final acceptance sweep done.
- **Last completed task:** Final acceptance sweep (requirements.md, qa-checklist.md, README, release artifacts, M8 checklist)
- **Next task:** None queued — wait for the user's M8 results and fix anything they report. Optional if asked: JSON import/restore, FCM, snooze, Google sign-in.

### Final sweep summary (2026-07-13, session 8)
- Walked FSD.md acceptance criteria — no code gaps found; docs-only task plus builds.
- New: `docs/requirements.md` (frozen scope, out-of-scope, criterion→implementation→verification table), `docs/qa-checklist.md` (automated commands, key conventions, device checklist index, platform caveats).
- README updated: status line, corrected stack (fl_chart was never added — progress bars + calendar grids instead), run instructions for all three platforms.
- Artifacts: Linux release bundle current; **`build/app/outputs/flutter-apk/app-release.apk` (56.6 MB) built** — user should install over the debug APK (signature differs → may need uninstall).
- `manual-task.md` M8 added: onboarding on fresh account, cross-device sync (note Linux 10s poll), export JSON/Markdown, synced theme, Android offline queue, Linux offline friendly-error, optional Windows build, filters/progress spot-check.
- Windows remains the one un-device-verified target (no hardware) — same native SDK path as Android; documented in requirements + M8·7.

### Phase 6 polish summary (2026-07-13, session 8)
- `lib/core/widgets/content_width.dart` — `ContentWidth` (Align topCenter + maxWidth 840) wraps the bodies of Today/Tasks/Progress/Settings/TaskDetail; add-task form already capped at 560.
- Today first-run onboarding: `_OnboardingEmpty` when the user has zero tasks — "Build a habit in three steps" + numbered steps + FilledButton key `onboarding-add-task` pushing AddTaskScreen. Distinct second empty state when tasks exist but none are active today ("Nothing scheduled for today…").
- Remark help text: hint is now "Optional note for today (how did it go?)".
- Also caught: TaskDetailScreen error path was still a raw string → now ErrorRetry (invalidates taskLogsProvider).
- Mobile layout verified at 400px (existing tests); no changes needed.
- Tests: +3 (onboarding flow incl. creating first task; distinct none-active-today empty state; 1600px width cap ≤840 on the list). **80 total passing.**
- Validation: analyze clean, 80 tests, Linux release rebuilt (Dart-only).

### Error/retry + offline review summary (2026-07-13, session 8)
- `lib/core/widgets/error_retry.dart` — `friendlyError(Object)`: SocketException/ClientException → "No connection…", FirestoreGatewayException 401 → re-sign-in, 403 → no access, other gateway errors → bare message, else toString. `ErrorRetry` widget: icon + message + friendly detail + Retry button (key `retry`).
- Wired into: AuthGate session error (invalidates authStateProvider), Today/Tasks/Progress list errors (invalidate tasksProvider), Today per-card log error (IconButton key `retry-log-{taskId}` → todayLogProvider), Progress per-card history error (key `retry-logs-{taskId}` → taskLogsProvider).
- `docs/architecture.md` — "Offline & conflict strategy" section rewritten: native = persistence on (offline-first ✓); Linux REST = online-only accepted limitation (friendly errors + idempotent date-key merge writes make retries safe); conflicts bounded by per-field merges + LWW + derived-stats-never-stored.
- Tests: +4 (3 friendlyError unit in `test/error_retry_test.dart`; 1 widget: `FlakyFirestoreGateway` in fakes — collection reads throw 503 until flag cleared → Today shows friendly retry, tap recovers). **77 total passing.** (Finders skip offstage IndexedStack tabs by default, so the duplicate ErrorRetry on hidden tabs doesn't break `findsOneWidget`.)
- Validation: analyze clean, 77 tests, Linux release rebuilt (Dart-only).

### Export summary (2026-07-13, session 8)
- Deps added: `file_selector`, `share_plus 13.2.0` (v13 API: `SharePlus.instance.share(ShareParams(...))`), `path_provider` — native plugins, so BOTH builds re-verified (Linux release + debug APK; APK pulled Android SDK Platform 35 automatically).
- `lib/features/export/domain/exporters.dart` — pure: `ExportBundle`/`TaskExport`, `ExportFormat{json,csv,markdown}`, `exportToJson` (formatVersion 1 — future import format; DateTimes → ISO), `exportToCsv` (CRLF, one row per log, log-less tasks keep one row, RFC-quoting), `exportToMarkdown` (section per task + history table, pipes escaped), `exportFileName` (`advanced_todo_export_YYYY-MM-DD.ext`), `serializeExport` switch.
- `lib/features/export/data/export_saver.dart` — `ExportSaver` interface (returns destination or null=cancelled); `DesktopExportSaver` (file_selector `getSaveLocation` → write) for Linux/Windows; `ShareExportSaver` (temp file → share sheet) for Android.
- `lib/features/export/providers.dart` — `exportSaverProvider` (platform-picked) + `gatherExportBundle()` (plain function, always fresh reads).
- Settings tile key `export-data` → SimpleDialog (option keys `export-json`/`export-csv`/`export-markdown`) → gather → serialize → save → snackbar (path / 'Export shared.' / 'Export cancelled.' / failure).
- Tests: +7 (5 serializer unit in `test/exporters_test.dart` incl. CSV quoting + markdown pipe escaping; 2 widget). `FakeExportSaver` in fakes + `appWith(exportSaver:)` override. **73 total passing.**
- Gotchas hit: (1) new Settings tile pushed `sign-out` below the fold → existing test needed `scrollUntilVisible`; (2) snackbars queue — second snackbar assertion needs `tester.pump(5s)` first to expire the previous one (4s duration).

### Tasks management summary (2026-07-13, session 7)
- `TaskRepository.delete` now cascades: deletes all `daily_logs` docs then the task doc (Firestore has no cascade).
- Tasks tab rebuilt (`ConsumerStatefulWidget`): search field (key `task-search`, matches title+description), status ChoiceChips (keys `filter-all/active/completed/archived`; **default filter = Active**), dynamic category FilterChips (keys `filter-cat-{name}`), per-tile PopupMenu (key `task-menu-{id}`): Mark completed / Reactivate / Archive / Delete (confirm dialog key `confirm-delete`). Two empty states: no tasks at all vs no filter matches.
- Tests: +5 (delete-cascades unit; filter default+archived chip, search+category, complete-via-menu, delete-confirm-removes-logs). 66 total passing.
- Validation: analyze clean, 66 tests pass, Linux release rebuilt (Dart-only).

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
1. Flutter 3.44.6 project at repo root (`advanced_todo`, org `com.itzzinfinity`, android/windows/linux). SDK at `~/development/flutter` (export PATH each session). flutter doctor all green; Android SDK registered from `~/android-sdk`.
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

### Next step (exact) — superseded by session 9 header above
1. Wait for the user's M8 + M9 verification results (manual-task.md). Fix anything reported, re-validating with `flutter analyze && flutter test && flutter build linux --release`.
2. If the user requests optional features, order of value: JSON import/restore (reads the formatVersion-1 export) → FCM → Google sign-in. (Snooze shipped in session 9.)
3. No other work is queued. Every phase in docs/roadmap.md is ✔.

### Assumptions
- Sign-out moved from Today appbar to Settings (better daily UX; Today stays minimal).
- IndexedStack keeps tab state; fine at this scale.
- Theme follows system; a user-facing toggle arrives with the settings doc (Phase 6 / data-model `themeMode`).

### Self-check (Task 3)
- Output matches goal: adaptive nav + theme, daily flow still 1 tap deep ✓
- No self-hosting ✓ · Linux build ✓ · Android/Windows preserved (Dart-only change) ✓
- Consistent with data model: no data changes ✓
- Resumable: this file + roadmap updated ✓
