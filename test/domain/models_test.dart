import 'package:chronos/core/local_date.dart';
import 'package:chronos/core/time.dart';
import 'package:chronos/domain/app_settings.dart';
import 'package:chronos/domain/errors.dart';
import 'package:chronos/domain/job.dart';
import 'package:chronos/domain/shift.dart';
import 'package:chronos/domain/shift_draft.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/shifts.dart';
import '../fixtures/tz.dart';

void main() {
  group('Job', () {
    const job = Job(id: 1, uuid: 'j1', name: 'Catering', colorArgb: 1);

    test('defaults', () {
      expect(job.rounding, RoundingRule.none);
      expect(job.archived, isFalse);
      expect(job.sortOrder, 0);
    });

    test('copyWith / equality', () {
      final c = job.copyWith(name: 'Bar', rounding: RoundingRule.nearest5);
      expect(c.name, 'Bar');
      expect(c.rounding, RoundingRule.nearest5);
      expect(c.uuid, 'j1');
      expect(job.copyWith(), job);
      expect(job.copyWith().hashCode, job.hashCode);
      expect(c, isNot(job));
      expect(job.copyWith(archived: true).toString(), contains('archived'));
    });
  });

  group('Shift', () {
    final shift = doneShift(
      start: local(2026, 9, 30, 22),
      end: local(2026, 10, 1, 6),
      breakMs: 30 * msPerMinute,
      tips: 500,
      note: 'Gala',
    );

    test('derived values', () {
      expect(shift.isDone, isTrue);
      expect(shift.isRunning, isFalse);
      expect(shift.isPaused, isFalse);
      expect(shift.isPaid, isFalse);
      expect(shift.isDeleted, isFalse);
      expect(shift.isOpen, isTrue);
      expect(shift.localStartDate, LocalDate(2026, 9, 30));
      expect(shift.localEndDate, LocalDate(2026, 10, 1));
      expect(shift.endsOnLaterDay, isTrue);
      expect(shift.durationMs, 8 * msPerHour);
      expect(shift.workedMs, 7 * msPerHour + 30 * msPerMinute);
      expect(shift.earnedCents, 11250);
    });

    test('earnedCents falls back to computing when not cached', () {
      final c = shift.copyWith(amountCents: null);
      expect(c.amountCents, isNull);
      expect(c.earnedCents, 11250);
    });

    test('running shift has no end and earns 0 without a clock', () {
      final r = runningShift(start: local(2026, 9, 30, 8));
      expect(r.isRunning, isTrue);
      expect(r.localEndDate, isNull);
      expect(r.endsOnLaterDay, isFalse);
      expect(r.durationMs, isNull);
      expect(r.workedMs, 0);
      expect(r.earnedCents, 0);
      expect(r.isOpen, isFalse);
      final paused = r.copyWith(pausedAtUtc: local(2026, 9, 30, 9));
      expect(paused.isPaused, isTrue);
      expect(paused.copyWith(pausedAtUtc: null).isPaused, isFalse);
    });

    test('paid / deleted are not open', () {
      expect(shift.copyWith(paidAtUtc: DateTime.utc(2026)).isOpen, isFalse);
      expect(shift.copyWith(deletedAt: DateTime.utc(2026)).isOpen, isFalse);
    });

    test('negative worked time is clamped', () {
      final c = shift.copyWith(breakMs: 20 * msPerHour, amountCents: null);
      expect(c.workedMs, 0);
      expect(c.earnedCents, 0);
    });

    test('copyWith keeps or clears every nullable field', () {
      expect(shift.copyWith(), shift);
      expect(shift.copyWith().hashCode, shift.hashCode);
      final cleared = shift.copyWith(
        endUtc: null,
        rawEndUtc: null,
        endOffsetMin: null,
        note: null,
        paidAtUtc: null,
        payoutId: null,
        amountCents: null,
        legacyId: null,
        deletedAt: null,
        status: ShiftStatus.running,
      );
      expect(cleared.endUtc, isNull);
      expect(cleared.rawEndUtc, isNull);
      expect(cleared.endOffsetMin, isNull);
      expect(cleared.note, isNull);
      expect(cleared.isRunning, isTrue);
      final set = shift.copyWith(
        payoutId: 3,
        legacyId: '1716712345678',
        source: ShiftSource.legacy,
        tipsCents: 1,
        rateCentsPerHour: 2,
        jobId: 4,
        id: 5,
        uuid: 'u',
        startOffsetMin: 60,
        createdAt: DateTime.utc(2020),
        updatedAt: DateTime.utc(2021),
        startUtc: DateTime.utc(2026),
        rawStartUtc: DateTime.utc(2026),
      );
      expect(set.payoutId, 3);
      expect(set.legacyId, '1716712345678');
      expect(set.source, ShiftSource.legacy);
      expect(set, isNot(shift));
      expect(set.toString(), contains('Shift(5'));
    });
  });

  group('ShiftDraft', () {
    test('fromLocal derives "ends next day" when end ≤ start', () {
      final d = ShiftDraft.fromLocal(
        jobId: 1,
        date: LocalDate(2026, 9, 30),
        startHour: 22,
        startMinute: 0,
        endHour: 6,
        endMinute: 0,
      );
      expect(d.startUtc, local(2026, 9, 30, 22));
      expect(d.endUtc, local(2026, 10, 1, 6));
      expect(d.durationMs, 8 * msPerHour);
      expect(d.localStartDate, LocalDate(2026, 9, 30));
    });

    test('end equal to start means the next day (24 h) unless overridden', () {
      final auto = ShiftDraft.fromLocal(
        jobId: 1,
        date: LocalDate(2026, 9, 30),
        startHour: 8,
        startMinute: 0,
        endHour: 8,
        endMinute: 0,
      );
      expect(auto.durationMs, 24 * msPerHour);
      final same = ShiftDraft.fromLocal(
        jobId: 1,
        date: LocalDate(2026, 9, 30),
        startHour: 8,
        startMinute: 0,
        endHour: 8,
        endMinute: 0,
        endsNextDay: false,
      );
      expect(same.durationMs, 0);
    });

    test('endsNextDayFor', () {
      expect(
        ShiftDraft.endsNextDayFor(
          startHour: 8,
          startMinute: 0,
          endHour: 16,
          endMinute: 15,
        ),
        isFalse,
      );
      expect(
        ShiftDraft.endsNextDayFor(
          startHour: 22,
          startMinute: 0,
          endHour: 6,
          endMinute: 0,
        ),
        isTrue,
      );
    });

    group('fromLocalEdit', () {
      ShiftDraft edit(
        Shift original, {
        LocalDate? date,
        ({int h, int m})? start,
        ({int h, int m})? end,
        bool? endsNextDay,
        int? breakMinutes,
      }) {
        final s = original.startUtc.toLocal();
        final e = original.endUtc!.toLocal();
        return ShiftDraft.fromLocalEdit(
          original: original,
          jobId: original.jobId,
          date: date ?? original.localStartDate,
          startHour: start?.h ?? s.hour,
          startMinute: start?.m ?? s.minute,
          endHour: end?.h ?? e.hour,
          endMinute: end?.m ?? e.minute,
          endsNextDay: endsNextDay ?? original.endsOnLaterDay,
          breakMinutes:
              breakMinutes ?? ShiftDraft.roundedBreakMinutes(original.breakMs),
        );
      }

      test('unchanged fields keep a shift over two midnights (D11)', () {
        final s = doneShift(
          start: local(2026, 9, 28, 20),
          end: local(2026, 9, 30, 2),
        );
        final d = edit(s);
        expect(d.startUtc, s.startUtc);
        expect(d.endUtc, s.endUtc);
        expect(d.durationMs, 30 * msPerHour);
        // A new start keeps the stored end.
        final earlier = edit(s, start: (h: 19, m: 0));
        expect(earlier.startUtc, local(2026, 9, 28, 19));
        expect(earlier.endUtc, s.endUtc);
        // A new end is taken from the fields.
        final changed = edit(s, end: (h: 3, m: 0));
        expect(changed.endUtc, local(2026, 9, 29, 3));
      });

      test('unchanged fields keep seconds and the exact break', () {
        final s = doneShift(
          start: local(2026, 9, 28, 8, 0, 40),
          end: local(2026, 9, 28, 16, 15, 10),
          breakMs: 30 * msPerMinute + 20 * msPerSecond,
        );
        final d = edit(s);
        expect(d.startUtc, s.startUtc);
        expect(d.endUtc, s.endUtc);
        expect(d.breakMs, s.breakMs);
        expect(edit(s, breakMinutes: 31).breakMs, 31 * msPerMinute);
        // Another date rebuilds both instants from the fields.
        final moved = edit(s, date: LocalDate(2026, 9, 29));
        expect(moved.startUtc, local(2026, 9, 29, 8));
        expect(moved.endUtc, local(2026, 9, 29, 16, 15));
      });

      test('an end in the repeated hour of the DST change stays put', () {
        // 25 Oct 2026: 02:30 CET (the second 02:30) = 01:30 UTC.
        final s = doneShift(
          start: local(2026, 10, 24, 22),
          end: DateTime.utc(2026, 10, 25, 1, 30),
        );
        final d = edit(s);
        expect(d.endUtc, DateTime.utc(2026, 10, 25, 1, 30));
        expect(d.durationMs, s.durationMs);
      }, skip: skipUnlessBerlin);
    });

    test('fromShift / worked / copyWith / equality', () {
      final s = doneShift(
        start: local(2026, 9, 30, 8),
        end: local(2026, 9, 30, 16),
        breakMs: msPerHour,
        paid: true,
        tips: 100,
        note: 'n',
      );
      final d = ShiftDraft.fromShift(s);
      expect(d.paid, isTrue);
      expect(d.workedMs, 7 * msPerHour);
      expect(d.rateCentsPerHour, 1500);
      expect(d.note, 'n');
      expect(d.copyWith(note: null).note, isNull);
      expect(d.copyWith(rateCentsPerHour: null).rateCentsPerHour, isNull);
      expect(d.copyWith(), d);
      expect(d.copyWith().hashCode, d.hashCode);
      expect(d.copyWith(breakMs: 9 * msPerHour).workedMs, 0);
      expect(d.toString(), contains('ShiftDraft'));
    });
  });

  group('AppSettings', () {
    test('defaults', () {
      const s = AppSettings.defaults;
      expect(s.language, AppLanguage.system);
      expect(s.themeMode, AppThemeMode.system);
      expect(s.monthlyGoalCents, isNull);
      expect(s.monthlyGoalType, MonthlyGoalType.goal);
      expect(s.reminderHours, 10);
      expect(s.reminderEnabled, isTrue);
      expect(s.onboardingDone, isFalse);
      expect(s.notificationPrimerShown, isFalse);
      expect(AppSettings.reminderHourOptions, [0, 6, 8, 10, 12]);
    });

    test('copyWith / equality', () {
      final s = AppSettings.defaults.copyWith(
        language: AppLanguage.de,
        monthlyGoalCents: 60300,
        monthlyGoalType: MonthlyGoalType.limit,
        reminderHours: 0,
      );
      expect(s.reminderEnabled, isFalse);
      expect(s.copyWith(monthlyGoalCents: null).monthlyGoalCents, isNull);
      expect(s.copyWith(), s);
      expect(s.copyWith().hashCode, s.hashCode);
      expect(s, isNot(AppSettings.defaults));
      expect(s.toString(), contains('limit'));
    });
  });

  test('ChronosException', () {
    const e = ChronosException(ChronosErrorCode.noRunningShift);
    expect(e.code, ChronosErrorCode.noRunningShift);
    expect(e.toString(), contains('noRunningShift'));
    expect(
      const ChronosException(
        ChronosErrorCode.invalidAmount,
        detail: -1,
      ).toString(),
      contains('-1'),
    );
  });
}
