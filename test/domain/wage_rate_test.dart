import 'package:chronos/core/local_date.dart';
import 'package:chronos/domain/wage_rate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  WageRate rate(int id, LocalDate from, int cents) =>
      WageRate(id: id, jobId: 1, validFrom: from, centsPerHour: cents);

  final history = [
    rate(2, LocalDate(2026, 7, 1), 1600),
    rate(1, LocalDate(2026, 1, 1), 1500),
    rate(3, LocalDate(2026, 10, 1), 1390),
  ];

  test('empty history has no rate', () {
    expect(rateForDate(const [], LocalDate(2026, 9, 30)), isNull);
  });

  test('picks the latest rate on or before the date', () {
    expect(rateForDate(history, LocalDate(2026, 3, 1)), 1500);
    expect(rateForDate(history, LocalDate(2026, 6, 30)), 1500);
    expect(rateForDate(history, LocalDate(2026, 7, 1)), 1600);
    expect(rateForDate(history, LocalDate(2026, 9, 30)), 1600);
    expect(rateForDate(history, LocalDate(2026, 10, 1)), 1390);
    expect(rateForDate(history, LocalDate(2030, 1, 1)), 1390);
  });

  test('dates before the first rate use the earliest rate', () {
    expect(rateForDate(history, LocalDate(2025, 12, 31)), 1500);
  });

  test('model basics', () {
    final a = rate(1, LocalDate(2026, 1, 1), 1500);
    expect(a, rate(1, LocalDate(2026, 1, 1), 1500));
    expect(a.hashCode, rate(1, LocalDate(2026, 1, 1), 1500).hashCode);
    expect(a.copyWith(centsPerHour: 1600).centsPerHour, 1600);
    expect(
      a.copyWith(validFrom: LocalDate(2026, 2, 1)).validFrom,
      LocalDate(2026, 2, 1),
    );
    expect(a.copyWith(), a);
    expect(a.toString(), contains('1500'));
  });
}
