import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/clock.dart';
import '../../data/legacy/legacy_models.dart';
import '../../domain/app_settings.dart';
import '../../domain/job.dart';
import '../../domain/review.dart';
import '../../domain/shift.dart';
import '../error_log.dart';
import 'core_providers.dart';
import 'settings_providers.dart';
import 'shift_providers.dart';

/// Inputs of the start sequence that come from the UI layer.
final class BootstrapConfig {
  /// Creates a config.
  const BootstrapConfig({
    this.defaultJobName = 'Mein Job',
    this.defaultJobColorArgb = kDefaultJobColorArgb,
    this.purgeDeletedAfter = const Duration(minutes: 1),
  });

  /// Name of the job created for v1 data. The app overrides
  /// [bootstrapConfigProvider] with the localized name (the German default
  /// is only a fallback).
  final String defaultJobName;

  /// Colour of that job.
  final int defaultJobColorArgb;

  /// Soft-deleted shifts older than this are removed for good at start.
  final Duration purgeDeletedAfter;
}

/// Override with the localized default job name, e.g.
/// `bootstrapConfigProvider.overrideWithValue(BootstrapConfig(defaultJobName: l10n.defaultJobName))`.
final bootstrapConfigProvider = Provider<BootstrapConfig>(
  (ref) => const BootstrapConfig(),
  name: 'bootstrapConfigProvider',
);

/// What the start sequence found.
final class BootstrapResult {
  /// Creates a result.
  const BootstrapResult({
    required this.settings,
    required this.migration,
    required this.onboardingNeeded,
    this.pendingWageCheck,
    this.reviewCount = 0,
    this.legacyFailureCount = 0,
    this.purgedCount = 0,
    this.runningShift,
  });

  /// Loaded (and possibly migrated) settings.
  final AppSettings settings;

  /// Result of the v1 migration check (`migrated` only on the first start
  /// with v1 data: show the one-time notice).
  final LegacyMigrationReport migration;

  /// Wage question to ask ("1250,00 €/h – stimmt das?"), if any.
  final WagePlausibility? pendingWageCheck;

  /// Entries on the review list.
  final int reviewCount;

  /// v1 entries that could not be imported.
  final int legacyFailureCount;

  /// Whether onboarding must be shown (no active job).
  final bool onboardingNeeded;

  /// Soft-deleted shifts removed for good.
  final int purgedCount;

  /// The running shift at start.
  final Shift? runningShift;

  @override
  String toString() =>
      'BootstrapResult(migration ${migration.status.name}, '
      'onboarding $onboardingNeeded, review $reviewCount, '
      'wage ${pendingWageCheck?.centsPerHour}, purged $purgedCount)';
}

/// The start sequence, run once behind the splash screen:
/// load settings → open database → v1 migration (idempotent) → purge
/// soft-deleted shifts → reconcile notification. Not retried automatically;
/// on error show the recovery screen and `ref.invalidate(bootstrapProvider)`
/// to retry. Errors are also written to the error log.
final bootstrapProvider = FutureProvider<BootstrapResult>(
  (ref) async {
    final log = ref.read(errorLogProvider);
    try {
      await ref.watch(settingsRepositoryProvider.future);
      final config = ref.read(bootstrapConfigProvider);
      final clock = ref.read(clockProvider);
      final migrator = ref.read(legacyMigratorProvider);
      final shifts = ref.read(shiftRepositoryProvider);
      final settingsController = ref.read(settingsProvider.notifier);

      final migration = await migrator.run(
        defaultJobName: config.defaultJobName,
        colorArgb: config.defaultJobColorArgb,
      );
      if (migration.migrated) {
        final current = ref.read(settingsProvider);
        await settingsController.replace(
          current.copyWith(
            language: migration.language ?? current.language,
            themeMode: AppThemeMode.system,
            onboardingDone: true,
          ),
        );
      }

      final purged = await shifts.purgeDeleted(
        before: clock.now().toUtc().subtract(config.purgeDeletedAfter),
      );
      final pendingWage = await migrator.pendingWageCheck();
      final review = ref.read(reviewRepositoryProvider);
      final reviewCount = (await review.getItems()).length;
      final failures = (await review.getLegacyFailures()).length;
      final activeJobs = await ref
          .read(jobRepositoryProvider)
          .getJobs(includeArchived: false);
      final running = await shifts.getRunning();

      await ref.read(activeShiftControllerProvider.notifier).reconcile();

      return BootstrapResult(
        settings: ref.read(settingsProvider),
        migration: migration,
        pendingWageCheck: pendingWage,
        reviewCount: reviewCount,
        legacyFailureCount: failures,
        onboardingNeeded: activeJobs.isEmpty,
        purgedCount: purged,
        runningShift: running,
      );
    } on Object catch (e, st) {
      await log.record(e, st, context: 'bootstrap');
      rethrow;
    }
  },
  retry: (_, _) => null,
  name: 'bootstrapProvider',
);
