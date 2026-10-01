import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import 'lifecycle.dart';
import 'notifications/notification_scope.dart';
import 'providers/providers.dart';
import 'startup/app_locale.dart';
import 'startup/startup_gate.dart';
import 'theme/theme.dart';

/// The Chronos app: theme, language, lifecycle and notification wiring
/// around the [StartupGate].
///
/// * Theme: "Sky Day" / "Navy Night", mode from the settings.
/// * Language: from the settings, or the device ("System"). The region of
///   the device is kept whenever its language is the app language, so an
///   Austrian phone gets `de_AT` number and date formats.
class ChronosApp extends ConsumerWidget {
  /// Creates the app.
  const ChronosApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(settingsProvider.select((s) => s.language));
    final themeMode = ref.watch(settingsProvider.select((s) => s.themeMode));
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      theme: ChronosTheme.light,
      darkTheme: ChronosTheme.dark,
      themeMode: themeModeFor(themeMode),
      locale: requestedLocale(language),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      // Called with the device locales (language "System") or with the
      // chosen locale; keeps or borrows the device region.
      localeListResolutionCallback: (locales, _) => resolveSupportedLocale(
        locales,
        device: WidgetsBinding.instance.platformDispatcher.locales,
      ),
      builder: (context, child) => AppLifecycleScope(
        child: NotificationScope(child: child ?? const SizedBox.shrink()),
      ),
      home: const StartupGate(),
    );
  }
}
