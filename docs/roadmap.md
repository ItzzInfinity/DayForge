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
