// Diagnostic entrypoint: exercises flutter_local_notifications on Linux the
// same way LocalReminderScheduler does. Run:
//   flutter build linux --debug -t tool/notify_probe.dart
//   ./build/linux/x64/debug/bundle/advanced_todo
// Prints PROBE lines to stdout and exits by itself.
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final plugin = FlutterLocalNotificationsPlugin();
  const details = NotificationDetails(linux: LinuxNotificationDetails());
  try {
    final ok = await plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        linux: LinuxInitializationSettings(defaultActionName: 'Open'),
        windows: WindowsInitializationSettings(
          appName: 'Advanced To-Do',
          appUserModelId: 'com.sisirradar.advancedTodo',
          guid: '7f8a1e5c-4b2d-4f9a-9c3e-6d5b8a7c2e10',
        ),
      ),
    );
    stdout.writeln('PROBE initialize: $ok');
    await plugin.cancelAll();
    stdout.writeln('PROBE cancelAll: OK');
    await plugin.show(
      id: 9001,
      title: 'Advanced To-Do probe',
      body: 'Immediate show() works.',
      notificationDetails: details,
    );
    stdout.writeln('PROBE immediate show: OK');
  } catch (e, s) {
    stdout.writeln('PROBE setup FAILED: $e');
    stdout.writeln(s.toString().split('\n').take(6).join('\n'));
    exit(1);
  }
  Timer(const Duration(seconds: 5), () async {
    try {
      await plugin.show(
        id: 9002,
        title: 'Advanced To-Do probe',
        body: 'Timer-fired show() works.',
        notificationDetails: details,
      );
      stdout.writeln('PROBE timer show: OK');
    } catch (e) {
      stdout.writeln('PROBE timer show FAILED: $e');
    }
    exit(0);
  });
  runApp(
    const MaterialApp(
      home: Scaffold(
        body: Center(child: Text('Notification probe — closes itself.')),
      ),
    ),
  );
}
