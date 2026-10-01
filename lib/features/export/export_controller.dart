import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/providers.dart';
import '../../core/format.dart';
import '../../core/time.dart';
import '../../data/export/export.dart';
import '../../l10n/app_localizations.dart';
import '../../platform/share_service.dart';
import 'export_texts.dart';

/// File format of an export.
enum ExportFormat {
  /// PDF timesheet with signature lines.
  pdf,

  /// CSV table for spreadsheets.
  csv,
}

/// What to export.
final class ExportRequest {
  /// Creates a request.
  const ExportRequest({
    required this.range,
    required this.format,
    this.jobId,
    this.includeNotes = false,
    this.personName,
  });

  /// Days to export.
  final LocalDateRange range;

  /// PDF or CSV.
  final ExportFormat format;

  /// Only this job (`null` = all jobs).
  final int? jobId;

  /// Whether notes are included.
  final bool includeNotes;

  /// Name printed on the PDF timesheet.
  final String? personName;
}

/// Outcome of [ExportController.export].
final class ExportResult {
  /// Creates a result.
  const ExportResult({required this.shiftCount, this.outcome});

  /// Number of exported shifts (0 = nothing to export, nothing shared).
  final int shiftCount;

  /// What the user did with the share sheet (`null` if nothing was shared).
  final ShareOutcome? outcome;
}

/// Loads the TrueType fonts embedded in PDF timesheets.
typedef TimesheetFontLoader = Future<TimesheetFonts> Function();

Future<TimesheetFonts>? _bundledFonts;

/// Roboto from the app bundle (loaded once).
Future<TimesheetFonts> loadBundledTimesheetFonts() =>
    _bundledFonts ??= () async {
      try {
        return TimesheetFonts(
          regular: await rootBundle.load('assets/fonts/Roboto-Regular.ttf'),
          bold: await rootBundle.load('assets/fonts/Roboto-Bold.ttf'),
        );
      } on Object {
        _bundledFonts = null;
        rethrow;
      }
    }();

/// Where the PDF fonts come from (tests may override it).
final timesheetFontLoaderProvider = Provider<TimesheetFontLoader>(
  (ref) => loadBundledTimesheetFonts,
  name: 'timesheetFontLoaderProvider',
);

/// Builds export files and hands them to the share sheet.
final exportControllerProvider = NotifierProvider<ExportController, bool>(
  ExportController.new,
  name: 'exportControllerProvider',
);

/// Export action (busy while a file is generated or shared).
class ExportController extends BusyNotifier {
  /// Reads the shifts of [request], builds the PDF or CSV with texts from
  /// [l10n] / [fmt], writes it to a temporary file and opens the share
  /// sheet. Returns a result with `shiftCount` 0 (and shares nothing) if the
  /// range has no shifts.
  Future<ExportResult> export(
    ExportRequest request, {
    required AppLocalizations l10n,
    required Fmt fmt,
  }) => runBusy(() async {
    final shifts = await ref
        .read(shiftRepositoryProvider)
        .getRange(request.range, jobId: request.jobId);
    final jobs = await ref.read(jobRepositoryProvider).getJobs();
    final rows = exportRowsFromShifts(shifts, jobs: jobs, jobId: request.jobId);
    if (rows.isEmpty) return const ExportResult(shiftCount: 0);

    final share = ref.read(shareServiceProvider);
    final rangeText = exportRangeText(l10n, fmt, request.range);
    final subject = l10n.exportSubject(rangeText);

    switch (request.format) {
      case ExportFormat.csv:
        final csv = buildCsv(
          rows,
          CsvOptions(
            labels: csvLabelsFor(l10n),
            dialect: CsvDialect.forDecimalSeparator(fmt.decimalSeparator),
            includeNotes: request.includeNotes,
          ),
        );
        final file = await share.saveTextToTemp(
          exportFileName(l10n, request.range, 'csv'),
          csv,
          withByteOrderMark: true,
        );
        final outcome = await share.shareFile(
          file.path,
          mimeType: ShareMimeTypes.csv,
          subject: subject,
        );
        return ExportResult(shiftCount: rows.length, outcome: outcome);
      case ExportFormat.pdf:
        String? jobName;
        for (final job in jobs) {
          if (job.id == request.jobId) jobName = job.name;
        }
        final bytes = await buildTimesheetPdf(
          data: TimesheetData(
            rows: rows,
            period: request.range,
            jobLabel:
                jobName ??
                (rows.map((r) => r.jobId).toSet().length == 1
                    ? rows.first.jobName
                    : l10n.exportAllJobs),
            createdOn: ref.read(clockProvider).today(),
            personName: request.personName,
            includeNotes: request.includeNotes,
            showJobColumn: rows.map((r) => r.jobId).toSet().length > 1,
          ),
          labels: timesheetLabelsFor(l10n),
          format: timesheetFormatFor(l10n, fmt),
          fonts: await ref.read(timesheetFontLoaderProvider)(),
        );
        final file = await share.saveToTemp(
          exportFileName(l10n, request.range, 'pdf'),
          bytes,
        );
        final outcome = await share.shareFile(
          file.path,
          mimeType: ShareMimeTypes.pdf,
          subject: subject,
        );
        return ExportResult(shiftCount: rows.length, outcome: outcome);
    }
  });
}
