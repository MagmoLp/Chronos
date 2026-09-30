import 'package:shared_preferences/shared_preferences.dart';

import '../domain/app_settings.dart';

/// Minimal synchronous-read key/value store for settings.
abstract interface class KeyValueStore {
  /// String value of [key], or `null`.
  String? getString(String key);

  /// Int value of [key], or `null`.
  int? getInt(String key);

  /// Bool value of [key], or `null`.
  bool? getBool(String key);

  /// Stores a string.
  Future<void> setString(String key, String value);

  /// Stores an int.
  Future<void> setInt(String key, int value);

  /// Stores a bool.
  Future<void> setBool(String key, bool value);

  /// Removes [key].
  Future<void> remove(String key);
}

/// [KeyValueStore] on `SharedPreferencesWithCache` (production).
///
/// Uses the async preferences backend, which on Android is a different store
/// than v1's legacy `SharedPreferences` file – v1 data is read separately
/// by the legacy migration.
class SharedPreferencesStore implements KeyValueStore {
  /// Wraps an existing [prefs] instance.
  SharedPreferencesStore(this._prefs);

  /// Creates the store with the settings keys as allow-list.
  static Future<SharedPreferencesStore> create() async =>
      SharedPreferencesStore(
        await SharedPreferencesWithCache.create(
          cacheOptions: const SharedPreferencesWithCacheOptions(
            allowList: SettingsRepository.keys,
          ),
        ),
      );

  final SharedPreferencesWithCache _prefs;

  @override
  String? getString(String key) {
    final value = _prefs.get(key);
    return value is String ? value : null;
  }

  @override
  int? getInt(String key) {
    final value = _prefs.get(key);
    return value is int ? value : null;
  }

  @override
  bool? getBool(String key) {
    final value = _prefs.get(key);
    return value is bool ? value : null;
  }

  @override
  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);

  @override
  Future<void> setInt(String key, int value) => _prefs.setInt(key, value);

  @override
  Future<void> setBool(String key, bool value) => _prefs.setBool(key, value);

  @override
  Future<void> remove(String key) => _prefs.remove(key);
}

/// In-memory [KeyValueStore] (tests, or a fallback if preferences fail).
class InMemoryKeyValueStore implements KeyValueStore {
  /// Creates a store with optional [initial] values.
  InMemoryKeyValueStore([Map<String, Object>? initial])
    : values = {...?initial};

  /// The stored values.
  final Map<String, Object> values;

  @override
  String? getString(String key) {
    final value = values[key];
    return value is String ? value : null;
  }

  @override
  int? getInt(String key) {
    final value = values[key];
    return value is int ? value : null;
  }

  @override
  bool? getBool(String key) {
    final value = values[key];
    return value is bool ? value : null;
  }

  @override
  Future<void> setString(String key, String value) async => values[key] = value;

  @override
  Future<void> setInt(String key, int value) async => values[key] = value;

  @override
  Future<void> setBool(String key, bool value) async => values[key] = value;

  @override
  Future<void> remove(String key) async => values.remove(key);
}

/// Reads and writes [AppSettings]. Unknown or corrupt values fall back to
/// the defaults, so settings can never block the app start.
class SettingsRepository {
  /// Creates the repository on [store].
  SettingsRepository(this._store);

  final KeyValueStore _store;

  /// Preference key: language.
  static const String kLanguage = 'settings.language';

  /// Preference key: theme mode.
  static const String kThemeMode = 'settings.themeMode';

  /// Preference key: monthly goal (cents).
  static const String kMonthlyGoalCents = 'settings.monthlyGoalCents';

  /// Preference key: monthly goal type.
  static const String kMonthlyGoalType = 'settings.monthlyGoalType';

  /// Preference key: reminder hours.
  static const String kReminderHours = 'settings.reminderHours';

  /// Preference key: onboarding done.
  static const String kOnboardingDone = 'settings.onboardingDone';

  /// Preference key: notification primer shown.
  static const String kNotificationPrimerShown =
      'settings.notificationPrimerShown';

  /// All keys (allow-list for `SharedPreferencesWithCache`).
  static const Set<String> keys = {
    kLanguage,
    kThemeMode,
    kMonthlyGoalCents,
    kMonthlyGoalType,
    kReminderHours,
    kOnboardingDone,
    kNotificationPrimerShown,
  };

  static T _enum<T extends Enum>(List<T> values, String? name, T fallback) {
    for (final value in values) {
      if (value.name == name) return value;
    }
    return fallback;
  }

  /// The stored settings (defaults for anything missing or invalid).
  AppSettings load() {
    const d = AppSettings.defaults;
    final goal = _store.getInt(kMonthlyGoalCents);
    final reminder = _store.getInt(kReminderHours);
    return AppSettings(
      language: _enum(
        AppLanguage.values,
        _store.getString(kLanguage),
        d.language,
      ),
      themeMode: _enum(
        AppThemeMode.values,
        _store.getString(kThemeMode),
        d.themeMode,
      ),
      monthlyGoalCents: goal != null && goal > 0 ? goal : null,
      monthlyGoalType: _enum(
        MonthlyGoalType.values,
        _store.getString(kMonthlyGoalType),
        d.monthlyGoalType,
      ),
      reminderHours:
          reminder != null && AppSettings.reminderHourOptions.contains(reminder)
          ? reminder
          : d.reminderHours,
      onboardingDone: _store.getBool(kOnboardingDone) ?? d.onboardingDone,
      notificationPrimerShown:
          _store.getBool(kNotificationPrimerShown) ?? d.notificationPrimerShown,
    );
  }

  /// Stores [settings] (all fields).
  Future<void> save(AppSettings settings) async {
    await _store.setString(kLanguage, settings.language.name);
    await _store.setString(kThemeMode, settings.themeMode.name);
    final goal = settings.monthlyGoalCents;
    if (goal == null) {
      await _store.remove(kMonthlyGoalCents);
    } else {
      await _store.setInt(kMonthlyGoalCents, goal);
    }
    await _store.setString(kMonthlyGoalType, settings.monthlyGoalType.name);
    await _store.setInt(kReminderHours, settings.reminderHours);
    await _store.setBool(kOnboardingDone, settings.onboardingDone);
    await _store.setBool(
      kNotificationPrimerShown,
      settings.notificationPrimerShown,
    );
  }
}
