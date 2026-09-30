import '../core/local_date.dart';
import '../core/money.dart';

/// Lifecycle state of a shift.
enum ShiftStatus {
  /// Timer is running (or paused). At most one such shift exists.
  running,

  /// Finished; has an end time and a cached amount.
  done,
}

/// How a shift was created.
enum ShiftSource {
  /// Start/finish with the timer.
  timer,

  /// Entered or duplicated in the editor.
  manual,

  /// Imported from v1 (shared_preferences) data.
  legacy,

  /// Restored from a backup file.
  import,
}

/// Filter of the shift list ("Alle / Offen / Bezahlt").
enum ShiftFilter {
  /// Every finished shift.
  all,

  /// Finished and not paid.
  open,

  /// Paid.
  paid;

  /// Whether a finished, non-deleted [shift] passes this filter.
  bool matches(Shift shift) => switch (this) {
    ShiftFilter.all => true,
    ShiftFilter.open => !shift.isPaid,
    ShiftFilter.paid => shift.isPaid,
  };
}

class _Unset {
  const _Unset();
}

const Object _unset = _Unset();

/// A work shift.
///
/// Times are UTC instants; the UTC offsets at start and end are kept so the
/// original wall-clock times can always be reconstructed. [startUtc]/[endUtc]
/// are the billed times (after the job's rounding); [rawStartUtc]/[rawEndUtc]
/// keep what was actually recorded.
final class Shift {
  /// Creates a shift.
  const Shift({
    required this.id,
    required this.uuid,
    required this.jobId,
    required this.status,
    required this.startUtc,
    required this.rawStartUtc,
    required this.startOffsetMin,
    required this.rateCentsPerHour,
    required this.source,
    required this.createdAt,
    required this.updatedAt,
    this.endUtc,
    this.rawEndUtc,
    this.endOffsetMin,
    this.breakMs = 0,
    this.pausedAtUtc,
    this.tipsCents = 0,
    this.note,
    this.paidAtUtc,
    this.payoutId,
    this.amountCents,
    this.legacyId,
    this.deletedAt,
  });

  /// Database id.
  final int id;

  /// Stable id used to merge backups.
  final String uuid;

  /// Job the shift belongs to.
  final int jobId;

  /// Running or done.
  final ShiftStatus status;

  /// Billed start (after rounding).
  final DateTime startUtc;

  /// Billed end (after rounding); `null` while running.
  final DateTime? endUtc;

  /// Recorded start before rounding.
  final DateTime rawStartUtc;

  /// Recorded end before rounding; `null` while running.
  final DateTime? rawEndUtc;

  /// UTC offset (minutes) of the device zone at the start.
  final int startOffsetMin;

  /// UTC offset (minutes) of the device zone at the end.
  final int? endOffsetMin;

  /// Wage snapshot in cents per hour.
  final int rateCentsPerHour;

  /// Total break time in ms (manual break plus completed pauses).
  final int breakMs;

  /// Start of the current pause while a running shift is paused.
  final DateTime? pausedAtUtc;

  /// Tips in cents (kept separate from the wage).
  final int tipsCents;

  /// Free-text note.
  final String? note;

  /// When the shift was marked paid; `null` = open.
  final DateTime? paidAtUtc;

  /// Payout that settled this shift, if any.
  final int? payoutId;

  /// Cached wage earnings (without tips), computed when finished.
  final int? amountCents;

  /// Original v1 id for migrated shifts.
  final String? legacyId;

  /// How the shift was created.
  final ShiftSource source;

  /// Creation time.
  final DateTime createdAt;

  /// Last modification time.
  final DateTime updatedAt;

  /// Soft-delete time; `null` = not deleted.
  final DateTime? deletedAt;

  /// Whether the timer is running (possibly paused).
  bool get isRunning => status == ShiftStatus.running;

  /// Whether the shift is finished.
  bool get isDone => status == ShiftStatus.done;

  /// Whether a running shift is currently paused.
  bool get isPaused => isRunning && pausedAtUtc != null;

  /// Whether the shift was paid.
  bool get isPaid => paidAtUtc != null;

  /// Whether the shift is soft-deleted.
  bool get isDeleted => deletedAt != null;

  /// Finished, not paid and not deleted: counts towards "open".
  bool get isOpen => isDone && !isPaid && !isDeleted;

  /// Local calendar date the shift belongs to (its local start date).
  LocalDate get localStartDate => LocalDate.ofInstant(startUtc);

  /// Local calendar date of the end; `null` while running.
  LocalDate? get localEndDate =>
      endUtc == null ? null : LocalDate.ofInstant(endUtc!);

  /// Whether the (billed) end falls on a later local day than the start.
  bool get endsOnLaterDay =>
      localEndDate != null && localEndDate!.isAfter(localStartDate);

  /// Gross billed duration (end − start) in ms; `null` while running.
  int? get durationMs => endUtc?.difference(startUtc).inMilliseconds;

  /// Worked time of a finished shift: duration − break, never negative.
  /// 0 while running (use `liveValues` from `pay.dart` instead).
  int get workedMs {
    final duration = durationMs;
    if (duration == null) return 0;
    final worked = duration - breakMs;
    return worked < 0 ? 0 : worked;
  }

  /// Wage earnings of a finished shift (cached [amountCents] or computed).
  /// 0 while running (use `liveValues` from `pay.dart` instead).
  int get earnedCents {
    if (!isDone) return 0;
    return amountCents ?? earningsCents(workedMs, rateCentsPerHour);
  }

  /// Copy with the given fields replaced. Nullable fields can be cleared by
  /// passing `null` explicitly.
  Shift copyWith({
    int? id,
    String? uuid,
    int? jobId,
    ShiftStatus? status,
    DateTime? startUtc,
    Object? endUtc = _unset,
    DateTime? rawStartUtc,
    Object? rawEndUtc = _unset,
    int? startOffsetMin,
    Object? endOffsetMin = _unset,
    int? rateCentsPerHour,
    int? breakMs,
    Object? pausedAtUtc = _unset,
    int? tipsCents,
    Object? note = _unset,
    Object? paidAtUtc = _unset,
    Object? payoutId = _unset,
    Object? amountCents = _unset,
    Object? legacyId = _unset,
    ShiftSource? source,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? deletedAt = _unset,
  }) => Shift(
    id: id ?? this.id,
    uuid: uuid ?? this.uuid,
    jobId: jobId ?? this.jobId,
    status: status ?? this.status,
    startUtc: startUtc ?? this.startUtc,
    endUtc: identical(endUtc, _unset) ? this.endUtc : endUtc as DateTime?,
    rawStartUtc: rawStartUtc ?? this.rawStartUtc,
    rawEndUtc: identical(rawEndUtc, _unset)
        ? this.rawEndUtc
        : rawEndUtc as DateTime?,
    startOffsetMin: startOffsetMin ?? this.startOffsetMin,
    endOffsetMin: identical(endOffsetMin, _unset)
        ? this.endOffsetMin
        : endOffsetMin as int?,
    rateCentsPerHour: rateCentsPerHour ?? this.rateCentsPerHour,
    breakMs: breakMs ?? this.breakMs,
    pausedAtUtc: identical(pausedAtUtc, _unset)
        ? this.pausedAtUtc
        : pausedAtUtc as DateTime?,
    tipsCents: tipsCents ?? this.tipsCents,
    note: identical(note, _unset) ? this.note : note as String?,
    paidAtUtc: identical(paidAtUtc, _unset)
        ? this.paidAtUtc
        : paidAtUtc as DateTime?,
    payoutId: identical(payoutId, _unset) ? this.payoutId : payoutId as int?,
    amountCents: identical(amountCents, _unset)
        ? this.amountCents
        : amountCents as int?,
    legacyId: identical(legacyId, _unset) ? this.legacyId : legacyId as String?,
    source: source ?? this.source,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: identical(deletedAt, _unset)
        ? this.deletedAt
        : deletedAt as DateTime?,
  );

  @override
  bool operator ==(Object other) =>
      other is Shift &&
      other.id == id &&
      other.uuid == uuid &&
      other.jobId == jobId &&
      other.status == status &&
      other.startUtc == startUtc &&
      other.endUtc == endUtc &&
      other.rawStartUtc == rawStartUtc &&
      other.rawEndUtc == rawEndUtc &&
      other.startOffsetMin == startOffsetMin &&
      other.endOffsetMin == endOffsetMin &&
      other.rateCentsPerHour == rateCentsPerHour &&
      other.breakMs == breakMs &&
      other.pausedAtUtc == pausedAtUtc &&
      other.tipsCents == tipsCents &&
      other.note == note &&
      other.paidAtUtc == paidAtUtc &&
      other.payoutId == payoutId &&
      other.amountCents == amountCents &&
      other.legacyId == legacyId &&
      other.source == source &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt &&
      other.deletedAt == deletedAt;

  @override
  int get hashCode => Object.hashAll([
    id,
    uuid,
    jobId,
    status,
    startUtc,
    endUtc,
    rawStartUtc,
    rawEndUtc,
    startOffsetMin,
    endOffsetMin,
    rateCentsPerHour,
    breakMs,
    pausedAtUtc,
    tipsCents,
    note,
    paidAtUtc,
    payoutId,
    amountCents,
    legacyId,
    source,
    createdAt,
    updatedAt,
    deletedAt,
  ]);

  @override
  String toString() =>
      'Shift($id, job $jobId, ${status.name}, $startUtc–$endUtc, '
      'break ${breakMs}ms, $rateCentsPerHour ct/h, amount $amountCents'
      '${isPaid ? ', paid' : ''}${isDeleted ? ', deleted' : ''})';
}
