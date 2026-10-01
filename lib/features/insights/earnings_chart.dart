import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../app/theme/theme.dart';
import '../../core/format.dart';
import '../../domain/stats.dart';
import '../../l10n/app_localizations.dart';

/// Card with the earnings bar chart of a period: 7 days (week), the days of
/// the month, or 12 months (year).
///
/// Tapping a bar shows its amount and hours below the title. For screen
/// readers every bar is a separate node ("Mittwoch, 30. September 2026:
/// 116,25 €, 7 Stunden 45 Minuten"), so the chart can be explored by touch.
class EarningsChartCard extends StatefulWidget {
  /// Creates the card.
  const EarningsChartCard({super.key, required this.stats});

  /// The period's figures.
  final PeriodStats stats;

  @override
  State<EarningsChartCard> createState() => _EarningsChartCardState();
}

class _EarningsChartCardState extends State<EarningsChartCard> {
  int? _selected;

  bool get _isYear => widget.stats.period.kind == StatsPeriodKind.year;

  /// Short label of a bucket for the caption ("Mi 30. Sep" / "Sep 2026").
  String _shortLabel(Fmt fmt, StatsBucket b) {
    final start = b.start.toLocalDateTime();
    return _isYear ? fmt.monthYear(start) : fmt.dateShort(start);
  }

  /// Spoken label of a bucket ("Mittwoch, 30. September 2026").
  String _longLabel(Fmt fmt, StatsBucket b) {
    final start = b.start.toLocalDateTime();
    return _isYear ? fmt.monthYear(start) : fmt.dateLong(start);
  }

  /// Axis label under a bar ("Mo", "30", "Sep").
  String _axisLabel(Fmt fmt, StatsBucket b) {
    final start = b.start.toLocalDateTime();
    return switch (widget.stats.period.kind) {
      StatsPeriodKind.week => fmt.weekdayShort(start),
      StatsPeriodKind.month => fmt.dayOfMonth(start),
      StatsPeriodKind.year => fmt.monthShort(start),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fmt = Fmt.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final stats = widget.stats;
    final selected = _selected;

    final caption = selected == null
        ? l10n.insightsChartHint
        : l10n.insightsChartSelection(
            _shortLabel(fmt, stats.buckets[selected]),
            fmt.money(stats.buckets[selected].earnedCents),
            fmt.durationHm(stats.buckets[selected].workedMs),
          );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(ChronosSpace.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                _isYear ? l10n.insightsChartMonths : l10n.insightsChartDays,
                style: text.titleMedium,
              ),
            ),
            const SizedBox(height: ChronosSpace.s4),
            if (!stats.isEmpty)
              Semantics(
                liveRegion: selected != null,
                child: Text(
                  caption,
                  style:
                      (selected == null
                              ? text.bodySmall
                              : context.chronosText.bodyNumbers)
                          ?.copyWith(
                            color: selected == null
                                ? scheme.onSurfaceVariant
                                : scheme.onSurface,
                          ),
                ),
              ),
            const SizedBox(height: ChronosSpace.s16),
            if (stats.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: ChronosSpace.s24),
                child: Row(
                  children: [
                    Icon(Icons.bar_chart, color: scheme.onSurfaceVariant),
                    const SizedBox(width: ChronosSpace.s12),
                    Expanded(
                      child: Text(
                        l10n.insightsChartEmpty,
                        style: text.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              _BarChart(
                buckets: stats.buckets,
                selected: selected,
                axisLabel: (b) => _axisLabel(fmt, b),
                semanticLabel: (b) => l10n.insightsChartBar(
                  _longLabel(fmt, b),
                  fmt.money(b.earnedCents),
                  fmt.durationSpoken(b.workedMs),
                ),
                onSelect: (i) => setState(() => _selected = i),
              ),
          ],
        ),
      ),
    );
  }
}

class _BarChart extends StatelessWidget {
  const _BarChart({
    required this.buckets,
    required this.selected,
    required this.axisLabel,
    required this.semanticLabel,
    required this.onSelect,
  });

  final List<StatsBucket> buckets;
  final int? selected;
  final String Function(StatsBucket) axisLabel;
  final String Function(StatsBucket) semanticLabel;
  final ValueChanged<int> onSelect;

  /// A "nice" axis step (1, 2 or 5 × 10ⁿ euros) for about four grid lines.
  static int _niceStep(int maxEuros) {
    if (maxEuros <= 0) return 10;
    final raw = maxEuros / 4;
    final exponent = (math.log(raw) / math.ln10).floor();
    final int magnitude = exponent <= 0 ? 1 : math.pow(10, exponent).toInt();
    for (final factor in const <int>[1, 2, 5]) {
      final step = factor * magnitude;
      if (step >= raw) return step;
    }
    return 10 * magnitude;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fmt = Fmt.of(context);
    final scheme = Theme.of(context).colorScheme;
    final labelStyle = context.chronosText.smallNumbers.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    final animate = !MediaQuery.disableAnimationsOf(context);

    final maxCents = buckets.fold<int>(0, (m, b) => math.max(m, b.earnedCents));
    final step = _niceStep((maxCents + 99) ~/ 100);
    final maxEuros = math.max(step, ((maxCents / 100) / step).ceil() * step);

    Size measure(String s) {
      final painter = TextPainter(
        text: TextSpan(text: s, style: labelStyle),
        textDirection: direction,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      final size = painter.size;
      painter.dispose();
      return size;
    }

    String euroLabel(num value) =>
        l10n.insightsAxisEuros(fmt.integer(value.round()));
    final leftReserved = measure(euroLabel(maxEuros)).width + ChronosSpace.s8;
    var widest = 0.0;
    var labelHeight = 0.0;
    for (final b in buckets) {
      final size = measure(axisLabel(b));
      widest = math.max(widest, size.width);
      labelHeight = math.max(labelHeight, size.height);
    }
    final bottomReserved = labelHeight + ChronosSpace.s8;

    return LayoutBuilder(
      builder: (context, constraints) {
        final plotWidth = math.max(1.0, constraints.maxWidth - leftReserved);
        final slot = plotWidth / buckets.length;
        final stride = math.max(1, ((widest + ChronosSpace.s4) / slot).ceil());
        final barWidth = (slot * 0.6).clamp(2.0, 28.0);
        final height = math.max(160.0, 120 + bottomReserved + labelHeight * 2);

        final data = BarChartData(
          alignment: BarChartAlignment.spaceAround,
          minY: 0,
          maxY: maxEuros.toDouble(),
          barTouchData: const BarTouchData(enabled: false),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            drawVerticalLine: false,
            horizontalInterval: step.toDouble(),
            getDrawingHorizontalLine: (_) =>
                FlLine(color: scheme.outlineVariant, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: leftReserved,
                interval: step.toDouble(),
                getTitlesWidget: (value, meta) => SideTitleWidget(
                  meta: meta,
                  space: ChronosSpace.s4,
                  fitInside: SideTitleFitInsideData.fromTitleMeta(meta),
                  child: Text(euroLabel(value), style: labelStyle),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: bottomReserved,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= buckets.length || i % stride != 0) {
                    return const SizedBox.shrink();
                  }
                  return SideTitleWidget(
                    meta: meta,
                    space: ChronosSpace.s4,
                    child: Text(
                      axisLabel(buckets[i]),
                      style: i == selected
                          ? labelStyle.copyWith(
                              color: scheme.onSurface,
                              fontWeight: FontWeight.w600,
                            )
                          : labelStyle,
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < buckets.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: buckets[i].earnedCents / 100,
                    width: barWidth,
                    color: selected == null || selected == i
                        ? scheme.primary
                        : scheme.primary.withValues(alpha: 0.45),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(ChronosRadius.extraSmall),
                    ),
                  ),
                ],
              ),
          ],
        );

        return SizedBox(
          height: height,
          child: Stack(
            children: [
              Positioned.fill(
                child: ExcludeSemantics(
                  child: BarChart(
                    data,
                    duration: animate ? ChronosMotion.short : Duration.zero,
                  ),
                ),
              ),
              // Tap target and per-bar screen-reader nodes over the plot.
              Positioned(
                left: leftReserved,
                right: 0,
                top: 0,
                bottom: bottomReserved,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  excludeFromSemantics: true,
                  onTapUp: (details) => onSelect(
                    (details.localPosition.dx / slot).floor().clamp(
                      0,
                      buckets.length - 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      for (var i = 0; i < buckets.length; i++)
                        Expanded(
                          child: Semantics(
                            container: true,
                            label: semanticLabel(buckets[i]),
                            selected: i == selected ? true : null,
                            child: const SizedBox.expand(),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
