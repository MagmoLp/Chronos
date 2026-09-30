import 'package:chronos/core/local_date.dart';
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

  setUp(() => h = DataHarness(local(2026, 9, 30, 12)));

  group('jobs', () {
    test('createJob stores the job and its first rate', () async {
      final job = await h.jobs.createJob(
        name: '  Catering  ',
        centsPerHour: 1500,
        rounding: RoundingRule.nearest15,
        colorArgb: 42,
      );
      expect(job.name, 'Catering');
      expect(job.rounding, RoundingRule.nearest15);
      expect(job.colorArgb, 42);
      expect(job.uuid, isNotEmpty);
      expect(job.sortOrder, 0);
      final rates = await h.jobs.getRates(job.id);
      expect(rates.single.centsPerHour, 1500);
      expect(rates.single.validFrom, LocalDate(2026, 9, 30)); // default today
    });

    test('createJob defaults and ordering', () async {
      final a = await h.job(name: 'A');
      final b = await h.job(name: 'B');
      expect(a.rounding, RoundingRule.none);
      expect(a.colorArgb, kDefaultJobColorArgb);
      expect(b.sortOrder, a.sortOrder + 1);
      expect((await h.jobs.getJobs()).map((j) => j.name), ['A', 'B']);
    });

    test('createJob validates input', () {
      expect(
        () => h.jobs.createJob(name: ' ', centsPerHour: 1500),
        throwsCode(ChronosErrorCode.emptyName),
      );
      expect(
        () => h.jobs.createJob(name: 'X', centsPerHour: -1),
        throwsCode(ChronosErrorCode.invalidAmount),
      );
    });

    test('updateJob saves fields', () async {
      final job = await h.job();
      final updated = await h.jobs.updateJob(
        job.copyWith(
          name: 'Bar',
          rounding: RoundingRule.nearest5,
          colorArgb: 7,
        ),
      );
      expect(updated.name, 'Bar');
      expect(updated.rounding, RoundingRule.nearest5);
      expect(updated.colorArgb, 7);
      expect(await h.jobs.getJob(job.id), updated);
    });

    test('updateJob errors', () async {
      final job = await h.job();
      expect(
        () => h.jobs.updateJob(job.copyWith(name: '')),
        throwsCode(ChronosErrorCode.emptyName),
      );
      expect(
        () => h.jobs.updateJob(job.copyWith(id: 999)),
        throwsCode(ChronosErrorCode.jobNotFound),
      );
      expect(
        () => h.jobs.setArchived(999, true),
        throwsCode(ChronosErrorCode.jobNotFound),
      );
    });

    test('the last active job cannot be archived', () async {
      final a = await h.job(name: 'A');
      await expectLater(
        h.jobs.setArchived(a.id, true),
        throwsCode(ChronosErrorCode.lastActiveJob),
      );
      final b = await h.job(name: 'B');
      final archived = await h.jobs.setArchived(a.id, true);
      expect(archived.archived, isTrue);
      await expectLater(
        h.jobs.setArchived(b.id, true),
        throwsCode(ChronosErrorCode.lastActiveJob),
      );
      expect((await h.jobs.getJobs(includeArchived: false)).map((j) => j.id), [
        b.id,
      ]);
      expect(await h.jobs.getJobs(), hasLength(2));
      final restored = await h.jobs.setArchived(a.id, false);
      expect(restored.archived, isFalse);
    });

    test('watchJobs emits changes and filters archived jobs', () async {
      final a = await h.job(name: 'A');
      await h.job(name: 'B');
      final stream = h.jobs.watchJobs(includeArchived: false);
      expect((await stream.first).map((j) => j.name), ['A', 'B']);
      await h.jobs.setArchived(a.id, true);
      expect((await stream.first).map((j) => j.name), ['B']);
      expect((await h.jobs.watchJobs().first), hasLength(2));
      expect((await h.jobs.watchJob(a.id).first)!.archived, isTrue);
      expect(await h.jobs.watchJob(999).first, isNull);
    });

    test('reorder', () async {
      final a = await h.job(name: 'A');
      final b = await h.job(name: 'B');
      final c = await h.job(name: 'C');
      await h.jobs.reorder([c.id, a.id, b.id]);
      expect((await h.jobs.getJobs()).map((j) => j.name), ['C', 'A', 'B']);
    });
  });

  group('wage rates', () {
    test('rateFor picks by date with fallback to the earliest', () async {
      final job = await h.job();
      await h.jobs.addRate(
        job.id,
        validFrom: LocalDate(2026, 7, 1),
        centsPerHour: 1600,
      );
      expect(await h.jobs.rateFor(job.id, LocalDate(2026, 6, 30)), 1500);
      expect(await h.jobs.rateFor(job.id, LocalDate(2026, 7, 1)), 1600);
      expect(await h.jobs.rateFor(job.id, LocalDate(2025, 1, 1)), 1500);
      expect(await h.jobs.rateFor(999, LocalDate(2026, 1, 1)), isNull);
    });

    test('rates are listed newest first and watched', () async {
      final job = await h.job();
      final stream = h.jobs.watchRates(job.id);
      expect((await stream.first), hasLength(1));
      await h.jobs.addRate(
        job.id,
        validFrom: LocalDate(2026, 7, 1),
        centsPerHour: 1600,
      );
      final rates = await stream.first;
      expect(rates.map((r) => r.centsPerHour), [1600, 1500]);
    });

    test('addRate on the same date replaces the rate', () async {
      final job = await h.job();
      await h.jobs.addRate(
        job.id,
        validFrom: LocalDate(2026, 1, 1),
        centsPerHour: 1390,
      );
      final rates = await h.jobs.getRates(job.id);
      expect(rates.single.centsPerHour, 1390);
    });

    test('addRate validates', () async {
      final job = await h.job();
      expect(
        () => h.jobs.addRate(
          job.id,
          validFrom: LocalDate(2026, 1, 1),
          centsPerHour: -5,
        ),
        throwsCode(ChronosErrorCode.invalidAmount),
      );
      await expectLater(
        h.jobs.addRate(999, validFrom: LocalDate(2026, 1, 1), centsPerHour: 5),
        throwsCode(ChronosErrorCode.jobNotFound),
      );
    });

    Future<({int early, int open, int paid, int deleted, int otherJob})>
    seedShifts(Job job) async {
      final other = await h.job(name: 'Other');
      Future<int> add(int day, {int? jobId}) async =>
          (await h.shifts.insertManual(
            ShiftDraft(
              jobId: jobId ?? job.id,
              startUtc: local(2026, 9, day, 8),
              endUtc: local(2026, 9, day, 16),
            ),
          )).id;
      final early = await add(1);
      final open = await add(20);
      final paid = await add(21);
      final deleted = await add(22);
      final otherJob = await add(23, jobId: other.id);
      await h.shifts.setPaid([paid], true);
      await h.shifts.softDelete([deleted]);
      return (
        early: early,
        open: open,
        paid: paid,
        deleted: deleted,
        otherJob: otherJob,
      );
    }

    test('new rate does not change old shifts by default', () async {
      final job = await h.job();
      final ids = await seedShifts(job);
      final count = await h.jobs.addRate(
        job.id,
        validFrom: LocalDate(2026, 9, 15),
        centsPerHour: 2000,
      );
      expect(count, 0);
      expect((await h.shifts.getById(ids.open))!.rateCentsPerHour, 1500);
      expect((await h.shifts.getById(ids.open))!.amountCents, 12000);
    });

    test(
      'recalcOpenFromDate re-prices only open shifts from that date',
      () async {
        final job = await h.job();
        final ids = await seedShifts(job);
        final count = await h.jobs.addRate(
          job.id,
          validFrom: LocalDate(2026, 9, 15),
          centsPerHour: 2000,
          recalcOpenFromDate: true,
        );
        expect(count, 1);
        final open = (await h.shifts.getById(ids.open))!;
        expect(open.rateCentsPerHour, 2000);
        expect(open.amountCents, 16000);
        expect((await h.shifts.getById(ids.early))!.rateCentsPerHour, 1500);
        expect((await h.shifts.getById(ids.paid))!.rateCentsPerHour, 1500);
        expect((await h.shifts.getById(ids.deleted))!.rateCentsPerHour, 1500);
        expect((await h.shifts.getById(ids.otherJob))!.rateCentsPerHour, 1500);
      },
    );

    test('recalc respects a later rate that still applies', () async {
      final job = await h.job();
      await h.jobs.addRate(
        job.id,
        validFrom: LocalDate(2026, 9, 21),
        centsPerHour: 1800,
      );
      final ids = await seedShifts(job);
      // Open shift of 20 Sep has 1500, a new rate from 1 Sep applies to it,
      // the 1800 from 21 Sep would still apply to later shifts.
      await h.jobs.addRate(
        job.id,
        validFrom: LocalDate(2026, 9, 1),
        centsPerHour: 1600,
        recalcOpenFromDate: true,
      );
      expect((await h.shifts.getById(ids.early))!.rateCentsPerHour, 1600);
      expect((await h.shifts.getById(ids.open))!.rateCentsPerHour, 1600);
    });

    test('recalc also updates a running shift started in range', () async {
      final job = await h.job();
      await h.shifts.start(job.id, startUtc: local(2026, 9, 30, 8));
      final count = await h.jobs.addRate(
        job.id,
        validFrom: LocalDate(2026, 9, 30),
        centsPerHour: 2000,
        recalcOpenFromDate: true,
      );
      expect(count, 1);
      final running = (await h.shifts.getRunning())!;
      expect(running.rateCentsPerHour, 2000);
      expect(running.amountCents, isNull);
    });

    test('deleteRate keeps at least one rate', () async {
      final job = await h.job();
      await h.jobs.addRate(
        job.id,
        validFrom: LocalDate(2026, 7, 1),
        centsPerHour: 1600,
      );
      final rates = await h.jobs.getRates(job.id);
      await h.jobs.deleteRate(rates.first.id);
      final left = await h.jobs.getRates(job.id);
      expect(left.single.centsPerHour, 1500);
      await expectLater(
        h.jobs.deleteRate(left.single.id),
        throwsCode(ChronosErrorCode.noWageRate),
      );
      await h.jobs.deleteRate(12345); // unknown id: no-op
    });
  });
}
