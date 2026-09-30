import 'dart:convert';
import 'dart:io';

import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../core/local_date.dart';
import '../../core/money.dart';
import '../../core/time.dart';
import '../../domain/errors.dart';
import '../../domain/job.dart';
import '../../domain/review.dart';
import '../../domain/shift.dart';
import '../database.dart';
import '../mappers.dart';
import 'legacy_models.dart';
import 'legacy_parser.dart';

/// Reads the raw v1 preference values.
abstract interface class LegacySource {
  /// The three v1 values (any of them may be `null`).
  Future<LegacyRawData> read();
}

/// Reads v1 data through the **legacy** `SharedPreferences` API.
///
/// `SharedPreferencesAsync`/`WithCache` read a different store on Android
/// (DataStore) and would see nothing. The keys are never deleted here.
class SharedPreferencesLegacySource implements LegacySource {
  /// Creates the source.
  const SharedPreferencesLegacySource();

  /// v1 key of the work log.
  static const String keyWorkEntries = 'work_entries';

  /// v1 key of the settings.
  static const String keyAppSettings = 'app_settings';

  /// v1 key of the running session.
  static const String keyActiveSession = 'active_session';

  @override
  Future<LegacyRawData> read() async {
    final prefs = await SharedPreferences.getInstance();
    return LegacyRawData(
      workEntries: prefs.get(keyWorkEntries),
      appSettings: prefs.get(keyAppSettings),
      activeSession: prefs.get(keyActiveSession),
    );
  }
}

/// Imports v1 data (shared_preferences) into the database, once.
///
/// Idempotent: a meta marker records the migration, so it can be checked on
/// every start (an Auto-Backup restore can bring v1 data back). The raw
/// values are first saved verbatim as `legacy_backup_v1.json`; the import
/// itself is one transaction; each entry is converted on its own and
/// failures are stored, never dropped.
class LegacyMigrator {
  /// Creates the migrator. [backupDirectory] returns the folder for the raw
  /// backup (app documents folder in production).
  LegacyMigrator({
    required this._db,
    required this._source,
    required this._backupDirectory,
    Clock? clock,
    Uuid? uuid,
  }) : _clockOverride = clock,
       _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final LegacySource _source;
  final Future<Directory> Function() _backupDirectory;
  final Clock? _clockOverride;
  final Uuid _uuid;

  Clock get _clock => _clockOverride ?? clock;

  /// Meta key: migration time (UTC ms).
  static const String kMetaMigratedAt = 'legacy_v1.migrated_at';

  /// Meta key: id of the created job.
  static const String kMetaJobId = 'legacy_v1.job_id';

  /// Meta key: id of the created wage rate.
  static const String kMetaRateId = 'legacy_v1.rate_id';

  /// Meta key: number of imported shifts.
  static const String kMetaImported = 'legacy_v1.imported';

  /// Meta key: '1' once the migrated wage is plausible or confirmed.
  static const String kMetaWageConfirmed = 'legacy_v1.wage_confirmed';

  /// File name of the raw backup.
  static const String backupFileName = 'legacy_backup_v1.json';

  /// First valid date of the wage rate when there are no entries.
  static final LocalDate fallbackValidFrom = LocalDate(2000, 1, 1);

  /// Whether v1 data was already migrated.
  Future<bool> isMigrated() async => await _db.getMeta(kMetaMigratedAt) != null;

  /// The raw v1 values as JSON (for "share raw data" on the recovery screen).
  Future<String> exportRawJson() async =>
      const JsonEncoder.withIndent('  ')
          .convert((await _source.read()).toJson());

  /// Runs the migration if v1 data exists and was not migrated yet.
  ///
  /// [defaultJobName] is the (localized) name of the created job, e.g.
  /// "Mein Job"; the job rounds to 15 min like v1 did.
  Future<LegacyMigrationReport> run({
    required String defaultJobName,
    int colorArgb = kDefaultJobColorArgb,
  }) async {
    final name = defaultJobName.trim();
    if (name.isEmpty) {
      throw ArgumentError.value(defaultJobName, 'defaultJobName');
    }
    if (await isMigrated()) return LegacyMigrationReport.alreadyMigrated;
    final raw = await _source.read();
    if (raw.isEmpty) return LegacyMigrationReport.noLegacyData;

    String? backupPath;
    String? backupError;
    try {
      backupPath = await _writeBackup(raw);
    } on Object catch (e) {
      backupError = e.toString();
    }

    final settings = parseLegacySettings(raw.appSettings);
    final parsed = parseLegacyWorkEntries(raw.workEntries);
    final session = parseLegacyActiveSession(raw.activeSession);
    final failures = <LegacyFailure>[
      ?settings.failure,
      ...parsed.failures,
      ?session.failure,
    ];
    final wage = settings.wageCents;
    final plausibility = checkWagePlausibility(wage);

    var validFrom = fallbackValidFrom;
    final dates = [
      for (final e in parsed.entries) LocalDate.ofInstant(e.startUtc),
      if (session.startUtc case final start?) LocalDate.ofInstant(start),
    ];
    if (dates.isNotEmpty) validFrom = dates.reduce(LocalDate.min);

    var activeImported = false;
    var reviewCount = 0;
    final imported = <Shift>[];
    late final int jobId;

    await _db.transaction(() async {
      final now = _clock.now().toUtc();
      final nowMs = now.millisecondsSinceEpoch;
      final maxOrder = _db.jobs.sortOrder.max();
      final currentMax = await (_db.selectOnly(
        _db.jobs,
      )..addColumns([maxOrder])).map((row) => row.read(maxOrder)).getSingle();
      jobId = await _db
          .into(_db.jobs)
          .insert(
            JobsCompanion.insert(
              uuid: _uuid.v4(),
              name: name,
              colorArgb: colorArgb,
              rounding: RoundingRule.nearest15,
              sortOrder: Value((currentMax ?? -1) + 1),
              createdAt: nowMs,
              updatedAt: nowMs,
            ),
          );
      final rateId = await _db
          .into(_db.wageRates)
          .insert(
            WageRatesCompanion.insert(
              jobId: jobId,
              validFrom: validFrom.key,
              centsPerHour: wage,
            ),
          );

      for (final entry in parsed.entries) {
        try {
          final workedMs = entry.endUtc
              .difference(entry.startUtc)
              .inMilliseconds;
          final id = await _db
              .into(_db.shifts)
              .insert(
                ShiftsCompanion.insert(
                  uuid: _uuid.v4(),
                  jobId: jobId,
                  status: ShiftStatus.done,
                  startUtc: entry.startUtc.millisecondsSinceEpoch,
                  endUtc: Value(entry.endUtc.millisecondsSinceEpoch),
                  rawStartUtc: entry.startUtc.millisecondsSinceEpoch,
                  rawEndUtc: Value(entry.endUtc.millisecondsSinceEpoch),
                  startOffsetMin: entry.startOffsetMin,
                  endOffsetMin: Value(entry.endOffsetMin),
                  rateCentsPerHour: wage,
                  paidAtUtc: Value(entry.isPaid ? nowMs : null),
                  amountCents: Value(earningsCents(workedMs, wage)),
                  legacyId: Value(entry.legacyId),
                  source: ShiftSource.legacy,
                  createdAt: nowMs,
                  updatedAt: nowMs,
                ),
              );
          final row = await (_db.select(
            _db.shifts,
          )..where((t) => t.id.equals(id))).getSingle();
          imported.add(row.toDomain());
        } on Object catch (e) {
          failures.add(
            LegacyFailure(
              origin: entry.origin,
              raw: entry.raw,
              code: LegacyErrorCode.insertFailed,
              message: e.toString(),
            ),
          );
        }
      }

      final sessionStart = session.startUtc;
      if (sessionStart != null) {
        final running =
            await (_db.select(_db.shifts)..where(
                  (t) =>
                      t.status.equalsValue(ShiftStatus.running) &
                      t.deletedAt.isNull(),
                ))
                .get();
        if (running.isNotEmpty) {
          failures.add(
            LegacyFailure(
              origin: 'active_session',
              raw: raw.activeSession.toString(),
              code: LegacyErrorCode.runningShiftExists,
            ),
          );
        } else {
          final ms = sessionStart.millisecondsSinceEpoch;
          await _db
              .into(_db.shifts)
              .insert(
                ShiftsCompanion.insert(
                  uuid: _uuid.v4(),
                  jobId: jobId,
                  status: ShiftStatus.running,
                  startUtc: ms,
                  rawStartUtc: ms,
                  startOffsetMin: offsetMinutesAt(sessionStart),
                  rateCentsPerHour: wage,
                  source: ShiftSource.legacy,
                  createdAt: nowMs,
                  updatedAt: nowMs,
                ),
              );
          activeImported = true;
        }
      }

      final review = computeReviewItems(imported);
      await _db.batch((batch) {
        batch.insertAll(_db.reviewItems, [
          for (final i in review) reviewItemCompanion(i),
        ]);
        batch.insertAll(_db.legacyErrors, [
          for (final f in failures)
            LegacyErrorsCompanion.insert(
              origin: f.origin,
              raw: f.raw,
              code: f.code.name,
              message: Value(f.message),
              createdAt: nowMs,
            ),
        ]);
      });
      reviewCount = review.length;

      await _db.setMeta(kMetaMigratedAt, '$nowMs');
      await _db.setMeta(kMetaJobId, '$jobId');
      await _db.setMeta(kMetaRateId, '$rateId');
      await _db.setMeta(kMetaImported, '${imported.length}');
      await _db.setMeta(
        kMetaWageConfirmed,
        plausibility.isPlausible ? '1' : '0',
      );
    });

    return LegacyMigrationReport(
      status: LegacyMigrationStatus.migrated,
      importedCount: imported.length,
      failures: List.unmodifiable(failures),
      activeSessionImported: activeImported,
      jobId: jobId,
      wageCentsPerHour: wage,
      wagePlausibility: plausibility,
      reviewCount: reviewCount,
      backupPath: backupPath,
      backupError: backupError,
      language: settings.language,
    );
  }

  Future<String> _writeBackup(LegacyRawData raw) async {
    final dir = await _backupDirectory();
    await dir.create(recursive: true);
    final content = const JsonEncoder.withIndent('  ').convert({
      'format': 'chronos-legacy-v1-backup',
      'backedUpAt': _clock.now().toUtc().toIso8601String(),
      'keys': raw.toJson(),
    });
    var file = File(p.join(dir.path, backupFileName));
    if (file.existsSync()) {
      // Keep the first backup; only add another if the data differs.
      try {
        final existing = jsonDecode(await file.readAsString());
        if (existing is Map &&
            jsonEncode(existing['keys']) == jsonEncode(raw.toJson())) {
          return file.path;
        }
      } on FormatException {
        // Unreadable old backup: keep it and write a new one next to it.
      }
      file = File(
        p.join(
          dir.path,
          'legacy_backup_v1_${_clock.now().toUtc().millisecondsSinceEpoch}.json',
        ),
      );
    }
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(content, flush: true);
    await tmp.rename(file.path);
    return file.path;
  }

  /// The migrated wage if it still needs the user's confirmation (outside
  /// 5–100 €/h and not confirmed yet), else `null`.
  Future<WagePlausibility?> pendingWageCheck() async {
    if (await _db.getMeta(kMetaWageConfirmed) != '0') return null;
    final rateId = int.tryParse(await _db.getMeta(kMetaRateId) ?? '');
    if (rateId == null) return null;
    final rate = await (_db.select(
      _db.wageRates,
    )..where((t) => t.id.equals(rateId))).getSingleOrNull();
    if (rate == null) return null;
    final check = checkWagePlausibility(rate.centsPerHour);
    if (check.isPlausible) {
      await confirmWage();
      return null;
    }
    return check;
  }

  /// Accepts the migrated wage as it is.
  Future<void> confirmWage() => _db.setMeta(kMetaWageConfirmed, '1');

  /// Corrects the migrated wage: updates the job's migrated rate and the
  /// snapshot and amount of every migrated shift (paid or not), then marks
  /// the wage as confirmed. Returns the number of updated shifts.
  ///
  /// Throws [ChronosErrorCode.invalidAmount] or
  /// [ChronosErrorCode.jobNotFound] (nothing was migrated).
  Future<int> correctWage(int centsPerHour) {
    if (centsPerHour < 0) {
      throw ChronosException(
        ChronosErrorCode.invalidAmount,
        detail: centsPerHour,
      );
    }
    return _db.transaction(() async {
      final jobId = int.tryParse(await _db.getMeta(kMetaJobId) ?? '');
      if (jobId == null) {
        throw const ChronosException(ChronosErrorCode.jobNotFound);
      }
      final rateId = int.tryParse(await _db.getMeta(kMetaRateId) ?? '');
      if (rateId != null) {
        await (_db.update(_db.wageRates)..where((t) => t.id.equals(rateId)))
            .write(WageRatesCompanion(centsPerHour: Value(centsPerHour)));
      }
      final rows =
          await (_db.select(_db.shifts)..where(
                (t) =>
                    t.jobId.equals(jobId) &
                    t.source.equalsValue(ShiftSource.legacy),
              ))
              .get();
      final nowMs = _clock.now().toUtc().millisecondsSinceEpoch;
      for (final row in rows) {
        final shift = row.toDomain();
        await (_db.update(
          _db.shifts,
        )..where((t) => t.id.equals(shift.id))).write(
          ShiftsCompanion(
            rateCentsPerHour: Value(centsPerHour),
            amountCents: Value(
              shift.isDone ? earningsCents(shift.workedMs, centsPerHour) : null,
            ),
            updatedAt: Value(nowMs),
          ),
        );
      }
      await confirmWage();
      return rows.length;
    });
  }
}
