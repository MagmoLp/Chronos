import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/providers.dart';
import '../../app/shell.dart';
import '../../app/theme/theme.dart';
import '../../core/format.dart';
import '../../core/local_date.dart';
import '../../domain/job.dart';
import '../../domain/payout.dart';
import '../../domain/stats.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/widgets.dart';
import '../export/export_sheet.dart';
import '../settings/settings_page.dart';
import '../settings/widgets/choice_segments.dart';
import 'earnings_chart.dart';
import 'insights_sections.dart';

/// The "Übersicht" tab: key figures, chart, monthly goal, per-job totals
/// and payouts of a week, month or year.
class InsightsPage extends ConsumerStatefulWidget {
  /// Creates the page.
  const InsightsPage({super.key});

  @override
  ConsumerState<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends ConsumerState<InsightsPage> {
  /// The shown period; `null` = the current month (follows the date).
  StatsPeriod? _period;

  /// Last loaded figures, shown while the next period loads (no flicker).
  PeriodStats? _lastStats;

  StatsPeriod _current(LocalDate today) => _period ?? StatsPeriod.month(today);

  void _setKind(StatsPeriodKind kind, LocalDate today) {
    final current = _current(today);
    if (kind == current.kind) return;
    // Keep today in view when the current period is shown, else stay near
    // the viewed period.
    final anchor = current.isCurrent(today) ? today : current.start;
    setState(() => _period = StatsPeriod(kind, anchor));
  }

  void _step(StatsPeriod next) => setState(() => _period = next);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final today = ref.watch(currentDateProvider);
    final period = _current(today);
    final statsValue = ref.watch(statsProvider(period));
    final stats = statsValue.value;
    if (stats != null) _lastStats = stats;
    final shown = stats ?? _lastStats;
    final jobs = ref.watch(jobsProvider).value ?? const <Job>[];
    // Watched here (not in the sections further down) so they are loaded
    // before their rows scroll into view and the list does not jump.
    final goalValue = ref.watch(monthlyGoalProvider);
    final payoutsValue = ref.watch(payoutsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navInsights),
        actions: [ShellSettingsButton(onPressed: () => openSettings(context))],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final padding = ResponsiveCenter.horizontalPaddingFor(
            constraints.maxWidth,
          );
          final content = constraints.maxWidth - 2 * padding;
          final wide = content >= 560;
          final twoPane = content >= 720;
          final safe = MediaQuery.paddingOf(context);

          final header = PeriodHeader(
            period: period,
            today: today,
            wide: wide,
            onKind: (kind) => _setKind(kind, today),
            onStep: _step,
          );

          if (shown == null) {
            return ListView(
              padding: EdgeInsets.fromLTRB(
                padding,
                ChronosSpace.s8,
                padding,
                ChronosSpace.s24 + safe.bottom,
              ),
              children: [
                header,
                const SizedBox(height: ChronosSpace.s48),
                if (statsValue.hasError)
                  EmptyState(
                    icon: Icons.error_outline,
                    title: l10n.errorLoadFailed,
                  )
                else
                  const Center(child: CircularProgressIndicator()),
              ],
            );
          }

          final chart = EarningsChartCard(
            key: ValueKey(shown.period),
            stats: shown,
          );
          final goal = MonthlyGoalSection(goal: goalValue);
          final byJob = jobs.length > 1 && shown.perJob.isNotEmpty
              ? JobBreakdownCard(stats: shown, jobs: jobs)
              : null;
          final payouts = PayoutsSection(
            period: shown.period,
            jobs: jobs,
            all: payoutsValue.value ?? const <Payout>[],
          );

          const gap = SizedBox(height: ChronosSpace.s16);
          return ListView(
            padding: EdgeInsets.fromLTRB(
              padding,
              ChronosSpace.s8,
              padding,
              ChronosSpace.s24 + safe.bottom,
            ),
            children: [
              header,
              if (statsValue.isLoading)
                const LinearProgressIndicator(minHeight: 2)
              else
                const SizedBox(height: 2),
              const SizedBox(height: ChronosSpace.s12),
              StatsGrid(stats: shown),
              gap,
              if (twoPane)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: chart),
                    const SizedBox(width: ChronosSpace.s16),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          goal,
                          if (byJob != null) ...[gap, byJob],
                        ],
                      ),
                    ),
                  ],
                )
              else ...[
                chart,
                gap,
                goal,
                if (byJob != null) ...[gap, byJob],
              ],
              gap,
              payouts,
              const SizedBox(height: ChronosSpace.s24),
              Align(
                alignment: wide
                    ? AlignmentDirectional.centerStart
                    : AlignmentDirectional.center,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      showExportSheet(context, range: shown.period.range),
                  icon: const Icon(Icons.ios_share),
                  label: Text(l10n.insightsExport),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Week/Month/Year switch and the "‹ September 2026 ›" stepper.
class PeriodHeader extends StatelessWidget {
  /// Creates the header.
  const PeriodHeader({
    super.key,
    required this.period,
    required this.today,
    required this.wide,
    required this.onKind,
    required this.onStep,
  });

  /// The shown period.
  final StatsPeriod period;

  /// Today (no stepping past the current period).
  final LocalDate today;

  /// Whether switch and stepper share one row.
  final bool wide;

  /// Called with the chosen period length.
  final ValueChanged<StatsPeriodKind> onKind;

  /// Called with the previous/next period.
  final ValueChanged<StatsPeriod> onStep;

  /// "September 2026", "2026" or "28. Sep – 4. Okt 2026".
  static String title(Fmt fmt, AppLocalizations l10n, StatsPeriod period) {
    final start = period.start.toLocalDateTime();
    return switch (period.kind) {
      StatsPeriodKind.week => l10n.insightsWeekTitle(
        fmt.dayMonth(start),
        fmt.dayMonth(period.range.endInclusive.toLocalDateTime()),
        fmt.year(period.range.endInclusive.toLocalDateTime()),
      ),
      StatsPeriodKind.month => fmt.monthYear(start),
      StatsPeriodKind.year => fmt.year(start),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fmt = Fmt.of(context);
    final text = Theme.of(context).textTheme;
    final canNext = period.canGoNext(today);

    final labels = [
      l10n.insightsPeriodWeek,
      l10n.insightsPeriodMonth,
      l10n.insightsPeriodYear,
    ];
    Widget kinds({required bool expand}) => Semantics(
      label: l10n.insightsPeriodChoice,
      container: true,
      child: ChoiceSegments<StatsPeriodKind>(
        expand: expand,
        segments: [
          for (final (i, kind) in StatsPeriodKind.values.indexed)
            ChoiceSegment(value: kind, label: labels[i]),
        ],
        selected: period.kind,
        onChanged: onKind,
      ),
    );

    final stepper = Row(
      children: [
        IconButton(
          onPressed: () => onStep(period.previous),
          tooltip: l10n.insightsPrevious,
          icon: const Icon(Icons.chevron_left),
        ),
        Expanded(
          child: Semantics(
            liveRegion: true,
            child: Text(
              title(fmt, l10n, period),
              textAlign: TextAlign.center,
              style: text.titleMedium,
            ),
          ),
        ),
        IconButton(
          onPressed: canNext ? () => onStep(period.next) : null,
          tooltip: l10n.insightsNext,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final oneRow =
            wide &&
            ChoiceSegments.labelsFit(
              context,
              labels,
              constraints.maxWidth * 0.55,
            );
        if (oneRow) {
          return Row(
            children: [
              Expanded(flex: 11, child: kinds(expand: true)),
              const SizedBox(width: ChronosSpace.s16),
              Expanded(flex: 9, child: stepper),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            kinds(expand: true),
            const SizedBox(height: ChronosSpace.s8),
            stepper,
          ],
        );
      },
    );
  }
}
