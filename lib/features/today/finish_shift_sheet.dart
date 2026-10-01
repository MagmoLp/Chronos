import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/providers.dart';
import '../../app/theme/theme.dart';
import '../../core/format.dart';
import '../../core/local_date.dart';
import '../../core/time.dart';
import '../../data/shift_repository.dart' show FinishResult;
import '../../domain/errors.dart';
import '../../domain/finish.dart';
import '../../domain/job.dart';
import '../../domain/shift.dart';
import '../../domain/validation.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/money_field.dart';
import '../../widgets/time_field.dart';
import 'today_state.dart';

/// What happened in the "Schicht beenden" sheet.
sealed class FinishSheetOutcome {
  const FinishSheetOutcome();
}

/// The shift was saved (keep [result] for undo).
final class FinishSheetSaved extends FinishSheetOutcome {
  /// Creates the outcome.
  const FinishSheetSaved(this.result);

  /// The finish result for `undoFinish`.
  final FinishResult result;
}

/// The running shift was discarded (keep [shift] for undo).
final class FinishSheetDiscarded extends FinishSheetOutcome {
  /// Creates the outcome.
  const FinishSheetDiscarded(this.shift);

  /// The discarded shift for `undoDiscard`.
  final Shift shift;
}

/// Opens the "Schicht beenden" sheet for the running shift.
///
/// Resolves to `null` if nothing runs or the user kept the shift running
/// ("Weiterlaufen lassen" or dismissing the sheet). The caller shows the
/// undo snackbar after the sheet has closed.
Future<FinishSheetOutcome?> showFinishShiftSheet(
  BuildContext context,
  WidgetRef ref,
) async {
  final openedAt = ref.read(clockProvider).nowUtc();
  final preview = await ref
      .read(activeShiftControllerProvider.notifier)
      .previewFinish(endUtc: openedAt);
  if (preview == null || !context.mounted) return null;
  return showModalBottomSheet<FinishSheetOutcome>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => FinishShiftSheet(initial: preview, openedAt: openedAt),
  );
}

/// Review and save the running shift: start (recorded → rounded), end (now,
/// editable), break (editable), worked time, amount, optional tips and note.
class FinishShiftSheet extends ConsumerStatefulWidget {
  /// Creates the sheet with the preview at [openedAt].
  const FinishShiftSheet({
    super.key,
    required this.initial,
    required this.openedAt,
  });

  /// The preview for ending now.
  final FinishPreview initial;

  /// When the sheet was opened (the default end).
  final DateTime openedAt;

  @override
  ConsumerState<FinishShiftSheet> createState() => _FinishShiftSheetState();
}

class _FinishShiftSheetState extends ConsumerState<FinishShiftSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _breakText = TextEditingController();
  final TextEditingController _noteText = TextEditingController();

  late FinishPreview _preview = widget.initial;
  late DateTime _endUtc = widget.openedAt;

  /// Break entered by the user; `null` = all pauses so far (default).
  int? _breakMs;
  int _tipsCents = 0;
  bool _busy = false;
  String? _failure;
  int _serial = 0;

  @override
  void initState() {
    super.initState();
    _breakText.text = _minutesOf(_preview.breakMs).toString();
  }

  @override
  void dispose() {
    _breakText.dispose();
    _noteText.dispose();
    super.dispose();
  }

  static int _minutesOf(int ms) => (ms + msPerMinute ~/ 2) ~/ msPerMinute;

  Future<void> _refresh() async {
    final serial = ++_serial;
    final preview = await ref
        .read(activeShiftControllerProvider.notifier)
        .previewFinish(endUtc: _endUtc, breakMs: _breakMs);
    if (!mounted || serial != _serial) return;
    if (preview == null) {
      _closeBecauseGone();
      return;
    }
    setState(() {
      _preview = preview;
      _failure = null;
      if (_breakMs == null) {
        _breakText.text = _minutesOf(preview.breakMs).toString();
      }
    });
  }

  void _setEnd(ClockTime time) {
    setState(() {
      _endUtc = resolveFinishEnd(
        time,
        start: _preview.rawStartUtc,
        now: ref.read(clockProvider).nowUtc(),
      );
    });
    unawaited(_refresh());
  }

  void _setBreak(String text) {
    final minutes = int.tryParse(text.trim()) ?? 0;
    _breakMs = minutes * msPerMinute;
    unawaited(_refresh());
  }

  /// Nothing runs any more (finished from the notification meanwhile):
  /// close the sheet, and a dialog on top of it.
  void _closeBecauseGone() {
    final route = ModalRoute.of(context);
    if (route == null || !route.isActive) return;
    Navigator.of(context)
      ..popUntil((r) => r == route)
      ..pop();
  }

  bool get _endInFuture => _endUtc.isAfter(ref.read(clockProvider).nowUtc());

  List<String> _problems(AppLocalizations l10n) => <String>[
    if (_endInFuture) l10n.todayFinishErrorEndInFuture,
    for (final error in _preview.errors)
      switch (error) {
        ShiftError.endNotAfterStart => l10n.todayFinishErrorEndNotAfterStart,
        ShiftError.breakNotShorterThanDuration =>
          l10n.todayFinishErrorBreakTooLong,
        _ => l10n.errorSaveFailed,
      },
    ?_failure,
  ];

  Future<void> _save() async {
    if (_busy) return;
    // Commit a typed but not yet confirmed end time first.
    FocusManager.instance.primaryFocus?.unfocus();
    await Future<void>.value();
    if (!mounted || !(_formKey.currentState?.validate() ?? false)) return;
    final l10n = AppLocalizations.of(context);
    if (_problems(l10n).isNotEmpty) return;
    setState(() => _busy = true);
    try {
      final result = await ref
          .read(activeShiftControllerProvider.notifier)
          .finish(
            endUtc: _endUtc,
            breakMs: _breakMs,
            tipsCents: _tipsCents,
            note: _noteText.text,
          );
      if (!mounted) return;
      unawaited(HapticFeedback.mediumImpact());
      Navigator.of(context).pop(FinishSheetSaved(result));
    } on ChronosException catch (e) {
      if (!mounted || e.code == ChronosErrorCode.busy) return;
      setState(() {
        _busy = false;
        _failure = e.code == ChronosErrorCode.invalidShift
            ? null
            : todayErrorMessage(l10n, e);
      });
      if (e.code == ChronosErrorCode.invalidShift) unawaited(_refresh());
    } finally {
      if (mounted && _busy) setState(() => _busy = false);
    }
  }

  Future<void> _discard() async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.todayDiscardTitle,
      message: l10n.todayDiscardMessage,
      confirmLabel: l10n.commonDiscard,
      icon: Icons.delete_outline,
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    setState(() => _busy = true);
    try {
      final shift = await ref
          .read(activeShiftControllerProvider.notifier)
          .discard();
      if (!mounted) return;
      Navigator.of(context).pop(FinishSheetDiscarded(shift));
    } on ChronosException catch (e) {
      if (!mounted || e.code == ChronosErrorCode.busy) return;
      setState(() {
        _busy = false;
        _failure = todayErrorMessage(l10n, e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // The shift was finished elsewhere (e.g. from the notification).
    ref.listen(runningShiftProvider, (_, next) {
      if (!_busy && next.hasValue && next.value == null) _closeBecauseGone();
    });

    final l10n = AppLocalizations.of(context);
    final fmt = Fmt.of(context);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final chronosText = ChronosTextStyles.of(context);
    final preview = _preview;
    final problems = _problems(l10n);

    final rawStart = preview.rawStartUtc.toLocal();
    final recorded = fmt.time(rawStart);
    final billed = fmt.time(preview.startUtc.toLocal());
    // "08:02 → 08:00" when the job's rounding moved the start.
    final Widget startValue = preview.startRounded
        ? Semantics(
            label: l10n.todayFinishRoundedTimes(recorded, billed),
            excludeSemantics: true,
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                Text(
                  recorded,
                  style: chronosText.amount.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ChronosSpace.s4,
                  ),
                  child: Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  billed,
                  key: const ValueKey<String>('finish-start'),
                  style: chronosText.amount,
                ),
              ],
            ),
          )
        : Text(
            recorded,
            key: const ValueKey<String>('finish-start'),
            style: chronosText.amount,
          );
    final endLocal = _endUtc.toLocal();
    final endNotes = <String>[
      if (LocalDate.fromDateTime(endLocal) != LocalDate.fromDateTime(rawStart))
        l10n.todayFinishEndDate(fmt.dateShort(endLocal)),
      if (preview.endRounded)
        l10n.todayFinishBilledEnd(fmt.time(preview.endUtc.toLocal())),
    ];
    final rounding = preview.rounding;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          ChronosSpace.s24,
          0,
          ChronosSpace.s24,
          ChronosSpace.s24,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Semantics(
                header: true,
                child: Text(
                  l10n.todayFinishSheetTitle,
                  style: text.headlineSmall,
                ),
              ),
              const SizedBox(height: ChronosSpace.s16),
              MergeSemantics(
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: ChronosSpace.s16,
                  children: <Widget>[
                    Text(l10n.todayFinishStart, style: text.bodyLarge),
                    startValue,
                  ],
                ),
              ),
              if (rounding != RoundingRule.none &&
                  (preview.startRounded || preview.endRounded))
                Padding(
                  padding: const EdgeInsets.only(top: ChronosSpace.s4),
                  child: Text(
                    l10n.todayFinishRoundingNote(rounding.stepMinutes),
                    style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              const SizedBox(height: ChronosSpace.s16),
              TimeField(
                key: const ValueKey<String>('finish-end'),
                label: l10n.todayFinishEnd,
                value: clockTimeOf(_endUtc),
                stepMinutes: 5,
                enabled: !_busy,
                onChanged: _setEnd,
              ),
              if (endNotes.isNotEmpty)
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: ChronosSpace.s16,
                    top: ChronosSpace.s4,
                  ),
                  child: Text(
                    endNotes.join(' · '),
                    key: const ValueKey<String>('finish-end-note'),
                    style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              const SizedBox(height: ChronosSpace.s12),
              TextFormField(
                key: const ValueKey<String>('finish-break'),
                controller: _breakText,
                enabled: !_busy,
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                onChanged: _setBreak,
                decoration: InputDecoration(
                  labelText: l10n.todayFinishBreak,
                  suffixText: l10n.todayMinutesUnit,
                ),
              ),
              const SizedBox(height: ChronosSpace.s16),
              const Divider(),
              const SizedBox(height: ChronosSpace.s12),
              MergeSemantics(
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: ChronosSpace.s16,
                  children: <Widget>[
                    Text(l10n.todayFinishWorked, style: text.bodyLarge),
                    Text(
                      fmt.durationHm(preview.workedMs),
                      key: const ValueKey<String>('finish-worked'),
                      style: chronosText.amount,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: ChronosSpace.s4),
              MergeSemantics(
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: ChronosSpace.s16,
                  children: <Widget>[
                    Text(
                      l10n.todayFinishCalculation(
                        fmt.durationHm(preview.workedMs),
                        fmt.rate(preview.rateCentsPerHour),
                      ),
                      style: chronosText.bodyNumbers.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      fmt.money(preview.amountCents),
                      key: const ValueKey<String>('finish-amount'),
                      style: chronosText.statValue,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: ChronosSpace.s16),
              MoneyField(
                key: const ValueKey<String>('finish-tips'),
                label: l10n.todayFinishTips,
                enabled: !_busy,
                onChanged: (cents) => _tipsCents = cents ?? 0,
              ),
              const SizedBox(height: ChronosSpace.s12),
              TextField(
                key: const ValueKey<String>('finish-note'),
                controller: _noteText,
                enabled: !_busy,
                minLines: 1,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(labelText: l10n.todayFinishNote),
              ),
              if (problems.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: ChronosSpace.s12),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      problems.join('\n'),
                      key: const ValueKey<String>('finish-problems'),
                      style: text.bodyMedium?.copyWith(color: scheme.error),
                    ),
                  ),
                ),
              const SizedBox(height: ChronosSpace.s24),
              FilledButton(
                onPressed: _busy || problems.isNotEmpty ? null : _save,
                style: ChronosButtonStyles.primary(context),
                child: Text(l10n.commonSave),
              ),
              const SizedBox(height: ChronosSpace.s8),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: ChronosSpace.s8,
                children: <Widget>[
                  TextButton(
                    onPressed: _busy ? null : () => Navigator.of(context).pop(),
                    child: Text(l10n.todayFinishKeepRunning),
                  ),
                  TextButton.icon(
                    onPressed: _busy ? null : _discard,
                    style: TextButton.styleFrom(foregroundColor: scheme.error),
                    icon: const Icon(Icons.delete_outline),
                    label: Text(l10n.commonDiscard),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
