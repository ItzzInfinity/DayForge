# Roadmap & Progress Tracker

Source of truth for task status. Update after every completed task.
Legend: `[ ]` pending · `[~]` in progress · `[x]` done · `[M]` waiting on manual step (see `../manual-task.md`)

## Phase 0 — Planning
- [x] Define file structure for the repo (this docs set)
- [x] Define checkpoint/resume format (`docs/checkpoints.md`)
- [x] Architecture outline (`docs/architecture.md`)
- [x] Data model outline (`docs/data-model.md`)
- [ ] Full product requirements document (`docs/requirements.md`) — expand when needed

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
- [ ] Offline-first behavior
- [ ] Multi-device conflict handling
- [ ] Export to JSON/CSV/Markdown
- [ ] Backup/restore flow
- [ ] Error handling and retry states

## Phase 6 — Polish
- [ ] Dark mode
- [ ] Empty states
- [ ] Desktop layout
- [ ] Mobile layout
- [ ] Onboarding
- [ ] Help text for daily logging
