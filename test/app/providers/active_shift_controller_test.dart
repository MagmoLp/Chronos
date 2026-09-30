import 'package:chronos/app/providers/providers.dart';
import 'package:chronos/core/time.dart';
import 'package:chronos/domain/errors.dart';
import 'package:chronos/domain/job.dart';
import 'package:chronos/domain/shift_draft.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fixtures/provider_harness.dart';
import '../../fixtures/shifts.dart';

Matcher throwsCode(ChronosErrorCode code) =>
    throwsA(isA<ChronosException>().having((e) => e.code, 'code', code));

void main() {
  late ProviderHarness h;
  late ActiveShiftController controller;
  late Job job;

  setUp(() async {
    h = ProviderHarness(local(2026, 9, 30, 8, 2));
    controller = h.read(activeShiftControllerProvider.notifier);
    job = await h.job(rounding: RoundingRule.nearest15);
  });

  test('start posts the running shift with its job', () async {
    final shift = await controller.start(job.id);
    expect(shift.isRunning, isTrue);
    expect(h.effects.calls, hasLength(1));
    expect(h.effects.last.running!.id, shift.id);
    expect(h.effects.last.job!.id, job.id);
    expect(await h.settle(runningShiftProvider), shift);
    expect(h.read(activeShiftControllerProvider), isFalse);
  });

  test('busy while an action runs; a second action is refused', () async {
    final first = controller.start(job.id);
    expect(h.read(activeShiftControllerProvider), isTrue);
    await expectLater(
      controller.start(job.id),
      throwsCode(ChronosErrorCode.busy),
    );
    await first;
    expect(h.read(activeShiftControllerProvider), isFalse);
    expect(h.effects.calls, hasLength(1));
  });

  test('refused actions reset busy and post nothing', () async {
    await expectLater(
      controller.pause(),
      throwsCode(ChronosErrorCode.noRunningShift),
    );
    expect(h.read(activeShiftControllerProvider), isFalse);
    expect(h.effects.calls, isEmpty);
  });

  test('pause, resume and adjust start each post once', () async {
    await controller.start(job.id);
    h.clock.advance(const Duration(hours: 1));
    final paused = await controller.pause();
    expect(h.effects.last.running!.isPaused, isTrue);
    h.clock.advance(const Duration(minutes: 15));
    final resumed = await controller.resume();
    expect(resumed.breakMs, 15 * msPerMinute);
    expect(paused.isPaused, isTrue);
    final adjusted = await controller.adjustStart(local(2026, 9, 30, 7, 30));
    expect(adjusted.startUtc, local(2026, 9, 30, 7, 30));
    expect(h.effects.calls, hasLength(4));
    expect(h.effects.last.running!.startUtc, local(2026, 9, 30, 7, 30));
  });

  test('previewFinish shows rounded values for the sheet', () async {
    expect(await controller.previewFinish(), isNull);
    await controller.start(job.id);
    h.clock.set(local(2026, 9, 30, 16, 10));
    final preview = (await controller.previewFinish())!;
    expect(preview.startUtc, local(2026, 9, 30, 8));
    expect(preview.endUtc, local(2026, 9, 30, 16, 15));
    expect(preview.amountCents, 12375);
    final edited = (await controller.previewFinish(
      endUtc: local(2026, 9, 30, 16),
      breakMs: 30 * msPerMinute,
    ))!;
    expect(edited.amountCents, 11250);
  });

  test('finish and undo', () async {
    await controller.start(job.id);
    h.clock.set(local(2026, 9, 30, 16, 10));
    final result = await controller.finish(tipsCents: 500, note: 'Gala');
    expect(result.after.isDone, isTrue);
    expect(result.after.amountCents, 12375);
    expect(h.effects.last.running, isNull);
    expect(h.effects.last.job, isNull);
    expect(await h.settle(runningShiftProvider), isNull);

    final back = await controller.undoFinish(result);
    expect(back.isRunning, isTrue);
    expect(back.startUtc, local(2026, 9, 30, 8, 2));
    expect(h.effects.last.running!.id, back.id);
  });

  test('discard and undo', () async {
    await controller.start(job.id);
    final discarded = await controller.discard();
    expect(discarded.isDeleted, isTrue);
    expect(h.effects.last.running, isNull);
    await controller.undoDiscard(discarded);
    expect(h.effects.last.running!.id, discarded.id);
  });

  test('reconcile posts the database state even while busy', () async {
    await controller.reconcile();
    expect(h.effects.last.running, isNull);
    await controller.start(job.id);
    await controller.reconcile();
    expect(h.effects.calls, hasLength(3));
    expect(h.effects.last.running, isNotNull);
  });

  test('side-effect failures are logged, the action still succeeds', () async {
    h.effects.fail = true;
    final shift = await controller.start(job.id);
    expect(shift.isRunning, isTrue);
    await pumpEventQueue();
    expect(await h.errorLog.read(), contains('notification failed'));
  });

  test('overlapsIfStartedAt warns before starting earlier', () async {
    await h
        .read(shiftRepositoryProvider)
        .insertManual(
          ShiftDraft(
            jobId: job.id,
            startUtc: local(2026, 9, 30, 6),
            endUtc: local(2026, 9, 30, 7, 45),
          ),
        );
    expect(
      await controller.overlapsIfStartedAt(local(2026, 9, 30, 7, 30)),
      hasLength(1),
    );
    expect(
      await controller.overlapsIfStartedAt(local(2026, 9, 30, 7, 45)),
      isEmpty,
    );
  });

  test('runningShiftWithJobProvider joins shift and job', () async {
    expect(await h.settle(runningShiftWithJobProvider), isNull);
    await controller.start(job.id);
    final value = (await h.settle(runningShiftWithJobProvider))!;
    expect(value.job!.name, 'Catering');
    expect(value.shift.jobId, job.id);
  });

  test('unawaited start from two places: only one shift', () async {
    final results = await Future.wait([
      controller.start(job.id).then((_) => true, onError: (Object _) => false),
      controller.start(job.id).then((_) => true, onError: (Object _) => false),
    ]);
    expect(results.where((ok) => ok), hasLength(1));
  });
}
