import 'package:flutter_test/flutter_test.dart';

import 'package:advanced_todo/services/firestore/firestore_value_codec.dart';

void main() {
  test('encode/decode round-trips every supported type', () {
    final data = <String, dynamic>{
      'title': 'Drink water',
      'durationDays': 21,
      'progress': 0.5,
      'completed': true,
      'remark': null,
      'createdAt': DateTime.utc(2026, 7, 13, 10, 30),
      'tags': ['health', 'daily'],
      'meta': {
        'nested': {'level': 2},
        'counts': [1, 2, 3],
      },
    };

    expect(decodeFields(encodeFields(data)), data);
  });

  test('integer values survive the REST string encoding', () {
    final encoded = encodeValue(42);
    expect(encoded, {'integerValue': '42'});
    expect(decodeValue(encoded), 42);
  });

  test('decode tolerates missing fields map', () {
    expect(decodeFields(null), <String, dynamic>{});
  });
}
