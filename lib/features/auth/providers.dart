import 'dart:io' show Platform;

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../firebase_options.dart';
import '../../services/firestore/providers.dart';
import 'data/firebase_auth_repository.dart';
import 'data/profile_repository.dart';
import 'data/rest_auth_repository.dart';
import 'domain/app_user.dart';
import 'domain/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (!kIsWeb && Platform.isLinux) {
    // No native Firebase SDK on Linux; the windows (web-type) app config
    // carries the API key the REST endpoints need. See docs/architecture.md.
    return RestAuthRepository(apiKey: DefaultFirebaseOptions.windows.apiKey);
  }
  return FirebaseAuthRepository(fb.FirebaseAuth.instance);
});

final authStateProvider = StreamProvider<AppUser?>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges(),
);

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(firestoreGatewayProvider)),
);
