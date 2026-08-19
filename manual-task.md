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
- [x] 4. **Completed-to-bottom + congrats:** with 2+ tasks active today, tick one — it moves under "Completed today". Tick all — a 🎉 "All done for today!" banner pops in.
- [x] 5. **Quotes:** Today shows a quote under the app bar (online: with "· zenquotes.io"; offline: from the bundled list — should still appear). Tick a task — a quote snackbar appears. Tomorrow the daily quote should differ.
- [x] 6. **Snooze (Android):** set a task reminder ~2 min ahead, close the app. When the notification arrives it has a "Snooze 10 min" button — tap it; the notification should return ~10 min later (repeatable). Change Settings → Snooze duration to 5 and confirm the button label updates on the next reminder.
- [x] 7. **Snooze (Linux, app running):** same — the desktop notification shows a Snooze button; tapping it re-notifies after the set duration while the app stays open.

### M10 — Verify the first-run tutorial (2026-07-14)
Fresh artifacts in `dist/` after `make all`: Linux `dist/dayforge_1.0.0_amd64.deb` (or run `./build/linux/x64/release/bundle/advanced_todo`), Android `dist/dayforge-1.0.0.apk` (install over the previous release APK; the app id is unchanged so it upgrades in place — no uninstall — and shows the new DayForge name/icon).

The tour is per-device and shows only on first launch, so to re-test you must clear the "seen" flag:
- **Linux:** delete the prefs file, e.g. `rm ~/.local/share/com.example.advanced_todo/shared_preferences.json` (path may vary by bundle id) — or just try it on a device that hasn't run this build yet.
- **Android:** app info → Storage → Clear data (this also signs you out; sign back in after), or install on a fresh device.

- [x] 1. **It appears on first run:** launch the app (signed in). The screen blacks out with a bright circle over the **Today** nav icon and a card titled "Today — your daily checklist".
- [x] 2. **NEXT walks the tabs:** tap **NEXT** — the spotlight moves to **Tasks** and the app switches to the Tasks tab; again → **Progress**; again → **Settings**, where the button reads **DONE**.
- [x] 3. **DONE ends it:** tap **DONE** — the overlay disappears and you're on the normal app.
- [x] 4. **It does not return:** fully close and reopen the app — the tour should NOT show again.
- [x] 5. **Skip works:** clear the flag again (step above), relaunch, tap **Skip** on the first card — the tour ends immediately and does not return on the next launch.
- [x] 6. **Readability:** the title/body text and the NEXT button are legible against the dark scrim in both light and dark theme.

> **Android install note (2026-07-14, after M10 was verified):** the app id has since changed to `com.itzzinfinity.advanced_todo`, so the **next** APK installs as a **new** app next to the old one. Uninstall the old app first — your data lives in Firestore; just sign in again. Optional cleanup: Firebase console → Project settings → General → delete the old Android app (`com.sisirradar.advanced_todo`) once the old install is gone.

### M11 — Verify feedback-round-3 features (2026-07-14)
Fresh artifacts in `dist/` after `make all`: Linux `dist/dayforge_1.0.0_amd64.deb` (or `./build/linux/x64/release/bundle/advanced_todo`), Android `dist/dayforge-1.0.0.apk`.

⚠️ **Android:** the app id changed (see the note above) — uninstall the old app first, install this APK, sign in again. Your tasks/history come back from Firestore.

- [x] 1. **+ everywhere:** the + button shows on Today, Tasks and Progress (not Settings) and opens the add-task form from each.
- [x] 2. **Heatmap (desktop):** Progress on Linux — the activity grid now spans the card's full width with bigger cells/more weeks. Resize the window: it adapts, never scrolls sideways.
- [x] 3. **Heatmap (mobile portrait):** Progress on the phone held upright — the grid fits with nothing cut off or overflowing.
- [x] 4. **Deadline edit:** Tasks → a task's menu → "Change deadline" → pick a later date — the tile shows the new range/day count and Today/Progress reflect it.
- [x] 5. **Today branding:** Today's app bar reads **DayForge** top-left with `Today · <date>` beneath.
- [x] 6. **Quotes:** the daily quote card and tick snackbars show quotes with no "zenquotes.io" anywhere; still fine offline; tomorrow's quote differs.
- [x] 7. **Categories on create:** add a task — suggestion chips (Learning/Skill/Habit/Health/Fitness/Work/Personal) are offered; select two, add a custom one via the "Add your own category" field (+); after creating, the Tasks tile shows all of them comma-separated and the filter chips include the custom one.
- [x] 8. **Old tasks keep their category:** tasks created before this build still show their original category (it migrated to the new format).
- [x] 9. **Progress filter:** Progress tab → category chips under the app bar — selecting one narrows the heatmap + cards to tasks carrying it; deselecting restores all.
- [x] 10. **New Android identity:** notifications still arrive (reminder + snooze + Mark completed) on the reinstalled app.

### M12 — Verify "Mark completed" from the notification with the app fully closed (2026-07-14)
Fresh APK in `dist/dayforge-1.0.0.apk` after `make apk`. Fixes a silent no-op where tapping **Mark completed** did nothing when the app process was dead (the background isolate read the auth session before it had hydrated, so the write was skipped).

- [x] 1. Sign in, add a task with a reminder ~2 min ahead, then **swipe the app away** from recents so the process is truly killed.
- [x] 2. When the reminder fires, tap **Mark completed** on the notification.
- [x] 3. Reopen the app → Today should show that task ticked for today (and the Firestore `daily_logs/<today>` doc has `completed: true`). Confirm it ticked the *right* task if you have several.

### M13 — Verify feedback-round-4 features (2026-08-17)
**Use the round-5 artifacts below (M17) — they are committed, cleanly named and contain round 4 as well.** The old `dist/dayforge-1.0.0+13.70eab8c.dirty…` files are the superseded round-4 builds; you can delete them.

- [ ] 1. **Sound picker:** Settings → Notifications → Reminder sound — pick each bundled tone and hit **Preview**; you should hear it. Pick "Alarm (loud)", then fire Settings → "Send a test notification" — it arrives *with that sound* at alarm volume.
- [ ] 2. **Device sound (Android):** Settings → Reminder sound → **Pick from device…** — the system ringtone/alarm picker opens; choose an alarm; the setting shows its name and a real reminder uses it.
- [ ] 3. **Early tick, no pop-up:** add a task with a reminder ~5 min ahead, tick it on Today *now*, leave the app closed — **no notification should arrive** at that time. Untick it and confirm the reminder *does* arrive.
- [ ] 4. **Intraday reminder:** add a task "Drink water", Repeat = multiple times a day, window ~ now→now+20 min, every 5 min, target 3 — reminders arrive every 5 min; Today shows a `n/3` counter that goes up on each +1 (and from the notification's Mark completed); at 3/3 the day counts complete and the reminders stop for the day.
- [ ] 5. **Intraday repeats tomorrow:** the same task fires again the next day starting at the window start.
- [ ] 6. **Forgot password:** sign out → **Forgot password?** on the sign-in screen → enter your email → confirmation message; the reset mail arrives (check spam, see M14) → open the link, set a new password, sign in with it. Try it on both Linux and Android.
- [ ] 7. **Rollover — fixed window:** create a task with Completion rule = *Fixed window*, 3 days, backfill 1 day, let the end date pass — it ends on the end date (moves out of Today).
- [ ] 8. **Rollover — target days:** create a task with Completion rule = *Target days*, 3 days; miss a day; after the original end date the task is still active and the end date has rolled forward by the number of missed days. The Tasks tile shows the new range and `x/3 days completed`.
- [ ] 9. **Change the rule later:** Tasks → task menu → "Completion rule" switches an existing task between the two modes.
- [ ] 10. **Nothing regressed:** existing tasks still show their categories/streaks/heatmap; snooze and "Mark completed" from the notification still work.

### M14 — Password reset email (Firebase console, 2026-08-17)
Sending the reset mail needs nothing enabled beyond Email/Password auth (already on, M2), but the mail itself is worth checking once:

- [ ] 1. Firebase console → **Authentication → Templates → Password reset** — confirm the sender (`noreply@<project>.firebaseapp.com`) and, optionally, set the "from name" to **DayForge**.
- [ ] 2. Trigger a reset from the app (M13·6) and confirm the mail arrives; **check the spam folder** — Firebase's default sender is often filtered.
- [ ] 3. Note: **your existing password cannot be looked up anywhere.** Firebase stores only a salted hash — the console (Authentication → Users) shows the email, uid, sign-in dates and lets you send a reset link, never the password itself. If it is not in your password manager, resetting it is the only route.


## Completed
- M1 — Create a Firebase project
- M2 — Enable Email/Password authentication
- M3 — Enable Cloud Firestore
- M4 — Android toolchain
- M5 — Linux desktop build packages
- M6 — Reminders verified on Android phone (2026-07-13)
- M7 — Linux app verified end to end, incl. reminders (2026-07-13)

### M15 — Firebase config files are no longer in git (2026-08-19)

`lib/firebase_options.dart` and `android/app/google-services.json` are now gitignored — they carry the project's `AIza…` client keys and GitHub's secret scanner mails you about them on every push. **They already exist on this laptop, so nothing breaks here.** This matters only on a fresh clone, or if you ever delete them.

Worth knowing: those keys are not secrets. Firebase publishes them in every Android/web client; they identify the project, not authorise anyone. What actually protects the data is `firestore.rules` plus Firebase App Check. Keeping them out of git buys a quiet inbox, not security.

- [ ] 1. Nothing to do right now. On a fresh clone, run `flutterfire configure --project=advanced-todo-infinite`, or `cp lib/firebase_options.dart.template lib/firebase_options.dart` (and the same for `android/app/google-services.json.template`) and paste the API key from the Firebase console → Project settings → Your apps.
- [ ] 2. Note: they are still in the repo's **history**, including tag `v1.0.0`. Removing them from history would mean rewriting and force-pushing every past commit; you chose not to (2026-08-19). If you ever want them genuinely gone, rotate the keys in the Google Cloud console (APIs & Services → Credentials) — that invalidates the published ones without touching git.
- [ ] 3. If GitHub mails you again about the *old* commits, it is describing history, not the current tree. `git grep AIza $(git rev-parse HEAD)` returning nothing is the check that the tip is clean.

### M16 — Optional: give this laptop some swap (2026-08-19)

Not required — `make` now runs builds inside a memory-capped systemd scope, so an overshoot kills the build instead of your session. But this machine has **14 GB RAM and zero swap**, which is why a big build could take the desktop down at all: with no swap the kernel has nowhere to spill and picks a victim immediately.

- [ ] 1. If you want the headroom (a few minutes, needs sudo):
```
sudo apt-get install zram-config     # compressed swap in RAM, no disk writes
# or a plain file:
sudo fallocate -l 8G /swapfile && sudo chmod 600 /swapfile
sudo mkswap /swapfile && sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```
- [ ] 2. Confirm with `make doctor` — the swap line stops warning.

### M17 — Verify feedback-round-5 features (2026-08-19)
Round 5 **is committed**, so the artifacts are named for the release with no build stamp in the filename — that was the point of the change. Settings → About still prints the full build id (`18.7d89b89`), which is how you confirm which build you are holding.

- Android — `dist/dayforge-1.0.0.apk` (57 MB). Installs over the previous one; same app id, data is kept, no uninstall.
- Linux — `dist/dayforge_1.0.0_amd64.deb` (8.6 MB, `sudo dpkg -i <file>`), or run `./build/linux/x64/release/bundle/advanced_todo`.

- [ ] 1. **Names:** the two files above are named exactly that — no `+13.70eab8c.dirty…` tail. `make version` prints the same names.
- [ ] 2. **Build id still reachable:** Settings → About shows `18.7d89b89`. (Build a file with an edited tree and it becomes `dayforge-1.0.0-dirty.apk` — that suffix is the guard against handing out an uncommitted build.)
- [ ] 3. **Majority rule:** add "Drink water", Repeat = many times a day, window now→now+40 min, every 10 min (⇒ 5 reminders), and **leave "Ticks needed per day" empty**. The summary should read `… · 3 of 5 a day (over half)`. Tick 3 times → the day flips to complete.
- [ ] 4. **…and you can keep going past it:** the +1 button stays enabled after 3/5; ticking on reads 4/5 then 5/5. It should not lock at the target.
- [ ] 5. **Override still wins:** make another task the same way but type `5` in "Ticks needed per day" — the summary says `5× a day` and the day only completes at 5.
- [ ] 6. **Existing tasks moved:** any intraday task you created before today that never had an explicit target now completes at the majority instead of every occurrence. This only ever *loosens* a day. Check one and confirm it looks right to you.
- [ ] 7. **"N times a day":** on the add form switch the second toggle from **Every…** to **N times a day**, pick `8× a day` — the summary shows the derived interval spread across your window.
- [ ] 8. **Icon:** the launcher icon and the Linux menu entry still show the anvil-calendar mark, now rendered from `assets/icon/dayforge.svg`. Look at it on the phone's home screen at normal size — that is the size it was checked at.
- [ ] 9. **Builds don't take the machine down:** run `make doctor` (reports the ceiling and your RAM/swap), then `make all` while you keep working. It should stay usable, and if it ever does run out, only the build dies. If a build is killed: `make apk ABI=android-arm64`.
