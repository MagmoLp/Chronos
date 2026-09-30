import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/settings_repository.dart';
import '../../domain/app_settings.dart';
import 'shift_providers.dart';

/// The settings store (`SharedPreferencesWithCache`, created once
/// asynchronously). Tests override it with an [InMemoryKeyValueStore].
final settingsStoreProvider = FutureProvider<KeyValueStore>(
  (ref) => SharedPreferencesStore.create(),
  retry: (_, _) => null,
  name: 'settingsStoreProvider',
);

/// Settings repository on the loaded store.
final settingsRepositoryProvider = FutureProvider<SettingsRepository>(
  (ref) async =>
      SettingsRepository(await ref.watch(settingsStoreProvider.future)),
  retry: (_, _) => null,
  name: 'settingsRepositoryProvider',
);

/// Current settings. Defaults until the store is loaded (during bootstrap).
final settingsProvider = NotifierProvider<SettingsController, AppSettings>(
  SettingsController.new,
  name: 'settingsProvider',
);

/// Reads and changes [AppSettings]; every setter persists immediately.
class SettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() =>
      ref.watch(settingsRepositoryProvider).value?.load() ??
      AppSettings.defaults;

  Future<void> _save(AppSettings next) async {
    if (next == state) return;
    final repoFuture = ref.read(settingsRepositoryProvider.future);
    state = next;
    await (await repoFuture).save(next);
  }

  Future<void> _reconcileShift() =>
      ref.read(activeShiftControllerProvider.notifier).reconcile();

  /// Replaces all settings (restore, migration).
  Future<void> replace(AppSettings settings) async {
    final languageChanged = settings.language != state.language;
    final reminderChanged = settings.reminderHours != state.reminderHours;
    await _save(settings);
    if (languageChanged || reminderChanged) await _reconcileShift();
  }

  /// App language; the notification is re-posted in the new language.
  Future<void> setLanguage(AppLanguage language) async {
    if (language == state.language) return;
    await _save(state.copyWith(language: language));
    await _reconcileShift();
  }

  /// Light/dark mode.
  Future<void> setThemeMode(AppThemeMode mode) =>
      _save(state.copyWith(themeMode: mode));

  /// Monthly goal/limit in cents (`null` = off) and optionally its type.
  Future<void> setMonthlyGoal(int? cents, {MonthlyGoalType? type}) {
    if (cents != null && cents < 0) {
      throw ArgumentError.value(cents, 'cents', 'negative');
    }
    return _save(
      state.copyWith(
        monthlyGoalCents: cents == 0 ? null : cents,
        monthlyGoalType: type,
      ),
    );
  }

  /// Reminder delay (one of [AppSettings.reminderHourOptions], 0 = off);
  /// the reminder of a running shift is rescheduled.
  Future<void> setReminderHours(int hours) async {
    if (!AppSettings.reminderHourOptions.contains(hours)) {
      throw ArgumentError.value(hours, 'hours', 'not an allowed option');
    }
    if (hours == state.reminderHours) return;
    await _save(state.copyWith(reminderHours: hours));
    await _reconcileShift();
  }

  /// Marks onboarding as done (or not).
  Future<void> setOnboardingDone(bool done) =>
      _save(state.copyWith(onboardingDone: done));

  /// Remembers that the notification permission explanation was shown.
  Future<void> setNotificationPrimerShown(bool shown) =>
      _save(state.copyWith(notificationPrimerShown: shown));
}
