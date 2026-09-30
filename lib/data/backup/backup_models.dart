import '../../core/local_date.dart';
import '../../domain/app_settings.dart';
import '../../domain/job.dart';
import '../../domain/payout.dart';
import '../../domain/review.dart';
import '../../domain/shift.dart';
import '../legacy/legacy_models.dart';

/// Newest backup format this app can read and the one it writes.
const int kBackupFormatVersion = 1;

/// How a backup is restored.
enum ImportMode {
  /// Delete all data, then insert the backup.
  replace,

  /// Keep existing data; add what is missing (matched by UUID).
  merge,
}

/// A wage rate in a backup (job referenced by UUID).
typedef BackupRate = ({String jobUuid, LocalDate validFrom, int centsPerHour});

/// A shift in a backup: ids inside [shift] are placeholders; job and payout
/// are referenced by UUID.
typedef BackupShift = ({Shift shift, String jobUuid, String? payoutUuid});

/// A payout in a backup: ids are placeholders; the job is referenced by UUID
/// (`null` = all jobs).
typedef BackupPayout = ({Payout payout, String? jobUuid});

/// A review item in a backup (shifts referenced by UUID).
typedef BackupReviewItem = ({
  String shiftUuid,
  Set<ReviewReason> reasons,
  Set<String> relatedShiftUuids,
});

/// A parsed and validated backup file.
final class BackupContents {
  /// Creates contents.
  const BackupContents({
    required this.formatVersion,
    required this.schemaVersion,
    required this.jobs,
    required this.rates,
    required this.shifts,
    required this.payouts,
    this.appVersion,
    this.exportedAt,
    this.settings,
    this.reviewItems = const [],
    this.legacyFailures = const [],
  });

  /// Backup format version.
  final int formatVersion;

  /// Database schema version of the exporting app.
  final int schemaVersion;

  /// App version that wrote the file.
  final String? appVersion;

  /// When the file was written.
  final DateTime? exportedAt;

  /// Settings contained in the file.
  final AppSettings? settings;

  /// Jobs (ids are placeholders).
  final List<Job> jobs;

  /// Wage rates.
  final List<BackupRate> rates;

  /// Shifts.
  final List<BackupShift> shifts;

  /// Payouts.
  final List<BackupPayout> payouts;

  /// Review items (only in automatic pre-wipe snapshots).
  final List<BackupReviewItem> reviewItems;

  /// Failed v1 entries (only in automatic pre-wipe snapshots).
  final List<LegacyFailure> legacyFailures;

  /// Overview for the restore dialog.
  BackupSummary get summary {
    DateTime? first;
    DateTime? last;
    for (final s in shifts) {
      final start = s.shift.startUtc;
      if (first == null || start.isBefore(first)) first = start;
      if (last == null || start.isAfter(last)) last = start;
    }
    return BackupSummary(
      formatVersion: formatVersion,
      appVersion: appVersion,
      exportedAt: exportedAt,
      jobCount: jobs.length,
      shiftCount: shifts.length,
      payoutCount: payouts.length,
      hasRunningShift: shifts.any((s) => s.shift.isRunning),
      firstShiftUtc: first,
      lastShiftUtc: last,
    );
  }
}

/// What a backup contains (shown before restoring).
final class BackupSummary {
  /// Creates a summary.
  const BackupSummary({
    required this.formatVersion,
    required this.jobCount,
    required this.shiftCount,
    required this.payoutCount,
    required this.hasRunningShift,
    this.appVersion,
    this.exportedAt,
    this.firstShiftUtc,
    this.lastShiftUtc,
  });

  /// Backup format version.
  final int formatVersion;

  /// App version that wrote the file.
  final String? appVersion;

  /// When the file was written.
  final DateTime? exportedAt;

  /// Number of jobs.
  final int jobCount;

  /// Number of shifts.
  final int shiftCount;

  /// Number of payouts.
  final int payoutCount;

  /// Whether a running shift is included.
  final bool hasRunningShift;

  /// Start of the oldest shift.
  final DateTime? firstShiftUtc;

  /// Start of the newest shift.
  final DateTime? lastShiftUtc;

  @override
  String toString() =>
      'BackupSummary(v$formatVersion, $jobCount jobs, $shiftCount shifts, '
      '$payoutCount payouts)';
}

/// What a restore did.
final class ImportResult {
  /// Creates a result.
  const ImportResult({
    required this.mode,
    this.jobsAdded = 0,
    this.ratesAdded = 0,
    this.shiftsAdded = 0,
    this.shiftsSkipped = 0,
    this.payoutsAdded = 0,
    this.runningSkipped = false,
    this.settings,
  });

  /// Replace or merge.
  final ImportMode mode;

  /// New jobs.
  final int jobsAdded;

  /// New wage rates.
  final int ratesAdded;

  /// New shifts.
  final int shiftsAdded;

  /// Shifts that already existed (merge).
  final int shiftsSkipped;

  /// New payouts.
  final int payoutsAdded;

  /// A running shift in the backup was skipped because one is running.
  final bool runningSkipped;

  /// Settings from the backup (the caller decides whether to apply them).
  final AppSettings? settings;

  @override
  String toString() =>
      'ImportResult(${mode.name}, jobs +$jobsAdded, shifts +$shiftsAdded '
      '(skipped $shiftsSkipped), payouts +$payoutsAdded)';
}
