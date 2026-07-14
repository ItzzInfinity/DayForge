# Manual Tasks (require your action)

Everything that needs an account, a key, or a console click lives here. Claude Code cannot do these for you. Each item says exactly what to do and which roadmap task it unblocks. Nothing here is needed for Phase 1 Task 1–3.

## Pending

### M1 — Create a Firebase project (unblocks Phase 1, Task 4)
 - [x] 1. Go to https://console.firebase.google.com and sign in with a Google account.
 - [x] 2. Click **Add project**, name it (e.g. `advanced-todo`), disable Google Analytics (not needed), create.
 - [x] 3. Stay on the free **Spark** plan — do not enter billing details.
 - [x] 4. Done 2026-07-13: `firebase login` completed (account pcinfinitesolutions@gmail.com) and `flutterfire configure` linked the app to project `advanced-todo-infinite` (android + windows apps registered).

### M2 — Enable Email/Password authentication (unblocks Phase 1, Task 5)
 - [x] 1. In the Firebase console → **Build → Authentication → Get started**.
 - [x] 2. Under **Sign-in method**, enable **Email/Password**. Save.

### M3 — Enable Cloud Firestore (unblocks Phase 1, Task 6)
 - [x] 1. In the Firebase console → **Build → Firestore Database → Create database**.
 - [x] 2. Choose a location close to you (e.g. `asia-south1` for India). Start in **production mode** (Claude Code will write the security rules).

### M4 — Android toolchain (only needed when you want to build/run the Android app)
 - [x] 1. Install Android Studio from https://developer.android.com/studio (or just the command-line SDK tools).
 - [x] 2. Run `flutter doctor` and follow its Android licence prompts (`flutter doctor --android-licenses`).
3. Note: `flutter create` warned that the installed Java version is newer than the project's Gradle supports. When you set up Android, tell Claude Code and it will bump `android/gradle/wrapper/gradle-wrapper.properties` to a compatible Gradle version.

### M5 — Linux desktop build packages (needed to run the app on this machine)
 - [x] 1. Run in a terminal (requires sudo):
```
sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev libstdc++-12-dev
```
- [x] Then run `flutter doctor` to confirm "Linux toolchain" shows a checkmark.

### M6 — Verify reminders on your Android phone (optional, when convenient)
1. Enable USB debugging on the phone, plug it in, run `flutter devices` to confirm it's seen.
2. Install the app: `flutter run` (or `flutter install` after a build) from the repo root.
- [x] Took the app-debug.apk and installed it on my Android phone.
- [x] Sign in, add a task with a reminder time a few minutes ahead, close the app, and confirm the notification arrives (allow the notification permission when prompted).
- [x] Got Notification on my Android phone.

### M7 — Verify the Linux app end to end
Run the release build from the repo root:
```
./build/linux/x64/release/bundle/advanced_todo
```
Then walk this checklist (each step maps to an acceptance criterion in FSD.md):

- [x] 1. **Sign up:** create an account with your real email + a password (min 6 chars). You should land on the Today screen.
- [x] 2. **Add a task:** Tasks tab → + → give it a title, leave duration 21, set a reminder time ~3 minutes from now → Create. It appears in the list with its date range.
- [x] 3. **Tick it:** Today tab → the task shows "Day 1 of 21" → tick the checkbox.
- [x] 4. **Remark:** type a short note in the "Add a remark for today…" field and press Enter.
- [x] 5. **Cloud sync:** open https://console.firebase.google.com/project/advanced-todo-infinite/firestore and confirm you see `users/<your-uid>/tasks/<task>/daily_logs/<today>` with `completed: true` and your remark.
- [x] 6. **Persistence:** close the app fully, reopen it — you should still be signed in, with the tick and remark intact.
- [x] 7. **Reminder (app running):** verified 2026-07-13 after re-test — reminder fired simultaneously on Android phone and Ubuntu. (First attempt failed only because the reminder time had already passed during earlier checklist steps; diagnosis in docs/checkpoints.md.)
- [x] 8. **Sign out/in:** Settings tab → Sign out → sign back in — data still there.

Report anything that fails (with what you saw) and Claude Code will fix it before moving on.

### M8 — Final acceptance verification (all FSD phases complete)
Fresh artifacts (2026-07-13): Linux `./build/linux/x64/release/bundle/advanced_todo`, Android `build/app/outputs/flutter-apk/app-release.apk` (install this over the old debug APK — it's the faster release build; Android may ask you to uninstall the debug version first because the signature differs).

Covers what M6/M7 didn't. Run the Linux app and have your phone nearby:

- [x] 1. **Onboarding:** Settings → Sign out, then create a brand-new throwaway account (any email-like string works). The Today screen should explain the 3-step loop with an "Add your first task" button; tap it, create a task, and it should appear on Today immediately. Then sign out and back into your real account.
- [x] 2. **Cross-device sync:** with the same account on phone + Linux, tick today's checkbox on the phone → within ~10 seconds the tick shows on Linux after switching tabs or pressing the entry (Linux polls every 10s). Type a remark on Linux → confirm it appears on the phone. Neither edit should overwrite the other.
- [x] 3. **Export:** Settings → Export data → JSON → save it somewhere and open the file: your tasks, daily history and settings should all be there. Try Markdown too — it should read like a report.
- [x] 4. **Theme:** Settings → Theme → Dark. The app should switch immediately, and still be dark after closing/reopening — on both devices (it's synced).
- [x] 5. **Offline (Android):** put the phone in airplane mode, tick today's task, reopen the app — the tick should still be there. Disable airplane mode, wait a moment, and confirm the tick reached Linux/the Firestore console (offline writes queue and sync).
- [x] 6. **Offline (Linux):** disconnect Wi-Fi/ethernet on the desktop and switch tabs — you should get a friendly "No connection. Check your internet and retry." message with a Retry button (NOT a technical error dump). Reconnect, press Retry, everything returns. (Linux is online-only by design.)
- [ ] 7. **(Optional) Windows:** if you ever have a Windows machine: install Flutter there, run `flutter build windows` in this repo, and walk the M7 checklist. The code path is the same native Firebase SDK that already passed on Android.
- [x] 8. **Filters/search/progress spot-check:** Tasks tab → search for part of a title; Progress tab → streak flame + % look right; open a task → calendar shows your ticked days in green.

When these pass, every FSD acceptance criterion is user-verified. Anything that fails: note what you saw and Claude Code will fix it.

### M9 — Verify feedback-round-1 features (2026-07-13)
Fresh artifacts: Linux `./build/linux/x64/release/bundle/advanced_todo`, Android `build/app/outputs/flutter-apk/app-release.apk` (58 MB — install over the previous release APK; same signature, no uninstall needed).

- [x] 1. **Calendar readability (both devices):** open any task's detail — day numbers in the circles should now be clearly readable, and on Linux the calendar shouldn't stretch into giant circles.
- [x] 2. **Archive flow:** Tasks tab → archive a task from its menu — it vanishes from the list (a snackbar points to Settings). Settings → Archived tasks → restore it (back to Active) or delete it. The Archived filter chip is gone from the Tasks tab.
- [x] 3. **Filter double-tap:** Tasks tab → tap "Active" (already selected) — filter resets to All. Same for Completed.
- [ ] 4. **Completed-to-bottom + congrats:** with 2+ tasks active today, tick one — it moves under "Completed today". Tick all — a 🎉 "All done for today!" banner pops in.
- [x] 5. **Quotes:** Today shows a quote under the app bar (online: with "· zenquotes.io"; offline: from the bundled list — should still appear). Tick a task — a quote snackbar appears. Tomorrow the daily quote should differ.
- [x] 6. **Snooze (Android):** set a task reminder ~2 min ahead, close the app. When the notification arrives it has a "Snooze 10 min" button — tap it; the notification should return ~10 min later (repeatable). Change Settings → Snooze duration to 5 and confirm the button label updates on the next reminder.
- [x] 7. **Snooze (Linux, app running):** same — the desktop notification shows a Snooze button; tapping it re-notifies after the set duration while the app stays open.

### M10 — Verify the first-run tutorial (2026-07-14)
Fresh artifacts in `dist/` after `make all`: Linux `dist/dayforge_1.0.0_amd64.deb` (or run `./build/linux/x64/release/bundle/advanced_todo`), Android `dist/dayforge-1.0.0.apk` (install over the previous release APK; the app id is unchanged so it upgrades in place — no uninstall — and shows the new DayForge name/icon).

The tour is per-device and shows only on first launch, so to re-test you must clear the "seen" flag:
- **Linux:** delete the prefs file, e.g. `rm ~/.local/share/com.example.advanced_todo/shared_preferences.json` (path may vary by bundle id) — or just try it on a device that hasn't run this build yet.
- **Android:** app info → Storage → Clear data (this also signs you out; sign back in after), or install on a fresh device.

- [ ] 1. **It appears on first run:** launch the app (signed in). The screen blacks out with a bright circle over the **Today** nav icon and a card titled "Today — your daily checklist".
- [ ] 2. **NEXT walks the tabs:** tap **NEXT** — the spotlight moves to **Tasks** and the app switches to the Tasks tab; again → **Progress**; again → **Settings**, where the button reads **DONE**.
- [ ] 3. **DONE ends it:** tap **DONE** — the overlay disappears and you're on the normal app.
- [ ] 4. **It does not return:** fully close and reopen the app — the tour should NOT show again.
- [ ] 5. **Skip works:** clear the flag again (step above), relaunch, tap **Skip** on the first card — the tour ends immediately and does not return on the next launch.
- [ ] 6. **Readability:** the title/body text and the NEXT button are legible against the dark scrim in both light and dark theme.

## Completed
- M1 — Create a Firebase project
- M2 — Enable Email/Password authentication
- M3 — Enable Cloud Firestore
- M4 — Android toolchain
- M5 — Linux desktop build packages
- M6 — Reminders verified on Android phone (2026-07-13)
- M7 — Linux app verified end to end, incl. reminders (2026-07-13)
