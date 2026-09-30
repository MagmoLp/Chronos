import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../core/local_date.dart';
import '../core/money.dart';
import '../core/time.dart';
import '../domain/errors.dart';
import '../domain/finish.dart';
import '../domain/job.dart';
import '../domain/shift.dart';
import '../domain/shift_draft.dart';
import '../domain/validation.dart';
import 'database.dart';
import 'job_repository.dart';
import 'mappers.dart';

/// Outcome of finishing a shift: the running state before (for undo) and
/// the finished shift after.
final class FinishResult {
  /// Creates a result.
  const FinishResult({required this.before, required this.after});

  /// The running shift as it was before finishing.
  final Shift before;

  /// The finished shift.
  final Shift after;

  @override
  bool operator ==(Object other) =>
      other is FinishResult && other.before == before && other.after == after;

  @override
  int get hashCode => Object.hash(before, after);

  @override
  String toString() => 'FinishResult(${after.id}, ${after.amountCents} ct)';
}

/// Paid state of a shift before a change, used to undo it.
final class PaidState {
  /// Creates a snapshot.
  const PaidState({required this.shiftId, this.paidAtUtc, this.payoutId});

  /// The shift.
  final int shiftId;

  /// Previous paid time.
  final DateTime? paidAtUtc;

  /// Previous payout.
  final int? payoutId;

  @override
  bool operator ==(Object other) =>
      other is PaidState &&
      other.shiftId == shiftId &&
      other.paidAtUtc == paidAtUtc &&
      other.payoutId == payoutId;

  @override
  int get hashCode => Object.hash(shiftId, paidAtUtc, payoutId);

  @override
  String toString() => 'PaidState($shiftId, $paidAtUtc, $payoutId)';
}

/// Shifts: reactive queries and every state change of the timer and the
/// editor. All writes that touch more than one row run in a transaction.
class ShiftRepository {
  /// Creates the repository on [db]. [clock], [uuid] and [jobs] are
  /// injectable for tests.
  ShiftRepository(this._db, {Clock? clock, Uuid? uuid, JobRepository? jobs})
    : _clockOverride = clock,
      _uuid = uuid ?? const Uuid(),
      _jobs = jobs ?? JobRepository(_db, clock: clock, uuid: uuid);

  final AppDatabase _db;
  final Clock? _clockOverride;
  final Uuid _uuid;
  final JobRepository _jobs;

  Clock get _clock => _clockOverride ?? clock;

  DateTime get _now => _clock.now().toUtc();

  List<Shift> _toDomain(List<ShiftRow> rows) => [
    for (final r in rows) r.toDomain(),
  ];

  // ---------------------------------------------------------------- queries

  SimpleSelectStatement<$ShiftsTable, ShiftRow> _doneQuery({
    ShiftFilter filter = ShiftFilter.all,
    int? jobId,
  }) => _db.select(_db.shifts)
    ..where((t) {
      var e = t.status.equalsValue(ShiftStatus.done) & t.deletedAt.isNull();
      if (filter == ShiftFilter.open) e = e & t.paidAtUtc.isNull();
      if (filter == ShiftFilter.paid) e = e & t.paidAtUtc.isNotNull();
      if (jobId != null) e = e & t.jobId.equals(jobId);
      return e;
    })
    ..orderBy([
      (t) => OrderingTerm.desc(t.startUtc),
      (t) => OrderingTerm.desc(t.id),
    ]);

  /// Finished, non-deleted shifts matching [filter] (and [jobId]), newest
  /// first.
  Stream<List<Shift>> watchDone({
    ShiftFilter filter = ShiftFilter.all,
    int? jobId,
  }) => _doneQuery(filter: filter, jobId: jobId).watch().map(_toDomain);

  /// Finished, non-deleted shifts matching [filter] (and [jobId]), newest
  /// first.
  Future<List<Shift>> getDone({
    ShiftFilter filter = ShiftFilter.all,
    int? jobId,
  }) async => _toDomain(await _doneQuery(filter: filter, jobId: jobId).get());

  SimpleSelectStatement<$ShiftsTable, ShiftRow> _rangeQuery(
    LocalDateRange range, {
    int? jobId,
  }) {
    final from = range.startUtc.millisecondsSinceEpoch;
    final to = range.endUtc.millisecondsSinceEpoch;
    return _db.select(_db.shifts)
      ..where((t) {
        var e =
            t.status.equalsValue(ShiftStatus.done) &
            t.deletedAt.isNull() &
            t.startUtc.isBiggerOrEqualValue(from) &
            t.startUtc.isSmallerThanValue(to);
        if (jobId != null) e = e & t.jobId.equals(jobId);
        return e;
      })
      ..orderBy([
        (t) => OrderingTerm.desc(t.startUtc),
        (t) => OrderingTerm.desc(t.id),
      ]);
  }

  /// Finished, non-deleted shifts whose local start date lies in [range],
  /// newest first.
  Stream<List<Shift>> watchRange(LocalDateRange range, {int? jobId}) =>
      _rangeQuery(range, jobId: jobId).watch().map(_toDomain);

  /// Finished, non-deleted shifts whose local start date lies in [range],
  /// newest first.
  Future<List<Shift>> getRange(LocalDateRange range, {int? jobId}) async =>
      _toDomain(await _rangeQuery(range, jobId: jobId).get());

  SimpleSelectStatement<$ShiftsTable, ShiftRow> _runningQuery() =>
      _db.select(_db.shifts)
        ..where(
          (t) =>
              t.status.equalsValue(ShiftStatus.running) & t.deletedAt.isNull(),
        )
        ..orderBy([(t) => OrderingTerm.desc(t.id)])
        ..limit(1);

  /// The running shift (paused or not), or `null`.
  Stream<Shift?> watchRunning() => _runningQuery().watch().map(
    (rows) => rows.isEmpty ? null : rows.first.toDomain(),
  );

  /// The running shift (paused or not), or `null`.
  Future<Shift?> getRunning() async {
    final rows = await _runningQuery().get();
    return rows.isEmpty ? null : rows.first.toDomain();
  }

  /// The shift with [id] (also if soft-deleted), or `null`.
  Future<Shift?> getById(int id) async {
    final row = await (_db.select(
      _db.shifts,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row?.toDomain();
  }

  /// Watches the shift with [id].
  Stream<Shift?> watchById(int id) =>
      (_db.select(_db.shifts)..where((t) => t.id.equals(id)))
          .watchSingleOrNull()
          .map((row) => row?.toDomain());

  SimpleSelectStatement<$ShiftsTable, ShiftRow> _lastDoneQuery(int? jobId) =>
      _doneQuery(jobId: jobId)..limit(1);

  /// The most recent finished shift (optionally of [jobId]).
  Future<Shift?> lastDone({int? jobId}) async {
    final rows = await _lastDoneQuery(jobId).get();
    return rows.isEmpty ? null : rows.first.toDomain();
  }

  /// Watches the most recent finished shift (optionally of [jobId]).
  Stream<Shift?> watchLastDone({int? jobId}) =>
      _lastDoneQuery(jobId)
          .watch()
          .map((rows) => rows.isEmpty ? null : rows.first.toDomain());

  /// Non-deleted shifts overlapping `[startUtc, endUtc)`, oldest first. A
  /// running shift counts as lasting until now.
  Future<List<Shift>> findOverlaps(
    DateTime startUtc,
    DateTime endUtc, {
    int? excludeId,
  }) async {
    final start = startUtc.millisecondsSinceEpoch;
    final end = endUtc.millisecondsSinceEpoch;
    final rows =
        await (_db.select(_db.shifts)..where(
              (t) =>
                  t.deletedAt.isNull() &
                  t.startUtc.isSmallerThanValue(end) &
                  (t.status.equalsValue(ShiftStatus.running) |
                      t.endUtc.isBiggerThanValue(start)),
            ))
            .get();
    return findOverlapping(
      startUtc,
      endUtc,
      _toDomain(rows),
      now: _now,
      ignoreShiftId: excludeId,
    );
  }

  /// Number of non-deleted shifts (finished and running).
  Future<int> countActive() async {
    final count = _db.shifts.id.count();
    return (_db.selectOnly(_db.shifts)
          ..addColumns([count])
          ..where(_db.shifts.deletedAt.isNull()))
        .map((row) => row.read(count)!)
        .getSingle();
  }

  // ------------------------------------------------------------------ timer

  Future<Shift> _requireRunning() async {
    final running = await getRunning();
    if (running == null) {
      throw const ChronosException(ChronosErrorCode.noRunningShift);
    }
    return running;
  }

  Future<Shift> _reload(int id) async => (await getById(id))!;

  Future<void> _write(int id, ShiftsCompanion companion) =>
      (_db.update(_db.shifts)..where((t) => t.id.equals(id))).write(companion);

  /// Starts a timer shift for [jobId] at [startUtc] (default now) with the
  /// job's wage on that date as snapshot.
  ///
  /// Throws [ChronosErrorCode.shiftAlreadyRunning],
  /// [ChronosErrorCode.startInFuture], [ChronosErrorCode.jobNotFound] or
  /// [ChronosErrorCode.noWageRate].
  Future<Shift> start(int jobId, {DateTime? startUtc}) =>
      _db.transaction(() async {
        final now = _now;
        final start = (startUtc ?? now).toUtc();
        if (start.isAfter(now)) {
          throw ChronosException(ChronosErrorCode.startInFuture, detail: start);
        }
        if (await getRunning() != null) {
          throw const ChronosException(ChronosErrorCode.shiftAlreadyRunning);
        }
        if (await _jobs.getJob(jobId) == null) {
          throw ChronosException(ChronosErrorCode.jobNotFound, detail: jobId);
        }
        final rate = await _jobs.rateFor(jobId, LocalDate.ofInstant(start));
        if (rate == null) {
          throw ChronosException(ChronosErrorCode.noWageRate, detail: jobId);
        }
        final startMs = start.millisecondsSinceEpoch;
        final int id;
        try {
          id = await _db
              .into(_db.shifts)
              .insert(
                ShiftsCompanion.insert(
                  uuid: _uuid.v4(),
                  jobId: jobId,
                  status: ShiftStatus.running,
                  startUtc: startMs,
                  rawStartUtc: startMs,
                  startOffsetMin: offsetMinutesAt(start),
                  rateCentsPerHour: rate,
                  source: ShiftSource.timer,
                  createdAt: now.millisecondsSinceEpoch,
                  updatedAt: now.millisecondsSinceEpoch,
                ),
              );
        } on Exception {
          // The partial unique index is the last line of defence against a
          // second running shift (e.g. written by another isolate).
          if (await getRunning() != null) {
            throw const ChronosException(ChronosErrorCode.shiftAlreadyRunning);
          }
          rethrow;
        }
        return _reload(id);
      });

  /// Pauses the running shift at [atUtc] (default now; clamped to the
  /// shift's start and now). No-op if already paused.
  Future<Shift> pause({DateTime? atUtc}) => _db.transaction(() async {
    final running = await _requireRunning();
    if (running.isPaused) return running;
    final now = _now;
    var at = (atUtc ?? now).toUtc();
    if (at.isAfter(now)) at = now;
    if (at.isBefore(running.startUtc)) at = running.startUtc;
    await _write(
      running.id,
      ShiftsCompanion(
        pausedAtUtc: Value(at.millisecondsSinceEpoch),
        updatedAt: Value(now.millisecondsSinceEpoch),
      ),
    );
    return _reload(running.id);
  });

  /// Resumes the paused shift; the pause is added to its break time.
  /// No-op if not paused.
  Future<Shift> resume({DateTime? atUtc}) => _db.transaction(() async {
    final running = await _requireRunning();
    final pausedAt = running.pausedAtUtc;
    if (pausedAt == null) return running;
    final now = _now;
    final at = (atUtc ?? now).toUtc();
    final pausedMs = at.difference(pausedAt).inMilliseconds;
    await _write(
      running.id,
      ShiftsCompanion(
        breakMs: Value(running.breakMs + (pausedMs > 0 ? pausedMs : 0)),
        pausedAtUtc: const Value(null),
        updatedAt: Value(now.millisecondsSinceEpoch),
      ),
    );
    return _reload(running.id);
  });

  /// Moves the start of the running shift to [newStartUtc] ("seit 08:02"
  /// tapped). The wage snapshot follows the new start date.
  ///
  /// Throws [ChronosErrorCode.startInFuture], or
  /// [ChronosErrorCode.invalidShift] if the start would be after the start
  /// of the current pause.
  Future<Shift> adjustStart(DateTime newStartUtc) => _db.transaction(() async {
    final running = await _requireRunning();
    final now = _now;
    final start = newStartUtc.toUtc();
    if (start.isAfter(now)) {
      throw ChronosException(ChronosErrorCode.startInFuture, detail: start);
    }
    final pausedAt = running.pausedAtUtc;
    if (pausedAt != null && start.isAfter(pausedAt)) {
      throw const ChronosException(
        ChronosErrorCode.invalidShift,
        detail: [ShiftError.endNotAfterStart],
      );
    }
    var rate = running.rateCentsPerHour;
    final newDate = LocalDate.ofInstant(start);
    if (newDate != running.localStartDate) {
      rate = await _jobs.rateFor(running.jobId, newDate) ?? rate;
    }
    await _write(
      running.id,
      ShiftsCompanion(
        startUtc: Value(start.millisecondsSinceEpoch),
        rawStartUtc: Value(start.millisecondsSinceEpoch),
        startOffsetMin: Value(offsetMinutesAt(start)),
        rateCentsPerHour: Value(rate),
        updatedAt: Value(now.millisecondsSinceEpoch),
      ),
    );
    return _reload(running.id);
  });

  /// Finishes the running shift at [endUtc] (default now).
  ///
  /// The job's rounding is applied to start and end (raw times are kept),
  /// [breakMs] defaults to all pauses including one in progress, and the
  /// wage amount is computed and cached – all in one transaction.
  ///
  /// Throws [ChronosErrorCode.noRunningShift],
  /// [ChronosErrorCode.invalidAmount] (negative tips) or
  /// [ChronosErrorCode.invalidShift] with the `List<ShiftError>` as detail.
  Future<FinishResult> finish({
    DateTime? endUtc,
    int? breakMs,
    int tipsCents = 0,
    String? note,
  }) {
    if (tipsCents < 0) {
      throw ChronosException(ChronosErrorCode.invalidAmount, detail: tipsCents);
    }
    return _db.transaction(() async {
      final running = await _requireRunning();
      final job = await _jobs.getJob(running.jobId);
      final now = _now;
      final end = (endUtc ?? now).toUtc();
      final preview = previewFinish(
        running: running,
        rounding: job?.rounding ?? RoundingRule.none,
        endUtc: end,
        breakMs: breakMs,
      );
      if (!preview.isValid) {
        throw ChronosException(
          ChronosErrorCode.invalidShift,
          detail: preview.errors,
        );
      }
      await _write(
        running.id,
        ShiftsCompanion(
          status: const Value(ShiftStatus.done),
          startUtc: Value(preview.startUtc.millisecondsSinceEpoch),
          endUtc: Value(preview.endUtc.millisecondsSinceEpoch),
          rawEndUtc: Value(end.millisecondsSinceEpoch),
          endOffsetMin: Value(offsetMinutesAt(end)),
          breakMs: Value(preview.breakMs),
          pausedAtUtc: const Value(null),
          tipsCents: Value(tipsCents),
          note: Value(normalizeNote(note)),
          amountCents: Value(preview.amountCents),
          updatedAt: Value(now.millisecondsSinceEpoch),
        ),
      );
      return FinishResult(before: running, after: await _reload(running.id));
    });
  }

  /// Undoes [finish]: the shift runs again.
  ///
  /// With [restore] (the `before` of a [FinishResult]) the exact previous
  /// running state is written back; otherwise the raw start is restored and
  /// the end cleared. Throws [ChronosErrorCode.shiftNotFound] or
  /// [ChronosErrorCode.shiftAlreadyRunning] (another shift runs meanwhile).
  Future<Shift> revertFinish(int shiftId, {Shift? restore}) => _db.transaction(
    () async {
      final current = await getById(shiftId);
      if (current == null) {
        throw ChronosException(ChronosErrorCode.shiftNotFound, detail: shiftId);
      }
      if (current.isRunning && !current.isDeleted) return current;
      final other = await getRunning();
      if (other != null && other.id != shiftId) {
        throw const ChronosException(ChronosErrorCode.shiftAlreadyRunning);
      }
      final base = restore != null && restore.id == shiftId
          ? restore
          : current.copyWith(startUtc: current.rawStartUtc, pausedAtUtc: null);
      final nowMs = _now.millisecondsSinceEpoch;
      await _write(
        shiftId,
        ShiftsCompanion(
          status: const Value(ShiftStatus.running),
          startUtc: Value(base.startUtc.millisecondsSinceEpoch),
          rawStartUtc: Value(base.rawStartUtc.millisecondsSinceEpoch),
          startOffsetMin: Value(base.startOffsetMin),
          endUtc: const Value(null),
          rawEndUtc: const Value(null),
          endOffsetMin: const Value(null),
          rateCentsPerHour: Value(base.rateCentsPerHour),
          breakMs: Value(base.breakMs),
          pausedAtUtc: Value(base.pausedAtUtc?.millisecondsSinceEpoch),
          tipsCents: Value(restore != null ? base.tipsCents : 0),
          note: Value(base.note),
          amountCents: const Value(null),
          paidAtUtc: const Value(null),
          payoutId: const Value(null),
          deletedAt: const Value(null),
          updatedAt: Value(nowMs),
        ),
      );
      return _reload(shiftId);
    },
  );

  /// Discards the running shift (soft delete, can be undone with
  /// [undoDelete]). Returns the discarded shift.
  Future<Shift> discardRunning() => _db.transaction(() async {
    final running = await _requireRunning();
    final nowMs = _now.millisecondsSinceEpoch;
    await _write(
      running.id,
      ShiftsCompanion(deletedAt: Value(nowMs), updatedAt: Value(nowMs)),
    );
    return _reload(running.id);
  });

  // ----------------------------------------------------------------- editor

  List<ShiftError> _draftErrors(ShiftDraft draft) => shiftErrors(
    startUtc: draft.startUtc,
    endUtc: draft.endUtc,
    breakMs: draft.breakMs,
    tipsCents: draft.tipsCents,
  );

  /// Inserts a finished shift entered in the editor (never rounded).
  ///
  /// Uses [ShiftDraft.rateCentsPerHour] or else the job's rate on the start
  /// date. Throws [ChronosErrorCode.invalidShift] (detail: errors),
  /// [ChronosErrorCode.jobNotFound] or [ChronosErrorCode.noWageRate].
  /// Warnings are the caller's business (see `validateDraft`).
  Future<Shift> insertManual(
    ShiftDraft draft, {
    ShiftSource source = ShiftSource.manual,
  }) {
    final errors = _draftErrors(draft);
    if (errors.isNotEmpty) {
      throw ChronosException(ChronosErrorCode.invalidShift, detail: errors);
    }
    return _db.transaction(() async {
      if (await _jobs.getJob(draft.jobId) == null) {
        throw ChronosException(
          ChronosErrorCode.jobNotFound,
          detail: draft.jobId,
        );
      }
      final rate =
          draft.rateCentsPerHour ??
          await _jobs.rateFor(draft.jobId, draft.localStartDate);
      if (rate == null || rate < 0) {
        throw ChronosException(
          ChronosErrorCode.noWageRate,
          detail: draft.jobId,
        );
      }
      final nowMs = _now.millisecondsSinceEpoch;
      final start = draft.startUtc.toUtc();
      final end = draft.endUtc.toUtc();
      final id = await _db
          .into(_db.shifts)
          .insert(
            ShiftsCompanion.insert(
              uuid: _uuid.v4(),
              jobId: draft.jobId,
              status: ShiftStatus.done,
              startUtc: start.millisecondsSinceEpoch,
              endUtc: Value(end.millisecondsSinceEpoch),
              rawStartUtc: start.millisecondsSinceEpoch,
              rawEndUtc: Value(end.millisecondsSinceEpoch),
              startOffsetMin: offsetMinutesAt(start),
              endOffsetMin: Value(offsetMinutesAt(end)),
              rateCentsPerHour: rate,
              breakMs: Value(draft.breakMs),
              tipsCents: Value(draft.tipsCents),
              note: Value(normalizeNote(draft.note)),
              paidAtUtc: Value(draft.paid ? nowMs : null),
              amountCents: Value(earningsCents(draft.workedMs, rate)),
              source: source,
              createdAt: nowMs,
              updatedAt: nowMs,
            ),
          );
      return _reload(id);
    });
  }

  /// Saves editor changes to the finished shift [id]. Never creates a shift.
  ///
  /// The stored wage stays unless the draft sets a different one or the job
  /// changes (then the new job's rate on the start date applies). Changed
  /// times become the new raw times. Marking unpaid clears the payout link.
  ///
  /// Throws [ChronosErrorCode.shiftNotFound], [ChronosErrorCode.shiftIsRunning],
  /// [ChronosErrorCode.invalidShift], [ChronosErrorCode.jobNotFound] or
  /// [ChronosErrorCode.noWageRate].
  Future<Shift> update(int id, ShiftDraft draft) {
    final errors = _draftErrors(draft);
    if (errors.isNotEmpty) {
      throw ChronosException(ChronosErrorCode.invalidShift, detail: errors);
    }
    return _db.transaction(() async {
      final existing = await getById(id);
      if (existing == null || existing.isDeleted) {
        throw ChronosException(ChronosErrorCode.shiftNotFound, detail: id);
      }
      if (existing.isRunning) {
        throw const ChronosException(ChronosErrorCode.shiftIsRunning);
      }
      final jobChanged = draft.jobId != existing.jobId;
      if (jobChanged && await _jobs.getJob(draft.jobId) == null) {
        throw ChronosException(
          ChronosErrorCode.jobNotFound,
          detail: draft.jobId,
        );
      }
      int? rate;
      final requested = draft.rateCentsPerHour;
      if (requested != null &&
          !(jobChanged && requested == existing.rateCentsPerHour)) {
        rate = requested;
      } else if (jobChanged) {
        rate = await _jobs.rateFor(draft.jobId, draft.localStartDate);
      } else {
        rate = existing.rateCentsPerHour;
      }
      if (rate == null || rate < 0) {
        throw ChronosException(
          ChronosErrorCode.noWageRate,
          detail: draft.jobId,
        );
      }
      final now = _now;
      final start = draft.startUtc.toUtc();
      final end = draft.endUtc.toUtc();
      final startChanged = start != existing.startUtc;
      final endChanged = end != existing.endUtc;
      final paidAt = draft.paid ? (existing.paidAtUtc ?? now) : null;
      await _write(
        id,
        ShiftsCompanion(
          jobId: Value(draft.jobId),
          startUtc: Value(start.millisecondsSinceEpoch),
          endUtc: Value(end.millisecondsSinceEpoch),
          rawStartUtc: startChanged
              ? Value(start.millisecondsSinceEpoch)
              : const Value.absent(),
          rawEndUtc: endChanged
              ? Value(end.millisecondsSinceEpoch)
              : const Value.absent(),
          startOffsetMin: startChanged
              ? Value(offsetMinutesAt(start))
              : const Value.absent(),
          endOffsetMin: endChanged
              ? Value(offsetMinutesAt(end))
              : const Value.absent(),
          rateCentsPerHour: Value(rate),
          breakMs: Value(draft.breakMs),
          tipsCents: Value(draft.tipsCents),
          note: Value(normalizeNote(draft.note)),
          paidAtUtc: Value(paidAt?.millisecondsSinceEpoch),
          payoutId: draft.paid ? const Value.absent() : const Value(null),
          amountCents: Value(earningsCents(draft.workedMs, rate)),
          updatedAt: Value(now.millisecondsSinceEpoch),
        ),
      );
      return _reload(id);
    });
  }

  /// Copies the finished shift [id] as a new, unpaid manual shift without
  /// tips. With [onDate] the copy keeps the wall-clock times on that date
  /// (and takes the job's wage there); otherwise it has the same times and
  /// wage.
  Future<Shift> duplicate(int id, {LocalDate? onDate}) async {
    final source = await getById(id);
    if (source == null || source.isDeleted) {
      throw ChronosException(ChronosErrorCode.shiftNotFound, detail: id);
    }
    if (source.isRunning) {
      throw const ChronosException(ChronosErrorCode.shiftIsRunning);
    }
    var draft = ShiftDraft.fromShift(source)
        .copyWith(paid: false, tipsCents: 0);
    if (onDate != null) {
      final start = source.startUtc.toLocal();
      final end = source.endUtc!.toLocal();
      final dayShift = source.localStartDate.daysUntil(
        LocalDate.fromDateTime(end),
      );
      draft = draft.copyWith(
        startUtc: combineLocal(onDate, start.hour, start.minute),
        endUtc: combineLocal(onDate.addDays(dayShift), end.hour, end.minute),
        rateCentsPerHour: onDate == source.localStartDate
            ? source.rateCentsPerHour
            : null,
      );
      if (!draft.endUtc.isAfter(draft.startUtc)) {
        // A DST gap swallowed the difference; keep the original duration.
        draft = draft.copyWith(
          endUtc: draft.startUtc.add(
            Duration(milliseconds: source.durationMs!),
          ),
        );
      }
    }
    return insertManual(draft);
  }

  // ------------------------------------------------------- delete and paid

  /// Soft-deletes [ids]; returns the shifts that were deleted by this call.
  Future<List<Shift>> softDelete(Iterable<int> ids) => _db.transaction(
    () async {
      final idList = ids.toSet().toList();
      final rows = await (_db.select(
        _db.shifts,
      )..where((t) => t.id.isIn(idList) & t.deletedAt.isNull())).get();
      if (rows.isEmpty) return const <Shift>[];
      final nowMs = _now.millisecondsSinceEpoch;
      final affected = [for (final r in rows) r.id];
      await (_db.update(_db.shifts)..where((t) => t.id.isIn(affected))).write(
        ShiftsCompanion(deletedAt: Value(nowMs), updatedAt: Value(nowMs)),
      );
      return _toDomain(
        await (_db.select(_db.shifts)..where((t) => t.id.isIn(affected))).get(),
      );
    },
  );

  /// Restores soft-deleted [ids]. Throws
  /// [ChronosErrorCode.shiftAlreadyRunning] if a restored running shift
  /// would be the second running shift (nothing is restored then).
  Future<void> undoDelete(Iterable<int> ids) => _db.transaction(() async {
    final idList = ids.toSet().toList();
    final rows = await (_db.select(
      _db.shifts,
    )..where((t) => t.id.isIn(idList) & t.deletedAt.isNotNull())).get();
    final restoringRunning = rows
        .where((r) => r.status == ShiftStatus.running)
        .toList();
    if (restoringRunning.length > 1 ||
        (restoringRunning.isNotEmpty && await getRunning() != null)) {
      throw const ChronosException(ChronosErrorCode.shiftAlreadyRunning);
    }
    if (rows.isEmpty) return;
    await (_db.update(
      _db.shifts,
    )..where((t) => t.id.isIn([for (final r in rows) r.id]))).write(
      ShiftsCompanion(
        deletedAt: const Value(null),
        updatedAt: Value(_now.millisecondsSinceEpoch),
      ),
    );
  });

  /// Permanently removes shifts soft-deleted before [before]. Returns the
  /// number of removed shifts.
  Future<int> purgeDeleted({required DateTime before}) =>
      (_db.delete(_db.shifts)..where(
            (t) =>
                t.deletedAt.isNotNull() &
                t.deletedAt.isSmallerThanValue(
                  before.toUtc().millisecondsSinceEpoch,
                ),
          ))
          .go();

  /// Marks finished, non-deleted [ids] as paid (now) or open. Returns the
  /// previous states for [restorePaidStates]. Marking open clears the
  /// payout link.
  Future<List<PaidState>> setPaid(Iterable<int> ids, bool paid) =>
      _db.transaction(() async {
        final idList = ids.toSet().toList();
        final rows =
            await (_db.select(_db.shifts)..where(
                  (t) =>
                      t.id.isIn(idList) &
                      t.deletedAt.isNull() &
                      t.status.equalsValue(ShiftStatus.done),
                ))
                .get();
        final previous = [
          for (final r in rows)
            PaidState(
              shiftId: r.id,
              paidAtUtc: utcFromMsOrNull(r.paidAtUtc),
              payoutId: r.payoutId,
            ),
        ];
        final changed = [
          for (final r in rows)
            if ((r.paidAtUtc != null) != paid) r.id,
        ];
        if (changed.isNotEmpty) {
          final nowMs = _now.millisecondsSinceEpoch;
          await (_db.update(
            _db.shifts,
          )..where((t) => t.id.isIn(changed))).write(
            ShiftsCompanion(
              paidAtUtc: Value(paid ? nowMs : null),
              payoutId: const Value(null),
              updatedAt: Value(nowMs),
            ),
          );
        }
        return previous;
      });

  /// Writes back paid states captured by [setPaid].
  Future<void> restorePaidStates(Iterable<PaidState> states) =>
      _db.transaction(() async {
        final nowMs = _now.millisecondsSinceEpoch;
        for (final s in states) {
          await _write(
            s.shiftId,
            ShiftsCompanion(
              paidAtUtc: Value(s.paidAtUtc?.millisecondsSinceEpoch),
              payoutId: Value(s.payoutId),
              updatedAt: Value(nowMs),
            ),
          );
        }
      });
}
