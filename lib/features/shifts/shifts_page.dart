import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/providers.dart';
import '../../app/shell.dart';
import '../../app/theme/theme.dart';
import '../../core/format.dart';
import '../../core/local_date.dart';
import '../../domain/job.dart';
import '../../domain/shift.dart';
import '../../domain/summaries.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/responsive_center.dart';
import '../../widgets/section_header.dart';
import '../export/export_sheet.dart';
import '../settings/settings_page.dart';
import 'payout_sheet.dart';
import 'shift_actions.dart';
import 'shift_editor.dart';
import 'shift_row.dart';
import 'shift_texts.dart';

/// Keys for tests and integration.
abstract final class ShiftsPageKeys {
  /// The overflow menu button.
  static const Key menu = Key('shifts-menu');

  /// The add-shift floating action button.
  static const Key fab = Key('shifts-fab');

  /// The running-shift tile.
  static const Key runningTile = Key('shifts-running');

  /// Filter chip for [filter].
  static Key filter(ShiftFilter filter) => Key('shifts-filter-${filter.name}');

  /// Month header of [year]/[month].
  static Key monthHeader(int year, int month) =>
      Key('shifts-month-$year-$month');
}

enum _MenuAction { payout, export }

/// The "Schichten" tab: finished shifts by month with filters, the running
/// shift on top, swipe/long-press actions and the add button.
///
/// Brings its own [ScaffoldMessenger], so undo snackbars stay on this tab.
class ShiftsPage extends StatelessWidget {
  /// Creates the page.
  const ShiftsPage({super.key});

  @override
  Widget build(BuildContext context) =>
      const ScaffoldMessenger(child: _ShiftsView());
}

class _ShiftsView extends ConsumerStatefulWidget {
  const _ShiftsView();

  @override
  ConsumerState<_ShiftsView> createState() => _ShiftsViewState();
}

class _ShiftsViewState extends ConsumerState<_ShiftsView> {
  ShiftFilter _filter = ShiftFilter.all;

  /// Rows swiped away whose deletion the list stream may not show yet.
  final Set<int> _dismissed = <int>{};

  /// Last groups shown, kept while another filter loads (no flicker).
  List<ShiftMonthGroup>? _lastGroups;

  void _edit(Shift shift) =>
      unawaited(showShiftEditor(context, shiftId: shift.id));

  void _add() => unawaited(showShiftEditor(context));

  void _duplicate(Shift shift) =>
      unawaited(duplicateShiftAndEdit(context, shift.id));

  void _togglePaid(Shift shift) =>
      unawaited(togglePaidWithUndo(context, shift.id));

  Future<bool> _delete(Shift shift) => deleteShiftWithUndo(
    context,
    shift.id,
    onRestored: () {
      if (mounted) setState(() => _dismissed.remove(shift.id));
    },
  );

  void _onMenu(_MenuAction action) {
    switch (action) {
      case _MenuAction.payout:
        unawaited(showPayoutSheet(context));
      case _MenuAction.export:
        unawaited(showExportSheet(context));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final groupsAsync = ref.watch(shiftMonthGroupsProvider(_filter));
    final running = ref.watch(runningShiftWithJobProvider).value;
    final jobs = ref.watch(jobsProvider).value ?? const <Job>[];
    final today = ref.watch(currentDateProvider);
    final showJobs = jobs.length > 1;
    final jobNames = <int, String>{for (final j in jobs) j.id: j.name};

    final groups = groupsAsync.value ?? _lastGroups;
    if (groupsAsync.hasValue) _lastGroups = groupsAsync.value;
    final visible = <ShiftMonthGroup>[
      if (groups != null)
        for (final g in groups)
          if (g.shifts.any((s) => !_dismissed.contains(s.id))) g,
    ];
    final showRunning = running != null && _filter != ShiftFilter.paid;
    final empty =
        groups != null &&
        visible.isEmpty &&
        !(showRunning && _filter == ShiftFilter.all);
    // The empty "Alle" state has its own add button.
    final showFab = !(empty && _filter == ShiftFilter.all);

    final slivers = <Widget>[
      SliverResponsiveCenter(
        applyMargin: false,
        sliver: SliverToBoxAdapter(child: _filterBar(context)),
      ),
      if (showRunning)
        SliverResponsiveCenter(
          sliver: SliverToBoxAdapter(
            child: _RunningTile(
              shift: running.shift,
              jobName: showJobs ? running.job?.name : null,
            ),
          ),
        ),
      if (groups == null && groupsAsync.hasError)
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyState(
            icon: Icons.error_outline,
            title: l10n.errorLoadFailed,
          ),
        )
      else if (groups == null)
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator()),
        )
      else if (empty)
        SliverFillRemaining(hasScrollBody: false, child: _emptyState(context))
      else ...<Widget>[
        for (final group in visible)
          SliverResponsiveCenter(
            applyMargin: false,
            sliver: _monthGroup(
              context,
              group,
              jobNames: showJobs ? jobNames : null,
              today: today,
            ),
          ),
        // Room for the floating action button.
        const SliverToBoxAdapter(
          child: SizedBox(height: ChronosSpace.s48 + ChronosSpace.s48),
        ),
      ],
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navShifts),
        actions: <Widget>[
          PopupMenuButton<_MenuAction>(
            key: ShiftsPageKeys.menu,
            tooltip: l10n.commonMoreOptions,
            onSelected: _onMenu,
            itemBuilder: (context) => <PopupMenuEntry<_MenuAction>>[
              _menuItem(
                _MenuAction.payout,
                Icons.payments_outlined,
                l10n.payoutTitle,
              ),
              _menuItem(_MenuAction.export, Icons.ios_share, l10n.commonExport),
            ],
          ),
          ShellSettingsButton(
            onPressed: () => unawaited(openSettings(context)),
          ),
        ],
      ),
      floatingActionButton: showFab
          ? FloatingActionButton.extended(
              key: ShiftsPageKeys.fab,
              onPressed: _add,
              tooltip: l10n.shiftsAddShiftTooltip,
              icon: const Icon(Icons.add),
              label: Text(l10n.shiftsAddShift),
            )
          : null,
      body: CustomScrollView(slivers: slivers),
    );
  }

  PopupMenuItem<_MenuAction> _menuItem(
    _MenuAction value,
    IconData icon,
    String label,
  ) => PopupMenuItem<_MenuAction>(
    value: value,
    child: Row(
      children: <Widget>[
        Icon(icon),
        const SizedBox(width: ChronosSpace.s12),
        Flexible(child: Text(label)),
      ],
    ),
  );

  Widget _filterBar(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    String label(ShiftFilter f) => switch (f) {
      ShiftFilter.all => l10n.commonAll,
      ShiftFilter.open => l10n.statusOpen,
      ShiftFilter.paid => l10n.statusPaid,
    };
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        ChronosSpace.s16,
        ChronosSpace.s4,
        ChronosSpace.s16,
        ChronosSpace.s4,
      ),
      child: Semantics(
        container: true,
        label: l10n.shiftsFilterLabel,
        child: Wrap(
          spacing: ChronosSpace.s8,
          children: <Widget>[
            for (final f in ShiftFilter.values)
              FilterChip(
                key: ShiftsPageKeys.filter(f),
                label: Text(label(f)),
                selected: f == _filter,
                onSelected: (_) => setState(() => _filter = f),
              ),
          ],
        ),
      ),
    );
  }

  Widget _monthGroup(
    BuildContext context,
    ShiftMonthGroup group, {
    required Map<int, String>? jobNames,
    required LocalDate today,
  }) {
    final fmt = Fmt.of(context);
    final texts = ShiftTexts.of(context);
    final shifts = <Shift>[
      for (final s in group.shifts)
        if (!_dismissed.contains(s.id)) s,
    ];
    return SliverMainAxisGroup(
      slivers: <Widget>[
        PinnedHeaderSliver(
          child: ColoredBox(
            key: ShiftsPageKeys.monthHeader(group.year, group.month),
            color: Theme.of(context).colorScheme.surface,
            child: SectionHeader(
              fmt.monthYear(group.firstDay.toLocalDateTime()),
              subtitle: texts.monthSummary(
                workedMs: group.workedMs,
                earnedCents: group.earnedCents,
                openCents: group.openCents,
              ),
            ),
          ),
        ),
        SliverList.builder(
          itemCount: shifts.length,
          findChildIndexCallback: (key) {
            if (key is! ValueKey<int>) return null;
            final index = shifts.indexWhere((s) => s.id == key.value);
            return index < 0 ? null : index;
          },
          itemBuilder: (context, index) {
            final shift = shifts[index];
            return ShiftRow(
              shift: shift,
              jobName: jobNames?[shift.jobId],
              isToday: shift.localStartDate == today,
              onEdit: () => _edit(shift),
              onDuplicate: () => _duplicate(shift),
              onTogglePaid: () => _togglePaid(shift),
              onDelete: () async {
                final deleted = await _delete(shift);
                if (deleted && mounted) {
                  setState(() => _dismissed.add(shift.id));
                }
                return deleted;
              },
            );
          },
        ),
      ],
    );
  }

  Widget _emptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return switch (_filter) {
      ShiftFilter.all => EmptyState(
        icon: Icons.work_history_outlined,
        title: l10n.shiftsEmptyTitle,
        message: l10n.shiftsEmptyMessage,
        action: FilledButton.icon(
          onPressed: () => AdaptiveShell.selectTab(context, ShellTab.today),
          icon: const Icon(Icons.play_arrow_rounded),
          label: Text(l10n.shiftsStartShift),
        ),
        secondaryAction: TextButton.icon(
          onPressed: _add,
          icon: const Icon(Icons.add),
          label: Text(l10n.shiftsAddPastShift),
        ),
      ),
      ShiftFilter.open => EmptyState(
        icon: Icons.check_circle_outline,
        title: l10n.shiftsEmptyOpenTitle,
        message: l10n.shiftsEmptyOpenMessage,
        secondaryAction: TextButton(
          onPressed: () => setState(() => _filter = ShiftFilter.all),
          child: Text(l10n.shiftsShowAll),
        ),
      ),
      ShiftFilter.paid => EmptyState(
        icon: Icons.payments_outlined,
        title: l10n.shiftsEmptyPaidTitle,
        message: l10n.shiftsEmptyPaidMessage,
        secondaryAction: TextButton(
          onPressed: () => setState(() => _filter = ShiftFilter.all),
          child: Text(l10n.shiftsShowAll),
        ),
      ),
    };
  }
}

/// The running shift on top of the list ("Läuft seit 08:02"); tapping it
/// switches to Today.
class _RunningTile extends StatelessWidget {
  const _RunningTile({required this.shift, this.jobName});

  final Shift shift;
  final String? jobName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fmt = Fmt.of(context);
    final colors = ChronosColors.of(context);
    final text = Theme.of(context).textTheme;
    final pausedAt = shift.pausedAtUtc;
    final title = pausedAt != null
        ? l10n.shiftsPausedSince(fmt.time(pausedAt.toLocal()))
        : l10n.shiftsRunningSince(fmt.time(shift.startUtc.toLocal()));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ChronosSpace.s8),
      child: Card(
        key: ShiftsPageKeys.runningTile,
        color: colors.liveContainer,
        child: Semantics(
          hint: l10n.shiftsRunningOpenToday,
          child: ListTile(
            onTap: () => AdaptiveShell.selectTab(context, ShellTab.today),
            iconColor: colors.onLive,
            textColor: colors.onLive,
            leading: Icon(
              pausedAt != null ? Icons.pause_circle_outline : Icons.timer,
            ),
            title: Text(
              title,
              style: text.titleMedium?.copyWith(color: colors.onLive),
            ),
            subtitle: jobName == null
                ? null
                : Text(
                    jobName!,
                    style: text.bodyMedium?.copyWith(color: colors.onLive),
                  ),
            trailing: const Icon(Icons.chevron_right),
          ),
        ),
      ),
    );
  }
}
