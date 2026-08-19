import '../../../core/utils/id_generator.dart';
import '../../../services/firestore/firestore_gateway.dart';
import '../domain/recurrence.dart';
import '../domain/rollover.dart';
import '../domain/task.dart';

/// CRUD for `users/{uid}/tasks` on top of [FirestoreGateway], so it works
/// identically on native (Android/Windows) and REST (Linux) backends.
class TaskRepository {
  TaskRepository(this._gateway, this.uid);

  final FirestoreGateway _gateway;
  final String uid;

  String get _collection => 'users/$uid/tasks';
  String _doc(String id) => '$_collection/$id';

  Future<Task> create({
    required String title,
    String? description,
    List<String> categories = const [],
    required String startDate,
    required int durationDays,
    String? reminderTime,
    Recurrence recurrence = const Recurrence.daily(),
    CompletionMode completionMode = CompletionMode.fixedWindow,
  }) async {
    final now = DateTime.now().toUtc();
    final task = Task(
      id: newDocId(),
      title: title,
      description: description,
      categories: categories,
      startDate: startDate,
      durationDays: durationDays,
      reminderTime: reminderTime,
      recurrence: recurrence,
      completionMode: completionMode,
      // Recorded up front so later end-date extensions never move the goal.
      targetDays: completionMode == CompletionMode.targetDays
          ? durationDays
          : null,
      createdAt: now,
      updatedAt: now,
    );
    await _gateway.setDocument(_doc(task.id), task.toMap());
    return task;
  }

  /// Persists [task] with a fresh updatedAt (last-write-wins sync).
  Future<Task> save(Task task) async {
    final updated = task.copyWith(updatedAt: DateTime.now().toUtc());
    await _gateway.setDocument(_doc(task.id), updated.toMap());
    return updated;
  }

  Future<void> setStatus(String id, TaskStatus status) {
    return _gateway.setDocument(
      _doc(id),
      {'status': status.name, 'updatedAt': DateTime.now().toUtc()},
      merge: true,
    );
  }

  /// Deletes the task and its daily logs (Firestore does not cascade
  /// subcollection deletes; at most durationDays small docs).
  Future<void> delete(String id) async {
    final logs = await _gateway.getCollection('${_doc(id)}/daily_logs');
    for (final log in logs) {
      await _gateway.deleteDocument('${_doc(id)}/daily_logs/${log.id}');
    }
    await _gateway.deleteDocument(_doc(id));
  }

  Future<Task?> getById(String id) async {
    final data = await _gateway.getDocument(_doc(id));
    return data == null ? null : Task.fromMap(id, data);
  }

  Future<List<Task>> getAll() async =>
      _sorted(await _gateway.getCollection(_collection));

  /// All tasks, newest first; emits again whenever the collection changes.
  Stream<List<Task>> watchAll() =>
      _gateway.watchCollection(_collection).map(_sorted);

  static List<Task> _sorted(List<DocRecord> records) {
    final tasks = [
      for (final r in records) Task.fromMap(r.id, r.data),
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return tasks;
  }
}
