import 'package:shared_preferences/shared_preferences.dart';

/// Whether this device has shown the first-run tutorial. Deliberately
/// per-device (not synced): a new phone deserves the tour even for an
/// existing account.
abstract interface class TutorialStore {
  Future<bool> isSeen();
  Future<void> markSeen();
}

class PrefsTutorialStore implements TutorialStore {
  static const _key = 'tutorial_seen_v1';

  @override
  Future<bool> isSeen() async =>
      (await SharedPreferences.getInstance()).getBool(_key) ?? false;

  @override
  Future<void> markSeen() async =>
      (await SharedPreferences.getInstance()).setBool(_key, true);
}
