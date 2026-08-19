import '../../../services/firestore/firestore_gateway.dart';
import '../domain/daily_log.dart';

/// Reads/writes `users/{uid}/tasks/{taskId}/daily_logs/{YYYY-MM-DD}`.
/// All writes are merges keyed by date, so ticking the checkbox and typing
/// a remark never clobber each other, on any device.
class DailyLogRepository {
  DailyLogRepository(this._gateway, this.uid);

  final FirestoreGateway _gateway;
  final String uid;

  String _collection(String taskId) => 'users/$uid/tasks/$taskId/daily_logs';
  String _doc(String taskId, String dateKey) =>
      '${_collection(taskId)}/$dateKey';

  Future<void> setCompleted(
    String taskId,
    String dateKey, {
    required bool completed,
  }) {
    final now = DateTime.now().toUtc();
    return _gateway.setDocument(
      _doc(taskId, dateKey),
      {
        'date': dateKey,
        'completed': completed,
        // A plain daily task is 0 or 1; keeping the count in step means the
        // two tick paths never disagree about the same day.
        'count': completed ? 1 : 0,
        'completedAt': completed ? now : null,
        'updatedAt': now,
      },
      merge: true,
    );
  }

  /// Records one tick of an intraday task ([delta] of -1 undoes it) and
  /// keeps `completed` in step with the day's [target]. Read-then-write
  /// rather than an atomic increment: the REST gateway (Linux) has no
  /// increment operator, and a lost race here costs at most one tick, which
  /// the user can simply tap again.
  /// Records a tick (or with a negative [delta], takes one back).
  ///
  /// [target] is what completes the day; [max] is what the counter can hold.
  /// They differ whenever the day completes on a majority — reaching 5 of 9
  /// marks the day done but must not stop the 6th glass of water being
  /// counted — so the clamp uses [max] and the flag uses [target].
  Future<int> addTick(
    String taskId,
    String dateKey, {
    required int target,
    int? max,
    int delta = 1,
  }) async {
    final ceiling = (max == null || max < target) ? target : max;
    final current = await get(taskId, dateKey);
    final count = ((current?.count ?? 0) + delta).clamp(0, ceiling);
    final completed = count >= target;
    final now = DateTime.now().toUtc();
    await _gateway.setDocument(
      _doc(taskId, dateKey),
      {
        'date': dateKey,
        'count': count,
        'completed': completed,
        'completedAt': completed ? (current?.completedAt ?? now) : null,
        'updatedAt': now,
      },
      merge: true,
    );
    return count;
  }

  Future<void> setRemark(String taskId, String dateKey, String remark) {
    return _gateway.setDocument(
      _doc(taskId, dateKey),
      {
        'date': dateKey,
        'remark': remark,
        'updatedAt': DateTime.now().toUtc(),
      },
      merge: true,
    );
  }

  Future<DailyLog?> get(String taskId, String dateKey) async {
    final data = await _gateway.getDocument(_doc(taskId, dateKey));
    return data == null ? null : DailyLog.fromMap(dateKey, data);
  }

  /// Every log for a task, oldest first (a task has at most durationDays
  /// logs, so this stays a small read).
  Future<List<DailyLog>> getAllForTask(String taskId) async =>
      _sorted(await _gateway.getCollection(_collection(taskId)));

  Stream<List<DailyLog>> watchForTask(String taskId) =>
      _gateway.watchCollection(_collection(taskId)).map(_sorted);

  Stream<DailyLog?> watch(String taskId, String dateKey) =>
      _gateway.watchDocument(_doc(taskId, dateKey)).map(
            (data) => data == null ? null : DailyLog.fromMap(dateKey, data),
          );

  static List<DailyLog> _sorted(List<DocRecord> records) {
    final logs = [
      for (final r in records) DailyLog.fromMap(r.id, r.data),
    ]..sort((a, b) => a.date.compareTo(b.date));
    return logs;
  }
}
