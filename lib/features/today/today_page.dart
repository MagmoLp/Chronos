import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/providers.dart';
import '../../app/shell.dart';
import '../../app/theme/theme.dart';
import '../../core/format.dart';
import '../../domain/errors.dart';
import '../../domain/shift.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/undo_snack_bar.dart';
import '../review/review_page.dart';
import '../settings/settings_page.dart';
import '../shifts/payout_sheet.dart';
import '../shifts/shift_editor.dart';
import 'finish_shift_sheet.dart';
import 'notification_primer.dart';
import 'time_dialog.dart';
import 'today_actions.dart';
import 'today_hero.dart';
import 'today_state.dart';
import 'today_summaries.dart';

/// Screens of other features that Today opens. Tests pass a recording
/// subclass; the app uses the default.
class TodayNavigation {
  /// Creates the default navigation.
  const TodayNavigation();

  /// The settings screen (gear).
  Future<void> openSettings(BuildContext context) => _openSettings(context);

  /// The shift editor for [shiftId] ("Letzte Schicht", today's shifts).
  Future<void> openShiftEditor(BuildContext context, int shiftId) =>
      showShiftEditor(context, shiftId: shiftId);

  /// "Auszahlung erfassen".
  Future<void> openPayoutSheet(BuildContext context) =>
      showPayoutSheet(context);

  /// The list of migrated entries to check.
  Future<void> openReview(BuildContext context) => openReviewPage(context);
}

// Top-level indirection: inside [TodayNavigation] the name `openSettings`
// refers to the method.
Future<void> _openSettings(BuildContext context) => openSettings(context);

/// The "Heute" tab: live pay of the running shift or the unpaid balance,
/// start/pause/finish, this week and the last shift.
///
/// Layout: one column on compact portrait windows; two columns (card left,
/// actions and summaries right) from 600 dp width or below 480 dp height;
/// from 840 dp an extra pane lists today's shifts.
class TodayPage extends ConsumerStatefulWidget {
  /// Creates the page.
  const TodayPage({super.key, this.navigation = const TodayNavigation()});

  /// Where the page navigates to (other features).
  final TodayNavigation navigation;

  @override
  ConsumerState<TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends ConsumerState<TodayPage> {
  late final AppLifecycleListener _lifecycle;

  /// Result of the last permission check; `null` until checked (only after
  /// the permission primer was shown).
  bool? _notificationsEnabled;
  bool _finishSheetOpen = false;

  TodayNavigation get _nav => widget.navigation;
  ActiveShiftController get _active =>
      ref.read(activeShiftControllerProvider.notifier);

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _onResume);
    ref.listenManual<bool>(
      settingsProvider.select((s) => s.notificationPrimerShown),
      (_, shown) {
        if (shown) unawaited(_checkNotifications());
      },
      fireImmediately: true,
    );
    ref.listenManual<AppRequest?>(
      appRequestProvider,
      (_, _) => _scheduleRequest(),
      fireImmediately: true,
    );
    ref.listenManual<AsyncValue<Shift?>>(
      runningShiftProvider,
      (_, _) => _scheduleRequest(),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  void _onResume() {
    ref.read(currentDateProvider.notifier).refresh();
    unawaited(_checkNotifications());
  }

  // ------------------------------------------------------------ requests --

  void _scheduleRequest() {
    if (ref.read(appRequestProvider)?.kind != AppRequestKind.openFinishSheet) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_handleRequest());
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  /// "Beenden" from the notification: open the finish sheet once the
  /// running shift is known.
  Future<void> _handleRequest() async {
    if (!mounted) return;
    final request = ref.read(appRequestProvider);
    if (request == null || request.kind != AppRequestKind.openFinishSheet) {
      return;
    }
    final running = ref.read(runningShiftProvider);
    if (!running.hasValue) return; // Retried when the shift has loaded.
    ref.read(appRequestProvider.notifier).consume(request);
    if (running.value != null) await _finish();
  }

  // ------------------------------------------------------- notifications --

  Future<void> _checkNotifications() async {
    if (!mounted || !ref.read(settingsProvider).notificationPrimerShown) {
      return;
    }
    final enabled = await ref
        .read(notificationServiceProvider)
        .areNotificationsEnabled();
    if (mounted && enabled != _notificationsEnabled) {
      setState(() => _notificationsEnabled = enabled);
    }
  }

  /// First start: explain the lock-screen notification, then ask for the
  /// permission. The shift starts whatever the answer is.
  Future<void> _primeNotifications() async {
    try {
      await ref.read(settingsRepositoryProvider.future);
    } on Exception {
      // Settings could not be loaded: behave like a first start.
    }
    if (!mounted || ref.read(settingsProvider).notificationPrimerShown) {
      return;
    }
    final service = ref.read(notificationServiceProvider);
    final settings = ref.read(settingsProvider.notifier);
    if (!await service.areNotificationsEnabled()) {
      if (!mounted) return;
      if (await showNotificationPrimer(context)) {
        await service.requestPermission();
      }
    }
    await settings.setNotificationPrimerShown(true);
    await _checkNotifications();
  }

  Future<void> _openNotificationSettings() async {
    await ref.read(notificationServiceProvider).openNotificationSettings();
  }

  // ------------------------------------------------------------- actions --

  /// Runs [action]; refused actions show a localized message, a double tap
  /// ([ChronosErrorCode.busy]) is ignored. Returns `null` on failure.
  Future<T?> _guard<T>(Future<T> Function() action) async {
    final log = mounted ? ref.read(errorLogProvider) : null;
    try {
      return await action();
    } on ChronosException catch (e) {
      if (!mounted) return null;
      final message = todayErrorMessage(AppLocalizations.of(context), e);
      if (message != null) _showMessage(message);
    } on Exception catch (e, stack) {
      if (log != null) unawaited(log.record(e, stack, context: 'today'));
      if (mounted) _showMessage(AppLocalizations.of(context).errorGeneric);
    }
    return null;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _start() async {
    final job = ref.read(todayStartJobProvider).value;
    if (job == null) return;
    // The shift starts when the button was tapped, not after the user has
    // read the permission explanation and answered the system dialog.
    final tappedAt = ref.read(clockProvider).nowUtc();
    await _primeNotifications();
    if (!mounted) return;
    final started = await _guard(
      () => _active.start(job.id, startUtc: tappedAt),
    );
    if (started != null) unawaited(HapticFeedback.mediumImpact());
  }

  Future<void> _startEarlier() async {
    final job = ref.read(todayStartJobProvider).value;
    if (job == null) return;
    final appClock = ref.read(clockProvider);
    final picked = await _pickTime(clockTimeOf(appClock.now()));
    if (picked == null || !mounted) return;
    final start = resolvePastStart(picked, now: appClock.nowUtc());
    if (start == null) {
      _showMessage(AppLocalizations.of(context).todayErrorStartInFuture);
      return;
    }
    final overlaps = await _active.overlapsIfStartedAt(start);
    if (!mounted) return;
    if (overlaps.isNotEmpty &&
        !await _confirmOverlap(
          overlaps,
          AppLocalizations.of(context).todayOverlapStartAnyway,
        )) {
      return;
    }
    await _primeNotifications();
    if (!mounted) return;
    final started = await _guard(() => _active.start(job.id, startUtc: start));
    if (started != null) unawaited(HapticFeedback.mediumImpact());
  }

  /// "seit 08:02" tapped: move the start of the running shift.
  Future<void> _adjustStart() async {
    final running = ref.read(runningShiftProvider).value;
    if (running == null) return;
    final picked = await _pickTime(clockTimeOf(running.startUtc));
    if (picked == null || !mounted) return;
    if (picked == clockTimeOf(running.startUtc)) return;
    final start = resolvePastStart(
      picked,
      now: ref.read(clockProvider).nowUtc(),
    );
    if (start == null) {
      _showMessage(AppLocalizations.of(context).todayErrorStartInFuture);
      return;
    }
    final overlaps = [
      for (final s in await _active.overlapsIfStartedAt(start))
        if (s.id != running.id) s,
    ];
    if (!mounted) return;
    if (overlaps.isNotEmpty &&
        !await _confirmOverlap(
          overlaps,
          AppLocalizations.of(context).todayOverlapChangeAnyway,
        )) {
      return;
    }
    final previous = running.startUtc;
    final active = _active;
    final updated = await _guard(() => active.adjustStart(start));
    if (updated == null || !mounted) return;
    final fmt = Fmt.of(context);
    showUndoSnackBar(
      context,
      message: AppLocalizations.of(context)
          .todayStartChanged(fmt.time(updated.startUtc.toLocal())),
      onUndo: () => unawaited(_guard(() => active.adjustStart(previous))),
    );
  }

  Future<void> _pauseOrResume() async {
    final running = ref.read(runningShiftProvider).value;
    if (running == null) return;
    await _guard(() => running.isPaused ? _active.resume() : _active.pause());
  }

  Future<void> _finish() async {
    if (_finishSheetOpen) return;
    _finishSheetOpen = true;
    final FinishSheetOutcome? outcome;
    try {
      outcome = await showFinishShiftSheet(context, ref);
    } finally {
      _finishSheetOpen = false;
    }
    if (!mounted || outcome == null) return;
    final l10n = AppLocalizations.of(context);
    final fmt = Fmt.of(context);
    final active = _active;
    switch (outcome) {
      case FinishSheetSaved(:final result):
        final saved = result.after;
        showUndoSnackBar(
          context,
          message: l10n.todayShiftSaved(
            fmt.durationHm(saved.workedMs),
            fmt.money(saved.earnedCents),
          ),
          onUndo: () => unawaited(_guard(() => active.undoFinish(result))),
        );
      case FinishSheetDiscarded(:final shift):
        showUndoSnackBar(
          context,
          message: l10n.todayShiftDiscarded,
          onUndo: () => unawaited(_guard(() => active.undoDiscard(shift))),
        );
    }
  }

  Future<ClockTime?> _pickTime(ClockTime initial) => showTodayTimeDialog(
    context,
    initial: initial,
    title: AppLocalizations.of(context).todayStartTimeHelp,
    label: AppLocalizations.of(context).todayFinishStart,
  );

  Future<bool> _confirmOverlap(List<Shift> overlaps, String confirmLabel) {
    final l10n = AppLocalizations.of(context);
    final fmt = Fmt.of(context);
    return showConfirmDialog(
      context,
      title: l10n.todayOverlapTitle,
      message: l10n.todayOverlapMessage(
        overlaps.map((s) => shiftDateAndTimes(fmt, s)).join('; '),
      ),
      confirmLabel: confirmLabel,
      icon: Icons.warning_amber_rounded,
    );
  }

  // -------------------------------------------------------------- layout --

  @override
  Widget build(BuildContext context) {
    final fmt = Fmt.of(context);
    final date = ref.watch(currentDateProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(fmt.todayTitle(date.toLocalDateTime())),
        actions: <Widget>[
          ShellSettingsButton(
            onPressed: () => unawaited(_nav.openSettings(context)),
          ),
        ],
      ),
      body: SafeArea(top: false, child: LayoutBuilder(builder: _buildBody)),
    );
  }

  Widget _buildBody(BuildContext context, BoxConstraints constraints) {
    final width = constraints.maxWidth;
    final compactHeight =
        MediaQuery.sizeOf(context).height < ChronosLayout.compactHeight;
    final expanded = width >= ChronosLayout.expandedWidth;
    final twoColumns =
        width >= ChronosLayout.compactWidth || (compactHeight && width >= 480);
    final margin = ChronosLayout.marginFor(width);
    final vertical = compactHeight ? ChronosSpace.s12 : ChronosSpace.s16;
    final sectionGap = compactHeight ? ChronosSpace.s16 : ChronosSpace.s24;

    final hints = TodayHints(
      notificationsOff: _notificationsEnabled == false,
      onReview: () => unawaited(_nav.openReview(context)),
      onOpenNotificationSettings: () => unawaited(_openNotificationSettings()),
    );
    final hero = TodayHeroCard(
      large: expanded,
      dense: compactHeight,
      onAdjustStart: () => unawaited(_adjustStart()),
      onRecordPayout: () => unawaited(_nav.openPayoutSheet(context)),
    );
    final actions = TodayActions(
      dense: compactHeight && twoColumns,
      onStart: () => unawaited(_start()),
      onStartEarlier: () => unawaited(_startEarlier()),
      onPauseResume: () => unawaited(_pauseOrResume()),
      onFinish: () => unawaited(_finish()),
    );
    final summaries = TodayWeekAndLastShift(
      onOpenShift: (id) => unawaited(_nav.openShiftEditor(context, id)),
    );

    final Widget content;
    if (!twoColumns) {
      content = ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: ChronosLayout.paneMaxWidth),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            hints,
            hero,
            const TodayOpenLines(
              padding: EdgeInsets.only(top: ChronosSpace.s12),
            ),
            SizedBox(height: sectionGap),
            actions,
            SizedBox(height: sectionGap),
            summaries,
          ],
        ),
      );
    } else {
      final columns = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(child: hero),
          SizedBox(width: sectionGap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                hints,
                const TodayOpenLines(
                  padding: EdgeInsets.only(bottom: ChronosSpace.s12),
                ),
                actions,
                SizedBox(height: sectionGap),
                summaries,
              ],
            ),
          ),
        ],
      );
      content = expanded
          ? ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: ChronosLayout.contentMaxWidth + 24 + 360,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(child: columns),
                  const SizedBox(width: ChronosSpace.s24),
                  SizedBox(
                    width: 360,
                    child: TodayShiftsPane(
                      onOpenShift: (id) =>
                          unawaited(_nav.openShiftEditor(context, id)),
                    ),
                  ),
                ],
              ),
            )
          : ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: ChronosLayout.contentMaxWidth,
              ),
              child: columns,
            );
    }

    return SingleChildScrollView(
      key: const ValueKey<String>('today-scroll'),
      padding: EdgeInsets.symmetric(horizontal: margin, vertical: vertical),
      child: Align(alignment: Alignment.topCenter, child: content),
    );
  }
}
