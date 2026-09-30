import '../core/time.dart';
import 'shift.dart';
import 'shift_draft.dart';

/// A problem that blocks saving a shift.
enum ShiftError {
  /// End is at or before the start.
  endNotAfterStart,

  /// The break is as long as (or longer than) the shift.
  breakNotShorterThanDuration,

  /// The break is negative.
  negativeBreak,

  /// Tips are negative.
  negativeTips,
}

/// A problem the user must confirm before saving.
sealed class ShiftWarning {
  const ShiftWarning();
}

/// The shift is longer than 16 hours.
final class LongerThan16h extends ShiftWarning {
  /// Creates the warning for a shift of [durationMs].
  const LongerThan16h(this.durationMs);

  /// Gross duration in ms.
  final int durationMs;

  @override
  bool operator ==(Object other) =>
      other is LongerThan16h && other.durationMs == durationMs;

  @override
  int get hashCode => Object.hash(LongerThan16h, durationMs);

  @override
  String toString() => 'LongerThan16h($durationMs)';
}

/// The shift overlaps [shift].
final class OverlapsWith extends ShiftWarning {
  /// Creates the warning for an overlap with [shift].
  const OverlapsWith(this.shift);

  /// The other shift.
  final Shift shift;

  @override
  bool operator ==(Object other) =>
      other is OverlapsWith && other.shift.id == shift.id;

  @override
  int get hashCode => Object.hash(OverlapsWith, shift.id);

  @override
  String toString() => 'OverlapsWith(${shift.id})';
}

/// The shift starts in the future.
final class StartsInFuture extends ShiftWarning {
  /// Creates the warning.
  const StartsInFuture();

  @override
  bool operator ==(Object other) => other is StartsInFuture;

  @override
  int get hashCode => (StartsInFuture).hashCode;

  @override
  String toString() => 'StartsInFuture()';
}

/// Result of validating shift input.
final class ShiftValidation {
  /// Creates a result.
  const ShiftValidation({this.errors = const [], this.warnings = const []});

  /// Valid, no warnings.
  static const ShiftValidation ok = ShiftValidation();

  /// Blocking problems.
  final List<ShiftError> errors;

  /// Problems that need confirmation.
  final List<ShiftWarning> warnings;

  /// Whether there are no errors.
  bool get isValid => errors.isEmpty;

  /// Whether there are warnings.
  bool get hasWarnings => warnings.isNotEmpty;

  /// Whether the input can be saved without asking.
  bool get isClean => errors.isEmpty && warnings.isEmpty;

  /// The shifts this input overlaps with.
  List<Shift> get overlaps => [
    for (final w in warnings)
      if (w is OverlapsWith) w.shift,
  ];

  @override
  bool operator ==(Object other) =>
      other is ShiftValidation &&
      _listEquals(other.errors, errors) &&
      _listEquals(other.warnings, warnings);

  @override
  int get hashCode =>
      Object.hash(Object.hashAll(errors), Object.hashAll(warnings));

  @override
  String toString() => 'ShiftValidation(errors: $errors, warnings: $warnings)';
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Longest shift that does not trigger [LongerThan16h].
const int kLongShiftThresholdMs = 16 * msPerHour;

/// Whether the half-open intervals `[aStart, aEnd)` and `[bStart, bEnd)`
/// overlap (touching ends do not overlap).
bool intervalsOverlap(
  DateTime aStart,
  DateTime aEnd,
  DateTime bStart,
  DateTime bEnd,
) => aStart.isBefore(bEnd) && bStart.isBefore(aEnd);

/// Shifts of [others] that overlap `[startUtc, endUtc)`.
///
/// Deleted shifts and [ignoreShiftId] are skipped; a running shift counts as
/// lasting until [now] (or at least until its start).
List<Shift> findOverlapping(
  DateTime startUtc,
  DateTime endUtc,
  Iterable<Shift> others, {
  required DateTime now,
  int? ignoreShiftId,
}) {
  final result = <Shift>[];
  for (final other in others) {
    if (other.isDeleted || other.id == ignoreShiftId) continue;
    final otherEnd =
        other.endUtc ?? (now.isAfter(other.startUtc) ? now : other.startUtc);
    if (intervalsOverlap(startUtc, endUtc, other.startUtc, otherEnd)) {
      result.add(other);
    }
  }
  result.sort((a, b) => a.startUtc.compareTo(b.startUtc));
  return result;
}

/// Blocking errors for a shift from [startUtc] to [endUtc] with [breakMs].
///
/// A break only errors when it is positive and not shorter than the
/// duration, so a zero-length (rounded) timer shift without break is valid.
List<ShiftError> shiftErrors({
  required DateTime startUtc,
  required DateTime endUtc,
  int breakMs = 0,
  int tipsCents = 0,
}) {
  final errors = <ShiftError>[];
  if (!endUtc.isAfter(startUtc)) errors.add(ShiftError.endNotAfterStart);
  if (breakMs < 0) {
    errors.add(ShiftError.negativeBreak);
  } else if (breakMs > 0 &&
      breakMs >= endUtc.difference(startUtc).inMilliseconds) {
    errors.add(ShiftError.breakNotShorterThanDuration);
  }
  if (tipsCents < 0) errors.add(ShiftError.negativeTips);
  return errors;
}

/// Validates editor input.
///
/// Errors: end not after start, break not shorter than the duration,
/// negative break or tips. Warnings: longer than 16 h, overlaps with any of
/// [others] (except [ignoreShiftId]), start after [now].
ShiftValidation validateShift({
  required DateTime startUtc,
  required DateTime endUtc,
  required DateTime now,
  int breakMs = 0,
  int tipsCents = 0,
  Iterable<Shift> others = const [],
  int? ignoreShiftId,
}) {
  final errors = shiftErrors(
    startUtc: startUtc,
    endUtc: endUtc,
    breakMs: breakMs,
    tipsCents: tipsCents,
  );
  final warnings = <ShiftWarning>[];
  final durationMs = endUtc.difference(startUtc).inMilliseconds;
  if (durationMs > kLongShiftThresholdMs) {
    warnings.add(LongerThan16h(durationMs));
  }
  if (endUtc.isAfter(startUtc)) {
    for (final other in findOverlapping(
      startUtc,
      endUtc,
      others,
      now: now,
      ignoreShiftId: ignoreShiftId,
    )) {
      warnings.add(OverlapsWith(other));
    }
  }
  if (startUtc.isAfter(now)) warnings.add(const StartsInFuture());
  return ShiftValidation(errors: errors, warnings: warnings);
}

/// [validateShift] for a [ShiftDraft].
ShiftValidation validateDraft(
  ShiftDraft draft, {
  required DateTime now,
  Iterable<Shift> others = const [],
  int? ignoreShiftId,
}) => validateShift(
  startUtc: draft.startUtc,
  endUtc: draft.endUtc,
  now: now,
  breakMs: draft.breakMs,
  tipsCents: draft.tipsCents,
  others: others,
  ignoreShiftId: ignoreShiftId,
);
