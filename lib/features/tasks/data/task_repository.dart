import '../../../core/utils/id_generator.dart';
import '../../../services/firestore/firestore_gateway.dart';
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
    String? category,
    required String startDate,
    required int durationDays,
    String? reminderTime,
  }) async {
    final now = DateTime.now().toUtc();
    final task = Task(
      id: newDocId(),
      title: title,
      description: description,
      category: category,
      startDate: startDate,
      durationDays: durationDays,
      reminderTime: reminderTime,
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

  Future<void> delete(String id) => _gateway.deleteDocument(_doc(id));

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
