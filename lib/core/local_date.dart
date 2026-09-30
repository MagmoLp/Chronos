import 'package:clock/clock.dart';

/// A calendar date without a time of day or time zone.
///
/// All arithmetic runs on `DateTime.utc(y, m, d + n)`, so daylight-saving
/// transitions can never shift a date. Converting to an instant happens only
/// through [toLocalDateTime] / [startUtc], which build the local wall-clock
/// time with the `DateTime(y, m, d, h, min)` constructor.
final class LocalDate implements Comparable<LocalDate> {
  /// Creates a date; out-of-range values are normalised like [DateTime]
  /// (e.g. `LocalDate(2026, 1, 32)` is 1 Feb 2026).
  factory LocalDate(int year, int month, int day) {
    final d = DateTime.utc(year, month, day);
    return LocalDate._(d.year, d.month, d.day);
  }

  const LocalDate._(this.year, this.month, this.day);

  /// The calendar fields of [dateTime] as they are (local fields for a local
  /// [DateTime], UTC fields for a UTC one).
  factory LocalDate.fromDateTime(DateTime dateTime) =>
      LocalDate._(dateTime.year, dateTime.month, dateTime.day);

  /// The local calendar date (device time zone) on which [instant] falls.
  factory LocalDate.ofInstant(DateTime instant) =>
      LocalDate.fromDateTime(instant.toLocal());

  /// Today's local date according to [source] (defaults to the zone clock).
  factory LocalDate.today([Clock? source]) =>
      LocalDate.ofInstant((source ?? clock).now());

  /// Inverse of [key] (`20260930` → 30 Sep 2026).
  factory LocalDate.fromKey(int key) =>
      LocalDate(key ~/ 10000, (key ~/ 100) % 100, key % 100);

  /// Parses `yyyy-mm-dd`; throws [FormatException] on anything else.
  factory LocalDate.parse(String iso) {
    final result = tryParse(iso);
    if (result == null) throw FormatException('Invalid date', iso);
    return result;
  }

  /// Parses `yyyy-mm-dd`, returning `null` for malformed or impossible dates.
  static LocalDate? tryParse(String iso) {
    final match = _isoPattern.firstMatch(iso.trim());
    if (match == null) return null;
    final y = int.parse(match.group(1)!);
    final m = int.parse(match.group(2)!);
    final d = int.parse(match.group(3)!);
    final date = LocalDate(y, m, d);
    if (date.year != y || date.month != m || date.day != d) return null;
    return date;
  }

  static final RegExp _isoPattern = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

  /// Calendar year.
  final int year;

  /// Month, 1–12.
  final int month;

  /// Day of month, 1–31.
  final int day;

  /// Sortable integer key `yyyymmdd`, used for storage.
  int get key => year * 10000 + month * 100 + day;

  /// ISO weekday, 1 = Monday … 7 = Sunday.
  int get weekday => DateTime.utc(year, month, day).weekday;

  /// Number of days in this date's month.
  int get daysInMonth => DateTime.utc(year, month + 1, 0).day;

  /// This date plus [days] calendar days (negative values go back).
  LocalDate addDays(int days) => LocalDate(year, month, day + days);

  /// This date plus [months] months; the day is clamped to the month's end
  /// (31 Jan + 1 month = 28/29 Feb).
  LocalDate addMonths(int months) {
    final first = LocalDate(year, month + months, 1);
    final clampedDay = day > first.daysInMonth ? first.daysInMonth : day;
    return LocalDate._(first.year, first.month, clampedDay);
  }

  /// First day of this date's month.
  LocalDate get firstOfMonth => LocalDate._(year, month, 1);

  /// Last day of this date's month.
  LocalDate get lastOfMonth => LocalDate._(year, month, daysInMonth);

  /// Monday of this date's week (weeks start on Monday).
  LocalDate get startOfWeek => addDays(1 - weekday);

  /// Whole days from this date to [other] (positive if [other] is later).
  int daysUntil(LocalDate other) => DateTime.utc(
    other.year,
    other.month,
    other.day,
  ).difference(DateTime.utc(year, month, day)).inDays;

  /// Local wall-clock time on this date (device time zone).
  ///
  /// Built with the `DateTime(y, m, d, h, min)` constructor, so it is correct
  /// on daylight-saving days. A wall time that does not exist (02:30 on a
  /// spring-forward day) resolves to the instant one hour later; an ambiguous
  /// one resolves to the first occurrence.
  DateTime toLocalDateTime([int hour = 0, int minute = 0]) =>
      DateTime(year, month, day, hour, minute);

  /// The UTC instant at which this local day starts (local midnight).
  DateTime get startUtc => toLocalDateTime().toUtc();

  /// Whether this date is before [other].
  bool isBefore(LocalDate other) => key < other.key;

  /// Whether this date is after [other].
  bool isAfter(LocalDate other) => key > other.key;

  /// Whether this date is on or before [other].
  bool isOnOrBefore(LocalDate other) => key <= other.key;

  /// Whether this date is on or after [other].
  bool isOnOrAfter(LocalDate other) => key >= other.key;

  /// Earlier of [a] and [b].
  static LocalDate min(LocalDate a, LocalDate b) => a.key <= b.key ? a : b;

  /// Later of [a] and [b].
  static LocalDate max(LocalDate a, LocalDate b) => a.key >= b.key ? a : b;

  @override
  int compareTo(LocalDate other) => key.compareTo(other.key);

  @override
  bool operator ==(Object other) => other is LocalDate && other.key == key;

  @override
  int get hashCode => key.hashCode;

  /// ISO `yyyy-mm-dd`.
  String toIso8601String() {
    final y = year.toString().padLeft(4, '0');
    final m = month.toString().padLeft(2, '0');
    final d = day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  @override
  String toString() => toIso8601String();
}
