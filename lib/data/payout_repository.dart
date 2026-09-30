import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../core/local_date.dart';
import '../domain/errors.dart';
import '../domain/payout.dart';
import '../domain/shift.dart';
import 'database.dart';
import 'mappers.dart';

/// Payouts ("Auszahlung erfassen") and the shifts they settle.
class PayoutRepository {
  /// Creates the repository on [db].
  PayoutRepository(this._db, {Clock? clock, Uuid? uuid})
    : _clockOverride = clock,
      _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final Clock? _clockOverride;
  final Uuid _uuid;

  Clock get _clock => _clockOverride ?? clock;

  SimpleSelectStatement<$PayoutsTable, PayoutRow> _payoutsQuery(int? jobId) {
    final query = _db.select(_db.payouts)
      ..orderBy([
        (t) => OrderingTerm.desc(t.paidOn),
        (t) => OrderingTerm.desc(t.id),
      ]);
    if (jobId != null) query.where((t) => t.jobId.equals(jobId));
    return query;
  }

  /// All payouts, newest first (optionally only those of [jobId]).
  Stream<List<Payout>> watchPayouts({int? jobId}) =>
      _payoutsQuery(jobId)
          .watch()
          .map((rows) => [for (final r in rows) r.toDomain()]);

  /// All payouts, newest first (optionally only those of [jobId]).
  Future<List<Payout>> getPayouts({int? jobId}) async => [
    for (final r in await _payoutsQuery(jobId).get()) r.toDomain(),
  ];

  /// The payout with [id], or `null`.
  Future<Payout?> getById(int id) async {
    final row = await (_db.select(
      _db.payouts,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row?.toDomain();
  }

  SimpleSelectStatement<$ShiftsTable, ShiftRow> _openQuery(
    LocalDate until,
    int? jobId,
  ) {
    final endMs = until.addDays(1).startUtc.millisecondsSinceEpoch;
    return _db.select(_db.shifts)..where((t) {
      var e =
          t.status.equalsValue(ShiftStatus.done) &
          t.deletedAt.isNull() &
          t.paidAtUtc.isNull() &
          t.startUtc.isSmallerThanValue(endMs);
      if (jobId != null) e = e & t.jobId.equals(jobId);
      return e;
    });
  }

  /// The open shifts a payout until [until] (inclusive, local start date)
  /// would settle, optionally only of [jobId].
  Future<PayoutSelection> preview({
    required LocalDate until,
    int? jobId,
  }) async {
    final rows = await _openQuery(until, jobId).get();
    return selectForPayout(
      [for (final r in rows) r.toDomain()],
      until: until,
      jobId: jobId,
    );
  }

  /// Reactive [preview].
  Stream<PayoutSelection> watchPreview({
    required LocalDate until,
    int? jobId,
  }) => _openQuery(until, jobId).watch().map(
    (rows) => selectForPayout(
      [for (final r in rows) r.toDomain()],
      until: until,
      jobId: jobId,
    ),
  );

  /// Records a payout and marks the selected shifts paid, in one
  /// transaction. [receivedCents] defaults to the expected amount,
  /// [paidOn] to today.
  ///
  /// Throws [ChronosErrorCode.nothingToPayOut] or
  /// [ChronosErrorCode.invalidAmount].
  Future<Payout> create({
    required LocalDate until,
    int? jobId,
    int? receivedCents,
    LocalDate? paidOn,
    String? note,
  }) {
    if (receivedCents != null && receivedCents < 0) {
      throw ChronosException(
        ChronosErrorCode.invalidAmount,
        detail: receivedCents,
      );
    }
    return _db.transaction(() async {
      final selection = await preview(until: until, jobId: jobId);
      if (selection.isEmpty) {
        throw const ChronosException(ChronosErrorCode.nothingToPayOut);
      }
      final now = _clock.now().toUtc();
      final id = await _db
          .into(_db.payouts)
          .insert(
            PayoutsCompanion.insert(
              uuid: _uuid.v4(),
              jobId: Value(jobId),
              untilDate: until.key,
              paidOn: (paidOn ?? LocalDate.ofInstant(now)).key,
              expectedCents: selection.expectedCents,
              receivedCents: receivedCents ?? selection.expectedCents,
              note: Value(normalizeNote(note)),
              createdAt: now.millisecondsSinceEpoch,
            ),
          );
      await (_db.update(
        _db.shifts,
      )..where((t) => t.id.isIn(selection.shiftIds))).write(
        ShiftsCompanion(
          paidAtUtc: Value(now.millisecondsSinceEpoch),
          payoutId: Value(id),
          updatedAt: Value(now.millisecondsSinceEpoch),
        ),
      );
      return (await getById(id))!;
    });
  }

  /// Undoes a payout: its shifts become open again and the payout is
  /// removed. Returns the number of shifts reopened.
  Future<int> undo(int payoutId) => _db.transaction(() async {
    final nowMs = _clock.now().toUtc().millisecondsSinceEpoch;
    final reopened =
        await (_db.update(
          _db.shifts,
        )..where((t) => t.payoutId.equals(payoutId))).write(
          ShiftsCompanion(
            paidAtUtc: const Value(null),
            payoutId: const Value(null),
            updatedAt: Value(nowMs),
          ),
        );
    await (_db.delete(_db.payouts)..where((t) => t.id.equals(payoutId))).go();
    return reopened;
  });
}
