# Advanced To-Do — Daily Progress Tracker

A cross-platform (Android, Windows, Linux), cloud-synced recurring task tracker built with Flutter + Firebase. Add a task once with a duration, tick it daily, leave a short remark each day, get reminders, and watch your streaks.

Spec: [`FSD.md`](FSD.md) (single source of truth).

## Project docs
- [`docs/roadmap.md`](docs/roadmap.md) — phase-by-phase progress tracker
- [`docs/checkpoints.md`](docs/checkpoints.md) — session resume notes (read this first when resuming)
- [`docs/architecture.md`](docs/architecture.md) — system design
- [`docs/data-model.md`](docs/data-model.md) — Firestore schema
- [`manual-task.md`](manual-task.md) — actions the user must do (accounts, keys, consoles)

## Stack
Flutter · Riverpod · Firebase Auth · Cloud Firestore · local notifications · fl_chart

## Development
Flutter SDK lives at `~/development/flutter` (installed by the setup task).
```
export PATH="$HOME/development/flutter/bin:$PATH"
flutter pub get
flutter test
```
