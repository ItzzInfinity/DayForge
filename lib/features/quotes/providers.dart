import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'data/quote_service.dart';
import 'domain/quotes.dart';

final quoteServiceProvider = Provider<QuoteService>((ref) => QuoteService());

/// One quote per day: API-backed when online, bundled rotation otherwise.
final dailyQuoteProvider = FutureProvider<Quote>((ref) {
  final today = ref.watch(currentDateProvider);
  return ref.watch(quoteServiceProvider).dailyQuote(today);
});
