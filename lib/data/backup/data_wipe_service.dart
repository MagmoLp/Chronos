import 'dart:io';

import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

import '../../domain/app_settings.dart';
import '../../domain/errors.dart';
import '../database.dart';
import 'backup_models.dart';
import 'backup_service.dart';

/// How much data exists (for "214 Schichten und 2 Jobs löschen?").
final class DataCounts {
  /// Creates counts.
  const DataCounts({
    required this.shifts,
    required this.jobs,
    required this.payouts,
  });

  /// Non-deleted shifts (finished and running).
  final int shifts;

  /// Jobs (including archived).
  final int jobs;

  /// Payouts.
  final int payouts;

  /// Whether there is nothing to delete.
  bool get isEmpty => shifts == 0 && jobs == 0 && payouts == 0;

  @override
  bool operator ==(Object other) =>
      other is DataCounts &&
      other.shifts == shifts &&
      other.jobs == jobs &&
      other.payouts == payouts;

  @override
  int get hashCode => Object.hash(shifts, jobs, payouts);

  @override
  String toString() =>
      'DataCounts($shifts shifts, $jobs jobs, $payouts payouts)';
}

/// Result of [DataWipeService.wipeAll]: what was deleted and where the
/// automatic snapshot lies (needed for undo).
final class WipeResult {
  /// Creates a result.
  const WipeResult({required this.snapshot, required this.deleted});

  /// The JSON snapshot written before deleting.
  final File snapshot;

  /// What was deleted.
  final DataCounts deleted;

  @override
  String toString() => 'WipeResult(${snapshot.path}, $deleted)';
}

/// "Alle Daten löschen" with an automatic snapshot and undo.
class DataWipeService {
  /// Creates the service. [snapshotDirectory] returns the folder for the
  /// pre-delete snapshots (app documents folder in production).
  DataWipeService(
    this._db,
    this._backup, {
    required this._snapshotDirectory,
    Clock? clock,
  }) : _clockOverride = clock;

  final AppDatabase _db;
  final BackupService _backup;
  final Future<Directory> Function() _snapshotDirectory;
  final Clock? _clockOverride;

  Clock get _clock => _clockOverride ?? clock;

  /// File name prefix of snapshots.
  static const String snapshotPrefix = 'chronos_before_delete_';

  /// Current amount of data.
  Future<DataCounts> counts() async {
    final shifts = _db.shifts.id.count();
    final jobs = _db.jobs.id.count();
    final payouts = _db.payouts.id.count();
    return DataCounts(
      shifts:
          await (_db.selectOnly(_db.shifts)
                ..addColumns([shifts])
                ..where(_db.shifts.deletedAt.isNull()))
              .map((r) => r.read(shifts)!)
              .getSingle(),
      jobs: await (_db.selectOnly(
        _db.jobs,
      )..addColumns([jobs])).map((r) => r.read(jobs)!).getSingle(),
      payouts: await (_db.selectOnly(
        _db.payouts,
      )..addColumns([payouts])).map((r) => r.read(payouts)!).getSingle(),
    );
  }

  /// Writes a full snapshot (including review list and failed v1 entries)
  /// to a file, then deletes all data in one transaction. Internal state
  /// (e.g. "v1 already migrated") is kept, so old v1 data is not imported
  /// again. Settings are not touched.
  Future<WipeResult> wipeAll({
    required String appVersion,
    AppSettings? settings,
  }) async {
    final before = await counts();
    final map = await _backup.export(
      appVersion: appVersion,
      settings: settings,
      includeExtras: true,
    );
    final dir = await _snapshotDirectory();
    await dir.create(recursive: true);
    final stamp = _clock.now().toUtc().toIso8601String().replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );
    final file = File(p.join(dir.path, '$snapshotPrefix$stamp.json'));
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(_backup.encode(map), flush: true);
    await tmp.rename(file.path);
    await _db.deleteAllData();
    return WipeResult(snapshot: file, deleted: before);
  }

  /// Restores the data deleted by [result] (replace mode). Throws
  /// [ChronosErrorCode.backupInvalid] if the snapshot is gone.
  Future<ImportResult> undo(WipeResult result) async {
    if (!result.snapshot.existsSync()) {
      throw ChronosException(
        ChronosErrorCode.backupInvalid,
        detail: result.snapshot.path,
      );
    }
    final contents = _backup.parse(await result.snapshot.readAsString());
    return _backup.import(contents, ImportMode.replace);
  }
}
