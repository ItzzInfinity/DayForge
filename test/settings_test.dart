import 'package:flutter_test/flutter_test.dart';

import 'package:advanced_todo/features/settings/data/settings_repository.dart';
import 'package:advanced_todo/features/settings/domain/app_settings.dart';

import 'helpers/fakes.dart';

void main() {
  group('AppSettings', () {
    test('defaults match the data model', () {
      const s = AppSettings();
      expect(s.defaultDurationDays, 21);
      expect(s.defaultReminderTime, '08:00');
      expect(s.notificationsEnabled, isTrue);
      expect(s.themeMode, 'system');
    });

    test('toMap/fromMap round-trips', () {
      const s = AppSettings(
        defaultDurationDays: 30,
        defaultReminderTime: '21:15',
        notificationsEnabled: false,
        themeMode: 'dark',
      );
      final restored = AppSettings.fromMap(s.toMap());
      expect(restored.defaultDurationDays, 30);
      expect(restored.defaultReminderTime, '21:15');
      expect(restored.notificationsEnabled, isFalse);
      expect(restored.themeMode, 'dark');
    });

    test('fromMap fills missing fields with defaults', () {
      final restored = AppSettings.fromMap({'themeMode': 'light'});
      expect(restored.themeMode, 'light');
      expect(restored.defaultDurationDays, 21);
      expect(restored.notificationsEnabled, isTrue);
    });
  });

  group('SettingsRepository', () {
    test('returns defaults when no doc exists, round-trips a save', () async {
      final gateway = FakeFirestoreGateway();
      final repo = SettingsRepository(gateway, 'u1');

      expect((await repo.get()).defaultDurationDays, 21);

      await repo.save(const AppSettings(defaultDurationDays: 14));
      expect(gateway.docs.keys.single, 'users/u1/settings/app');
      expect((await repo.get()).defaultDurationDays, 14);
    });
  });
}
