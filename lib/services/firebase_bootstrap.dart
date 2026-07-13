import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../firebase_options.dart';

/// The official Firebase SDKs have no Linux desktop support, so on Linux the
/// data layer must use a REST/community fallback instead (docs/architecture.md).
bool get firebaseSupportedOnThisPlatform => kIsWeb || !Platform.isLinux;

Future<void> initFirebase() async {
  if (!firebaseSupportedOnThisPlatform) return;
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
}
