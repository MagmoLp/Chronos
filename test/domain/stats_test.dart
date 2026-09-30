import 'package:chronos/core/local_date.dart';
import 'package:chronos/core/time.dart';
import 'package:chronos/domain/app_settings.dart';
import 'package:chronos/domain/stats.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/shifts.dart';
import '../fixtures/tz.dart';

void main() {
  group('StatsPeriod', () {
    test('normalises to the first day', () {
      expect(
        StatsPeriod.week(LocalDate(2026, 9, 30)).start,
        LocalDate(2026, 9, 28),
      );
      expect(
        StatsPeriod.month(LocalDate(2026, 9, 30)).start,
        LocalDate(2026, 9, 1),
      );
      expect(
        StatsPeriod.year(LocalDate(2026, 9, 30)).start,
        LocalDate(2026, 1, 1),
      );
      expect(
        StatsPeriod.week(LocalDate(2026, 9, 30)),
        StatsPeriod.week(LocalDate(2026, 10, 4)),
      );
    });

    test('ranges', () {
      expect(StatsPeriod.week(LocalDate(2026, 9, 30)).range.dayCount, 7);
      expect(StatsPeriod.month(LocalDate(2026, 2, 3)).range.dayCount, 28);
      expect(StatsPeriod.year(LocalDate(2024, 2, 3)).range.dayCount, 366);
    });

    test('previous / next', () {
      final w = StatsPeriod.week(LocalDate(2026, 9, 30));
      expect(w.previous.start, LocalDate(2026, 9, 21));
      expect(w.next.start, LocalDate(2026, 10, 5));
      final m = StatsPeriod.month(LocalDate(2026, 1, 31));
      expect(m.previous.start, LocalDate(2025, 12, 1));
      expect(m.next.start, LocalDate(2026, 2, 1));
      final y = StatsPeriod.year(LocalDate(2026, 5, 5));
      expect(y.previous.start, LocalDate(2025, 1, 1));
      expect(y.next.start, LocalDate(2027, 1, 1));
      expect(w.previous.next, w);
    });

    test('isCurrent / canGoNext never passes the current period', () {
      final today = LocalDate(2026, 9, 30);
      final current = StatsPeriod.month(today);
      expect(current.isCurrent(today), isTrue);
      expect(current.canGoNext(today), isFalse);
      expect(current.previous.canGoNext(today), isTrue);
      expect(current.previous.isCurrent(today), isFalse);
      expect(StatsPeriod.week(today).canGoNext(today), isFalse);
      expect(StatsPeriod.year(today).canGoNext(today), isFalse);
      expect(StatsPeriod.year(today).toString(), contains('year'));
    });
  });

  group('computeStats', () {
    final shifts = [
      // Monday 28 Sep: 8 h, 15 €/h, paid.
      doneShift(
        id: 1,
        start: local(2026, 9, 28, 8),
        end: local(2026, 9, 28, 16),
        paid: true,
      ),
      // Wednesday 30 Sep: 4 h at 20 €/h + 10 € tips, job 2.
      doneShift(
        id: 2,
        jobId: 2,
        start: local(2026, 9, 30, 10),
        end: local(2026, 9, 30, 14),
        rate: 2000,
        tips: 1000,
      ),
      // Sunday 4 Oct, overnight into Monday: belongs to Sunday (and October).
      doneShift(
        id: 3,
        start: local(2026, 10, 4, 22),
        end: local(2026, 10, 5, 6),
        breakMs: 30 * msPerMinute,
      ),
      // Deleted and running shifts never count.
      doneShift(
        id: 4,
        start: local(2026, 9, 29, 8),
        end: local(2026, 9, 29, 16),
        deletedAt: local(2026, 9, 29, 17),
      ),
      runningShift(id: 5, start: local(2026, 9, 30, 16)),
      // Previous week.
      doneShift(
        id: 6,
        start: local(2026, 9, 27, 8),
        end: local(2026, 9, 27, 10),
      ),
    ];

    test('week: totals, buckets, jobs', () {
      final s = computeStats(StatsPeriod.week(LocalDate(2026, 9, 30)), shifts);
      expect(s.shiftCount, 3);
      expect(
        s.workedMs,
        (8 + 4) * msPerHour + 7 * msPerHour + 30 * msPerMinute,
      );
      expect(s.earnedCents, 12000 + 8000 + 11250);
      expect(s.openCents, 8000 + 11250);
      expect(s.tipsCents, 1000);
      // (31250 + 1000) ct over 19.5 h = 1653.8 → 1654.
      expect(s.avgHourlyInclTipsCents, 1654);
      expect(s.buckets, hasLength(7));
      expect(s.buckets[0].start, LocalDate(2026, 9, 28));
      expect(s.buckets[0].earnedCents, 12000);
      expect(s.buckets[2].earnedCents, 8000);
      expect(s.buckets[2].tipsCents, 1000);
      expect(s.buckets[6].earnedCents, 11250);
      expect(s.buckets[6].shiftCount, 1);
      expect(s.buckets[1].earnedCents, 0);
      expect(s.perJob.map((j) => j.jobId), [1, 2]);
      expect(s.perJob.first.earnedCents, 23250);
      expect(s.perJob.first.openCents, 11250);
      expect(s.perJob.last.tipsCents, 1000);
      expect(s.isEmpty, isFalse);
    });

    test('month: one bucket per day', () {
      final s = computeStats(StatsPeriod.month(LocalDate(2026, 9, 1)), shifts);
      expect(s.buckets, hasLength(30));
      expect(s.shiftCount, 3); // 27, 28, 30 Sep
      expect(s.buckets[26].earnedCents, 3000);
      final oct = computeStats(
        StatsPeriod.month(LocalDate(2026, 10, 1)),
        shifts,
      );
      expect(oct.buckets, hasLength(31));
      expect(oct.shiftCount, 1);
      expect(oct.buckets[3].earnedCents, 11250);
    });

    test('year: 12 month buckets', () {
      final s = computeStats(StatsPeriod.year(LocalDate(2026, 1, 1)), shifts);
      expect(s.buckets, hasLength(12));
      expect(s.buckets[8].range, LocalDateRange.month(2026, 9));
      expect(s.buckets[8].shiftCount, 3);
      expect(s.buckets[9].shiftCount, 1);
      expect(s.buckets[0].shiftCount, 0);
      expect(s.shiftCount, 4);
    });

    test('empty period', () {
      final s = computeStats(StatsPeriod.month(LocalDate(2025, 1, 1)), shifts);
      expect(s.isEmpty, isTrue);
      expect(s.avgHourlyInclTipsCents, isNull);
      expect(s.perJob, isEmpty);
      expect(s.buckets.every((b) => b.earnedCents == 0), isTrue);
    });

    test('equality', () {
      final a = computeStats(StatsPeriod.week(LocalDate(2026, 9, 30)), shifts);
      final b = computeStats(StatsPeriod.week(LocalDate(2026, 9, 30)), shifts);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a.buckets.first.hashCode, b.buckets.first.hashCode);
      expect(a.perJob.first, b.perJob.first);
      expect(a.perJob.first.hashCode, b.perJob.first.hashCode);
      expect(a.toString(), contains('3 shifts'));
      expect(a.buckets.first.toString(), contains('2026-09-28'));
      expect(a.perJob.first.toString(), contains('JobStats'));
    });

    test('Berlin: shifts on DST days land in the right buckets', () {
      final dstShifts = [
        doneShift(
          id: 1,
          start: local(2026, 10, 24, 22),
          end: local(2026, 10, 25, 6),
        ),
        doneShift(
          id: 2,
          start: local(2026, 10, 25, 0, 30),
          end: local(2026, 10, 25, 3, 30),
        ),
      ];
      final s = computeStats(
        StatsPeriod.week(LocalDate(2026, 10, 25)),
        dstShifts,
      );
      expect(s.buckets[5].workedMs, 9 * msPerHour); // Saturday
      expect(s.buckets[6].workedMs, 4 * msPerHour); // Sunday, repeated hour
    }, skip: skipUnlessBerlin);
  });

  group('GoalProgress', () {
    test('no goal set', () {
      expect(monthlyGoalProgress(AppSettings.defaults, 1000), isNull);
      expect(
        monthlyGoalProgress(
          AppSettings.defaults.copyWith(monthlyGoalCents: 0),
          1000,
        ),
        isNull,
      );
    });

    test('goal', () {
      final p = monthlyGoalProgress(
        AppSettings.defaults.copyWith(monthlyGoalCents: 60300),
        43800,
      )!;
      expect(p.fraction, closeTo(0.726, 0.001));
      expect(p.reached, isFalse);
      expect(p.remainingCents, 16500);
      expect(p.level, GoalLevel.normal);
      const done = GoalProgress(
        earnedCents: 70000,
        targetCents: 60300,
        type: MonthlyGoalType.goal,
      );
      expect(done.reached, isTrue);
      expect(done.remainingCents, 0);
      expect(done.level, GoalLevel.normal);
    });

    test('limit levels at 80 % and 100 %', () {
      GoalProgress limit(int earned) => GoalProgress(
        earnedCents: earned,
        targetCents: 60300,
        type: MonthlyGoalType.limit,
      );
      expect(limit(48239).level, GoalLevel.normal);
      expect(limit(48240).level, GoalLevel.warning);
      expect(limit(60299).level, GoalLevel.warning);
      expect(limit(60300).level, GoalLevel.exceeded);
      expect(limit(90000).level, GoalLevel.exceeded);
      expect(limit(1), limit(1));
      expect(limit(1).hashCode, limit(1).hashCode);
      expect(limit(1).toString(), contains('limit'));
    });

    test('non-positive target has zero fraction', () {
      const p = GoalProgress(
        earnedCents: 5,
        targetCents: 0,
        type: MonthlyGoalType.goal,
      );
      expect(p.fraction, 0);
    });
  });
}
