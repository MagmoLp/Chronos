import '../../core/local_date.dart';
import '../../core/money.dart';
import '../../core/time.dart';
import '../../domain/job.dart';
import '../../domain/shift.dart';

/// One line of a timesheet export: a finished shift with its job name.
///
/// Times are local wall-clock [DateTime]s; money is `int` cents.
final class ExportRow {
  /// Creates a row.
  const ExportRow({
    required this.date,
    required this.start,
    required this.end,
    required this.breakMs,
    required this.workedMs,
    required this.rateCentsPerHour,
    required this.amountCents,
    required this.tipsCents,
    required this.paid,
    required this.jobId,
    required this.jobName,
    this.note,
  });

  /// The row of a finished [shift] of the job called [jobName].
  factory ExportRow.fromShift(Shift shift, {required String jobName}) {
    final end = shift.endUtc ?? shift.startUtc;
    return ExportRow(
      date: shift.localStartDate,
      start: shift.startUtc.toLocal(),
      end: end.toLocal(),
      breakMs: shift.breakMs,
      workedMs: shift.workedMs,
      rateCentsPerHour: shift.rateCentsPerHour,
      amountCents: shift.earnedCents,
      tipsCents: shift.tipsCents,
      paid: shift.isPaid,
      jobId: shift.jobId,
      jobName: jobName,
      note: shift.note,
    );
  }

  /// Local date the shift belongs to (its start date).
  final LocalDate date;

  /// Local start time.
  final DateTime start;

  /// Local end time (may be on the next day).
  final DateTime end;

  /// Break in ms.
  final int breakMs;

  /// Worked time in ms (duration − break).
  final int workedMs;

  /// Wage snapshot in cents per hour.
  final int rateCentsPerHour;

  /// Wage earned (without tips) in cents.
  final int amountCents;

  /// Tips in cents.
  final int tipsCents;

  /// Whether the shift was paid.
  final bool paid;

  /// Job id.
  final int jobId;

  /// Job name.
  final String jobName;

  /// Optional note.
  final String? note;

  /// Break in whole minutes (rounded half-up).
  int get breakMinutes => roundedMinutes(breakMs);

  /// Whether the end falls on a later calendar day than the start.
  bool get endsNextDay => LocalDate.fromDateTime(end).isAfter(date);
}

/// Sums over the rows of an export.
final class ExportTotals {
  /// Creates totals.
  const ExportTotals({
    required this.count,
    required this.breakMs,
    required this.workedMs,
    required this.amountCents,
    required this.tipsCents,
  });

  /// Totals of [rows].
  factory ExportTotals.of(Iterable<ExportRow> rows) {
    var count = 0;
    var breakMs = 0;
    var workedMs = 0;
    for (final row in rows) {
      count++;
      breakMs += row.breakMs;
      workedMs += row.workedMs;
    }
    return ExportTotals(
      count: count,
      breakMs: breakMs,
      workedMs: workedMs,
      amountCents: sumCents(rows.map((r) => r.amountCents)),
      tipsCents: sumCents(rows.map((r) => r.tipsCents)),
    );
  }

  /// Number of shifts.
  final int count;

  /// Total break in ms.
  final int breakMs;

  /// Total worked time in ms.
  final int workedMs;

  /// Total wage in cents.
  final int amountCents;

  /// Total tips in cents.
  final int tipsCents;

  /// Total break in whole minutes (rounded half-up from the exact sum).
  int get breakMinutes => roundedMinutes(breakMs);

  /// Whether there is nothing to export.
  bool get isEmpty => count == 0;
}

/// Export rows for finished, non-deleted [shifts], oldest first.
///
/// Job names come from [jobs] (by id); unknown jobs get [unknownJobName].
/// With [jobId] only shifts of that job are included.
List<ExportRow> exportRowsFromShifts(
  Iterable<Shift> shifts, {
  required Iterable<Job> jobs,
  int? jobId,
  String unknownJobName = '',
}) {
  final names = {for (final job in jobs) job.id: job.name};
  final selected =
      [
        for (final s in shifts)
          if (s.isDone && !s.isDeleted && (jobId == null || s.jobId == jobId))
            s,
      ]..sort((a, b) {
        final byStart = a.startUtc.compareTo(b.startUtc);
        return byStart != 0 ? byStart : a.id.compareTo(b.id);
      });
  return [
    for (final s in selected)
      ExportRow.fromShift(s, jobName: names[s.jobId] ?? unknownJobName),
  ];
}

/// Whole minutes of [ms], rounded half-up.
int roundedMinutes(int ms) => (ms + msPerMinute ~/ 2) ~/ msPerMinute;

/// Hundredths of an hour of [ms], rounded half-up (`27 900 000` → 775).
int hundredthsOfHour(int ms) => (ms * 100 + msPerHour ~/ 2) ~/ msPerHour;
