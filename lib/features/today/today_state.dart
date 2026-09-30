import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/providers.dart';
import '../../app/theme/theme.dart';
import '../../core/format.dart';
import '../../core/local_date.dart';
import '../../core/time.dart';
import '../../domain/errors.dart';
import '../../domain/job.dart';
import '../../domain/pay.dart';
import '../../domain/shift.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/live_ticker.dart';

// ------------------------------------------------------------- UI state --

/// The job picked with the job chip on Today. Remembered for the app
/// session (not persisted); `null` = follow [defaultJobProvider].
final todaySelectedJobIdProvider = NotifierProvider<TodaySelectedJob, int?>(
  TodaySelectedJob.new,
  name: 'todaySelectedJobIdProvider',
);

/// Holds the job chip selection.
class TodaySelectedJob extends Notifier<int?> {
  @override
  int? build() => null;

  /// Remembers [jobId] for the next "Schicht starten".
  void select(int jobId) => state = jobId;
}

/// The job "Schicht starten" uses: the chip selection while that job is
/// still active, else the default job (last used / first active job).
final todayStartJobProvider = Provider<AsyncValue<Job?>>((ref) {
  final selected = ref.watch(todaySelectedJobIdProvider);
  return combineAsync2(
    ref.watch(activeJobsProvider),
    ref.watch(defaultJobProvider),
    (List<Job> jobs, Job? fallback) {
      for (final job in jobs) {
        if (job.id == selected) return job;
      }
      return fallback;
    },
  );
}, name: 'todayStartJobProvider');

// --------------------------------------------------------- time helpers --

/// Interprets a picked wall-clock [time] as a start that already happened.
///
/// Today at [time] if that is not after [now]; otherwise the same time
/// yesterday, as long as that is at most [lookback] ago (e.g. 23:00 picked
/// at 00:30 means last night). Returns `null` for a start in the future
/// (e.g. 10:30 picked at 10:00).
DateTime? resolvePastStart(
  ClockTime time, {
  required DateTime now,
  Duration lookback = const Duration(hours: 12),
}) {
  final today = LocalDate.ofInstant(now);
  final candidate = combineLocal(today, time.hour, time.minute);
  if (!candidate.isAfter(now)) return candidate;
  final yesterday = combineLocal(today.addDays(-1), time.hour, time.minute);
  if (!yesterday.isAfter(now) && now.difference(yesterday) <= lookback) {
    return yesterday;
  }
  return null;
}

/// Interprets a picked end [time] of the running shift that started at
/// [start]: today at [time] if that is not after [now]; otherwise yesterday
/// at [time] if that is still after [start] (a night shift); otherwise
/// today at [time], which lies in the future (the sheet shows an error).
DateTime resolveFinishEnd(
  ClockTime time, {
  required DateTime start,
  required DateTime now,
}) {
  final today = LocalDate.ofInstant(now);
  final candidate = combineLocal(today, time.hour, time.minute);
  if (!candidate.isAfter(now)) return candidate;
  final yesterday = combineLocal(today.addDays(-1), time.hour, time.minute);
  return yesterday.isAfter(start) ? yesterday : candidate;
}

/// The local wall-clock time of [instant].
ClockTime clockTimeOf(DateTime instant) {
  final local = instant.toLocal();
  return (hour: local.hour, minute: local.minute);
}

// --------------------------------------------------------- tick schedule --

/// When the amount of [running] shows its next cent, on the ticker's
/// timeline: `null` while paused (nothing changes).
///
/// [appClock] is the app's clock (`clockProvider`) the values are computed
/// with; the returned instant is relative to the ticker's own `now`.
NextTickScheduler centTicks(Shift running, Clock appClock) => (tickerNow) {
  if (running.isPaused) return null;
  final worked = liveValues(running, appClock.now()).workedMs;
  final wait = msUntilNextCent(worked, running.rateCentsPerHour);
  return wait == null ? null : tickerNow.add(Duration(milliseconds: wait));
};

/// When the worked-time clock ("3:11:42") of [running] shows its next
/// second; `null` while paused (the clock stands still).
NextTickScheduler secondTicks(Shift running, Clock appClock) => (tickerNow) {
  if (running.isPaused) return null;
  final worked = liveValues(running, appClock.now()).workedMs;
  return tickerNow.add(
    Duration(milliseconds: msPerSecond - worked % msPerSecond),
  );
};

/// While [running] is paused: when the break ("Pause 0:31", rounded to
/// minutes like `Fmt.durationHm`) shows its next minute; else `null`.
NextTickScheduler breakTicks(Shift running, Clock appClock) => (tickerNow) {
  if (!running.isPaused) return null;
  final breakMs = liveValues(running, appClock.now()).breakMs;
  final wait = msPerMinute - (breakMs + msPerMinute ~/ 2) % msPerMinute;
  return tickerNow.add(Duration(milliseconds: wait));
};

// ----------------------------------------------------------- presentation --

/// Colour of [job] in the current theme (stored values are the light
/// palette; they map to the dark palette in dark mode).
Color jobColorOf(BuildContext context, Job job) {
  final colors = ChronosColors.of(context);
  const light = ChronosColors.light;
  for (var i = 0; i < light.jobPalette.length; i++) {
    if (light.jobPalette[i].toARGB32() == job.colorArgb) {
      return colors.jobColor(i);
    }
  }
  return Color(job.colorArgb);
}

/// "Mo 28. Sep, 08:00–16:15" for a finished [shift].
String shiftDateAndTimes(Fmt fmt, Shift shift) {
  final start = shift.startUtc.toLocal();
  final end = (shift.endUtc ?? shift.startUtc).toLocal();
  return '${fmt.dateShort(start)}, ${fmt.timeRange(start, end)}';
}

/// The user-facing message for a refused action, or `null` for
/// [ChronosErrorCode.busy] (a double tap; ignored).
String? todayErrorMessage(AppLocalizations l10n, ChronosException error) =>
    switch (error.code) {
      ChronosErrorCode.busy => null,
      ChronosErrorCode.startInFuture => l10n.todayErrorStartInFuture,
      ChronosErrorCode.shiftAlreadyRunning => l10n.todayErrorAlreadyRunning,
      ChronosErrorCode.noRunningShift => l10n.todayErrorNoRunningShift,
      ChronosErrorCode.noWageRate => l10n.todayErrorNoWage,
      ChronosErrorCode.jobNotFound => l10n.todayErrorJobNotFound,
      ChronosErrorCode.shiftNotFound => l10n.todayErrorShiftNotFound,
      ChronosErrorCode.invalidShift => l10n.todayErrorStartAfterBreak,
      _ => l10n.errorSaveFailed,
    };
