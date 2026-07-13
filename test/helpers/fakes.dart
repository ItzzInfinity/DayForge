import 'dart:async';

import 'package:advanced_todo/features/auth/domain/app_user.dart';
import 'package:advanced_todo/features/auth/domain/auth_repository.dart';
import 'package:advanced_todo/features/tasks/domain/task.dart';
import 'package:advanced_todo/services/firestore/firestore_gateway.dart';
import 'package:advanced_todo/services/notifications/reminder_scheduler.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({AppUser? initialUser}) : _current = initialUser;

  final _controller = StreamController<AppUser?>.broadcast();
  AppUser? _current;

  @override
  Stream<AppUser?> authStateChanges() async* {
    yield _current;
    yield* _controller.stream;
  }

  @override
  AppUser? get currentUser => _current;

  @override
  Future<AppUser> signIn({required String email, required String password}) {
    _current = AppUser(uid: 'test-uid', email: email);
    _controller.add(_current);
    return Future.value(_current!);
  }

  @override
  Future<AppUser> signUp({required String email, required String password}) =>
      signIn(email: email, password: password);

  @override
  Future<void> signOut() async {
    _current = null;
    _controller.add(null);
  }

  @override
  Future<String?> getIdToken() async => 'fake-token';
}

/// Records sync calls; keeps widget tests away from the notifications plugin.
class FakeReminderScheduler implements ReminderScheduler {
  final syncedTaskLists = <List<Task>>[];
  final shownNow = <String>[];
  int permissionRequests = 0;

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return true;
  }

  @override
  Future<void> sync(
    List<Task> tasks,
    DateTime now, {
    String defaultTime = defaultReminderTime,
  }) async {
    syncedTaskLists.add(tasks);
    lastDefaultTime = defaultTime;
  }

  String? lastDefaultTime;

  @override
  Future<void> showNow({required String title, required String body}) async {
    shownNow.add('$title: $body');
  }
}

/// In-memory FirestoreGateway so tests never touch the network.
class FakeFirestoreGateway implements FirestoreGateway {
  final docs = <String, Map<String, dynamic>>{};

  @override
  Future<Map<String, dynamic>?> getDocument(String path) async => docs[path];

  @override
  Future<void> setDocument(
    String path,
    Map<String, dynamic> data, {
    bool merge = false,
  }) async {
    docs[path] = merge ? {...?docs[path], ...data} : Map.of(data);
  }

  @override
  Future<void> deleteDocument(String path) async => docs.remove(path);

  @override
  Future<List<DocRecord>> getCollection(String path) async => [
        for (final e in docs.entries)
          if (e.key.startsWith('$path/') &&
              !e.key.substring(path.length + 1).contains('/'))
            (id: e.key.substring(path.length + 1), data: e.value)
      ];

  @override
  Stream<Map<String, dynamic>?> watchDocument(String path) =>
      Stream.fromFuture(getDocument(path));

  @override
  Stream<List<DocRecord>> watchCollection(String path) =>
      Stream.fromFuture(getCollection(path));
}
