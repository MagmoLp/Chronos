import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/providers.dart';
import '../../app/theme/theme.dart';
import '../../core/format.dart';
import '../../core/local_date.dart';
import '../../core/time.dart';
import '../../data/export/export.dart';
import '../../domain/errors.dart';
import '../../domain/job.dart';
import '../../l10n/app_localizations.dart';
import '../../platform/share_service.dart';
import 'export_controller.dart';
import 'export_texts.dart';

/// Opens the export sheet (PDF timesheet / CSV), optionally preset to
/// [range] and [jobId].
Future<void> showExportSheet(
  BuildContext context, {
  LocalDateRange? range,
  int? jobId,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  useSafeArea: true,
  builder: (_) => ExportSheet(initialRange: range, initialJobId: jobId),
);

/// Content of the export sheet: range, job, format, options and "Teilen".
class ExportSheet extends ConsumerStatefulWidget {
  /// Creates the sheet content.
  const ExportSheet({super.key, this.initialRange, this.initialJobId});

  /// Preselected range (default: this month).
  final LocalDateRange? initialRange;

  /// Preselected job (default: all jobs).
  final int? initialJobId;

  @override
  ConsumerState<ExportSheet> createState() => _ExportSheetState();
}

class _ExportSheetState extends ConsumerState<ExportSheet> {
  late LocalDateRange _range;
  late ExportRangePreset _preset;
  int? _jobId;
  ExportFormat _format = ExportFormat.pdf;
  bool _includeNotes = false;
  final TextEditingController _name = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    final today = ref.read(currentDateProvider);
    _range = widget.initialRange ?? LocalDateRange.monthOf(today);
    _preset = ExportRangePreset.match(_range, today);
    _jobId = widget.initialJobId;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _selectPreset(ExportRangePreset preset) async {
    final today = ref.read(currentDateProvider);
    final range = preset.rangeFor(today);
    if (range != null) {
      setState(() {
        _preset = preset;
        _range = range;
        _error = null;
      });
      return;
    }
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: today.addDays(366).toLocalDateTime(),
      initialDateRange: DateTimeRange(
        start: _range.start.toLocalDateTime(),
        end: _range.endInclusive.toLocalDateTime(),
      ),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (!mounted || picked == null) return;
    final start = LocalDate.fromDateTime(picked.start);
    final end = LocalDate.fromDateTime(picked.end);
    setState(() {
      _preset = ExportRangePreset.custom;
      _range = LocalDateRange(start, end.addDays(1));
      _error = null;
    });
  }

  Future<void> _share() async {
    final l10n = AppLocalizations.of(context);
    final fmt = Fmt.of(context);
    final navigator = Navigator.of(context);
    setState(() => _error = null);
    try {
      final result = await ref
          .read(exportControllerProvider.notifier)
          .export(
            ExportRequest(
              range: _range,
              format: _format,
              jobId: _jobId,
              includeNotes: _includeNotes,
              personName: _format == ExportFormat.pdf ? _name.text : null,
            ),
            l10n: l10n,
            fmt: fmt,
          );
      if (!mounted) return;
      if (result.shiftCount == 0) {
        setState(() => _error = l10n.exportEmpty);
      } else if (result.outcome != ShareOutcome.dismissed) {
        navigator.pop();
      }
    } on ChronosException catch (e) {
      if (e.code == ChronosErrorCode.busy || !mounted) return;
      setState(() => _error = l10n.exportFailed);
    } on Object catch (e, st) {
      final log = ref.read(errorLogProvider);
      if (mounted) setState(() => _error = l10n.exportFailed);
      await log.record(e, st, context: 'export');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fmt = Fmt.of(context);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final busy = ref.watch(exportControllerProvider);
    final jobs = ref.watch(jobsProvider).value ?? const <Job>[];
    final shifts = ref.watch(shiftsInRangeProvider(_range));
    final rows = shifts.whenData(
      (list) => exportRowsFromShifts(list, jobs: jobs, jobId: _jobId),
    );
    final totals = rows.value == null ? null : ExportTotals.of(rows.value!);
    final empty = totals != null && totals.isEmpty;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          ChronosSpace.s24,
          0,
          ChronosSpace.s24,
          ChronosSpace.s24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              header: true,
              child: Text(l10n.exportTitle, style: text.headlineSmall),
            ),
            const SizedBox(height: ChronosSpace.s24),
            _Label(l10n.exportRange),
            Wrap(
              spacing: ChronosSpace.s8,
              runSpacing: ChronosSpace.s8,
              children: [
                for (final preset in ExportRangePreset.values)
                  ChoiceChip(
                    label: Text(switch (preset) {
                      ExportRangePreset.thisWeek => l10n.exportRangeThisWeek,
                      ExportRangePreset.thisMonth => l10n.exportRangeThisMonth,
                      ExportRangePreset.lastMonth => l10n.exportRangeLastMonth,
                      ExportRangePreset.custom => l10n.exportRangeCustom,
                    }),
                    avatar: preset == ExportRangePreset.custom
                        ? const Icon(Icons.date_range_outlined)
                        : null,
                    selected: _preset == preset,
                    onSelected: busy ? null : (_) => _selectPreset(preset),
                  ),
              ],
            ),
            const SizedBox(height: ChronosSpace.s8),
            Text(
              exportRangeText(l10n, fmt, _range),
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            if (jobs.length > 1) ...[
              const SizedBox(height: ChronosSpace.s24),
              DropdownButtonFormField<int?>(
                initialValue: _jobId,
                isExpanded: true,
                decoration: InputDecoration(labelText: l10n.exportJob),
                items: [
                  DropdownMenuItem<int?>(child: Text(l10n.exportAllJobs)),
                  for (final job in jobs)
                    DropdownMenuItem<int?>(
                      value: job.id,
                      child: Text(job.name, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: busy
                    ? null
                    : (id) => setState(() {
                        _jobId = id;
                        _error = null;
                      }),
              ),
            ],
            const SizedBox(height: ChronosSpace.s24),
            _Label(l10n.exportFormat),
            SegmentedButton<ExportFormat>(
              segments: [
                ButtonSegment(
                  value: ExportFormat.pdf,
                  label: Text(l10n.exportFormatPdf),
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                ),
                ButtonSegment(
                  value: ExportFormat.csv,
                  label: Text(l10n.exportFormatCsv),
                  icon: const Icon(Icons.table_chart_outlined),
                ),
              ],
              selected: {_format},
              onSelectionChanged: busy
                  ? null
                  : (s) => setState(() => _format = s.single),
            ),
            const SizedBox(height: ChronosSpace.s8),
            Text(
              _format == ExportFormat.pdf
                  ? l10n.exportFormatPdfHelp
                  : l10n.exportFormatCsvHelp,
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            if (_format == ExportFormat.pdf) ...[
              const SizedBox(height: ChronosSpace.s16),
              TextField(
                controller: _name,
                enabled: !busy,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: l10n.exportName,
                  helperText: l10n.exportNameHelp,
                ),
              ),
            ],
            const SizedBox(height: ChronosSpace.s8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.exportIncludeNotes),
              value: _includeNotes,
              onChanged: busy ? null : (v) => setState(() => _includeNotes = v),
            ),
            const SizedBox(height: ChronosSpace.s16),
            _Summary(totals: totals, loading: rows.isLoading && totals == null),
            if (_error != null && !(empty && _error == l10n.exportEmpty)) ...[
              const SizedBox(height: ChronosSpace.s8),
              Text(
                _error!,
                style: text.bodyMedium?.copyWith(color: scheme.error),
              ),
            ],
            const SizedBox(height: ChronosSpace.s16),
            FilledButton.icon(
              style: ChronosButtonStyles.primary(context),
              onPressed: busy || empty || totals == null ? null : _share,
              icon: busy
                  ? SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: scheme.onSurface,
                        semanticsLabel: l10n.exportPreparing,
                      ),
                    )
                  : const Icon(Icons.share_outlined),
              label: Text(busy ? l10n.exportPreparing : l10n.commonShare),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: ChronosSpace.s8),
    child: Text(
      text,
      style: Theme.of(context).textTheme.titleSmall
          ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
    ),
  );
}

/// "12 Schichten · 82,5 h · 1.237,50 €" or the empty-range message.
class _Summary extends StatelessWidget {
  const _Summary({required this.totals, required this.loading});

  final ExportTotals? totals;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fmt = Fmt.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final t = totals;
    if (t == null) {
      return loading
          ? const LinearProgressIndicator()
          : const SizedBox.shrink();
    }
    if (t.isEmpty) {
      return Row(
        children: [
          Icon(Icons.info_outline, color: scheme.onSurfaceVariant),
          const SizedBox(width: ChronosSpace.s12),
          Expanded(
            child: Text(
              l10n.exportEmpty,
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      );
    }
    return Text(
      l10n.exportSummary(
        t.count,
        fmt.hours(t.workedMs),
        fmt.money(t.amountCents),
      ),
      style: context.chronosText.bodyNumbers.copyWith(color: scheme.onSurface),
    );
  }
}
