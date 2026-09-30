import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../core/local_date.dart';
import '../core/money.dart';
import '../domain/errors.dart';
import '../domain/job.dart';
import '../domain/shift.dart';
import '../domain/wage_rate.dart';
import 'database.dart';
import 'mappers.dart';

/// Jobs and their wage history.
class JobRepository {
  /// Creates the repository on [db]. [clock] and [uuid] are injectable for
  /// tests.
  JobRepository(this._db, {Clock? clock, Uuid? uuid})
    : _clockOverride = clock,
      _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final Clock? _clockOverride;
  final Uuid _uuid;

  Clock get _clock => _clockOverride ?? clock;

  int get _nowMs => _clock.now().toUtc().millisecondsSinceEpoch;

  SimpleSelectStatement<$JobsTable, JobRow> _jobsQuery(bool includeArchived) {
    final query = _db.select(_db.jobs)
      ..orderBy([
        (t) => OrderingTerm(expression: t.sortOrder),
        (t) => OrderingTerm(expression: t.id),
      ]);
    if (!includeArchived) query.where((t) => t.archived.equals(false));
    return query;
  }

  /// All jobs ordered by `sortOrder` (optionally without archived ones).
  Stream<List<Job>> watchJobs({bool includeArchived = true}) =>
      _jobsQuery(includeArchived)
          .watch()
          .map((rows) => [for (final r in rows) r.toDomain()]);

  /// All jobs ordered by `sortOrder` (optionally without archived ones).
  Future<List<Job>> getJobs({bool includeArchived = true}) async => [
    for (final r in await _jobsQuery(includeArchived).get()) r.toDomain(),
  ];

  /// The job with [id], or `null`.
  Future<Job?> getJob(int id) async {
    final row = await (_db.select(
      _db.jobs,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row?.toDomain();
  }

  /// Watches the job with [id].
  Stream<Job?> watchJob(int id) =>
      (_db.select(_db.jobs)..where((t) => t.id.equals(id)))
          .watchSingleOrNull()
          .map((row) => row?.toDomain());

  /// Creates a job with its first wage rate (valid from [validFrom], default
  /// today) and returns it.
  ///
  /// Throws [ChronosException] with [ChronosErrorCode.emptyName] or
  /// [ChronosErrorCode.invalidAmount].
  Future<Job> createJob({
    required String name,
    required int centsPerHour,
    int colorArgb = kDefaultJobColorArgb,
    RoundingRule rounding = RoundingRule.none,
    LocalDate? validFrom,
  }) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw const ChronosException(ChronosErrorCode.emptyName);
    }
    if (centsPerHour < 0) {
      throw ChronosException(
        ChronosErrorCode.invalidAmount,
        detail: centsPerHour,
      );
    }
    return _db.transaction(() async {
      final now = _nowMs;
      final maxOrder = _db.jobs.sortOrder.max();
      final currentMax = await (_db.selectOnly(
        _db.jobs,
      )..addColumns([maxOrder])).map((row) => row.read(maxOrder)).getSingle();
      final id = await _db
          .into(_db.jobs)
          .insert(
            JobsCompanion.insert(
              uuid: _uuid.v4(),
              name: trimmed,
              colorArgb: colorArgb,
              rounding: rounding,
              sortOrder: Value((currentMax ?? -1) + 1),
              createdAt: now,
              updatedAt: now,
            ),
          );
      await _db
          .into(_db.wageRates)
          .insert(
            WageRatesCompanion.insert(
              jobId: id,
              validFrom: (validFrom ?? LocalDate.today(_clock)).key,
              centsPerHour: centsPerHour,
            ),
          );
      return (await getJob(id))!;
    });
  }

  /// Saves name, colour, rounding, archive flag and order of [job].
  ///
  /// Throws [ChronosErrorCode.jobNotFound], [ChronosErrorCode.emptyName] or
  /// [ChronosErrorCode.lastActiveJob] (archiving the only active job).
  Future<Job> updateJob(Job job) {
    final trimmed = job.name.trim();
    if (trimmed.isEmpty) {
      throw const ChronosException(ChronosErrorCode.emptyName);
    }
    return _db.transaction(() async {
      final existing = await getJob(job.id);
      if (existing == null) {
        throw ChronosException(ChronosErrorCode.jobNotFound, detail: job.id);
      }
      if (job.archived && !existing.archived) {
        await _ensureAnotherActive(job.id);
      }
      await (_db.update(_db.jobs)..where((t) => t.id.equals(job.id))).write(
        JobsCompanion(
          name: Value(trimmed),
          colorArgb: Value(job.colorArgb),
          rounding: Value(job.rounding),
          archived: Value(job.archived),
          sortOrder: Value(job.sortOrder),
          updatedAt: Value(_nowMs),
        ),
      );
      return (await getJob(job.id))!;
    });
  }

  /// Archives or restores a job. At least one active job must remain.
  Future<Job> setArchived(int jobId, bool archived) async {
    final job = await getJob(jobId);
    if (job == null) {
      throw ChronosException(ChronosErrorCode.jobNotFound, detail: jobId);
    }
    return updateJob(job.copyWith(archived: archived));
  }

  Future<void> _ensureAnotherActive(int jobId) async {
    final others = await (_db.select(
      _db.jobs,
    )..where((t) => t.archived.equals(false) & t.id.equals(jobId).not())).get();
    if (others.isEmpty) {
      throw const ChronosException(ChronosErrorCode.lastActiveJob);
    }
  }

  /// Stores the order of jobs: position in [jobIds] becomes `sortOrder`.
  Future<void> reorder(List<int> jobIds) => _db.transaction(() async {
    final now = _nowMs;
    for (var i = 0; i < jobIds.length; i++) {
      await (_db.update(_db.jobs)..where((t) => t.id.equals(jobIds[i]))).write(
        JobsCompanion(sortOrder: Value(i), updatedAt: Value(now)),
      );
    }
  });

  SimpleSelectStatement<$WageRatesTable, WageRateRow> _ratesQuery(int jobId) =>
      _db.select(_db.wageRates)
        ..where((t) => t.jobId.equals(jobId))
        ..orderBy([(t) => OrderingTerm.desc(t.validFrom)]);

  /// Wage history of [jobId], newest first.
  Stream<List<WageRate>> watchRates(int jobId) =>
      _ratesQuery(jobId)
          .watch()
          .map((rows) => [for (final r in rows) r.toDomain()]);

  /// Wage history of [jobId], newest first.
  Future<List<WageRate>> getRates(int jobId) async => [
    for (final r in await _ratesQuery(jobId).get()) r.toDomain(),
  ];

  /// The rate of [jobId] on [date] (see [rateForDate]); `null` if the job
  /// has no rates.
  Future<int?> rateFor(int jobId, LocalDate date) async =>
      rateForDate(await getRates(jobId), date);

  /// Adds (or replaces) the rate valid from [validFrom].
  ///
  /// Existing shifts keep their wage snapshot unless [recalcOpenFromDate] is
  /// set: then unpaid, finished, non-deleted shifts of the job starting on or
  /// after [validFrom] – and a running shift of the job started in that
  /// range – get the rate that now applies on their date, and their amount is
  /// recomputed. Returns the number of re-priced shifts.
  Future<int> addRate(
    int jobId, {
    required LocalDate validFrom,
    required int centsPerHour,
    bool recalcOpenFromDate = false,
  }) {
    if (centsPerHour < 0) {
      throw ChronosException(
        ChronosErrorCode.invalidAmount,
        detail: centsPerHour,
      );
    }
    return _db.transaction(() async {
      if (await getJob(jobId) == null) {
        throw ChronosException(ChronosErrorCode.jobNotFound, detail: jobId);
      }
      await _db
          .into(_db.wageRates)
          .insert(
            WageRatesCompanion.insert(
              jobId: jobId,
              validFrom: validFrom.key,
              centsPerHour: centsPerHour,
            ),
            onConflict: DoUpdate(
              (_) => WageRatesCompanion(centsPerHour: Value(centsPerHour)),
              target: [_db.wageRates.jobId, _db.wageRates.validFrom],
            ),
          );
      if (!recalcOpenFromDate) return 0;
      return _repriceOpenShifts(jobId, validFrom);
    });
  }

  Future<int> _repriceOpenShifts(int jobId, LocalDate from) async {
    final rates = await getRates(jobId);
    final fromMs = from.startUtc.millisecondsSinceEpoch;
    final rows =
        await (_db.select(_db.shifts)..where(
              (t) =>
                  t.jobId.equals(jobId) &
                  t.deletedAt.isNull() &
                  t.paidAtUtc.isNull() &
                  t.startUtc.isBiggerOrEqualValue(fromMs),
            ))
            .get();
    var count = 0;
    final now = _nowMs;
    for (final row in rows) {
      final shift = row.toDomain();
      final rate = rateForDate(rates, shift.localStartDate);
      if (rate == null || rate == shift.rateCentsPerHour) continue;
      await (_db.update(_db.shifts)..where((t) => t.id.equals(shift.id))).write(
        ShiftsCompanion(
          rateCentsPerHour: Value(rate),
          amountCents: Value(
            shift.status == ShiftStatus.done
                ? earningsCents(shift.workedMs, rate)
                : null,
          ),
          updatedAt: Value(now),
        ),
      );
      count++;
    }
    return count;
  }

  /// Removes a wage rate. The last rate of a job cannot be removed
  /// ([ChronosErrorCode.noWageRate]). Shift snapshots are not changed.
  Future<void> deleteRate(int rateId) => _db.transaction(() async {
    final row = await (_db.select(
      _db.wageRates,
    )..where((t) => t.id.equals(rateId))).getSingleOrNull();
    if (row == null) return;
    final count = await (_db.select(
      _db.wageRates,
    )..where((t) => t.jobId.equals(row.jobId))).get();
    if (count.length <= 1) {
      throw const ChronosException(ChronosErrorCode.noWageRate);
    }
    await (_db.delete(_db.wageRates)..where((t) => t.id.equals(rateId))).go();
  });
}
