import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/firestore/providers.dart';
import '../auth/providers.dart';
import 'data/task_repository.dart';
import 'domain/task.dart';

/// Null while signed out; rebuilt whenever the signed-in user changes.
final taskRepositoryProvider = Provider<TaskRepository?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return null;
  return TaskRepository(ref.watch(firestoreGatewayProvider), user.uid);
});

/// Live task list for the signed-in user (empty stream while signed out).
final tasksProvider = StreamProvider<List<Task>>((ref) {
  final repo = ref.watch(taskRepositoryProvider);
  if (repo == null) return Stream.value(const []);
  return repo.watchAll();
});
