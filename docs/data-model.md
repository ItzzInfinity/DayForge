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
| quietHoursStart / quietHoursEnd | string | "HH:mm", optional |
| themeMode | string | system / light / dark |

## `users/{uid}/tasks/{taskId}`
| field | type | notes |
|---|---|---|
| title | string | |
| description | string | optional |
| category | string | optional, for filtering |
| startDate | string | "YYYY-MM-DD" (local date, avoids TZ drift) |
| durationDays | int | task runs startDate .. startDate+durationDays-1 |
| reminderTime | string | "HH:mm", null = use global default |
| status | string | active / completed / archived |
| createdAt / updatedAt | timestamp | updatedAt drives last-write-wins |

## `users/{uid}/tasks/{taskId}/daily_logs/{YYYY-MM-DD}`
Doc ID **is** the local date → idempotent writes, easy range queries.
| field | type | notes |
|---|---|---|
| date | string | "YYYY-MM-DD" (duplicated for queries) |
| completed | bool | the daily checkbox |
| remark | string | short note (also allowed on skipped days) |
| completedAt | timestamp | null if not completed |
| updatedAt | timestamp | conflict resolution |

## Derived values (computed client-side, not stored)
- **Streak:** consecutive `completed == true` days ending today/yesterday.
- **Completion %:** completed logs ÷ elapsed active days.
Computed from `daily_logs` (max `durationDays` docs per task — cheap reads).
