import '../core/local_date.dart';
import '../core/money.dart';
import 'shift.dart';

class _Unset {
  const _Unset();
}

const Object _unset = _Unset();

/// A recorded payout that settled a set of shifts.
final class Payout {
  /// Creates a payout.
  const Payout({
    required this.id,
    required this.uuid,
    required this.untilDate,
    required this.paidOn,
    required this.expectedCents,
    required this.receivedCents,
    required this.createdAt,
    this.jobId,
    this.note,
  });

  /// Database id.
  final int id;

  /// Stable id used to merge backups.
  final String uuid;

  /// Job the payout is for; `null` = all jobs.
  final int? jobId;

  /// Shifts up to and including this local date were settled.
  final LocalDate untilDate;

  /// Date the money was received.
  final LocalDate paidOn;

  /// Sum of the settled shifts' wage.
  final int expectedCents;

  /// Amount actually received.
  final int receivedCents;

  /// Optional note.
  final String? note;

  /// Creation time.
  final DateTime createdAt;

  /// Received minus expected (negative = less than expected).
  int get differenceCents => receivedCents - expectedCents;

  /// Copy with the given fields replaced.
  Payout copyWith({
    int? id,
    String? uuid,
    Object? jobId = _unset,
    LocalDate? untilDate,
    LocalDate? paidOn,
    int? expectedCents,
    int? receivedCents,
    Object? note = _unset,
    DateTime? createdAt,
  }) => Payout(
    id: id ?? this.id,
    uuid: uuid ?? this.uuid,
    jobId: identical(jobId, _unset) ? this.jobId : jobId as int?,
    untilDate: untilDate ?? this.untilDate,
    paidOn: paidOn ?? this.paidOn,
    expectedCents: expectedCents ?? this.expectedCents,
    receivedCents: receivedCents ?? this.receivedCents,
    note: identical(note, _unset) ? this.note : note as String?,
    createdAt: createdAt ?? this.createdAt,
  );

  @override
  bool operator ==(Object other) =>
      other is Payout &&
      other.id == id &&
      other.uuid == uuid &&
      other.jobId == jobId &&
      other.untilDate == untilDate &&
      other.paidOn == paidOn &&
      other.expectedCents == expectedCents &&
      other.receivedCents == receivedCents &&
      other.note == note &&
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(
    id,
    uuid,
    jobId,
    untilDate,
    paidOn,
    expectedCents,
    receivedCents,
    note,
    createdAt,
  );

  @override
  String toString() =>
      'Payout($id, job $jobId, until $untilDate, expected $expectedCents, '
      'received $receivedCents)';
}

/// The open shifts a payout would settle.
final class PayoutSelection {
  /// Creates a selection.
  const PayoutSelection({
    required this.shifts,
    required this.expectedCents,
    required this.workedMs,
    required this.tipsCents,
  });

  /// Nothing to pay out.
  static const PayoutSelection empty = PayoutSelection(
    shifts: [],
    expectedCents: 0,
    workedMs: 0,
    tipsCents: 0,
  );

  /// Selected shifts, oldest first.
  final List<Shift> shifts;

  /// Sum of their wage earnings.
  final int expectedCents;

  /// Sum of their worked time.
  final int workedMs;

  /// Sum of their tips (informational; not part of [expectedCents]).
  final int tipsCents;

  /// Number of shifts.
  int get count => shifts.length;

  /// Whether nothing is selected.
  bool get isEmpty => shifts.isEmpty;

  /// Ids of the selected shifts.
  List<int> get shiftIds => [for (final s in shifts) s.id];

  @override
  bool operator ==(Object other) =>
      other is PayoutSelection &&
      other.expectedCents == expectedCents &&
      other.workedMs == workedMs &&
      other.tipsCents == tipsCents &&
      other.shifts.length == shifts.length &&
      Iterable<int>.generate(shifts.length)
          .every((i) => other.shifts[i] == shifts[i]);

  @override
  int get hashCode =>
      Object.hash(expectedCents, workedMs, tipsCents, Object.hashAll(shifts));

  @override
  String toString() =>
      'PayoutSelection($count shifts, $expectedCents ct, ${workedMs}ms)';
}

/// Selects the open (finished, unpaid, not deleted) shifts whose local start
/// date is on or before [until], optionally only of [jobId].
PayoutSelection selectForPayout(
  Iterable<Shift> shifts, {
  required LocalDate until,
  int? jobId,
}) {
  final selected =
      [
        for (final s in shifts)
          if (s.isOpen &&
              (jobId == null || s.jobId == jobId) &&
              s.localStartDate.isOnOrBefore(until))
            s,
      ]..sort((a, b) {
        final byStart = a.startUtc.compareTo(b.startUtc);
        return byStart != 0 ? byStart : a.id.compareTo(b.id);
      });
  return PayoutSelection(
    shifts: List.unmodifiable(selected),
    expectedCents: sumCents(selected.map((s) => s.earnedCents)),
    workedMs: selected.fold(0, (sum, s) => sum + s.workedMs),
    tipsCents: sumCents(selected.map((s) => s.tipsCents)),
  );
}
