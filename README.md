# DayForge — Daily Progress Tracker

A cross-platform (Android, Windows, Linux), cloud-synced recurring task tracker built with Flutter + Firebase. Add a task once with a duration, tick it daily, leave a short remark each day, get reminders, and watch your streaks.

Spec: [`FSD.md`](FSD.md) (single source of truth). **Status: all six FSD phases complete + feedback rounds 1–4 shipped (2026-08-17)** — snooze-able reminders with a choice of alarm sounds (bundled tones or any ringtone on the phone), reminders that stay quiet once you have ticked the task, tasks that repeat many times a day inside a window ("drink water 08:00–20:00, every 90 min") with a per-day tick counter, password reset from the sign-in screen, and a per-task completion rule — a fixed window, or a target number of completed days whose end date rolls forward when you miss one.

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

## Firebase config (first clone only)
`lib/firebase_options.dart` and `android/app/google-services.json` are **gitignored**. They hold the project's `AIza…` client keys, which GitHub's secret scanner flags on every push. (They are not credentials — they ship inside every APK; `firestore.rules` and App Check are what guard the data — they are simply not worth an alert per push.) Recreate them with either:

```
flutterfire configure --project=advanced-todo-infinite   # preferred
# or copy the checked-in templates and paste the keys from the Firebase console:
cp lib/firebase_options.dart.template lib/firebase_options.dart
cp android/app/google-services.json.template android/app/google-services.json
```

`make` refuses to start without them and says exactly this. Full steps: [`manual-task.md` M15](manual-task.md).

## Versioning
Plain semver, `MAJOR.MINOR.PATCH`, set once in `pubspec.yaml` and used everywhere:

| part | bump it when |
| --- | --- |
| **MAJOR** | a breaking change — the sync/export format or data model an older build cannot read |
| **MINOR** | a new feature, backwards compatible |
| **PATCH** | a bug fix only |

Release files are named for that and nothing else — `dayforge_1.0.0_amd64.deb`, `dayforge-1.0.0.apk` — with a `-dirty` suffix if the tree had uncommitted changes when it was built. Full provenance (commit count, sha, timestamp) still travels *inside* the binary: **Settings → About** prints it, and `make version` shows both. Tag releases `v1.0.0`.

## Build it
```
make            # everything this machine can build (.apk + .deb on Linux)
make apk        # Android release APK        -> dist/
make deb        # Debian/Ubuntu package      -> dist/
make version    # what this build would be called
make doctor     # memory budget, containment, RAM/swap
make test       # flutter analyze + flutter test
```

Builds run inside a systemd scope with a hard memory ceiling (`MEM_MAX`, 8G default), because Gradle's JVM, the Kotlin daemon and one `gen_snapshot` per ABI all peak together — on a machine with no swap that used to get the *desktop session* OOM-killed rather than the build. Overshoot now kills only the build. If it does: `make apk ABI=android-arm64` (≈⅓ the work and RAM, right for any phone made this decade) or `make apk MEM_MAX=10G`.

## Run it
```
# Linux desktop (release build lives in the repo)
./build/linux/x64/release/bundle/advanced_todo

# Android
flutter build apk --release   # then install build/app/outputs/flutter-apk/app-release.apk

# Windows (on a Windows machine)
flutter build windows
```

## Icon
`assets/icon/dayforge.svg` is the master. `assets/icon/dayforge.png` is a build product (committed, because flutter_launcher_icons and the .deb packaging both need a raster). After editing the SVG:
```
tool/render_icon.sh --install   # re-renders the PNG, then the mipmaps + .ico
```

## Development
Flutter SDK lives at `~/development/flutter` (installed by the setup task).
```
export PATH="$HOME/development/flutter/bin:$PATH"
flutter pub get
flutter analyze && flutter test
```
