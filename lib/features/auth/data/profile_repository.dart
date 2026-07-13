import '../../../services/firestore/firestore_gateway.dart';
import '../domain/app_user.dart';

/// Maintains the `users/{uid}` profile document (docs/data-model.md).
class ProfileRepository {
  ProfileRepository(this._gateway);

  final FirestoreGateway _gateway;

  /// Creates the profile document on first sign-in; no-op afterwards.
  Future<void> ensureProfile(AppUser user) async {
    final path = 'users/${user.uid}';
    final existing = await _gateway.getDocument(path);
    if (existing != null) return;
    await _gateway.setDocument(path, {
      'email': user.email,
      'createdAt': DateTime.now().toUtc(),
    });
  }
}
