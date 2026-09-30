import '../core/local_date.dart';
import '../core/money.dart';
import '../core/time.dart';
import 'pay.dart';
import 'shift.dart';

/// Figures for the "Heute" card.
///
/// Holds finished shifts of [date] plus the running shift. Nothing ticks
/// here: the UI calls [earnedCentsAt] / [workedMsAt] with the current time.
final class TodaySummary {
  /// Creates a summary.
  const TodaySummary({
    required this.date,
    required this.doneShifts,
    this.running,
  });

  /// The local day.
  final LocalDate date;

  /// Finished, non-deleted shifts starting on [date], newest first.
  final List<Shift> doneShifts;

  /// The running shift (whatever day it started), if any.
  final Shift? running;

  /// Wage of today's finished shifts.
  int get doneEarnedCents => sumCents(doneShifts.map((s) => s.earnedCents));

  /// Worked time of today's finished shifts.
  int get doneWorkedMs => doneShifts.fold(0, (sum, s) => sum + s.workedMs);

  /// Tips of today's finished shifts.
  int get doneTipsCents => sumCents(doneShifts.map((s) => s.tipsCents));

  /// Number of finished shifts today.
  int get doneCount => doneShifts.length;

  /// Whether something was or is being worked today.
  bool get hasWork => doneShifts.isNotEmpty || running != null;

  /// "Heute verdient": today's finished wage plus the running shift at [now].
  int earnedCentsAt(DateTime now) =>
      doneEarnedCents +
      (running == null ? 0 : liveValues(running!, now).earnedCents);

  /// Today's worked time plus the running shift at [now].
  int workedMsAt(DateTime now) =>
      doneWorkedMs + (running == null ? 0 : liveValues(running!, now).workedMs);

  @override
  bool operator ==(Object other) =>
      other is TodaySummary &&
      other.date == date &&
      other.running == running &&
      _listEquals(other.doneShifts, doneShifts);

  @override
  int get hashCode => Object.hash(date, running, Object.hashAll(doneShifts));

  @override
  String toString() =>
      'TodaySummary($date, $doneCount done, $doneEarnedCents ct'
      '${running == null ? '' : ', running'})';
}

/// Builds the [TodaySummary] for [today] from [shifts].
TodaySummary computeTodaySummary({
  required LocalDate today,
  required Iterable<Shift> shifts,
  Shift? running,
}) {
  final done = [
    for (final s in shifts)
      if (s.isDone && !s.isDeleted && s.localStartDate == today) s,
  ]..sort(_newestFirst);
  return TodaySummary(
    date: today,
    doneShifts: List.unmodifiable(done),
    running: running != null && running.isRunning && !running.isDeleted
        ? running
        : null,
  );
}

/// Totals of a date range (e.g. "Diese Woche · 18,5 h · 256,75 €").
final class PeriodSummary {
  /// Creates a summary.
  const PeriodSummary({
    required this.range,
    required this.shiftCount,
    required this.workedMs,
    required this.earnedCents,
    required this.tipsCents,
    this.running,
  });

  /// The days covered.
  final LocalDateRange range;

  /// Finished shifts in the range.
  final int shiftCount;

  /// Worked time of finished shifts.
  final int workedMs;

  /// Wage of finished shifts.
  final int earnedCents;

  /// Tips of finished shifts.
  final int tipsCents;

  /// The running shift if it started inside the range.
  final Shift? running;

  /// Wage including the running shift at [now].
  int earnedCentsAt(DateTime now) =>
      earnedCents +
      (running == null ? 0 : liveValues(running!, now).earnedCents);

  /// Worked time including the running shift at [now].
  int workedMsAt(DateTime now) =>
      workedMs + (running == null ? 0 : liveValues(running!, now).workedMs);

  @override
  bool operator ==(Object other) =>
      other is PeriodSummary &&
      other.range == range &&
      other.shiftCount == shiftCount &&
      other.workedMs == workedMs &&
      other.earnedCents == earnedCents &&
      other.tipsCents == tipsCents &&
      other.running == running;

  @override
  int get hashCode =>
      Object.hash(range, shiftCount, workedMs, earnedCents, tipsCents, running);

  @override
  String toString() =>
      'PeriodSummary($range, $shiftCount, ${workedMs}ms, $earnedCents ct)';
}

/// Totals of finished, non-deleted shifts whose local start date is in
/// [range]; [running] is kept if it started inside the range.
PeriodSummary computePeriodSummary(
  LocalDateRange range,
  Iterable<Shift> shifts, {
  Shift? running,
}) {
  var count = 0;
  var worked = 0;
  var earned = 0;
  var tips = 0;
  for (final s in shifts) {
    if (!s.isDone || s.isDeleted || !range.contains(s.localStartDate)) continue;
    count++;
    worked += s.workedMs;
    earned += s.earnedCents;
    tips += s.tipsCents;
  }
  final keepRunning =
      running != null &&
      running.isRunning &&
      !running.isDeleted &&
      range.contains(running.localStartDate);
  return PeriodSummary(
    range: range,
    shiftCount: count,
    workedMs: worked,
    earnedCents: earned,
    tipsCents: tips,
    running: keepRunning ? running : null,
  );
}

/// "Offen": unpaid wage of finished shifts (+ running shift live).
final class OpenSummary {
  /// Creates a summary.
  const OpenSummary({
    required this.openCents,
    required this.shiftCount,
    required this.workedMs,
    required this.tipsCents,
    this.running,
  });

  /// Nothing open.
  static const OpenSummary empty = OpenSummary(
    openCents: 0,
    shiftCount: 0,
    workedMs: 0,
    tipsCents: 0,
  );

  /// Unpaid wage of finished shifts.
  final int openCents;

  /// Number of open shifts.
  final int shiftCount;

  /// Worked time of open shifts.
  final int workedMs;

  /// Tips of open shifts.
  final int tipsCents;

  /// The running shift, if any.
  final Shift? running;

  /// Open wage including the running shift at [now].
  int openCentsAt(DateTime now) =>
      openCents + (running == null ? 0 : liveValues(running!, now).earnedCents);

  /// Whether there is nothing open and nothing running.
  bool get isEmpty => shiftCount == 0 && running == null;

  @override
  bool operator ==(Object other) =>
      other is OpenSummary &&
      other.openCents == openCents &&
      other.shiftCount == shiftCount &&
      other.workedMs == workedMs &&
      other.tipsCents == tipsCents &&
      other.running == running;

  @override
  int get hashCode =>
      Object.hash(openCents, shiftCount, workedMs, tipsCents, running);

  @override
  String toString() =>
      'OpenSummary($openCents ct, $shiftCount shifts, ${workedMs}ms)';
}

/// Builds the [OpenSummary] from [shifts] (only open ones count).
OpenSummary computeOpenSummary(Iterable<Shift> shifts, {Shift? running}) {
  var open = 0;
  var count = 0;
  var worked = 0;
  var tips = 0;
  for (final s in shifts) {
    if (!s.isOpen) continue;
    open += s.earnedCents;
    count++;
    worked += s.workedMs;
    tips += s.tipsCents;
  }
  return OpenSummary(
    openCents: open,
    shiftCount: count,
    workedMs: worked,
    tipsCents: tips,
    running: running != null && running.isRunning && !running.isDeleted
        ? running
        : null,
  );
}

/// Shifts of one calendar month for the list ("September 2026 · 42,5 h ·
/// 637,50 € · 318,75 € offen").
final class ShiftMonthGroup {
  /// Creates a group.
  const ShiftMonthGroup({
    required this.year,
    required this.month,
    required this.shifts,
  });

  /// Year.
  final int year;

  /// Month 1–12.
  final int month;

  /// The month's shifts, newest first.
  final List<Shift> shifts;

  /// First day of the month.
  LocalDate get firstDay => LocalDate(year, month, 1);

  /// Worked time.
  int get workedMs => shifts.fold(0, (sum, s) => sum + s.workedMs);

  /// Wage earned (without tips).
  int get earnedCents => sumCents(shifts.map((s) => s.earnedCents));

  /// Unpaid wage.
  int get openCents =>
      sumCents(shifts.where((s) => !s.isPaid).map((s) => s.earnedCents));

  /// Tips.
  int get tipsCents => sumCents(shifts.map((s) => s.tipsCents));

  @override
  bool operator ==(Object other) =>
      other is ShiftMonthGroup &&
      other.year == year &&
      other.month == month &&
      _listEquals(other.shifts, shifts);

  @override
  int get hashCode => Object.hash(year, month, Object.hashAll(shifts));

  @override
  String toString() => 'ShiftMonthGroup($year-$month, ${shifts.length})';
}

/// Groups finished, non-deleted [shifts] by the month of their local start
/// date: newest month first, newest shift first within a month.
List<ShiftMonthGroup> groupShiftsByMonth(Iterable<Shift> shifts) {
  final sorted = [
    for (final s in shifts)
      if (s.isDone && !s.isDeleted) s,
  ]..sort(_newestFirst);
  final groups = <ShiftMonthGroup>[];
  var current = <Shift>[];
  int? year;
  int? month;
  for (final s in sorted) {
    final date = s.localStartDate;
    if (date.year != year || date.month != month) {
      if (current.isNotEmpty) {
        groups.add(
          ShiftMonthGroup(
            year: year!,
            month: month!,
            shifts: List.unmodifiable(current),
          ),
        );
      }
      current = <Shift>[];
      year = date.year;
      month = date.month;
    }
    current.add(s);
  }
  if (current.isNotEmpty) {
    groups.add(
      ShiftMonthGroup(
        year: year!,
        month: month!,
        shifts: List.unmodifiable(current),
      ),
    );
  }
  return groups;
}

int _newestFirst(Shift a, Shift b) {
  final byStart = b.startUtc.compareTo(a.startUtc);
  return byStart != 0 ? byStart : b.id.compareTo(a.id);
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
