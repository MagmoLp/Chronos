import 'package:chronos/core/local_date.dart';
import 'package:chronos/core/time.dart';
import 'package:chronos/data/payout_repository.dart';
import 'package:chronos/domain/errors.dart';
import 'package:chronos/domain/job.dart';
import 'package:chronos/domain/shift_draft.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/db.dart';
import '../fixtures/shifts.dart';

Matcher throwsCode(ChronosErrorCode code) =>
    throwsA(isA<ChronosException>().having((e) => e.code, 'code', code));

void main() {
  late DataHarness h;
  late PayoutRepository payouts;
  late Job a;
  late Job b;

  setUp(() async {
    h = DataHarness(local(2026, 9, 30, 12));
    payouts = PayoutRepository(h.db, clock: h.clock.clock);
    a = await h.job(name: 'A');
    b = await h.job(name: 'B', centsPerHour: 2000);
  });

  Future<int> add(Job job, int day, {int fromH = 8, int toH = 16}) async =>
      (await h.shifts.insertManual(
        ShiftDraft(
          jobId: job.id,
          startUtc: local(2026, 9, day, fromH),
          endUtc: local(2026, 9, day, toH),
        ),
      )).id;

  test('preview selects open shifts up to the date (inclusive)', () async {
    final s1 = await add(a, 10);
    final s2 = await add(b, 12, toH: 12);
    await add(a, 20);
    final paid = await add(a, 5);
    await h.shifts.setPaid([paid], true);
    final sel = await payouts.preview(until: LocalDate(2026, 9, 12));
    expect(sel.shiftIds, [s1, s2]);
    expect(sel.expectedCents, 12000 + 8000);
    expect(sel.workedMs, 12 * msPerHour);
    final onlyA = await payouts.preview(
      until: LocalDate(2026, 9, 30),
      jobId: a.id,
    );
    expect(onlyA.count, 2);
  });

  test('an overnight shift belongs to its start date', () async {
    final s = await add(a, 12, fromH: 22, toH: 23);
    final shift = await h.shifts.update(
      s,
      ShiftDraft(
        jobId: a.id,
        startUtc: local(2026, 9, 12, 22),
        endUtc: local(2026, 9, 13, 6),
      ),
    );
    expect((await payouts.preview(until: LocalDate(2026, 9, 12))).shiftIds, [
      shift.id,
    ]);
  });

  test('create marks the shifts paid and links them', () async {
    final s1 = await add(a, 10);
    final s2 = await add(a, 11);
    final later = await add(a, 25);
    final payout = await payouts.create(
      until: LocalDate(2026, 9, 15),
      jobId: a.id,
      receivedCents: 23000,
      note: ' Sept ',
    );
    expect(payout.expectedCents, 24000);
    expect(payout.receivedCents, 23000);
    expect(payout.differenceCents, -1000);
    expect(payout.jobId, a.id);
    expect(payout.untilDate, LocalDate(2026, 9, 15));
    expect(payout.paidOn, LocalDate(2026, 9, 30));
    expect(payout.note, 'Sept');
    for (final id in [s1, s2]) {
      final s = (await h.shifts.getById(id))!;
      expect(s.isPaid, isTrue);
      expect(s.payoutId, payout.id);
    }
    expect((await h.shifts.getById(later))!.isPaid, isFalse);
    expect(await payouts.getById(payout.id), payout);
  });

  test('received defaults to expected, paidOn can be set', () async {
    await add(b, 10);
    final payout = await payouts.create(
      until: LocalDate(2026, 9, 30),
      paidOn: LocalDate(2026, 10, 5),
    );
    expect(payout.receivedCents, payout.expectedCents);
    expect(payout.jobId, isNull);
    expect(payout.paidOn, LocalDate(2026, 10, 5));
  });

  test('errors', () async {
    await expectLater(
      payouts.create(until: LocalDate(2026, 9, 30)),
      throwsCode(ChronosErrorCode.nothingToPayOut),
    );
    expect(
      () => payouts.create(until: LocalDate(2026, 9, 30), receivedCents: -1),
      throwsCode(ChronosErrorCode.invalidAmount),
    );
  });

  test('undo reopens the shifts and removes the payout', () async {
    final s1 = await add(a, 10);
    final manuallyPaid = await add(a, 11);
    await h.shifts.setPaid([manuallyPaid], true);
    final payout = await payouts.create(until: LocalDate(2026, 9, 30));
    expect(await payouts.undo(payout.id), 1);
    expect((await h.shifts.getById(s1))!.isPaid, isFalse);
    expect((await h.shifts.getById(manuallyPaid))!.isPaid, isTrue);
    expect(await payouts.getById(payout.id), isNull);
  });

  test('watchPayouts lists newest first, optionally per job', () async {
    await add(a, 10);
    await add(b, 11);
    final stream = payouts.watchPayouts();
    expect(await stream.first, isEmpty);
    final p1 = await payouts.create(
      until: LocalDate(2026, 9, 30),
      jobId: a.id,
      paidOn: LocalDate(2026, 9, 1),
    );
    final p2 = await payouts.create(
      until: LocalDate(2026, 9, 30),
      jobId: b.id,
      paidOn: LocalDate(2026, 9, 2),
    );
    expect((await stream.first).map((p) => p.id), [p2.id, p1.id]);
    expect((await payouts.getPayouts(jobId: a.id)).single.id, p1.id);
  });

  test('watchPreview reacts to new shifts', () async {
    final stream = payouts.watchPreview(until: LocalDate(2026, 9, 30));
    expect((await stream.first).isEmpty, isTrue);
    await add(a, 10);
    expect((await stream.first).count, 1);
  });
}
