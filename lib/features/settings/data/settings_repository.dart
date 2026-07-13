import '../../../services/firestore/firestore_gateway.dart';
import '../domain/app_settings.dart';

/// Reads/writes the single `users/{uid}/settings/app` document.
class SettingsRepository {
  SettingsRepository(this._gateway, this.uid);

  final FirestoreGateway _gateway;
  final String uid;

  String get _path => 'users/$uid/settings/app';

  /// Defaults when the user never saved settings.
  Future<AppSettings> get() async {
    final data = await _gateway.getDocument(_path);
    return data == null ? const AppSettings() : AppSettings.fromMap(data);
  }

  Future<void> save(AppSettings settings) =>
      _gateway.setDocument(_path, settings.toMap(), merge: true);
}
