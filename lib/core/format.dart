import 'dart:async' show unawaited;

import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';

/// A wall-clock time of day without a date (e.g. a parsed "08:15").
typedef ClockTime = ({int hour, int minute});

/// Locale-aware formatting and parsing of money, durations, times and dates.
///
/// The single place where numbers, dates and times become text (CLAUDE.md).
/// Obtain one per build with [Fmt.of]; instances are cached per locale and
/// 12/24-hour setting, so this is cheap.
///
/// ```dart
/// final fmt = Fmt.of(context);
/// Text(fmt.money(123456)); // "1.234,56 €" (de) / "€1,234.56" (en)
/// ```
///
/// Money is always `int` cents in EUR. Durations are `int` milliseconds.
/// Dates and times are local [DateTime]s.
class Fmt {
  /// A formatter for [locale] (language plus optional region, e.g. `de_AT`).
  ///
  /// [use24HourFormat] follows the system setting
  /// (`MediaQuery.alwaysUse24HourFormatOf`).
  factory Fmt(Locale locale, {bool use24HourFormat = true}) =>
      _cache.putIfAbsent((
        locale.toString(),
        use24HourFormat,
      ), () => Fmt._(locale, use24HourFormat));

  Fmt._(this.locale, this.use24HourFormat)
    : localeName = Intl.canonicalizedLocale(locale.toString()),
      _l10n = lookupAppLocalizations(_supportedOrEnglish(locale)) {
    _ensureDateSymbols();
  }

  /// The formatter for the app locale and the system 12/24-hour setting.
  factory Fmt.of(BuildContext context) => Fmt(
    Localizations.localeOf(context),
    use24HourFormat: MediaQuery.maybeAlwaysUse24HourFormatOf(context) ?? true,
  );

  static final Map<(String, bool), Fmt> _cache = <(String, bool), Fmt>{};
  static bool _dateSymbolsReady = false;

  /// The locale this formatter was created for.
  final Locale locale;

  /// The canonical intl locale name, e.g. `de_DE`.
  final String localeName;

  /// Whether times are shown as 24-hour clock.
  final bool use24HourFormat;

  final AppLocalizations _l10n;

  bool get _isGerman => locale.languageCode == 'de';
  bool get _isEnglish => locale.languageCode == 'en';

  // ---------------------------------------------------------------- money --

  late final NumberFormat _money = NumberFormat.currency(
    locale: localeName,
    name: 'EUR',
    symbol: '€',
    decimalDigits: 2,
  );
  late final NumberFormat _moneyInput = NumberFormat.decimalPatternDigits(
    locale: localeName,
    decimalDigits: 2,
  );
  late final NumberFormat _integer = NumberFormat.decimalPattern(localeName);
  late final NumberFormat _percent = NumberFormat.percentPattern(localeName);
  final Map<(int, int), NumberFormat> _decimals = <(int, int), NumberFormat>{};

  /// The currency symbol ("€").
  String get currencySymbol => '€';

  /// Whether the currency symbol precedes the number ("€1.00" in English,
  /// "1,00 €" in German).
  bool get currencySymbolFirst =>
      _money.positivePrefix.contains(currencySymbol);

  /// The locale's decimal separator ("," in German, "." in English).
  String get decimalSeparator => _integer.symbols.DECIMAL_SEP;

  /// The locale's grouping separator ("." in German, "," in English).
  String get groupSeparator => _integer.symbols.GROUP_SEP;

  /// `123456` → "1.234,56 €" (de) / "€1,234.56" (en).
  ///
  /// The cents are converted to a double for display only; that is exact to
  /// the cent for every realistic amount (< 2^53 / 100).
  String money(int cents) => _money.format(cents / 100);

  /// Editable amount without symbol: `123456` → "1.234,56" / "1,234.56".
  /// [parseMoneyToCents] reads it back.
  String moneyInput(int cents) => _moneyInput.format(cents / 100);

  /// Hourly rate: `1500` → "15,00 €/h" / "€15.00/h".
  String rate(int centsPerHour) => _l10n.formatRatePerHour(money(centsPerHour));

  /// Parses a user-entered amount into cents, or `null` if it is not a valid,
  /// non-negative amount with at most two decimals.
  ///
  /// Accepts both `,` and `.` as decimal separator ("15,50", "15.50"),
  /// thousands separators ("1.234,56", "1,234.56", "1'234.56"), a currency
  /// symbol ("15 €", "€15") and surrounding whitespace. A single separator
  /// followed by exactly three digits ("1.234") is read as a thousands
  /// separator unless it is this locale's decimal separator, in which case
  /// the input has too many decimals and is rejected.
  int? parseMoneyToCents(String input) {
    var s = input.replaceAll(RegExp('€|eur', caseSensitive: false), '');
    s = s.replaceAll(RegExp(r'\s'), '');
    if (s.isEmpty ||
        !RegExp(r"^[0-9.,'’]+$").hasMatch(s) ||
        !s.contains(RegExp('[0-9]'))) {
      return null;
    }

    int? decimalIndex;
    final lastDot = s.lastIndexOf('.');
    final lastComma = s.lastIndexOf(',');
    if (lastDot >= 0 && lastComma >= 0) {
      decimalIndex = lastDot > lastComma ? lastDot : lastComma;
    } else if (lastDot >= 0 || lastComma >= 0) {
      final sep = lastDot >= 0 ? '.' : ',';
      final index = lastDot >= 0 ? lastDot : lastComma;
      final count = sep.allMatches(s).length;
      if (count == 1) {
        final after = s.length - index - 1;
        final before = s.substring(0, index).replaceAll(RegExp(r"['’]"), '');
        final looksLikeGrouping =
            after == 3 && before.isNotEmpty && before.length <= 3;
        if (!looksLikeGrouping || sep == decimalSeparator) decimalIndex = index;
      }
      // count > 1: the separator groups thousands ("1.234.567").
    }

    final intPart = decimalIndex == null ? s : s.substring(0, decimalIndex);
    final fracPart = decimalIndex == null ? '' : s.substring(decimalIndex + 1);
    if (!RegExp(r'^[0-9]{0,2}$').hasMatch(fracPart)) return null;

    final groups = intPart.split(RegExp(r"[.,'’]"));
    if (groups.length > 1) {
      if (groups.first.isEmpty || groups.first.length > 3) return null;
      if (groups.skip(1).any((g) => g.length != 3)) return null;
    }
    final intDigits = groups.join();
    if (intDigits.isEmpty && fracPart.isEmpty) return null;
    if (intDigits.length > 12) return null;

    final whole = intDigits.isEmpty ? 0 : int.parse(intDigits);
    final fraction = fracPart.isEmpty
        ? 0
        : int.parse(fracPart.padRight(2, '0'));
    return whole * 100 + fraction;
  }

  // ------------------------------------------------------------ durations --

  /// Worked time as hours and minutes, rounded half-up to the nearest minute:
  /// `27900000` → "7:45 h" (or "7:45" when [unit] is false).
  String durationHm(int ms, {bool unit = true}) {
    final totalMinutes = _roundedMinutes(ms);
    final text =
        '${ms < 0 && totalMinutes > 0 ? '-' : ''}'
        '${totalMinutes ~/ 60}:${_two(totalMinutes % 60)}';
    return unit ? _l10n.formatHours(text) : text;
  }

  /// Running stopwatch: `11502000` → "3:11:42" (seconds truncated).
  String durationClock(int ms) {
    final totalSeconds = ms.abs() ~/ 1000;
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    return '${ms < 0 && totalSeconds > 0 ? '-' : ''}$h:${_two(m)}:${_two(s)}';
  }

  /// Decimal hours, rounded half-up to 1/100 h: `27900000` → "7,75" / "7.75".
  ///
  /// Trailing zeros are dropped down to [minFractionDigits] ("8", "18,5");
  /// pass `minFractionDigits: 2` for fixed columns such as exports ("8,00").
  String hoursDecimal(
    int ms, {
    int minFractionDigits = 0,
    int maxFractionDigits = 2,
  }) {
    final hundredths = (ms.abs() * 100 + 1800000) ~/ 3600000;
    final value = (ms < 0 ? -hundredths : hundredths) / 100;
    return decimal(
      value,
      minFractionDigits: minFractionDigits,
      maxFractionDigits: maxFractionDigits,
    );
  }

  /// Decimal hours with unit: "18,5 h" / "18.5 h".
  String hours(int ms) => _l10n.formatHours(hoursDecimal(ms));

  /// Whole minutes with unit: `30` → "30 min".
  String minutes(int minutes) => _l10n.formatMinutes(integer(minutes));

  /// Duration for screen readers, rounded to minutes:
  /// "7 Stunden 45 Minuten" / "7 hours 45 minutes".
  String durationSpoken(int ms) {
    final total = _roundedMinutes(ms);
    final h = total ~/ 60;
    final m = total % 60;
    if (h == 0) return _l10n.durationSpokenMinutes(m);
    if (m == 0) return _l10n.durationSpokenHours(h);
    return _l10n.durationSpokenHoursMinutes(
      _l10n.durationSpokenHours(h),
      _l10n.durationSpokenMinutes(m),
    );
  }

  // -------------------------------------------------------------- numbers --

  /// Grouped integer: `1234` → "1.234" / "1,234".
  String integer(int value) => _integer.format(value);

  /// Decimal number with locale separators.
  String decimal(
    num value, {
    int minFractionDigits = 0,
    int maxFractionDigits = 2,
  }) {
    final format = _decimals.putIfAbsent(
      (minFractionDigits, maxFractionDigits),
      () {
        return NumberFormat.decimalPattern(localeName)
          ..minimumFractionDigits = minFractionDigits
          ..maximumFractionDigits = maxFractionDigits;
      },
    );
    return format.format(value);
  }

  /// Percentage of a ratio: `0.8` → "80 %" / "80%".
  String percent(double ratio) => _percent.format(ratio);

  // ---------------------------------------------------------------- times --

  late final DateFormat _time = use24HourFormat
      ? DateFormat.Hm(localeName)
      : _twelveHourFormat();

  DateFormat _twelveHourFormat() {
    final natural = DateFormat.jm(localeName);
    return (natural.pattern ?? '').contains('a')
        ? natural
        : DateFormat('h:mm a', localeName);
  }

  /// Local time of day, 24 h ("08:02") or 12 h ("8:02 AM") per system setting.
  String time(DateTime local) => _time.format(local);

  /// A [ClockTime] formatted like [time].
  String clockTime(ClockTime t) =>
      _time.format(DateTime(2000, 1, 1, t.hour, t.minute));

  /// "08:00–16:15", with " +1" when [end] falls on a later calendar day.
  String timeRange(DateTime start, DateTime end) {
    final days = _calendarDaysBetween(start, end);
    final suffix = days > 0 ? '\u00A0+$days' : '';
    return '${time(start)}–${time(end)}$suffix';
  }

  /// Parses a typed time of day, or returns `null`.
  ///
  /// Accepts "0815", "815", "8", "16", "8:15", "08.15", "8,15", "8h15",
  /// "8 Uhr" and 12-hour input such as "8:15 pm" or "8p".
  ClockTime? parseTime(String input) {
    var s = input.trim().toLowerCase();
    s = s.replaceFirst(RegExp(r'\s*uhr$'), '');
    int? pmOffset;
    final meridiem = RegExp(r'^(.*?)\s*(a\.?\s?m\.?|p\.?\s?m\.?|a|p)$')
        .firstMatch(s);
    if (meridiem != null) {
      s = meridiem.group(1)!;
      pmOffset = meridiem.group(2)!.startsWith('p') ? 12 : 0;
    }
    s = s.trim();

    int hour;
    var minute = 0;
    final separated = RegExp(r'^(\d{1,2})\s*[:.,h\s]\s*(\d{2})$').firstMatch(s);
    final hourOnly = RegExp(r'^(\d{1,2})\s*[:.,h]?$').firstMatch(s);
    if (separated != null) {
      hour = int.parse(separated.group(1)!);
      minute = int.parse(separated.group(2)!);
    } else if (hourOnly != null) {
      hour = int.parse(hourOnly.group(1)!);
    } else if (RegExp(r'^\d{3,4}$').hasMatch(s)) {
      hour = int.parse(s.substring(0, s.length - 2));
      minute = int.parse(s.substring(s.length - 2));
    } else {
      return null;
    }

    if (pmOffset != null) {
      if (hour < 1 || hour > 12) return null;
      hour = hour % 12 + pmOffset;
    }
    if (hour > 23 || minute > 59) return null;
    return (hour: hour, minute: minute);
  }

  // ---------------------------------------------------------------- dates --

  late final DateFormat _weekdayShort = DateFormat('ccc', localeName);
  late final DateFormat _weekdayLong = DateFormat('cccc', localeName);
  late final DateFormat _day = DateFormat.d(localeName);
  late final DateFormat _dayMonth = _isGerman
      ? DateFormat('d. LLL', localeName)
      : _isEnglish
      ? DateFormat('d LLL', localeName)
      : DateFormat.MMMd(localeName);
  late final DateFormat _dateShort = _isGerman
      ? DateFormat('ccc d. LLL', localeName)
      : _isEnglish
      ? DateFormat('ccc d LLL', localeName)
      : DateFormat.MMMEd(localeName);
  late final DateFormat _dateNumeric = _isGerman
      ? DateFormat('dd.MM.yyyy', localeName)
      : DateFormat.yMd(localeName);
  late final DateFormat _dateMedium = DateFormat.yMMMEd(localeName);
  late final DateFormat _dateLong = DateFormat.yMMMMEEEEd(localeName);
  late final DateFormat _monthYear = DateFormat.yMMMM(localeName);
  late final DateFormat _month = DateFormat('LLLL', localeName);
  late final DateFormat _monthShort = DateFormat('LLL', localeName);
  late final DateFormat _year = DateFormat.y(localeName);

  /// "Mi" / "Wed".
  String weekdayShort(DateTime date) => _weekdayShort.format(date);

  /// "Mittwoch" / "Wednesday".
  String weekdayLong(DateTime date) => _weekdayLong.format(date);

  /// Day of month: "30".
  String dayOfMonth(DateTime date) => _day.format(date);

  /// "30. Sep" / "30 Sep".
  String dayMonth(DateTime date) => _dayMonth.format(date);

  /// "Mi 30. Sep" / "Wed 30 Sep".
  String dateShort(DateTime date) => _dateShort.format(date);

  /// "30.09.2026" (de) / "9/30/2026" (en_US) / "30/09/2026" (en_GB).
  String dateNumeric(DateTime date) => _dateNumeric.format(date);

  /// "Mi., 30. Sept. 2026" / "Wed, Sep 30, 2026" (form fields).
  String dateMedium(DateTime date) => _dateMedium.format(date);

  /// "Mittwoch, 30. September 2026" (screen-reader labels).
  String dateLong(DateTime date) => _dateLong.format(date);

  /// "September 2026".
  String monthYear(DateTime date) => _monthYear.format(date);

  /// "September".
  String monthName(DateTime date) => _month.format(date);

  /// "Sep" (chart axes).
  String monthShort(DateTime date) => _monthShort.format(date);

  /// "2026".
  String year(DateTime date) => _year.format(date);

  /// Title of the Today screen: "Heute, Mi 30. Sep" / "Today, Wed 30 Sep".
  String todayTitle(DateTime date) => _l10n.formatToday(dateShort(date));

  /// "28. Sep – 4. Okt" / "28 Sep – 4 Oct".
  String dateRangeShort(DateTime start, DateTime end) =>
      '${dayMonth(start)} – ${dayMonth(end)}';

  // -------------------------------------------------------------- helpers --

  static String _two(int n) => n.toString().padLeft(2, '0');

  static int _roundedMinutes(int ms) => (ms.abs() + 30000) ~/ 60000;

  static int _calendarDaysBetween(DateTime a, DateTime b) {
    final da = DateTime.utc(a.year, a.month, a.day);
    final db = DateTime.utc(b.year, b.month, b.day);
    return db.difference(da).inDays;
  }

  static Locale _supportedOrEnglish(Locale locale) {
    final supported = AppLocalizations.supportedLocales.any(
      (l) => l.languageCode == locale.languageCode,
    );
    return supported ? Locale(locale.languageCode) : const Locale('en');
  }

  /// intl's date symbols are registered when Flutter loads the Material
  /// localizations. Trigger that once so formatting also works outside a
  /// widget tree (unit tests, notification texts).
  static void _ensureDateSymbols() {
    if (_dateSymbolsReady) return;
    unawaited(GlobalMaterialLocalizations.delegate.load(const Locale('en')));
    _dateSymbolsReady = true;
  }
}
