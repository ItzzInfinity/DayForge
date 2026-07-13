import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_gateway.dart';

/// [FirestoreGateway] backed by the native cloud_firestore SDK
/// (Android, Windows). Offline persistence and realtime streams come for
/// free from the SDK.
class NativeFirestoreGateway implements FirestoreGateway {
  NativeFirestoreGateway(this._db);

  final FirebaseFirestore _db;

  @override
  Future<Map<String, dynamic>?> getDocument(String path) async {
    final snap = await _guard(() => _db.doc(path).get());
    return snap.exists ? _fromSdk(snap.data()!) : null;
  }

  @override
  Future<void> setDocument(
    String path,
    Map<String, dynamic> data, {
    bool merge = false,
  }) {
    return _guard(
      () => _db.doc(path).set(data, SetOptions(merge: merge)),
    );
  }

  @override
  Future<void> deleteDocument(String path) =>
      _guard(() => _db.doc(path).delete());

  @override
  Future<List<DocRecord>> getCollection(String path) async {
    final snap = await _guard(() => _db.collection(path).get());
    return [
      for (final doc in snap.docs) (id: doc.id, data: _fromSdk(doc.data()))
    ];
  }

  @override
  Stream<Map<String, dynamic>?> watchDocument(String path) {
    return _db
        .doc(path)
        .snapshots()
        .map((snap) => snap.exists ? _fromSdk(snap.data()!) : null);
  }

  @override
  Stream<List<DocRecord>> watchCollection(String path) {
    return _db.collection(path).snapshots().map(
          (snap) => [
            for (final doc in snap.docs)
              (id: doc.id, data: _fromSdk(doc.data()))
          ],
        );
  }

  /// The SDK returns [Timestamp]s; the rest of the app (and the REST
  /// gateway) speak [DateTime], so normalize on the way out.
  static Map<String, dynamic> _fromSdk(Map<String, dynamic> data) =>
      data.map((k, v) => MapEntry(k, _convert(v)));

  static Object? _convert(Object? value) => switch (value) {
        Timestamp t => t.toDate(),
        List l => l.map(_convert).toList(),
        Map m => m.map((k, v) => MapEntry(k as String, _convert(v))),
        _ => value,
      };

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FirebaseException catch (e) {
      throw FirestoreGatewayException(
        e.message ?? e.code,
        statusCode: e.code == 'permission-denied' ? 403 : null,
      );
    }
  }
}
