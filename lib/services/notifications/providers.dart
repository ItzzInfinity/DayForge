import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'local_reminder_scheduler.dart';
import 'reminder_scheduler.dart';

final reminderSchedulerProvider =
    Provider<ReminderScheduler>((ref) => LocalReminderScheduler());
