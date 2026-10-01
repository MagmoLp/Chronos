import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/providers.dart';
import '../../app/theme/theme.dart';
import '../../core/format.dart';
import '../../core/local_date.dart';
import '../../domain/errors.dart';
import '../../domain/job.dart';
import '../../domain/wage_rate.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/widgets.dart';
import 'error_text.dart';
import 'jobs_page.dart' show currentRate;
import 'widgets/choice_segments.dart';
import 'widgets/job_color.dart';
import 'widgets/settings_group.dart';

/// What the job editor did (returned when it closes).
final class JobEditorResult {
  /// Creates a result.
  const JobEditorResult(this.job, {this.archivedChanged = false});

  /// The saved job.
  final Job job;

  /// Whether the job was archived or restored (the list offers Undo).
  final bool archivedChanged;
}

/// Creates ([job] `null`) or edits a job: name, colour, rounding, wage
/// history and archiving.
class JobEditorPage extends ConsumerStatefulWidget {
  /// Creates the editor.
  const JobEditorPage({super.key, this.job});

  /// The job to edit, or `null` for a new job.
  final Job? job;

  @override
  ConsumerState<JobEditorPage> createState() => _JobEditorPageState();
}

class _JobEditorPageState extends ConsumerState<JobEditorPage> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late int _colorIndex;
  late final int _initialColorIndex;
  late RoundingRule _rounding;
  int? _rateCents;
  bool _saving = false;

  bool get _isNew => widget.job == null;

  @override
  void initState() {
    super.initState();
    final job = widget.job;
    _name = TextEditingController(text: job?.name ?? '');
    _name.addListener(() => setState(() {}));
    _rounding = job?.rounding ?? RoundingRule.none;
    _colorIndex = job == null
        ? _firstUnusedColor()
        : JobColors.indexOf(job.colorArgb) ?? 0;
    _initialColorIndex = _colorIndex;
  }

  int _firstUnusedColor() {
    final used = {
      for (final j in ref.read(jobsProvider).value ?? const <Job>[])
        JobColors.indexOf(j.colorArgb),
    };
    for (var i = 0; i < ChronosColors.jobColorCount; i++) {
      if (!used.contains(i)) return i;
    }
    return 0;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool get _dirty {
    final job = widget.job;
    if (job == null) return _name.text.trim().isNotEmpty || _rateCents != null;
    return _name.text.trim() != job.name ||
        _rounding != job.rounding ||
        _colorIndex != _initialColorIndex;
  }

  /// The colour to store; an unchanged colour is kept as it is (also one
  /// outside the palette, e.g. from an old backup).
  int _colorArgb() {
    final job = widget.job;
    if (job != null && _colorIndex == _initialColorIndex) return job.colorArgb;
    return JobColors.argbFor(_colorIndex);
  }

  void _showError(Object error) {
    final l10n = AppLocalizations.of(context);
    final message = error is ChronosException
        ? chronosErrorText(l10n, error.code)
        : l10n.errorSaveFailed;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final controller = ref.read(jobsControllerProvider.notifier);
    try {
      final job = widget.job;
      final saved = job == null
          ? await controller.create(
              name: _name.text.trim(),
              centsPerHour: _rateCents!,
              colorArgb: _colorArgb(),
              rounding: _rounding,
            )
          : await controller.update(
              job.copyWith(
                name: _name.text.trim(),
                colorArgb: _colorArgb(),
                rounding: _rounding,
              ),
            );
      if (!mounted) return;
      Navigator.of(context).pop(JobEditorResult(saved));
    } on ChronosException catch (e) {
      if (!mounted || e.code == ChronosErrorCode.busy) return;
      setState(() => _saving = false);
      _showError(e);
    } on Object catch (e, st) {
      await ref.read(errorLogProvider).record(e, st, context: 'jobEditor');
      if (!mounted) return;
      setState(() => _saving = false);
      _showError(e);
    }
  }

  Future<void> _setArchived(Job job, bool archived) async {
    setState(() => _saving = true);
    try {
      final saved = await ref
          .read(jobsControllerProvider.notifier)
          .setArchived(job.id, archived);
      if (!mounted) return;
      Navigator.of(context).pop(JobEditorResult(saved, archivedChanged: true));
    } on Object catch (e, st) {
      if (e is ChronosException && e.code == ChronosErrorCode.busy) return;
      if (e is! ChronosException) {
        await ref.read(errorLogProvider).record(e, st, context: 'archiveJob');
      }
      if (!mounted) return;
      setState(() => _saving = false);
      _showError(e);
    }
  }

  Future<void> _confirmLeave() async {
    final l10n = AppLocalizations.of(context);
    final discard = await showConfirmDialog(
      context,
      title: l10n.jobsDiscardTitle,
      confirmLabel: l10n.commonDiscard,
    );
    if (discard && mounted) Navigator.of(context).pop();
  }

  String _colorName(AppLocalizations l10n, int index) => switch (index) {
    0 => l10n.jobsColorBlue,
    1 => l10n.jobsColorTeal,
    2 => l10n.jobsColorOchre,
    3 => l10n.jobsColorRaspberry,
    4 => l10n.jobsColorViolet,
    _ => l10n.jobsColorGreen,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fmt = Fmt.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final job = widget.job == null
        ? null
        : ref.watch(jobByIdProvider(widget.job!.id)).value ?? widget.job;

    return PopScope<Object?>(
      canPop: !_dirty || _saving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_confirmLeave());
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isNew ? l10n.jobsNewTitle : l10n.jobsEditTitle),
          actions: [
            Padding(
              padding: const EdgeInsetsDirectional.only(end: ChronosSpace.s8),
              child: TextButton(
                onPressed: _saving ? null : _save,
                child: Text(l10n.commonSave),
              ),
            ),
          ],
        ),
        body: Form(
          key: _form,
          child: SettingsListView(
            children: [
              const SizedBox(height: ChronosSpace.s8),
              TextFormField(
                controller: _name,
                enabled: !_saving,
                autofocus: _isNew,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                maxLength: 60,
                decoration: InputDecoration(
                  labelText: l10n.jobsName,
                  hintText: l10n.jobsNameHint,
                  counterText: '',
                ),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? l10n.errorRequired : null,
              ),
              const SizedBox(height: ChronosSpace.s24),
              Text(l10n.jobsColor, style: text.titleSmall),
              const SizedBox(height: ChronosSpace.s8),
              Wrap(
                spacing: ChronosSpace.s8,
                runSpacing: ChronosSpace.s8,
                children: [
                  for (var i = 0; i < ChronosColors.jobColorCount; i++)
                    _ColorSwatch(
                      color: context.chronosColors.jobColor(i),
                      name: _colorName(l10n, i),
                      selected: i == _colorIndex,
                      onTap: _saving
                          ? null
                          : () => setState(() => _colorIndex = i),
                    ),
                ],
              ),
              if (_isNew) ...[
                const SizedBox(height: ChronosSpace.s24),
                MoneyField(
                  label: l10n.jobsRate,
                  helperText: l10n.jobsRateNewHelp,
                  required: true,
                  allowZero: false,
                  enabled: !_saving,
                  textInputAction: TextInputAction.done,
                  onChanged: (c) => setState(() => _rateCents = c),
                ),
              ],
              const SizedBox(height: ChronosSpace.s24),
              Text(l10n.jobsRounding, style: text.titleSmall),
              const SizedBox(height: ChronosSpace.s8),
              ChoiceSegments<RoundingRule>(
                segments: [
                  ChoiceSegment(
                    value: RoundingRule.none,
                    label: l10n.jobsRoundingOff,
                  ),
                  ChoiceSegment(
                    value: RoundingRule.nearest5,
                    label: fmt.minutes(5),
                  ),
                  ChoiceSegment(
                    value: RoundingRule.nearest15,
                    label: fmt.minutes(15),
                  ),
                ],
                selected: _rounding,
                onChanged: _saving ? null : (r) => setState(() => _rounding = r),
              ),
              const SizedBox(height: ChronosSpace.s8),
              Text(
                l10n.jobsRoundingHelp,
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
              if (job != null) ...[
                _RateHistory(job: job, enabled: !_saving),
                _ArchiveSection(
                  job: job,
                  enabled: !_saving,
                  onChanged: (archived) => _setArchived(job, archived),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    required this.color,
    required this.name,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final String name;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: name,
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      excludeSemantics: true,
      onTap: onTap,
      child: Tooltip(
        message: name,
        excludeFromSemantics: true,
        child: InkResponse(
          onTap: onTap,
          radius: 24,
          customBorder: const CircleBorder(),
          child: SizedBox.square(
            dimension: ChronosLayout.minTapTarget,
            child: Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: selected
                      ? Border.all(color: scheme.onSurface, width: 2)
                      : null,
                ),
                child: SizedBox.square(
                  dimension: 36,
                  child: selected
                      ? Icon(Icons.check, size: 20, color: scheme.surface)
                      : null,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Wage history with "Neuer Lohn ab …" and delete (not the last one).
class _RateHistory extends ConsumerWidget {
  const _RateHistory({required this.job, required this.enabled});

  final Job job;
  final bool enabled;

  Future<void> _add(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final count = await showDialog<int>(
      context: context,
      builder: (_) => RateDialog(job: job),
    );
    if (count == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.jobsRateSaved(count))));
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    WageRate rate,
  ) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final controller = ref.read(jobsControllerProvider.notifier);
    try {
      await controller.deleteRate(rate.id);
      if (!context.mounted) return;
      showUndoSnackBar(
        context,
        message: l10n.jobsRateDeleted,
        onUndo: () async {
          try {
            await controller.addRate(
              rate.jobId,
              validFrom: rate.validFrom,
              centsPerHour: rate.centsPerHour,
            );
          } on ChronosException catch (e) {
            if (e.code == ChronosErrorCode.busy) return;
            messenger.showSnackBar(
              SnackBar(content: Text(chronosErrorText(l10n, e.code))),
            );
          }
        },
      );
    } on ChronosException catch (e) {
      if (e.code == ChronosErrorCode.busy) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(chronosErrorText(l10n, e.code))));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final fmt = Fmt.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final rates = ref.watch(jobRatesProvider(job.id)).value ?? const [];
    final today = ref.watch(currentDateProvider);
    final current = currentRate(rates, today);
    final canDelete = rates.length > 1;

    return SettingsGroup(
      title: l10n.jobsRateHistory,
      children: [
        for (final rate in rates)
          ListTile(
            title: Text(
              fmt.rate(rate.centsPerHour),
              style: context.chronosText.amount.copyWith(
                color: scheme.onSurface,
              ),
            ),
            subtitle: Wrap(
              spacing: ChronosSpace.s8,
              runSpacing: ChronosSpace.s4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  l10n.jobsRateFrom(
                    fmt.dateNumeric(rate.validFrom.toLocalDateTime()),
                  ),
                ),
                if (rate == current)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: scheme.secondaryContainer,
                      borderRadius: ChronosCorners.small,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: ChronosSpace.s8,
                        vertical: 2,
                      ),
                      child: Text(
                        l10n.jobsRateCurrent,
                        style: text.labelMedium?.copyWith(
                          color: scheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            trailing: canDelete
                ? IconButton(
                    tooltip: l10n.jobsRateDelete,
                    onPressed: enabled
                        ? () => _delete(context, ref, rate)
                        : null,
                    icon: const Icon(Icons.delete_outline),
                  )
                : null,
          ),
        ListTile(
          enabled: enabled,
          leading: const Icon(Icons.add),
          title: Text(l10n.jobsRateAdd),
          subtitle: canDelete ? null : Text(l10n.jobsRateDeleteLast),
          onTap: () => _add(context),
        ),
      ],
    );
  }
}

class _ArchiveSection extends ConsumerWidget {
  const _ArchiveSection({
    required this.job,
    required this.enabled,
    required this.onChanged,
  });

  final Job job;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final active = ref.watch(activeJobsProvider).value ?? const <Job>[];
    final lastActive = !job.archived && active.length <= 1;
    return SettingsGroup(
      children: [
        ListTile(
          enabled: enabled && !lastActive,
          leading: Icon(
            job.archived ? Icons.unarchive_outlined : Icons.archive_outlined,
          ),
          title: Text(job.archived ? l10n.jobsUnarchive : l10n.jobsArchive),
          subtitle: Text(
            lastActive ? l10n.jobsArchiveLastActive : l10n.jobsArchiveHelp,
          ),
          onTap: () => onChanged(!job.archived),
        ),
      ],
    );
  }
}

/// "Neuer Lohn ab …": wage, valid-from date and the option to re-price open
/// shifts from that date. Pops the number of re-priced shifts.
class RateDialog extends ConsumerStatefulWidget {
  /// Creates the dialog.
  const RateDialog({super.key, required this.job});

  /// The job.
  final Job job;

  @override
  ConsumerState<RateDialog> createState() => _RateDialogState();
}

class _RateDialogState extends ConsumerState<RateDialog> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  int? _cents;
  late LocalDate _from;
  bool _recalc = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _from = ref.read(currentDateProvider);
  }

  Future<void> _pickDate() async {
    final today = ref.read(currentDateProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: _from.toLocalDateTime(),
      firstDate: DateTime(2000),
      lastDate: today.addDays(730).toLocalDateTime(),
    );
    if (picked == null || !mounted) return;
    setState(() => _from = LocalDate.fromDateTime(picked));
  }

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final count = await ref
          .read(jobsControllerProvider.notifier)
          .addRate(
            widget.job.id,
            validFrom: _from,
            centsPerHour: _cents!,
            recalcOpenFromDate: _recalc,
          );
      if (mounted) Navigator.of(context).pop(count);
    } on Object catch (e, st) {
      if (e is ChronosException && e.code == ChronosErrorCode.busy) return;
      if (e is! ChronosException) {
        await ref.read(errorLogProvider).record(e, st, context: 'addRate');
      }
      if (!mounted) return;
      setState(() => _saving = false);
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is ChronosException
                ? chronosErrorText(l10n, e.code)
                : l10n.errorSaveFailed,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fmt = Fmt.of(context);
    return AlertDialog(
      scrollable: true,
      title: Text(l10n.jobsRateDialogTitle),
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MoneyField(
              label: l10n.jobsRate,
              required: true,
              allowZero: false,
              autofocus: true,
              enabled: !_saving,
              onChanged: (c) => _cents = c,
            ),
            const SizedBox(height: ChronosSpace.s16),
            InputDecorator(
              decoration: InputDecoration(labelText: l10n.jobsRateValidFrom),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  onPressed: _saving ? null : _pickDate,
                  icon: const Icon(Icons.event_outlined),
                  label: Text(fmt.dateMedium(_from.toLocalDateTime())),
                ),
              ),
            ),
            const SizedBox(height: ChronosSpace.s8),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _recalc,
              onChanged: _saving
                  ? null
                  : (v) => setState(() => _recalc = v ?? false),
              title: Text(l10n.jobsRateRecalc),
              subtitle: Text(l10n.jobsRateRecalcHelp),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(l10n.commonSave),
        ),
      ],
    );
  }
}
