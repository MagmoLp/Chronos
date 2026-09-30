import 'package:chronos/domain/job.dart';
import 'package:chronos/domain/rounding.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/shifts.dart';
import '../fixtures/tz.dart';

void main() {
  DateTime r15(DateTime t) => roundToRule(t, RoundingRule.nearest15);
  DateTime r5(DateTime t) => roundToRule(t, RoundingRule.nearest5);

  test('none keeps the instant (as UTC)', () {
    final t = DateTime(2026, 9, 30, 8, 7, 12);
    expect(roundToRule(t, RoundingRule.none), t.toUtc());
    expect(roundToRule(t, RoundingRule.none).isUtc, isTrue);
  });

  test('step sizes', () {
    expect(RoundingRule.none.stepMinutes, 0);
    expect(RoundingRule.nearest5.stepMinutes, 5);
    expect(RoundingRule.nearest15.stepMinutes, 15);
  });

  group('nearest 15 min (threshold exactly 7:30 min)', () {
    test('rounds down below half a step', () {
      expect(r15(local(2026, 9, 30, 8, 7)), local(2026, 9, 30, 8, 0));
      expect(r15(local(2026, 9, 30, 8, 7, 29)), local(2026, 9, 30, 8, 0));
      expect(r15(local(2026, 9, 30, 8, 0)), local(2026, 9, 30, 8, 0));
    });

    test('exact half rounds up', () {
      expect(r15(local(2026, 9, 30, 8, 7, 30)), local(2026, 9, 30, 8, 15));
      expect(r15(local(2026, 9, 30, 8, 52, 30)), local(2026, 9, 30, 9, 0));
    });

    test('rounds up above half a step', () {
      expect(r15(local(2026, 9, 30, 8, 8)), local(2026, 9, 30, 8, 15));
      expect(r15(local(2026, 9, 30, 16, 14)), local(2026, 9, 30, 16, 15));
    });

    test('rolls over midnight', () {
      expect(r15(local(2026, 9, 30, 23, 53)), local(2026, 10, 1, 0, 0));
      expect(r15(local(2026, 12, 31, 23, 59)), local(2027, 1, 1, 0, 0));
    });

    test('v1 bug D5: 08:07 no longer rounds to 08:15', () {
      expect(r15(local(2026, 5, 26, 8, 7)), local(2026, 5, 26, 8, 0));
    });

    test('milliseconds count', () {
      final almostHalf = local(
        2026,
        9,
        30,
        8,
        7,
        29,
      ).add(const Duration(milliseconds: 999));
      expect(r15(almostHalf), local(2026, 9, 30, 8, 0));
    });
  });

  group('nearest 5 min', () {
    test('threshold 2:30 min', () {
      expect(r5(local(2026, 9, 30, 8, 2, 29)), local(2026, 9, 30, 8, 0));
      expect(r5(local(2026, 9, 30, 8, 2, 30)), local(2026, 9, 30, 8, 5));
      expect(r5(local(2026, 9, 30, 8, 58)), local(2026, 9, 30, 9, 0));
    });
  });

  test('roundShiftTimes rounds both ends', () {
    final times = roundShiftTimes(
      rawStartUtc: local(2026, 9, 30, 8, 7, 30),
      rawEndUtc: local(2026, 9, 30, 16, 7),
      rule: RoundingRule.nearest15,
    );
    expect(times.startUtc, local(2026, 9, 30, 8, 15));
    expect(times.endUtc, local(2026, 9, 30, 16, 0));
  });

  group('Berlin DST days', () {
    test('spring: 01:55 CET rounds to the switch instant, not an hour off', () {
      final raw = DateTime.utc(2026, 3, 29, 0, 55); // 01:55 CET
      final rounded = r15(raw);
      expect(rounded, DateTime.utc(2026, 3, 29, 1)); // 03:00 CEST
      expect(rounded.difference(raw), const Duration(minutes: 5));
    });

    test('spring: 03:08 CEST rounds to 03:15 CEST', () {
      final raw = DateTime(2026, 3, 29, 3, 8).toUtc();
      expect(r15(raw), DateTime(2026, 3, 29, 3, 15).toUtc());
    });

    test('autumn: first 02:53 (CEST) rounds 7 minutes forward', () {
      final raw = DateTime.utc(2026, 10, 25, 0, 53); // 02:53 CEST
      final rounded = r15(raw);
      expect(rounded.difference(raw), const Duration(minutes: 7));
      expect(rounded, DateTime.utc(2026, 10, 25, 1));
    });

    test('autumn: second 02:53 (CET) rounds 7 minutes forward', () {
      final raw = DateTime.utc(2026, 10, 25, 1, 53); // 02:53 CET
      final rounded = r15(raw);
      expect(rounded, DateTime.utc(2026, 10, 25, 2)); // 03:00 CET
    });

    test('autumn: second 02:05 (CET) rounds down within the repeated hour', () {
      final raw = DateTime.utc(2026, 10, 25, 1, 5); // 02:05 CET
      expect(r15(raw), DateTime.utc(2026, 10, 25, 1)); // 02:00 CET
    });

    test('rounding never moves more than half a step on switch days', () {
      for (final day in [
        DateTime.utc(2026, 3, 28, 22),
        DateTime.utc(2026, 10, 24, 22),
      ]) {
        for (var m = 0; m < 6 * 60; m++) {
          final raw = day.add(Duration(minutes: m, seconds: 17));
          final diff = r15(raw).difference(raw).abs();
          expect(
            diff <= const Duration(minutes: 7, seconds: 30),
            isTrue,
            reason: '$raw',
          );
        }
      }
    });
  }, skip: skipUnlessBerlin);
}
