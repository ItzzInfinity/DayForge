import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/providers.dart';
import '../../firebase_options.dart';
import 'firestore_gateway.dart';
import 'native_firestore_gateway.dart';
import 'rest_firestore_gateway.dart';

final firestoreGatewayProvider = Provider<FirestoreGateway>((ref) {
  if (!kIsWeb && Platform.isLinux) {
    final auth = ref.watch(authRepositoryProvider);
    return RestFirestoreGateway(
      projectId: DefaultFirebaseOptions.windows.projectId,
      idTokenProvider: auth.getIdToken,
    );
  }
  return NativeFirestoreGateway(FirebaseFirestore.instance);
});
