import '../core/time.dart';
import 'job.dart';

/// Rounds [instant] to the nearest [rule] step of the local wall clock.
///
/// Exactly half a step rounds up (08:07:30 → 08:15 with 15 min). Seconds and
/// milliseconds count. The wall clock is taken with the UTC offset valid at
/// [instant] and converted back with the same offset, so the result is never
/// more than half a step away from [instant] – also on daylight-saving days,
/// where rebuilding a local time could otherwise jump by an hour.
///
/// Returns a UTC [DateTime].
DateTime roundToRule(DateTime instant, RoundingRule rule) {
  final utc = instant.toUtc();
  if (rule.stepMinutes == 0) return utc;
  final stepMs = rule.stepMinutes * msPerMinute;
  final offsetMs = utc.toLocal().timeZoneOffset.inMilliseconds;
  final wallMs = utc.millisecondsSinceEpoch + offsetMs;
  final remainder = wallMs % stepMs; // Dart's % is non-negative here.
  final roundedWallMs = remainder * 2 >= stepMs
      ? wallMs - remainder + stepMs
      : wallMs - remainder;
  return utcFromMs(roundedWallMs - offsetMs);
}

/// Billed start and end of a timer shift after applying [rule].
({DateTime startUtc, DateTime endUtc}) roundShiftTimes({
  required DateTime rawStartUtc,
  required DateTime rawEndUtc,
  required RoundingRule rule,
}) => (
  startUtc: roundToRule(rawStartUtc, rule),
  endUtc: roundToRule(rawEndUtc, rule),
);
