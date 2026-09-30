import 'package:chronos/data/settings_repository.dart';
import 'package:chronos/domain/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('empty store yields defaults', () {
    final repo = SettingsRepository(InMemoryKeyValueStore());
    expect(repo.load(), AppSettings.defaults);
  });

  test('save and load round-trip', () async {
    final store = InMemoryKeyValueStore();
    final repo = SettingsRepository(store);
    const settings = AppSettings(
      language: AppLanguage.en,
      themeMode: AppThemeMode.dark,
      monthlyGoalCents: 60300,
      monthlyGoalType: MonthlyGoalType.limit,
      reminderHours: 8,
      onboardingDone: true,
      notificationPrimerShown: true,
    );
    await repo.save(settings);
    expect(repo.load(), settings);
    expect(SettingsRepository(store).load(), settings);
    await repo.save(settings.copyWith(monthlyGoalCents: null));
    expect(
      store.values.containsKey(SettingsRepository.kMonthlyGoalCents),
      isFalse,
    );
    expect(repo.load().monthlyGoalCents, isNull);
  });

  test('corrupt values fall back to defaults', () {
    final repo = SettingsRepository(
      InMemoryKeyValueStore({
        SettingsRepository.kLanguage: 'klingon',
        SettingsRepository.kThemeMode: 42,
        SettingsRepository.kMonthlyGoalCents: -5,
        SettingsRepository.kMonthlyGoalType: 'x',
        SettingsRepository.kReminderHours: 7,
        SettingsRepository.kOnboardingDone: 'yes',
        SettingsRepository.kNotificationPrimerShown: 1,
      }),
    );
    expect(repo.load(), AppSettings.defaults);
  });

  test('keys are the allow-list', () {
    expect(SettingsRepository.keys, hasLength(7));
    expect(
      SettingsRepository.keys.every((k) => k.startsWith('settings.')),
      isTrue,
    );
  });

  test('in-memory store typed access', () async {
    final store = InMemoryKeyValueStore();
    await store.setString('s', 'v');
    await store.setInt('i', 1);
    await store.setBool('b', true);
    expect(store.getString('s'), 'v');
    expect(store.getInt('i'), 1);
    expect(store.getBool('b'), isTrue);
    expect(store.getString('i'), isNull);
    expect(store.getInt('s'), isNull);
    expect(store.getBool('s'), isNull);
    await store.remove('s');
    expect(store.getString('s'), isNull);
  });
}
