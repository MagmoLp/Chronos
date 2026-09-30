import 'package:chronos/core/local_date.dart';
import 'package:chronos/core/time.dart';
import 'package:chronos/domain/shift_draft.dart';
import 'package:chronos/domain/validation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/shifts.dart';

void main() {
  final now = local(2026, 9, 30, 18);

  group('errors', () {
    test('end equal to start', () {
      final v = validateShift(
        startUtc: local(2026, 9, 30, 8),
        endUtc: local(2026, 9, 30, 8),
        now: now,
      );
      expect(v.errors, [ShiftError.endNotAfterStart]);
      expect(v.isValid, isFalse);
    });

    test('end before start', () {
      final v = validateShift(
        startUtc: local(2026, 9, 30, 9),
        endUtc: local(2026, 9, 30, 8),
        now: now,
      );
      expect(v.errors, contains(ShiftError.endNotAfterStart));
    });

    test('break as long as the shift', () {
      final v = validateShift(
        startUtc: local(2026, 9, 30, 8),
        endUtc: local(2026, 9, 30, 9),
        breakMs: msPerHour,
        now: now,
      );
      expect(v.errors, [ShiftError.breakNotShorterThanDuration]);
    });

    test('break longer than the shift', () {
      final v = validateShift(
        startUtc: local(2026, 9, 30, 8),
        endUtc: local(2026, 9, 30, 9),
        breakMs: 2 * msPerHour,
        now: now,
      );
      expect(v.errors, [ShiftError.breakNotShorterThanDuration]);
    });

    test('break shorter than the shift is fine', () {
      final v = validateShift(
        startUtc: local(2026, 9, 30, 8),
        endUtc: local(2026, 9, 30, 9),
        breakMs: msPerHour - 1,
        now: now,
      );
      expect(v.isClean, isTrue);
      expect(v, ShiftValidation.ok);
    });

    test('negative break and tips', () {
      final v = validateShift(
        startUtc: local(2026, 9, 30, 8),
        endUtc: local(2026, 9, 30, 9),
        breakMs: -1,
        tipsCents: -1,
        now: now,
      );
      expect(v.errors, [ShiftError.negativeBreak, ShiftError.negativeTips]);
    });

    test('shiftErrors allows a zero-length shift without break', () {
      expect(
        shiftErrors(
          startUtc: local(2026, 9, 30, 8),
          endUtc: local(2026, 9, 30, 8),
        ),
        [ShiftError.endNotAfterStart],
      );
      expect(
        shiftErrors(
          startUtc: local(2026, 9, 30, 8),
          endUtc: local(2026, 9, 30, 8, 15),
          breakMs: 0,
        ),
        isEmpty,
      );
    });
  });

  group('warnings', () {
    test('longer than 16 h (strictly)', () {
      final exactly16 = validateShift(
        startUtc: local(2026, 9, 29, 8),
        endUtc: local(2026, 9, 30, 0),
        now: now,
      );
      expect(exactly16.hasWarnings, isFalse);
      final longer = validateShift(
        startUtc: local(2026, 9, 29, 8),
        endUtc: local(2026, 9, 30, 0, 1),
        now: now,
      );
      expect(longer.warnings, [
        const LongerThan16h(16 * msPerHour + msPerMinute),
      ]);
      expect(longer.isValid, isTrue);
      expect(longer.isClean, isFalse);
    });

    test('starts in the future', () {
      final v = validateShift(
        startUtc: local(2026, 9, 30, 19),
        endUtc: local(2026, 9, 30, 23),
        now: now,
      );
      expect(v.warnings, [const StartsInFuture()]);
    });

    test('overlap with another shift is reported with that shift', () {
      final other = doneShift(
        id: 7,
        start: local(2026, 9, 30, 12),
        end: local(2026, 9, 30, 14),
      );
      final v = validateShift(
        startUtc: local(2026, 9, 30, 13),
        endUtc: local(2026, 9, 30, 15),
        now: now,
        others: [other],
      );
      expect(v.warnings, [OverlapsWith(other)]);
      expect(v.overlaps.single.id, 7);
    });

    test('touching shifts do not overlap', () {
      final other = doneShift(
        id: 7,
        start: local(2026, 9, 30, 12),
        end: local(2026, 9, 30, 14),
      );
      final v = validateShift(
        startUtc: local(2026, 9, 30, 14),
        endUtc: local(2026, 9, 30, 15),
        now: now,
        others: [other],
      );
      expect(v.isClean, isTrue);
    });

    test('ignores deleted shifts and the edited shift itself', () {
      final deleted = doneShift(
        id: 1,
        start: local(2026, 9, 30, 12),
        end: local(2026, 9, 30, 14),
        deletedAt: now,
      );
      final self = doneShift(
        id: 2,
        start: local(2026, 9, 30, 12),
        end: local(2026, 9, 30, 14),
      );
      final v = validateShift(
        startUtc: local(2026, 9, 30, 12),
        endUtc: local(2026, 9, 30, 14),
        now: now,
        others: [deleted, self],
        ignoreShiftId: 2,
      );
      expect(v.isClean, isTrue);
    });

    test('a running shift lasts until now', () {
      final running = runningShift(id: 5, start: local(2026, 9, 30, 16));
      final overlapping = validateShift(
        startUtc: local(2026, 9, 30, 17),
        endUtc: local(2026, 9, 30, 17, 30),
        now: now,
        others: [running],
      );
      expect(overlapping.overlaps.single.id, 5);
      final after = validateShift(
        startUtc: local(2026, 9, 30, 18),
        endUtc: local(2026, 9, 30, 19),
        now: now,
        others: [running],
      );
      expect(after.overlaps, isEmpty);
    });

    test('no overlap check for invalid ranges', () {
      final other = doneShift(
        id: 7,
        start: local(2026, 9, 30, 12),
        end: local(2026, 9, 30, 14),
      );
      final v = validateShift(
        startUtc: local(2026, 9, 30, 13),
        endUtc: local(2026, 9, 30, 13),
        now: now,
        others: [other],
      );
      expect(v.overlaps, isEmpty);
      expect(v.errors, [ShiftError.endNotAfterStart]);
    });
  });

  test('findOverlapping sorts by start', () {
    final a = doneShift(
      id: 1,
      start: local(2026, 9, 30, 14),
      end: local(2026, 9, 30, 16),
    );
    final b = doneShift(
      id: 2,
      start: local(2026, 9, 30, 8),
      end: local(2026, 9, 30, 12),
    );
    final found = findOverlapping(
      local(2026, 9, 30, 10),
      local(2026, 9, 30, 15),
      [a, b],
      now: now,
    );
    expect(found.map((s) => s.id), [2, 1]);
  });

  test('intervalsOverlap', () {
    final t = [for (var h = 0; h < 5; h++) local(2026, 1, 1, h)];
    expect(intervalsOverlap(t[0], t[2], t[1], t[3]), isTrue);
    expect(intervalsOverlap(t[0], t[4], t[1], t[2]), isTrue);
    expect(intervalsOverlap(t[0], t[1], t[1], t[2]), isFalse);
    expect(intervalsOverlap(t[2], t[3], t[0], t[1]), isFalse);
  });

  test('validateDraft uses the draft fields', () {
    final draft = ShiftDraft.fromLocal(
      jobId: 1,
      date: LocalDate(2026, 9, 30),
      startHour: 8,
      startMinute: 0,
      endHour: 8,
      endMinute: 0,
      endsNextDay: false,
    );
    expect(validateDraft(draft, now: now).errors, [
      ShiftError.endNotAfterStart,
    ]);
  });

  test('warning equality and toString', () {
    expect(const LongerThan16h(1), const LongerThan16h(1));
    expect(const LongerThan16h(1).hashCode, const LongerThan16h(1).hashCode);
    expect(const LongerThan16h(1), isNot(const LongerThan16h(2)));
    expect(const StartsInFuture().hashCode, const StartsInFuture().hashCode);
    final s = doneShift(start: local(2026, 1, 1), end: local(2026, 1, 1, 1));
    expect(OverlapsWith(s).hashCode, OverlapsWith(s).hashCode);
    expect(OverlapsWith(s).toString(), 'OverlapsWith(1)');
    expect(
      const ShiftValidation(errors: [ShiftError.negativeTips]),
      const ShiftValidation(errors: [ShiftError.negativeTips]),
    );
    expect(ShiftValidation.ok.toString(), contains('errors'));
  });
}
