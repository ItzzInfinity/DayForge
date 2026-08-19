import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/utils/date_utils.dart';
import '../../services/firestore/providers.dart';
import '../auth/providers.dart';
import '../tasks/domain/task.dart';
import '../tasks/providers.dart';
import 'data/daily_log_repository.dart';
import 'domain/daily_log.dart';

/// Null while signed out; rebuilt whenever the signed-in user changes.
final dailyLogRepositoryProvider = Provider<DailyLogRepository?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return null;
  return DailyLogRepository(ref.watch(firestoreGatewayProvider), user.uid);
});

/// Today's log for one task (null if nothing recorded yet). Invalidate after
/// writes so dependents refresh immediately, even on the polling gateway.
final todayLogProvider =
    FutureProvider.family<DailyLog?, String>((ref, taskId) async {
  final repo = ref.watch(dailyLogRepositoryProvider);
  if (repo == null) return null;
  final dateKey = toDateKey(ref.watch(currentDateProvider));
  return repo.get(taskId, dateKey);
});

/// Every log of one task (streaks, history). Invalidated together with
/// [todayLogProvider] after each write on the Today screen.
final taskLogsProvider =
    FutureProvider.family<List<DailyLog>, String>((ref, taskId) async {
  final repo = ref.watch(dailyLogRepositoryProvider);
  if (repo == null) return const [];
  return repo.getAllForTask(taskId);
});

/// Ids of the active tasks already ticked for today. Watching each task's
/// [todayLogProvider] means every tick/untick (Today screen, notification
/// action, backfill) refreshes this automatically — which is what lets the
/// reminder scheduler drop a reminder the user has already satisfied.
final completedTodayProvider = FutureProvider<Set<String>>((ref) async {
  final tasks = ref.watch(tasksProvider).value ?? const <Task>[];
  final done = <String>{};
  for (final task in tasks) {
    if (task.status != TaskStatus.active) continue;
    final log = await ref.watch(todayLogProvider(task.id).future);
    if (log?.completed ?? false) done.add(task.id);
  }
  return done;
});
