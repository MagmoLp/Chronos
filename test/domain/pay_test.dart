import 'dart:math';

import 'package:chronos/core/money.dart';
import 'package:chronos/core/time.dart';
import 'package:chronos/domain/pay.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/shifts.dart';
import '../fixtures/tz.dart';

void main() {
  group('workedMsBetween', () {
    test('duration minus break', () {
      expect(
        workedMsBetween(
          local(2026, 9, 30, 8),
          local(2026, 9, 30, 16, 15),
          breakMs: 30 * msPerMinute,
        ),
        7 * msPerHour + 45 * msPerMinute,
      );
    });

    test('never negative', () {
      expect(workedMsBetween(local(2026, 9, 30, 9), local(2026, 9, 30, 8)), 0);
      expect(
        workedMsBetween(
          local(2026, 9, 30, 8),
          local(2026, 9, 30, 9),
          breakMs: 2 * msPerHour,
        ),
        0,
      );
    });

    test('midnight crossing', () {
      expect(
        workedMsBetween(local(2026, 9, 30, 22), local(2026, 10, 1, 6)),
        8 * msPerHour,
      );
    });

    test('Berlin: night shift over the autumn switch has 9 h', () {
      expect(
        workedMsBetween(local(2026, 10, 24, 22), local(2026, 10, 25, 6)),
        9 * msPerHour,
      );
    }, skip: skipUnlessBerlin);

    test('Berlin: night shift over the spring switch has 7 h', () {
      expect(
        workedMsBetween(local(2026, 3, 28, 22), local(2026, 3, 29, 6)),
        7 * msPerHour,
      );
    }, skip: skipUnlessBerlin);
  });

  group('currentBreakMs', () {
    test('not paused: stored breaks', () {
      final s = runningShift(start: local(2026, 9, 30, 8), breakMs: 60000);
      expect(currentBreakMs(s, local(2026, 9, 30, 12)), 60000);
    });

    test('paused: stored breaks plus the pause so far', () {
      final s = runningShift(
        start: local(2026, 9, 30, 8),
        breakMs: 10 * msPerMinute,
        pausedAt: local(2026, 9, 30, 12),
      );
      expect(currentBreakMs(s, local(2026, 9, 30, 12, 20)), 30 * msPerMinute);
      // A clock before the pause start adds nothing.
      expect(currentBreakMs(s, local(2026, 9, 30, 11)), 10 * msPerMinute);
    });

    test('done shift: stored breaks', () {
      final s = doneShift(
        start: local(2026, 9, 30, 8),
        end: local(2026, 9, 30, 9),
        breakMs: 5000,
      );
      expect(currentBreakMs(s, local(2026, 9, 30, 12)), 5000);
    });
  });

  group('liveValues', () {
    test('running shift', () {
      final s = runningShift(start: local(2026, 9, 30, 8, 2));
      final now = local(2026, 9, 30, 11, 13, 42);
      final v = liveValues(s, now);
      const worked = 3 * msPerHour + 11 * msPerMinute + 42 * msPerSecond;
      expect(v.workedMs, worked);
      expect(v.earnedCents, earningsCents(worked, 1500));
      expect(v.breakMs, 0);
      expect(v.isPaused, isFalse);
      expect(v.pausedSinceUtc, isNull);
    });

    test('paused shift: time stands still', () {
      final s = runningShift(
        start: local(2026, 9, 30, 8),
        breakMs: 30 * msPerMinute,
        pausedAt: local(2026, 9, 30, 14, 32),
      );
      final a = liveValues(s, local(2026, 9, 30, 14, 40));
      final b = liveValues(s, local(2026, 9, 30, 15, 40));
      const worked = 6 * msPerHour + 2 * msPerMinute;
      expect(a.workedMs, worked);
      expect(b.workedMs, worked);
      expect(a.earnedCents, b.earnedCents);
      expect(a.isPaused, isTrue);
      expect(a.pausedSinceUtc, local(2026, 9, 30, 14, 32));
      expect(b.breakMs, 30 * msPerMinute + 68 * msPerMinute);
    });

    test('clock before start gives zero', () {
      final s = runningShift(start: local(2026, 9, 30, 8));
      final v = liveValues(s, local(2026, 9, 30, 7));
      expect(v.workedMs, 0);
      expect(v.earnedCents, 0);
    });

    test('done shift uses stored values', () {
      final s = doneShift(
        start: local(2026, 9, 30, 8),
        end: local(2026, 9, 30, 16, 15),
        breakMs: 30 * msPerMinute,
      );
      final v = liveValues(s, local(2030, 1, 1));
      expect(v.workedMs, 7 * msPerHour + 45 * msPerMinute);
      expect(v.earnedCents, 11625);
      expect(v.isPaused, isFalse);
    });

    test('Berlin: running over the autumn switch counts the extra hour', () {
      final s = runningShift(start: local(2026, 10, 24, 22));
      expect(liveValues(s, local(2026, 10, 25, 6)).workedMs, 9 * msPerHour);
    }, skip: skipUnlessBerlin);

    test('equality and toString', () {
      const a = LiveShiftValues(
        workedMs: 1,
        earnedCents: 2,
        breakMs: 3,
        isPaused: false,
      );
      const b = LiveShiftValues(
        workedMs: 1,
        earnedCents: 2,
        breakMs: 3,
        isPaused: false,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a.toString(), contains('2 ct'));
    });
  });

  group('shiftWorkedMs / shiftEarnedCents', () {
    test('done shifts need no clock', () {
      final s = doneShift(
        start: local(2026, 9, 30, 8),
        end: local(2026, 9, 30, 9),
      );
      expect(shiftWorkedMs(s), msPerHour);
      expect(shiftEarnedCents(s), 1500);
    });

    test('running shifts need now', () {
      final s = runningShift(start: local(2026, 9, 30, 8));
      expect(() => shiftWorkedMs(s), throwsArgumentError);
      expect(() => shiftEarnedCents(s), throwsArgumentError);
      expect(shiftWorkedMs(s, now: local(2026, 9, 30, 10)), 2 * msPerHour);
      expect(shiftEarnedCents(s, now: local(2026, 9, 30, 10)), 3000);
    });
  });

  group('msUntilNextCent', () {
    test('first cent at 15 €/h after 1.2 s', () {
      expect(msUntilNextCent(0, 1500), 1200);
      expect(earningsCents(1199, 1500), 0);
      expect(earningsCents(1200, 1500), 1);
    });

    test('zero rate never changes', () {
      expect(msUntilNextCent(1000, 0), isNull);
    });

    test('negative worked time is treated as zero', () {
      expect(msUntilNextCent(-500, 1500), 1700);
    });

    test('property: exactly when the next cent appears', () {
      final random = Random(7);
      for (var i = 0; i < 3000; i++) {
        final worked = random.nextInt(12 * msPerHour);
        final rate = 1 + random.nextInt(20000);
        final wait = msUntilNextCent(worked, rate)!;
        final now = earningsCents(worked, rate);
        expect(wait, greaterThan(0));
        expect(
          earningsCents(worked + wait, rate),
          greaterThan(now),
          reason: 'worked=$worked rate=$rate wait=$wait',
        );
        expect(
          earningsCents(worked + wait - 1, rate),
          now,
          reason: 'worked=$worked rate=$rate wait=$wait',
        );
      }
    });
  });
}
