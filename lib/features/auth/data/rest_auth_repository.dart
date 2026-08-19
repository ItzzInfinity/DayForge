import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/app_user.dart';
import '../domain/auth_repository.dart';

/// Auth via the Firebase Auth REST API, for platforms without a native
/// Firebase SDK (Linux desktop). Same Firebase project and users as the
/// native implementation; the session is persisted in SharedPreferences.
class RestAuthRepository implements AuthRepository {
  RestAuthRepository({required this.apiKey, http.Client? client})
      : _http = client ?? http.Client();

  final String apiKey;
  final http.Client _http;

  final _controller = StreamController<AppUser?>.broadcast();
  AppUser? _current;
  String? _idToken;
  String? _refreshToken;
  DateTime _expiry = DateTime.fromMillisecondsSinceEpoch(0);
  Future<void>? _restoring;

  static const _prefsKey = 'rest_auth_session_v1';

  @override
  AppUser? get currentUser => _current;

  @override
  Stream<AppUser?> authStateChanges() async* {
    await _restoreSession();
    yield _current;
    yield* _controller.stream;
  }

  Future<void> _restoreSession() {
    return _restoring ??= () async {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null) return;
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final refreshToken = data['refreshToken'] as String?;
      final uid = data['uid'] as String?;
      if (refreshToken == null || uid == null) return;
      _refreshToken = refreshToken;
      _current = AppUser(uid: uid, email: data['email'] as String? ?? '');
    }();
  }

  @override
  Future<AppUser> signIn({required String email, required String password}) =>
      _authenticate('signInWithPassword', email, password);

  @override
  Future<AppUser> signUp({required String email, required String password}) =>
      _authenticate('signUp', email, password);

  @override
  Future<void> sendPasswordReset(String email) async {
    final res = await _http.post(
      Uri.parse('https://identitytoolkit.googleapis.com/v1/'
          'accounts:sendOobCode?key=$apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'requestType': 'PASSWORD_RESET', 'email': email}),
    );
    if (res.statusCode == 200) return;
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final code = ((data['error'] as Map?)?['message'] as String? ?? 'UNKNOWN')
        .split(' ')
        .first;
    // Unknown addresses stay silent (see AuthRepository.sendPasswordReset).
    if (code == 'EMAIL_NOT_FOUND') return;
    throw AuthException(_friendlyMessage(code));
  }

  Future<AppUser> _authenticate(
    String endpoint,
    String email,
    String password,
  ) async {
    final res = await _http.post(
      Uri.parse(
        'https://identitytoolkit.googleapis.com/v1/accounts:$endpoint?key=$apiKey',
      ),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'returnSecureToken': true,
      }),
    );
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      final code =
          (data['error'] as Map?)?['message'] as String? ?? 'UNKNOWN';
      throw AuthException(_friendlyMessage(code));
    }
    await _setSession(
      uid: data['localId'] as String,
      email: data['email'] as String? ?? email,
      idToken: data['idToken'] as String,
      refreshToken: data['refreshToken'] as String,
      expiresInSeconds: int.parse(data['expiresIn'] as String? ?? '3600'),
    );
    return _current!;
  }

  Future<void> _setSession({
    required String uid,
    required String email,
    required String idToken,
    required String refreshToken,
    required int expiresInSeconds,
  }) async {
    _current = AppUser(uid: uid, email: email);
    _idToken = idToken;
    _refreshToken = refreshToken;
    // Refresh a minute early so callers never hold an expired token.
    _expiry = DateTime.now().add(Duration(seconds: expiresInSeconds - 60));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode({'uid': uid, 'email': email, 'refreshToken': refreshToken}),
    );
    _controller.add(_current);
  }

  @override
  Future<String?> getIdToken() async {
    await _restoreSession();
    final refreshToken = _refreshToken;
    if (_current == null || refreshToken == null) return null;
    if (_idToken != null && DateTime.now().isBefore(_expiry)) return _idToken;
    final res = await _http.post(
      Uri.parse('https://securetoken.googleapis.com/v1/token?key=$apiKey'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'grant_type': 'refresh_token', 'refresh_token': refreshToken},
    );
    if (res.statusCode != 200) return null;
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    _idToken = data['id_token'] as String?;
    _refreshToken = data['refresh_token'] as String? ?? _refreshToken;
    _expiry = DateTime.now().add(
      Duration(seconds: int.parse(data['expires_in'] as String? ?? '3600') - 60),
    );
    return _idToken;
  }

  @override
  Future<void> signOut() async {
    _current = null;
    _idToken = null;
    _refreshToken = null;
    _expiry = DateTime.fromMillisecondsSinceEpoch(0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    _controller.add(null);
  }

  static String _friendlyMessage(String rawCode) {
    // Some codes arrive as 'WEAK_PASSWORD : Password should be ...'.
    final code = rawCode.split(' ').first;
    return switch (code) {
      'EMAIL_EXISTS' => 'An account already exists for that email.',
      'EMAIL_NOT_FOUND' ||
      'INVALID_PASSWORD' ||
      'INVALID_LOGIN_CREDENTIALS' =>
        'Email or password is incorrect.',
      'INVALID_EMAIL' => 'That email address is not valid.',
      'WEAK_PASSWORD' => 'Password is too weak (use at least 6 characters).',
      'USER_DISABLED' => 'This account has been disabled.',
      'TOO_MANY_ATTEMPTS_TRY_LATER' => 'Too many attempts. Try again later.',
      _ => 'Authentication failed ($code).',
    };
  }
}
