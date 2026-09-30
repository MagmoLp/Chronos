/// Machine-readable reasons why a domain or data operation was refused.
///
/// The UI maps each code to a localized message; no text lives here.
enum ChronosErrorCode {
  /// A shift is already running; only one may run at a time.
  shiftAlreadyRunning,

  /// The operation needs a running shift, but none is running.
  noRunningShift,

  /// A start (or adjusted start) lies in the future.
  startInFuture,

  /// The job has no wage rate at all.
  noWageRate,

  /// The referenced job does not exist.
  jobNotFound,

  /// The referenced shift does not exist (or was purged).
  shiftNotFound,

  /// A running shift cannot be edited like a finished one.
  shiftIsRunning,

  /// Input failed validation; see [ChronosException.detail].
  invalidShift,

  /// The last active job cannot be archived.
  lastActiveJob,

  /// A payout was requested but there are no open shifts to include.
  nothingToPayOut,

  /// An amount (wage, tips, received) is negative or otherwise invalid.
  invalidAmount,

  /// A name is empty.
  emptyName,

  /// A backup file is not valid JSON or misses required data.
  backupInvalid,

  /// A backup was written by a newer app version (unknown format).
  backupNewerFormat,

  /// Another save of the same kind is still in progress.
  busy,
}

/// An expected, user-facing failure identified by [code].
final class ChronosException implements Exception {
  /// Creates an exception with [code] and optional machine-readable [detail].
  const ChronosException(this.code, {this.detail});

  /// What went wrong.
  final ChronosErrorCode code;

  /// Extra data for the UI (e.g. a validation result or offending value).
  final Object? detail;

  @override
  String toString() => detail == null
      ? 'ChronosException($code)'
      : 'ChronosException($code, $detail)';
}
