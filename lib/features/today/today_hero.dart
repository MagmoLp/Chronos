import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/providers.dart';
import '../../app/theme/theme.dart';
import '../../core/format.dart';
import '../../domain/job.dart';
import '../../domain/pay.dart';
import '../../domain/shift.dart';
import '../../domain/summaries.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/live_ticker.dart';
import '../../widgets/rolling_amount.dart';
import 'today_state.dart';

/// The big card on Today: live pay of the running shift, today's pay, or
/// the unpaid balance when nothing was worked today.
///
/// Only the numbers inside [LiveTicker]s rebuild while a shift runs: the
/// amount when the next cent is earned (at most 4×/s), the stopwatch once
/// per second, the break once per minute while paused.
class TodayHeroCard extends ConsumerWidget {
  /// Creates the card.
  const TodayHeroCard({
    super.key,
    required this.onAdjustStart,
    required this.onRecordPayout,
    this.large = false,
    this.dense = false,
  });

  /// "seit 08:02" was tapped (change the start of the running shift).
  final VoidCallback onAdjustStart;

  /// "Auszahlung erfassen" was tapped.
  final VoidCallback onRecordPayout;

  /// Expanded windows: the 72 sp amount.
  final bool large;

  /// Compact height (phone landscape): tighter padding.
  final bool dense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todaySummaryProvider);
    final open = ref.watch(openSummaryProvider);
    final jobs = ref.watch(jobsProvider).value ?? const <Job>[];
    final colors = ChronosColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    final animate = !(MediaQuery.maybeDisableAnimationsOf(context) ?? false);
    final duration = animate ? ChronosMotion.medium : Duration.zero;

    final running = today.value?.running;
    final Widget content;
    final Object stateKey;
    if (today.hasError || open.hasError) {
      stateKey = 'error';
      content = Text(
        AppLocalizations.of(context).errorLoadFailed,
        style: Theme.of(context).textTheme.bodyLarge,
      );
    } else if (!today.hasValue || !open.hasValue) {
      stateKey = 'loading';
      content = const SizedBox(height: ChronosLayout.listRow3);
    } else if (running != null) {
      stateKey = 'running';
      Job? job;
      for (final j in jobs) {
        if (j.id == running.jobId) job = j;
      }
      final activeJobCount = jobs.where((j) => !j.archived).length;
      content = _RunningContent(
        today: today.requireValue,
        shift: running,
        jobName: activeJobCount > 1 ? job?.name : null,
        large: large,
        onAdjustStart: onAdjustStart,
      );
    } else if (today.requireValue.hasWork) {
      stateKey = 'today';
      content = _EarnedTodayContent(today: today.requireValue);
    } else {
      stateKey = 'open';
      content = _OpenContent(
        open: open.requireValue,
        onRecordPayout: onRecordPayout,
      );
    }

    final padding = dense ? ChronosSpace.s16 : ChronosSpace.s24;
    return AnimatedContainer(
      duration: duration,
      curve: ChronosMotion.standard,
      decoration: ShapeDecoration(
        color: running != null ? colors.liveContainer : scheme.surfaceContainer,
        shape: const RoundedRectangleBorder(
          borderRadius: ChronosCorners.extraLarge,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: AnimatedSize(
          duration: duration,
          curve: ChronosMotion.standard,
          alignment: AlignmentDirectional.topStart,
          child: AnimatedSwitcher(
            duration: duration,
            layoutBuilder: (current, previous) => Stack(
              alignment: AlignmentDirectional.topStart,
              children: <Widget>[...previous, ?current],
            ),
            child: Padding(
              key: ValueKey<Object>(stateKey),
              padding: EdgeInsets.all(padding),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}

/// Running (or paused) shift: status, today's pay live, stopwatch, start,
/// rate and break.
class _RunningContent extends ConsumerWidget {
  const _RunningContent({
    required this.today,
    required this.shift,
    required this.jobName,
    required this.large,
    required this.onAdjustStart,
  });

  final TodaySummary today;
  final Shift shift;
  final String? jobName;
  final bool large;
  final VoidCallback onAdjustStart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final fmt = Fmt.of(context);
    final text = Theme.of(context).textTheme;
    final chronosText = ChronosTextStyles.of(context);
    final colors = ChronosColors.of(context);
    final onLive = colors.onLive;
    final appClock = ref.watch(clockProvider);

    final status = shift.isPaused
        ? l10n.todayPausedSince(fmt.time(shift.pausedAtUtc!.toLocal()))
        : l10n.statusRunning;
    final header = jobName == null
        ? status
        : l10n.todayStatusWithJob(status, jobName!);
    final amountStyle =
        (large ? chronosText.moneyHeroLarge : chronosText.moneyHero).copyWith(
          color: onLive,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(
              shift.isPaused ? Icons.pause_circle_outline : Icons.circle,
              size: shift.isPaused ? 20 : 12,
              color: colors.liveIndicator,
            ),
            const SizedBox(width: ChronosSpace.s8),
            Expanded(
              child: Text(
                header,
                style: text.labelLarge?.copyWith(color: onLive),
              ),
            ),
          ],
        ),
        const SizedBox(height: ChronosSpace.s12),
        LiveTicker(
          nextTick: centTicks(shift, appClock),
          builder: (context, _) {
            final cents = today.earnedCentsAt(appClock.now());
            // Label and amount are read together.
            return Semantics(
              container: true,
              label: '${l10n.todayEarnedToday}\n${fmt.money(cents)}',
              excludeSemantics: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    l10n.todayEarnedToday,
                    style: text.titleSmall?.copyWith(color: onLive),
                  ),
                  RollingAmount.cents(
                    cents,
                    style: amountStyle,
                    fractionScale: 0.6,
                    alignment: AlignmentDirectional.centerStart,
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: ChronosSpace.s4),
        Wrap(
          spacing: ChronosSpace.s8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            LiveTicker(
              nextTick: secondTicks(shift, appClock),
              builder: (context, _) {
                final worked = liveValues(shift, appClock.now()).workedMs;
                return Semantics(
                  label: l10n.todayWorkedSemantics(fmt.durationSpoken(worked)),
                  child: ExcludeSemantics(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        fmt.durationClock(worked),
                        key: const ValueKey<String>('today-worked'),
                        style: chronosText.timer.copyWith(color: onLive),
                        maxLines: 1,
                      ),
                    ),
                  ),
                );
              },
            ),
            Tooltip(
              message: l10n.todayAdjustStart,
              child: TextButton.icon(
                onPressed: onAdjustStart,
                style: TextButton.styleFrom(foregroundColor: onLive),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: Text(
                  l10n.todaySince(fmt.time(shift.startUtc.toLocal())),
                ),
              ),
            ),
          ],
        ),
        LiveTicker(
          nextTick: breakTicks(shift, appClock),
          builder: (context, _) {
            final breakMs = liveValues(shift, appClock.now()).breakMs;
            final parts = <String>[
              fmt.rate(shift.rateCentsPerHour),
              if (breakMs > 0)
                l10n.todayBreak(fmt.durationHm(breakMs, unit: false)),
            ];
            return Text(
              parts.join(' · '),
              key: const ValueKey<String>('today-rate'),
              style: chronosText.bodyNumbers.copyWith(color: onLive),
            );
          },
        ),
      ],
    );
  }
}

/// No shift runs, but something was worked today.
class _EarnedTodayContent extends StatelessWidget {
  const _EarnedTodayContent({required this.today});

  final TodaySummary today;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fmt = Fmt.of(context);
    return _StaticHero(
      label: l10n.todayEarnedToday,
      cents: today.doneEarnedCents,
      caption: l10n.todayShiftsHours(
        today.doneCount,
        fmt.durationHm(today.doneWorkedMs),
      ),
    );
  }
}

/// Nothing worked today: the unpaid balance with "Auszahlung erfassen".
class _OpenContent extends StatelessWidget {
  const _OpenContent({required this.open, required this.onRecordPayout});

  final OpenSummary open;
  final VoidCallback onRecordPayout;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fmt = Fmt.of(context);
    final hasOpen = open.shiftCount > 0;
    return _StaticHero(
      label: l10n.todayOpenLabel,
      cents: open.openCents,
      caption: hasOpen
          ? l10n.todayShiftsHours(open.shiftCount, fmt.hours(open.workedMs))
          : l10n.todayNothingOpen,
      action: hasOpen
          ? TextButton.icon(
              onPressed: onRecordPayout,
              icon: const Icon(Icons.payments_outlined),
              label: Text(l10n.todayRecordPayout),
            )
          : null,
    );
  }
}

class _StaticHero extends StatelessWidget {
  const _StaticHero({
    required this.label,
    required this.cents,
    required this.caption,
    this.action,
  });

  final String label;
  final int cents;
  final String caption;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final chronosText = ChronosTextStyles.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Semantics(
          container: true,
          label: '$label\n${Fmt.of(context).money(cents)}\n$caption',
          excludeSemantics: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                label,
                style: text.titleSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              RollingAmount.cents(
                cents,
                style: chronosText.amountLarge.copyWith(
                  color: scheme.onSurface,
                ),
                alignment: AlignmentDirectional.centerStart,
              ),
              const SizedBox(height: ChronosSpace.s4),
              Text(
                caption,
                style: chronosText.bodyNumbers.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (action != null)
          Align(alignment: AlignmentDirectional.centerEnd, child: action),
      ],
    );
  }
}
