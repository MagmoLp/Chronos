import 'package:flutter/material.dart';

import '../../domain/app_settings.dart';
import '../../l10n/app_localizations.dart';

/// The locale the user chose in the settings, or `null` to follow the
/// device ([AppLanguage.system]).
Locale? requestedLocale(AppLanguage language) => switch (language) {
  AppLanguage.system => null,
  AppLanguage.de => const Locale('de'),
  AppLanguage.en => const Locale('en'),
};

bool _isSupportedLanguage(String languageCode) => AppLocalizations
    .supportedLocales
    .any((l) => l.languageCode == languageCode);

/// Picks the app locale from [preferred] (the device's preferred locales, or
/// the single locale chosen in the settings).
///
/// The first locale whose language Chronos supports wins. Its region is
/// kept (`de_AT` stays `de_AT`, so numbers and dates follow the Austrian
/// conventions); a locale without region borrows the region of the first
/// [device] locale with the same language (German chosen in the app on an
/// Austrian phone → `de_AT`). Falls back to English.
Locale resolveSupportedLocale(
  List<Locale>? preferred, {
  List<Locale> device = const <Locale>[],
}) {
  for (final locale in preferred ?? const <Locale>[]) {
    final language = locale.languageCode;
    if (!_isSupportedLanguage(language)) continue;
    var country = locale.countryCode;
    if (country == null || country.isEmpty) {
      for (final d in device) {
        if (d.languageCode == language &&
            d.countryCode != null &&
            d.countryCode!.isNotEmpty) {
          country = d.countryCode;
          break;
        }
      }
    }
    return country == null || country.isEmpty
        ? Locale(language)
        : Locale(language, country);
  }
  return const Locale('en');
}

/// The locale for texts outside the widget tree (notifications, the default
/// job name): the settings' [language], else the device's [deviceLocales].
Locale localeForLanguage(AppLanguage language, List<Locale> deviceLocales) {
  final requested = requestedLocale(language);
  return resolveSupportedLocale(
    requested == null ? deviceLocales : <Locale>[requested],
    device: deviceLocales,
  );
}

/// Flutter's [ThemeMode] for the stored [mode].
ThemeMode themeModeFor(AppThemeMode mode) => switch (mode) {
  AppThemeMode.system => ThemeMode.system,
  AppThemeMode.light => ThemeMode.light,
  AppThemeMode.dark => ThemeMode.dark,
};
