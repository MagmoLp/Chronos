import '../core/local_date.dart';
import '../core/time.dart';
import 'shift.dart';

class _Unset {
  const _Unset();
}

const Object _unset = _Unset();

/// Input for creating or editing a finished shift (editor, duplicate).
final class ShiftDraft {
  /// Creates a draft from UTC instants.
  const ShiftDraft({
    required this.jobId,
    required this.startUtc,
    required this.endUtc,
    this.breakMs = 0,
    this.tipsCents = 0,
    this.note,
    this.paid = false,
    this.rateCentsPerHour,
  });

  /// Builds a draft from editor fields: local [date], wall-clock start and
  /// end, and whether the end is on the next day.
  ///
  /// With [endsNextDay] `null` the value is derived: an end at or before the
  /// start means the shift ends on the next day (see [endsNextDayFor]).
  factory ShiftDraft.fromLocal({
    required int jobId,
    required LocalDate date,
    required int startHour,
    required int startMinute,
    required int endHour,
    required int endMinute,
    bool? endsNextDay,
    int breakMs = 0,
    int tipsCents = 0,
    String? note,
    bool paid = false,
    int? rateCentsPerHour,
  }) {
    final nextDay =
        endsNextDay ??
        endsNextDayFor(
          startHour: startHour,
          startMinute: startMinute,
          endHour: endHour,
          endMinute: endMinute,
        );
    return ShiftDraft(
      jobId: jobId,
      startUtc: combineLocal(date, startHour, startMinute),
      endUtc: combineLocal(date, endHour, endMinute, nextDay: nextDay),
      breakMs: breakMs,
      tipsCents: tipsCents,
      note: note,
      paid: paid,
      rateCentsPerHour: rateCentsPerHour,
    );
  }

  /// The editable fields of an existing finished [shift].
  factory ShiftDraft.fromShift(Shift shift) => ShiftDraft(
    jobId: shift.jobId,
    startUtc: shift.startUtc,
    endUtc: shift.endUtc ?? shift.startUtc,
    breakMs: shift.breakMs,
    tipsCents: shift.tipsCents,
    note: shift.note,
    paid: shift.isPaid,
    rateCentsPerHour: shift.rateCentsPerHour,
  );

  /// Whether a wall-clock end at or before the start means "ends next day".
  static bool endsNextDayFor({
    required int startHour,
    required int startMinute,
    required int endHour,
    required int endMinute,
  }) => endHour * 60 + endMinute <= startHour * 60 + startMinute;

  /// Job of the shift.
  final int jobId;

  /// Start instant (UTC).
  final DateTime startUtc;

  /// End instant (UTC).
  final DateTime endUtc;

  /// Break in ms.
  final int breakMs;

  /// Tips in cents.
  final int tipsCents;

  /// Optional note; blank notes are stored as `null`.
  final String? note;

  /// Paid status.
  final bool paid;

  /// Wage override. `null` = new shift: the job's rate on the start date;
  /// edit: keep the stored snapshot unless the job changes.
  final int? rateCentsPerHour;

  /// Gross duration in ms (may be ≤ 0 for invalid input).
  int get durationMs => endUtc.difference(startUtc).inMilliseconds;

  /// Worked time (duration − break), never negative.
  int get workedMs {
    final worked = durationMs - breakMs;
    return worked < 0 ? 0 : worked;
  }

  /// Local calendar date of the start.
  LocalDate get localStartDate => LocalDate.ofInstant(startUtc);

  /// Copy with the given fields replaced ([note] and [rateCentsPerHour] can
  /// be cleared with an explicit `null`).
  ShiftDraft copyWith({
    int? jobId,
    DateTime? startUtc,
    DateTime? endUtc,
    int? breakMs,
    int? tipsCents,
    Object? note = _unset,
    bool? paid,
    Object? rateCentsPerHour = _unset,
  }) => ShiftDraft(
    jobId: jobId ?? this.jobId,
    startUtc: startUtc ?? this.startUtc,
    endUtc: endUtc ?? this.endUtc,
    breakMs: breakMs ?? this.breakMs,
    tipsCents: tipsCents ?? this.tipsCents,
    note: identical(note, _unset) ? this.note : note as String?,
    paid: paid ?? this.paid,
    rateCentsPerHour: identical(rateCentsPerHour, _unset)
        ? this.rateCentsPerHour
        : rateCentsPerHour as int?,
  );

  @override
  bool operator ==(Object other) =>
      other is ShiftDraft &&
      other.jobId == jobId &&
      other.startUtc == startUtc &&
      other.endUtc == endUtc &&
      other.breakMs == breakMs &&
      other.tipsCents == tipsCents &&
      other.note == note &&
      other.paid == paid &&
      other.rateCentsPerHour == rateCentsPerHour;

  @override
  int get hashCode => Object.hash(
    jobId,
    startUtc,
    endUtc,
    breakMs,
    tipsCents,
    note,
    paid,
    rateCentsPerHour,
  );

  @override
  String toString() =>
      'ShiftDraft(job $jobId, $startUtc–$endUtc, break ${breakMs}ms)';
}
