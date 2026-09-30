class _Unset {
  const _Unset();
}

const Object _unset = _Unset();

/// App language choice.
enum AppLanguage {
  /// Follow the device language.
  system,

  /// German.
  de,

  /// English.
  en,
}

/// Light/dark choice (mapped to Flutter's `ThemeMode` by the UI).
enum AppThemeMode {
  /// Follow the system.
  system,

  /// Always light.
  light,

  /// Always dark.
  dark,
}

/// How the monthly amount is interpreted.
enum MonthlyGoalType {
  /// A target to reach.
  goal,

  /// A ceiling not to exceed (e.g. the Minijob limit).
  limit,
}

/// User settings (stored in SharedPreferences, not in the database).
final class AppSettings {
  /// Creates settings; the defaults are the first-start values.
  const AppSettings({
    this.language = AppLanguage.system,
    this.themeMode = AppThemeMode.system,
    this.monthlyGoalCents,
    this.monthlyGoalType = MonthlyGoalType.goal,
    this.reminderHours = kDefaultReminderHours,
    this.onboardingDone = false,
    this.notificationPrimerShown = false,
  });

  /// First-start defaults.
  static const AppSettings defaults = AppSettings();

  /// Allowed "still working?" reminder delays (0 = off).
  static const List<int> reminderHourOptions = [0, 6, 8, 10, 12];

  /// Default reminder delay in hours.
  static const int kDefaultReminderHours = 10;

  /// App language.
  final AppLanguage language;

  /// Light/dark mode.
  final AppThemeMode themeMode;

  /// Monthly goal or limit in cents; `null` = off.
  final int? monthlyGoalCents;

  /// Whether [monthlyGoalCents] is a goal or a limit.
  final MonthlyGoalType monthlyGoalType;

  /// Hours after start for the "still working?" reminder; 0 = off.
  final int reminderHours;

  /// Whether onboarding was completed (or skipped by a v1 migration).
  final bool onboardingDone;

  /// Whether the notification permission explanation was shown.
  final bool notificationPrimerShown;

  /// Whether the reminder is enabled.
  bool get reminderEnabled => reminderHours > 0;

  /// Copy with the given fields replaced ([monthlyGoalCents] can be cleared
  /// with an explicit `null`).
  AppSettings copyWith({
    AppLanguage? language,
    AppThemeMode? themeMode,
    Object? monthlyGoalCents = _unset,
    MonthlyGoalType? monthlyGoalType,
    int? reminderHours,
    bool? onboardingDone,
    bool? notificationPrimerShown,
  }) => AppSettings(
    language: language ?? this.language,
    themeMode: themeMode ?? this.themeMode,
    monthlyGoalCents: identical(monthlyGoalCents, _unset)
        ? this.monthlyGoalCents
        : monthlyGoalCents as int?,
    monthlyGoalType: monthlyGoalType ?? this.monthlyGoalType,
    reminderHours: reminderHours ?? this.reminderHours,
    onboardingDone: onboardingDone ?? this.onboardingDone,
    notificationPrimerShown:
        notificationPrimerShown ?? this.notificationPrimerShown,
  );

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.language == language &&
      other.themeMode == themeMode &&
      other.monthlyGoalCents == monthlyGoalCents &&
      other.monthlyGoalType == monthlyGoalType &&
      other.reminderHours == reminderHours &&
      other.onboardingDone == onboardingDone &&
      other.notificationPrimerShown == notificationPrimerShown;

  @override
  int get hashCode => Object.hash(
    language,
    themeMode,
    monthlyGoalCents,
    monthlyGoalType,
    reminderHours,
    onboardingDone,
    notificationPrimerShown,
  );

  @override
  String toString() =>
      'AppSettings(${language.name}, ${themeMode.name}, goal $monthlyGoalCents '
      '${monthlyGoalType.name}, reminder ${reminderHours}h, '
      'onboarding $onboardingDone, primer $notificationPrimerShown)';
}
