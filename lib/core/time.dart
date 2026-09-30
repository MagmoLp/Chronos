import 'local_date.dart';

/// Milliseconds per second.
const int msPerSecond = 1000;

/// Milliseconds per minute.
const int msPerMinute = 60 * msPerSecond;

/// Milliseconds per hour.
const int msPerHour = 60 * msPerMinute;

/// A UTC [DateTime] from epoch milliseconds (the storage format).
DateTime utcFromMs(int ms) =>
    DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);

/// A UTC [DateTime] from nullable epoch milliseconds.
DateTime? utcFromMsOrNull(int? ms) => ms == null ? null : utcFromMs(ms);

/// UTC offset in minutes of the device time zone at [instant].
int offsetMinutesAt(DateTime instant) =>
    instant.toLocal().timeZoneOffset.inMinutes;

/// Local calendar date (device time zone) of [instant].
LocalDate localDateOf(DateTime instant) => LocalDate.ofInstant(instant);

/// Combines a local [date] and wall-clock [hour]:[minute] into a UTC instant.
///
/// With [nextDay] the time is taken on the following calendar day (a shift
/// that ends after midnight). Uses `DateTime(y, m, d + n, h, min)`, never
/// `add(Duration(days: n))`, so the result is right on DST switch days.
DateTime combineLocal(
  LocalDate date,
  int hour,
  int minute, {
  bool nextDay = false,
}) => DateTime(
  date.year,
  date.month,
  date.day + (nextDay ? 1 : 0),
  hour,
  minute,
).toUtc();

/// Monday of the week containing [date].
LocalDate weekStart(LocalDate date) => date.startOfWeek;

/// Whether [date] is an EU daylight-saving switch day (last Sunday of March
/// or October), independent of the device time zone.
bool isEuDstSwitchDay(LocalDate date) =>
    (date.month == 3 || date.month == 10) &&
    date.weekday == DateTime.sunday &&
    date.day + 7 > date.daysInMonth;

/// Whether the device time zone changes its UTC offset during [date].
bool isLocalOffsetChangeDay(LocalDate date) =>
    date.toLocalDateTime().timeZoneOffset !=
    date.addDays(1).toLocalDateTime().timeZoneOffset;

/// Whether [date] is a daylight-saving switch day (EU rule or device zone).
bool isDstSwitchDay(LocalDate date) =>
    isEuDstSwitchDay(date) || isLocalOffsetChangeDay(date);

/// A half-open range of local calendar dates `[start, endExclusive)`.
final class LocalDateRange {
  /// Creates the range `[start, endExclusive)`.
  const LocalDateRange(this.start, this.endExclusive);

  /// The single day [date].
  factory LocalDateRange.day(LocalDate date) =>
      LocalDateRange(date, date.addDays(1));

  /// The Monday-based week containing [anyDay].
  factory LocalDateRange.week(LocalDate anyDay) {
    final monday = anyDay.startOfWeek;
    return LocalDateRange(monday, monday.addDays(7));
  }

  /// The calendar month [month] of [year].
  factory LocalDateRange.month(int year, int month) {
    final first = LocalDate(year, month, 1);
    return LocalDateRange(first, first.addMonths(1));
  }

  /// The calendar month containing [anyDay].
  factory LocalDateRange.monthOf(LocalDate anyDay) =>
      LocalDateRange.month(anyDay.year, anyDay.month);

  /// The calendar year [year].
  factory LocalDateRange.year(int year) =>
      LocalDateRange(LocalDate(year, 1, 1), LocalDate(year + 1, 1, 1));

  /// First day of the range (inclusive).
  final LocalDate start;

  /// First day after the range (exclusive).
  final LocalDate endExclusive;

  /// Last day of the range (inclusive).
  LocalDate get endInclusive => endExclusive.addDays(-1);

  /// Number of days in the range.
  int get dayCount => start.daysUntil(endExclusive);

  /// Every day of the range in order.
  Iterable<LocalDate> get days sync* {
    for (var d = start; d.isBefore(endExclusive); d = d.addDays(1)) {
      yield d;
    }
  }

  /// Whether [date] lies inside the range.
  bool contains(LocalDate date) =>
      date.isOnOrAfter(start) && date.isBefore(endExclusive);

  /// UTC instant of local midnight at [start].
  DateTime get startUtc => start.startUtc;

  /// UTC instant of local midnight at [endExclusive].
  DateTime get endUtc => endExclusive.startUtc;

  /// Whether the local date of [instant] lies inside the range.
  bool containsInstant(DateTime instant) =>
      contains(LocalDate.ofInstant(instant));

  @override
  bool operator ==(Object other) =>
      other is LocalDateRange &&
      other.start == start &&
      other.endExclusive == endExclusive;

  @override
  int get hashCode => Object.hash(start, endExclusive);

  @override
  String toString() => '[$start, $endExclusive)';
}
