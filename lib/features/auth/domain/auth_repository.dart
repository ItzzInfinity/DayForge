import 'app_user.dart';

abstract interface class AuthRepository {
  /// Emits the current user immediately on listen, then on every change.
  Stream<AppUser?> authStateChanges();

  AppUser? get currentUser;

  Future<AppUser> signIn({required String email, required String password});

  Future<AppUser> signUp({required String email, required String password});

  Future<void> signOut();

  /// Emails a password-reset link to [email]. Succeeds silently for unknown
  /// addresses on purpose — telling a stranger which emails have accounts
  /// leaks the user list.
  Future<void> sendPasswordReset(String email);

  /// Fresh Firebase ID token, used by REST-based data access (Linux).
  Future<String?> getIdToken();
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}
