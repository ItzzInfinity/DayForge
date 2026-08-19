# Data Model (Firestore)

All user data lives under `users/{uid}` so security rules are trivial (`request.auth.uid == uid`).

## `users/{uid}`
| field | type | notes |
|---|---|---|
| displayName | string | optional |
| email | string | from auth |
| createdAt | timestamp | |

## `users/{uid}/settings/app` (single doc)
| field | type | notes |
|---|---|---|
| defaultDurationDays | int | default duration for new tasks (e.g. 21) |
| defaultReminderTime | string | "HH:mm" local time |
| notificationsEnabled | bool | |
| snoozeMinutes | int | how far the Snooze button postpones a reminder |
| reminderSoundId | string | `default` / `chime` / `beep` / `bell` / `alarm` (default) / `buzz` / `silent` / `device` |
| deviceSoundUri / deviceSoundLabel | string | Android ringtone picked from the phone; used when reminderSoundId is `device` |
| alarmVolume | bool | play reminders on the alarm audio channel |
| quietHoursStart / quietHoursEnd | string | "HH:mm", optional |
| themeMode | string | system / light / dark |

## `users/{uid}/tasks/{taskId}`
| field | type | notes |
|---|---|---|
| title | string | |
| description | string | optional |
| categories | array&lt;string&gt; | zero or more labels, for filtering; legacy docs may instead hold a single `category` string, migrated on read |
| startDate | string | "YYYY-MM-DD" (local date, avoids TZ drift) |
| durationDays | int | task runs startDate .. startDate+durationDays-1 |
| reminderTime | string | "HH:mm", null = use global default (daily tasks only) |
| recurrence | map | absent/null = once a day; otherwise `{kind: "intraday", startTime, endTime, intervalMinutes, targetPerDay}` — reminders every intervalMinutes inside the window, repeating daily (max 48/day) |
| completionMode | string | `fixedWindow` (default, and for every task created before this shipped) / `targetDays` |
| targetDays | int | completed days the run is aiming for; pinned when completionMode is `targetDays` so end-date extensions never move the goal |
| status | string | active / completed / archived |
| createdAt / updatedAt | timestamp | updatedAt drives last-write-wins |

## `users/{uid}/tasks/{taskId}/daily_logs/{YYYY-MM-DD}`
Doc ID **is** the local date → idempotent writes, easy range queries.
| field | type | notes |
|---|---|---|
| date | string | "YYYY-MM-DD" (duplicated for queries) |
| completed | bool | the daily checkbox; for an intraday task, "the day's target was reached" |
| count | int | ticks recorded today (intraday); legacy ticked days read as 1 |
| remark | string | short note (also allowed on skipped days) |
| completedAt | timestamp | null if not completed |
| updatedAt | timestamp | conflict resolution |

## Derived values (computed client-side, not stored)
- **Streak:** consecutive `completed == true` days ending today/yesterday.
- **Completion %:** completed logs ÷ elapsed active days.
Computed from `daily_logs` (max `durationDays` docs per task — cheap reads).
