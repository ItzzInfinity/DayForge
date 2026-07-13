import 'dart:math';

final _random = Random.secure();
const _chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

/// Client-generated Firestore document id (the REST gateway has no
/// server-side id allocation). Timestamp prefix keeps ids roughly sortable.
String newDocId() {
  final time = DateTime.now().toUtc().millisecondsSinceEpoch.toRadixString(36);
  final suffix =
      List.generate(8, (_) => _chars[_random.nextInt(_chars.length)]).join();
  return '$time$suffix';
}
