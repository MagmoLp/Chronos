import 'dart:convert';

import 'package:chronos/core/local_date.dart';
import 'package:chronos/data/backup/backup_models.dart';
import 'package:chronos/data/backup/backup_service.dart';
import 'package:chronos/data/payout_repository.dart';
import 'package:chronos/domain/app_settings.dart';
import 'package:chronos/domain/errors.dart';
import 'package:chronos/domain/job.dart';
import 'package:chronos/domain/shift_draft.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/db.dart';
import '../fixtures/shifts.dart';

Matcher throwsCode(ChronosErrorCode code) =>
    throwsA(isA<ChronosException>().having((e) => e.code, 'code', code));

void main() {
  late DataHarness h;
  late BackupService backup;
  late PayoutRepository payouts;

  const settings = AppSettings(
    language: AppLanguage.de,
    themeMode: AppThemeMode.dark,
    monthlyGoalCents: 60300,
    monthlyGoalType: MonthlyGoalType.limit,
    reminderHours: 8,
    onboardingDone: true,
  );

  setUp(() {
    h = DataHarness(local(2026, 9, 30, 12));
    backup = BackupService(h.db, clock: h.clock.clock);
    payouts = PayoutRepository(h.db, clock: h.clock.clock);
  });

  Future<void> seed() async {
    final a = await h.job(name: 'Catering');
    final b = await h.jobs.createJob(
      name: 'Bar',
      centsPerHour: 1390,
      rounding: RoundingRule.nearest5,
      colorArgb: 0xFF00796B,
      validFrom: LocalDate(2026, 2, 1),
    );
    await h.jobs.addRate(
      a.id,
      validFrom: LocalDate(2026, 7, 1),
      centsPerHour: 1600,
    );
    for (var d = 1; d <= 5; d++) {
      await h.shifts.insertManual(
        ShiftDraft(
          jobId: d.isEven ? a.id : b.id,
          startUtc: local(2026, 9, d, 8),
          endUtc: local(2026, 9, d, 16, 30),
          breakMs: 30 * 60000,
          tipsCents: d * 100,
          note: d == 3 ? 'Hochzeit' : null,
        ),
      );
    }
    await payouts.create(
      until: LocalDate(2026, 9, 2),
      jobId: b.id,
      receivedCents: 1,
    );
    final deleted = await h.shifts.insertManual(
      ShiftDraft(
        jobId: a.id,
        startUtc: local(2026, 9, 6, 8),
        endUtc: local(2026, 9, 6, 9),
      ),
    );
    await h.shifts.softDelete([deleted.id]);
    await h.shifts.start(a.id, startUtc: local(2026, 9, 30, 8));
    await h.shifts.pause(atUtc: local(2026, 9, 30, 10));
  }

  /// Export without volatile fields, for comparing two databases.
  Future<Map<String, Object?>> snapshot() async {
    final map = await backup.export(appVersion: '2.0.0', settings: settings);
    return (jsonDecode(jsonEncode(map)) as Map<String, Object?>)
      ..remove('exportedAt');
  }

  test('export has the documented shape', () async {
    await seed();
    final map = await backup.export(appVersion: '2.0.0+2', settings: settings);
    expect(map['formatVersion'], kBackupFormatVersion);
    expect(map['schemaVersion'], 1);
    expect(map['appVersion'], '2.0.0+2');
    expect(map['exportedAt'], h.clock.now.toIso8601String());
    expect((map['settings']! as Map)['language'], 'de');
    expect(map['jobs'], hasLength(2));
    expect(map['wageRates'], hasLength(3));
    expect(map['shifts'], hasLength(6)); // 5 done + running, deleted excluded
    expect(map['payouts'], hasLength(1));
    expect(map.containsKey('reviewItems'), isFalse);
    final shift = (map['shifts']! as List).first as Map;
    expect(shift['startUtc'], isA<int>());
    expect(shift['jobUuid'], isA<String>());
    expect(
      (map['wageRates']! as List).first,
      containsPair('validFrom', '2026-01-01'),
    );
    expect(jsonDecode(backup.encode(map)), isA<Map<String, Object?>>());
  });

  test('round-trip: export → replace import reproduces the data', () async {
    await seed();
    final before = await snapshot();
    final json = backup.encode(
      await backup.export(appVersion: '2.0.0', settings: settings),
    );
    await h.db.deleteAllData();
    final contents = backup.parse(json);
    final result = await backup.import(contents, ImportMode.replace);
    expect(result.jobsAdded, 2);
    expect(result.ratesAdded, 3);
    expect(result.shiftsAdded, 6);
    expect(result.payoutsAdded, 1);
    expect(result.settings, settings.copyWith(onboardingDone: false));
    expect(await snapshot(), before);
    final running = (await h.shifts.getRunning())!;
    expect(running.pausedAtUtc, local(2026, 9, 30, 10));
    final paid = (await h.shifts.getDone()).where((s) => s.isPaid).toList();
    expect(paid.single.payoutId, isNotNull);
  });

  test('replace wipes existing data first', () async {
    await seed();
    final json = backup.encode(await backup.export(appVersion: '2.0.0'));
    await h.job(name: 'Other');
    final result = await backup.import(backup.parse(json), ImportMode.replace);
    expect(result.mode, ImportMode.replace);
    expect((await h.jobs.getJobs()).map((j) => j.name), ['Catering', 'Bar']);
  });

  test('merge adds unknown data by UUID and skips the rest', () async {
    await seed();
    final json = backup.encode(await backup.export(appVersion: '2.0.0'));
    // Same data again: nothing new.
    final same = await backup.import(backup.parse(json), ImportMode.merge);
    expect(same.jobsAdded, 0);
    expect(same.ratesAdded, 0);
    expect(same.shiftsAdded, 0);
    expect(same.shiftsSkipped, 6);
    expect(same.payoutsAdded, 0);
    expect(same.toString(), contains('merge'));

    // A second phone: other data, plus a running shift that must be skipped.
    final other = DataHarness(local(2026, 9, 30, 12));
    final otherBackup = BackupService(other.db, clock: other.clock.clock);
    final job = await other.job(name: 'Messe');
    await other.shifts.insertManual(
      ShiftDraft(
        jobId: job.id,
        startUtc: local(2026, 8, 1, 8),
        endUtc: local(2026, 8, 1, 12),
      ),
    );
    await other.shifts.start(job.id, startUtc: local(2026, 9, 30, 9));
    final otherJson = otherBackup.encode(
      await otherBackup.export(appVersion: '2.0.0'),
    );

    final merged = await backup.import(
      backup.parse(otherJson),
      ImportMode.merge,
    );
    expect(merged.jobsAdded, 1);
    expect(merged.ratesAdded, 1);
    expect(merged.shiftsAdded, 1);
    expect(merged.runningSkipped, isTrue);
    expect(await h.jobs.getJobs(), hasLength(3));
    expect((await h.shifts.getRunning())!.startUtc, local(2026, 9, 30, 8));
  });

  test('summary', () async {
    await seed();
    final contents = backup.parse(
      backup.encode(await backup.export(appVersion: '2.0.0')),
    );
    final summary = contents.summary;
    expect(summary.jobCount, 2);
    expect(summary.shiftCount, 6);
    expect(summary.payoutCount, 1);
    expect(summary.hasRunningShift, isTrue);
    expect(summary.appVersion, '2.0.0');
    expect(summary.exportedAt, h.clock.now);
    expect(summary.firstShiftUtc, local(2026, 9, 1, 8));
    expect(summary.lastShiftUtc, local(2026, 9, 30, 8));
    expect(summary.toString(), contains('6 shifts'));
  });

  group('validation', () {
    late Map<String, Object?> valid;

    setUp(() async {
      await seed();
      valid = jsonDecode(
        backup.encode(await backup.export(appVersion: '2.0.0')),
      ) as Map<String, Object?>;
    });

    Map<String, Object?> copy() =>
        jsonDecode(jsonEncode(valid)) as Map<String, Object?>;

    List<Map<String, Object?>> listOf(Map<String, Object?> m, String key) =>
        (m[key]! as List).cast<Map<String, Object?>>();

    void expectInvalid(Map<String, Object?> m, [String? path]) {
      expect(
        () => backup.parseMap(m),
        throwsA(
          isA<ChronosException>()
              .having((e) => e.code, 'code', ChronosErrorCode.backupInvalid)
              .having((e) => e.detail, 'detail', path ?? anything),
        ),
      );
    }

    test('newer format is rejected with its own code', () {
      expect(
        () => backup.parseMap(copy()..['formatVersion'] = 2),
        throwsCode(ChronosErrorCode.backupNewerFormat),
      );
    });

    test('garbage input', () {
      expect(
        () => backup.parse('not json'),
        throwsCode(ChronosErrorCode.backupInvalid),
      );
      expect(
        () => backup.parse('[]'),
        throwsCode(ChronosErrorCode.backupInvalid),
      );
      expectInvalid(copy()..['formatVersion'] = 0, r'$.formatVersion');
      expectInvalid(copy()..remove('formatVersion'), r'$.formatVersion');
      expectInvalid(copy()..remove('jobs'), r'$.jobs');
      expectInvalid(copy()..['shifts'] = [1], r'$.shifts[0]');
    });

    test('broken references and values', () {
      final badJobRef = copy();
      listOf(badJobRef, 'shifts').first['jobUuid'] = 'nope';
      expectInvalid(badJobRef, r'$.shifts[0].jobUuid');

      final badRate = copy();
      listOf(badRate, 'wageRates').first['centsPerHour'] = -1;
      expectInvalid(badRate, r'$.wageRates[0].centsPerHour');

      final badDate = copy();
      listOf(badDate, 'wageRates').first['validFrom'] = '2026-02-30';
      expectInvalid(badDate, r'$.wageRates[0].validFrom');

      final badEnd = copy();
      listOf(badEnd, 'shifts').first['endUtc'] = 0;
      expectInvalid(badEnd, r'$.shifts[0].endUtc');

      final dupUuid = copy();
      final jobs = listOf(dupUuid, 'jobs');
      jobs.last['uuid'] = jobs.first['uuid'];
      expectInvalid(dupUuid, r'$.jobs[1].uuid');

      final twoRunning = copy();
      final shifts = listOf(twoRunning, 'shifts');
      shifts.first['status'] = 'running';
      expectInvalid(twoRunning);

      final badPayoutRef = copy();
      listOf(badPayoutRef, 'shifts').first['payoutUuid'] = 'nope';
      expectInvalid(badPayoutRef, r'$.shifts[0].payoutUuid');

      final badEnum = copy();
      listOf(badEnum, 'jobs').first['rounding'] = 'nearest7';
      expectInvalid(badEnum, r'$.jobs[0].rounding');

      final badType = copy();
      listOf(badType, 'shifts').first['startUtc'] = '2026';
      expectInvalid(badType, r'$.shifts[0].startUtc');
    });

    test('optional fields get sensible defaults', () {
      final m = copy();
      final shift = listOf(m, 'shifts').first
        ..remove('amountCents')
        ..remove('rawStartUtc')
        ..remove('updatedAt');
      final contents = backup.parseMap(m);
      final parsed = contents.shifts.first.shift;
      expect(parsed.amountCents, isNotNull);
      expect(parsed.rawStartUtc.millisecondsSinceEpoch, shift['startUtc']);
      expect(contents.settings, isNull);
    });
  });

  test('settings codec is lenient', () {
    expect(
      settingsFromJson(settingsToJson(settings)),
      settings.copyWith(onboardingDone: false),
    );
    expect(
      settingsFromJson(const {'language': 'x', 'reminderHours': 7}),
      AppSettings.defaults,
    );
  });
}
