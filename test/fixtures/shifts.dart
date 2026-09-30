import 'package:chronos/core/money.dart';
import 'package:chronos/core/time.dart';
import 'package:chronos/domain/shift.dart';

/// UTC instant of a local wall-clock time (device time zone).
DateTime local(int y, int m, int d, [int h = 0, int min = 0, int s = 0]) =>
    DateTime(y, m, d, h, min, s).toUtc();

/// A finished shift for domain tests.
Shift doneShift({
  int id = 1,
  int jobId = 1,
  required DateTime start,
  required DateTime end,
  int breakMs = 0,
  int rate = 1500,
  int tips = 0,
  bool paid = false,
  int? payoutId,
  DateTime? deletedAt,
  String? legacyId,
  int? amountCents,
  ShiftSource source = ShiftSource.manual,
  String? note,
}) {
  final startUtc = start.toUtc();
  final endUtc = end.toUtc();
  final worked = endUtc.difference(startUtc).inMilliseconds - breakMs;
  return Shift(
    id: id,
    uuid: 'uuid-$id',
    jobId: jobId,
    status: ShiftStatus.done,
    startUtc: startUtc,
    endUtc: endUtc,
    rawStartUtc: startUtc,
    rawEndUtc: endUtc,
    startOffsetMin: offsetMinutesAt(startUtc),
    endOffsetMin: offsetMinutesAt(endUtc),
    rateCentsPerHour: rate,
    breakMs: breakMs,
    tipsCents: tips,
    note: note,
    paidAtUtc: paid ? endUtc : null,
    payoutId: payoutId,
    amountCents: amountCents ?? earningsCents(worked < 0 ? 0 : worked, rate),
    legacyId: legacyId,
    source: source,
    createdAt: startUtc,
    updatedAt: endUtc,
    deletedAt: deletedAt,
  );
}

/// A running shift for domain tests.
Shift runningShift({
  int id = 99,
  int jobId = 1,
  required DateTime start,
  int breakMs = 0,
  DateTime? pausedAt,
  int rate = 1500,
}) {
  final startUtc = start.toUtc();
  return Shift(
    id: id,
    uuid: 'uuid-$id',
    jobId: jobId,
    status: ShiftStatus.running,
    startUtc: startUtc,
    rawStartUtc: startUtc,
    startOffsetMin: offsetMinutesAt(startUtc),
    rateCentsPerHour: rate,
    breakMs: breakMs,
    pausedAtUtc: pausedAt?.toUtc(),
    source: ShiftSource.timer,
    createdAt: startUtc,
    updatedAt: startUtc,
  );
}
