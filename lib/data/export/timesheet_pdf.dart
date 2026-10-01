import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/local_date.dart';
import '../../core/time.dart';
import 'export_rows.dart';

/// Localized texts of the PDF timesheet.
final class TimesheetLabels {
  /// Creates the labels.
  const TimesheetLabels({
    required this.title,
    required this.name,
    required this.job,
    required this.period,
    required this.date,
    required this.start,
    required this.end,
    required this.breakTime,
    required this.hours,
    required this.rate,
    required this.amount,
    required this.note,
    required this.total,
    required this.signatureEmployee,
    required this.signatureEmployer,
    required this.createdOn,
    required this.pageOf,
  });

  /// "Stundenzettel".
  final String title;

  /// "Name".
  final String name;

  /// "Job".
  final String job;

  /// "Zeitraum".
  final String period;

  /// Column "Datum".
  final String date;

  /// Column "Start".
  final String start;

  /// Column "Ende".
  final String end;

  /// Column "Pause".
  final String breakTime;

  /// Column "Stunden".
  final String hours;

  /// Column "Lohn".
  final String rate;

  /// Column "Betrag".
  final String amount;

  /// Column "Notiz".
  final String note;

  /// Label of the sums line ("Summe").
  final String total;

  /// Caption under the employee's signature line.
  final String signatureEmployee;

  /// Caption under the employer's signature line.
  final String signatureEmployer;

  /// Footer text for the creation date: "Erstellt am {date} mit Chronos".
  final String Function(String date) createdOn;

  /// Page footer: "Seite {page} von {count}".
  final String Function(int page, int count) pageOf;
}

/// Formatters for the values in the PDF (locale-aware, supplied by the UI).
final class TimesheetFormat {
  /// Creates the formatters.
  const TimesheetFormat({
    required this.date,
    required this.rowDate,
    required this.time,
    required this.hours,
    required this.minutes,
    required this.money,
  });

  /// A full date ("30.09.2026"), for the period and the creation date.
  final String Function(LocalDate date) date;

  /// The date in a table row ("Mi 30.09.").
  final String Function(LocalDate date) rowDate;

  /// A local time of day ("08:00" / "8:00 AM").
  final String Function(DateTime local) time;

  /// Worked time as decimal hours ("7,75").
  final String Function(int ms) hours;

  /// Whole minutes with unit ("30 min").
  final String Function(int minutes) minutes;

  /// Money ("116,25 €").
  final String Function(int cents) money;
}

/// TrueType fonts embedded in the PDF (the PDF base fonts cannot show "€"
/// or characters outside Latin-1).
final class TimesheetFonts {
  /// Creates the font set.
  const TimesheetFonts({required this.regular, required this.bold});

  /// Regular weight (e.g. Roboto-Regular.ttf).
  final ByteData regular;

  /// Bold weight (e.g. Roboto-Bold.ttf).
  final ByteData bold;
}

/// Content of one timesheet.
final class TimesheetData {
  /// Creates the content.
  const TimesheetData({
    required this.rows,
    required this.period,
    required this.jobLabel,
    required this.createdOn,
    this.personName,
    this.includeNotes = false,
    this.showJobColumn = false,
  });

  /// The shifts, oldest first.
  final List<ExportRow> rows;

  /// The exported date range.
  final LocalDateRange period;

  /// Job name, or "Alle Jobs".
  final String jobLabel;

  /// Date the file was created.
  final LocalDate createdOn;

  /// Name of the person; `null` or blank leaves a line to fill in by hand.
  final String? personName;

  /// Whether a note column is added.
  final bool includeNotes;

  /// Whether a job column is added (export of several jobs).
  final bool showJobColumn;
}

/// Builds an A4 PDF timesheet: title, name/job/period header, a table with
/// date, start, end, break, hours, rate and amount (plus optional job and
/// note columns), a sums line, signature lines and page numbers.
///
/// Pass [fonts] in production so "€" and umlauts render; without it the
/// PDF base fonts are used (tests only). [compress] = false keeps the
/// content streams readable (tests).
Future<Uint8List> buildTimesheetPdf({
  required TimesheetData data,
  required TimesheetLabels labels,
  required TimesheetFormat format,
  TimesheetFonts? fonts,
  bool compress = true,
}) {
  final theme = fonts == null
      ? pw.ThemeData.base()
      : pw.ThemeData.withFont(
          base: pw.Font.ttf(fonts.regular),
          bold: pw.Font.ttf(fonts.bold),
        );
  final doc = pw.Document(
    compress: compress,
    theme: theme,
    title: labels.title,
    creator: 'Chronos',
    producer: 'Chronos',
  );
  final totals = ExportTotals.of(data.rows);
  final period =
      '${format.date(data.period.start)} – '
      '${format.date(data.period.endInclusive)}';

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(
        18 * PdfPageFormat.mm,
        16 * PdfPageFormat.mm,
        18 * PdfPageFormat.mm,
        14 * PdfPageFormat.mm,
      ),
      maxPages: 1000,
      footer: (context) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 8),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              labels.createdOn(format.date(data.createdOn)),
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
            ),
            pw.Text(
              labels.pageOf(context.pageNumber, context.pagesCount),
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
            ),
          ],
        ),
      ),
      build: (context) => [
        pw.Text(
          labels.title,
          style: const pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 12),
        _header(labels, data, period),
        pw.SizedBox(height: 16),
        _table(labels, format, data, totals),
        pw.SizedBox(height: 48),
        _signatures(labels),
      ],
    ),
  );
  return doc.save();
}

pw.Widget _header(TimesheetLabels labels, TimesheetData data, String period) {
  final name = data.personName?.trim() ?? '';
  pw.TableRow row(String label, pw.Widget value) => pw.TableRow(
    verticalAlignment: pw.TableCellVerticalAlignment.bottom,
    children: [
      pw.Padding(
        padding: const pw.EdgeInsets.only(right: 12, bottom: 4),
        child: pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
      ),
      pw.Padding(padding: const pw.EdgeInsets.only(bottom: 4), child: value),
    ],
  );
  const valueStyle = pw.TextStyle(fontSize: 11);
  return pw.Table(
    columnWidths: const {
      0: pw.IntrinsicColumnWidth(),
      1: pw.FlexColumnWidth(),
    },
    children: [
      row(
        labels.name,
        name.isEmpty
            ? pw.Container(
                height: 14,
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.grey600, width: 0.5),
                  ),
                ),
              )
            : pw.Text(name, style: valueStyle),
      ),
      row(labels.job, pw.Text(data.jobLabel, style: valueStyle)),
      row(labels.period, pw.Text(period, style: valueStyle)),
    ],
  );
}

enum _Col { date, start, end, breakTime, hours, rate, amount, job, note }

pw.Widget _table(
  TimesheetLabels labels,
  TimesheetFormat format,
  TimesheetData data,
  ExportTotals totals,
) {
  final columns = [
    _Col.date,
    _Col.start,
    _Col.end,
    _Col.breakTime,
    _Col.hours,
    _Col.rate,
    _Col.amount,
    if (data.showJobColumn) _Col.job,
    if (data.includeNotes) _Col.note,
  ];

  bool numeric(_Col c) => switch (c) {
    _Col.breakTime || _Col.hours || _Col.rate || _Col.amount => true,
    _ => false,
  };

  pw.FlexColumnWidth width(_Col c) => pw.FlexColumnWidth(switch (c) {
    _Col.date => 2.1,
    _Col.start => 1.25,
    _Col.end => 1.5,
    _Col.breakTime => 1.2,
    _Col.hours => 1.2,
    _Col.rate => 1.5,
    _Col.amount => 1.6,
    _Col.job => 2,
    _Col.note => 2.6,
  });

  String header(_Col c) => switch (c) {
    _Col.date => labels.date,
    _Col.start => labels.start,
    _Col.end => labels.end,
    _Col.breakTime => labels.breakTime,
    _Col.hours => labels.hours,
    _Col.rate => labels.rate,
    _Col.amount => labels.amount,
    _Col.job => labels.job,
    _Col.note => labels.note,
  };

  String value(_Col c, ExportRow r) => switch (c) {
    _Col.date => format.rowDate(r.date),
    _Col.start => format.time(r.start),
    _Col.end => '${format.time(r.end)}${r.endsNextDay ? ' +1' : ''}',
    _Col.breakTime => r.breakMinutes == 0 ? '–' : format.minutes(r.breakMinutes),
    _Col.hours => format.hours(r.workedMs),
    _Col.rate => format.money(r.rateCentsPerHour),
    _Col.amount => format.money(r.amountCents),
    _Col.job => r.jobName,
    _Col.note => r.note ?? '',
  };

  String total(_Col c) => switch (c) {
    _Col.date => labels.total,
    _Col.breakTime =>
      totals.breakMinutes == 0 ? '–' : format.minutes(totals.breakMinutes),
    _Col.hours => format.hours(totals.workedMs),
    _Col.amount => format.money(totals.amountCents),
    _ => '',
  };

  pw.Widget cell(String text, _Col c, {bool bold = false, double size = 9}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
        child: pw.Text(
          text,
          textAlign: numeric(c) ? pw.TextAlign.right : pw.TextAlign.left,
          style: pw.TextStyle(
            fontSize: size,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      );

  const line = pw.BorderSide(color: PdfColors.grey400, width: 0.5);
  return pw.Table(
    columnWidths: {
      for (var i = 0; i < columns.length; i++) i: width(columns[i]),
    },
    border: const pw.TableBorder(horizontalInside: line, bottom: line),
    children: [
      pw.TableRow(
        repeat: true,
        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
        children: [
          for (final c in columns) cell(header(c), c, bold: true, size: 8.5),
        ],
      ),
      for (final row in data.rows)
        pw.TableRow(children: [for (final c in columns) cell(value(c, row), c)]),
      pw.TableRow(
        decoration: const pw.BoxDecoration(
          border: pw.Border(
            top: pw.BorderSide(color: PdfColors.grey800, width: 1),
          ),
        ),
        children: [for (final c in columns) cell(total(c), c, bold: true)],
      ),
    ],
  );
}

pw.Widget _signatures(TimesheetLabels labels) {
  pw.Widget block(String caption) => pw.Expanded(
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          height: 0.7,
          color: PdfColors.grey800,
          margin: const pw.EdgeInsets.only(bottom: 4),
        ),
        pw.Text(
          caption,
          style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700),
        ),
      ],
    ),
  );
  return pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      block(labels.signatureEmployee),
      pw.SizedBox(width: 32),
      block(labels.signatureEmployer),
    ],
  );
}
