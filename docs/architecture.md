# Architecture Outline

## Stack
- **Frontend:** Flutter (single codebase)
- **Targets:** Android, Windows, Linux
- **State management:** Riverpod
- **Auth:** Firebase Auth (email/password to start; Google sign-in later)
- **Database / sync:** Cloud Firestore (free Spark tier) with built-in offline persistence
- **Notifications:** flutter_local_notifications (all platforms) + FCM later for cross-device push
- **Local settings:** SharedPreferences
- **Charts:** fl_chart

No self-hosted component anywhere. All sync goes through Firestore; conflict resolution uses last-write-wins per daily-log document (documents are small and per-day, so conflicts are rare and low-risk).

## Linux desktop caveat (decided 2026-07-13)
The official FlutterFire SDKs support Android, iOS/macOS, web, and Windows — **not Linux desktop**. Decision:
- `lib/services/firebase_bootstrap.dart` guards `Firebase.initializeApp` so the app still runs on Linux.
- All data access goes through repository interfaces. On Android/Windows the implementation uses the native `firebase_auth`/`cloud_firestore` plugins; on Linux a fallback implementation will use the Firebase Auth REST API + Firestore REST API (same project, same data, no self-hosting) or a community pure-Dart package if it proves solid at implementation time (Phase 1 Tasks 5–6).
- Firebase app IDs registered: android `1:611264529887:android:0a31e3f9f698822ca5f06a`, windows(web-type) `1:611264529887:web:824852d3e4efbee0a5f06a`. Project: `advanced-todo-infinite`. The windows/web-type config in `firebase_options.dart` also carries the API key the Linux REST fallback needs.

## Layered structure (inside `lib/`)
```
lib/
  main.dart
  app/            # MaterialApp, theme, routing
  features/
    auth/         # sign-in/up screens + auth providers
    tasks/        # task CRUD (models, repository, screens)
    daily/        # today screen, checkboxes, remarks
    progress/     # streaks, history, calendar, charts
    reminders/    # scheduling, preferences
    settings/     # settings screen
  core/           # shared widgets, utils, constants, error handling
  services/       # firebase wrappers, notification service, storage
```

## State flow
UI widgets → Riverpod providers → repositories → Firestore/local storage.
Repositories expose streams; providers map them to UI state. Writes are optimistic (Firestore offline queue handles retry).

## Recurring task strategy
Tasks are stored once with `startDate` + `durationDays`. Daily entries are **not pre-generated**; the Today screen computes which tasks are active for the current date and reads/creates a `daily_logs` doc lazily when the user ticks or remarks. This keeps writes minimal (free-tier friendly).

## Reminder strategy
- Primary: local scheduled notifications per device (works offline, survives restarts via boot-time rescheduling on Android; on desktop, re-scheduled at app launch).
- Optional later: FCM for sync-related nudges. No server functions required for MVP.

## Offline strategy
Firestore persistence enabled on all platforms. App is fully usable offline; sync happens automatically when back online.
