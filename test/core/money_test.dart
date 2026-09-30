import 'dart:math';

import 'package:chronos/core/money.dart';
import 'package:chronos/core/time.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('earningsCents', () {
    test('exact hours', () {
      expect(earningsCents(8 * msPerHour, 1500), 12000);
      expect(earningsCents(msPerHour, 1390), 1390);
    });

    test('7:45 h × 15,00 € = 116,25 €', () {
      expect(earningsCents(7 * msPerHour + 45 * msPerMinute, 1500), 11625);
    });

    test('rounds half-up', () {
      // 1 min at 15,00 €/h = 25 ct exactly.
      expect(earningsCents(msPerMinute, 1500), 25);
      // 1 min at 13,90 €/h = 23.1666… ct → 23.
      expect(earningsCents(msPerMinute, 1390), 23);
      // Exactly half a cent: 1 ms × 1 800 000 ct/h = 0.5 ct → 1.
      expect(earningsCents(1, 1800000), 1);
      // Just below half: 0.4999… → 0.
      expect(earningsCents(1, 1799999), 0);
      // 30 s at 1 ct/h = 0.0083 ct → 0.
      expect(earningsCents(30 * msPerSecond, 1), 0);
    });

    test('non-positive worked time earns nothing', () {
      expect(earningsCents(0, 1500), 0);
      expect(earningsCents(-5 * msPerHour, 1500), 0);
      expect(earningsCents(msPerHour, 0), 0);
    });

    test('negative rate is rejected', () {
      expect(() => earningsCents(msPerHour, -1), throwsArgumentError);
    });

    test('matches the naive formula for random inputs', () {
      final random = Random(42);
      for (var i = 0; i < 5000; i++) {
        final worked = random.nextInt(24 * msPerHour);
        final rate = random.nextInt(10000);
        expect(
          earningsCents(worked, rate),
          (worked * rate + 1800000) ~/ 3600000,
          reason: 'worked=$worked rate=$rate',
        );
      }
    });

    test('does not overflow for huge values', () {
      // 100 years at 1 000 000 €/h.
      const worked = 100 * 365 * 24 * msPerHour;
      const rate = 100000000;
      expect(earningsCents(worked, rate), 100 * 365 * 24 * rate);
      // The naive product would overflow 64 bit here.
      expect(
        earningsCents(worked + msPerHour ~/ 2, rate),
        100 * 365 * 24 * rate + rate ~/ 2,
      );
    });

    test('summing cents per shift beats summing doubles (v1 bug D8)', () {
      // Three entries at 92,52 € must sum to 277,56 €.
      final perShift = earningsCents(6 * msPerHour + 10 * msPerMinute, 1500);
      expect(perShift, 9250);
      expect(sumCents([9252, 9252, 9252]), 27756);
    });
  });

  test('sumCents', () {
    expect(sumCents(const []), 0);
    expect(sumCents(const [1, 2, 3]), 6);
    expect(sumCents(const [-5, 5]), 0);
  });

  group('averageHourlyCents', () {
    test('null when nothing worked', () {
      expect(averageHourlyCents(1000, 0), isNull);
      expect(averageHourlyCents(1000, -1), isNull);
    });

    test('exact and rounded averages', () {
      expect(averageHourlyCents(12000, 8 * msPerHour), 1500);
      // 100 ct over 3 h = 33.33 → 33.
      expect(averageHourlyCents(100, 3 * msPerHour), 33);
      // 5 ct over 2 h = 2.5 → 3 (half-up).
      expect(averageHourlyCents(5, 2 * msPerHour), 3);
      // Negative amounts round symmetrically.
      expect(averageHourlyCents(-5, 2 * msPerHour), -3);
    });
  });

  group('centsFromEuros', () {
    test('converts typical legacy wages', () {
      expect(centsFromEuros(15.0), 1500);
      expect(centsFromEuros(12.5), 1250);
      expect(centsFromEuros(13.9), 1390);
      expect(centsFromEuros(1250.0), 125000);
      expect(centsFromEuros(0), 0);
      expect(centsFromEuros(0.1 + 0.2), 30);
    });

    test('rounds half-up on the decimal value', () {
      expect(centsFromEuros(12.345), 1235);
      expect(centsFromEuros(12.344), 1234);
      expect(centsFromEuros(0.005), 1);
    });

    test('rejects invalid values', () {
      expect(() => centsFromEuros(double.nan), throwsArgumentError);
      expect(() => centsFromEuros(double.infinity), throwsArgumentError);
      expect(() => centsFromEuros(-1), throwsArgumentError);
    });
  });
}
