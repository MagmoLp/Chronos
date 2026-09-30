import 'package:chronos/core/time.dart';
import 'package:chronos/domain/finish.dart';
import 'package:chronos/domain/job.dart';
import 'package:chronos/domain/validation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/shifts.dart';
import '../fixtures/tz.dart';

void main() {
  test('no rounding: raw times are billed', () {
    final running = runningShift(start: local(2026, 9, 30, 8, 2));
    final p = previewFinish(
      running: running,
      rounding: RoundingRule.none,
      endUtc: local(2026, 9, 30, 16, 17),
    );
    expect(p.startUtc, p.rawStartUtc);
    expect(p.endUtc, p.rawEndUtc);
    expect(p.startRounded, isFalse);
    expect(p.endRounded, isFalse);
    expect(p.workedMs, 8 * msPerHour + 15 * msPerMinute);
    expect(p.amountCents, 12375);
    expect(p.isValid, isTrue);
    expect(p.durationMs, p.workedMs);
  });

  test('15-min rounding: 08:07:30–16:07 → 08:15–16:00 = 7:45 h = 116,25 €', () {
    final running = runningShift(start: local(2026, 9, 30, 8, 7, 30));
    final p = previewFinish(
      running: running,
      rounding: RoundingRule.nearest15,
      endUtc: local(2026, 9, 30, 16, 7),
    );
    expect(p.rawStartUtc, local(2026, 9, 30, 8, 7, 30));
    expect(p.startUtc, local(2026, 9, 30, 8, 15));
    expect(p.endUtc, local(2026, 9, 30, 16, 0));
    expect(p.startRounded, isTrue);
    expect(p.workedMs, 7 * msPerHour + 45 * msPerMinute);
    expect(p.amountCents, 11625);
    expect(p.rounding, RoundingRule.nearest15);
  });

  test('default break includes the pause in progress', () {
    final running = runningShift(
      start: local(2026, 9, 30, 8),
      breakMs: 15 * msPerMinute,
      pausedAt: local(2026, 9, 30, 15, 45),
    );
    final p = previewFinish(
      running: running,
      rounding: RoundingRule.none,
      endUtc: local(2026, 9, 30, 16),
    );
    expect(p.breakMs, 30 * msPerMinute);
    expect(p.workedMs, 7 * msPerHour + 30 * msPerMinute);
  });

  test('explicit break overrides', () {
    final running = runningShift(start: local(2026, 9, 30, 8), breakMs: 999);
    final p = previewFinish(
      running: running,
      rounding: RoundingRule.none,
      endUtc: local(2026, 9, 30, 9),
      breakMs: 0,
    );
    expect(p.breakMs, 0);
    expect(p.amountCents, 1500);
  });

  test('end before start is an error', () {
    final running = runningShift(start: local(2026, 9, 30, 8));
    final p = previewFinish(
      running: running,
      rounding: RoundingRule.nearest15,
      endUtc: local(2026, 9, 30, 7),
    );
    expect(p.errors, [ShiftError.endNotAfterStart]);
    expect(p.isValid, isFalse);
    expect(p.workedMs, 0);
    expect(p.amountCents, 0);
  });

  test('a very short shift rounded to zero is still valid', () {
    final running = runningShift(start: local(2026, 9, 30, 8, 1));
    final p = previewFinish(
      running: running,
      rounding: RoundingRule.nearest15,
      endUtc: local(2026, 9, 30, 8, 6),
    );
    expect(p.startUtc, p.endUtc);
    expect(p.isValid, isTrue);
    expect(p.amountCents, 0);
  });

  test('a break covering the whole billed duration is an error', () {
    final running = runningShift(
      start: local(2026, 9, 30, 8, 1),
      breakMs: 3 * msPerMinute,
    );
    final p = previewFinish(
      running: running,
      rounding: RoundingRule.nearest15,
      endUtc: local(2026, 9, 30, 8, 6),
    );
    expect(p.errors, [ShiftError.breakNotShorterThanDuration]);
  });

  test('midnight crossing', () {
    final running = runningShift(start: local(2026, 9, 30, 22));
    final p = previewFinish(
      running: running,
      rounding: RoundingRule.none,
      endUtc: local(2026, 10, 1, 6),
    );
    expect(p.workedMs, 8 * msPerHour);
    expect(p.amountCents, 12000);
  });

  test('Berlin: night shift over the autumn switch pays 9 h', () {
    final running = runningShift(start: local(2026, 10, 24, 22));
    final p = previewFinish(
      running: running,
      rounding: RoundingRule.nearest15,
      endUtc: local(2026, 10, 25, 6),
    );
    expect(p.workedMs, 9 * msPerHour);
    expect(p.amountCents, 13500);
  }, skip: skipUnlessBerlin);

  test('equality', () {
    final running = runningShift(start: local(2026, 9, 30, 8));
    FinishPreview make() => previewFinish(
      running: running,
      rounding: RoundingRule.none,
      endUtc: local(2026, 9, 30, 9),
    );
    expect(make(), make());
    expect(make().hashCode, make().hashCode);
    expect(make().toString(), contains('1500 ct'));
  });
}
