import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Today's local date. Widgets watch this instead of calling DateTime.now()
/// directly so date-dependent UI can be overridden in tests.
final currentDateProvider = Provider<DateTime>((ref) => DateTime.now());
