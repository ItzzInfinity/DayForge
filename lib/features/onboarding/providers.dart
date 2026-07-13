import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/tutorial_store.dart';

final tutorialStoreProvider =
    Provider<TutorialStore>((_) => PrefsTutorialStore());

/// Resolves to false exactly once per device — that first-run signal is
/// what triggers the spotlight tutorial in the home shell.
final tutorialSeenProvider = FutureProvider<bool>(
  (ref) => ref.watch(tutorialStoreProvider).isSeen(),
);
