import '../../core/time.dart';
import '../../domain/app_settings.dart';
import '../../domain/review.dart';
import '../database.dart';

/// Why a v1 value could not be imported.
enum LegacyErrorCode {
  /// The stored string is not valid JSON.
  invalidJson,

  /// `work_entries` is not a JSON list.
  notAList,

  /// A list element is not a JSON object.
  notAnObject,

  /// `startTime` is missing.
  missingStartTime,

  /// `startTime` is not a valid date/time.
  invalidStartTime,

  /// `endTime` is missing.
  missingEndTime,

  /// `endTime` is not a valid date/time.
  invalidEndTime,

  /// End is not after start.
  endNotAfterStart,

  /// `active_session` is not a valid date/time.
  invalidActiveSession,

  /// A v1 session was running but v2 already has a running shift.
  runningShiftExists,

  /// `app_settings` could not be read (defaults were used).
  invalidSettings,

  /// The database refused the row.
  insertFailed,
}

/// A v1 value that could not be imported. Kept in the database (never
/// dropped silently) so the UI can list and export it.
final class LegacyFailure {
  /// Creates a failure.
  const LegacyFailure({
    required this.origin,
    required this.raw,
    required this.code,
    this.message,
    this.id,
  });

  /// Reads a stored failure.
  factory LegacyFailure.fromRow(LegacyErrorRow row) => LegacyFailure(
    id: row.id,
    origin: row.origin,
    raw: row.raw,
    code: LegacyErrorCode.values.firstWhere(
      (c) => c.name == row.code,
      orElse: () => LegacyErrorCode.insertFailed,
    ),
    message: row.message,
  );

  /// Database id (`null` before it is stored).
  final int? id;

  /// Where the value came from, e.g. `work_entries[3]`.
  final String origin;

  /// The raw value.
  final String raw;

  /// Machine-readable reason.
  final LegacyErrorCode code;

  /// Diagnostic detail.
  final String? message;

  /// JSON for exports.
  Map<String, Object?> toJson() => {
    'origin': origin,
    'raw': raw,
    'code': code.name,
    'message': message,
  };

  @override
  bool operator ==(Object other) =>
      other is LegacyFailure &&
      other.origin == origin &&
      other.raw == raw &&
      other.code == code &&
      other.message == message;

  @override
  int get hashCode => Object.hash(origin, raw, code, message);

  @override
  String toString() => 'LegacyFailure($origin, ${code.name})';
}

/// The three raw v1 preference values, exactly as stored.
final class LegacyRawData {
  /// Creates the raw data.
  const LegacyRawData({this.workEntries, this.appSettings, this.activeSession});

  /// Value of `work_entries` (a JSON string in v1).
  final Object? workEntries;

  /// Value of `app_settings` (a JSON string in v1).
  final Object? appSettings;

  /// Value of `active_session` (an ISO string in v1).
  final Object? activeSession;

  /// Whether none of the keys exist.
  bool get isEmpty =>
      workEntries == null && appSettings == null && activeSession == null;

  /// The raw values keyed by their v1 preference names.
  Map<String, Object?> toJson() => {
    'work_entries': workEntries,
    'app_settings': appSettings,
    'active_session': activeSession,
  };
}

/// Outcome of the v1 migration.
enum LegacyMigrationStatus {
  /// No v1 data found; nothing to do.
  noLegacyData,

  /// Migrated on an earlier start.
  alreadyMigrated,

  /// Migrated now.
  migrated,
}

/// What the v1 migration did (shown once to the user).
final class LegacyMigrationReport {
  /// Creates a report.
  const LegacyMigrationReport({
    required this.status,
    this.importedCount = 0,
    this.failures = const [],
    this.activeSessionImported = false,
    this.jobId,
    this.wageCentsPerHour,
    this.wagePlausibility,
    this.reviewCount = 0,
    this.backupPath,
    this.backupError,
    this.language,
  });

  /// Nothing to migrate.
  static const LegacyMigrationReport noLegacyData = LegacyMigrationReport(
    status: LegacyMigrationStatus.noLegacyData,
  );

  /// Migrated before.
  static const LegacyMigrationReport alreadyMigrated = LegacyMigrationReport(
    status: LegacyMigrationStatus.alreadyMigrated,
  );

  /// What happened.
  final LegacyMigrationStatus status;

  /// Imported finished shifts.
  final int importedCount;

  /// Values that could not be imported.
  final List<LegacyFailure> failures;

  /// Whether a running v1 session became a running shift.
  final bool activeSessionImported;

  /// The created job.
  final int? jobId;

  /// The wage taken over from v1.
  final int? wageCentsPerHour;

  /// Plausibility of that wage (ask the user if implausible).
  final WagePlausibility? wagePlausibility;

  /// Shifts put on the review list.
  final int reviewCount;

  /// Path of `legacy_backup_v1.json`.
  final String? backupPath;

  /// Why the raw backup could not be written (migration continued; the v1
  /// keys are kept, so nothing is lost).
  final String? backupError;

  /// Language taken over from v1 (`null` = keep following the system).
  final AppLanguage? language;

  /// Whether data was migrated in this run.
  bool get migrated => status == LegacyMigrationStatus.migrated;

  @override
  String toString() =>
      'LegacyMigrationReport(${status.name}, imported $importedCount, '
      'failed ${failures.length}, review $reviewCount, '
      'wage $wageCentsPerHour)';
}

/// A parsed v1 work entry.
final class ParsedLegacyEntry {
  /// Creates an entry.
  const ParsedLegacyEntry({
    required this.origin,
    required this.raw,
    required this.startUtc,
    required this.endUtc,
    required this.isPaid,
    this.legacyId,
  });

  /// Where it came from (`work_entries[i]`).
  final String origin;

  /// Raw JSON of the element.
  final String raw;

  /// v1 id (millisecond timestamp string or UUID).
  final String? legacyId;

  /// Start instant.
  final DateTime startUtc;

  /// End instant.
  final DateTime endUtc;

  /// v1 paid flag.
  final bool isPaid;

  /// UTC offset at the start (device zone).
  int get startOffsetMin => offsetMinutesAt(startUtc);

  /// UTC offset at the end (device zone).
  int get endOffsetMin => offsetMinutesAt(endUtc);
}
