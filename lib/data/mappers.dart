import 'package:drift/drift.dart';

import '../core/local_date.dart';
import '../core/time.dart';
import '../domain/job.dart';
import '../domain/payout.dart';
import '../domain/review.dart';
import '../domain/shift.dart';
import '../domain/wage_rate.dart';
import 'database.dart';

/// Conversions between drift rows and domain models.
extension JobRowX on JobRow {
  /// The domain model.
  Job toDomain() => Job(
    id: id,
    uuid: uuid,
    name: name,
    colorArgb: colorArgb,
    rounding: rounding,
    archived: archived,
    sortOrder: sortOrder,
  );
}

/// Conversions for wage rows.
extension WageRateRowX on WageRateRow {
  /// The domain model.
  WageRate toDomain() => WageRate(
    id: id,
    jobId: jobId,
    validFrom: LocalDate.fromKey(validFrom),
    centsPerHour: centsPerHour,
  );
}

/// Conversions for payout rows.
extension PayoutRowX on PayoutRow {
  /// The domain model.
  Payout toDomain() => Payout(
    id: id,
    uuid: uuid,
    jobId: jobId,
    untilDate: LocalDate.fromKey(untilDate),
    paidOn: LocalDate.fromKey(paidOn),
    expectedCents: expectedCents,
    receivedCents: receivedCents,
    note: note,
    createdAt: utcFromMs(createdAt),
  );
}

/// Conversions for shift rows.
extension ShiftRowX on ShiftRow {
  /// The domain model.
  Shift toDomain() => Shift(
    id: id,
    uuid: uuid,
    jobId: jobId,
    status: status,
    startUtc: utcFromMs(startUtc),
    endUtc: utcFromMsOrNull(endUtc),
    rawStartUtc: utcFromMs(rawStartUtc),
    rawEndUtc: utcFromMsOrNull(rawEndUtc),
    startOffsetMin: startOffsetMin,
    endOffsetMin: endOffsetMin,
    rateCentsPerHour: rateCentsPerHour,
    breakMs: breakMs,
    pausedAtUtc: utcFromMsOrNull(pausedAtUtc),
    tipsCents: tipsCents,
    note: note,
    paidAtUtc: utcFromMsOrNull(paidAtUtc),
    payoutId: payoutId,
    amountCents: amountCents,
    legacyId: legacyId,
    source: source,
    createdAt: utcFromMs(createdAt),
    updatedAt: utcFromMs(updatedAt),
    deletedAt: utcFromMsOrNull(deletedAt),
  );
}

/// Conversions from domain shifts to companions.
extension ShiftToCompanion on Shift {
  /// All columns of this shift; the id is omitted when [withId] is false
  /// (insert with a new id).
  ShiftsCompanion toCompanion({bool withId = true}) => ShiftsCompanion(
    id: withId ? Value(id) : const Value.absent(),
    uuid: Value(uuid),
    jobId: Value(jobId),
    status: Value(status),
    startUtc: Value(startUtc.millisecondsSinceEpoch),
    endUtc: Value(endUtc?.millisecondsSinceEpoch),
    rawStartUtc: Value(rawStartUtc.millisecondsSinceEpoch),
    rawEndUtc: Value(rawEndUtc?.millisecondsSinceEpoch),
    startOffsetMin: Value(startOffsetMin),
    endOffsetMin: Value(endOffsetMin),
    rateCentsPerHour: Value(rateCentsPerHour),
    breakMs: Value(breakMs),
    pausedAtUtc: Value(pausedAtUtc?.millisecondsSinceEpoch),
    tipsCents: Value(tipsCents),
    note: Value(note),
    paidAtUtc: Value(paidAtUtc?.millisecondsSinceEpoch),
    payoutId: Value(payoutId),
    amountCents: Value(amountCents),
    legacyId: Value(legacyId),
    source: Value(source),
    createdAt: Value(createdAt.millisecondsSinceEpoch),
    updatedAt: Value(updatedAt.millisecondsSinceEpoch),
    deletedAt: Value(deletedAt?.millisecondsSinceEpoch),
  );
}

/// Conversions for review rows.
extension ReviewItemRowX on ReviewItemRow {
  /// The domain model (unknown reason names are ignored).
  ReviewItem toDomain() => ReviewItem(
    shiftId: shiftId,
    reasons: decodeReviewReasons(reasons),
    relatedShiftIds: {
      for (final part in related.split(',')) ?int.tryParse(part),
    },
  );
}

/// Serialises review reasons for storage.
String encodeReviewReasons(Iterable<ReviewReason> reasons) =>
    (reasons.map((r) => r.name).toList()..sort()).join(',');

/// Parses stored review reasons (unknown names are skipped).
Set<ReviewReason> decodeReviewReasons(String encoded) {
  final byName = {for (final r in ReviewReason.values) r.name: r};
  return {for (final name in encoded.split(',')) ?byName[name]};
}

/// Companion for storing [item].
ReviewItemsCompanion reviewItemCompanion(ReviewItem item) =>
    ReviewItemsCompanion.insert(
      shiftId: Value(item.shiftId),
      reasons: encodeReviewReasons(item.reasons),
      related: Value((item.relatedShiftIds.toList()..sort()).join(',')),
    );

/// Nullable-safe trimmed note: blank notes are stored as `null`.
String? normalizeNote(String? note) {
  final trimmed = note?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}
