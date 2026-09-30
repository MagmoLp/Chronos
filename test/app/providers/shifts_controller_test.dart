import 'package:chronos/app/providers/providers.dart';
import 'package:chronos/core/local_date.dart';
import 'package:chronos/core/time.dart';
import 'package:chronos/domain/errors.dart';
import 'package:chronos/domain/job.dart';
import 'package:chronos/domain/shift.dart';
import 'package:chronos/domain/shift_draft.dart';
import 'package:chronos/domain/validation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fixtures/provider_harness.dart';
import '../../fixtures/shifts.dart';

Matcher throwsCode(ChronosErrorCode code) =>
    throwsA(isA<ChronosException>().having((e) => e.code, 'code', code));

void main() {
  late ProviderHarness h;
  late ShiftsController controller;
  late Job job;

  setUp(() async {
    h = ProviderHarness(local(2026, 9, 30, 18));
    controller = h.read(shiftsControllerProvider.notifier);
    job = await h.job();
  });

  ShiftDraft draft(int day, int from, int to, {int breakMin = 0}) => ShiftDraft(
    jobId: job.id,
    startUtc: local(2026, 9, day, from),
    endUtc: local(2026, 9, day, to),
    breakMs: breakMin * msPerMinute,
  );

  test('save inserts a valid shift', () async {
    final result = await controller.save(draft(29, 8, 16, breakMin: 30));
    expect(result, isA<ShiftSaved>());
    final shift = (result as ShiftSaved).shift;
    expect(shift.amountCents, 11250);
    expect(result.validation.isClean, isTrue);
    expect(await h.settle(shiftListProvider(ShiftFilter.all)), [shift]);
  });

  test('errors are returned, nothing is saved', () async {
    final result = await controller.save(draft(29, 9, 8));
    expect(result, isA<ShiftSaveInvalid>());
    expect(result.validation.errors, [ShiftError.endNotAfterStart]);
    expect(await h.read(shiftRepositoryProvider).getDone(), isEmpty);
  });

  test('warnings need confirmation', () async {
    final first = (await controller.save(draft(29, 8, 16)) as ShiftSaved).shift;
    final overlap = await controller.save(draft(29, 15, 18));
    expect(overlap, isA<ShiftSaveNeedsConfirmation>());
    expect(overlap.validation.overlaps.single.id, first.id);
    expect(await h.read(shiftRepositoryProvider).getDone(), hasLength(1));
    final confirmed = await controller.save(draft(29, 15, 18), confirmed: true);
    expect(confirmed, isA<ShiftSaved>());

    final future = await controller.save(draft(30, 19, 23));
    expect(future.validation.warnings, [const StartsInFuture()]);
  });

  test(
    'update never creates a shift and ignores itself for overlaps',
    () async {
      final shift =
          (await controller.save(draft(29, 8, 16)) as ShiftSaved).shift;
      final result = await controller.save(
        ShiftDraft.fromShift(shift).copyWith(endUtc: local(2026, 9, 29, 17)),
        shiftId: shift.id,
      );
      expect(result, isA<ShiftSaved>());
      expect((result as ShiftSaved).shift.id, shift.id);
      expect(await h.read(shiftRepositoryProvider).getDone(), hasLength(1));
    },
  );

  test('double tap on save: the second call is refused', () async {
    final first = controller.save(draft(29, 8, 16));
    await expectLater(
      controller.save(draft(29, 8, 16)),
      throwsCode(ChronosErrorCode.busy),
    );
    await first;
    expect(await h.read(shiftRepositoryProvider).getDone(), hasLength(1));
  });

  test('validate reports overlaps from the database', () async {
    await controller.save(draft(29, 8, 16));
    final v = await controller.validate(draft(29, 10, 11));
    expect(v.overlaps, hasLength(1));
    expect((await controller.validate(draft(29, 11, 10))).errors, [
      ShiftError.endNotAfterStart,
    ]);
  });

  test('delete and undo; the list follows immediately', () async {
    final a = (await controller.save(draft(28, 8, 16)) as ShiftSaved).shift;
    final b = (await controller.save(draft(29, 8, 16)) as ShiftSaved).shift;
    expect(await h.settle(shiftListProvider(ShiftFilter.all)), [b, a]);
    final token = await controller.delete([a.id]);
    expect(token.shiftIds, [a.id]);
    expect(
      (await h.settle(shiftListProvider(ShiftFilter.all))).map((s) => s.id),
      [b.id],
    );
    expect((await h.settle(openSummaryProvider)).shiftCount, 1);
    await controller.undoDelete(token);
    expect(await h.settle(shiftListProvider(ShiftFilter.all)), hasLength(2));
    expect(h.effects.calls, isEmpty); // no running shift involved
  });

  test('togglePaid / setPaid with undo', () async {
    final a = (await controller.save(draft(28, 8, 16)) as ShiftSaved).shift;
    final b = (await controller.save(draft(29, 8, 16)) as ShiftSaved).shift;
    final toggled = await controller.togglePaid(a.id);
    expect(toggled.paid, isTrue);
    expect(
      (await h.settle(shiftListProvider(ShiftFilter.paid))).single.id,
      a.id,
    );
    await controller.undoPaid(toggled);
    expect(await h.settle(shiftListProvider(ShiftFilter.paid)), isEmpty);
    final all = await controller.setPaid([a.id, b.id], true);
    expect(all.previous, hasLength(2));
    expect(await h.settle(shiftListProvider(ShiftFilter.open)), isEmpty);
    await expectLater(
      controller.togglePaid(999),
      throwsCode(ChronosErrorCode.shiftNotFound),
    );
  });

  test('duplicate', () async {
    final a = (await controller.save(draft(28, 8, 16)) as ShiftSaved).shift;
    final copy = await controller.duplicate(
      a.id,
      onDate: LocalDate(2026, 9, 29),
    );
    expect(copy.startUtc, local(2026, 9, 29, 8));
  });

  test('newDraft: last shift times of the job, else 08:00–16:00', () async {
    final empty = await controller.newDraft(
      jobId: job.id,
      date: LocalDate(2026, 9, 30),
    );
    expect(empty.startUtc, local(2026, 9, 30, 8));
    expect(empty.endUtc, local(2026, 9, 30, 16));
    await h
        .read(shiftRepositoryProvider)
        .insertManual(
          ShiftDraft(
            jobId: job.id,
            startUtc: local(2026, 9, 28, 22),
            endUtc: local(2026, 9, 29, 6, 30),
          ),
        );
    final night = await controller.newDraft(
      jobId: job.id,
      date: LocalDate(2026, 9, 30),
    );
    expect(night.startUtc, local(2026, 9, 30, 22));
    expect(night.endUtc, local(2026, 10, 1, 6, 30));
    expect(night.breakMs, 0);
  });

  test('deleting a running shift updates the notification', () async {
    final running = await h
        .read(activeShiftControllerProvider.notifier)
        .start(job.id);
    final token = await controller.delete([running.id]);
    expect(h.effects.last.running, isNull);
    await controller.undoDelete(token);
    expect(h.effects.last.running!.id, running.id);
  });

  test('month groups for the list', () async {
    await controller.save(draft(28, 8, 16));
    await h
        .read(shiftRepositoryProvider)
        .insertManual(
          ShiftDraft(
            jobId: job.id,
            startUtc: local(2026, 8, 3, 8),
            endUtc: local(2026, 8, 3, 12),
          ),
        );
    final groups = await h.settle(shiftMonthGroupsProvider(ShiftFilter.all));
    expect(groups.map((g) => g.month), [9, 8]);
    expect(groups.first.earnedCents, 12000);
    expect(groups.last.workedMs, 4 * msPerHour);
  });
}
