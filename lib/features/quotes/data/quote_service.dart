import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/date_utils.dart';
import '../domain/quotes.dart';

/// Fetches the quote of the day from zenquotes.io (free, keyless; their
/// terms ask for visible attribution — the UI shows "zenquotes.io" for
/// API quotes). Any failure — offline, rate limit, missing plugin —
/// falls back to the bundled 365-quote daily rotation, so the app never
/// shows an empty or broken quote.
class QuoteService {
  QuoteService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _endpoint = 'https://zenquotes.io/api/today';

  Future<Quote> dailyQuote(DateTime today) async {
    SharedPreferences? prefs;
    final cacheKey = 'daily-quote-${toDateKey(today)}';
    try {
      prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(cacheKey);
      if (cached != null) {
        final map = jsonDecode(cached) as Map<String, dynamic>;
        return Quote(map['q'] as String, map['a'] as String? ?? '', true);
      }
    } catch (_) {
      // No local storage (e.g. tests) — continue without a cache.
    }
    try {
      final response = await _client
          .get(Uri.parse(_endpoint))
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List<dynamic>;
        final first = list.first as Map<String, dynamic>;
        final text = (first['q'] as String).trim();
        final author = (first['a'] as String? ?? '').trim();
        if (text.isNotEmpty) {
          await prefs?.setString(
              cacheKey, jsonEncode({'q': text, 'a': author}));
          return Quote(text, author, true);
        }
      }
    } catch (_) {
      // Offline or API hiccup — the bundled rotation below covers it.
    }
    return quoteOfTheDay(today);
  }
}
