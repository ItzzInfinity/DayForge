import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'firestore_gateway.dart';
import 'firestore_value_codec.dart';

/// [FirestoreGateway] backed by the Firestore REST API, for platforms
/// without a native SDK (Linux desktop). Pure Dart. Watch methods poll,
/// emitting only when data changes; interval kept modest to stay well
/// inside the free tier (see docs/architecture.md).
class RestFirestoreGateway implements FirestoreGateway {
  RestFirestoreGateway({
    required this.projectId,
    required this.idTokenProvider,
    http.Client? client,
    this.pollInterval = const Duration(seconds: 10),
  }) : _http = client ?? http.Client();

  final String projectId;

  /// Supplies a fresh Firebase ID token (AuthRepository.getIdToken).
  final Future<String?> Function() idTokenProvider;

  final http.Client _http;
  final Duration pollInterval;

  String get _base =>
      'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents';

  Future<Map<String, String>> _headers() async {
    final token = await idTokenProvider();
    if (token == null) {
      throw const FirestoreGatewayException('Not signed in', statusCode: 401);
    }
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  @override
  Future<Map<String, dynamic>?> getDocument(String path) async {
    final res = await _http.get(
      Uri.parse('$_base/$path'),
      headers: await _headers(),
    );
    if (res.statusCode == 404) return null;
    _check(res);
    final doc = jsonDecode(res.body) as Map<String, dynamic>;
    return decodeFields(
      (doc['fields'] as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  Future<void> setDocument(
    String path,
    Map<String, dynamic> data, {
    bool merge = false,
  }) async {
    var uri = Uri.parse('$_base/$path');
    if (merge) {
      uri = uri.replace(
        queryParameters: {
          'updateMask.fieldPaths': data.keys.toList(),
        },
      );
    }
    final res = await _http.patch(
      uri,
      headers: await _headers(),
      body: jsonEncode({'fields': encodeFields(data)}),
    );
    _check(res);
  }

  @override
  Future<void> deleteDocument(String path) async {
    final res = await _http.delete(
      Uri.parse('$_base/$path'),
      headers: await _headers(),
    );
    _check(res);
  }

  @override
  Future<List<DocRecord>> getCollection(String path) async {
    final records = <DocRecord>[];
    String? pageToken;
    do {
      final uri = Uri.parse('$_base/$path').replace(
        queryParameters: {
          'pageSize': '300',
          'pageToken': ?pageToken,
        },
      );
      final res = await _http.get(uri, headers: await _headers());
      _check(res);
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      for (final doc in (body['documents'] as List? ?? [])) {
        final map = (doc as Map).cast<String, dynamic>();
        final name = map['name'] as String;
        records.add((
          id: name.substring(name.lastIndexOf('/') + 1),
          data: decodeFields((map['fields'] as Map?)?.cast<String, dynamic>()),
        ));
      }
      pageToken = body['nextPageToken'] as String?;
    } while (pageToken != null);
    return records;
  }

  @override
  Stream<Map<String, dynamic>?> watchDocument(String path) =>
      _poll(() => getDocument(path));

  @override
  Stream<List<DocRecord>> watchCollection(String path) =>
      _poll(() => getCollection(path));

  /// Emits the first fetch immediately, then re-fetches on [pollInterval],
  /// emitting only when the payload actually changed. Transient errors after
  /// a successful first fetch are swallowed (next poll retries).
  Stream<T> _poll<T>(Future<T> Function() fetch) async* {
    String? lastJson;
    var first = true;
    while (true) {
      try {
        final value = await fetch();
        final asJson = jsonEncode(value, toEncodable: _jsonFallback);
        if (asJson != lastJson) {
          lastJson = asJson;
          yield value;
        }
      } catch (_) {
        if (first) rethrow;
      }
      first = false;
      await Future<void>.delayed(pollInterval);
    }
  }

  static Object? _jsonFallback(Object? value) => switch (value) {
        DateTime t => t.toIso8601String(),
        (:final String id, :final Map<String, dynamic> data) => {
            'id': id,
            'data': data
          },
        _ => value.toString(),
      };

  void _check(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    String message = res.body;
    try {
      final body = jsonDecode(res.body);
      message = ((body as Map)['error'] as Map)['message'] as String;
    } catch (_) {}
    throw FirestoreGatewayException(message, statusCode: res.statusCode);
  }
}
