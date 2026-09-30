import '../core/money.dart';
import 'job.dart';
import 'pay.dart';
import 'rounding.dart';
import 'shift.dart';
import 'validation.dart';

/// What finishing a running shift would store: the numbers for the
/// "Schicht beenden" sheet and the values the repository writes.
final class FinishPreview {
  /// Creates a preview.
  const FinishPreview({
    required this.rawStartUtc,
    required this.startUtc,
    required this.rawEndUtc,
    required this.endUtc,
    required this.breakMs,
    required this.rateCentsPerHour,
    required this.rounding,
    required this.workedMs,
    required this.amountCents,
    required this.errors,
  });

  /// Recorded start.
  final DateTime rawStartUtc;

  /// Billed start (after rounding).
  final DateTime startUtc;

  /// Recorded end.
  final DateTime rawEndUtc;

  /// Billed end (after rounding).
  final DateTime endUtc;

  /// Break in ms.
  final int breakMs;

  /// Wage snapshot of the shift.
  final int rateCentsPerHour;

  /// Rounding rule that was applied.
  final RoundingRule rounding;

  /// Billed worked time.
  final int workedMs;

  /// Wage earnings (without tips).
  final int amountCents;

  /// Blocking problems (e.g. end before start); empty = can be saved.
  final List<ShiftError> errors;

  /// Billed duration (end − start) in ms.
  int get durationMs => endUtc.difference(startUtc).inMilliseconds;

  /// Whether rounding moved the start.
  bool get startRounded => startUtc != rawStartUtc;

  /// Whether rounding moved the end.
  bool get endRounded => endUtc != rawEndUtc;

  /// Whether the shift can be finished with these values.
  bool get isValid => errors.isEmpty;

  @override
  bool operator ==(Object other) =>
      other is FinishPreview &&
      other.rawStartUtc == rawStartUtc &&
      other.startUtc == startUtc &&
      other.rawEndUtc == rawEndUtc &&
      other.endUtc == endUtc &&
      other.breakMs == breakMs &&
      other.rateCentsPerHour == rateCentsPerHour &&
      other.rounding == rounding &&
      other.workedMs == workedMs &&
      other.amountCents == amountCents &&
      other.errors.length == errors.length &&
      other.errors.every(errors.contains);

  @override
  int get hashCode => Object.hash(
    rawStartUtc,
    startUtc,
    rawEndUtc,
    endUtc,
    breakMs,
    rateCentsPerHour,
    rounding,
    workedMs,
    amountCents,
  );

  @override
  String toString() =>
      'FinishPreview($startUtc–$endUtc, break ${breakMs}ms, '
      'worked ${workedMs}ms, $amountCents ct, errors $errors)';
}

/// Computes how [running] would be finished at [endUtc].
///
/// [rounding] (the job's rule) is applied to start and end; the raw times
/// are kept. [breakMs] defaults to the breaks so far including a pause that
/// is still in progress at [endUtc].
FinishPreview previewFinish({
  required Shift running,
  required RoundingRule rounding,
  required DateTime endUtc,
  int? breakMs,
}) {
  final rawStart = running.rawStartUtc.toUtc();
  final rawEnd = endUtc.toUtc();
  final effectiveBreak = breakMs ?? currentBreakMs(running, rawEnd);
  final start = roundToRule(rawStart, rounding);
  final end = roundToRule(rawEnd, rounding);
  final errors = <ShiftError>[
    if (!rawEnd.isAfter(rawStart)) ShiftError.endNotAfterStart,
    ...shiftErrors(
      startUtc: start,
      endUtc: end,
      breakMs: effectiveBreak,
    ).where((e) => e != ShiftError.endNotAfterStart),
  ];
  final worked = workedMsBetween(start, end, breakMs: effectiveBreak);
  return FinishPreview(
    rawStartUtc: rawStart,
    startUtc: start,
    rawEndUtc: rawEnd,
    endUtc: end,
    breakMs: effectiveBreak,
    rateCentsPerHour: running.rateCentsPerHour,
    rounding: rounding,
    workedMs: worked,
    amountCents: earningsCents(worked, running.rateCentsPerHour),
    errors: errors,
  );
}
