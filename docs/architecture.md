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

### When a day counts as done (the majority rule, 2026-08-19)
A task that repeats many times a day completes its day at a **strict majority** of its occurrences — 5 of 9, 5 of 8, never an exact half (`Recurrence.majorityTarget`). A day where you drank six of nine glasses is a day you kept the habit; marking it missed breaks streaks the user was actually keeping.

Two properties make this behave rather than surprise:

- **The target is derived, not stored.** `targetPerDay: null` stays null in Firestore, and `Recurrence.targetPerDay` computes the majority on read. Widen the task's window later and the bar moves with it, instead of enforcing arithmetic frozen on the day it was created. A number written into that field is an explicit override and wins.
- **Completing is not the same as capping.** `DailyLogRepository.addTick` takes `target` *and* `max`: it clamps the counter at `maxPerDay` (every occurrence) but flips `completed` at `targetPerDay`. Reaching the majority marks the day done without closing the counter, so a nine-of-nine day is still recorded as nine.

Everything downstream — streaks, the heatmap, the calendar, exports — keeps reading the single `completed` flag and needed no change.

The add-task form can describe the same schedule either way round: a gap ("every 90 minutes") or a count ("8 times a day"). The count path runs `Recurrence.intervalForOccurrences` to find the interval that fits exactly that many reminders into the window and stores an ordinary interval — the count is a UI affordance, not a second representation in the data model.

## Build and release
- **Versioning** is plain semver in `pubspec.yaml`; artifacts are named for it and nothing else (`dayforge_1.0.0_amd64.deb`). The full build stamp — commit count, sha, dirty timestamp — travels inside the binary via `--dart-define=BUILD_ID` and surfaces in Settings → About, so a file is named for its release while the running app can still say exactly which build it is. See README → Versioning.
- **Memory containment.** Gradle's JVM, the Kotlin daemon and one `gen_snapshot` per ABI all peak together, and a JVM heap flag bounds only the first of those. Every Flutter build therefore goes through `tool/capped_build.sh`, which puts a hard memory ceiling (`MEM_MAX`, 8G default) on the whole process tree at `nice -n 10`; `.NOTPARALLEL:` stops `make -j` running the Android and Linux builds at once. An overshoot OOM-kills inside the build's own cgroup; on a machine with no swap it used to take the desktop session instead. `make doctor` reports the ceiling, whether containment is active, and the host's RAM/swap.

  It is a script rather than a bare `systemd-run --scope` because **Flutter is installed here as a classic snap**, and `snap run` does not stay in the cgroup it was launched from — snapd asks systemd for a fresh `snap.flutter.flutter-<uuid>.scope` under `app.slice`, a *sibling* of the wrapper. A ceiling on the wrapper's scope therefore governs an empty cgroup while Gradle runs unbounded next door (verified 2026-08-19: the build's Gradle process reported `memory.max = max`). The script starts the build in a capped scope *and* watches for a snap scope that did not exist beforehand, applying the same ceiling to it with `systemctl --user set-property --runtime`. Only newly created scopes are touched, so an already-running Flutter or VS Code snap is left alone.
- **Firebase client config** (`lib/firebase_options.dart`, `android/app/google-services.json`) is gitignored with `.template` copies committed; `make` will not start without the real files. The keys are project identifiers rather than credentials — `firestore.rules` and App Check are the access control — but GitHub's scanner flags the pattern on every push.
- **The app icon** is a vector: `assets/icon/dayforge.svg` is the master and `tool/render_icon.sh [--install]` renders the committed PNG plus the Android mipmaps and Windows `.ico`. The PNG stays in the repo because flutter_launcher_icons and the `.deb` packaging both need a raster.

## Reminder strategy
- Primary: local scheduled notifications per device (works offline, survives restarts via boot-time rescheduling on Android; on desktop, re-scheduled at app launch).
- Optional later: FCM for sync-related nudges. No server functions required for MVP.

**Scheduling model (round 4, 2026-08-17).** `ReminderScheduler.sync` replaces
every scheduled notification on each change, from three inputs bundled in
`ReminderOptions`: the default time, the snooze length and the chosen sound —
plus `completedToday`, the set of tasks already ticked, whose reminder for
*today* is skipped (`nextReminderInstant`). A task contributes one time a day,
or every slot of its intraday window (`reminderTimesFor`). Ids are
`stableNotificationId(taskId) * 64 + slot`, with the last slot reserved for the
snoozed one-shot, which is why occurrences are capped at 48 a day.

**Sound.** Bundled tones are synthesised by `tool/generate_sounds.py` (no
third-party audio licence) into a Flutter asset (Linux) and an Android raw
resource. Android channels are immutable, so the channel id encodes the sound
and the alarm-volume flag (`ReminderSoundChoice.channelKey`); "Pick from
device" goes through the `dayforge/sound_picker` MethodChannel in
`MainActivity` (RingtoneManager). Windows maps the tones onto built-in toast
sounds — custom audio there needs an MSIX package.

**Rollover.** `completionMode: targetDays` tasks keep their end date far
enough out to still reach `targetDays` completed days; `applyRollovers` runs
on every task-list load and is idempotent, so the refresh it triggers settles
at once.

## Offline & conflict strategy (reviewed 2026-07-13, Phase 5)

**Android / Windows (native SDK):** Firestore offline persistence is enabled
(`firebase_bootstrap.dart`). Reads serve from the local cache; writes queue and
sync automatically when back online. The app is fully usable offline.

**Linux (REST gateway): online-only — accepted limitation.** The REST gateway
has no local cache or write queue; a lost connection surfaces as a
SocketException/ClientException. Mitigations in place instead of a cache:
- Every failed load shows a friendly message ("No connection…") with a Retry
  button (`lib/core/widgets/error_retry.dart`), never a raw exception dump.
- Daily-log writes are idempotent (doc id = date key, merge writes), so
  retrying a tick/remark after reconnecting can never duplicate or corrupt data.
- A lightweight read cache could be added later if Linux offline use becomes a
  real need; not justified for the MVP.

**Multi-device conflicts:** bounded by design rather than resolved at runtime:
- All writes are per-field **merge** writes; the checkbox (`completed`/
  `completedAt`) and the remark are written as separate field sets, so ticking
  on the phone and typing a remark on the desktop never clobber each other,
  even for the same day.
- Within a single field, Firestore applies last-write-wins. Documents are tiny
  and per-day/per-task, so a genuine same-field race (two devices editing the
  same remark at the same moment) loses at most one short edit — acceptable.
- Derived data (streaks, completion %) is computed client-side from logs and
  never stored, so it cannot conflict or go stale.
