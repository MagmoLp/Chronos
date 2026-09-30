import '../core/money.dart';
import '../core/time.dart';
import 'shift.dart';

/// Worked time between [start] and [end] minus [breakMs], never negative.
int workedMsBetween(DateTime start, DateTime end, {int breakMs = 0}) {
  final worked = end.difference(start).inMilliseconds - breakMs;
  return worked < 0 ? 0 : worked;
}

/// Total break of [shift] at [now]: stored breaks plus the pause in progress
/// (if the shift is paused and [now] is after the pause started).
int currentBreakMs(Shift shift, DateTime now) {
  final pausedAt = shift.pausedAtUtc;
  if (!shift.isRunning || pausedAt == null) return shift.breakMs;
  final running = now.difference(pausedAt).inMilliseconds;
  return shift.breakMs + (running > 0 ? running : 0);
}

/// Worked time and earnings of a shift at a given instant.
final class LiveShiftValues {
  /// Creates live values.
  const LiveShiftValues({
    required this.workedMs,
    required this.earnedCents,
    required this.breakMs,
    required this.isPaused,
    this.pausedSinceUtc,
  });

  /// Worked time without breaks, in ms.
  final int workedMs;

  /// Wage earned so far (half-up to the cent).
  final int earnedCents;

  /// Break time so far, including a pause in progress.
  final int breakMs;

  /// Whether the shift is paused right now.
  final bool isPaused;

  /// Start of the current pause.
  final DateTime? pausedSinceUtc;

  @override
  bool operator ==(Object other) =>
      other is LiveShiftValues &&
      other.workedMs == workedMs &&
      other.earnedCents == earnedCents &&
      other.breakMs == breakMs &&
      other.isPaused == isPaused &&
      other.pausedSinceUtc == pausedSinceUtc;

  @override
  int get hashCode =>
      Object.hash(workedMs, earnedCents, breakMs, isPaused, pausedSinceUtc);

  @override
  String toString() =>
      'LiveShiftValues(worked ${workedMs}ms, $earnedCents ct, '
      'break ${breakMs}ms${isPaused ? ', paused' : ''})';
}

/// Worked time and earnings of [shift] at [now].
///
/// Running: `(now − start) − breaks − current pause`, computed from stored
/// instants (nothing is counted up), never negative. Done: the stored values.
LiveShiftValues liveValues(Shift shift, DateTime now) {
  if (!shift.isRunning) {
    return LiveShiftValues(
      workedMs: shift.workedMs,
      earnedCents: shift.earnedCents,
      breakMs: shift.breakMs,
      isPaused: false,
    );
  }
  final breakMs = currentBreakMs(shift, now);
  final worked = workedMsBetween(shift.startUtc, now, breakMs: breakMs);
  return LiveShiftValues(
    workedMs: worked,
    earnedCents: earningsCents(worked, shift.rateCentsPerHour),
    breakMs: breakMs,
    isPaused: shift.isPaused,
    pausedSinceUtc: shift.pausedAtUtc,
  );
}

/// Worked ms of [shift]; for a running shift at [now] (required then).
int shiftWorkedMs(Shift shift, {DateTime? now}) {
  if (!shift.isRunning) return shift.workedMs;
  if (now == null) throw ArgumentError.notNull('now');
  return liveValues(shift, now).workedMs;
}

/// Wage earnings of [shift]; for a running shift at [now] (required then).
int shiftEarnedCents(Shift shift, {DateTime? now}) {
  if (!shift.isRunning) return shift.earnedCents;
  if (now == null) throw ArgumentError.notNull('now');
  return liveValues(shift, now).earnedCents;
}

/// Milliseconds of further work until [earningsCents] shows the next cent,
/// or `null` if the rate is 0 (nothing ever changes). Lets the UI refresh the
/// amount exactly when a new cent is earned.
int? msUntilNextCent(int workedMs, int centsPerHour) {
  if (centsPerHour <= 0) return null;
  final worked = workedMs < 0 ? 0 : workedMs;
  final current = earningsCents(worked, centsPerHour);
  // Smallest w with (w × c + H/2) ≥ (current + 1) × H.
  final target = (current + 1) * msPerHour - msPerHour ~/ 2;
  final nextWorked = (target + centsPerHour - 1) ~/ centsPerHour;
  final wait = nextWorked - workedMs;
  return wait < 1 ? 1 : wait;
}
