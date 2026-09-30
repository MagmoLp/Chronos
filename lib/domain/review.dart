import '../core/local_date.dart';
import '../core/time.dart';
import 'shift.dart';
import 'validation.dart';

/// Why a migrated shift should be reviewed by the user.
enum ReviewReason {
  /// 16 hours or longer.
  tooLong16h,

  /// Exactly 23 or 24 hours (v1 silently turned end ≤ start into these).
  exactly23or24h,

  /// Same start and end as another shift.
  duplicateTimes,

  /// Same v1 id as another shift.
  duplicateLegacyId,

  /// Overlaps another shift.
  overlap,

  /// Starts or ends on a daylight-saving switch day (v1 got these wrong).
  dstDay,
}

/// A shift on the "please review" list with all reasons that apply.
final class ReviewItem {
  /// Creates an item.
  const ReviewItem({
    required this.shiftId,
    required this.reasons,
    this.relatedShiftIds = const {},
  });

  /// The shift to review.
  final int shiftId;

  /// Why it is listed (never empty).
  final Set<ReviewReason> reasons;

  /// Other shifts involved (duplicates, overlaps).
  final Set<int> relatedShiftIds;

  @override
  bool operator ==(Object other) =>
      other is ReviewItem &&
      other.shiftId == shiftId &&
      _setEquals(other.reasons, reasons) &&
      _setEquals(other.relatedShiftIds, relatedShiftIds);

  @override
  int get hashCode => Object.hash(
    shiftId,
    Object.hashAllUnordered(reasons),
    Object.hashAllUnordered(relatedShiftIds),
  );

  @override
  String toString() =>
      'ReviewItem($shiftId, ${reasons.map((r) => r.name).join('+')}'
      '${relatedShiftIds.isEmpty ? '' : ', related $relatedShiftIds'})';
}

bool _setEquals<T>(Set<T> a, Set<T> b) =>
    a.length == b.length && a.containsAll(b);

/// Length from which a shift is flagged [ReviewReason.tooLong16h].
const int kReviewLongShiftMs = 16 * msPerHour;

/// Checks [shifts] for suspicious data (used after the v1 migration).
///
/// Deleted and running shifts are ignored. Returns one item per flagged
/// shift, oldest first. Nothing is changed – the user decides.
List<ReviewItem> computeReviewItems(Iterable<Shift> shifts) {
  final done =
      [
        for (final s in shifts)
          if (s.isDone && !s.isDeleted && s.endUtc != null) s,
      ]..sort((a, b) {
        final byStart = a.startUtc.compareTo(b.startUtc);
        return byStart != 0 ? byStart : a.id.compareTo(b.id);
      });

  final reasons = <int, Set<ReviewReason>>{};
  final related = <int, Set<int>>{};
  void flag(Shift shift, ReviewReason reason, [int? otherId]) {
    reasons.putIfAbsent(shift.id, () => <ReviewReason>{}).add(reason);
    if (otherId != null) {
      related.putIfAbsent(shift.id, () => <int>{}).add(otherId);
    }
  }

  const exactHours = {23 * msPerHour, 24 * msPerHour};
  final byTimes = <(int, int), List<Shift>>{};
  final byLegacyId = <String, List<Shift>>{};

  for (final shift in done) {
    final end = shift.endUtc!;
    final duration = end.difference(shift.startUtc).inMilliseconds;
    if (duration >= kReviewLongShiftMs) flag(shift, ReviewReason.tooLong16h);

    final endOffset = shift.endOffsetMin ?? shift.startOffsetMin;
    final wallDuration =
        duration + (endOffset - shift.startOffsetMin) * msPerMinute;
    if (exactHours.contains(duration) || exactHours.contains(wallDuration)) {
      flag(shift, ReviewReason.exactly23or24h);
    }

    if (isDstSwitchDay(shift.localStartDate) ||
        isDstSwitchDay(LocalDate.ofInstant(end))) {
      flag(shift, ReviewReason.dstDay);
    }

    byTimes
        .putIfAbsent((
          shift.startUtc.millisecondsSinceEpoch,
          end.millisecondsSinceEpoch,
        ), () => [])
        .add(shift);
    final legacyId = shift.legacyId;
    if (legacyId != null) byLegacyId.putIfAbsent(legacyId, () => []).add(shift);
  }

  void flagGroups<K>(Map<K, List<Shift>> groups, ReviewReason reason) {
    for (final group in groups.values) {
      if (group.length < 2) continue;
      for (final shift in group) {
        for (final other in group) {
          if (other.id != shift.id) flag(shift, reason, other.id);
        }
      }
    }
  }

  flagGroups(byTimes, ReviewReason.duplicateTimes);
  flagGroups(byLegacyId, ReviewReason.duplicateLegacyId);

  // Sweep over shifts sorted by start: every later shift starting before
  // this one ends is a candidate.
  for (var i = 0; i < done.length; i++) {
    final a = done[i];
    for (var j = i + 1; j < done.length; j++) {
      final b = done[j];
      if (!b.startUtc.isBefore(a.endUtc!)) break;
      if (intervalsOverlap(a.startUtc, a.endUtc!, b.startUtc, b.endUtc!)) {
        flag(a, ReviewReason.overlap, b.id);
        flag(b, ReviewReason.overlap, a.id);
      }
    }
  }

  return [
    for (final shift in done)
      if (reasons.containsKey(shift.id))
        ReviewItem(
          shiftId: shift.id,
          reasons: Set.unmodifiable(reasons[shift.id]!),
          relatedShiftIds: Set.unmodifiable(related[shift.id] ?? const <int>{}),
        ),
  ];
}

/// Why a wage looks wrong.
enum WageIssue {
  /// More than 100 €/h.
  tooHigh,

  /// Less than 5 €/h.
  tooLow,
}

/// Plausibility of an hourly wage (v1 turned "12,50" into 1250 €/h).
final class WagePlausibility {
  /// Creates a result.
  const WagePlausibility({
    required this.centsPerHour,
    this.issue,
    this.suggestedCentsPerHour,
  });

  /// The checked wage.
  final int centsPerHour;

  /// What is wrong, or `null` if plausible.
  final WageIssue? issue;

  /// A likely intended wage (e.g. 12,50 € for 1250 €/h), if one exists.
  final int? suggestedCentsPerHour;

  /// Whether the wage is within 5–100 €/h.
  bool get isPlausible => issue == null;

  @override
  bool operator ==(Object other) =>
      other is WagePlausibility &&
      other.centsPerHour == centsPerHour &&
      other.issue == issue &&
      other.suggestedCentsPerHour == suggestedCentsPerHour;

  @override
  int get hashCode => Object.hash(centsPerHour, issue, suggestedCentsPerHour);

  @override
  String toString() =>
      'WagePlausibility($centsPerHour, $issue, suggest $suggestedCentsPerHour)';
}

/// Highest plausible wage: 100 €/h.
const int kMaxPlausibleWageCents = 10000;

/// Lowest plausible wage: 5 €/h.
const int kMinPlausibleWageCents = 500;

/// Checks whether [centsPerHour] is between 5 and 100 €/h.
///
/// For too-high values it suggests the wage with the decimal separator put
/// back (÷100, then ÷10), if that division is exact and plausible.
WagePlausibility checkWagePlausibility(int centsPerHour) {
  bool plausible(int cents) =>
      cents >= kMinPlausibleWageCents && cents <= kMaxPlausibleWageCents;
  if (plausible(centsPerHour)) {
    return WagePlausibility(centsPerHour: centsPerHour);
  }
  if (centsPerHour < kMinPlausibleWageCents) {
    return WagePlausibility(
      centsPerHour: centsPerHour,
      issue: WageIssue.tooLow,
    );
  }
  int? suggestion;
  for (final divisor in const [100, 10]) {
    if (centsPerHour % divisor == 0 && plausible(centsPerHour ~/ divisor)) {
      suggestion = centsPerHour ~/ divisor;
      break;
    }
  }
  return WagePlausibility(
    centsPerHour: centsPerHour,
    issue: WageIssue.tooHigh,
    suggestedCentsPerHour: suggestion,
  );
}
