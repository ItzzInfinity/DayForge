import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'domain/quotes.dart';

/// One quote per day from the bundled rotation — deterministic, instant,
/// offline-safe, and free of third-party attribution requirements.
final dailyQuoteProvider = Provider<Quote>((ref) {
  final today = ref.watch(currentDateProvider);
  return quoteOfTheDay(today);
});
