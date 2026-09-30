import 'package:chronos/app/providers/providers.dart';
import 'package:chronos/data/legacy/legacy_models.dart';
import 'package:chronos/domain/app_settings.dart';
import 'package:chronos/domain/review.dart';
import 'package:chronos/domain/shift_draft.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fixtures/legacy_v1.dart';
import '../../fixtures/provider_harness.dart';
import '../../fixtures/shifts.dart';

void main() {
  test('fresh install: onboarding, nothing migrated', () async {
    final h = ProviderHarness(local(2026, 9, 30, 12));
    final result = await h.read(bootstrapProvider.future);
    expect(result.migration.status, LegacyMigrationStatus.noLegacyData);
    expect(result.onboardingNeeded, isTrue);
    expect(result.settings, AppSettings.defaults);
    expect(result.pendingWageCheck, isNull);
    expect(result.reviewCount, 0);
    expect(result.runningShift, isNull);
    expect(h.effects.last.running, isNull); // reconciled
    expect(result.toString(), contains('noLegacyData'));
  });

  test('v1 data: migrated, settings taken over, no onboarding', () async {
    final h = ProviderHarness(
      local(2026, 9, 30, 12),
      legacy: LegacyRawData(
        workEntries: LegacyV1.workEntries,
        appSettings: LegacyV1.settingsGerman,
        activeSession: LegacyV1.activeSession,
      ),
    );
    h.store.values['settings.themeMode'] = 'dark';
    final result = await h.read(bootstrapProvider.future);
    expect(result.migration.migrated, isTrue);
    expect(result.migration.importedCount, LegacyV1.importable);
    expect(result.onboardingNeeded, isFalse);
    expect(result.settings.language, AppLanguage.de);
    expect(result.settings.themeMode, AppThemeMode.system);
    expect(result.settings.onboardingDone, isTrue);
    expect(h.read(settingsProvider), result.settings);
    expect(result.reviewCount, greaterThan(0));
    expect(result.legacyFailureCount, LegacyV1.broken);
    expect(result.runningShift, isNotNull);
    expect(h.effects.last.running!.id, result.runningShift!.id);
    expect(h.effects.last.job!.name, 'Mein Job');

    // Second start: nothing migrated again.
    h.container.invalidate(bootstrapProvider);
    final again = await h.read(bootstrapProvider.future);
    expect(again.migration.status, LegacyMigrationStatus.alreadyMigrated);
  });

  test('localized default job name and the wage question', () async {
    final h = ProviderHarness(
      local(2026, 9, 30, 12),
      legacy: LegacyRawData(
        workEntries: LegacyV1.workEntries,
        appSettings: LegacyV1.settings1250,
      ),
      overrides: [
        bootstrapConfigProvider.overrideWithValue(
          const BootstrapConfig(defaultJobName: 'My job'),
        ),
      ],
    );
    final result = await h.read(bootstrapProvider.future);
    expect(result.pendingWageCheck!.issue, WageIssue.tooHigh);
    expect(result.pendingWageCheck!.suggestedCentsPerHour, 1250);
    expect(result.settings.language, AppLanguage.en);
    final jobs = await h.read(jobRepositoryProvider).getJobs();
    expect(jobs.single.name, 'My job');
  });

  test('purges shifts deleted before the threshold', () async {
    final h = ProviderHarness(local(2026, 9, 30, 12));
    final job = await h.job();
    final shifts = h.read(shiftRepositoryProvider);
    final old = await shifts.insertManual(
      ShiftDraft(
        jobId: job.id,
        startUtc: local(2026, 9, 1, 8),
        endUtc: local(2026, 9, 1, 9),
      ),
    );
    await shifts.softDelete([old.id]);
    h.clock.advance(const Duration(minutes: 5));
    final fresh = await shifts.insertManual(
      ShiftDraft(
        jobId: job.id,
        startUtc: local(2026, 9, 2, 8),
        endUtc: local(2026, 9, 2, 9),
      ),
    );
    await shifts.softDelete([fresh.id]);
    final result = await h.read(bootstrapProvider.future);
    expect(result.purgedCount, 1);
    expect(await shifts.getById(old.id), isNull);
    expect(await shifts.getById(fresh.id), isNotNull);
    expect(result.onboardingNeeded, isFalse);
  });

  test(
    'failures are logged, not retried, and can be retried manually',
    () async {
      final h = ProviderHarness(local(2026, 9, 30, 12));
      h.legacySource.fail = true;
      await expectLater(h.read(bootstrapProvider.future), throwsA(anything));
      expect(await h.errorLog.read(), contains('prefs unreadable'));
      h.legacySource.fail = false;
      h.container.invalidate(bootstrapProvider);
      final result = await h.read(bootstrapProvider.future);
      expect(result.onboardingNeeded, isTrue);
    },
  );
}
