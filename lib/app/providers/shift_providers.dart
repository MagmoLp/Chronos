import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/clock.dart';
import '../../core/local_date.dart';
import '../../core/time.dart';
import '../../data/job_repository.dart';
import '../../data/shift_repository.dart';
import '../../domain/errors.dart';
import '../../domain/finish.dart';
import '../../domain/finish.dart' as finish_logic show previewFinish;
import '../../domain/job.dart';
import '../../domain/shift.dart';
import '../../domain/shift_draft.dart';
import '../../domain/summaries.dart';
import '../../domain/validation.dart';
import '../error_log.dart';
import 'async_utils.dart';
import 'core_providers.dart';
import 'job_providers.dart';
import 'shift_side_effects.dart';

// ------------------------------------------------------------------- reads

/// The running shift (paused or not), or `null`. Emits on every change.
final runningShiftProvider = StreamProvider<Shift?>(
  (ref) => ref.watch(shiftRepositoryProvider).watchRunning(),
  name: 'runningShiftProvider',
);

/// Finished shifts for the list filter (Alle / Offen / Bezahlt), newest
/// first.
final shiftListProvider = StreamProvider.autoDispose
    .family<List<Shift>, ShiftFilter>(
      (ref, filter) =>
          ref.watch(shiftRepositoryProvider).watchDone(filter: filter),
      name: 'shiftListProvider',
    );

/// [shiftListProvider] grouped by month with monthly totals.
final shiftMonthGroupsProvider = Provider.autoDispose
    .family<AsyncValue<List<ShiftMonthGroup>>, ShiftFilter>(
      (ref, filter) =>
          ref.watch(shiftListProvider(filter)).whenData(groupShiftsByMonth),
      name: 'shiftMonthGroupsProvider',
    );

/// One shift by id (also soft-deleted ones), for the editor.
final shiftByIdProvider = StreamProvider.autoDispose.family<Shift?, int>(
  (ref, id) => ref.watch(shiftRepositoryProvider).watchById(id),
  name: 'shiftByIdProvider',
);

/// The most recent finished shift ("Letzte Schicht …").
final lastShiftProvider = StreamProvider<Shift?>(
  (ref) => ref.watch(shiftRepositoryProvider).watchLastDone(),
  name: 'lastShiftProvider',
);

/// Finished shifts whose local start date lies in the range, newest first.
final shiftsInRangeProvider = StreamProvider.autoDispose
    .family<List<Shift>, LocalDateRange>(
      (ref, range) => ref.watch(shiftRepositoryProvider).watchRange(range),
      name: 'shiftsInRangeProvider',
    );

/// The running shift together with its job.
final runningShiftWithJobProvider =
    Provider<AsyncValue<({Shift shift, Job? job})?>>((ref) {
      final running = ref.watch(runningShiftProvider);
      final jobs = ref.watch(jobsProvider);
      return combineAsync2(running, jobs, (shift, jobList) {
        if (shift == null) return null;
        Job? job;
        for (final j in jobList) {
          if (j.id == shift.jobId) job = j;
        }
        return (shift: shift, job: job);
      });
    }, name: 'runningShiftWithJobProvider');

// ----------------------------------------------------------- shared helper

/// Base for intent controllers: `state` is `true` while an action runs, and
/// a second action meanwhile fails with [ChronosErrorCode.busy] (protects
/// against double taps).
abstract class BusyNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  /// Runs [action] as the single in-flight action of this controller.
  Future<T> runBusy<T>(Future<T> Function() action) async {
    if (state) throw const ChronosException(ChronosErrorCode.busy);
    state = true;
    try {
      return await action();
    } finally {
      if (ref.mounted) state = false;
    }
  }
}

/// Tells the side effects (notification, reminder) about the current
/// running shift. Failures are logged, never thrown: the data change already
/// happened.
Future<void> notifyShiftSideEffects(Ref ref) async {
  final shifts = ref.read(shiftRepositoryProvider);
  final jobs = ref.read(jobRepositoryProvider);
  final effects = ref.read(shiftSideEffectsProvider);
  final log = ref.read(errorLogProvider);
  try {
    final running = await shifts.getRunning();
    final job = running == null ? null : await jobs.getJob(running.jobId);
    await effects.shiftChanged(running, job);
  } on Object catch (e, st) {
    unawaited(log.record(e, st, context: 'shiftSideEffects'));
  }
}

// ----------------------------------------------------------- active shift

/// Timer actions of the running shift. Every change is followed by one
/// side-effects call (notification / reminder).
final activeShiftControllerProvider =
    NotifierProvider<ActiveShiftController, bool>(
      ActiveShiftController.new,
      name: 'activeShiftControllerProvider',
    );

/// Start, pause, resume, adjust start, finish (+ undo) and discard.
///
/// All methods throw [ChronosException] for refused actions (see the
/// repository docs) and [ChronosErrorCode.busy] during another action.
class ActiveShiftController extends BusyNotifier {
  ShiftRepository get _shifts => ref.read(shiftRepositoryProvider);
  JobRepository get _jobs => ref.read(jobRepositoryProvider);

  Future<T> _change<T>(Future<T> Function(ShiftRepository shifts) action) =>
      runBusy(() async {
        final result = await action(_shifts);
        await notifyShiftSideEffects(ref);
        return result;
      });

  /// Starts a shift for [jobId] now or at [startUtc] ("Früher angefangen?").
  Future<Shift> start(int jobId, {DateTime? startUtc}) =>
      _change((s) => s.start(jobId, startUtc: startUtc));

  /// Shifts a start at [startUtc] would overlap (warn before starting
  /// earlier than the end of the last shift).
  Future<List<Shift>> overlapsIfStartedAt(DateTime startUtc) {
    final now = ref.read(clockProvider).nowUtc();
    return _shifts.findOverlaps(
      startUtc,
      now.isAfter(startUtc) ? now : startUtc,
    );
  }

  /// Pauses the running shift.
  Future<Shift> pause() => _change((s) => s.pause());

  /// Resumes the paused shift.
  Future<Shift> resume() => _change((s) => s.resume());

  /// Moves the start of the running shift.
  Future<Shift> adjustStart(DateTime startUtc) =>
      _change((s) => s.adjustStart(startUtc));

  /// Values for the "Schicht beenden" sheet (rounded times, break, amount)
  /// at [endUtc] (default now); `null` if nothing runs.
  Future<FinishPreview?> previewFinish({DateTime? endUtc, int? breakMs}) async {
    final running = await _shifts.getRunning();
    if (running == null) return null;
    final job = await _jobs.getJob(running.jobId);
    return finish_logic.previewFinish(
      running: running,
      rounding: job?.rounding ?? RoundingRule.none,
      endUtc: endUtc ?? ref.read(clockProvider).nowUtc(),
      breakMs: breakMs,
    );
  }

  /// Finishes the running shift. Keep the result for [undoFinish] (snackbar
  /// "Schicht gespeichert · 7:45 h · 116,25 €": `result.after`).
  Future<FinishResult> finish({
    DateTime? endUtc,
    int? breakMs,
    int tipsCents = 0,
    String? note,
  }) => _change(
    (s) => s.finish(
      endUtc: endUtc,
      breakMs: breakMs,
      tipsCents: tipsCents,
      note: note,
    ),
  );

  /// Undo of [finish]: the shift runs again exactly as before.
  Future<Shift> undoFinish(FinishResult result) =>
      _change((s) => s.revertFinish(result.after.id, restore: result.before));

  /// Discards the running shift (after the user confirmed). Returns it for
  /// [undoDiscard].
  Future<Shift> discard() => _change((s) => s.discardRunning());

  /// Undo of [discard].
  Future<void> undoDiscard(Shift discarded) =>
      _change((s) => s.undoDelete([discarded.id]));

  /// Re-syncs notification and reminder with the database (app start and
  /// resume, after settings changes). Not blocked by [state].
  Future<void> reconcile() => notifyShiftSideEffects(ref);
}

// ------------------------------------------------------------------ editor

/// Outcome of [ShiftsController.save].
sealed class ShiftSaveResult {
  const ShiftSaveResult(this.validation);

  /// The validation that led to this result.
  final ShiftValidation validation;
}

/// Saved.
final class ShiftSaved extends ShiftSaveResult {
  /// Creates the result.
  const ShiftSaved(this.shift, super.validation);

  /// The stored shift.
  final Shift shift;
}

/// Not saved: the input has errors (see `validation.errors`).
final class ShiftSaveInvalid extends ShiftSaveResult {
  /// Creates the result.
  const ShiftSaveInvalid(super.validation);
}

/// Not saved yet: warnings need confirmation (save again with
/// `confirmed: true`).
final class ShiftSaveNeedsConfirmation extends ShiftSaveResult {
  /// Creates the result.
  const ShiftSaveNeedsConfirmation(super.validation);
}

/// Undo token of [ShiftsController.delete].
final class DeleteUndo {
  /// Creates a token.
  const DeleteUndo(this.shifts);

  /// The deleted shifts (as they were after deleting).
  final List<Shift> shifts;

  /// Their ids.
  List<int> get shiftIds => [for (final s in shifts) s.id];
}

/// Undo token of [ShiftsController.setPaid] / [ShiftsController.togglePaid].
final class PaidUndo {
  /// Creates a token.
  const PaidUndo({required this.previous, required this.paid});

  /// States before the change.
  final List<PaidState> previous;

  /// The new state that was set.
  final bool paid;
}

/// Editor and list actions on finished shifts.
final shiftsControllerProvider = NotifierProvider<ShiftsController, bool>(
  ShiftsController.new,
  name: 'shiftsControllerProvider',
);

/// Validate/save (insert or update), duplicate, delete + undo, paid + undo.
class ShiftsController extends BusyNotifier {
  ShiftRepository get _shifts => ref.read(shiftRepositoryProvider);

  /// Validates editor input against the other shifts and the clock
  /// ([shiftId] = the shift being edited).
  Future<ShiftValidation> validate(ShiftDraft draft, {int? shiftId}) async {
    final now = ref.read(clockProvider).nowUtc();
    final others = draft.endUtc.isAfter(draft.startUtc)
        ? await _shifts.findOverlaps(
            draft.startUtc,
            draft.endUtc,
            excludeId: shiftId,
          )
        : const <Shift>[];
    return validateDraft(
      draft,
      now: now,
      others: others,
      ignoreShiftId: shiftId,
    );
  }

  /// Saves the editor: inserts when [shiftId] is `null`, else updates.
  ///
  /// Errors → [ShiftSaveInvalid]; warnings without [confirmed] →
  /// [ShiftSaveNeedsConfirmation]; otherwise [ShiftSaved]. A second call
  /// while saving throws [ChronosErrorCode.busy] (no double insert).
  Future<ShiftSaveResult> save(
    ShiftDraft draft, {
    int? shiftId,
    bool confirmed = false,
  }) => runBusy(() async {
    final validation = await validate(draft, shiftId: shiftId);
    if (!validation.isValid) return ShiftSaveInvalid(validation);
    if (validation.hasWarnings && !confirmed) {
      return ShiftSaveNeedsConfirmation(validation);
    }
    final shift = shiftId == null
        ? await _shifts.insertManual(draft)
        : await _shifts.update(shiftId, draft);
    return ShiftSaved(shift, validation);
  });

  /// Copies a finished shift (same date, or [onDate]).
  Future<Shift> duplicate(int shiftId, {LocalDate? onDate}) =>
      runBusy(() => _shifts.duplicate(shiftId, onDate: onDate));

  /// Soft-deletes shifts; keep the token for [undoDelete].
  Future<DeleteUndo> delete(Iterable<int> shiftIds) => runBusy(() async {
    final deleted = await _shifts.softDelete(shiftIds);
    if (deleted.any((s) => s.isRunning)) await notifyShiftSideEffects(ref);
    return DeleteUndo(deleted);
  });

  /// Restores deleted shifts.
  Future<void> undoDelete(DeleteUndo token) => runBusy(() async {
    await _shifts.undoDelete(token.shiftIds);
    if (token.shifts.any((s) => s.isRunning)) {
      await notifyShiftSideEffects(ref);
    }
  });

  /// Marks shifts paid or open; keep the token for [undoPaid].
  Future<PaidUndo> setPaid(Iterable<int> shiftIds, bool paid) => runBusy(
    () async =>
        PaidUndo(previous: await _shifts.setPaid(shiftIds, paid), paid: paid),
  );

  /// Flips the paid state of one shift (swipe right).
  Future<PaidUndo> togglePaid(int shiftId) => runBusy(() async {
    final shift = await _shifts.getById(shiftId);
    if (shift == null || shift.isDeleted) {
      throw ChronosException(ChronosErrorCode.shiftNotFound, detail: shiftId);
    }
    final paid = !shift.isPaid;
    return PaidUndo(
      previous: await _shifts.setPaid([shiftId], paid),
      paid: paid,
    );
  });

  /// Restores the paid states before [token].
  Future<void> undoPaid(PaidUndo token) =>
      runBusy(() => _shifts.restorePaidStates(token.previous));

  /// Default times for a new shift: those of the last shift of [jobId]
  /// (wall clock) on [date], else 08:00–16:00.
  Future<ShiftDraft> newDraft({
    required int jobId,
    required LocalDate date,
  }) async {
    final last = await _shifts.lastDone(jobId: jobId);
    if (last == null || last.endUtc == null) {
      return ShiftDraft.fromLocal(
        jobId: jobId,
        date: date,
        startHour: 8,
        startMinute: 0,
        endHour: 16,
        endMinute: 0,
      );
    }
    final start = last.startUtc.toLocal();
    final end = last.endUtc!.toLocal();
    return ShiftDraft.fromLocal(
      jobId: jobId,
      date: date,
      startHour: start.hour,
      startMinute: start.minute,
      endHour: end.hour,
      endMinute: end.minute,
      endsNextDay: last.endsOnLaterDay,
    );
  }
}
