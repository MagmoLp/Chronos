import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'app/app.dart';
import 'app/error_log.dart';
import 'app/startup/app_locale.dart';
import 'app/startup/app_overrides.dart';
import 'l10n/app_localizations.dart';

/// Starts Chronos: UI immediately, everything slow (database, v1 migration,
/// notifications) happens behind the splash screen via providers.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final errorLog = ErrorLog(directory: getApplicationSupportDirectory)
    ..install();
  final l10n = lookupAppLocalizations(
    resolveSupportedLocale(WidgetsBinding.instance.platformDispatcher.locales),
  );
  runApp(
    ProviderScope(
      overrides: chronosOverrides(
        errorLog: errorLog,
        defaultJobName: l10n.onboardingDefaultJobName,
      ),
      child: const ChronosApp(),
    ),
  );
}
