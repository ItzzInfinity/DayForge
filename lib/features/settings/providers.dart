import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/firestore/providers.dart';
import '../auth/providers.dart';
import 'data/settings_repository.dart';
import 'domain/app_settings.dart';

/// Null while signed out; rebuilt whenever the signed-in user changes.
final settingsRepositoryProvider = Provider<SettingsRepository?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return null;
  return SettingsRepository(ref.watch(firestoreGatewayProvider), user.uid);
});

/// Current settings (defaults while signed out or before first save).
/// Invalidate after every save.
final appSettingsProvider = FutureProvider<AppSettings>((ref) async {
  final repo = ref.watch(settingsRepositoryProvider);
  if (repo == null) return const AppSettings();
  return repo.get();
});
