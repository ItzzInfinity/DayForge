# Claude Code Master Prompt — Advanced Progress Tracker

## Purpose
Build a cross-platform, cloud-synced progress tracker that behaves like an advanced recurring todo system.

## Core goal
Create an app that lets me:

- add a task once,
- choose how many days it should continue,
- tick it daily,
- add short remarks beside the daily completion checkbox,
- receive reminders on each device,
- track progress over time,
- resume safely after context/token exhaustion without losing work.

## Hard constraints
- **No self-hosting**
- Must support **Android, Windows, and Linux**
- Must be designed for **Claude Code on Linux**
- Prefer **free-tier cloud services** only
- Must support **daily recurring completion**
- Must support **remarks/notes per day**
- Must have **resume/checkpoint support** if context runs out
- Must be implemented with independent tasks that can be split across sub-agents

## Project definition
This is not a simple todo app.

It is a **task lifecycle and daily progress system** with:

- task creation
- default duration settings
- recurring daily task generation
- completion checkbox
- short remark entry on each completed or skipped day
- reminder notifications
- progress streak tracking
- task history
- sync across devices
- offline-friendly behavior
- checkpointed development workflow

## Recommended stack
Use a stack that avoids self-hosting and works well on Linux:

- **Frontend:** Flutter
- **Targets:** Android, Windows, Linux
- **Authentication:** Firebase Auth
- **Database:** Cloud Firestore
- **Notifications:** Firebase Cloud Messaging + local notifications
- **Offline cache:** Firestore persistence and/or lightweight local storage
- **State management:** Riverpod or Bloc
- **Charts:** FL Chart or similar
- **Local settings:** Hive / SharedPreferences

## Product rules for Claude Code
Before coding, first produce:
1. a short architecture outline,
2. a data model,
3. a task breakdown,
4. a file/folder plan,
5. a checkpoint strategy.

Then execute in small, independent increments.

## Sub-agent breakdown
Use separate mental agents or workstreams. Each workstream must be independent and have a clear output.

### Agent 1 — Product / Requirements
**Goal:** define exactly what the app does and does not do.

**Tasks**
- Convert the idea into a crisp feature list.
- Define the minimum viable product.
- Identify which features are phase 1 vs later.
- Write acceptance criteria for the final app.

**Done when**
- requirements are unambiguous,
- scope is narrow enough to build,
- acceptance criteria are written.

### Agent 2 — Architecture
**Goal:** design the system so it stays simple and cloud-based.

**Tasks**
- choose the app structure,
- define state flow,
- define sync strategy,
- define reminder strategy,
- define offline strategy,
- define how device sync works without self-hosting.

**Done when**
- architecture is documented,
- no part depends on a self-hosted server,
- cross-platform support is preserved.

### Agent 3 — Data Model
**Goal:** design the database to support recurring tasks and daily remarks.

**Tasks**
- define `users`,
- define `tasks`,
- define `daily_logs`,
- define `settings`,
- define reminder fields,
- define streak/progress calculation fields.

**Done when**
- the schema can represent daily completion and remarks,
- it supports duration-based tasks,
- it supports multi-device sync.

### Agent 4 — UI / UX
**Goal:** make the app easy to use every day.

**Tasks**
- define home screen,
- define add-task flow,
- define daily tick flow,
- define remark input,
- define settings page,
- define task history / calendar view.

**Done when**
- the daily workflow takes only a few taps,
- remark entry is quick,
- the UI is usable on mobile and desktop.

### Agent 5 — Notifications
**Goal:** make reminders reliable across devices.

**Tasks**
- define reminder scheduling,
- define notification permissions,
- define local fallback reminders,
- define cross-device reminder behavior,
- define quiet hours / snooze if needed.

**Done when**
- reminders are practical,
- reminders can survive app restarts,
- reminders do not depend on self-hosting.

### Agent 6 — Implementation / QA
**Goal:** build and verify each piece safely.

**Tasks**
- implement one module at a time,
- write basic tests,
- run self-checks,
- verify no feature breaks another,
- keep the code runnable on Linux.

**Done when**
- the app runs,
- core flows work,
- tests or sanity checks pass,
- outputs are documented.

## Actionable todo list by phase

### Phase 0 — Planning
- [ ] Write the product requirements document
- [ ] Freeze the MVP scope
- [ ] Define success criteria
- [ ] Decide cloud services and free-tier limits
- [ ] Define file structure for the repo
- [ ] Define checkpoint/resume format

### Phase 1 — Foundation
- [ ] Create Flutter project
- [ ] Set up platform targets for Android, Windows, Linux
- [ ] Add state management
- [ ] Add app theme and base navigation
- [ ] Add Firebase project configuration
- [ ] Add authentication flow
- [ ] Add Firestore integration

### Phase 2 — Core data + task flow
- [ ] Create task model
- [ ] Create daily log model
- [ ] Build add-task screen
- [ ] Add default duration setting
- [ ] Add recurring duration logic
- [ ] Build today screen with checkboxes
- [ ] Add remark input beside each daily completion
- [ ] Save task completion to database

### Phase 3 — Reminders
- [ ] Define reminder time per task or global default
- [ ] Add local notifications
- [ ] Add FCM if needed for sync-related push
- [ ] Add snooze / retry logic
- [ ] Add notification preference settings

### Phase 4 — Progress tracking
- [ ] Add streak calculation
- [ ] Add completion percentage
- [ ] Add task history timeline
- [ ] Add calendar view
- [ ] Add task filtering by category/status
- [ ] Add search

### Phase 5 — Reliability
- [ ] Add offline-first behavior
- [ ] Add conflict handling for multi-device edits
- [ ] Add export to JSON/CSV/Markdown
- [ ] Add backup/restore flow
- [ ] Add error handling and retry states

### Phase 6 — Polish
- [ ] Add dark mode
- [ ] Improve empty states
- [ ] Improve desktop layout
- [ ] Improve mobile layout
- [ ] Add onboarding
- [ ] Add help text for daily logging

## Definition of “independent task”
Each task must:
- have its own goal,
- have its own output,
- not require unfinished work from another task unless explicitly declared,
- be small enough to finish in one focused step,
- end with a clear self-check.

## Self-check rules
After every task, Claude Code must verify:

- Did the output match the goal?
- Did it introduce any dependency on self-hosting?
- Does it work on Linux?
- Does it preserve Android and Windows support?
- Is the new code or doc consistent with the data model?
- Can the task be resumed later without confusion?

## Deliverable structure for the repo
Recommended files:

- `README.md` — project overview
- `docs/requirements.md` — product scope and rules
- `docs/architecture.md` — system design
- `docs/data-model.md` — Firestore schema
- `docs/roadmap.md` — phased task list
- `docs/checkpoints.md` — resume notes
- `docs/qa-checklist.md` — validation steps
- `lib/` — Flutter app code
- `test/` — tests

## Resume / token exhaustion protocol
If token or context budget is running low, Claude Code must not continue blindly.

Instead it must:
1. finish the current atomic task,
2. write a checkpoint summary,
3. note what is done,
4. note what is partially done,
5. note what remains,
6. list any files changed,
7. include the next exact action to continue from,
8. stop cleanly.

### Checkpoint format
Create or update `docs/checkpoints.md` with:

- current phase
- completed tasks
- current task
- blocked items
- files changed
- next step
- any assumptions made

### Resume instruction
When work resumes the next day:
- read `docs/checkpoints.md` first,
- continue from the exact next unfinished item,
- do not redo completed work,
- do not skip the self-check.

## Build order
Use this order:
1. requirements
2. architecture
3. data model
4. UI skeleton
5. task creation
6. daily completion flow
7. remarks
8. reminders
9. sync/offline
10. progress analytics
11. export/backup
12. QA and polish

## Final acceptance criteria
The project is done when:

- I can add a task with a duration
- I can mark it complete every day
- I can add a short remark each day
- the app works on Android, Windows, and Linux
- reminders work
- progress is saved in the cloud
- no self-hosting is required
- the system can be resumed cleanly after token exhaustion

## Instruction to Claude Code
Work like an execution-focused engineer:
- think carefully,
- break work into small independent units,
- keep output consistent,
- update checkpoints often,
- never lose context,
- always be ready to resume.

Start by generating the architecture, data model, and phase-wise implementation plan.