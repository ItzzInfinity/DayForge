import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/utils/date_utils.dart';
import '../../services/firestore/providers.dart';
import '../auth/providers.dart';
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
