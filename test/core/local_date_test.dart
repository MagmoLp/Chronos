import 'package:chronos/core/local_date.dart';
import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/tz.dart';

void main() {
  group('LocalDate construction', () {
    test('normalises out-of-range values like DateTime', () {
      expect(LocalDate(2026, 1, 32), LocalDate(2026, 2, 1));
      expect(LocalDate(2026, 13, 1), LocalDate(2027, 1, 1));
      expect(LocalDate(2026, 3, 0), LocalDate(2026, 2, 28));
      expect(LocalDate(2024, 2, 29).day, 29);
    });

    test('fromDateTime keeps the given calendar fields', () {
      expect(
        LocalDate.fromDateTime(DateTime(2026, 9, 30, 23, 59)),
        LocalDate(2026, 9, 30),
      );
      expect(
        LocalDate.fromDateTime(DateTime.utc(2026, 9, 30, 23, 59)),
        LocalDate(2026, 9, 30),
      );
    });

    test('ofInstant uses the local date of an instant', () {
      final instant = DateTime(2026, 9, 30, 0, 30).toUtc();
      expect(LocalDate.ofInstant(instant), LocalDate(2026, 9, 30));
    });

    test('today reads the injected clock', () {
      final fixed = Clock.fixed(DateTime(2026, 9, 30, 12));
      expect(LocalDate.today(fixed), LocalDate(2026, 9, 30));
      withClock(Clock.fixed(DateTime(2026, 10, 1, 8)), () {
        expect(LocalDate.today(), LocalDate(2026, 10, 1));
      });
    });

    test('key round-trips', () {
      final d = LocalDate(2026, 9, 30);
      expect(d.key, 20260930);
      expect(LocalDate.fromKey(20260930), d);
      expect(
        LocalDate.fromKey(LocalDate(1999, 12, 31).key),
        LocalDate(1999, 12, 31),
      );
    });

    test('parse / tryParse / toIso8601String', () {
      expect(LocalDate.parse('2026-03-29'), LocalDate(2026, 3, 29));
      expect(LocalDate(5, 1, 2).toIso8601String(), '0005-01-02');
      expect(LocalDate(2026, 9, 30).toString(), '2026-09-30');
      expect(LocalDate.tryParse('2026-02-30'), isNull);
      expect(LocalDate.tryParse('30.09.2026'), isNull);
      expect(LocalDate.tryParse(''), isNull);
      expect(() => LocalDate.parse('nope'), throwsFormatException);
    });
  });

  group('LocalDate arithmetic', () {
    test('addDays across months, years and DST switches', () {
      expect(LocalDate(2026, 1, 31).addDays(1), LocalDate(2026, 2, 1));
      expect(LocalDate(2026, 12, 31).addDays(1), LocalDate(2027, 1, 1));
      expect(LocalDate(2026, 3, 1).addDays(-1), LocalDate(2026, 2, 28));
      expect(LocalDate(2026, 3, 28).addDays(1), LocalDate(2026, 3, 29));
      expect(LocalDate(2026, 3, 29).addDays(1), LocalDate(2026, 3, 30));
      expect(LocalDate(2026, 10, 25).addDays(1), LocalDate(2026, 10, 26));
      expect(LocalDate(2026, 10, 24).addDays(2), LocalDate(2026, 10, 26));
    });

    test('addMonths clamps to the end of the month', () {
      expect(LocalDate(2026, 1, 31).addMonths(1), LocalDate(2026, 2, 28));
      expect(LocalDate(2024, 1, 31).addMonths(1), LocalDate(2024, 2, 29));
      expect(LocalDate(2026, 3, 15).addMonths(-3), LocalDate(2025, 12, 15));
      expect(LocalDate(2026, 12, 1).addMonths(1), LocalDate(2027, 1, 1));
    });

    test('weekday, startOfWeek (Monday) and month bounds', () {
      final wed = LocalDate(2026, 9, 30);
      expect(wed.weekday, DateTime.wednesday);
      expect(wed.startOfWeek, LocalDate(2026, 9, 28));
      expect(LocalDate(2026, 9, 28).startOfWeek, LocalDate(2026, 9, 28));
      expect(LocalDate(2026, 10, 4).startOfWeek, LocalDate(2026, 9, 28));
      expect(wed.firstOfMonth, LocalDate(2026, 9, 1));
      expect(wed.lastOfMonth, LocalDate(2026, 9, 30));
      expect(LocalDate(2024, 2, 10).daysInMonth, 29);
      expect(LocalDate(2026, 2, 10).daysInMonth, 28);
    });

    test('daysUntil counts calendar days, also over DST', () {
      expect(LocalDate(2026, 3, 28).daysUntil(LocalDate(2026, 3, 30)), 2);
      expect(LocalDate(2026, 10, 30).daysUntil(LocalDate(2026, 10, 20)), -10);
      expect(LocalDate(2026, 1, 1).daysUntil(LocalDate(2027, 1, 1)), 365);
    });

    test('comparisons', () {
      final a = LocalDate(2026, 9, 29);
      final b = LocalDate(2026, 9, 30);
      expect(a.isBefore(b), isTrue);
      expect(b.isAfter(a), isTrue);
      expect(a.isOnOrBefore(a), isTrue);
      expect(a.isOnOrAfter(b), isFalse);
      expect(a.compareTo(b), lessThan(0));
      expect(LocalDate.min(a, b), a);
      expect(LocalDate.max(a, b), b);
      expect({a, LocalDate(2026, 9, 29)}.length, 1);
      expect([b, a]..sort(), [a, b]);
    });
  });

  group('LocalDate to instants', () {
    test('toLocalDateTime builds wall-clock time', () {
      final dt = LocalDate(2026, 9, 30).toLocalDateTime(8, 15);
      expect(dt.isUtc, isFalse);
      expect((dt.hour, dt.minute), (8, 15));
      expect(LocalDate(2026, 9, 30).startUtc, DateTime(2026, 9, 30).toUtc());
    });

    test('Berlin: day lengths on DST switch days', () {
      final spring = LocalDate(2026, 3, 29);
      expect(
        spring.addDays(1).startUtc.difference(spring.startUtc),
        const Duration(hours: 23),
      );
      final autumn = LocalDate(2026, 10, 25);
      expect(
        autumn.addDays(1).startUtc.difference(autumn.startUtc),
        const Duration(hours: 25),
      );
      // 08:00 local stays 08:00 on both sides of the switch.
      expect(spring.toLocalDateTime(8).toUtc(), DateTime.utc(2026, 3, 29, 6));
      expect(
        LocalDate(2026, 3, 28).toLocalDateTime(8).toUtc(),
        DateTime.utc(2026, 3, 28, 7),
      );
      expect(autumn.toLocalDateTime(8).toUtc(), DateTime.utc(2026, 10, 25, 7));
    }, skip: skipUnlessBerlin);

    test('Berlin: non-existent 02:30 resolves forward', () {
      final dt = LocalDate(2026, 3, 29).toLocalDateTime(2, 30);
      expect(dt.toUtc(), DateTime.utc(2026, 3, 29, 1, 30));
    }, skip: skipUnlessBerlin);
  });
}
