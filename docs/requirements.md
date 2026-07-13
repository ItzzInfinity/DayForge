# Product Requirements — Advanced Progress Tracker

Finalized 2026-07-13 at project completion; the authoritative spec remains
[`../FSD.md`](../FSD.md). This document freezes what was built, what was
deliberately left out, and how each acceptance criterion is met.

## What the app is
A task lifecycle + daily progress system: add a task once with a duration
(N days), tick it off each day, leave a short remark per day, get a daily
reminder on every device, and track streaks/completion — synced through the
cloud with no self-hosted component.

## MVP scope (all shipped)
- Email/password accounts (Firebase Auth); each user sees only their own data.
- Tasks: title, description, category, start date, duration (days), optional
  per-task reminder time, status (active/completed/archived).
- Daily logging: one checkbox + one remark per task per day; remarks allowed
  on skipped days; writes are idempotent (one doc per day).
- Reminders: daily local notifications per device at the task's time or the
  global default; test-notification button; on/off preference.
- Progress: current streak, completion %, per-task calendar of the whole run,
  chronological history with remarks.
- Task management: search, status + category filters, complete/reactivate/
  archive/delete (cascade).
- Settings: default duration, default reminder time, notifications on/off,
  theme (system/light/dark) — synced per account.
- Export: full data to JSON (backup format), CSV, or Markdown.
- Platforms: Android, Windows, Linux from one Flutter codebase.

## Explicitly out of scope (optional leftovers)
- JSON import/restore (the export IS the backup; restore is manual for now).
- FCM push — local notifications satisfy the reminder requirement without
  server-side components.
- Snooze / quiet hours.
- Google sign-in (email/password only).
- Charts library (fl_chart) — progress bars + calendar grids cover the need.

## Final acceptance criteria → how each is met
| Criterion (FSD) | Implementation | Verified |
| --- | --- | --- |
| Add a task with a duration | Add-task form → `TaskRepository` → `users/{uid}/tasks` | Unit+widget tests; live on Linux (M7·2) |
| Mark it complete every day | Today screen checkbox → `daily_logs/{YYYY-MM-DD}` merge write | Tests; live (M7·3) |
| Add a short remark each day | Inline remark field, saves on submit/blur, skipped days too | Tests; live (M7·4) |
| Works on Android, Windows, Linux | Native Firebase SDKs (Android/Windows) + REST gateway (Linux) behind one interface | Android device ✓ (M6), Linux desktop ✓ (M7); Windows builds from the same codebase — verify when a Windows machine is available (M8·7) |
| Reminders work | Platform strategies: Android daily zonedSchedule (boot-safe), Windows 7-day toasts, Linux in-app timers | Fired simultaneously on phone + Ubuntu ✓ (M6/M7·7) |
| Progress saved in the cloud | Cloud Firestore, owner-only security rules | Console-verified docs + live 403 checks (M7·5) |
| No self-hosting | Firebase Spark free tier only; no servers, no functions | By construction; reviewed each task |
| Resumes cleanly after token exhaustion | `docs/checkpoints.md` protocol (state, next exact step, self-check) | Used across 8+ sessions incl. compactions |

## Success criteria / free-tier limits (decided Phase 0)
- Firebase Spark: 50K reads / 20K writes per day — usage is bounded by lazy
  daily-log creation, client-side derived stats (never stored), and a 10s
  polling budget on the Linux REST watch.
- The daily workflow (open → tick → remark) stays within 2 taps + typing.
