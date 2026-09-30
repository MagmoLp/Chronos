import 'package:chronos/core/local_date.dart';
import 'package:chronos/core/time.dart';
import 'package:chronos/domain/summaries.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/shifts.dart';

void main() {
  final today = LocalDate(2026, 9, 30);
  final shifts = [
    doneShift(id: 1, start: local(2026, 9, 30, 6), end: local(2026, 9, 30, 8)),
    doneShift(
      id: 2,
      start: local(2026, 9, 30, 9),
      end: local(2026, 9, 30, 10),
      tips: 300,
      paid: true,
    ),
    // Yesterday's overnight shift ends today but belongs to yesterday.
    doneShift(id: 3, start: local(2026, 9, 29, 22), end: local(2026, 9, 30, 2)),
    doneShift(
      id: 4,
      start: local(2026, 9, 30, 11),
      end: local(2026, 9, 30, 12),
      deletedAt: local(2026, 9, 30, 12),
    ),
    doneShift(id: 5, start: local(2026, 9, 21, 8), end: local(2026, 9, 21, 9)),
  ];

  group('TodaySummary', () {
    test('finished shifts of today, newest first', () {
      final s = computeTodaySummary(today: today, shifts: shifts);
      expect(s.doneShifts.map((x) => x.id), [2, 1]);
      expect(s.doneEarnedCents, 4500);
      expect(s.doneWorkedMs, 3 * msPerHour);
      expect(s.doneTipsCents, 300);
      expect(s.doneCount, 2);
      expect(s.hasWork, isTrue);
      expect(s.running, isNull);
      expect(s.earnedCentsAt(local(2026, 9, 30, 20)), 4500);
    });

    test('adds the running shift live, even if it started yesterday', () {
      final running = runningShift(start: local(2026, 9, 29, 23));
      final s = computeTodaySummary(
        today: today,
        shifts: shifts,
        running: running,
      );
      expect(s.running, running);
      final now = local(2026, 9, 30, 13);
      expect(s.earnedCentsAt(now), 4500 + 14 * 1500);
      expect(s.workedMsAt(now), 3 * msPerHour + 14 * msPerHour);
    });

    test('nothing today', () {
      final s = computeTodaySummary(
        today: LocalDate(2026, 9, 25),
        shifts: shifts,
      );
      expect(s.hasWork, isFalse);
      expect(s.doneEarnedCents, 0);
      expect(s.workedMsAt(local(2026, 9, 25, 12)), 0);
    });

    test('ignores a running shift passed as deleted or done', () {
      final s = computeTodaySummary(
        today: today,
        shifts: shifts,
        running: shifts.first,
      );
      expect(s.running, isNull);
    });

    test('equality', () {
      final a = computeTodaySummary(today: today, shifts: shifts);
      final b = computeTodaySummary(today: today, shifts: shifts.reversed);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a.toString(), contains('2 done'));
    });
  });

  group('PeriodSummary', () {
    final week = LocalDateRange.week(today);

    test('this week', () {
      final s = computePeriodSummary(week, shifts);
      expect(s.shiftCount, 3);
      expect(s.workedMs, 7 * msPerHour);
      expect(s.earnedCents, 10500);
      expect(s.tipsCents, 300);
      expect(s.running, isNull);
    });

    test('running shift only if it started in the range', () {
      final inside = runningShift(start: local(2026, 9, 30, 14));
      final s = computePeriodSummary(week, shifts, running: inside);
      expect(s.running, inside);
      expect(s.earnedCentsAt(local(2026, 9, 30, 16)), 10500 + 3000);
      expect(s.workedMsAt(local(2026, 9, 30, 16)), 9 * msPerHour);

      final outside = runningShift(start: local(2026, 9, 27, 23));
      final t = computePeriodSummary(week, shifts, running: outside);
      expect(t.running, isNull);
      expect(t.earnedCentsAt(local(2026, 9, 30, 16)), 10500);
    });

    test('equality', () {
      expect(
        computePeriodSummary(week, shifts),
        computePeriodSummary(week, shifts.reversed),
      );
      expect(
        computePeriodSummary(week, shifts).hashCode,
        computePeriodSummary(week, shifts).hashCode,
      );
      expect(computePeriodSummary(week, shifts).toString(), contains('10500'));
    });
  });

  group('OpenSummary', () {
    test('unpaid finished shifts', () {
      final s = computeOpenSummary(shifts);
      expect(s.shiftCount, 3); // 1, 3, 5
      expect(s.openCents, 3000 + 6000 + 1500);
      expect(s.workedMs, 7 * msPerHour);
      expect(s.tipsCents, 0);
      expect(s.isEmpty, isFalse);
    });

    test('plus the running shift live', () {
      final running = runningShift(start: local(2026, 9, 30, 14));
      final s = computeOpenSummary(shifts, running: running);
      expect(s.openCentsAt(local(2026, 9, 30, 15)), 10500 + 1500);
    });

    test('empty', () {
      expect(computeOpenSummary(const []), OpenSummary.empty);
      expect(OpenSummary.empty.isEmpty, isTrue);
      expect(OpenSummary.empty.hashCode, computeOpenSummary(const []).hashCode);
      expect(OpenSummary.empty.toString(), contains('0 ct'));
    });
  });
}
