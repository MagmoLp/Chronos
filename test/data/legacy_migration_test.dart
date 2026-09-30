import 'dart:convert';
import 'dart:io';

import 'package:chronos/core/local_date.dart';
import 'package:chronos/core/time.dart';
import 'package:chronos/data/database.dart';
import 'package:chronos/data/job_repository.dart';
import 'package:chronos/data/legacy/legacy_migration.dart';
import 'package:chronos/data/legacy/legacy_models.dart';
import 'package:chronos/data/legacy/legacy_parser.dart';
import 'package:chronos/data/mappers.dart';
import 'package:chronos/data/review_repository.dart';
import 'package:chronos/data/shift_repository.dart';
import 'package:chronos/domain/app_settings.dart';
import 'package:chronos/domain/errors.dart';
import 'package:chronos/domain/job.dart';
import 'package:chronos/domain/review.dart';
import 'package:chronos/domain/shift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fixtures/db.dart';
import '../fixtures/legacy_v1.dart';
import '../fixtures/shifts.dart';
import '../fixtures/test_clock.dart';
import '../fixtures/tz.dart';

class FakeLegacySource implements LegacySource {
  FakeLegacySource(this.data);

  LegacyRawData data;

  @override
  Future<LegacyRawData> read() async => data;
}

/// Local wall-clock ISO (v1 format) → UTC instant.
DateTime v1(String iso) => DateTime.parse(iso).toUtc();

void main() {
  late AppDatabase db;
  late TestClock clock;
  late Directory dir;
  late FakeLegacySource source;
  late LegacyMigrator migrator;
  late ShiftRepository shifts;
  late JobRepository jobs;
  late ReviewRepository review;

  setUp(() {
    db = memoryDb();
    clock = TestClock(local(2026, 9, 30, 12));
    dir = tempDir();
    source = FakeLegacySource(
      LegacyRawData(
        workEntries: LegacyV1.workEntries,
        appSettings: LegacyV1.settingsGerman,
        activeSession: LegacyV1.activeSession,
      ),
    );
    migrator = LegacyMigrator(
      db: db,
      source: source,
      backupDirectory: () async => dir,
      clock: clock.clock,
    );
    jobs = JobRepository(db, clock: clock.clock);
    shifts = ShiftRepository(db, clock: clock.clock, jobs: jobs);
    review = ReviewRepository(db);
  });

  Future<List<Shift>> allShifts() async => [
    for (final r in await db.select(db.shifts).get()) r.toDomain(),
  ];

  Shift byStart(List<Shift> list, String iso) =>
      list.firstWhere((s) => s.rawStartUtc == v1(iso) && s.isDone);

  group('realistic v1 installation', () {
    late LegacyMigrationReport report;

    setUp(() async {
      report = await migrator.run(defaultJobName: 'Mein Job');
    });

    test('report', () {
      expect(report.status, LegacyMigrationStatus.migrated);
      expect(report.migrated, isTrue);
      expect(report.importedCount, LegacyV1.importable);
      expect(report.failures, hasLength(LegacyV1.broken));
      expect(report.activeSessionImported, isTrue);
      expect(report.wageCentsPerHour, 1500);
      expect(report.wagePlausibility!.isPlausible, isTrue);
      expect(report.language, AppLanguage.de);
      expect(report.backupPath, endsWith(LegacyMigrator.backupFileName));
      expect(report.backupError, isNull);
      expect(report.reviewCount, greaterThan(0));
      expect(report.toString(), contains('imported 10'));
    });

    test('creates "Mein Job" with 15-min rounding and the v1 wage', () async {
      final job = (await jobs.getJob(report.jobId!))!;
      expect(job.name, 'Mein Job');
      expect(job.rounding, RoundingRule.nearest15);
      expect(job.colorArgb, kDefaultJobColorArgb);
      final rates = await jobs.getRates(job.id);
      expect(rates.single.centsPerHour, 1500);
      // Earliest entry: 25 Oct 2025.
      expect(rates.single.validFrom, LocalDate(2025, 10, 25));
    });

    test(
      'converts local times to UTC with offsets, keeps paid and ids',
      () async {
        final list = await allShifts();
        final first = byStart(list, '2026-05-26T08:00:00.000');
        expect(first.startUtc, v1('2026-05-26T08:00:00.000'));
        expect(first.endUtc, v1('2026-05-26T16:15:00.000'));
        expect(first.rawEndUtc, first.endUtc);
        expect(first.startOffsetMin, offsetMinutesAt(first.startUtc));
        expect(first.source, ShiftSource.legacy);
        expect(first.rateCentsPerHour, 1500);
        expect(first.amountCents, 12375);
        expect(first.breakMs, 0);
        expect(first.isPaid, isFalse);

        final manual = list.firstWhere((s) => s.legacyId == LegacyV1.manualId);
        expect(manual.isPaid, isTrue);
        expect(manual.paidAtUtc, clock.now);
        expect(manual.amountCents, 6750);

        final night = byStart(list, '2026-06-05T22:00:00.000');
        expect(night.workedMs, 8 * msPerHour);
        expect(night.localStartDate, LocalDate(2026, 6, 5));

        final noPaid = byStart(list, '2026-06-12T10:00:00.000');
        expect(noPaid.isPaid, isFalse);
        final noId = byStart(list, '2026-06-16T10:00:00.000');
        expect(noId.legacyId, isNull);
        expect(noId.isPaid, isTrue);
        expect(list.where((s) => s.legacyId == LegacyV1.timerId), hasLength(2));
      },
    );

    test('the active session becomes the running shift', () async {
      final running = (await shifts.getRunning())!;
      expect(running.startUtc, v1(LegacyV1.activeSession));
      expect(running.rateCentsPerHour, 1500);
      expect(running.source, ShiftSource.legacy);
    });

    test('broken entries are stored, not dropped', () async {
      final failures = await review.getLegacyFailures();
      expect(failures.map((f) => (f.origin, f.code)), [
        ('work_entries[9]', LegacyErrorCode.invalidStartTime),
        ('work_entries[10]', LegacyErrorCode.missingEndTime),
        ('work_entries[11]', LegacyErrorCode.notAnObject),
        ('work_entries[12]', LegacyErrorCode.endNotAfterStart),
      ]);
      expect(failures[2].raw, '42');
      expect(jsonDecode(failures[0].raw), LegacyV1.entries[9]);
    });

    test('suspicious entries land on the review list', () async {
      final list = await allShifts();
      final items = {for (final i in await review.getItems()) i.shiftId: i};
      Set<ReviewReason> reasons(String iso) =>
          items[byStart(list, iso).id]?.reasons ?? const {};

      expect(reasons('2026-05-26T08:00:00.000'), {
        ReviewReason.duplicateTimes,
        ReviewReason.duplicateLegacyId,
        ReviewReason.overlap,
      });
      expect(reasons('2026-05-28T08:00:00.000'), {
        ReviewReason.duplicateLegacyId,
      });
      expect(reasons('2026-06-10T09:00:00.000'), {
        ReviewReason.tooLong16h,
        ReviewReason.exactly23or24h,
      });
      expect(reasons('2026-03-29T08:00:00.000'), {ReviewReason.dstDay});
      expect(reasons('2025-10-25T22:00:00.000'), {ReviewReason.dstDay});
      expect(reasons('2026-06-05T22:00:00.000'), isEmpty);
      expect(reasons('2026-05-27T09:00:00.000'), isEmpty);
      expect(report.reviewCount, items.length);
    });

    test('is idempotent', () async {
      final again = await migrator.run(defaultJobName: 'Mein Job');
      expect(again.status, LegacyMigrationStatus.alreadyMigrated);
      expect(await jobs.getJobs(), hasLength(1));
      expect(await allShifts(), hasLength(LegacyV1.importable + 1));
      expect(await migrator.isMigrated(), isTrue);
    });

    test('the raw data is backed up verbatim', () async {
      final file = File(report.backupPath!);
      final json = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
      final keys = json['keys']! as Map<String, Object?>;
      expect(keys['work_entries'], LegacyV1.workEntries);
      expect(keys['app_settings'], LegacyV1.settingsGerman);
      expect(keys['active_session'], LegacyV1.activeSession);
      expect(json['format'], 'chronos-legacy-v1-backup');
    });

    test('wage is plausible: nothing to ask', () async {
      expect(await migrator.pendingWageCheck(), isNull);
    });

    test('exportRawJson for the recovery screen', () async {
      final raw = jsonDecode(await migrator.exportRawJson()) as Map;
      expect(raw['active_session'], LegacyV1.activeSession);
    });
  });

  group('1250 €/h (v1 comma bug)', () {
    setUp(() {
      source.data = LegacyRawData(
        workEntries: LegacyV1.workEntries,
        appSettings: LegacyV1.settings1250,
        activeSession: LegacyV1.activeSession,
      );
    });

    test('is reported and pending until corrected', () async {
      final report = await migrator.run(defaultJobName: 'My job');
      expect(report.wageCentsPerHour, 125000);
      expect(report.language, AppLanguage.en);
      final check = report.wagePlausibility!;
      expect(check.issue, WageIssue.tooHigh);
      expect(check.suggestedCentsPerHour, 1250);
      expect(await migrator.pendingWageCheck(), check);
    });

    test('correctWage fixes rate, snapshots and amounts', () async {
      final report = await migrator.run(defaultJobName: 'My job');
      final updated = await migrator.correctWage(1250);
      expect(updated, LegacyV1.importable + 1);
      expect((await jobs.getRates(report.jobId!)).single.centsPerHour, 1250);
      final list = await allShifts();
      expect(list.every((s) => s.rateCentsPerHour == 1250), isTrue);
      final first = byStart(list, '2026-05-26T08:00:00.000');
      expect(first.amountCents, 10313); // 8.25 h × 12,50 € = 103,125 → 103,13
      final paid = list.firstWhere((s) => s.legacyId == LegacyV1.manualId);
      expect(paid.amountCents, 5625);
      expect((await shifts.getRunning())!.amountCents, isNull);
      expect(await migrator.pendingWageCheck(), isNull);
    });

    test('confirmWage keeps the wage', () async {
      await migrator.run(defaultJobName: 'My job');
      await migrator.confirmWage();
      expect(await migrator.pendingWageCheck(), isNull);
    });

    test('a later plausible rate change clears the question', () async {
      final report = await migrator.run(defaultJobName: 'My job');
      await jobs.addRate(
        report.jobId!,
        validFrom: LocalDate(2025, 10, 25),
        centsPerHour: 1300,
      );
      expect(await migrator.pendingWageCheck(), isNull);
    });
  });

  test('correctWage without migration fails', () async {
    await expectLater(
      migrator.correctWage(1500),
      throwsA(isA<ChronosException>()),
    );
    expect(() => migrator.correctWage(-1), throwsA(isA<ChronosException>()));
    expect(await migrator.pendingWageCheck(), isNull);
  });

  test('no v1 data: nothing happens', () async {
    source.data = const LegacyRawData();
    final report = await migrator.run(defaultJobName: 'Mein Job');
    expect(report.status, LegacyMigrationStatus.noLegacyData);
    expect(await jobs.getJobs(), isEmpty);
    expect(await migrator.isMigrated(), isFalse);
    expect(dir.listSync(), isEmpty);
  });

  test('empty list with settings: job created, no shifts', () async {
    source.data = const LegacyRawData(
      workEntries: '[]',
      appSettings: LegacyV1.settingsGerman,
    );
    final report = await migrator.run(defaultJobName: 'Mein Job');
    expect(report.migrated, isTrue);
    expect(report.importedCount, 0);
    expect(report.failures, isEmpty);
    expect(report.activeSessionImported, isFalse);
    final rates = await jobs.getRates(report.jobId!);
    expect(rates.single.validFrom, LocalDate(2000, 1, 1));
  });

  test('missing settings use the v1 default wage', () async {
    source.data = LegacyRawData(workEntries: LegacyV1.workEntries);
    final report = await migrator.run(defaultJobName: 'Mein Job');
    expect(report.wageCentsPerHour, kLegacyDefaultWageCents);
    expect(report.language, isNull);
    expect(await shifts.getRunning(), isNull);
  });

  test('unreadable work_entries are kept as one failure', () async {
    source.data = const LegacyRawData(
      workEntries: '[{"id":',
      appSettings: LegacyV1.settingsGerman,
    );
    final report = await migrator.run(defaultJobName: 'Mein Job');
    expect(report.migrated, isTrue);
    expect(report.failures.single.code, LegacyErrorCode.invalidJson);
    expect(report.failures.single.raw, '[{"id":');
  });

  test('work_entries that is not a list', () async {
    source.data = const LegacyRawData(workEntries: '{"a":1}');
    final report = await migrator.run(defaultJobName: 'Mein Job');
    expect(report.failures.single.code, LegacyErrorCode.notAList);
  });

  test('a v2 running shift wins over the v1 session', () async {
    final existing = await jobs.createJob(name: 'v2', centsPerHour: 1500);
    await shifts.start(existing.id);
    final report = await migrator.run(defaultJobName: 'Mein Job');
    expect(report.activeSessionImported, isFalse);
    expect(
      report.failures.map((f) => f.code),
      contains(LegacyErrorCode.runningShiftExists),
    );
    expect((await shifts.getRunning())!.jobId, existing.id);
    expect((await jobs.getJob(report.jobId!))!.sortOrder, 1);
  });

  test('invalid active session is a failure', () async {
    source.data = const LegacyRawData(activeSession: 'gestern');
    final report = await migrator.run(defaultJobName: 'Mein Job');
    expect(report.failures.single.code, LegacyErrorCode.invalidActiveSession);
    expect(report.activeSessionImported, isFalse);
  });

  test('a failing backup folder does not stop the migration', () async {
    final m = LegacyMigrator(
      db: db,
      source: source,
      backupDirectory: () async => throw const FileSystemException('no dir'),
      clock: clock.clock,
    );
    final report = await m.run(defaultJobName: 'Mein Job');
    expect(report.migrated, isTrue);
    expect(report.backupPath, isNull);
    expect(report.backupError, contains('no dir'));
  });

  test('an existing backup is kept; different data gets a new file', () async {
    final first = File('${dir.path}/${LegacyMigrator.backupFileName}');
    first.writeAsStringSync(
      jsonEncode({
        'keys': {
          'work_entries': 'old',
          'app_settings': null,
          'active_session': null,
        },
      }),
    );
    final report = await migrator.run(defaultJobName: 'Mein Job');
    expect(report.backupPath, isNot(first.path));
    final kept = jsonDecode(first.readAsStringSync()) as Map<String, Object?>;
    expect((kept['keys']! as Map<String, Object?>)['work_entries'], 'old');
    expect(File(report.backupPath!).existsSync(), isTrue);
  });

  test('same data again reuses the existing backup file', () async {
    final report = await migrator.run(defaultJobName: 'Mein Job');
    // Simulate a restore that brings v1 data back after a wipe of meta.
    await db.deleteMeta(LegacyMigrator.kMetaMigratedAt);
    await db.deleteAllData();
    final again = await migrator.run(defaultJobName: 'Mein Job');
    expect(again.backupPath, report.backupPath);
    expect(dir.listSync().whereType<File>(), hasLength(1));
  });

  test('empty job name is rejected', () {
    expect(() => migrator.run(defaultJobName: ' '), throwsArgumentError);
  });

  test('Berlin: DST entries get the right instants and offsets', () async {
    await migrator.run(defaultJobName: 'Mein Job');
    final list = await allShifts();
    final spring = byStart(list, '2026-03-29T08:00:00.000');
    expect(spring.startUtc, DateTime.utc(2026, 3, 29, 6));
    expect(spring.startOffsetMin, 120);
    final autumn = byStart(list, '2025-10-25T22:00:00.000');
    expect(autumn.startUtc, DateTime.utc(2025, 10, 25, 20));
    expect(autumn.endUtc, DateTime.utc(2025, 10, 26, 5));
    expect(autumn.startOffsetMin, 120);
    expect(autumn.endOffsetMin, 60);
    expect(autumn.workedMs, 9 * msPerHour);
    expect(autumn.amountCents, 13500);
  }, skip: skipUnlessBerlin);

  group('SharedPreferencesLegacySource', () {
    test('reads the legacy keys', () async {
      SharedPreferences.setMockInitialValues({
        SharedPreferencesLegacySource.keyWorkEntries: LegacyV1.workEntries,
        SharedPreferencesLegacySource.keyAppSettings: LegacyV1.settingsGerman,
        SharedPreferencesLegacySource.keyActiveSession: LegacyV1.activeSession,
        'unrelated': 'x',
      });
      final data = await const SharedPreferencesLegacySource().read();
      expect(data.workEntries, LegacyV1.workEntries);
      expect(data.appSettings, LegacyV1.settingsGerman);
      expect(data.activeSession, LegacyV1.activeSession);
      expect(data.isEmpty, isFalse);
    });

    test('empty preferences', () async {
      SharedPreferences.setMockInitialValues({});
      final data = await const SharedPreferencesLegacySource().read();
      expect(data.isEmpty, isTrue);
    });
  });

  group('parser details', () {
    test('settings variants', () {
      expect(parseLegacySettings('{"hourlyWage":"12,50"}').wageCents, 1250);
      expect(parseLegacySettings('{"hourlyWage":13.9}').wageCents, 1390);
      expect(parseLegacySettings('{"hourlyWage":13}').wageCents, 1300);
      expect(
        parseLegacySettings('{"language":"english"}').language,
        AppLanguage.en,
      );
      expect(parseLegacySettings('{"language":"french"}').language, isNull);
      final notObject = parseLegacySettings('[1]');
      expect(notObject.wageCents, kLegacyDefaultWageCents);
      expect(notObject.failure!.code, LegacyErrorCode.invalidSettings);
      final badWage = parseLegacySettings('{"hourlyWage":-3}');
      expect(badWage.failure, isNotNull);
      expect(parseLegacySettings('{broken').failure, isNotNull);
      expect(parseLegacySettings(null).failure, isNull);
    });

    test('active session with explicit offset is respected', () {
      final r = parseLegacyActiveSession('2026-09-30T05:45:00.000Z');
      expect(r.startUtc, DateTime.utc(2026, 9, 30, 5, 45));
      expect(
        parseLegacyActiveSession(12).failure!.code,
        LegacyErrorCode.invalidActiveSession,
      );
      expect(parseLegacyActiveSession(null).startUtc, isNull);
    });

    test('isPaid variants and non-string ids', () {
      final parsed = parseLegacyWorkEntries(
        jsonEncode([
          {
            'id': 5,
            'startTime': '2026-01-01T08:00:00.000',
            'endTime': '2026-01-01T09:00:00.000',
            'isPaid': 'true',
          },
          {
            'startTime': '2026-01-02T08:00:00.000',
            'endTime': '2026-01-02T09:00:00.000',
            'isPaid': 1,
          },
          {
            'startTime': '2026-01-03T08:00:00.000',
            'endTime': '2026-01-03T09:00:00.000',
            'isPaid': 'no',
          },
          {'endTime': '2026-01-03T09:00:00.000'},
          {'startTime': '2026-01-03T08:00:00.000', 'endTime': 7},
        ]),
      );
      expect(parsed.entries.map((e) => e.isPaid), [true, true, false]);
      expect(parsed.entries.first.legacyId, '5');
      expect(parsed.failures.map((f) => f.code), [
        LegacyErrorCode.missingStartTime,
        LegacyErrorCode.invalidEndTime,
      ]);
      expect(parseLegacyWorkEntries(null).entries, isEmpty);
      expect(
        parseLegacyWorkEntries([
          {
            'startTime': '2026-01-01T08:00:00.000',
            'endTime': '2026-01-01T09:00:00.000',
          },
        ]).entries,
        hasLength(1),
      );
    });

    test('models', () {
      const f = LegacyFailure(
        origin: 'o',
        raw: 'r',
        code: LegacyErrorCode.notAList,
      );
      expect(
        f,
        const LegacyFailure(
          origin: 'o',
          raw: 'r',
          code: LegacyErrorCode.notAList,
        ),
      );
      expect(
        f.hashCode,
        const LegacyFailure(
          origin: 'o',
          raw: 'r',
          code: LegacyErrorCode.notAList,
        ).hashCode,
      );
      expect(f.toString(), contains('notAList'));
      expect(const LegacyRawData().toJson().keys, [
        'work_entries',
        'app_settings',
        'active_session',
      ]);
      expect(LegacyMigrationReport.noLegacyData.migrated, isFalse);
    });
  });
}
