import 'dart:io';

import 'package:flutter/material.dart';

import '../../services/firestore/firestore_gateway.dart';

/// Turns raw exceptions into something a user can act on. The REST gateway
/// (Linux) lets SocketException/ClientException bubble up on network loss —
/// those must read as "you're offline", not as a stack of class names.
String friendlyError(Object error) {
  if (error is FirestoreGatewayException) {
    if (error.statusCode == 401) {
      return 'Your session has expired. Sign out and back in.';
    }
    if (error.isPermissionDenied) {
      return 'You do not have access to this data. Sign out and back in.';
    }
    return error.message;
  }
  if (error is SocketException ||
      error.toString().contains('ClientException')) {
    return 'No connection. Check your internet and retry.';
  }
  return '$error';
}

/// Standard failed-load state: what happened, why (friendly), and a Retry
/// button that re-runs the load (callers invalidate the failed provider).
class ErrorRetry extends StatelessWidget {
  const ErrorRetry({
    super.key,
    required this.message,
    required this.error,
    required this.onRetry,
  });

  final String message;
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined,
                size: 40, color: theme.colorScheme.error),
            const SizedBox(height: 12),
            Text(message,
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(friendlyError(error),
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              key: const Key('retry'),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
