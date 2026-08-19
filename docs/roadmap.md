# Roadmap & Progress Tracker

Source of truth for task status. Update after every completed task.
Legend: `[ ]` pending · `[~]` in progress · `[x]` done · `[M]` waiting on manual step (see `../manual-task.md`)

## Phase 0 — Planning
- [x] Define file structure for the repo (this docs set)
- [x] Define checkpoint/resume format (`docs/checkpoints.md`)
- [x] Architecture outline (`docs/architecture.md`)
- [x] Data model outline (`docs/data-model.md`)
- [x] Full product requirements document (`docs/requirements.md`) — done 2026-07-13; final scope, out-of-scope list, acceptance-criteria mapping

**Phase 0 complete ✔ (2026-07-13)**

## Phase 1 — Foundation
- [x] Task 1: Create Flutter project (Android, Windows, Linux targets) — done 2026-07-13, `flutter analyze` + `flutter test` pass
- [x] Task 2: Add state management (Riverpod) — done 2026-07-13, analyze/test pass, Linux debug build verified
- [x] Task 3: Add app theme and base navigation — done 2026-07-13; light/dark theme, adaptive shell (bottom bar / nav rail), Today·Tasks·Progress·Settings tabs, sign-out in Settings

**Phase 1 complete ✔ (2026-07-13)**
- [x] Task 4: Add Firebase project configuration — done 2026-07-13; project `advanced-todo-infinite`, android+windows apps registered, `firebase_options.dart` generated, debug APK build verified
- [x] Task 5: Add authentication flow — done 2026-07-13; AuthRepository with native (Android/Windows) + REST (Linux) impls, sign-in/up screen, AuthGate; REST endpoints verified live against the project
- [x] Task 6: Add Firestore integration — done 2026-07-13; gateway (native+REST), offline persistence, profile doc on sign-in; rules deployed by user and verified live (owner-only access, cross-uid + unauthenticated denied)

## Phase 2 — Core data + task flow
- [x] Create task model — done 2026-07-13; `Task` + `TaskStatus`, date-key range logic, `TaskRepository` (create/save/setStatus/delete/getAll/watchAll) + providers; 10 new unit tests
- [x] Create daily log model — done 2026-07-13; `DailyLog` (doc id = date key), `DailyLogRepository` (merge-based tick/remark, range reads, watches) + provider; 7 new unit tests
- [x] Build add-task screen — done 2026-07-13; full form (title/description/category/duration/start date picker/reminder time picker), FAB entry on Tasks tab, real task list from `tasksProvider`
- [x] Add default duration setting — partial: hardcoded 21-day default in add form; user-editable setting arrives with the settings doc
- [x] Add recurring duration logic — done via `Task.isActiveOn`/`endDate` (model task) + duration validation in form
- [x] Build today screen with checkboxes — done 2026-07-13; lists tasks active today with "Day X of N", optimistic tick/untick
- [x] Add remark input beside each daily completion — done 2026-07-13; inline field per task, saves on submit/focus-loss, works on skipped days
- [x] Save task completion to database — done 2026-07-13; merge writes to `daily_logs/{YYYY-MM-DD}`, verified in tests

**Phase 2 complete ✔ (2026-07-13)**

## Phase 3 — Reminders
- [x] Reminder time per task / global default — done 2026-07-13; per-task "HH:mm" from add form, global default 08:00 const (user-editable setting later)
- [x] Local notifications — done 2026-07-13; `LocalReminderScheduler`: Android daily repeating (boot-safe, inexact), Windows 7-day one-shot toasts, Linux in-app timers; auto re-sync on every task-list change
- [ ] FCM (if needed) — deferred, optional (local notifications already satisfy the FSD reminder requirement)
- [ ] Snooze / retry logic — deferred, optional polish
- [x] Notification preference settings — done 2026-07-13; settings doc (`users/{uid}/settings/app`), reminders on/off, default reminder time, default duration (pre-fills add-task), theme mode; reminders re-sync live on change

**Phase 3 core complete ✔ (2026-07-13)** — remaining items optional

## Phase 4 — Progress tracking
- [x] Streak calculation — done 2026-07-13; pure `calculateProgress` (streak ends today-or-yesterday; gaps break it), 9 unit tests
- [x] Completion percentage — done 2026-07-13; completed ÷ elapsed active days, capped at task end; Progress screen with 🔥 streak chip + progress bar per task
- [x] Task history timeline — done 2026-07-13; chronological log list with ✓/○ + remarks on the task detail screen
- [x] Calendar view — done 2026-07-13; per-task month grids (completed/missed/pending-today/future coloring), tap a day for its remark; reachable from Tasks tiles and Progress cards
- [x] Filtering by category/status — done 2026-07-13; status chips (default Active) + dynamic category chips; complete/reactivate/archive/delete menu per task (delete confirms + cascades to logs)
- [x] Search — done 2026-07-13; live title/description search on Tasks tab

**Phase 4 complete ✔ (2026-07-13)**

## Phase 5 — Reliability
- [x] Offline-first behavior — done 2026-07-13; native platforms use Firestore persistence (already on); Linux REST gateway documented as online-only accepted limitation with friendly offline errors + idempotent retryable writes (docs/architecture.md)
- [x] Multi-device conflict handling — done 2026-07-13; bounded by design: per-field merge writes (tick and remark never clobber each other), last-write-wins within a field, derived stats never stored; documented in docs/architecture.md
- [x] Export to JSON/CSV/Markdown — done 2026-07-13; pure serializers + Settings "Export data" tile; desktop save-as dialog (file_selector), Android share sheet (share_plus)
- [~] Backup/restore flow — backup covered by JSON export (formatVersion 1); import/restore optional, not started
- [x] Error handling and retry states — done 2026-07-13; shared ErrorRetry widget (friendly messages incl. offline/expired-session) + Retry on session/Today/Tasks/Progress loads and inline retry on per-card log loads

**Phase 5 complete ✔ (2026-07-13)** — import/restore remains optional

## Phase 6 — Polish
- [x] Dark mode — done earlier (settings theme toggle: system/light/dark, persisted)
- [x] Empty states — done; all list screens, incl. distinct Today states (no tasks at all vs none active today)
- [x] Desktop layout — done 2026-07-13; shared `ContentWidth` caps list/form content at 840px (add-task form already 560px); nav rail ≥640px
- [x] Mobile layout — done 2026-07-13; verified at 400px (bottom bar, FAB clearance, tap targets); no changes needed
- [x] Onboarding — done 2026-07-13; first-run Today explains the 3-step loop with an "Add your first task" button
- [x] Help text for daily logging — done 2026-07-13; remark hint now "Optional note for today (how did it go?)"

**Phase 6 complete ✔ (2026-07-13)**

## Final acceptance sweep (2026-07-13)
- [x] All FSD acceptance criteria mapped to implementation + verification (`docs/requirements.md`)
- [x] `docs/qa-checklist.md` written (automated checks + device verification + known caveats)
- [x] README updated (status, correct stack, run instructions)
- [x] Release artifacts rebuilt: Linux release bundle + `app-release.apk` (56.6 MB)
- [M] M8 — final user verification checklist (cross-device sync, offline, export, theme, onboarding; Windows optional) — waiting on user

Optional leftovers (only if requested): JSON import/restore · FCM push · Google sign-in

## Feedback round 1 (2026-07-13, session 9) — user-requested features
- [x] Tasks tab: tapping the already-selected status filter chip resets to All
- [x] Archive hidden from main list — archived tasks live in Settings → Archived tasks (restore/delete there); Archived filter chip removed
- [x] Calendar: day numbers scale with the circle (12–22px) and the grid is capped at 420px so desktop circles stay proportionate
- [x] Today: ticked tasks sink below pending under a "Completed today" header; 🎉 congrats banner when everything active today is done
- [x] Motivational quotes: zenquotes.io quote-of-the-day (free API, cached daily, attributed) with a bundled 593-quote offline rotation; encouragement quote snackbar on every tick
- [x] Snooze: reminder notifications carry a "Snooze N min" button (Android + Linux; Windows toasts have no action support), duration configurable in Settings (5/10/15/30/60, default 10)
- [M] M9 — device verification of the above on Linux + Android (see ../manual-task.md)

## Feedback round 2 (2026-07-13, session 10) — user-requested features
- [x] `Advanced` section in Settings: backfill task dates — done 2026-07-13; Settings → Advanced (ExpansionTile) → Backfill task history: pick a task, tick any day from its start up to today (newest first); merge-safe daily-log writes, streaks/calendar update; +2 widget tests
- [x] Reminder time can be modified on an existing task — done 2026-07-13; Tasks menu → "Change reminder time": pick a new time or revert to the default; reminders re-sync automatically via the tasksProvider listener; +1 widget test
- [x] Persistent notification on mobile — done 2026-07-13; Android reminders are `ongoing` + no auto-cancel, stay in the tray until touched (touch dismisses) or an action is tapped
- [x] Notification "Mark completed" button — done 2026-07-13; Android + Linux action; app-running path writes via the repository (AuthGate-installed handler, screens refresh live), app-closed path (Android background isolate) writes the same merge-safe log doc via the native Firebase SDK; payload now carries taskId; +1 widget test, payload tests updated
- [x] Today: centered all-done + hidden completed — done 2026-07-13; completed tasks collapse behind "Completed today (N) ^" (tap to expand/collapse); when everything is done the 🎉 banner sits centered on screen with the toggle pinned at the bottom; tests updated +1 new
- [x] Single Makefile for all builds — done 2026-07-13; `make all` → .apk + .deb into `dist/` (verified: advanced-todo_1.0.0_amd64.deb with /usr/bin wrapper + desktop entry via `tool/build_deb.sh`); `make exe` builds+zips on a Windows host, prints a clear skip elsewhere (Flutter cannot cross-compile desktop targets); also `make test`/`make clean`
- [x] Progress: GitHub-style activity heatmap — done 2026-07-13; top ⅓ of the screen (clamped 150–280px) shows 20 Monday-first week columns, cells brighten with the day's tick count (relative 0–4 buckets), tooltip per day, Less→More legend, today outlined, newest week docked right; pure helpers in `activity_heatmap.dart`; +6 unit +1 widget test
- [x] First-run tutorial overlay: spotlight each section (rest of screen blacked out) with a NEXT button to advance — done 2026-07-14; per-device first-run tour (`PrefsTutorialStore`, `tutorial_seen_v1`) blacks out the shell with a spotlight circle over each nav destination, walks Today→Tasks→Progress→Settings switching tabs as it goes, Skip/DONE end it and mark it seen; +3 widget tests
- [M] M10 — device verification of the first-run tutorial on Linux + Android (see ../manual-task.md)

## Rebrand (2026-07-14, session 11)
- [x] App renamed to **DayForge** with the new anvil-calendar icon — all display strings, window titles, Android label, notification titles, export header/filenames; icon generated for Android mipmaps + Windows .ico via flutter_launcher_icons from `assets/icon/dayforge.png`; .deb package renamed `dayforge` with menu entry + hicolor icon; Firebase-registered android applicationId initially kept, then renamed to `com.itzzinfinity.advanced_todo` in feedback round 3

## Feedback round 3 (2026-07-14, session 11) — user-requested features
- [x] `Advanced` section in Settings with task-date backfill — already shipped in round 2 (`backfill_screen.dart`, Settings → Advanced → Backfill task history); re-verified 2026-07-14, both backfill widget tests green
- [x] Replace every `sisirradar` identifier with `itzzinfinity` — done 2026-07-14; android namespace/applicationId → `com.itzzinfinity.advanced_todo` (new Firebase Android app registered via flutterfire, google-services.json + firebase_options.dart regenerated, debug APK build verified), Kotlin package moved, Linux APPLICATION_ID, Windows CompanyName/copyright/appUserModelId, deb maintainer; NOTE: new package id ⇒ the next APK installs as a new app — uninstall the old one (data is in Firestore, just sign in again)
- [x] The + (add task) button appears on every screen except Settings — done 2026-07-14; shared `AddTaskFab` (unique hero tags — all tabs live in one IndexedStack) on Today/Tasks/Progress; +1 widget test
- [x] Heatmap quality: fills the width on desktop, no overflow in mobile portrait — done 2026-07-14; cell size derives from height (up to 36px), week count derives from width (8–53 whole columns, cells shrink on narrow screens instead of overflowing); horizontal scroll removed — the grid always fits exactly; +1 widget test (portrait no-overflow + desktop shows more weeks)
- [x] Task deadline (duration/end date) can be modified after creation — done 2026-07-14; Tasks menu → "Change deadline" opens a date picker on the current end date (min = start date), recomputes durationDays; streaks/calendar/reminders follow automatically; +1 widget test
- [x] Today app bar: app name `DayForge` top-left, date below it — done 2026-07-14; two-line left-aligned app bar (DayForge in titleLarge, `Today · YYYY-MM-DD` beneath in labelMedium)
- [x] Remove `zenquotes.io` attribution from quotes — done 2026-07-14; the API fetch itself was removed (its free tier *requires* visible attribution, so dropping only the label would violate their terms) — quotes now come solely from the bundled 593-quote daily rotation (still changes daily, works offline); `quote_service.dart` deleted, `dailyQuoteProvider` is now synchronous
- [x] Categories: suggest Learning/Skill/Habit/Health/Fitness/Work/Personal + user-defined; one or more categories per task; category filter in Progress — done 2026-07-14; `Task.category` → `categories` list (legacy single-string docs migrate on read, exporters emit joined labels), add-task form offers suggestion chips + categories from existing tasks + an "add your own" field, Tasks filter matches any of a task's categories, Progress gained filter chips that slice both the heatmap and the cards; also fixed: the add-task form is no longer a lazy ListView (off-screen validators silently stopped running); +4 tests
- [M] M11 — device verification of round 3 on Linux + Android (see ../manual-task.md)

## Feedback round 4 (2026-08-17, session 12) — user-requested features
Design decisions taken up front (user, 2026-08-17): sounds = bundled tones **plus** an Android device-ringtone picker; intraday recurrence = **window + interval** with a per-day tick counter; rollover mode = **per task, chosen at creation** (existing tasks stay Fixed window).

- [x] R4.1a Notification sound: bundled alarm-style tones + Settings picker with preview — done 2026-08-17; 5 synthesised tones (`tool/generate_sounds.py` → `assets/sounds/*.ogg` + `android/.../res/raw/*.ogg`), `ReminderSound`/`ReminderSoundChoice` catalogue, per-sound Android channel id (channels are immutable), Linux asset sound, Windows preset mapping, Settings picker with per-tone Preview + "Alarm volume" switch; scheduler args bundled into `ReminderOptions`; +7 unit +2 widget tests (120 total, analyze clean)
- [x] R4.1b Notification sound: Android "Pick from device…" system ringtone/alarm picker — done 2026-08-17; `MainActivity` hosts the `dayforge/sound_picker` MethodChannel (RingtoneManager ACTION_RINGTONE_PICKER over alarm+notification+ringtone types, returns `{uri,label}`, cancel/Silent → null), Dart `DeviceSoundPicker` + provider, Settings shows the entry only where supported and stores the URI on a per-URI Android channel; alarm audio attributes come from the "Alarm volume" switch (R4.1a); +2 widget tests (122 total), debug APK builds
- [x] R4.2 Bug: a task ticked before its reminder time no longer fires that day — done 2026-08-17; new `completedTodayProvider` (watches each active task's `todayLogProvider`, so every tick/untick/notification-action refreshes it) feeds `ReminderOptions.completedToday`; pure `nextReminderInstant(now,h,m,doneToday:)` pushes the first fire past today (and the task is skipped entirely if that lands beyond its end date) on all three platforms; +3 unit +1 widget test (126 total)
- [x] R4.3a Intraday recurrence — domain — done 2026-08-17; `Recurrence` (daily | intraday window+interval+target, `occurrenceMinutes`, clamped `targetPerDay`, `summary`), `Task.recurrence` (daily tasks still write no field), `DailyLog.count` (legacy ticked days read as 1); +10 unit tests
- [x] R4.3b Intraday recurrence — add-task UI — done 2026-08-17; "Repeat" segmented control (Once a day | Many times a day) reveals window from/until, an interval dropdown (15 min–4 h), an optional "ticks needed per day" field and a live summary; the single reminder-time tile hides for intraday tasks; `TaskRepository.create` takes a `Recurrence`; +1 widget test (137 total)
- [x] R4.3c Intraday recurrence — scheduling — done 2026-08-17; pure `reminderTimesFor(task)` yields one time (daily) or every window slot (intraday) and `sync` arms one notification per slot on Android (daily repeat), Linux (in-app timers) and Windows (slots × days); ids re-based on 64 slots per task (24-bit hash, snooze on the last slot), occurrences capped at 48/day, payload carries the day's target; +3 unit tests
- [x] R4.3d Intraday recurrence — ticking — done 2026-08-17; `DailyLogRepository.addTick` (read-then-write, clamped to the target, keeps `completed` in step; the REST gateway has no atomic increment), Today shows a `n/target` counter tile with −1/+1 instead of a checkbox, notification "Mark completed" increments on both the in-app and app-closed (background isolate, target from the payload) paths, CSV gained a `count` column and Markdown shows `n/target` per day; streaks/heatmap/calendar keep reading `completed`, so they needed no change; +1 widget test (141 total)
- [x] R4.4 Forgot password — done 2026-08-17; `AuthRepository.sendPasswordReset` on both backends (native `sendPasswordResetEmail`, Linux/REST `accounts:sendOobCode`), unknown addresses succeed silently so the user list can't be probed; sign-in screen gained "Forgot password?" → dialog pre-filled from the email field → non-committal confirmation naming the spam folder; +3 widget tests (144 total). Existing passwords are unreadable by design — Firebase stores only a salted hash (see M14)
- [x] R4.5a Rollover — domain — done 2026-08-17; `CompletionMode` + `Task.targetDays` (pinned at creation so extensions can't move the goal), pure `rolloverDurationDays` stated as an invariant ("always at least as many days left as completions still needed") so it is idempotent, and `applyRollovers` which rewrites only the tasks that fell behind; +9 unit tests
- [x] R4.5b Rollover — UI — done 2026-08-17; add-task form gained a "Completion rule" radio pair (fixed window default), Tasks menu → "Completion rule" switches an existing task, tiles show `target N done` (and `N×/day` for intraday), and `AuthGate` applies rollovers on every task-list load before anything renders; +3 widget tests (156 total)
- [x] R4.6 Docs + release — done 2026-08-17; data-model gained the sound settings, `recurrence`, `completionMode`/`targetDays` and `count`; architecture documents the scheduling model, sound plumbing and rollover invariant; qa-checklist lists the new widget keys and platform caveats; `make all` rebuilt `dist/dayforge_1.0.0_amd64.deb` + `dist/dayforge-1.0.0.apk` (analyze clean, 156 tests green)
- [M] M13 — device verification of round 4 on Linux + Android (see ../manual-task.md)
- [M] M14 — Firebase console: confirm the password-reset email template/sender and receive the mail (see ../manual-task.md)

## Feedback round 5 (2026-08-19, session 14) — housekeeping + the majority rule
- [x] R5.1 Git: local `main` and `origin/main` had diverged (1 local commit vs 2 remote) — done 2026-08-19; the two remote commits net out to no change (the web edit replacing the keys with `SECRET_KEY` was undone by the next commit, so the real keys were back), so `git rebase origin/main` replayed the local commit cleanly onto them. History is linear again and the push is a fast-forward. `pull.rebase=true` set for this repo so a plain `git pull` stops asking which strategy to use
- [x] R5.2 Firebase client keys out of the working tree — done 2026-08-19; `lib/firebase_options.dart` and `android/app/google-services.json` gitignored, `.template` copies committed alongside, `make` gained a `firebase-check` prerequisite that names the missing file and how to recreate it. **They remain in git history and in tag `v1.0.0`** — the user chose not to rewrite published history (they are project identifiers, not credentials; see M15 for the rotate-instead option)
- [x] R5.3 Version naming: semver only, no build stamp in the filename — done 2026-08-19; `dayforge_1.0.0_amd64.deb` instead of `dayforge_1.0.0+13.70eab8c.dirty2026-08-18-0013_amd64.deb`. `ARTIFACT := $(VERSION)` (plus a bare `-dirty` when the tree is not clean); full provenance still reaches the app through `--dart-define=BUILD_ID` and shows in Settings → About. Scheme documented in README ("Versioning") — MAJOR = breaking data/sync format, MINOR = feature, PATCH = fix
- [x] R5.4 The majority rule for recurring tasks — done 2026-08-19; an intraday task with no explicit target now completes its day at **more than half** its occurrences (`Recurrence.majorityTarget`: 9→5, 8→5, never an exact half) rather than needing every one. The target stays *derived*, so changing the schedule moves it instead of freezing the number from creation day. Ticking no longer stops at the target either: `addTick` clamps to `maxPerDay` and flags `completed` at `targetPerDay`, so a day where you did all nine is still recorded as nine; +6 unit tests
- [x] R5.5 Say the schedule as a count, not a gap — done 2026-08-19; the add-task form's "Every…" / "N times a day" toggle. Picking a count derives the interval that fits exactly that many reminders into the window (`Recurrence.intervalForOccurrences`, with a widening loop because floor division overshoots on short windows) and stores an ordinary interval — no new field; +1 widget test (160 total)
- [x] R5.6 `make all` / `make apk` no longer risk taking the desktop down — done 2026-08-19; every build goes through `tool/capped_build.sh` (hard `MEM_MAX`, 8G default, `MemorySwapMax=0`, `nice -n 10`), `.NOTPARALLEL:` stops `-j` running the Android and Linux builds together, and `make doctor` reports the ceiling, the containment status and this machine's RAM/swap. Overshoot now OOM-kills inside the build's cgroup only. **The first attempt silently did nothing** — Flutter is a classic snap and `snap run` escapes into its own scope under `app.slice`, so the wrapper's ceiling governed an empty cgroup (caught by reading Gradle's own `memory.max`, which said `max`); the script now caps the snap scope too. Verified with a full `make all`: artifacts built, machine never below 5.5 GB available, build scope peaked ~4.3 GB. Escape hatches: `MEM_MAX=`, `ABI=android-arm64`, `CAP=` to opt out
- [x] R5.7 Vector master for the app icon — done 2026-08-19; `assets/icon/dayforge.svg` (hand-authored, 1024 grid) is now the source for the anvil-calendar mark; `tool/render_icon.sh [--install]` renders the committed PNG and regenerates the Android mipmaps + Windows .ico. Gotcha baked into the file: a gradient-stroked horizontal line has a zero-height bounding box and vanishes under `objectBoundingBox` gradient units, so the calendar's header rule is a filled rect
- [M] M15 — Firebase config on a fresh clone / optional key rotation (see ../manual-task.md)
- [M] M16 — optional swap for this laptop (see ../manual-task.md)
