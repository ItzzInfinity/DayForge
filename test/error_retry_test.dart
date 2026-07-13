import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:advanced_todo/core/widgets/error_retry.dart';
import 'package:advanced_todo/services/firestore/firestore_gateway.dart';

void main() {
  group('friendlyError', () {
    test('network failures read as offline, not as class names', () {
      expect(friendlyError(const SocketException('Failed host lookup')),
          'No connection. Check your internet and retry.');
      expect(friendlyError(Exception('ClientException: connection closed')),
          'No connection. Check your internet and retry.');
    });

    test('auth-shaped gateway errors tell the user to re-sign-in', () {
      expect(
        friendlyError(const FirestoreGatewayException('expired',
            statusCode: 401)),
        contains('session has expired'),
      );
      expect(
        friendlyError(const FirestoreGatewayException('denied',
            statusCode: 403)),
        contains('do not have access'),
      );
    });

    test('other gateway errors show just the message; unknowns pass through',
        () {
      expect(
        friendlyError(const FirestoreGatewayException('Backend unavailable',
            statusCode: 503)),
        'Backend unavailable',
      );
      expect(friendlyError(StateError('boom')), contains('boom'));
    });
  });
}
