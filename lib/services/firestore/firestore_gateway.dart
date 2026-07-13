/// Platform-neutral document store interface.
///
/// Android/Windows use [NativeFirestoreGateway] (cloud_firestore SDK, real
/// offline persistence and realtime streams). Linux uses
/// [RestFirestoreGateway] (Firestore REST API, polling-based watch).
/// See docs/architecture.md — "Linux desktop caveat".
library;

/// A document snapshot: id plus decoded data.
typedef DocRecord = ({String id, Map<String, dynamic> data});

abstract interface class FirestoreGateway {
  /// Returns the document at [path] (e.g. `users/u1/tasks/t1`), or null.
  Future<Map<String, dynamic>?> getDocument(String path);

  /// Creates or updates the document at [path]. With [merge] only the given
  /// fields are written; otherwise the document is replaced.
  Future<void> setDocument(
    String path,
    Map<String, dynamic> data, {
    bool merge = false,
  });

  Future<void> deleteDocument(String path);

  /// All documents in the collection at [path] (e.g. `users/u1/tasks`).
  Future<List<DocRecord>> getCollection(String path);

  /// Emits the document at [path] on subscribe and whenever it changes.
  Stream<Map<String, dynamic>?> watchDocument(String path);

  /// Emits the collection at [path] on subscribe and whenever it changes.
  Stream<List<DocRecord>> watchCollection(String path);
}

class FirestoreGatewayException implements Exception {
  const FirestoreGatewayException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  bool get isPermissionDenied => statusCode == 403;

  @override
  String toString() => 'FirestoreGatewayException($statusCode): $message';
}
