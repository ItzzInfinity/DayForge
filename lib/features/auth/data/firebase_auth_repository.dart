import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../domain/app_user.dart';
import '../domain/auth_repository.dart';

/// Auth via the native FlutterFire SDK (Android, Windows).
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth);

  final fb.FirebaseAuth _auth;

  AppUser? _toAppUser(fb.User? user) =>
      user == null ? null : AppUser(uid: user.uid, email: user.email ?? '');

  @override
  Stream<AppUser?> authStateChanges() =>
      _auth.authStateChanges().map(_toAppUser);

  @override
  AppUser? get currentUser => _toAppUser(_auth.currentUser);

  @override
  Future<AppUser> signIn({required String email, required String password}) {
    return _guard(() async {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _toAppUser(cred.user)!;
    });
  }

  @override
  Future<AppUser> signUp({required String email, required String password}) {
    return _guard(() async {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _toAppUser(cred.user)!;
    });
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<String?> getIdToken() async => _auth.currentUser?.getIdToken();

  Future<AppUser> _guard(Future<AppUser> Function() action) async {
    try {
      return await action();
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_friendlyMessage(e.code));
    }
  }

  static String _friendlyMessage(String code) => switch (code) {
        'invalid-email' => 'That email address is not valid.',
        'user-disabled' => 'This account has been disabled.',
        'user-not-found' ||
        'wrong-password' ||
        'invalid-credential' =>
          'Email or password is incorrect.',
        'email-already-in-use' => 'An account already exists for that email.',
        'weak-password' => 'Password is too weak (use at least 6 characters).',
        'network-request-failed' => 'Network error. Check your connection.',
        _ => 'Authentication failed ($code).',
      };
}
