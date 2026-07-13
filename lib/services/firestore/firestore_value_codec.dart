/// Converts between plain Dart values and the Firestore REST API's typed
/// value JSON (https://firebase.google.com/docs/firestore/reference/rest).
/// Pure Dart — shared by the Linux REST gateway and its tests.
library;

Map<String, dynamic> encodeFields(Map<String, dynamic> data) =>
    data.map((key, value) => MapEntry(key, encodeValue(value)));

Map<String, dynamic> decodeFields(Map<String, dynamic>? fields) {
  if (fields == null) return {};
  return fields.map(
    (key, value) =>
        MapEntry(key, decodeValue(value as Map<String, dynamic>)),
  );
}

Map<String, dynamic> encodeValue(Object? value) {
  return switch (value) {
    null => {'nullValue': null},
    bool b => {'booleanValue': b},
    int i => {'integerValue': '$i'},
    double d => {'doubleValue': d},
    String s => {'stringValue': s},
    DateTime t => {'timestampValue': t.toUtc().toIso8601String()},
    List l => {
        'arrayValue': {'values': l.map(encodeValue).toList()}
      },
    Map m => {
        'mapValue': {'fields': encodeFields(m.cast<String, dynamic>())}
      },
    _ => throw ArgumentError(
        'Unsupported Firestore value type: ${value.runtimeType}'),
  };
}

Object? decodeValue(Map<String, dynamic> value) {
  if (value.containsKey('nullValue')) return null;
  if (value.containsKey('booleanValue')) return value['booleanValue'] as bool;
  if (value.containsKey('integerValue')) {
    return int.parse(value['integerValue'] as String);
  }
  if (value.containsKey('doubleValue')) {
    return (value['doubleValue'] as num).toDouble();
  }
  if (value.containsKey('stringValue')) return value['stringValue'] as String;
  if (value.containsKey('timestampValue')) {
    return DateTime.parse(value['timestampValue'] as String);
  }
  if (value.containsKey('arrayValue')) {
    final values = (value['arrayValue'] as Map)['values'] as List? ?? [];
    return values
        .map((v) => decodeValue((v as Map).cast<String, dynamic>()))
        .toList();
  }
  if (value.containsKey('mapValue')) {
    final fields = (value['mapValue'] as Map)['fields'] as Map?;
    return decodeFields(fields?.cast<String, dynamic>());
  }
  throw ArgumentError('Unsupported Firestore value JSON: $value');
}
