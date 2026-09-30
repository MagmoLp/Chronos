import 'dart:io';

import 'package:chronos/core/local_date.dart';
import 'package:chronos/data/backup/backup_service.dart';
import 'package:chronos/data/backup/data_wipe_service.dart';
import 'package:chronos/data/legacy/legacy_migration.dart';
import 'package:chronos/data/legacy/legacy_models.dart';
import 'package:chronos/data/payout_repository.dart';
import 'package:chronos/data/review_repository.dart';
import 'package:chronos/domain/errors.dart';
import 'package:chronos/domain/shift_draft.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/db.dart';
import '../fixtures/legacy_v1.dart';
import '../fixtures/shifts.dart';

class _Source implements LegacySource {
  @override
  Future<LegacyRawData> read() async => LegacyRawData(
    workEntries: LegacyV1.workEntries,
    appSettings: LegacyV1.settingsGerman,
  );
}

void main() {
  late DataHarness h;
  late Directory dir;
  late DataWipeService wipe;
  late ReviewRepository review;

  setUp(() {
    h = DataHarness(local(2026, 9, 30, 12));
    dir = tempDir();
    wipe = DataWipeService(
      h.db,
      BackupService(h.db, clock: h.clock.clock),
      snapshotDirectory: () async => dir,
      clock: h.clock.clock,
    );
    review = ReviewRepository(h.db);
  });

  test('counts', () async {
    expect((await wipe.counts()).isEmpty, isTrue);
    final job = await h.job();
    final a = await h.shifts.insertManual(
      ShiftDraft(
        jobId: job.id,
        startUtc: local(2026, 9, 1, 8),
        endUtc: local(2026, 9, 1, 9),
      ),
    );
    await h.shifts.insertManual(
      ShiftDraft(
        jobId: job.id,
        startUtc: local(2026, 9, 2, 8),
        endUtc: local(2026, 9, 2, 9),
      ),
    );
    await h.shifts.softDelete([a.id]);
    await PayoutRepository(
      h.db,
      clock: h.clock.clock,
    ).create(until: LocalDate(2026, 9, 30));
    expect(
      await wipe.counts(),
      const DataCounts(shifts: 1, jobs: 1, payouts: 1),
    );
    expect(
      const DataCounts(shifts: 1, jobs: 1, payouts: 1).hashCode,
      (await wipe.counts()).hashCode,
    );
    expect((await wipe.counts()).toString(), contains('1 shifts'));
  });

  test(
    'wipe snapshots first, keeps the migration marker, undo restores all',
    () async {
      final migrator = LegacyMigrator(
        db: h.db,
        source: _Source(),
        backupDirectory: () async => dir,
        clock: h.clock.clock,
      );
      await migrator.run(defaultJobName: 'Mein Job');
      final reviewBefore = await review.getItems();
      final failuresBefore = await review.getLegacyFailures();
      expect(reviewBefore, isNotEmpty);
      expect(failuresBefore, isNotEmpty);
      final countsBefore = await wipe.counts();

      final result = await wipe.wipeAll(appVersion: '2.0.0');
      expect(result.deleted, countsBefore);
      expect(result.snapshot.existsSync(), isTrue);
      expect(result.snapshot.path, contains(DataWipeService.snapshotPrefix));
      expect(result.toString(), contains('WipeResult'));
      expect((await wipe.counts()).isEmpty, isTrue);
      expect(await review.getItems(), isEmpty);
      expect(await migrator.isMigrated(), isTrue);
      // v1 data is not imported again after deleting everything.
      expect(
        (await migrator.run(defaultJobName: 'Mein Job')).migrated,
        isFalse,
      );

      final restored = await wipe.undo(result);
      expect(restored.shiftsAdded, countsBefore.shifts);
      expect(await wipe.counts(), countsBefore);
      expect((await review.getItems()).length, reviewBefore.length);
      expect(await review.getLegacyFailures(), failuresBefore);
    },
  );

  test('undo fails without the snapshot file', () async {
    await h.job();
    final result = await wipe.wipeAll(appVersion: '2.0.0');
    result.snapshot.deleteSync();
    await expectLater(
      wipe.undo(result),
      throwsA(
        isA<ChronosException>().having(
          (e) => e.code,
          'code',
          ChronosErrorCode.backupInvalid,
        ),
      ),
    );
  });
}
