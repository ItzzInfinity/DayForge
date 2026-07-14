# DayForge — Daily Progress Tracker

A cross-platform (Android, Windows, Linux), cloud-synced recurring task tracker built with Flutter + Firebase. Add a task once with a duration, tick it daily, leave a short remark each day, get reminders, and watch your streaks.

Spec: [`FSD.md`](FSD.md) (single source of truth). **Status: all six FSD phases complete + feedback round 1 shipped (2026-07-13)** — snooze-able reminders, daily motivational quotes (bundled 593-quote rotation), archive tucked into Settings, completed-tasks-sink + 🎉 banner on Today, readable calendar day numbers, double-tap filter reset.

## Project docs
- [`docs/requirements.md`](docs/requirements.md) — final scope + acceptance-criteria mapping
- [`docs/roadmap.md`](docs/roadmap.md) — phase-by-phase progress tracker
- [`docs/checkpoints.md`](docs/checkpoints.md) — session resume notes (read this first when resuming)
- [`docs/architecture.md`](docs/architecture.md) — system design (incl. the Linux/REST caveat)
- [`docs/data-model.md`](docs/data-model.md) — Firestore schema
- [`docs/qa-checklist.md`](docs/qa-checklist.md) — validation steps
- [`manual-task.md`](manual-task.md) — actions the user must do (accounts, keys, consoles)

## Stack
Flutter · Riverpod · Firebase Auth · Cloud Firestore (Spark free tier) · flutter_local_notifications · file_selector / share_plus (export). On Linux, Firebase is reached through its REST APIs (no official SDK) behind the same repository interfaces.

## Run it
```
# Linux desktop (release build lives in the repo)
./build/linux/x64/release/bundle/advanced_todo

# Android
flutter build apk --release   # then install build/app/outputs/flutter-apk/app-release.apk

# Windows (on a Windows machine)
flutter build windows
```

## Development
Flutter SDK lives at `~/development/flutter` (installed by the setup task).
```
export PATH="$HOME/development/flutter/bin:$PATH"
flutter pub get
flutter analyze && flutter test
```
