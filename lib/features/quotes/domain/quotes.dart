import 'dart:math';

import '../data/local_quotes.dart';

/// A motivational quote. [author] may be empty (proverbs / unattributed).
class Quote {
  const Quote(this.text, [this.author = '']);

  final String text;
  final String author;
}

/// 1-based day of the year for [date] (1..366).
int dayOfYear(DateTime date) =>
    date.difference(DateTime(date.year)).inDays + 1;

/// Deterministic daily rotation over the bundled list: the same quote all
/// day, a different one tomorrow. With 365+ bundled quotes a whole year
/// passes without a repeat.
Quote quoteOfTheDay(DateTime date, [List<Quote> quotes = localQuotes]) =>
    quotes[(dayOfYear(date) - 1) % quotes.length];

/// Random pick for the "you ticked a task" encouragement snackbar.
/// Local-only by design — instant, offline-safe, no API rate limits.
Quote encouragementQuote([Random? random]) =>
    localQuotes[(random ?? Random()).nextInt(localQuotes.length)];
