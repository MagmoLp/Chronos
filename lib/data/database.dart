import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../domain/job.dart';
import '../domain/shift.dart';

part 'database.g.dart';

/// Jobs / employers.
@DataClassName('JobRow')
class Jobs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  TextColumn get name => text()();
  IntColumn get colorArgb => integer()();
  TextColumn get rounding => textEnum<RoundingRule>()();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  /// UTC epoch ms.
  IntColumn get createdAt => integer()();

  /// UTC epoch ms.
  IntColumn get updatedAt => integer()();
}

/// Wage history per job.
@DataClassName('WageRateRow')
@TableIndex(
  name: 'wage_rates_job_valid_from',
  columns: {#jobId, #validFrom},
  unique: true,
)
class WageRates extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get jobId =>
      integer().references(Jobs, #id, onDelete: KeyAction.cascade)();

  /// Local date as `yyyymmdd`.
  IntColumn get validFrom => integer()();
  IntColumn get centsPerHour => integer()();
}

/// Recorded payouts.
@DataClassName('PayoutRow')
class Payouts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();

  /// `null` = all jobs.
  IntColumn get jobId => integer().nullable().references(Jobs, #id)();

  /// Local date as `yyyymmdd`.
  IntColumn get untilDate => integer()();

  /// Local date as `yyyymmdd`.
  IntColumn get paidOn => integer()();
  IntColumn get expectedCents => integer()();
  IntColumn get receivedCents => integer()();
  TextColumn get note => text().nullable()();

  /// UTC epoch ms.
  IntColumn get createdAt => integer()();
}

/// Shifts. All instants are UTC epoch ms.
@DataClassName('ShiftRow')
@TableIndex(name: 'shifts_start', columns: {#startUtc})
@TableIndex(name: 'shifts_job_start', columns: {#jobId, #startUtc})
@TableIndex(name: 'shifts_payout', columns: {#payoutId})
@TableIndex(name: 'shifts_status', columns: {#status})
@TableIndex.sql(
  'CREATE UNIQUE INDEX shifts_one_running ON shifts (status) '
  "WHERE status = 'running' AND deleted_at IS NULL",
)
class Shifts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  IntColumn get jobId => integer().references(Jobs, #id)();
  TextColumn get status => textEnum<ShiftStatus>()();
  IntColumn get startUtc => integer()();
  IntColumn get endUtc => integer().nullable()();
  IntColumn get rawStartUtc => integer()();
  IntColumn get rawEndUtc => integer().nullable()();
  IntColumn get startOffsetMin => integer()();
  IntColumn get endOffsetMin => integer().nullable()();
  IntColumn get rateCentsPerHour => integer()();
  IntColumn get breakMs => integer().withDefault(const Constant(0))();
  IntColumn get pausedAtUtc => integer().nullable()();
  IntColumn get tipsCents => integer().withDefault(const Constant(0))();
  TextColumn get note => text().nullable()();
  IntColumn get paidAtUtc => integer().nullable()();
  IntColumn get payoutId => integer().nullable().references(
    Payouts,
    #id,
    onDelete: KeyAction.setNull,
  )();
  IntColumn get amountCents => integer().nullable()();
  TextColumn get legacyId => text().nullable()();
  TextColumn get source => textEnum<ShiftSource>()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();
}

/// Key/value store for migration state and other internal flags.
@DataClassName('MetaRow')
class Meta extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

/// Migrated shifts the user should review.
@DataClassName('ReviewItemRow')
class ReviewItems extends Table {
  IntColumn get shiftId =>
      integer().references(Shifts, #id, onDelete: KeyAction.cascade)();

  /// Comma-separated `ReviewReason` names.
  TextColumn get reasons => text()();

  /// Comma-separated related shift ids.
  TextColumn get related => text().withDefault(const Constant(''))();

  @override
  Set<Column<Object>> get primaryKey => {shiftId};
}

/// v1 entries that could not be imported (never dropped silently).
@DataClassName('LegacyErrorRow')
class LegacyErrors extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Where the value came from, e.g. `work_entries[3]` or `active_session`.
  TextColumn get origin => text()();

  /// The raw value (JSON-encoded when it was not a string).
  TextColumn get raw => text()();

  /// Machine-readable error code (`LegacyErrorCode` name).
  TextColumn get code => text()();

  /// Diagnostic detail (exception text), not shown to users directly.
  TextColumn get message => text().nullable()();

  /// UTC epoch ms.
  IntColumn get createdAt => integer()();
}

/// The Chronos SQLite database (drift). Single source of truth for jobs,
/// wages, shifts and payouts.
@DriftDatabase(
  tables: [Jobs, WageRates, Payouts, Shifts, Meta, ReviewItems, LegacyErrors],
)
class AppDatabase extends _$AppDatabase {
  /// Opens the database on [executor] (tests: `NativeDatabase.memory()`).
  AppDatabase(super.executor);

  /// Opens the app database file `chronos` in the app's documents folder,
  /// shared across isolates so notification actions see the same data.
  factory AppDatabase.open() => AppDatabase(
    driftDatabase(
      name: 'chronos',
      native: const DriftNativeOptions(shareAcrossIsolates: true),
    ),
  );

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  /// Reads a meta value.
  Future<String?> getMeta(String key) async {
    final row = await (select(
      meta,
    )..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  /// Writes a meta value.
  Future<void> setMeta(String key, String value) =>
      into(meta)
          .insertOnConflictUpdate(MetaCompanion.insert(key: key, value: value));

  /// Removes a meta value.
  Future<void> deleteMeta(String key) =>
      (delete(meta)..where((t) => t.key.equals(key))).go();

  /// Deletes all user data (shifts, payouts, wages, jobs, review items and
  /// legacy errors) but keeps [meta], so the v1 migration does not run again.
  Future<void> deleteAllData() => transaction(() async {
    await delete(reviewItems).go();
    await delete(legacyErrors).go();
    await delete(shifts).go();
    await delete(payouts).go();
    await delete(wageRates).go();
    await delete(jobs).go();
  });
}
