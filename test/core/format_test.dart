import 'package:chronos/core/format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

const nbsp = '\u00A0';

/// Normalises the narrow/non-breaking spaces intl emits so expectations stay
/// readable where the exact space character does not matter.
String plain(String s) => s.replaceAll(RegExp('[\u00A0\u202F]'), ' ');

const int h = 3600000;
const int min = 60000;
const int sec = 1000;

void main() {
  final de = Fmt(const Locale('de'));
  final en = Fmt(const Locale('en'), use24HourFormat: false);
  final en24 = Fmt(const Locale('en'));
  final wed = DateTime(2026, 9, 30, 8, 2);

  group('money', () {
    test('formats cents with locale grouping and symbol position', () {
      expect(de.money(123456), '1.234,56$nbsp€');
      expect(en.money(123456), '€1,234.56');
      expect(de.money(0), '0,00$nbsp€');
      expect(en.money(5), '€0.05');
      expect(de.money(-1234), '-12,34$nbsp€');
      expect(en.money(-1234), '-€12.34');
      expect(de.money(99999999999), '999.999.999,99$nbsp€');
    });

    test('rate appends the per-hour unit', () {
      expect(de.rate(1500), '15,00$nbsp€/h');
      expect(en.rate(1500), '€15.00/h');
    });

    test('moneyInput has no symbol and round-trips through the parser', () {
      expect(de.moneyInput(123456), '1.234,56');
      expect(en.moneyInput(123456), '1,234.56');
      for (final cents in [0, 5, 1550, 123456, 100000000]) {
        expect(de.parseMoneyToCents(de.moneyInput(cents)), cents);
        expect(en.parseMoneyToCents(en.moneyInput(cents)), cents);
        expect(de.parseMoneyToCents(de.money(cents)), cents);
        expect(en.parseMoneyToCents(en.money(cents)), cents);
      }
    });

    test('separators and symbol placement are exposed', () {
      expect(de.decimalSeparator, ',');
      expect(de.groupSeparator, '.');
      expect(en.decimalSeparator, '.');
      expect(en.groupSeparator, ',');
      expect(de.currencySymbolFirst, isFalse);
      expect(en.currencySymbolFirst, isTrue);
      expect(de.currencySymbol, '€');
    });

    test('regional locales keep their own conventions', () {
      final at = Fmt(const Locale('de', 'AT'));
      expect(
        plain(at.money(123456)),
        anyOf('€ 1.234,56', '1.234,56 €', '€ 1 234,56'),
      );
      expect(at.rate(1500), endsWith('/h'));
    });
  });

  group('parseMoneyToCents', () {
    final cases = <String, int?>{
      '15': 1500,
      '15,5': 1550,
      '15,50': 1550,
      '15.50': 1550,
      '15.5': 1550,
      ' 7 ': 700,
      '0': 0,
      '0,01': 1,
      ',5': 50,
      '15,': 1500,
      '1.234,56': 123456,
      '1,234.56': 123456,
      '1234,56': 123456,
      '1234.56': 123456,
      '1.234.567': 123456700,
      '1,234,567.89': 123456789,
      "1'234.50": 123450,
      '1’234,50': 123450,
      '€ 15,00': 1500,
      '15,00 €': 1500,
      '15 EUR': 1500,
      '€15.00': 1500,
      '1${nbsp}234,56': 123456,
      '': null,
      '   ': null,
      '€': null,
      'abc': null,
      '12a': null,
      '1e5': null,
      '-5': null,
      '-5,00': null,
      '+5': null,
      '15,555': null,
      '15.555,5': 1555550,
      '15,5555': null,
      '1,2,3': null,
      '12.34.567': null,
      '1.23.4': null,
      '1234.567': null,
      '.': null,
      ',,': null,
      '1,,5': null,
      '1234567890123': null,
    };
    for (final entry in cases.entries) {
      test('de "${entry.key}" → ${entry.value}', () {
        expect(de.parseMoneyToCents(entry.key), entry.value);
      });
    }

    test('a single separator before three digits depends on the locale', () {
      // German: "." groups thousands, "," is decimal → three decimals are rejected.
      expect(de.parseMoneyToCents('1.234'), 123400);
      expect(de.parseMoneyToCents('1,234'), isNull);
      // English: the other way round.
      expect(en.parseMoneyToCents('1,234'), 123400);
      expect(en.parseMoneyToCents('1.234'), isNull);
      // With both separators the last one is always the decimal separator.
      expect(en.parseMoneyToCents('1.234,56'), 123456);
      expect(de.parseMoneyToCents('1,234.56'), 123456);
    });

    test('English accepts the German decimal comma', () {
      expect(en.parseMoneyToCents('15,50'), 1550);
      expect(en.parseMoneyToCents('15,5'), 1550);
      expect(en.parseMoneyToCents('-1'), isNull);
    });
  });

  group('durations', () {
    test('durationHm rounds to minutes and appends the unit', () {
      expect(de.durationHm(7 * h + 45 * min), '7:45 h');
      expect(en.durationHm(7 * h + 45 * min), '7:45 h');
      expect(de.durationHm(0), '0:00 h');
      expect(de.durationHm(8 * h + 5 * min, unit: false), '8:05');
      expect(de.durationHm(7 * h + 44 * min + 30 * sec), '7:45 h');
      expect(de.durationHm(7 * h + 44 * min + 29 * sec), '7:44 h');
      expect(de.durationHm(172 * h + 30 * min), '172:30 h');
      expect(de.durationHm(-30 * min), '-0:30 h');
    });

    test('durationClock shows h:mm:ss with truncated seconds', () {
      expect(de.durationClock(3 * h + 11 * min + 42 * sec), '3:11:42');
      expect(de.durationClock(3 * h + 11 * min + 42 * sec + 999), '3:11:42');
      expect(de.durationClock(0), '0:00:00');
      expect(de.durationClock(25 * h), '25:00:00');
      expect(de.durationClock(-5 * sec), '-0:00:05');
      expect(de.durationClock(-999), '0:00:00');
    });

    test('hoursDecimal uses locale decimals and rounds half-up to 1/100 h', () {
      expect(de.hoursDecimal(7 * h + 45 * min), '7,75');
      expect(en.hoursDecimal(7 * h + 45 * min), '7.75');
      expect(de.hoursDecimal(8 * h), '8');
      expect(de.hoursDecimal(18 * h + 30 * min), '18,5');
      expect(de.hoursDecimal(7 * h + 20 * min), '7,33');
      expect(de.hoursDecimal(8 * h, minFractionDigits: 2), '8,00');
      expect(de.hoursDecimal(1234 * h), '1.234');
      // 0.005 h = 18 s is the rounding threshold.
      expect(de.hoursDecimal(18 * sec), '0,01');
      expect(de.hoursDecimal(17 * sec), '0');
    });

    test('hours and minutes with units', () {
      expect(de.hours(18 * h + 30 * min), '18,5 h');
      expect(en.hours(172 * h + 30 * min), '172.5 h');
      expect(de.minutes(30), '30 min');
      expect(en.minutes(1500), '1,500 min');
    });

    test('durationSpoken is a readable sentence', () {
      expect(de.durationSpoken(7 * h + 45 * min), '7 Stunden 45 Minuten');
      expect(en.durationSpoken(7 * h + 45 * min), '7 hours 45 minutes');
      expect(de.durationSpoken(1 * h + 1 * min), '1 Stunde 1 Minute');
      expect(en.durationSpoken(1 * h), '1 hour');
      expect(en.durationSpoken(3 * h), '3 hours');
      expect(de.durationSpoken(45 * min), '45 Minuten');
      expect(en.durationSpoken(0), '0 minutes');
    });
  });

  group('numbers', () {
    test('integer, decimal and percent', () {
      expect(de.integer(1234), '1.234');
      expect(en.integer(1234), '1,234');
      expect(de.decimal(2.5), '2,5');
      expect(en.decimal(2.5, minFractionDigits: 2), '2.50');
      expect(plain(de.percent(0.8)), '80 %');
      expect(en.percent(0.8), '80%');
    });
  });

  group('times', () {
    test('24-hour format', () {
      expect(de.time(wed), '08:02');
      expect(en24.time(wed), '08:02');
      expect(de.time(DateTime(2026, 9, 30, 16, 15)), '16:15');
    });

    test('12-hour format follows the system setting in every language', () {
      expect(plain(en.time(wed)), '8:02 AM');
      expect(plain(en.time(DateTime(2026, 9, 30, 16, 15))), '4:15 PM');
      final de12 = Fmt(const Locale('de'), use24HourFormat: false);
      expect(plain(de12.time(DateTime(2026, 9, 30, 16, 15))), '4:15 PM');
    });

    test('clockTime formats a ClockTime', () {
      expect(de.clockTime((hour: 8, minute: 5)), '08:05');
      expect(plain(en.clockTime((hour: 0, minute: 30))), '12:30 AM');
    });

    test('timeRange marks shifts that end on a later day', () {
      expect(
        de.timeRange(DateTime(2026, 9, 30, 8), DateTime(2026, 9, 30, 16, 15)),
        '08:00–16:15',
      );
      expect(
        de.timeRange(DateTime(2026, 9, 30, 18), DateTime(2026, 10, 1, 2)),
        '18:00–02:00$nbsp+1',
      );
      // Across the end of DST (25 Oct 2026) the day count stays calendar-based.
      expect(
        de.timeRange(DateTime(2026, 10, 24, 22), DateTime(2026, 10, 25, 6)),
        '22:00–06:00$nbsp+1',
      );
    });
  });

  group('parseTime', () {
    final valid = <String, ClockTime>{
      '0815': (hour: 8, minute: 15),
      '815': (hour: 8, minute: 15),
      '8:15': (hour: 8, minute: 15),
      '08:15': (hour: 8, minute: 15),
      '08.15': (hour: 8, minute: 15),
      '8,15': (hour: 8, minute: 15),
      '8h15': (hour: 8, minute: 15),
      '8 15': (hour: 8, minute: 15),
      '8': (hour: 8, minute: 0),
      '08': (hour: 8, minute: 0),
      '8h': (hour: 8, minute: 0),
      '8 Uhr': (hour: 8, minute: 0),
      '16': (hour: 16, minute: 0),
      '1630': (hour: 16, minute: 30),
      '0': (hour: 0, minute: 0),
      '0000': (hour: 0, minute: 0),
      '2359': (hour: 23, minute: 59),
      ' 23:59 ': (hour: 23, minute: 59),
      '8:15 pm': (hour: 20, minute: 15),
      '8:15 PM': (hour: 20, minute: 15),
      '8:15\u202FPM': (hour: 20, minute: 15),
      '8pm': (hour: 20, minute: 0),
      '8p': (hour: 20, minute: 0),
      '8 a.m.': (hour: 8, minute: 0),
      '12 am': (hour: 0, minute: 0),
      '12:30 pm': (hour: 12, minute: 30),
    };
    for (final entry in valid.entries) {
      test('"${entry.key}" → ${entry.value}', () {
        expect(de.parseTime(entry.key), entry.value);
      });
    }

    for (final input in [
      '',
      '   ',
      'abc',
      '24',
      '2400',
      '24:00',
      '8:60',
      '860',
      '12345',
      '8:5',
      '8:155',
      '-8',
      '13 pm',
      '0 am',
      '8::15',
      '8:15:00',
    ]) {
      test('"$input" is rejected', () {
        expect(de.parseTime(input), isNull);
      });
    }

    test('formatted times parse back', () {
      for (final t in [
        (hour: 0, minute: 0),
        (hour: 8, minute: 2),
        (hour: 12, minute: 0),
        (hour: 23, minute: 59),
      ]) {
        expect(de.parseTime(de.clockTime(t)), t);
        expect(en.parseTime(en.clockTime(t)), t);
      }
    });
  });

  group('dates', () {
    test('German', () {
      expect(de.weekdayShort(wed), 'Mi');
      expect(de.weekdayLong(wed), 'Mittwoch');
      expect(de.dayOfMonth(wed), '30');
      expect(de.dayMonth(wed), '30. Sep');
      expect(de.dateShort(wed), 'Mi 30. Sep');
      expect(de.dateNumeric(DateTime(2026, 1, 1)), '01.01.2026');
      expect(de.dateNumeric(wed), '30.09.2026');
      expect(de.dateMedium(wed), 'Mi., 30. Sept. 2026');
      expect(de.dateLong(wed), 'Mittwoch, 30. September 2026');
      expect(de.monthYear(wed), 'September 2026');
      expect(de.monthName(DateTime(2026, 3)), 'März');
      expect(de.monthShort(DateTime(2026, 3)), 'Mär');
      expect(de.year(wed), '2026');
      expect(de.todayTitle(wed), 'Heute, Mi 30. Sep');
      expect(
        de.dateRangeShort(DateTime(2026, 9, 28), DateTime(2026, 10, 4)),
        '28. Sep – 4. Okt',
      );
    });

    test('English', () {
      expect(en.weekdayShort(wed), 'Wed');
      expect(en.weekdayLong(wed), 'Wednesday');
      expect(en.dayOfMonth(wed), '30');
      expect(en.dayMonth(wed), '30 Sep');
      expect(en.dateShort(wed), 'Wed 30 Sep');
      expect(en.dateNumeric(wed), '9/30/2026');
      expect(Fmt(const Locale('en', 'GB')).dateNumeric(wed), '30/09/2026');
      expect(en.dateMedium(wed), 'Wed, Sep 30, 2026');
      expect(en.dateLong(wed), 'Wednesday, September 30, 2026');
      expect(en.monthYear(wed), 'September 2026');
      expect(en.monthShort(wed), 'Sep');
      expect(en.todayTitle(wed), 'Today, Wed 30 Sep');
      expect(
        en.dateRangeShort(DateTime(2026, 9, 28), DateTime(2026, 10, 4)),
        '28 Sep – 4 Oct',
      );
    });
  });

  group('instances', () {
    test('are cached per locale and 12/24-hour setting', () {
      expect(identical(Fmt(const Locale('de')), de), isTrue);
      expect(
        identical(Fmt(const Locale('en'), use24HourFormat: false), en),
        isTrue,
      );
      expect(identical(en, en24), isFalse);
    });

    test('unsupported languages fall back to English texts', () {
      final fr = Fmt(const Locale('fr'));
      expect(fr.minutes(5), '5 min');
      expect(fr.todayTitle(wed), startsWith('Today, '));
      expect(fr.decimalSeparator, ',');
    });

    testWidgets('Fmt.of reads locale and 24-hour setting from context', (
      tester,
    ) async {
      late Fmt fmt;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(alwaysUse24HourFormat: false),
          child: Localizations(
            locale: const Locale('en'),
            delegates: GlobalMaterialLocalizations.delegates,
            child: Builder(
              builder: (context) {
                fmt = Fmt.of(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      expect(fmt.use24HourFormat, isFalse);
      expect(fmt.locale, const Locale('en'));
      expect(plain(fmt.time(wed)), '8:02 AM');
    });
  });
}
