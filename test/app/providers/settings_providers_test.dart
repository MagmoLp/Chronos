import 'package:chronos/app/providers/providers.dart';
import 'package:chronos/data/settings_repository.dart';
import 'package:chronos/domain/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fixtures/provider_harness.dart';
import '../../fixtures/shifts.dart';

void main() {
  late ProviderHarness h;

  setUp(() => h = ProviderHarness(local(2026, 9, 30, 12)));

  test(
    'defaults before the store is loaded, stored values afterwards',
    () async {
      h.store.values[SettingsRepository.kThemeMode] = 'dark';
      h.keepAlive(settingsProvider);
      expect(h.read(settingsProvider), AppSettings.defaults);
      await h.read(settingsRepositoryProvider.future);
      await pumpEventQueue();
      expect(h.read(settingsProvider).themeMode, AppThemeMode.dark);
    },
  );

  test('setters persist immediately', () async {
    await h.read(settingsRepositoryProvider.future);
    final c = h.read(settingsProvider.notifier);
    await c.setThemeMode(AppThemeMode.light);
    await c.setMonthlyGoal(60300, type: MonthlyGoalType.limit);
    await c.setOnboardingDone(true);
    await c.setNotificationPrimerShown(true);
    final expected = AppSettings.defaults.copyWith(
      themeMode: AppThemeMode.light,
      monthlyGoalCents: 60300,
      monthlyGoalType: MonthlyGoalType.limit,
      onboardingDone: true,
      notificationPrimerShown: true,
    );
    expect(h.read(settingsProvider), expected);
    expect(SettingsRepository(h.store).load(), expected);
    await c.setMonthlyGoal(0);
    expect(h.read(settingsProvider).monthlyGoalCents, isNull);
    expect(() => c.setMonthlyGoal(-1), throwsArgumentError);
  });

  test('language and reminder changes re-sync the notification', () async {
    await h.read(settingsRepositoryProvider.future);
    final c = h.read(settingsProvider.notifier);
    await c.setLanguage(AppLanguage.en);
    expect(h.effects.calls, hasLength(1));
    await c.setLanguage(AppLanguage.en); // unchanged: nothing
    expect(h.effects.calls, hasLength(1));
    await c.setReminderHours(6);
    expect(h.effects.calls, hasLength(2));
    expect(h.read(settingsProvider).reminderHours, 6);
    expect(() => c.setReminderHours(7), throwsArgumentError);
    await c.setThemeMode(AppThemeMode.dark);
    expect(h.effects.calls, hasLength(2));
    await c.replace(h.read(settingsProvider).copyWith(reminderHours: 0));
    expect(h.effects.calls, hasLength(3));
  });
}
