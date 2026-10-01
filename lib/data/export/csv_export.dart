import '../../core/local_date.dart';
import 'export_rows.dart';

/// Number and separator conventions of a CSV file.
enum CsvDialect {
  /// Excel with German regional settings: `;` between fields, decimal comma,
  /// dates as `30.09.2026`.
  excelGerman(separator: ';', decimalSeparator: ','),

  /// Excel/Sheets with English regional settings: `,` between fields,
  /// decimal point, ISO dates (`2026-09-30`).
  international(separator: ',', decimalSeparator: '.');

  const CsvDialect({required this.separator, required this.decimalSeparator});

  /// Field separator.
  final String separator;

  /// Decimal separator of numbers.
  final String decimalSeparator;

  /// The dialect matching a locale whose decimal separator is
  /// [decimalSeparator] (`,` → [excelGerman], anything else →
  /// [international]).
  static CsvDialect forDecimalSeparator(String decimalSeparator) =>
      decimalSeparator == ',' ? excelGerman : international;
}

/// Localized header and status texts of the CSV file.
final class CsvLabels {
  /// Creates the labels.
  const CsvLabels({
    required this.date,
    required this.start,
    required this.end,
    required this.breakMinutes,
    required this.hours,
    required this.rate,
    required this.amount,
    required this.tips,
    required this.status,
    required this.job,
    required this.note,
    required this.paid,
    required this.open,
    required this.total,
  });

  /// "Datum".
  final String date;

  /// "Start".
  final String start;

  /// "Ende".
  final String end;

  /// "Pause (min)".
  final String breakMinutes;

  /// "Stunden".
  final String hours;

  /// "Stundenlohn".
  final String rate;

  /// "Betrag".
  final String amount;

  /// "Trinkgeld".
  final String tips;

  /// "Status".
  final String status;

  /// "Job".
  final String job;

  /// "Notiz".
  final String note;

  /// Status value of a paid shift ("Bezahlt").
  final String paid;

  /// Status value of an unpaid shift ("Offen").
  final String open;

  /// Label of the totals line ("Summe").
  final String total;
}

/// What goes into the CSV file.
final class CsvOptions {
  /// Creates options.
  const CsvOptions({
    required this.labels,
    this.dialect = CsvDialect.excelGerman,
    this.includeNotes = true,
    this.includeTotals = true,
  });

  /// Header and status texts.
  final CsvLabels labels;

  /// Separators and number format.
  final CsvDialect dialect;

  /// Whether the "Notiz" column is included.
  final bool includeNotes;

  /// Whether a totals line follows the shifts.
  final bool includeTotals;
}

/// Line terminator of the CSV file (RFC 4180, what Excel writes).
const String csvLineBreak = '\r\n';

/// Builds a CSV timesheet from [rows] (one line per shift, oldest first as
/// given), with a header line and optionally a totals line.
///
/// Columns: date, start, end, break (minutes), hours (decimal, 2 places),
/// rate, amount, tips, status, job, note. Numbers carry no currency symbol
/// or grouping so spreadsheets read them as numbers. Text fields are quoted
/// when needed and protected against formula injection. Lines end with
/// CRLF; the UTF-8 byte order mark is added when the file is written.
String buildCsv(List<ExportRow> rows, CsvOptions options) {
  final l = options.labels;
  final d = options.dialect;
  final out = StringBuffer();

  void line(List<String> fields) {
    out
      ..write(fields.join(d.separator))
      ..write(csvLineBreak);
  }

  line([
    for (final label in [
      l.date,
      l.start,
      l.end,
      l.breakMinutes,
      l.hours,
      l.rate,
      l.amount,
      l.tips,
      l.status,
      l.job,
      if (options.includeNotes) l.note,
    ])
      csvField(label, d),
  ]);

  for (final row in rows) {
    line([
      _date(row.date, d),
      _time(row.start),
      _time(row.end),
      '${row.breakMinutes}',
      csvDecimal(hundredthsOfHour(row.workedMs), d),
      csvDecimal(row.rateCentsPerHour, d),
      csvDecimal(row.amountCents, d),
      csvDecimal(row.tipsCents, d),
      csvField(row.paid ? l.paid : l.open, d),
      csvField(row.jobName, d),
      if (options.includeNotes) csvField(row.note ?? '', d),
    ]);
  }

  if (options.includeTotals) {
    final totals = ExportTotals.of(rows);
    line([
      csvField(l.total, d),
      '',
      '',
      '${totals.breakMinutes}',
      csvDecimal(hundredthsOfHour(totals.workedMs), d),
      '',
      csvDecimal(totals.amountCents, d),
      csvDecimal(totals.tipsCents, d),
      '',
      '',
      if (options.includeNotes) '',
    ]);
  }
  return out.toString();
}

/// A number stored in hundredths (cents, 1/100 h) with two decimals and
/// the dialect's decimal separator: `11625` → "116,25" / "116.25".
String csvDecimal(int hundredths, CsvDialect dialect) {
  final sign = hundredths < 0 ? '-' : '';
  final abs = hundredths.abs();
  final fraction = (abs % 100).toString().padLeft(2, '0');
  return '$sign${abs ~/ 100}${dialect.decimalSeparator}$fraction';
}

/// A text field, quoted if it contains the separator, quotes, line breaks
/// or surrounding spaces. Values starting with `=`, `+`, `-`, `@`, tab or
/// carriage return get a leading apostrophe so spreadsheets do not run them
/// as formulas.
String csvField(String value, CsvDialect dialect) {
  var v = value;
  if (v.isNotEmpty && const ['=', '+', '-', '@', '\t', '\r'].contains(v[0])) {
    v = "'$v";
  }
  final needsQuotes =
      v.contains(dialect.separator) ||
      v.contains('"') ||
      v.contains('\n') ||
      v.contains('\r') ||
      v.startsWith(' ') ||
      v.endsWith(' ');
  return needsQuotes ? '"${v.replaceAll('"', '""')}"' : v;
}

String _two(int n) => n.toString().padLeft(2, '0');

String _date(LocalDate date, CsvDialect dialect) => switch (dialect) {
  CsvDialect.excelGerman => '${_two(date.day)}.${_two(date.month)}.${date.year}',
  CsvDialect.international => date.toIso8601String(),
};

String _time(DateTime local) => '${_two(local.hour)}:${_two(local.minute)}';
