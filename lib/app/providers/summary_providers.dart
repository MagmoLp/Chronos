import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/clock.dart';
import '../../core/local_date.dart';
import '../../core/time.dart';
import '../../domain/shift.dart';
import '../../domain/summaries.dart';
import 'async_utils.dart';
import 'core_providers.dart';
import 'shift_providers.dart';

/// Today's local date. Nothing ticks: the UI calls
/// [CurrentDateController.refresh] on app resume (and may call it from its
/// visible ticker); dependants only rebuild when the date really changes.
final currentDateProvider = NotifierProvider<CurrentDateController, LocalDate>(
  CurrentDateController.new,
  name: 'currentDateProvider',
);

/// Holds today's date.
class CurrentDateController extends Notifier<LocalDate> {
  @override
  LocalDate build() => ref.watch(clockProvider).today();

  /// Re-reads the clock; updates only if the date changed.
  void refresh() {
    final today = ref.read(clockProvider).today();
    if (today != state) state = today;
  }
}

/// Finished shifts of the current week (Monday–Sunday).
final _weekShiftsProvider = StreamProvider<List<Shift>>((ref) {
  final today = ref.watch(currentDateProvider);
  return ref
      .watch(shiftRepositoryProvider)
      .watchRange(LocalDateRange.week(today));
}, name: '_weekShiftsProvider');

/// Finished, unpaid shifts.
final _openShiftsProvider = StreamProvider<List<Shift>>(
  (ref) =>
      ref.watch(shiftRepositoryProvider).watchDone(filter: ShiftFilter.open),
  name: '_openShiftsProvider',
);

/// "Heute": today's finished shifts plus the running shift. Live values come
/// from `summary.earnedCentsAt(now)` in the UI's visible ticker.
final todaySummaryProvider = Provider<AsyncValue<TodaySummary>>((ref) {
  final today = ref.watch(currentDateProvider);
  return combineAsync2(
    ref.watch(_weekShiftsProvider),
    ref.watch(runningShiftProvider),
    (List<Shift> week, Shift? running) =>
        computeTodaySummary(today: today, shifts: week, running: running),
  );
}, name: 'todaySummaryProvider');

/// "Diese Woche · 18,5 h · 256,75 €" (running shift available for live
/// values via `earnedCentsAt(now)`).
final weekSummaryProvider = Provider<AsyncValue<PeriodSummary>>((ref) {
  final range = LocalDateRange.week(ref.watch(currentDateProvider));
  return combineAsync2(
    ref.watch(_weekShiftsProvider),
    ref.watch(runningShiftProvider),
    (List<Shift> week, Shift? running) =>
        computePeriodSummary(range, week, running: running),
  );
}, name: 'weekSummaryProvider');

/// "Offen": unpaid wage of finished shifts (+ running shift live via
/// `openCentsAt(now)`).
final openSummaryProvider = Provider<AsyncValue<OpenSummary>>((ref) {
  return combineAsync2(
    ref.watch(_openShiftsProvider),
    ref.watch(runningShiftProvider),
    (List<Shift> open, Shift? running) =>
        computeOpenSummary(open, running: running),
  );
}, name: 'openSummaryProvider');
