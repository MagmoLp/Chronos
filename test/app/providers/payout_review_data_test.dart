import 'package:chronos/app/providers/providers.dart';
import 'package:chronos/core/local_date.dart';
import 'package:chronos/data/backup/backup_models.dart';
import 'package:chronos/data/legacy/legacy_models.dart';
import 'package:chronos/domain/app_settings.dart';
import 'package:chronos/domain/errors.dart';
import 'package:chronos/domain/review.dart';
import 'package:chronos/domain/shift_draft.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fixtures/legacy_v1.dart';
import '../../fixtures/provider_harness.dart';
import '../../fixtures/shifts.dart';

Matcher throwsCode(ChronosErrorCode code) =>
    throwsA(isA<ChronosException>().having((e) => e.code, 'code', code));

void main() {
  group('payouts', () {
    late ProviderHarness h;

    setUp(() => h = ProviderHarness(local(2026, 9, 30, 12)));

    test('preview, create, undo', () async {
      final job = await h.job();
      final shifts = h.read(shiftRepositoryProvider);
      for (var d = 1; d <= 3; d++) {
        await shifts.insertManual(
          ShiftDraft(
            jobId: job.id,
            startUtc: local(2026, 9, d, 8),
            endUtc: local(2026, 9, d, 16),
          ),
        );
      }
      final query = (until: LocalDate(2026, 9, 2), jobId: null);
      final preview = await h.settle(payoutPreviewProvider(query));
      expect(preview.count, 2);
      expect(preview.expectedCents, 24000);

      final c = h.read(payoutControllerProvider.notifier);
      expect((await c.preview(until: LocalDate(2026, 9, 30))).count, 3);
      final payout = await c.create(
        until: LocalDate(2026, 9, 2),
        receivedCents: 23500,
      );
      expect(payout.differenceCents, -500);
      expect((await h.settle(payoutPreviewProvider(query))).isEmpty, isTrue);
      expect((await h.settle(payoutsProvider)).single.id, payout.id);
      expect((await h.settle(openSummaryProvider)).shiftCount, 1);

      expect(await c.undo(payout), 2);
      expect(await h.settle(payoutsProvider), isEmpty);
      expect((await h.settle(openSummaryProvider)).shiftCount, 3);
      await expectLater(
        c.create(until: LocalDate(2026, 8, 1)),
        throwsCode(ChronosErrorCode.nothingToPayOut),
      );
    });
  });

  group('review', () {
    late ProviderHarness h;

    setUp(() async {
      h = ProviderHarness(
        local(2026, 9, 30, 12),
        legacy: LegacyRawData(
          workEntries: LegacyV1.workEntries,
          appSettings: LegacyV1.settings1250,
          activeSession: LegacyV1.activeSession,
        ),
      );
      await h.read(bootstrapProvider.future);
    });

    test('items, failures and dismiss', () async {
      final items = await h.settle(reviewItemsProvider);
      expect(items, isNotEmpty);
      expect(
        await h.settle(legacyFailuresProvider),
        hasLength(LegacyV1.broken),
      );
      final c = h.read(reviewControllerProvider.notifier);
      await c.dismiss(items.first.shiftId);
      expect(await h.settle(reviewItemsProvider), hasLength(items.length - 1));
      await c.dismissAll();
      expect(await h.settle(reviewItemsProvider), isEmpty);
    });

    test('fixWage corrects shifts and clears the question', () async {
      final pending = await h.read(pendingWageCheckProvider.future);
      expect(pending!.issue, WageIssue.tooHigh);
      final before = h.effects.calls.length;
      final count = await h
          .read(reviewControllerProvider.notifier)
          .fixWage(1250);
      expect(count, LegacyV1.importable + 1);
      expect(await h.read(pendingWageCheckProvider.future), isNull);
      expect(h.effects.calls.length, before + 1);
      expect(h.effects.last.running!.rateCentsPerHour, 1250);
      final open = await h.settle(openSummaryProvider);
      expect(open.running!.rateCentsPerHour, 1250);
    });

    test('confirmWage keeps the wage', () async {
      await h.read(reviewControllerProvider.notifier).confirmWage();
      expect(await h.read(pendingWageCheckProvider.future), isNull);
    });
  });

  group('data', () {
    late ProviderHarness h;
    late DataController c;

    setUp(() async {
      h = ProviderHarness(local(2026, 9, 30, 12));
      await h.read(bootstrapProvider.future);
      c = h.read(dataControllerProvider.notifier);
      final job = await h.job();
      await h
          .read(shiftRepositoryProvider)
          .insertManual(
            ShiftDraft(
              jobId: job.id,
              startUtc: local(2026, 9, 1, 8),
              endUtc: local(2026, 9, 1, 16),
            ),
          );
      await h.read(activeShiftControllerProvider.notifier).start(job.id);
      await h.read(settingsProvider.notifier).setLanguage(AppLanguage.en);
    });

    test('export → replace import restores data and settings', () async {
      final file = await c.exportBackup();
      expect(file.fileName, 'chronos-backup-2026-09-30.json');
      expect(file.json, contains('"appVersion": "2.0.0+2"'));
      final contents = c.readBackup(file.json);
      expect(contents.summary.shiftCount, 2);

      await h.read(settingsProvider.notifier).setLanguage(AppLanguage.de);
      final result = await c.importBackup(contents, ImportMode.replace);
      expect(result.shiftsAdded, 2);
      expect(h.read(settingsProvider).language, AppLanguage.en);
      expect(h.read(settingsProvider).onboardingDone, isTrue);
      expect(h.effects.last.running, isNotNull);
      expect(
        () => c.readBackup('{}'),
        throwsCode(ChronosErrorCode.backupInvalid),
      );
    });

    test('merge import leaves settings alone', () async {
      final contents = c.readBackup((await c.exportBackup()).json);
      await h.read(settingsProvider.notifier).setLanguage(AppLanguage.de);
      final result = await c.importBackup(contents, ImportMode.merge);
      expect(result.shiftsAdded, 0);
      expect(h.read(settingsProvider).language, AppLanguage.de);
    });

    test('wipe and undo', () async {
      final counts = await c.counts();
      expect(counts.shifts, 2);
      final result = await c.wipeAll();
      expect(result.deleted, counts);
      expect(h.effects.last.running, isNull);
      expect((await c.counts()).isEmpty, isTrue);
      expect(await h.settle(onboardingNeededProvider), isTrue);
      await c.undoWipe(result);
      expect(await c.counts(), counts);
      expect(h.effects.last.running, isNotNull);
      expect(await h.settle(onboardingNeededProvider), isFalse);
    });
  });
}
