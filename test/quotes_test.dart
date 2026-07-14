import 'package:flutter_test/flutter_test.dart';

import 'package:advanced_todo/features/quotes/data/local_quotes.dart';
import 'package:advanced_todo/features/quotes/domain/quotes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('bundled quote list', () {
    test('holds at least 365 distinct, non-empty quotes', () {
      expect(localQuotes.length, greaterThanOrEqualTo(365));
      final texts = {for (final q in localQuotes) q.text};
      expect(texts.length, localQuotes.length,
          reason: 'quote texts must be unique');
      expect(texts.any((t) => t.trim().isEmpty), isFalse);
    });

    test('daily rotation is stable within a day and changes across days',
        () {
      final day = DateTime(2026, 7, 13);
      expect(quoteOfTheDay(day).text,
          quoteOfTheDay(DateTime(2026, 7, 13, 23)).text);
      expect(quoteOfTheDay(day).text,
          isNot(quoteOfTheDay(DateTime(2026, 7, 14)).text));
      // Wraps safely past the end of the list.
      expect(() => quoteOfTheDay(DateTime(2026, 12, 31)), returnsNormally);
    });

    test('encouragementQuote picks from the bundled list', () {
      final quote = encouragementQuote();
      expect(localQuotes.map((q) => q.text), contains(quote.text));
    });
  });
}
