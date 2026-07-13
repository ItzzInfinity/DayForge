import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:advanced_todo/features/quotes/data/local_quotes.dart';
import 'package:advanced_todo/features/quotes/data/quote_service.dart';
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

  group('QuoteService', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('returns the API quote, marks it fromApi, and caches it',
        () async {
      var calls = 0;
      final service = QuoteService(
        client: MockClient((request) async {
          calls++;
          return http.Response(
              jsonEncode([
                {'q': 'Ship it.', 'a': 'Zen'}
              ]),
              200);
        }),
      );
      final quote = await service.dailyQuote(DateTime(2026, 7, 13));
      expect(quote.text, 'Ship it.');
      expect(quote.author, 'Zen');
      expect(quote.fromApi, isTrue);

      // Second call the same day is served from the cache, not the API.
      final again = await service.dailyQuote(DateTime(2026, 7, 13));
      expect(again.text, 'Ship it.');
      expect(calls, 1);
    });

    test('falls back to the bundled rotation when the API fails',
        () async {
      final service = QuoteService(
        client: MockClient(
            (request) async => throw http.ClientException('offline')),
      );
      final quote = await service.dailyQuote(DateTime(2026, 7, 13));
      expect(quote.text, quoteOfTheDay(DateTime(2026, 7, 13)).text);
      expect(quote.fromApi, isFalse);
    });
  });
}
