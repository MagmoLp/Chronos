import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

import '../../app/providers/providers.dart';
import '../../app/theme/theme.dart';
import '../../core/format.dart';
import '../../core/local_date.dart';
import '../../core/money.dart';
import '../../core/time.dart';
import '../../domain/errors.dart';
import '../../domain/job.dart';
import '../../domain/shift.dart';
import '../../domain/shift_draft.dart';
import '../../domain/validation.dart';
import '../../domain/wage_rate.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/hint_card.dart';
import '../../widgets/money_field.dart';
import '../../widgets/time_field.dart';
import '../../widgets/undo_snack_bar.dart';
import 'adaptive_sheet.dart';
import 'date_field.dart';
import 'shift_actions.dart';
import 'shift_texts.dart';

/// Keys of the editor's controls (tests).
abstract final class ShiftEditorKeys {
  /// The editor itself.
  static const Key editor = Key('editor');

  /// Job selector.
  static const Key job = Key('editor-job');

  /// Date field.
  static const Key date = Key('editor-date');

  /// Start time field.
  static const Key start = Key('editor-start');

  /// End time field.
  static const Key end = Key('editor-end');

  /// "Ends the next day" switch.
  static const Key nextDay = Key('editor-next-day');

  /// Break minutes field.
  static const Key breakField = Key('editor-break');

  /// Break − button.
  static const Key breakLess = Key('editor-break-less');

  /// Break + button.
  static const Key breakMore = Key('editor-break-more');

  /// Tips field.
  static const Key tips = Key('editor-tips');

  /// Note field.
  static const Key note = Key('editor-note');

  /// Open | Paid selector.
  static const Key status = Key('editor-status');

  /// Live preview.
  static const Key preview = Key('editor-preview');

  /// Validation messages.
  static const Key issues = Key('editor-issues');

  /// Save button.
  static const Key save = Key('editor-save');

  /// Delete button (edit mode).
  static const Key delete = Key('editor-delete');

  /// Duplicate button (edit mode).
  static const Key duplicate = Key('editor-duplicate');
}

/// Break stepper size in minutes.
const int _breakStepMinutes = 5;

/// Opens the shift editor: edits shift [shiftId], or creates a new shift
/// (optionally on [date] / for [jobId]).
///
/// Shown as a bottom sheet (full height in landscape) or, on expanded
/// windows, as a centred dialog. After closing, the page of [context] shows
/// the undo snackbars (new shift saved, shift deleted).
Future<void> showShiftEditor(
  BuildContext context, {
  int? shiftId,
  LocalDate? date,
  int? jobId,
}) => _openEditor(context, shiftId: shiftId, date: date, jobId: jobId);

/// Duplicates shift [shiftId] to today and opens the editor for the copy.
Future<void> duplicateShiftAndEdit(BuildContext context, int shiftId) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context);
  try {
    final today = container.read(clockProvider).today();
    final copy = await container
        .read(shiftsControllerProvider.notifier)
        .duplicate(shiftId, onDate: today);
    if (!context.mounted) return;
    await _openEditor(context, shiftId: copy.id, isCopy: true);
  } on Object catch (e, st) {
    reportShiftsError(messenger, l10n, container, e, st);
  }
}

Future<void> _openEditor(
  BuildContext context, {
  int? shiftId,
  LocalDate? date,
  int? jobId,
  bool isCopy = false,
}) async {
  final guard = SheetPopGuard();
  final outcome = await showAdaptiveSheet<_EditorOutcome>(
    context,
    guard: guard,
    builder: (_) => ShiftEditor(
      shiftId: shiftId,
      date: date,
      jobId: jobId,
      isCopy: isCopy,
      popGuard: guard,
    ),
  );
  if (outcome == null || !context.mounted) return;
  switch (outcome) {
    case _Saved(:final shift, :final isNew):
      if (!isNew) return;
      final container = ProviderScope.containerOf(context, listen: false);
      final messenger = ScaffoldMessenger.of(context);
      final l10n = AppLocalizations.of(context);
      final fmt = Fmt.of(context);
      final shifts = container.read(shiftsControllerProvider.notifier);
      showUndoSnackBar(
        context,
        message: l10n.shiftsSaved(
          fmt.durationHm(shift.workedMs),
          fmt.money(shift.earnedCents),
        ),
        onUndo: () => unawaited(
          shifts
              .delete([shift.id])
              .then<void>((_) {})
              .catchError(
                (Object e, StackTrace st) =>
                    reportShiftsError(messenger, l10n, container, e, st),
              ),
        ),
      );
    case _Delete(:final shiftId):
      await deleteShiftWithUndo(context, shiftId);
    case _Duplicate(:final shiftId):
      await duplicateShiftAndEdit(context, shiftId);
  }
}

/// How the editor was closed (besides dismissing).
sealed class _EditorOutcome {
  const _EditorOutcome();
}

final class _Saved extends _EditorOutcome {
  const _Saved(this.shift, {required this.isNew});

  final Shift shift;
  final bool isNew;
}

final class _Delete extends _EditorOutcome {
  const _Delete(this.shiftId);

  final int shiftId;
}

final class _Duplicate extends _EditorOutcome {
  const _Duplicate(this.shiftId);

  final int shiftId;
}

/// Editor field values, compared to detect unsaved changes.
typedef _Values = ({
  int? jobId,
  LocalDate date,
  ClockTime start,
  ClockTime end,
  bool endsNextDay,
  int breakMinutes,
  int tipsCents,
  String note,
  bool paid,
});

/// Add / edit form for a finished shift, with live preview and validation.
///
/// Use [showShiftEditor]; the widget is public for embedding and tests.
class ShiftEditor extends ConsumerStatefulWidget {
  /// Creates the editor.
  const ShiftEditor({
    super.key = ShiftEditorKeys.editor,
    this.shiftId,
    this.date,
    this.jobId,
    this.isCopy = false,
    this.popGuard,
  });

  /// Shift to edit; `null` adds a new shift.
  final int? shiftId;

  /// Date of a new shift (default today).
  final LocalDate? date;

  /// Job of a new shift (default: the default job).
  final int? jobId;

  /// Shows the "copy created" hint.
  final bool isCopy;

  /// Lets the sheet ask before a drag closes it with unsaved changes.
  final SheetPopGuard? popGuard;

  @override
  ConsumerState<ShiftEditor> createState() => _ShiftEditorState();
}

class _ShiftEditorState extends ConsumerState<ShiftEditor> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _note = TextEditingController();
  final TextEditingController _break = TextEditingController();

  bool _loading = true;

  /// Why the editor could not open (shown instead of the form).
  String Function(AppLocalizations l10n)? _loadProblem;
  Shift? _existing;

  int? _jobId;
  late LocalDate _date;
  late LocalDate _today;
  ClockTime _start = (hour: 8, minute: 0);
  ClockTime _end = (hour: 16, minute: 0);
  bool _endsNextDay = false;

  /// The user set "ends next day" explicitly (keep it when times change).
  bool _nextDayManual = false;

  /// "Ends next day" was switched on automatically (highlighted).
  bool _nextDayAuto = false;
  int _breakMinutes = 0;
  int? _tipsCents;
  bool _paid = false;

  _Values? _initial;
  ShiftValidation? _validation;
  int _validationRun = 0;

  bool _saving = false;
  bool _closing = false;
  bool _askingDiscard = false;
  String? _error;

  bool get _isEdit => widget.shiftId != null;

  @override
  void initState() {
    super.initState();
    _today = ref.read(clockProvider).today();
    _date = widget.date ?? _today;
    final guard = widget.popGuard;
    if (guard != null) {
      guard
        ..shouldVeto = (() => _dirty && !_closing)
        ..onVetoed = () => unawaited(_confirmDiscard());
    }
    _break.text = '0';
    unawaited(_load());
  }

  @override
  void dispose() {
    _note.dispose();
    _break.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------- loading

  /// First value of an async provider (keeps it alive meanwhile).
  Future<T> _first<T>(ProviderListenable<AsyncValue<T>> provider) {
    final completer = Completer<T>();
    final sub = ref.listenManual<AsyncValue<T>>(provider, (_, next) {
      if (completer.isCompleted) return;
      if (next.hasValue) {
        completer.complete(next.requireValue);
      } else if (next.hasError) {
        completer.completeError(next.error!, next.stackTrace);
      }
    }, fireImmediately: true);
    return completer.future.whenComplete(sub.close);
  }

  Future<void> _load() async {
    try {
      if (widget.shiftId case final id?) {
        final shift = await _first(shiftByIdProvider(id));
        if (!mounted) return;
        if (shift == null || shift.isDeleted || !shift.isDone) {
          setState(() {
            _loading = false;
            _loadProblem = shift != null && shift.isRunning
                ? (l10n) => l10n.shiftsErrorRunning
                : (l10n) => l10n.shiftsErrorNotFound;
          });
          return;
        }
        _applyShift(shift);
      } else {
        final jobId = widget.jobId ?? (await _first(defaultJobProvider))?.id;
        if (!mounted) return;
        if (jobId == null) {
          setState(() {
            _loading = false;
            _loadProblem = (l10n) => l10n.shiftsErrorJobNotFound;
          });
          return;
        }
        final draft = await ref
            .read(shiftsControllerProvider.notifier)
            .newDraft(jobId: jobId, date: _date);
        if (!mounted) return;
        _applyDraft(draft);
      }
    } on Object catch (e, st) {
      unawaited(ref.read(errorLogProvider).record(e, st, context: 'editor'));
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadProblem = (l10n) => l10n.errorLoadFailed;
      });
    }
  }

  void _applyShift(Shift shift) {
    final start = shift.startUtc.toLocal();
    final end = shift.endUtc!.toLocal();
    setState(() {
      _existing = shift;
      _jobId = shift.jobId;
      _date = shift.localStartDate;
      _start = (hour: start.hour, minute: start.minute);
      _end = (hour: end.hour, minute: end.minute);
      _endsNextDay = shift.endsOnLaterDay;
      _nextDayManual = _endsNextDay && !_endBeforeStart;
      _breakMinutes = ShiftTexts.breakMinutes(shift.breakMs);
      _break.text = '$_breakMinutes';
      _tipsCents = shift.tipsCents == 0 ? null : shift.tipsCents;
      _note.text = shift.note ?? '';
      _paid = shift.isPaid;
      _loading = false;
      _initial = _values;
    });
    _revalidate();
  }

  void _applyDraft(ShiftDraft draft) {
    final start = draft.startUtc.toLocal();
    final end = draft.endUtc.toLocal();
    setState(() {
      _jobId = draft.jobId;
      _start = (hour: start.hour, minute: start.minute);
      _end = (hour: end.hour, minute: end.minute);
      _endsNextDay = draft.localStartDate.isBefore(LocalDate.ofInstant(end));
      _nextDayManual = _endsNextDay && !_endBeforeStart;
      _loading = false;
      _initial = _values;
    });
    _revalidate();
  }

  // --------------------------------------------------------------- state

  _Values get _values => (
    jobId: _jobId,
    date: _date,
    start: _start,
    end: _end,
    endsNextDay: _endsNextDay,
    breakMinutes: _breakMinutes,
    tipsCents: _tipsCents ?? 0,
    note: _note.text.trim(),
    paid: _paid,
  );

  /// The end lies before the start on the clock, so the shift must end on
  /// the next day. An end equal to the start stays an error ("end must be
  /// after start") unless the user explicitly turns "ends next day" on.
  bool get _endBeforeStart =>
      _end.hour * 60 + _end.minute < _start.hour * 60 + _start.minute;

  bool get _dirty => !_loading && _initial != null && _values != _initial;

  ShiftDraft? get _draft {
    final jobId = _jobId;
    if (jobId == null) return null;
    // Editing keeps the stored instants of fields the user did not change
    // (a shift over more than one midnight must not shrink, v1 bug D11).
    if (_existing case final existing?) {
      return ShiftDraft.fromLocalEdit(
        original: existing,
        jobId: jobId,
        date: _date,
        startHour: _start.hour,
        startMinute: _start.minute,
        endHour: _end.hour,
        endMinute: _end.minute,
        endsNextDay: _endsNextDay,
        breakMinutes: _breakMinutes,
        tipsCents: _tipsCents ?? 0,
        note: _note.text,
        paid: _paid,
      );
    }
    return ShiftDraft.fromLocal(
      jobId: jobId,
      date: _date,
      startHour: _start.hour,
      startMinute: _start.minute,
      endHour: _end.hour,
      endMinute: _end.minute,
      endsNextDay: _endsNextDay,
      breakMs: _breakMinutes * msPerMinute,
      tipsCents: _tipsCents ?? 0,
      note: _note.text,
      paid: _paid,
    );
  }

  void _revalidate() {
    final draft = _draft;
    if (draft == null) return;
    final run = ++_validationRun;
    unawaited(
      ref
          .read(shiftsControllerProvider.notifier)
          .validate(draft, shiftId: widget.shiftId)
          .then<void>((validation) {
            if (!mounted || run != _validationRun) return;
            setState(() => _validation = validation);
          }, onError: (Object _) {}),
    );
  }

  void _change(VoidCallback update) {
    setState(() {
      update();
      _error = null;
    });
    _revalidate();
  }

  void _setTimes({ClockTime? start, ClockTime? end}) => _change(() {
    if (start != null) _start = start;
    if (end != null) _end = end;
    if (_endBeforeStart) {
      if (!_endsNextDay) {
        _endsNextDay = true;
        _nextDayAuto = true;
        _nextDayManual = false;
      }
    } else if (_endsNextDay && !_nextDayManual) {
      _endsNextDay = false;
      _nextDayAuto = false;
    }
  });

  void _setBreak(int minutes) {
    final value = minutes < 0 ? 0 : minutes;
    _break.text = '$value';
    _change(() => _breakMinutes = value);
  }

  /// Rate for the preview: the stored snapshot while editing (unless the
  /// job changed), else the job's rate on the date.
  int? _previewRate() {
    final existing = _existing;
    final jobId = _jobId;
    if (existing != null && existing.jobId == jobId) {
      return existing.rateCentsPerHour;
    }
    if (jobId == null) return null;
    final rates = ref.watch(jobRatesProvider(jobId)).value;
    return rates == null ? null : rateForDate(rates, _date);
  }

  // ------------------------------------------------------------- actions

  void _close([_EditorOutcome? outcome]) {
    _closing = true;
    Navigator.of(context).pop(outcome);
  }

  Future<bool> _askDiscard() {
    final l10n = AppLocalizations.of(context);
    return showConfirmDialog(
      context,
      title: l10n.editorDiscardTitle,
      message: l10n.editorDiscardMessage,
      confirmLabel: l10n.commonDiscard,
      cancelLabel: l10n.editorKeepEditing,
      destructive: true,
    );
  }

  Future<void> _confirmDiscard() async {
    if (_askingDiscard || _closing) return;
    _askingDiscard = true;
    final discard = await _askDiscard();
    _askingDiscard = false;
    if (discard && mounted) _close();
  }

  Future<bool> _confirmWarnings(ShiftValidation validation) {
    final l10n = AppLocalizations.of(context);
    final texts = ShiftTexts.of(context);
    return showConfirmDialog(
      context,
      title: l10n.editorConfirmTitle,
      message: validation.warnings.map(texts.warning).join('\n'),
      confirmLabel: l10n.editorConfirmSave,
      icon: Icons.warning_amber_rounded,
    );
  }

  Future<void> _save() async {
    if (_saving || _loading || _closing) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await commitPendingInput();
      if (!mounted) return;
      if (!(_formKey.currentState?.validate() ?? true)) return;
      final draft = _draft;
      if (draft == null) return;
      final controller = ref.read(shiftsControllerProvider.notifier);
      var outcome = await controller.save(draft, shiftId: widget.shiftId);
      if (!mounted) return;
      if (outcome is ShiftSaveNeedsConfirmation) {
        setState(() => _validation = outcome.validation);
        final confirmed = await _confirmWarnings(outcome.validation);
        if (!mounted || !confirmed) return;
        outcome = await controller.save(
          draft,
          shiftId: widget.shiftId,
          confirmed: true,
        );
        if (!mounted) return;
      }
      switch (outcome) {
        case ShiftSaved(:final shift):
          unawaited(HapticFeedback.mediumImpact());
          _close(_Saved(shift, isNew: !_isEdit));
        case ShiftSaveInvalid(:final validation):
        case ShiftSaveNeedsConfirmation(:final validation):
          setState(() => _validation = validation);
      }
    } on Object catch (e, st) {
      if (e is! ChronosException) {
        unawaited(ref.read(errorLogProvider).record(e, st, context: 'editor'));
      }
      if (!mounted) return;
      final message = shiftsErrorMessage(AppLocalizations.of(context), e);
      if (message != null) setState(() => _error = message);
    } finally {
      if (mounted && !_closing) setState(() => _saving = false);
    }
  }

  void _delete() {
    final id = widget.shiftId;
    if (id == null || _saving) return;
    _close(_Delete(id));
  }

  Future<void> _duplicate() async {
    final id = widget.shiftId;
    if (id == null || _saving) return;
    if (_dirty && !await _askDiscard()) return;
    if (!mounted) return;
    _close(_Duplicate(id));
  }

  // ---------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = _isEdit ? l10n.editorTitleEdit : l10n.editorTitleNew;
    final scope = SheetScope.maybeOf(context);
    final textScale = MediaQuery.textScalerOf(context).scale(10) / 10;
    final previewInFooter = !(scope?.fillHeight ?? false) && textScale <= 1.5;

    final Widget frame;
    final problem = _loadProblem;
    if (_loading || problem != null) {
      frame = SheetFrame(
        title: title,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: ChronosSpace.s32),
            child: Center(
              child: _loading
                  ? const CircularProgressIndicator()
                  : Text(problem!(l10n), textAlign: TextAlign.center),
            ),
          ),
        ],
      );
    } else {
      final preview = _Preview(
        key: ShiftEditorKeys.preview,
        draft: _draft,
        rate: _previewRate(),
      );
      frame = SheetFrame(
        title: title,
        footer: _footer(context, previewInFooter ? preview : null),
        children: <Widget>[
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: _fields(context),
            ),
          ),
          if (!previewInFooter) ...<Widget>[
            const SizedBox(height: ChronosSpace.s16),
            preview,
          ],
          if (_isEdit) ..._editActions(context),
        ],
      );
    }

    return PopScope<Object?>(
      canPop: !_dirty || _closing,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_confirmDiscard());
      },
      child: frame,
    );
  }

  Widget _footer(BuildContext context, Widget? preview) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final save = FilledButton(
      key: ShiftEditorKeys.save,
      onPressed: _saving ? null : () => unawaited(_save()),
      child: Text(l10n.commonSave),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: ChronosSpace.s8),
            child: Semantics(
              liveRegion: true,
              child: Text(
                _error!,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: scheme.error),
              ),
            ),
          ),
        if (preview == null)
          save
        else
          OverflowBar(
            spacing: ChronosSpace.s16,
            overflowSpacing: ChronosSpace.s12,
            alignment: MainAxisAlignment.spaceBetween,
            overflowAlignment: OverflowBarAlignment.end,
            children: <Widget>[preview, save],
          ),
      ],
    );
  }

  List<Widget> _fields(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final jobs = ref.watch(activeJobsProvider).value ?? const <Job>[];
    final allJobs = ref.watch(jobsProvider).value ?? const <Job>[];
    final choices = <Job>[
      ...jobs,
      for (final j in allJobs)
        if (j.id == _jobId && !jobs.any((a) => a.id == j.id)) j,
    ];
    final tenYearsAgo = LocalDate(_today.year - 10, _today.month, _today.day);
    const gap = SizedBox(height: ChronosSpace.s16);

    return <Widget>[
      if (widget.isCopy) ...<Widget>[
        HintCard(message: l10n.editorCopyNotice, icon: Icons.content_copy),
        gap,
      ],
      if (choices.length > 1) ...<Widget>[
        _JobSelector(
          key: ShiftEditorKeys.job,
          jobs: choices,
          selected: _jobId,
          onSelected: (id) => _change(() => _jobId = id),
        ),
        gap,
      ],
      DateField(
        key: ShiftEditorKeys.date,
        label: l10n.editorDate,
        date: _date,
        firstDate: tenYearsAgo,
        lastDate: _today.addDays(1),
        onChanged: (d) => _change(() => _date = d),
      ),
      gap,
      TimeField(
        key: ShiftEditorKeys.start,
        label: l10n.editorStart,
        value: _start,
        onChanged: (t) => _setTimes(start: t),
      ),
      gap,
      TimeField(
        key: ShiftEditorKeys.end,
        label: l10n.editorEnd,
        value: _end,
        onChanged: (t) => _setTimes(end: t),
      ),
      const SizedBox(height: ChronosSpace.s8),
      _NextDaySwitch(
        key: ShiftEditorKeys.nextDay,
        value: _endsNextDay,
        highlighted: _nextDayAuto && _endsNextDay,
        endDate: _date.addDays(1),
        onChanged: (v) => _change(() {
          _endsNextDay = v;
          _nextDayManual = v;
          _nextDayAuto = false;
        }),
      ),
      const SizedBox(height: ChronosSpace.s8),
      _BreakField(
        controller: _break,
        onChanged: (minutes) => _change(() => _breakMinutes = minutes),
        onStep: (delta) => _setBreak(_breakMinutes + delta),
      ),
      ..._issues(context),
      gap,
      MoneyField(
        key: ShiftEditorKeys.tips,
        label: l10n.editorTips,
        value: _tipsCents,
        textInputAction: TextInputAction.next,
        onChanged: (cents) => _change(() => _tipsCents = cents),
      ),
      gap,
      TextFormField(
        key: ShiftEditorKeys.note,
        controller: _note,
        minLines: 1,
        maxLines: 3,
        maxLength: 500,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          labelText: l10n.editorNote,
          counterText: '',
        ),
        onChanged: (_) => setState(() {}),
      ),
      gap,
      _StatusSelector(
        key: ShiftEditorKeys.status,
        paid: _paid,
        onChanged: (paid) => _change(() => _paid = paid),
      ),
    ];
  }

  List<Widget> _issues(BuildContext context) {
    final validation = _validation;
    if (validation == null || validation.isClean) return const <Widget>[];
    final texts = ShiftTexts.of(context);
    final scheme = Theme.of(context).colorScheme;
    final colors = ChronosColors.of(context);
    return <Widget>[
      const SizedBox(height: ChronosSpace.s12),
      Semantics(
        key: ShiftEditorKeys.issues,
        container: true,
        liveRegion: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            for (final error in validation.errors)
              _IssueLine(
                icon: Icons.error_outline,
                color: scheme.error,
                text: texts.error(error),
              ),
            for (final warning in validation.warnings)
              _IssueLine(
                icon: Icons.warning_amber_rounded,
                color: colors.warning,
                text: texts.warning(warning),
              ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _editActions(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return <Widget>[
      const SizedBox(height: ChronosSpace.s16),
      const Divider(),
      const SizedBox(height: ChronosSpace.s8),
      Wrap(
        alignment: WrapAlignment.spaceBetween,
        spacing: ChronosSpace.s8,
        runSpacing: ChronosSpace.s8,
        children: <Widget>[
          TextButton.icon(
            key: ShiftEditorKeys.delete,
            onPressed: _saving ? null : _delete,
            style: TextButton.styleFrom(foregroundColor: scheme.error),
            icon: const Icon(Icons.delete_outline),
            label: Text(l10n.commonDelete),
          ),
          TextButton.icon(
            key: ShiftEditorKeys.duplicate,
            onPressed: _saving ? null : () => unawaited(_duplicate()),
            icon: const Icon(Icons.content_copy_outlined),
            label: Text(l10n.commonDuplicate),
          ),
        ],
      ),
    ];
  }
}

/// Live earnings preview: time range, "7:45 h × 15,00 €/h = 116,25 €" and
/// tips.
class _Preview extends StatelessWidget {
  const _Preview({super.key, required this.draft, required this.rate});

  final ShiftDraft? draft;
  final int? rate;

  @override
  Widget build(BuildContext context) {
    final draft = this.draft;
    final rate = this.rate;
    if (draft == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final fmt = Fmt.of(context);
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final scheme = theme.colorScheme;
    final worked = draft.workedMs;
    final range = fmt.timeRange(
      draft.startUtc.toLocal(),
      draft.endUtc.toLocal(),
    );
    final amount = rate == null ? null : earningsCents(worked, rate);
    final line = amount == null
        ? fmt.durationHm(worked)
        : l10n.editorPreview(
            fmt.durationHm(worked),
            fmt.rate(rate!),
            fmt.money(amount),
          );
    final spoken = amount == null
        ? fmt.durationSpoken(worked)
        : l10n.editorPreviewSpoken(
            fmt.durationSpoken(worked),
            fmt.rate(rate!),
            fmt.money(amount),
          );
    return Semantics(
      container: true,
      label: <String>[
        range,
        spoken,
        if (draft.tipsCents > 0)
          l10n.editorPreviewTips(fmt.money(draft.tipsCents)),
      ].join(', '),
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            range,
            style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          Text(
            line,
            style: ChronosTextStyles.of(context).amount
                .copyWith(color: scheme.onSurface),
          ),
          if (draft.tipsCents > 0)
            Text(
              l10n.editorPreviewTips(fmt.money(draft.tipsCents)),
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
        ],
      ),
    );
  }
}

class _JobSelector extends StatelessWidget {
  const _JobSelector({
    super.key,
    required this.jobs,
    required this.selected,
    required this.onSelected,
  });

  final List<Job> jobs;
  final int? selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return DropdownMenu<int>(
      initialSelection: selected,
      expandedInsets: EdgeInsets.zero,
      // Filled like the other form fields.
      inputDecorationTheme: Theme.of(context).inputDecorationTheme,
      label: Text(AppLocalizations.of(context).editorJob),
      requestFocusOnTap: false,
      onSelected: (id) {
        if (id != null && id != selected) onSelected(id);
      },
      dropdownMenuEntries: <DropdownMenuEntry<int>>[
        for (final job in jobs)
          DropdownMenuEntry<int>(
            value: job.id,
            label: job.name,
            leadingIcon: Icon(
              Icons.circle,
              size: 12,
              color: jobColorOf(context, job),
            ),
          ),
      ],
    );
  }
}

class _NextDaySwitch extends StatelessWidget {
  const _NextDaySwitch({
    super.key,
    required this.value,
    required this.highlighted,
    required this.endDate,
    required this.onChanged,
  });

  final bool value;
  final bool highlighted;
  final LocalDate endDate;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fmt = Fmt.of(context);
    final scheme = Theme.of(context).colorScheme;
    final subtitle = !value
        ? null
        : highlighted
        ? l10n.editorEndsNextDayAuto
        : fmt.dateShort(endDate.toLocalDateTime());
    return Material(
      color: highlighted ? scheme.secondaryContainer : Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: ChronosCorners.medium),
      clipBehavior: Clip.antiAlias,
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        contentPadding: const EdgeInsetsDirectional.only(
          start: ChronosSpace.s12,
          end: ChronosSpace.s8,
        ),
        secondary: Icon(
          Icons.nights_stay_outlined,
          color: highlighted
              ? scheme.onSecondaryContainer
              : scheme.onSurfaceVariant,
        ),
        title: Text(
          l10n.editorEndsNextDay,
          style: TextStyle(
            color: highlighted ? scheme.onSecondaryContainer : scheme.onSurface,
          ),
        ),
        subtitle: subtitle == null
            ? null
            : Text(
                subtitle,
                style: TextStyle(
                  color: highlighted
                      ? scheme.onSecondaryContainer
                      : scheme.onSurfaceVariant,
                ),
              ),
      ),
    );
  }
}

class _BreakField extends StatelessWidget {
  const _BreakField({
    required this.controller,
    required this.onChanged,
    required this.onStep,
  });

  final TextEditingController controller;
  final ValueChanged<int> onChanged;
  final ValueChanged<int> onStep;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const stepStyle = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(
        Size.square(ChronosLayout.minTapTarget),
      ),
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: TextFormField(
            key: ShiftEditorKeys.breakField,
            controller: controller,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            decoration: InputDecoration(
              labelText: l10n.editorBreak,
              suffixText: l10n.formatMinutes('').trim(),
            ),
            validator: (text) {
              final value = text?.trim() ?? '';
              if (value.isEmpty) return null;
              return int.tryParse(value) == null
                  ? l10n.editorBreakInvalid
                  : null;
            },
            onChanged: (text) => onChanged(int.tryParse(text.trim()) ?? 0),
          ),
        ),
        const SizedBox(width: ChronosSpace.s8),
        Padding(
          padding: const EdgeInsets.only(top: ChronosSpace.s4),
          child: IconButton.filledTonal(
            key: ShiftEditorKeys.breakLess,
            onPressed: () => onStep(-_breakStepMinutes),
            tooltip: l10n.editorBreakLess(_breakStepMinutes),
            style: stepStyle,
            icon: const Icon(Icons.remove),
          ),
        ),
        const SizedBox(width: ChronosSpace.s8),
        Padding(
          padding: const EdgeInsets.only(top: ChronosSpace.s4),
          child: IconButton.filledTonal(
            key: ShiftEditorKeys.breakMore,
            onPressed: () => onStep(_breakStepMinutes),
            tooltip: l10n.editorBreakMore(_breakStepMinutes),
            style: stepStyle,
            icon: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}

class _StatusSelector extends StatelessWidget {
  const _StatusSelector({
    super.key,
    required this.paid,
    required this.onChanged,
  });

  final bool paid;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          l10n.editorStatus,
          style: text.labelLarge?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: ChronosSpace.s8),
        SegmentedButton<bool>(
          showSelectedIcon: false,
          segments: <ButtonSegment<bool>>[
            ButtonSegment<bool>(
              value: false,
              icon: const Icon(Icons.schedule),
              label: Text(l10n.statusOpen),
            ),
            ButtonSegment<bool>(
              value: true,
              icon: const Icon(Icons.check_circle_outline),
              label: Text(l10n.statusPaid),
            ),
          ],
          selected: <bool>{paid},
          onSelectionChanged: (selection) => onChanged(selection.first),
        ),
      ],
    );
  }
}

class _IssueLine extends StatelessWidget {
  const _IssueLine({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ChronosSpace.s4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 20, color: color),
          const SizedBox(width: ChronosSpace.s8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
