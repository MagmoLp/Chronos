import 'package:chronos/core/local_date.dart';
import 'package:chronos/core/time.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/tz.dart';

void main() {
  test('constants', () {
    expect(msPerSecond, 1000);
    expect(msPerMinute, 60000);
    expect(msPerHour, 3600000);
  });

  test('utcFromMs / utcFromMsOrNull', () {
    final dt = utcFromMs(0);
    expect(dt.isUtc, isTrue);
    expect(dt, DateTime.utc(1970));
    expect(utcFromMsOrNull(null), isNull);
    expect(utcFromMsOrNull(1000), DateTime.utc(1970, 1, 1, 0, 0, 1));
  });

  test('offsetMinutesAt and localDateOf follow the device zone', () {
    final instant = DateTime(2026, 7, 1, 12).toUtc();
    expect(
      offsetMinutesAt(instant),
      DateTime(2026, 7, 1, 12).timeZoneOffset.inMinutes,
    );
    expect(
      localDateOf(DateTime(2026, 7, 1, 0, 5).toUtc()),
      LocalDate(2026, 7, 1),
    );
  });

  test('combineLocal builds local wall-clock instants', () {
    final d = LocalDate(2026, 9, 30);
    expect(combineLocal(d, 8, 0), DateTime(2026, 9, 30, 8).toUtc());
    expect(
      combineLocal(d, 6, 0, nextDay: true),
      DateTime(2026, 10, 1, 6).toUtc(),
    );
    expect(
      combineLocal(LocalDate(2026, 12, 31), 2, 0, nextDay: true),
      DateTime(2027, 1, 1, 2).toUtc(),
    );
  });

  group('Berlin DST', () {
    test('overnight shift into the autumn switch is 9 h real time', () {
      final start = combineLocal(LocalDate(2026, 10, 24), 22, 0);
      final end = combineLocal(LocalDate(2026, 10, 24), 6, 0, nextDay: true);
      expect(end.difference(start), const Duration(hours: 9));
    });

    test('overnight shift into the spring switch is 7 h real time', () {
      final start = combineLocal(LocalDate(2026, 3, 28), 22, 0);
      final end = combineLocal(LocalDate(2026, 3, 28), 6, 0, nextDay: true);
      expect(end.difference(start), const Duration(hours: 7));
    });

    test('offsets differ on both sides of the switch', () {
      expect(offsetMinutesAt(DateTime.utc(2026, 3, 29, 0, 59)), 60);
      expect(offsetMinutesAt(DateTime.utc(2026, 3, 29, 1)), 120);
      expect(offsetMinutesAt(DateTime.utc(2026, 10, 25, 0, 59)), 120);
      expect(offsetMinutesAt(DateTime.utc(2026, 10, 25, 1)), 60);
    });

    test('local offset change days', () {
      expect(isLocalOffsetChangeDay(LocalDate(2026, 3, 29)), isTrue);
      expect(isLocalOffsetChangeDay(LocalDate(2026, 10, 25)), isTrue);
      expect(isLocalOffsetChangeDay(LocalDate(2026, 10, 24)), isFalse);
      expect(isLocalOffsetChangeDay(LocalDate(2026, 3, 30)), isFalse);
    });
  }, skip: skipUnlessBerlin);

  test('EU DST switch days (independent of device zone)', () {
    expect(isEuDstSwitchDay(LocalDate(2026, 3, 29)), isTrue);
    expect(isEuDstSwitchDay(LocalDate(2026, 10, 25)), isTrue);
    expect(isEuDstSwitchDay(LocalDate(2027, 3, 28)), isTrue);
    expect(isEuDstSwitchDay(LocalDate(2027, 10, 31)), isTrue);
    expect(isEuDstSwitchDay(LocalDate(2025, 3, 30)), isTrue);
    expect(isEuDstSwitchDay(LocalDate(2025, 10, 26)), isTrue);
    expect(isEuDstSwitchDay(LocalDate(2026, 3, 22)), isFalse); // Sunday
    expect(isEuDstSwitchDay(LocalDate(2026, 10, 18)), isFalse); // Sunday
    expect(isEuDstSwitchDay(LocalDate(2026, 3, 28)), isFalse);
    expect(isEuDstSwitchDay(LocalDate(2026, 5, 31)), isFalse); // last Sun May
    expect(isDstSwitchDay(LocalDate(2026, 10, 25)), isTrue);
    expect(isDstSwitchDay(LocalDate(2026, 9, 30)), isFalse);
  });

  test('weekStart', () {
    expect(weekStart(LocalDate(2026, 10, 4)), LocalDate(2026, 9, 28));
  });

  group('LocalDateRange', () {
    test('week is Monday to Monday', () {
      final r = LocalDateRange.week(LocalDate(2026, 9, 30));
      expect(r.start, LocalDate(2026, 9, 28));
      expect(r.endExclusive, LocalDate(2026, 10, 5));
      expect(r.endInclusive, LocalDate(2026, 10, 4));
      expect(r.dayCount, 7);
      expect(r.days.first, r.start);
      expect(r.days.last, r.endInclusive);
    });

    test('month and year', () {
      final feb = LocalDateRange.month(2024, 2);
      expect(feb.dayCount, 29);
      expect(
        LocalDateRange.monthOf(LocalDate(2026, 12, 5)).endExclusive,
        LocalDate(2027, 1, 1),
      );
      expect(LocalDateRange.year(2026).dayCount, 365);
      expect(LocalDateRange.day(LocalDate(2026, 1, 1)).dayCount, 1);
    });

    test('contains / containsInstant', () {
      final r = LocalDateRange.month(2026, 9);
      expect(r.contains(LocalDate(2026, 9, 1)), isTrue);
      expect(r.contains(LocalDate(2026, 9, 30)), isTrue);
      expect(r.contains(LocalDate(2026, 10, 1)), isFalse);
      expect(r.contains(LocalDate(2026, 8, 31)), isFalse);
      expect(r.containsInstant(DateTime(2026, 9, 30, 23, 59).toUtc()), isTrue);
      expect(r.containsInstant(DateTime(2026, 10, 1).toUtc()), isFalse);
    });

    test('UTC bounds are local midnights', () {
      final r = LocalDateRange.month(2026, 9);
      expect(r.startUtc, DateTime(2026, 9).toUtc());
      expect(r.endUtc, DateTime(2026, 10).toUtc());
      expect(r.startUtc.isUtc, isTrue);
    });

    test('Berlin: October has 31 days and one extra hour', () {
      final r = LocalDateRange.month(2026, 10);
      expect(
        r.endUtc.difference(r.startUtc),
        const Duration(days: 31, hours: 1),
      );
    }, skip: skipUnlessBerlin);

    test('equality', () {
      expect(
        LocalDateRange.week(LocalDate(2026, 9, 30)),
        LocalDateRange.week(LocalDate(2026, 10, 1)),
      );
      expect(
        LocalDateRange.week(LocalDate(2026, 9, 30)).hashCode,
        LocalDateRange.week(LocalDate(2026, 10, 1)).hashCode,
      );
      expect(
        LocalDateRange.day(LocalDate(2026, 1, 1)).toString(),
        '[2026-01-01, 2026-01-02)',
      );
    });
  });
}
