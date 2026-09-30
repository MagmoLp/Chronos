import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/providers.dart';
import '../../app/theme/theme.dart';
import '../../core/format.dart';
import '../../core/local_date.dart';
import '../../domain/errors.dart';
import '../../domain/job.dart';
import '../../domain/payout.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/money_field.dart';
import '../../widgets/undo_snack_bar.dart';
import 'adaptive_sheet.dart';
import 'date_field.dart';
import 'shift_actions.dart';
import 'shift_texts.dart';

/// Keys of the payout sheet's controls (tests).
abstract final class PayoutSheetKeys {
  /// The sheet.
  static const Key sheet = Key('payout');

  /// Job selector.
  static const Key job = Key('payout-job');

  /// "Up to and including" date.
  static const Key until = Key('payout-until');

  /// "23 Schichten · 172,5 h".
  static const Key summary = Key('payout-summary');

  /// Expected amount.
  static const Key expected = Key('payout-expected');

  /// Received amount field.
  static const Key received = Key('payout-received');

  /// Difference value.
  static const Key difference = Key('payout-difference');

  /// "Paid on" date.
  static const Key paidOn = Key('payout-paid-on');

  /// Note field.
  static const Key note = Key('payout-note');

  /// Submit button.
  static const Key submit = Key('payout-submit');

  /// Hint shown when nothing is open.
  static const Key nothingOpen = Key('payout-nothing-open');
}

/// Value of the job selector for "all jobs".
const int _allJobs = -1;

/// Opens the "Auszahlung erfassen" sheet (optionally preselecting [jobId]).
///
/// On success the shifts are marked paid, the sheet closes and the page of
/// [context] offers Undo.
Future<void> showPayoutSheet(BuildContext context, {int? jobId}) async {
  final result = await showAdaptiveSheet<_PayoutResult>(
    context,
    builder: (_) => PayoutSheet(jobId: jobId),
  );
  if (result == null || !context.mounted) return;
  final container = ProviderScope.containerOf(context, listen: false);
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context);
  final payouts = container.read(payoutControllerProvider.notifier);
  showUndoSnackBar(
    context,
    message: l10n.payoutRecorded(result.count),
    onUndo: () => unawaited(
      payouts
          .undo(result.payout)
          .then<void>((_) {})
          .catchError(
            (Object e, StackTrace st) =>
                reportShiftsError(messenger, l10n, container, e, st),
          ),
    ),
  );
}

final class _PayoutResult {
  const _PayoutResult(this.payout, this.count);

  final Payout payout;
  final int count;
}

/// Form that settles all open shifts up to a date (optionally of one job)
/// as one payout. Use [showPayoutSheet].
class PayoutSheet extends ConsumerStatefulWidget {
  /// Creates the sheet content.
  const PayoutSheet({super.key = PayoutSheetKeys.sheet, this.jobId});

  /// Preselected job; `null` = all jobs.
  final int? jobId;

  @override
  ConsumerState<PayoutSheet> createState() => _PayoutSheetState();
}

class _PayoutSheetState extends ConsumerState<PayoutSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _note = TextEditingController();

  late final LocalDate _today;
  late LocalDate _until;
  late LocalDate _paidOn;
  int? _jobId;

  /// Received amount typed by the user; `null` = follow the expected sum.
  int? _received;
  bool _receivedEdited = false;

  PayoutSelection? _lastSelection;
  bool _saving = false;
  bool _closing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _today = ref.read(clockProvider).today();
    _until = _today;
    _paidOn = _today;
    _jobId = widget.jobId;
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit(PayoutSelection selection) async {
    if (_saving || _closing) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await commitPendingInput();
      if (!mounted) return;
      if (!(_formKey.currentState?.validate() ?? true)) return;
      final received = _receivedEdited ? _received : selection.expectedCents;
      final payout = await ref
          .read(payoutControllerProvider.notifier)
          .create(
            until: _until,
            jobId: _jobId,
            receivedCents: received,
            paidOn: _paidOn,
            note: _note.text,
          );
      if (!mounted) return;
      unawaited(HapticFeedback.mediumImpact());
      _closing = true;
      Navigator.of(context).pop(_PayoutResult(payout, selection.count));
    } on Object catch (e, st) {
      if (e is! ChronosException) {
        unawaited(ref.read(errorLogProvider).record(e, st, context: 'payout'));
      }
      if (!mounted) return;
      final message = shiftsErrorMessage(AppLocalizations.of(context), e);
      if (message != null) setState(() => _error = message);
    } finally {
      if (mounted && !_closing) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fmt = Fmt.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = ChronosColors.of(context);
    final numbers = ChronosTextStyles.of(context);
    final jobs = ref.watch(activeJobsProvider).value ?? const <Job>[];

    final previewAsync = ref.watch(
      payoutPreviewProvider((until: _until, jobId: _jobId)),
    );
    final selection = previewAsync.value ?? _lastSelection;
    if (previewAsync.hasValue) _lastSelection = previewAsync.value;

    final expected = selection?.expectedCents ?? 0;
    final received = _receivedEdited ? _received : expected;
    final difference = received == null ? null : received - expected;
    final tenYearsAgo = LocalDate(_today.year - 10, _today.month, _today.day);
    const gap = SizedBox(height: ChronosSpace.s16);

    String differenceText(int cents) => cents > 0
        ? l10n.payoutDifferencePositive(fmt.money(cents))
        : fmt.money(cents);
    final differenceColor = difference == null || difference == 0
        ? scheme.onSurfaceVariant
        : difference > 0
        ? colors.success
        : scheme.error;

    final Widget footer;
    if (selection == null) {
      footer = const Center(child: CircularProgressIndicator());
    } else if (selection.isEmpty) {
      footer = Text(
        l10n.payoutNothingOpen,
        key: PayoutSheetKeys.nothingOpen,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      );
    } else {
      footer = Column(
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
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.error,
                  ),
                ),
              ),
            ),
          FilledButton.icon(
            key: PayoutSheetKeys.submit,
            onPressed: _saving ? null : () => unawaited(_submit(selection)),
            icon: const Icon(Icons.done_all),
            label: Text(l10n.payoutSubmit(selection.count)),
          ),
        ],
      );
    }

    return SheetFrame(
      title: l10n.payoutTitle,
      footer: footer,
      children: <Widget>[
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (jobs.length > 1) ...<Widget>[
                DropdownMenu<int>(
                  key: PayoutSheetKeys.job,
                  initialSelection: _jobId ?? _allJobs,
                  expandedInsets: EdgeInsets.zero,
                  inputDecorationTheme: theme.inputDecorationTheme,
                  requestFocusOnTap: false,
                  label: Text(l10n.editorJob),
                  onSelected: (value) {
                    if (value == null) return;
                    setState(() => _jobId = value == _allJobs ? null : value);
                  },
                  dropdownMenuEntries: <DropdownMenuEntry<int>>[
                    DropdownMenuEntry<int>(
                      value: _allJobs,
                      label: l10n.payoutAllJobs,
                      leadingIcon: const Icon(Icons.work_outline, size: 20),
                    ),
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
                ),
                gap,
              ],
              DateField(
                key: PayoutSheetKeys.until,
                label: l10n.payoutUntil,
                date: _until,
                firstDate: tenYearsAgo,
                lastDate: _today,
                onChanged: (d) => setState(() => _until = d),
              ),
              gap,
              _SummaryPanel(
                summary: selection == null
                    ? null
                    : l10n.payoutSummary(
                        selection.count,
                        fmt.hours(selection.workedMs),
                      ),
                expectedLabel: l10n.payoutExpected,
                expected: fmt.money(expected),
                valueStyle: numbers.statValue.copyWith(color: scheme.onSurface),
              ),
              gap,
              MoneyField(
                key: PayoutSheetKeys.received,
                label: l10n.payoutReceived,
                value: received,
                required: true,
                textInputAction: TextInputAction.next,
                onChanged: (cents) => setState(() {
                  _receivedEdited = true;
                  _received = cents;
                }),
              ),
              const SizedBox(height: ChronosSpace.s8),
              MergeSemantics(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ChronosSpace.s16,
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          l10n.payoutDifference,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(width: ChronosSpace.s12),
                      Expanded(
                        child: Text(
                          difference == null ? '' : differenceText(difference),
                          key: PayoutSheetKeys.difference,
                          textAlign: TextAlign.end,
                          style: numbers.amount.copyWith(
                            color: differenceColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              gap,
              DateField(
                key: PayoutSheetKeys.paidOn,
                label: l10n.payoutPaidOn,
                date: _paidOn,
                firstDate: tenYearsAgo,
                lastDate: _today,
                onChanged: (d) => setState(() => _paidOn = d),
              ),
              gap,
              TextFormField(
                key: PayoutSheetKeys.note,
                controller: _note,
                minLines: 1,
                maxLines: 3,
                maxLength: 500,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: l10n.editorNote,
                  counterText: '',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// "23 Schichten · 172,5 h" and the expected amount on a tonal panel.
class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel({
    required this.summary,
    required this.expectedLabel,
    required this.expected,
    required this.valueStyle,
  });

  final String? summary;
  final String expectedLabel;
  final String expected;
  final TextStyle valueStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: ChronosCorners.large,
      ),
      child: Padding(
        padding: const EdgeInsets.all(ChronosSpace.s16),
        child: MergeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                summary ?? '',
                key: PayoutSheetKeys.summary,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: ChronosSpace.s8),
              Text(
                expectedLabel,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              Text(expected, key: PayoutSheetKeys.expected, style: valueStyle),
            ],
          ),
        ),
      ),
    );
  }
}
