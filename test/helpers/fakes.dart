import 'dart:async';

import 'package:advanced_todo/features/auth/domain/app_user.dart';
import 'package:advanced_todo/features/auth/domain/auth_repository.dart';
import 'package:advanced_todo/features/export/data/export_saver.dart';
import 'package:advanced_todo/features/onboarding/data/tutorial_store.dart';
import 'package:advanced_todo/features/tasks/domain/task.dart';
import 'package:advanced_todo/services/firestore/firestore_gateway.dart';
import 'package:advanced_todo/services/notifications/device_sound_picker.dart';
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

  /// Addresses a reset mail was requested for.
  final resetRequests = <String>[];

  /// Set to make the next reset attempt fail (e.g. an offline device).
  AuthException? resetError;

  @override
  Future<void> sendPasswordReset(String email) async {
    final error = resetError;
    if (error != null) throw error;
    resetRequests.add(email);
  }
}

/// Records sync calls; keeps widget tests away from the notifications plugin.
class FakeReminderScheduler implements ReminderScheduler {
  final syncedTaskLists = <List<Task>>[];
  final shownNow = <String>[];
  int permissionRequests = 0;

  /// Captured so tests can simulate the notification's "Mark completed"
  /// action being tapped while the app runs.
  @override
  Future<void> Function(String taskId)? onMarkCompleted;

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return true;
  }

  @override
  Future<void> sync(
    List<Task> tasks,
    DateTime now, {
    ReminderOptions options = const ReminderOptions(),
  }) async {
    syncedTaskLists.add(tasks);
    lastOptions = options;
  }

  ReminderOptions? lastOptions;
  String? get lastDefaultTime => lastOptions?.defaultTime;
  int? get lastSnoozeMinutes => lastOptions?.snoozeMinutes;

  /// Sound each showNow() was asked to play, newest last.
  final shownSounds = <ReminderSoundChoice>[];

  @override
  Future<void> showNow({
    required String title,
    required String body,
    ReminderSoundChoice sound = const ReminderSoundChoice(),
  }) async {
    shownNow.add('$title: $body');
    shownSounds.add(sound);
  }
}

/// Captures exports; keeps widget tests away from file dialogs and disks.
class FakeExportSaver implements ExportSaver {
  final saved = <({String fileName, String content})>[];

  /// What save() reports back; set to null to simulate a cancelled dialog.
  String? destination = '/fake/export';

  @override
  Future<String?> save({
    required String fileName,
    required String content,
  }) async {
    if (destination != null) saved.add((fileName: fileName, content: content));
    return destination;
  }
}

/// In-memory tutorial flag; defaults to "already seen" so the first-run
/// overlay stays out of tests that aren't about it.
class FakeTutorialStore implements TutorialStore {
  FakeTutorialStore({this.seen = true});

  bool seen;

  @override
  Future<bool> isSeen() async => seen;

  @override
  Future<void> markSeen() async => seen = true;
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

/// Gateway whose collection reads can be switched to fail — drives the
/// error/retry states. Only list reads fail so sign-in (a doc write) and
/// settings (a doc read) keep working around the failure.
class FlakyFirestoreGateway extends FakeFirestoreGateway {
  bool failCollectionReads = false;

  @override
  Future<List<DocRecord>> getCollection(String path) async {
    if (failCollectionReads) {
      throw const FirestoreGatewayException('Backend unavailable',
          statusCode: 503);
    }
    return super.getCollection(path);
  }
}

/// Stands in for the Android system ringtone picker.
class FakeDeviceSoundPicker implements DeviceSoundPicker {
  FakeDeviceSoundPicker({this.isSupported = true, this.result});

  @override
  final bool isSupported;

  /// What the picker "returns"; null simulates a cancelled pick.
  ({String uri, String label})? result;

  final pickedWith = <String?>[];

  @override
  Future<({String uri, String label})?> pick({String? currentUri}) async {
    pickedWith.add(currentUri);
    return result;
  }
}
