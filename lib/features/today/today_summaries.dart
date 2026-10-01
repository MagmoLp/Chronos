import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/providers.dart';
import '../../app/theme/theme.dart';
import '../../core/format.dart';
import '../../core/time.dart';
import '../../domain/pay.dart';
import '../../domain/shift.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/hint_card.dart';
import '../../widgets/live_ticker.dart';
import '../../widgets/section_header.dart';
import 'today_state.dart';

/// "Offen gesamt" (unless the card already shows the unpaid balance) and,
/// while a shift runs next to other shifts of today, "Davon diese Schicht".
/// Live while a shift runs. Renders nothing when not applicable.
class TodayOpenLines extends ConsumerWidget {
  /// Creates the lines.
  const TodayOpenLines({super.key, this.padding = EdgeInsets.zero});

  /// Space around the lines when they are shown.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todaySummaryProvider).value;
    final open = ref.watch(openSummaryProvider).value;
    if (today == null || open == null || !today.hasWork) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final fmt = Fmt.of(context);
    final appClock = ref.watch(clockProvider);
    final running = today.running;
    final showThisShift = running != null && today.doneCount > 0;
    Widget lines(DateTime now) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        FigureLine(
          key: const ValueKey<String>('today-open-total'),
          label: l10n.todayOpenTotal,
          value: fmt.money(open.openCentsAt(now)),
        ),
        if (showThisShift)
          FigureLine(
            key: const ValueKey<String>('today-this-shift'),
            label: l10n.todayThisShift,
            value: fmt.money(liveValues(running, now).earnedCents),
          ),
      ],
    );
    return Padding(
      padding: padding,
      child: running == null
          ? lines(appClock.now())
          : LiveTicker(
              nextTick: centTicks(running, appClock),
              builder: (context, _) => lines(appClock.now()),
            ),
    );
  }
}

/// A label with a number on the right (wraps below at large text sizes).
class FigureLine extends StatelessWidget {
  /// Creates the line.
  const FigureLine({super.key, required this.label, required this.value});

  /// "Offen gesamt".
  final String label;

  /// "1.282,39 €".
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final chronosText = ChronosTextStyles.of(context);
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: ChronosSpace.s16,
          children: <Widget>[
            Text(
              label,
              style: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
            ),
            Text(
              value,
              style: chronosText.amount.copyWith(color: scheme.onSurface),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Diese Woche · 18,5 h · 256,75 €" and "Letzte Schicht …" (→ editor) as
/// a grouped list.
class TodayWeekAndLastShift extends ConsumerWidget {
  /// Creates the group.
  const TodayWeekAndLastShift({super.key, required this.onOpenShift});

  /// Opens the editor for a shift.
  final ValueChanged<int> onOpenShift;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final week = ref.watch(weekSummaryProvider).value;
    final last = ref.watch(lastShiftProvider).value;
    if (week == null && last == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final fmt = Fmt.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final chronosText = ChronosTextStyles.of(context);
    final appClock = ref.watch(clockProvider);

    Widget? weekRow;
    if (week != null) {
      Widget figures(DateTime now) => Text(
        l10n.todayWeekFigures(
          fmt.hours(week.workedMsAt(now)),
          fmt.money(week.earnedCentsAt(now)),
        ),
        key: const ValueKey<String>('today-week'),
        style: chronosText.bodyNumbers.copyWith(color: scheme.onSurface),
      );
      final running = week.running;
      weekRow = MergeSemantics(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: ChronosLayout.minTapTarget,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: ChronosSpace.s16,
              vertical: ChronosSpace.s12,
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: ChronosSpace.s16,
              children: <Widget>[
                Text(l10n.todayThisWeek, style: text.bodyLarge),
                if (running == null)
                  figures(appClock.now())
                else
                  LiveTicker(
                    nextTick: centTicks(running, appClock),
                    builder: (context, _) => figures(appClock.now()),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    Widget? lastRow;
    if (last != null) {
      lastRow = InkWell(
        key: const ValueKey<String>('today-last-shift'),
        onTap: () => onOpenShift(last.id),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: ChronosLayout.minTapTarget,
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              ChronosSpace.s16,
              ChronosSpace.s8,
              ChronosSpace.s8,
              ChronosSpace.s8,
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(l10n.todayLastShift, style: text.bodyLarge),
                      Text(
                        l10n.todayLastShiftDetails(
                          fmt.dateShort(last.startUtc.toLocal()),
                          fmt.timeRange(
                            last.startUtc.toLocal(),
                            (last.endUtc ?? last.startUtc).toLocal(),
                          ),
                          fmt.durationHm(last.workedMs),
                        ),
                        style: chronosText.bodyNumbers.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: ChronosSpace.s8),
                Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      );
    }

    return Material(
      color: scheme.surfaceContainerLow,
      shape: const RoundedRectangleBorder(borderRadius: ChronosCorners.large),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ?weekRow,
          if (weekRow != null && lastRow != null) const Divider(indent: 16),
          ?lastRow,
        ],
      ),
    );
  }
}

/// Hint cards shown only when they apply: migrated entries to review and
/// switched-off notifications.
class TodayHints extends ConsumerWidget {
  /// Creates the hints.
  const TodayHints({
    super.key,
    required this.notificationsOff,
    required this.onReview,
    required this.onOpenNotificationSettings,
  });

  /// Whether the notification permission is known to be denied.
  final bool notificationsOff;

  /// Opens the review list.
  final VoidCallback onReview;

  /// Opens the system notification settings.
  final VoidCallback onOpenNotificationSettings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final reviewCount = ref.watch(reviewItemsProvider).value?.length ?? 0;
    final cards = <Widget>[
      if (reviewCount > 0)
        HintCard(
          key: const ValueKey<String>('today-review-hint'),
          icon: Icons.fact_check_outlined,
          message: l10n.todayReviewHint(reviewCount),
          actionLabel: l10n.todayReviewAction,
          onAction: onReview,
        ),
      if (notificationsOff)
        HintCard(
          key: const ValueKey<String>('today-notifications-hint'),
          icon: Icons.notifications_off_outlined,
          tone: HintTone.warning,
          message: l10n.todayNotificationsOff,
          actionLabel: l10n.commonOpenSettings,
          onAction: onOpenNotificationSettings,
        ),
    ];
    if (cards.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final card in cards)
          Padding(
            padding: const EdgeInsets.only(bottom: ChronosSpace.s12),
            child: card,
          ),
      ],
    );
  }
}

/// Side pane on expanded windows: today's finished shifts (→ editor).
class TodayShiftsPane extends ConsumerWidget {
  /// Creates the pane.
  const TodayShiftsPane({super.key, required this.onOpenShift});

  /// Opens the editor for a shift.
  final ValueChanged<int> onOpenShift;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final fmt = Fmt.of(context);
    final scheme = Theme.of(context).colorScheme;
    final chronosText = ChronosTextStyles.of(context);
    final date = ref.watch(currentDateProvider);
    final shifts =
        ref.watch(shiftsInRangeProvider(LocalDateRange.day(date))).value ??
        const <Shift>[];
    return Material(
      key: const ValueKey<String>('today-shifts-pane'),
      color: scheme.surfaceContainerLow,
      shape: const RoundedRectangleBorder(borderRadius: ChronosCorners.large),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SectionHeader(l10n.todayShiftsTodayTitle),
          if (shifts.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                ChronosSpace.s16,
                0,
                ChronosSpace.s16,
                ChronosSpace.s16,
              ),
              child: Text(
                l10n.todayNoShiftsToday,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            )
          else
            for (final shift in shifts)
              ListTile(
                onTap: () => onOpenShift(shift.id),
                title: Text(
                  fmt.timeRange(
                    shift.startUtc.toLocal(),
                    (shift.endUtc ?? shift.startUtc).toLocal(),
                  ),
                  style: chronosText.bodyNumbers.copyWith(
                    color: scheme.onSurface,
                  ),
                ),
                subtitle: Text(fmt.durationHm(shift.workedMs)),
                trailing: Text(
                  fmt.money(shift.earnedCents),
                  style: chronosText.amount.copyWith(color: scheme.onSurface),
                ),
              ),
        ],
      ),
    );
  }
}
