import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/providers.dart';
import '../../app/theme/theme.dart';
import '../../core/format.dart';
import '../../domain/app_settings.dart';
import '../../domain/job.dart';
import '../../domain/payout.dart';
import '../../domain/stats.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/widgets.dart';
import '../settings/goal_dialog.dart';
import '../settings/widgets/job_color.dart';

/// The key-figure cards: hours, earned, unpaid, average rate incl. tips and
/// (if any) tips. As many cards per row as fit at the current text size
/// (all in one row on wide windows, two on phones, one at large text).
class StatsGrid extends StatelessWidget {
  /// Creates the grid.
  const StatsGrid({super.key, required this.stats});

  /// The period's figures.
  final PeriodStats stats;

  /// Narrowest comfortable card at 100 % text.
  static const double _minCardWidth = 148;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fmt = Fmt.of(context);
    final colors = context.chronosColors;
    final avg = stats.avgHourlyInclTipsCents;
    final cards = <Widget>[
      StatCard(
        icon: Icons.schedule,
        label: l10n.insightsStatHours,
        value: fmt.hours(stats.workedMs),
        caption: l10n.insightsShiftCount(stats.shiftCount),
      ),
      StatCard(
        icon: Icons.payments_outlined,
        label: l10n.insightsStatEarned,
        value: fmt.money(stats.earnedCents),
      ),
      StatCard(
        icon: Icons.pending_outlined,
        label: l10n.insightsStatOpen,
        value: fmt.money(stats.openCents),
        valueColor: stats.openCents > 0 ? colors.open : null,
      ),
      StatCard(
        icon: Icons.speed,
        label: l10n.insightsStatAverage,
        value: avg == null ? l10n.insightsNoValue : fmt.money(avg),
      ),
      if (stats.tipsCents > 0)
        StatCard(
          icon: Icons.volunteer_activism_outlined,
          label: l10n.insightsStatTips,
          value: fmt.money(stats.tipsCents),
        ),
    ];

    const gap = ChronosSpace.s12;
    final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
    return LayoutBuilder(
      builder: (context, constraints) {
        final fit =
            ((constraints.maxWidth + gap) / (_minCardWidth * scale + gap))
                .floor()
                .clamp(1, cards.length);
        final perRow = fit >= cards.length ? cards.length : fit.clamp(1, 3);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var start = 0; start < cards.length; start += perRow) ...[
              if (start > 0) const SizedBox(height: gap),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (
                      var i = start;
                      i < start + perRow && i < cards.length;
                      i++
                    ) ...[
                      if (i > start) const SizedBox(width: gap),
                      Expanded(child: cards[i]),
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Progress of the current month towards the monthly goal/limit, or a link
/// to set one (nothing while the progress is still loading).
class MonthlyGoalSection extends ConsumerWidget {
  /// Creates the section.
  const MonthlyGoalSection({super.key, required this.goal});

  /// The progress (`null` value = no goal configured).
  final AsyncValue<GoalProgress?> goal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    if (!goal.hasValue) return const SizedBox.shrink();
    final progress = goal.value;
    if (progress == null) {
      return Align(
        alignment: AlignmentDirectional.centerStart,
        child: TextButton.icon(
          onPressed: () => showMonthlyGoalDialog(context),
          icon: const Icon(Icons.flag_outlined),
          label: Text(l10n.insightsGoalSetUp),
        ),
      );
    }
    return MonthlyGoalCard(
      goal: progress,
      month: ref.watch(currentDateProvider).toLocalDateTime(),
    );
  }
}

/// "Monatsgrenze · 438,00 € / 603,00 €" with a coloured progress bar.
class MonthlyGoalCard extends StatelessWidget {
  /// Creates the card.
  const MonthlyGoalCard({super.key, required this.goal, required this.month});

  /// The progress.
  final GoalProgress goal;

  /// A day of the current month (for the caption).
  final DateTime month;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fmt = Fmt.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final isLimit = goal.type == MonthlyGoalType.limit;
    final color = switch (goal.level) {
      GoalLevel.normal => scheme.primary,
      GoalLevel.warning => context.chronosColors.warning,
      GoalLevel.exceeded => scheme.error,
    };
    final title = isLimit ? l10n.insightsLimitTitle : l10n.insightsGoalTitle;
    final progress = l10n.insightsGoalProgress(
      fmt.money(goal.earnedCents),
      fmt.money(goal.targetCents),
    );
    final status = switch ((isLimit, goal.level)) {
      (true, GoalLevel.exceeded) => l10n.insightsLimitExceeded(
        fmt.money(goal.earnedCents - goal.targetCents),
      ),
      (true, GoalLevel.warning) => l10n.insightsLimitWarning(
        fmt.money(goal.remainingCents),
      ),
      (true, _) => l10n.insightsLimitRemaining(fmt.money(goal.remainingCents)),
      (false, _) =>
        goal.reached
            ? l10n.insightsGoalReached
            : l10n.insightsGoalRemaining(fmt.money(goal.remainingCents)),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(ChronosSpace.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(title, style: text.titleMedium),
            ),
            const SizedBox(height: ChronosSpace.s4),
            Text(
              progress,
              style: context.chronosText.statValue.copyWith(
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: ChronosSpace.s12),
            // The amounts and the status line say it all; the bar is visual.
            ExcludeSemantics(
              child: LinearProgressIndicator(
                value: goal.fraction.clamp(0.0, 1.0),
                minHeight: 8,
                color: color,
                borderRadius: ChronosCorners.extraSmall,
              ),
            ),
            const SizedBox(height: ChronosSpace.s8),
            Row(
              children: [
                if (goal.level != GoalLevel.normal) ...[
                  Icon(
                    goal.level == GoalLevel.exceeded
                        ? Icons.error_outline
                        : Icons.warning_amber_outlined,
                    size: 18,
                    color: color,
                  ),
                  const SizedBox(width: ChronosSpace.s8),
                ],
                Expanded(
                  child: Text(
                    status,
                    style: text.bodyMedium?.copyWith(
                      color: goal.level == GoalLevel.normal
                          ? scheme.onSurfaceVariant
                          : color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: ChronosSpace.s4),
            Text(
              l10n.insightsGoalMonth(fmt.monthYear(month)),
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

/// Hours and earnings per job in the period.
class JobBreakdownCard extends StatelessWidget {
  /// Creates the card.
  const JobBreakdownCard({super.key, required this.stats, required this.jobs});

  /// The period's figures.
  final PeriodStats stats;

  /// All jobs (names and colours).
  final List<Job> jobs;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fmt = Fmt.of(context);
    final text = Theme.of(context).textTheme;
    final byId = {for (final j in jobs) j.id: j};
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: ChronosSpace.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: ChronosSpace.s16),
              child: Semantics(
                header: true,
                child: Text(l10n.insightsByJob, style: text.titleMedium),
              ),
            ),
            const SizedBox(height: ChronosSpace.s8),
            for (final entry in stats.perJob)
              MergeSemantics(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ChronosSpace.s16,
                    vertical: ChronosSpace.s8,
                  ),
                  child: Row(
                    children: [
                      JobColorDot(
                        colorArgb:
                            byId[entry.jobId]?.colorArgb ??
                            kDefaultJobColorArgb,
                      ),
                      const SizedBox(width: ChronosSpace.s12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              byId[entry.jobId]?.name ?? '',
                              style: text.bodyLarge,
                            ),
                            Text(
                              l10n.insightsJobLine(
                                fmt.hours(entry.workedMs),
                                fmt.money(entry.earnedCents),
                              ),
                              style: context.chronosText.bodyNumbers.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Payouts received in the period (date, job, received, difference).
/// Hidden while no payout was ever recorded.
class PayoutsSection extends StatelessWidget {
  /// Creates the section.
  const PayoutsSection({
    super.key,
    required this.period,
    required this.jobs,
    required this.all,
  });

  /// The shown period.
  final StatsPeriod period;

  /// All jobs (names).
  final List<Job> jobs;

  /// All payouts (filtered to [period] here).
  final List<Payout> all;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fmt = Fmt.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    if (all.isEmpty) return const SizedBox.shrink();
    final range = period.range;
    final payouts = [
      for (final p in all)
        if (range.contains(p.paidOn)) p,
    ];
    final names = {for (final j in jobs) j.id: j.name};

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: ChronosSpace.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: ChronosSpace.s16),
              child: Semantics(
                header: true,
                child: Text(l10n.insightsPayouts, style: text.titleMedium),
              ),
            ),
            const SizedBox(height: ChronosSpace.s8),
            if (payouts.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: ChronosSpace.s16,
                ),
                child: Text(
                  l10n.insightsPayoutsEmpty,
                  style: text.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            for (final p in payouts)
              MergeSemantics(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ChronosSpace.s16,
                    vertical: ChronosSpace.s8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fmt.dateShort(p.paidOn.toLocalDateTime()),
                              style: text.bodyLarge,
                            ),
                            Text(
                              p.jobId == null
                                  ? l10n.exportAllJobs
                                  : names[p.jobId] ?? '',
                              style: text.bodyMedium?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              switch (p.differenceCents) {
                                0 => l10n.insightsPayoutExact,
                                > 0 => l10n.insightsPayoutMore(
                                  fmt.money(p.differenceCents),
                                ),
                                _ => l10n.insightsPayoutLess(
                                  fmt.money(-p.differenceCents),
                                ),
                              },
                              style: text.bodySmall?.copyWith(
                                color: p.differenceCents < 0
                                    ? scheme.error
                                    : scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: ChronosSpace.s8),
                      Expanded(
                        flex: 2,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerEnd,
                          child: Text(
                            fmt.money(p.receivedCents),
                            style: context.chronosText.amount,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
