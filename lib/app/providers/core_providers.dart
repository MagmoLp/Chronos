import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/clock.dart';
import '../../data/backup/backup_service.dart';
import '../../data/backup/data_wipe_service.dart';
import '../../data/database.dart';
import '../../data/job_repository.dart';
import '../../data/legacy/legacy_migration.dart';
import '../../data/payout_repository.dart';
import '../../data/review_repository.dart';
import '../../data/shift_repository.dart';

/// Folder for files the user may need later (raw v1 backup, pre-delete
/// snapshots). Tests override it with a temporary folder.
final documentsDirectoryProvider = Provider<Future<Directory> Function()>(
  (ref) => getApplicationDocumentsDirectory,
  name: 'documentsDirectoryProvider',
);

/// The app database (opened lazily, closed with the container). Tests
/// override it with `AppDatabase(NativeDatabase.memory())`.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.open();
  ref.onDispose(() => unawaited(db.close()));
  return db;
}, name: 'databaseProvider');

/// Jobs and wage history.
final jobRepositoryProvider = Provider<JobRepository>(
  (ref) => JobRepository(
    ref.watch(databaseProvider),
    clock: ref.watch(clockProvider),
  ),
  name: 'jobRepositoryProvider',
);

/// Shifts.
final shiftRepositoryProvider = Provider<ShiftRepository>(
  (ref) => ShiftRepository(
    ref.watch(databaseProvider),
    clock: ref.watch(clockProvider),
    jobs: ref.watch(jobRepositoryProvider),
  ),
  name: 'shiftRepositoryProvider',
);

/// Payouts.
final payoutRepositoryProvider = Provider<PayoutRepository>(
  (ref) => PayoutRepository(
    ref.watch(databaseProvider),
    clock: ref.watch(clockProvider),
  ),
  name: 'payoutRepositoryProvider',
);

/// Review list and failed v1 entries.
final reviewRepositoryProvider = Provider<ReviewRepository>(
  (ref) => ReviewRepository(ref.watch(databaseProvider)),
  name: 'reviewRepositoryProvider',
);

/// JSON backup export/import.
final backupServiceProvider = Provider<BackupService>(
  (ref) => BackupService(
    ref.watch(databaseProvider),
    clock: ref.watch(clockProvider),
  ),
  name: 'backupServiceProvider',
);

/// "Delete all data" with snapshot and undo.
final dataWipeServiceProvider = Provider<DataWipeService>(
  (ref) => DataWipeService(
    ref.watch(databaseProvider),
    ref.watch(backupServiceProvider),
    snapshotDirectory: ref.watch(documentsDirectoryProvider),
    clock: ref.watch(clockProvider),
  ),
  name: 'dataWipeServiceProvider',
);

/// Where v1 data is read from (legacy SharedPreferences API).
final legacySourceProvider = Provider<LegacySource>(
  (ref) => const SharedPreferencesLegacySource(),
  name: 'legacySourceProvider',
);

/// The v1 → v2 migration.
final legacyMigratorProvider = Provider<LegacyMigrator>(
  (ref) => LegacyMigrator(
    db: ref.watch(databaseProvider),
    source: ref.watch(legacySourceProvider),
    backupDirectory: ref.watch(documentsDirectoryProvider),
    clock: ref.watch(clockProvider),
  ),
  name: 'legacyMigratorProvider',
);

/// App version "2.0.0+2" (for backups and the about page).
final appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return info.buildNumber.isEmpty
      ? info.version
      : '${info.version}+${info.buildNumber}';
}, name: 'appVersionProvider');
