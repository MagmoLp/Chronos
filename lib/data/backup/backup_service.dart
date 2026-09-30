import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:drift/drift.dart';

import '../../core/local_date.dart';
import '../../core/money.dart';
import '../../core/time.dart';
import '../../domain/app_settings.dart';
import '../../domain/errors.dart';
import '../../domain/job.dart';
import '../../domain/payout.dart';
import '../../domain/review.dart';
import '../../domain/shift.dart';
import '../database.dart';
import '../legacy/legacy_models.dart';
import '../mappers.dart';
import 'backup_models.dart';

/// JSON backup: export, validation and restore (replace or merge by UUID).
///
/// Format (version [kBackupFormatVersion]):
/// `{formatVersion, schemaVersion, appVersion, exportedAt, settings, jobs,
/// wageRates, shifts, payouts}`. Instants are UTC epoch ms, dates
/// `yyyy-mm-dd`, money int cents. References between entities use UUIDs.
/// Soft-deleted shifts are not exported.
class BackupService {
  /// Creates the service on [db].
  BackupService(this._db, {Clock? clock}) : _clockOverride = clock;

  final AppDatabase _db;
  final Clock? _clockOverride;

  Clock get _clock => _clockOverride ?? clock;

  // ----------------------------------------------------------------- export

  /// Builds the backup map. With [includeExtras] the review list and failed
  /// v1 entries are included too (used for the automatic pre-wipe snapshot).
  Future<Map<String, Object?>> export({
    required String appVersion,
    AppSettings? settings,
    bool includeExtras = false,
  }) => _db.transaction(() async {
    final jobs =
        await (_db.select(_db.jobs)..orderBy([
              (t) => OrderingTerm.asc(t.sortOrder),
              (t) => OrderingTerm.asc(t.id),
            ]))
            .get();
    final rates =
        await (_db.select(_db.wageRates)..orderBy([
              (t) => OrderingTerm.asc(t.jobId),
              (t) => OrderingTerm.asc(t.validFrom),
            ]))
            .get();
    final payouts = await (_db.select(
      _db.payouts,
    )..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
    final shifts =
        await (_db.select(_db.shifts)
              ..where((t) => t.deletedAt.isNull())
              ..orderBy([
                (t) => OrderingTerm.asc(t.startUtc),
                (t) => OrderingTerm.asc(t.id),
              ]))
            .get();
    final jobUuid = {for (final j in jobs) j.id: j.uuid};
    final payoutUuid = {for (final p in payouts) p.id: p.uuid};
    final shiftUuid = {for (final s in shifts) s.id: s.uuid};

    final map = <String, Object?>{
      'formatVersion': kBackupFormatVersion,
      'schemaVersion': _db.schemaVersion,
      'appVersion': appVersion,
      'exportedAt': _clock.now().toUtc().toIso8601String(),
      'settings': settings == null ? null : settingsToJson(settings),
      'jobs': [
        for (final j in jobs)
          {
            'uuid': j.uuid,
            'name': j.name,
            'colorArgb': j.colorArgb,
            'rounding': j.rounding.name,
            'archived': j.archived,
            'sortOrder': j.sortOrder,
          },
      ],
      'wageRates': [
        for (final r in rates)
          {
            'jobUuid': jobUuid[r.jobId],
            'validFrom': LocalDate.fromKey(r.validFrom).toIso8601String(),
            'centsPerHour': r.centsPerHour,
          },
      ],
      'shifts': [
        for (final s in shifts)
          {
            'uuid': s.uuid,
            'jobUuid': jobUuid[s.jobId],
            'status': s.status.name,
            'startUtc': s.startUtc,
            'endUtc': s.endUtc,
            'rawStartUtc': s.rawStartUtc,
            'rawEndUtc': s.rawEndUtc,
            'startOffsetMin': s.startOffsetMin,
            'endOffsetMin': s.endOffsetMin,
            'rateCentsPerHour': s.rateCentsPerHour,
            'breakMs': s.breakMs,
            'pausedAtUtc': s.pausedAtUtc,
            'tipsCents': s.tipsCents,
            'note': s.note,
            'paidAtUtc': s.paidAtUtc,
            'payoutUuid': s.payoutId == null ? null : payoutUuid[s.payoutId],
            'amountCents': s.amountCents,
            'legacyId': s.legacyId,
            'source': s.source.name,
            'createdAt': s.createdAt,
            'updatedAt': s.updatedAt,
          },
      ],
      'payouts': [
        for (final p in payouts)
          {
            'uuid': p.uuid,
            'jobUuid': p.jobId == null ? null : jobUuid[p.jobId],
            'untilDate': LocalDate.fromKey(p.untilDate).toIso8601String(),
            'paidOn': LocalDate.fromKey(p.paidOn).toIso8601String(),
            'expectedCents': p.expectedCents,
            'receivedCents': p.receivedCents,
            'note': p.note,
            'createdAt': p.createdAt,
          },
      ],
    };
    if (includeExtras) {
      final review = await _db.select(_db.reviewItems).get();
      final failures = await _db.select(_db.legacyErrors).get();
      map['reviewItems'] = [
        for (final r in review)
          if (shiftUuid[r.shiftId] case final uuid?)
            {
              'shiftUuid': uuid,
              'reasons': decodeReviewReasons(
                r.reasons,
              ).map((e) => e.name).toList()..sort(),
              'relatedShiftUuids': [
                for (final id in r.toDomain().relatedShiftIds) ?shiftUuid[id],
              ],
            },
      ];
      map['legacyFailures'] = [
        for (final f in failures) LegacyFailure.fromRow(f).toJson(),
      ];
    }
    return map;
  });

  /// Pretty-printed JSON of a backup map.
  String encode(Map<String, Object?> backup) =>
      const JsonEncoder.withIndent('  ').convert(backup);

  // ------------------------------------------------------------------ parse

  /// Parses and validates a backup file's text.
  ///
  /// Throws [ChronosException] with [ChronosErrorCode.backupNewerFormat] for
  /// files from a newer app, or [ChronosErrorCode.backupInvalid] (detail: the
  /// offending JSON path) for anything malformed.
  BackupContents parse(String json) {
    final Object? decoded;
    try {
      decoded = jsonDecode(json);
    } on FormatException catch (e) {
      throw ChronosException(ChronosErrorCode.backupInvalid, detail: e.message);
    }
    return parseMap(decoded);
  }

  /// Validates an already decoded backup (see [parse]).
  BackupContents parseMap(Object? decoded) {
    if (decoded is! Map) {
      throw const ChronosException(
        ChronosErrorCode.backupInvalid,
        detail: r'$',
      );
    }
    final root = _Obj(decoded, r'$');
    final format = root.integer('formatVersion');
    if (format > kBackupFormatVersion) {
      throw ChronosException(
        ChronosErrorCode.backupNewerFormat,
        detail: format,
      );
    }
    if (format < 1) root.fail('formatVersion');

    final jobs = <Job>[];
    final jobUuids = <String>{};
    for (final o in root.list('jobs')) {
      final uuid = o.uuid('uuid');
      if (!jobUuids.add(uuid)) o.fail('uuid');
      jobs.add(
        Job(
          id: 0,
          uuid: uuid,
          name: o.string('name'),
          colorArgb: o.integer('colorArgb'),
          rounding: o.enumValue(RoundingRule.values, 'rounding'),
          archived: o.boolOr('archived', false),
          sortOrder: o.integerOr('sortOrder', jobs.length),
        ),
      );
    }

    String jobRef(_Obj o, String key) {
      final uuid = o.string(key);
      if (!jobUuids.contains(uuid)) o.fail(key);
      return uuid;
    }

    final rates = <BackupRate>[];
    for (final o in root.list('wageRates')) {
      rates.add((
        jobUuid: jobRef(o, 'jobUuid'),
        validFrom: o.date('validFrom'),
        centsPerHour: o.nonNegative('centsPerHour'),
      ));
    }

    final payouts = <BackupPayout>[];
    final payoutUuids = <String>{};
    for (final o in root.list('payouts')) {
      final uuid = o.uuid('uuid');
      if (!payoutUuids.add(uuid)) o.fail('uuid');
      final jobUuid = o.stringOrNull('jobUuid');
      if (jobUuid != null && !jobUuids.contains(jobUuid)) o.fail('jobUuid');
      payouts.add((
        payout: Payout(
          id: 0,
          uuid: uuid,
          untilDate: o.date('untilDate'),
          paidOn: o.date('paidOn'),
          expectedCents: o.nonNegative('expectedCents'),
          receivedCents: o.nonNegative('receivedCents'),
          note: o.stringOrNull('note'),
          createdAt: utcFromMs(o.integer('createdAt')),
        ),
        jobUuid: jobUuid,
      ));
    }

    final shifts = <BackupShift>[];
    final shiftUuids = <String>{};
    var running = 0;
    for (final o in root.list('shifts')) {
      final uuid = o.uuid('uuid');
      if (!shiftUuids.add(uuid)) o.fail('uuid');
      final status = o.enumValue(ShiftStatus.values, 'status');
      final start = o.integer('startUtc');
      final end = o.integerOrNull('endUtc');
      final breakMs = o.nonNegativeOr('breakMs', 0);
      final rate = o.nonNegative('rateCentsPerHour');
      if (status == ShiftStatus.done) {
        if (end == null || end < start) o.fail('endUtc');
      } else {
        if (++running > 1) o.fail('status');
      }
      final payoutUuid = o.stringOrNull('payoutUuid');
      if (payoutUuid != null && !payoutUuids.contains(payoutUuid)) {
        o.fail('payoutUuid');
      }
      final startUtc = utcFromMs(start);
      final endUtc = status == ShiftStatus.done ? utcFromMs(end!) : null;
      final workedMs = endUtc == null
          ? 0
          : endUtc.difference(startUtc).inMilliseconds - breakMs;
      final amount = o.integerOrNull('amountCents');
      if (amount != null && amount < 0) o.fail('amountCents');
      final createdAt = o.integerOr('createdAt', start);
      shifts.add((
        shift: Shift(
          id: 0,
          uuid: uuid,
          jobId: 0,
          status: status,
          startUtc: startUtc,
          endUtc: endUtc,
          rawStartUtc: utcFromMs(o.integerOr('rawStartUtc', start)),
          rawEndUtc: endUtc == null
              ? null
              : utcFromMs(o.integerOr('rawEndUtc', end!)),
          startOffsetMin: o.integerOr(
            'startOffsetMin',
            offsetMinutesAt(startUtc),
          ),
          endOffsetMin: endUtc == null
              ? null
              : o.integerOr('endOffsetMin', offsetMinutesAt(endUtc)),
          rateCentsPerHour: rate,
          breakMs: breakMs,
          pausedAtUtc: status == ShiftStatus.running
              ? utcFromMsOrNull(o.integerOrNull('pausedAtUtc'))
              : null,
          tipsCents: o.nonNegativeOr('tipsCents', 0),
          note: o.stringOrNull('note'),
          paidAtUtc: utcFromMsOrNull(o.integerOrNull('paidAtUtc')),
          amountCents: status == ShiftStatus.done
              ? amount ?? earningsCents(workedMs, rate)
              : null,
          legacyId: o.stringOrNull('legacyId'),
          source: o.enumValue(ShiftSource.values, 'source'),
          createdAt: utcFromMs(createdAt),
          updatedAt: utcFromMs(o.integerOr('updatedAt', createdAt)),
        ),
        jobUuid: jobRef(o, 'jobUuid'),
        payoutUuid: payoutUuid,
      ));
    }

    final settingsObj = root.objectOrNull('settings');
    final reviewItems = <BackupReviewItem>[
      for (final o in root.listOrEmpty('reviewItems'))
        (
          shiftUuid: o.string('shiftUuid'),
          reasons: {
            for (final name in o.stringList('reasons'))
              ?ReviewReason.values.asNameMap()[name],
          },
          relatedShiftUuids: o.stringList('relatedShiftUuids').toSet(),
        ),
    ];
    final failures = <LegacyFailure>[
      for (final o in root.listOrEmpty('legacyFailures'))
        LegacyFailure(
          origin: o.string('origin'),
          raw: o.string('raw'),
          code:
              LegacyErrorCode.values.asNameMap()[o.string('code')] ??
              LegacyErrorCode.insertFailed,
          message: o.stringOrNull('message'),
        ),
    ];

    final exportedAt = root.stringOrNull('exportedAt');
    return BackupContents(
      formatVersion: format,
      schemaVersion: root.integerOr('schemaVersion', 1),
      appVersion: root.stringOrNull('appVersion'),
      exportedAt: exportedAt == null
          ? null
          : DateTime.tryParse(exportedAt)?.toUtc(),
      settings: settingsObj == null ? null : settingsFromJson(settingsObj.map),
      jobs: List.unmodifiable(jobs),
      rates: List.unmodifiable(rates),
      shifts: List.unmodifiable(shifts),
      payouts: List.unmodifiable(payouts),
      reviewItems: List.unmodifiable(reviewItems),
      legacyFailures: List.unmodifiable(failures),
    );
  }

  // ----------------------------------------------------------------- import

  /// Restores [contents] in one transaction.
  ///
  /// [ImportMode.replace] deletes all data first (internal migration state
  /// is kept). [ImportMode.merge] keeps existing data and adds jobs, rates,
  /// payouts and shifts whose UUIDs are unknown; a running shift is skipped
  /// if one is already running. Settings are returned, not applied.
  Future<ImportResult> import(BackupContents contents, ImportMode mode) =>
      _db.transaction(() async {
        if (mode == ImportMode.replace) {
          await _db.delete(_db.reviewItems).go();
          await _db.delete(_db.legacyErrors).go();
          await _db.delete(_db.shifts).go();
          await _db.delete(_db.payouts).go();
          await _db.delete(_db.wageRates).go();
          await _db.delete(_db.jobs).go();
        }
        final nowMs = _clock.now().toUtc().millisecondsSinceEpoch;

        final jobIds = {
          for (final j in await _db.select(_db.jobs).get()) j.uuid: j.id,
        };
        var jobsAdded = 0;
        for (final job in contents.jobs) {
          if (jobIds.containsKey(job.uuid)) continue;
          jobIds[job.uuid] = await _db
              .into(_db.jobs)
              .insert(
                JobsCompanion.insert(
                  uuid: job.uuid,
                  name: job.name,
                  colorArgb: job.colorArgb,
                  rounding: job.rounding,
                  archived: Value(job.archived),
                  sortOrder: Value(job.sortOrder),
                  createdAt: nowMs,
                  updatedAt: nowMs,
                ),
              );
          jobsAdded++;
        }

        final existingRates = {
          for (final r in await _db.select(_db.wageRates).get())
            (r.jobId, r.validFrom),
        };
        var ratesAdded = 0;
        for (final rate in contents.rates) {
          final key = (jobIds[rate.jobUuid]!, rate.validFrom.key);
          if (!existingRates.add(key)) continue;
          await _db
              .into(_db.wageRates)
              .insert(
                WageRatesCompanion.insert(
                  jobId: key.$1,
                  validFrom: key.$2,
                  centsPerHour: rate.centsPerHour,
                ),
              );
          ratesAdded++;
        }

        final payoutIds = {
          for (final p in await _db.select(_db.payouts).get()) p.uuid: p.id,
        };
        var payoutsAdded = 0;
        for (final entry in contents.payouts) {
          final p = entry.payout;
          if (payoutIds.containsKey(p.uuid)) continue;
          payoutIds[p.uuid] = await _db
              .into(_db.payouts)
              .insert(
                PayoutsCompanion.insert(
                  uuid: p.uuid,
                  jobId: Value(
                    entry.jobUuid == null ? null : jobIds[entry.jobUuid],
                  ),
                  untilDate: p.untilDate.key,
                  paidOn: p.paidOn.key,
                  expectedCents: p.expectedCents,
                  receivedCents: p.receivedCents,
                  note: Value(p.note),
                  createdAt: p.createdAt.millisecondsSinceEpoch,
                ),
              );
          payoutsAdded++;
        }

        final existingShifts = {
          for (final s in await _db.select(_db.shifts).get()) s.uuid: s.id,
        };
        var hasRunning =
            (await (_db.select(_db.shifts)..where(
                      (t) =>
                          t.status.equalsValue(ShiftStatus.running) &
                          t.deletedAt.isNull(),
                    ))
                    .get())
                .isNotEmpty;
        var shiftsAdded = 0;
        var shiftsSkipped = 0;
        var runningSkipped = false;
        for (final entry in contents.shifts) {
          final s = entry.shift;
          if (existingShifts.containsKey(s.uuid)) {
            shiftsSkipped++;
            continue;
          }
          if (s.isRunning) {
            if (hasRunning) {
              runningSkipped = true;
              shiftsSkipped++;
              continue;
            }
            hasRunning = true;
          }
          final row = s.copyWith(
            jobId: jobIds[entry.jobUuid],
            payoutId: entry.payoutUuid == null
                ? null
                : payoutIds[entry.payoutUuid],
            deletedAt: null,
          );
          existingShifts[s.uuid] = await _db
              .into(_db.shifts)
              .insert(row.toCompanion(withId: false));
          shiftsAdded++;
        }

        if (mode == ImportMode.replace) {
          await _db.batch((batch) {
            batch.insertAll(_db.reviewItems, [
              for (final r in contents.reviewItems)
                if (existingShifts[r.shiftUuid] case final id?)
                  reviewItemCompanion(
                    ReviewItem(
                      shiftId: id,
                      reasons: r.reasons,
                      relatedShiftIds: {
                        for (final u in r.relatedShiftUuids) ?existingShifts[u],
                      },
                    ),
                  ),
            ], mode: InsertMode.insertOrIgnore);
            batch.insertAll(_db.legacyErrors, [
              for (final f in contents.legacyFailures)
                LegacyErrorsCompanion.insert(
                  origin: f.origin,
                  raw: f.raw,
                  code: f.code.name,
                  message: Value(f.message),
                  createdAt: nowMs,
                ),
            ]);
          });
        }

        return ImportResult(
          mode: mode,
          jobsAdded: jobsAdded,
          ratesAdded: ratesAdded,
          shiftsAdded: shiftsAdded,
          shiftsSkipped: shiftsSkipped,
          payoutsAdded: payoutsAdded,
          runningSkipped: runningSkipped,
          settings: contents.settings,
        );
      });
}

/// Settings as stored in backups (device-specific flags are left out).
Map<String, Object?> settingsToJson(AppSettings s) => {
  'language': s.language.name,
  'themeMode': s.themeMode.name,
  'monthlyGoalCents': s.monthlyGoalCents,
  'monthlyGoalType': s.monthlyGoalType.name,
  'reminderHours': s.reminderHours,
};

/// Reads backup settings leniently (unknown values → defaults).
AppSettings settingsFromJson(Map<Object?, Object?> json) {
  const d = AppSettings.defaults;
  final goal = json['monthlyGoalCents'];
  final reminder = json['reminderHours'];
  return AppSettings(
    language: AppLanguage.values.asNameMap()[json['language']] ?? d.language,
    themeMode:
        AppThemeMode.values.asNameMap()[json['themeMode']] ?? d.themeMode,
    monthlyGoalCents: goal is int && goal > 0 ? goal : null,
    monthlyGoalType:
        MonthlyGoalType.values.asNameMap()[json['monthlyGoalType']] ??
        d.monthlyGoalType,
    reminderHours:
        reminder is int && AppSettings.reminderHourOptions.contains(reminder)
        ? reminder
        : d.reminderHours,
  );
}

/// Typed, path-aware access to a JSON object for validation.
class _Obj {
  _Obj(this.map, this.path);

  final Map<Object?, Object?> map;
  final String path;

  Never fail(String key) => throw ChronosException(
    ChronosErrorCode.backupInvalid,
    detail: '$path.$key',
  );

  int integer(String key) {
    final v = map[key];
    if (v is int) return v;
    fail(key);
  }

  int? integerOrNull(String key) {
    final v = map[key];
    if (v == null) return null;
    if (v is int) return v;
    fail(key);
  }

  int integerOr(String key, int fallback) => integerOrNull(key) ?? fallback;

  int nonNegative(String key) {
    final v = integer(key);
    if (v < 0) fail(key);
    return v;
  }

  int nonNegativeOr(String key, int fallback) {
    final v = integerOr(key, fallback);
    if (v < 0) fail(key);
    return v;
  }

  String string(String key) {
    final v = map[key];
    if (v is String) return v;
    fail(key);
  }

  String? stringOrNull(String key) {
    final v = map[key];
    if (v == null) return null;
    if (v is String) return v;
    fail(key);
  }

  String uuid(String key) {
    final v = string(key).trim();
    if (v.isEmpty) fail(key);
    return v;
  }

  bool boolOr(String key, bool fallback) {
    final v = map[key];
    if (v == null) return fallback;
    if (v is bool) return v;
    fail(key);
  }

  T enumValue<T extends Enum>(List<T> values, String key) {
    final v = values.asNameMap()[map[key]];
    if (v == null) fail(key);
    return v;
  }

  LocalDate date(String key) {
    final v = map[key];
    final parsed = v is String ? LocalDate.tryParse(v) : null;
    if (parsed == null) fail(key);
    return parsed;
  }

  List<String> stringList(String key) {
    final v = map[key];
    if (v == null) return const [];
    if (v is! List) fail(key);
    return [
      for (final e in v)
        if (e is String) e else fail(key),
    ];
  }

  _Obj? objectOrNull(String key) {
    final v = map[key];
    if (v == null) return null;
    if (v is Map) return _Obj(v, '$path.$key');
    fail(key);
  }

  List<_Obj> list(String key) {
    final v = map[key];
    if (v is! List) fail(key);
    return [
      for (var i = 0; i < v.length; i++)
        if (v[i] case final Map<Object?, Object?> m)
          _Obj(m, '$path.$key[$i]')
        else
          fail('$key[$i]'),
    ];
  }

  List<_Obj> listOrEmpty(String key) => map[key] == null ? const [] : list(key);
}
