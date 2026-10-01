import 'package:chronos/core/local_date.dart';
import 'package:chronos/core/time.dart';
import 'package:chronos/data/shift_repository.dart';
import 'package:chronos/domain/errors.dart';
import 'package:chronos/domain/job.dart';
import 'package:chronos/domain/shift.dart';
import 'package:chronos/domain/shift_draft.dart';
import 'package:chronos/domain/validation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/db.dart';
import '../fixtures/shifts.dart';
import '../fixtures/tz.dart';

Matcher throwsCode(ChronosErrorCode code) =>
    throwsA(isA<ChronosException>().having((e) => e.code, 'code', code));

void main() {
  late DataHarness h;
  late Job job;

  setUp(() async {
    h = DataHarness(local(2026, 9, 30, 8, 2));
    job = await h.job();
  });

  ShiftDraft draft(
    int day,
    int fromH,
    int toH, {
    int breakMin = 0,
    int? jobId,
    bool paid = false,
    int tips = 0,
  }) => ShiftDraft(
    jobId: jobId ?? job.id,
    startUtc: local(2026, 9, day, fromH),
    endUtc: local(2026, 9, day, toH),
    breakMs: breakMin * msPerMinute,
    paid: paid,
    tipsCents: tips,
  );

  group('start', () {
    test('starts now with the job wage as snapshot', () async {
      final s = await h.shifts.start(job.id);
      expect(s.isRunning, isTrue);
      expect(s.startUtc, local(2026, 9, 30, 8, 2));
      expect(s.rawStartUtc, s.startUtc);
      expect(s.startOffsetMin, offsetMinutesAt(s.startUtc));
      expect(s.rateCentsPerHour, 1500);
      expect(s.source, ShiftSource.timer);
      expect(s.uuid, isNotEmpty);
      expect(await h.shifts.getRunning(), s);
    });

    test('earlier start ("Früher angefangen?")', () async {
      final s = await h.shifts.start(
        job.id,
        startUtc: local(2026, 9, 30, 7, 30),
      );
      expect(s.startUtc, local(2026, 9, 30, 7, 30));
    });

    test('rejects a start in the future', () {
      expect(
        () => h.shifts.start(job.id, startUtc: local(2026, 9, 30, 9)),
        throwsCode(ChronosErrorCode.startInFuture),
      );
    });

    test('rejects a second running shift', () async {
      await h.shifts.start(job.id);
      await expectLater(
        h.shifts.start(job.id),
        throwsCode(ChronosErrorCode.shiftAlreadyRunning),
      );
    });

    test('rejects unknown jobs', () {
      expect(
        () => h.shifts.start(999),
        throwsCode(ChronosErrorCode.jobNotFound),
      );
    });

    test('uses the wage valid on the start date', () async {
      await h.jobs.addRate(
        job.id,
        validFrom: LocalDate(2026, 9, 30),
        centsPerHour: 1600,
      );
      final s = await h.shifts.start(job.id, startUtc: local(2026, 9, 29, 22));
      expect(s.rateCentsPerHour, 1500);
    });
  });

  group('pause / resume / adjustStart', () {
    test('breaks accumulate over several pauses', () async {
      await h.shifts.start(job.id);
      h.clock.advance(const Duration(hours: 2));
      final paused = await h.shifts.pause();
      expect(paused.isPaused, isTrue);
      expect(paused.pausedAtUtc, h.clock.now);
      expect((await h.shifts.pause()).pausedAtUtc, paused.pausedAtUtc); // no-op
      h.clock.advance(const Duration(minutes: 20));
      final resumed = await h.shifts.resume();
      expect(resumed.isPaused, isFalse);
      expect(resumed.breakMs, 20 * msPerMinute);
      expect((await h.shifts.resume()).breakMs, 20 * msPerMinute); // no-op
      await h.shifts.pause();
      h.clock.advance(const Duration(minutes: 10));
      final again = await h.shifts.resume();
      expect(again.breakMs, 30 * msPerMinute);
    });

    test('pause time is clamped to the start and to now', () async {
      await h.shifts.start(job.id);
      final early = await h.shifts.pause(atUtc: local(2026, 9, 30, 6));
      expect(early.pausedAtUtc, local(2026, 9, 30, 8, 2));
      await h.shifts.resume();
      final late = await h.shifts.pause(atUtc: local(2026, 9, 30, 20));
      expect(late.pausedAtUtc, h.clock.now);
    });

    test('pause/resume/adjust need a running shift', () async {
      await expectLater(
        h.shifts.pause(),
        throwsCode(ChronosErrorCode.noRunningShift),
      );
      await expectLater(
        h.shifts.resume(),
        throwsCode(ChronosErrorCode.noRunningShift),
      );
      await expectLater(
        h.shifts.adjustStart(local(2026, 9, 30, 7)),
        throwsCode(ChronosErrorCode.noRunningShift),
      );
    });

    test(
      'adjustStart moves the start and re-snapshots on a new date',
      () async {
        await h.jobs.addRate(
          job.id,
          validFrom: LocalDate(2026, 9, 30),
          centsPerHour: 1600,
        );
        await h.shifts.start(job.id);
        final same = await h.shifts.adjustStart(local(2026, 9, 30, 7));
        expect(same.startUtc, local(2026, 9, 30, 7));
        expect(same.rawStartUtc, local(2026, 9, 30, 7));
        expect(same.rateCentsPerHour, 1600);
        final yesterday = await h.shifts.adjustStart(local(2026, 9, 29, 23));
        expect(yesterday.rateCentsPerHour, 1500);
      },
    );

    test(
      'adjustStart past finished pauses clamps the break to the new span',
      () async {
        // Started 06:00, paused 06:30 until now (08:02): 92 min of breaks.
        await h.shifts.start(job.id, startUtc: local(2026, 9, 30, 6));
        await h.shifts.pause(atUtc: local(2026, 9, 30, 6, 30));
        final resumed = await h.shifts.resume();
        expect(resumed.breakMs, 92 * msPerMinute);
        // The real start was 07:45: only 17 min remain, so the stored break
        // cannot be longer than that.
        final moved = await h.shifts.adjustStart(local(2026, 9, 30, 7, 45));
        expect(moved.breakMs, 17 * msPerMinute);
        // A start before the pauses keeps them untouched.
        final back = await h.shifts.adjustStart(local(2026, 9, 30, 6));
        expect(back.breakMs, 17 * msPerMinute);
        // Finishing works with a corrected break.
        h.clock.advance(const Duration(hours: 1));
        final done = await h.shifts.finish(breakMs: 0);
        expect(done.after.isDone, isTrue);
      },
    );

    test(
      'adjustStart rejects the future and a start after the pause',
      () async {
        await h.shifts.start(job.id, startUtc: local(2026, 9, 30, 7));
        await expectLater(
          h.shifts.adjustStart(local(2026, 9, 30, 9)),
          throwsCode(ChronosErrorCode.startInFuture),
        );
        await h.shifts.pause(atUtc: local(2026, 9, 30, 7, 30));
        await expectLater(
          h.shifts.adjustStart(local(2026, 9, 30, 7, 45)),
          throwsCode(ChronosErrorCode.invalidShift),
        );
      },
    );
  });

  group('finish', () {
    test('without rounding: amount cached, raw kept', () async {
      await h.shifts.start(job.id);
      h.clock.set(local(2026, 9, 30, 16, 17));
      final r = await h.shifts.finish(tipsCents: 500, note: '  Gala  ');
      expect(r.before.isRunning, isTrue);
      final s = r.after;
      expect(s.isDone, isTrue);
      expect(s.startUtc, local(2026, 9, 30, 8, 2));
      expect(s.endUtc, local(2026, 9, 30, 16, 17));
      expect(s.rawEndUtc, s.endUtc);
      expect(s.endOffsetMin, offsetMinutesAt(s.endUtc!));
      expect(s.amountCents, 12375);
      expect(s.tipsCents, 500);
      expect(s.note, 'Gala');
      expect(await h.shifts.getRunning(), isNull);
      expect(r, FinishResult(before: r.before, after: s));
      expect(r.hashCode, FinishResult(before: r.before, after: s).hashCode);
      expect(r.toString(), contains('12375'));
    });

    test('applies the job rounding and keeps raw times', () async {
      await h.jobs.updateJob(job.copyWith(rounding: RoundingRule.nearest15));
      h.clock.set(local(2026, 9, 30, 8, 7, 30));
      await h.shifts.start(job.id);
      h.clock.set(local(2026, 9, 30, 16, 7));
      final s = (await h.shifts.finish(breakMs: 0)).after;
      expect(s.rawStartUtc, local(2026, 9, 30, 8, 7, 30));
      expect(s.startUtc, local(2026, 9, 30, 8, 15));
      expect(s.rawEndUtc, local(2026, 9, 30, 16, 7));
      expect(s.endUtc, local(2026, 9, 30, 16, 0));
      expect(s.amountCents, 11625);
    });

    test('a pause in progress counts as break', () async {
      await h.shifts.start(job.id);
      h.clock.set(local(2026, 9, 30, 12));
      await h.shifts.pause();
      h.clock.set(local(2026, 9, 30, 12, 30));
      final s = (await h.shifts.finish()).after;
      expect(s.breakMs, 30 * msPerMinute);
      expect(s.pausedAtUtc, isNull);
      expect(s.workedMs, 3 * msPerHour + 58 * msPerMinute);
    });

    test('explicit end and break', () async {
      await h.shifts.start(job.id);
      h.clock.set(local(2026, 9, 30, 18));
      final s = (await h.shifts.finish(
        endUtc: local(2026, 9, 30, 16, 2),
        breakMs: 30 * msPerMinute,
      )).after;
      expect(s.endUtc, local(2026, 9, 30, 16, 2));
      expect(s.amountCents, 11250);
    });

    test('errors', () async {
      await expectLater(
        h.shifts.finish(),
        throwsCode(ChronosErrorCode.noRunningShift),
      );
      await h.shifts.start(job.id);
      expect(
        () => h.shifts.finish(tipsCents: -1),
        throwsCode(ChronosErrorCode.invalidAmount),
      );
      await expectLater(
        h.shifts.finish(endUtc: local(2026, 9, 30, 7)),
        throwsA(
          isA<ChronosException>()
              .having((e) => e.code, 'code', ChronosErrorCode.invalidShift)
              .having((e) => e.detail, 'detail', [ShiftError.endNotAfterStart]),
        ),
      );
      expect(await h.shifts.getRunning(), isNotNull); // nothing changed
    });

    test('Berlin: night shift over the autumn switch is paid 9 h', () async {
      h.clock.set(local(2026, 10, 24, 22));
      await h.shifts.start(job.id);
      h.clock.set(local(2026, 10, 25, 6));
      final s = (await h.shifts.finish()).after;
      expect(s.workedMs, 9 * msPerHour);
      expect(s.amountCents, 13500);
      expect(s.startOffsetMin, 120);
      expect(s.endOffsetMin, 60);
      expect(s.localStartDate, LocalDate(2026, 10, 24));
    }, skip: skipUnlessBerlin);
  });

  group('revertFinish (undo) and discard', () {
    test('undo restores the exact running state', () async {
      await h.shifts.start(job.id);
      h.clock.set(local(2026, 9, 30, 12));
      await h.shifts.pause();
      h.clock.set(local(2026, 9, 30, 12, 30));
      final r = await h.shifts.finish(tipsCents: 100);
      final back = await h.shifts.revertFinish(r.after.id, restore: r.before);
      expect(back.isRunning, isTrue);
      expect(back.endUtc, isNull);
      expect(back.amountCents, isNull);
      expect(back.pausedAtUtc, local(2026, 9, 30, 12));
      expect(back.breakMs, 0);
      expect(back.tipsCents, 0);
      expect(await h.shifts.getRunning(), isNotNull);
    });

    test('undo without snapshot restores the raw start', () async {
      await h.jobs.updateJob(job.copyWith(rounding: RoundingRule.nearest15));
      await h.shifts.start(job.id);
      h.clock.set(local(2026, 9, 30, 10));
      final r = await h.shifts.finish(tipsCents: 100);
      expect(r.after.startUtc, local(2026, 9, 30, 8));
      final back = await h.shifts.revertFinish(r.after.id);
      expect(back.startUtc, local(2026, 9, 30, 8, 2));
      expect(back.tipsCents, 0);
      // Already running: returned as is.
      expect(await h.shifts.revertFinish(back.id), back);
    });

    test('undo fails if another shift runs or the shift is gone', () async {
      await h.shifts.start(job.id);
      h.clock.advance(const Duration(minutes: 1));
      final r = await h.shifts.finish();
      await h.shifts.start(job.id);
      await expectLater(
        h.shifts.revertFinish(r.after.id),
        throwsCode(ChronosErrorCode.shiftAlreadyRunning),
      );
      await expectLater(
        h.shifts.revertFinish(999),
        throwsCode(ChronosErrorCode.shiftNotFound),
      );
    });

    test('discardRunning soft-deletes and can be undone', () async {
      await h.shifts.start(job.id);
      final discarded = await h.shifts.discardRunning();
      expect(discarded.isDeleted, isTrue);
      expect(await h.shifts.getRunning(), isNull);
      await h.shifts.undoDelete([discarded.id]);
      expect((await h.shifts.getRunning())!.id, discarded.id);
      await expectLater(
        h.shifts.discardRunning().then((_) => h.shifts.discardRunning()),
        throwsCode(ChronosErrorCode.noRunningShift),
      );
    });

    test('undoing a discard fails while another shift runs', () async {
      await h.shifts.start(job.id);
      final discarded = await h.shifts.discardRunning();
      await h.shifts.start(job.id);
      await expectLater(
        h.shifts.undoDelete([discarded.id]),
        throwsCode(ChronosErrorCode.shiftAlreadyRunning),
      );
    });
  });

  group('insertManual / update / duplicate', () {
    test(
      'insertManual uses the job wage on the date and never rounds',
      () async {
        await h.jobs.updateJob(job.copyWith(rounding: RoundingRule.nearest15));
        await h.jobs.addRate(
          job.id,
          validFrom: LocalDate(2026, 9, 15),
          centsPerHour: 1600,
        );
        final s = await h.shifts.insertManual(
          ShiftDraft(
            jobId: job.id,
            startUtc: local(2026, 9, 20, 8, 7),
            endUtc: local(2026, 9, 20, 16, 7),
            breakMs: 30 * msPerMinute,
            tipsCents: 250,
            note: ' ',
          ),
        );
        expect(s.source, ShiftSource.manual);
        expect(s.startUtc, local(2026, 9, 20, 8, 7));
        expect(s.rateCentsPerHour, 1600);
        expect(s.amountCents, 12000);
        expect(s.tipsCents, 250);
        expect(s.note, isNull);
        expect(s.isPaid, isFalse);
        final earlier = await h.shifts.insertManual(draft(1, 8, 9));
        expect(earlier.rateCentsPerHour, 1500);
      },
    );

    test('insertManual: explicit wage, paid, errors', () async {
      final s = await h.shifts.insertManual(
        draft(20, 8, 16, paid: true).copyWith(rateCentsPerHour: 2000),
      );
      expect(s.rateCentsPerHour, 2000);
      expect(s.paidAtUtc, h.clock.now);
      expect(
        () => h.shifts.insertManual(draft(20, 9, 8)),
        throwsCode(ChronosErrorCode.invalidShift),
      );
      expect(
        () => h.shifts.insertManual(draft(20, 8, 9, breakMin: 60)),
        throwsCode(ChronosErrorCode.invalidShift),
      );
      await expectLater(
        h.shifts.insertManual(draft(20, 8, 9, jobId: 999)),
        throwsCode(ChronosErrorCode.jobNotFound),
      );
    });

    test('update keeps the stored wage and never creates a shift', () async {
      final s = await h.shifts.insertManual(draft(20, 8, 16));
      await h.jobs.addRate(
        job.id,
        validFrom: LocalDate(2026, 1, 1),
        centsPerHour: 2000,
      );
      final updated = await h.shifts.update(
        s.id,
        ShiftDraft.fromShift(s).copyWith(endUtc: local(2026, 9, 20, 17)),
      );
      expect(updated.id, s.id);
      expect(updated.rateCentsPerHour, 1500);
      expect(updated.amountCents, 13500);
      expect(updated.rawEndUtc, local(2026, 9, 20, 17));
      expect(updated.rawStartUtc, s.rawStartUtc);
      expect(await h.shifts.getDone(), hasLength(1));
    });

    test('update re-prices when the job changes', () async {
      final other = await h.job(name: 'Bar', centsPerHour: 2000);
      final s = await h.shifts.insertManual(draft(20, 8, 16));
      final moved = await h.shifts.update(
        s.id,
        ShiftDraft.fromShift(s).copyWith(jobId: other.id),
      );
      expect(moved.jobId, other.id);
      expect(moved.rateCentsPerHour, 2000);
      expect(moved.amountCents, 16000);
      final explicit = await h.shifts.update(
        s.id,
        ShiftDraft.fromShift(moved).copyWith(rateCentsPerHour: 1000),
      );
      expect(explicit.rateCentsPerHour, 1000);
    });

    test('update toggles paid and clears the payout link', () async {
      final s = await h.shifts.insertManual(draft(20, 8, 16));
      final paid = await h.shifts.update(
        s.id,
        ShiftDraft.fromShift(s).copyWith(paid: true),
      );
      expect(paid.paidAtUtc, h.clock.now);
      h.clock.advance(const Duration(hours: 1));
      final stillPaid = await h.shifts.update(
        s.id,
        ShiftDraft.fromShift(paid).copyWith(tipsCents: 5),
      );
      expect(stillPaid.paidAtUtc, paid.paidAtUtc);
      final open = await h.shifts.update(
        s.id,
        ShiftDraft.fromShift(paid).copyWith(paid: false),
      );
      expect(open.paidAtUtc, isNull);
      expect(open.payoutId, isNull);
    });

    test('update errors', () async {
      final s = await h.shifts.insertManual(draft(20, 8, 16));
      expect(
        () => h.shifts.update(s.id, draft(20, 9, 8)),
        throwsCode(ChronosErrorCode.invalidShift),
      );
      await expectLater(
        h.shifts.update(999, draft(20, 8, 9)),
        throwsCode(ChronosErrorCode.shiftNotFound),
      );
      await expectLater(
        h.shifts.update(s.id, draft(20, 8, 9, jobId: 999)),
        throwsCode(ChronosErrorCode.jobNotFound),
      );
      final running = await h.shifts.start(job.id);
      await expectLater(
        h.shifts.update(running.id, draft(20, 8, 9)),
        throwsCode(ChronosErrorCode.shiftIsRunning),
      );
      await h.shifts.softDelete([s.id]);
      await expectLater(
        h.shifts.update(s.id, draft(20, 8, 9)),
        throwsCode(ChronosErrorCode.shiftNotFound),
      );
    });

    test('duplicate on the same date or another date', () async {
      final s = await h.shifts.insertManual(
        draft(20, 8, 16, paid: true, tips: 300).copyWith(note: 'Gala'),
      );
      final copy = await h.shifts.duplicate(s.id);
      expect(copy.id, isNot(s.id));
      expect(copy.uuid, isNot(s.uuid));
      expect(copy.startUtc, s.startUtc);
      expect(copy.isPaid, isFalse);
      expect(copy.tipsCents, 0);
      expect(copy.note, 'Gala');
      expect(copy.source, ShiftSource.manual);

      await h.jobs.addRate(
        job.id,
        validFrom: LocalDate(2026, 9, 25),
        centsPerHour: 1600,
      );
      final moved = await h.shifts.duplicate(
        s.id,
        onDate: LocalDate(2026, 9, 28),
      );
      expect(moved.startUtc, local(2026, 9, 28, 8));
      expect(moved.endUtc, local(2026, 9, 28, 16));
      expect(moved.rateCentsPerHour, 1600);
    });

    test('duplicate keeps overnight shifts overnight', () async {
      final s = await h.shifts.insertManual(
        ShiftDraft(
          jobId: job.id,
          startUtc: local(2026, 9, 20, 22),
          endUtc: local(2026, 9, 21, 6),
        ),
      );
      final moved = await h.shifts.duplicate(
        s.id,
        onDate: LocalDate(2026, 9, 25),
      );
      expect(moved.startUtc, local(2026, 9, 25, 22));
      expect(moved.endUtc, local(2026, 9, 26, 6));
    });

    test('duplicate errors', () async {
      await expectLater(
        h.shifts.duplicate(999),
        throwsCode(ChronosErrorCode.shiftNotFound),
      );
      final running = await h.shifts.start(job.id);
      await expectLater(
        h.shifts.duplicate(running.id),
        throwsCode(ChronosErrorCode.shiftIsRunning),
      );
    });
  });

  group('delete and paid', () {
    test('softDelete hides, undoDelete restores, purge removes', () async {
      final a = await h.shifts.insertManual(draft(20, 8, 16));
      final b = await h.shifts.insertManual(draft(21, 8, 16));
      final deleted = await h.shifts.softDelete([a.id, a.id, 999]);
      expect(deleted.single.id, a.id);
      expect(deleted.single.isDeleted, isTrue);
      expect(await h.shifts.softDelete([a.id]), isEmpty);
      expect((await h.shifts.getDone()).map((s) => s.id), [b.id]);
      await h.shifts.undoDelete([a.id]);
      expect(await h.shifts.getDone(), hasLength(2));
      await h.shifts.undoDelete([a.id]); // not deleted: no-op

      await h.shifts.softDelete([a.id]);
      h.clock.advance(const Duration(minutes: 5));
      expect(await h.shifts.purgeDeleted(before: local(2026, 9, 30, 8)), 0);
      expect(await h.shifts.purgeDeleted(before: h.clock.now), 1);
      expect(await h.shifts.getById(a.id), isNull);
      expect(await h.shifts.getById(b.id), isNotNull);
    });

    test('setPaid returns previous states for undo', () async {
      final a = await h.shifts.insertManual(draft(20, 8, 16));
      final b = await h.shifts.insertManual(draft(21, 8, 16, paid: true));
      final running = await h.shifts.start(job.id);
      final prev = await h.shifts.setPaid([a.id, b.id, running.id], true);
      expect(prev, hasLength(2));
      expect((await h.shifts.getById(a.id))!.isPaid, isTrue);
      expect((await h.shifts.getById(b.id))!.paidAtUtc, b.paidAtUtc);
      expect((await h.shifts.getById(running.id))!.isPaid, isFalse);
      await h.shifts.restorePaidStates(prev);
      expect((await h.shifts.getById(a.id))!.isPaid, isFalse);
      expect((await h.shifts.getById(b.id))!.paidAtUtc, b.paidAtUtc);
      await h.shifts.setPaid([b.id], false);
      expect((await h.shifts.getById(b.id))!.isPaid, isFalse);
      expect(prev.first, PaidState(shiftId: a.id));
      expect(prev.first.hashCode, PaidState(shiftId: a.id).hashCode);
      expect(prev.first.toString(), contains('PaidState'));
    });
  });

  group('queries', () {
    test('watchDone filters and sorts newest first', () async {
      final a = await h.shifts.insertManual(draft(20, 8, 16));
      final b = await h.shifts.insertManual(draft(22, 8, 16, paid: true));
      final c = await h.shifts.insertManual(draft(21, 8, 16));
      await h.shifts.start(job.id);
      expect((await h.shifts.watchDone().first).map((s) => s.id), [
        b.id,
        c.id,
        a.id,
      ]);
      expect(
        (await h.shifts.watchDone(filter: ShiftFilter.open).first).map(
          (s) => s.id,
        ),
        [c.id, a.id],
      );
      expect(
        (await h.shifts.watchDone(filter: ShiftFilter.paid).first).map(
          (s) => s.id,
        ),
        [b.id],
      );
      expect(await h.shifts.getDone(jobId: 999), isEmpty);
      expect(await h.shifts.countActive(), 4);
    });

    test('streams update after changes', () async {
      final stream = h.shifts.watchDone();
      expect(await stream.first, isEmpty);
      final a = await h.shifts.insertManual(draft(20, 8, 16));
      expect((await stream.first).single.id, a.id);
      await h.shifts.softDelete([a.id]);
      expect(await stream.first, isEmpty);
    });

    test('watchRunning follows the timer', () async {
      final emitted = <bool>[];
      final sub = h.shifts.watchRunning().listen((s) => emitted.add(s != null));
      addTearDown(sub.cancel);
      await pumpEventQueue();
      await h.shifts.start(job.id);
      await pumpEventQueue();
      h.clock.advance(const Duration(minutes: 1));
      await h.shifts.finish();
      await pumpEventQueue();
      expect(emitted, [false, true, false]);
    });

    test('watchRange uses local start dates', () async {
      final late = await h.shifts.insertManual(
        ShiftDraft(
          jobId: job.id,
          startUtc: local(2026, 9, 29, 23, 30),
          endUtc: local(2026, 9, 30, 2),
        ),
      );
      final today = await h.shifts.insertManual(
        ShiftDraft(
          jobId: job.id,
          startUtc: local(2026, 9, 30, 0),
          endUtc: local(2026, 9, 30, 1),
        ),
      );
      final range = LocalDateRange.day(LocalDate(2026, 9, 30));
      expect((await h.shifts.watchRange(range).first).map((s) => s.id), [
        today.id,
      ]);
      expect(
        (await h.shifts.getRange(LocalDateRange.day(LocalDate(2026, 9, 29))))
            .map((s) => s.id),
        [late.id],
      );
      expect(await h.shifts.getRange(range, jobId: 999), isEmpty);
    });

    test('byId, lastDone', () async {
      expect(await h.shifts.lastDone(), isNull);
      final a = await h.shifts.insertManual(draft(20, 8, 16));
      final b = await h.shifts.insertManual(draft(22, 8, 16));
      expect((await h.shifts.lastDone())!.id, b.id);
      expect((await h.shifts.watchLastDone(jobId: job.id).first)!.id, b.id);
      expect((await h.shifts.watchById(a.id).first)!.id, a.id);
      expect(await h.shifts.getById(999), isNull);
    });

    test('findOverlaps includes a running shift until now', () async {
      final a = await h.shifts.insertManual(draft(20, 8, 16));
      await h.shifts.insertManual(draft(20, 16, 18));
      final found = await h.shifts.findOverlaps(
        local(2026, 9, 20, 15),
        local(2026, 9, 20, 17),
      );
      expect(found, hasLength(2));
      expect(
        await h.shifts.findOverlaps(
          local(2026, 9, 20, 15),
          local(2026, 9, 20, 16),
          excludeId: a.id,
        ),
        isEmpty,
      );
      final running = await h.shifts.start(
        job.id,
        startUtc: local(2026, 9, 30, 7),
      );
      h.clock.set(local(2026, 9, 30, 12));
      final withRunning = await h.shifts.findOverlaps(
        local(2026, 9, 30, 11),
        local(2026, 9, 30, 13),
      );
      expect(withRunning.single.id, running.id);
    });

    test('Berlin: watchRange on the autumn switch day covers 25 h', () async {
      final s = await h.shifts.insertManual(
        ShiftDraft(
          jobId: job.id,
          startUtc: DateTime.utc(2026, 10, 25, 22, 30), // 23:30 CET
          endUtc: DateTime.utc(2026, 10, 25, 23),
        ),
      );
      final range = LocalDateRange.day(LocalDate(2026, 10, 25));
      expect((await h.shifts.getRange(range)).single.id, s.id);
    }, skip: skipUnlessBerlin);
  });
}
