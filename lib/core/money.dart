import 'time.dart';

/// Money is always an `int` amount of cents (EUR). Never a `double`.
///
/// The single rounding rule of the app: half-up in pure integer arithmetic.

/// Wage earned for [workedMs] at [centsPerHour], rounded half-up to a cent:
/// `(workedMs × centsPerHour + 1 800 000) ~/ 3 600 000`.
///
/// Non-positive [workedMs] earns nothing. The multiplication is split into
/// whole hours and the remainder, so it cannot overflow for any realistic
/// (or unrealistic) duration or rate.
int earningsCents(int workedMs, int centsPerHour) {
  if (centsPerHour < 0) {
    throw ArgumentError.value(centsPerHour, 'centsPerHour', 'negative');
  }
  if (workedMs <= 0 || centsPerHour == 0) return 0;
  final wholeHours = workedMs ~/ msPerHour;
  final rest = workedMs % msPerHour;
  return wholeHours * centsPerHour +
      (rest * centsPerHour + msPerHour ~/ 2) ~/ msPerHour;
}

/// Sum of [values] (cents).
int sumCents(Iterable<int> values) =>
    values.fold(0, (sum, value) => sum + value);

/// Average hourly amount for [cents] earned over [workedMs], rounded half-up;
/// `null` when nothing was worked.
int? averageHourlyCents(int cents, int workedMs) {
  if (workedMs <= 0) return null;
  final numerator = cents * msPerHour;
  if (numerator >= 0) return (numerator + workedMs ~/ 2) ~/ workedMs;
  return -((-numerator + workedMs ~/ 2) ~/ workedMs);
}

/// Converts a legacy euro amount stored as `double` (v1) to cents, rounding
/// half-up on the decimal representation (so 12.345 → 1235, not 1234).
///
/// Throws [ArgumentError] for NaN, infinite or negative values.
int centsFromEuros(double euros) {
  if (euros.isNaN || euros.isInfinite || euros < 0) {
    throw ArgumentError.value(euros, 'euros', 'not a valid amount');
  }
  // Six decimals are far beyond double noise for money-sized values.
  final fixed = euros.toStringAsFixed(6);
  final dot = fixed.indexOf('.');
  final whole = int.parse(fixed.substring(0, dot));
  final fraction = fixed.substring(dot + 1); // exactly six digits
  final cents = int.parse(fraction.substring(0, 2));
  final roundUp = int.parse(fraction[2]) >= 5;
  return whole * 100 + cents + (roundUp ? 1 : 0);
}
