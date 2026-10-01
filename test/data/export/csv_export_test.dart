import 'package:chronos/core/local_date.dart';
import 'package:chronos/data/export/export.dart';
import 'package:flutter_test/flutter_test.dart';

const _de = CsvLabels(
  date: 'Datum',
  start: 'Start',
  end: 'Ende',
  breakMinutes: 'Pause (min)',
  hours: 'Stunden',
  rate: 'Stundenlohn',
  amount: 'Betrag',
  tips: 'Trinkgeld',
  status: 'Status',
  job: 'Job',
  note: 'Notiz',
  paid: 'Bezahlt',
  open: 'Offen',
  total: 'Summe',
);

const _en = CsvLabels(
  date: 'Date',
  start: 'Start',
  end: 'End',
  breakMinutes: 'Break (min)',
  hours: 'Hours',
  rate: 'Hourly rate',
  amount: 'Amount',
  tips: 'Tips',
  status: 'Status',
  job: 'Job',
  note: 'Note',
  paid: 'Paid',
  open: 'Unpaid',
  total: 'Total',
);

ExportRow _row({
  required LocalDate date,
  required DateTime start,
  required DateTime end,
  int breakMinutes = 0,
  int rate = 1500,
  int tips = 0,
  bool paid = false,
  String job = 'Catering Müller',
  String? note,
}) {
  final worked =
      end.difference(start).inMilliseconds - breakMinutes * 60 * 1000;
  return ExportRow(
    date: date,
    start: start,
    end: end,
    breakMs: breakMinutes * 60 * 1000,
    workedMs: worked,
    rateCentsPerHour: rate,
    amountCents: (worked * rate + 1800000) ~/ 3600000,
    tipsCents: tips,
    paid: paid,
    jobId: 1,
    jobName: job,
    note: note,
  );
}

final _rows = [
  _row(
    date: LocalDate(2026, 9, 28),
    start: DateTime(2026, 9, 28, 8),
    end: DateTime(2026, 9, 28, 16, 15),
    breakMinutes: 30,
    tips: 500,
    note: 'Aufbau; "Gala"',
  ),
  _row(
    date: LocalDate(2026, 9, 29),
    start: DateTime(2026, 9, 29, 18),
    end: DateTime(2026, 9, 30, 2),
    paid: true,
    job: 'Event Hall',
  ),
];

void main() {
  test('Excel-DE: semicolons, decimal comma, CRLF, totals (German labels)', () {
    final csv = buildCsv(_rows, const CsvOptions(labels: _de));
    expect(
      csv,
      'Datum;Start;Ende;Pause (min);Stunden;Stundenlohn;Betrag;Trinkgeld;'
      'Status;Job;Notiz\r\n'
      '28.09.2026;08:00;16:15;30;7,75;15,00;116,25;5,00;Offen;'
      'Catering Müller;"Aufbau; ""Gala"""\r\n'
      '29.09.2026;18:00;02:00;0;8,00;15,00;120,00;0,00;Bezahlt;Event Hall;'
      '\r\n'
      'Summe;;;30;15,75;;236,25;5,00;;;\r\n',
    );
  });

  test('international dialect: commas, decimal point, ISO dates (English)', () {
    final csv = buildCsv(
      _rows,
      const CsvOptions(labels: _en, dialect: CsvDialect.international),
    );
    expect(
      csv,
      'Date,Start,End,Break (min),Hours,Hourly rate,Amount,Tips,Status,Job,'
      'Note\r\n'
      '2026-09-28,08:00,16:15,30,7.75,15.00,116.25,5.00,Unpaid,'
      'Catering Müller,"Aufbau; ""Gala"""\r\n'
      '2026-09-29,18:00,02:00,0,8.00,15.00,120.00,0.00,Paid,Event Hall,\r\n'
      'Total,,,30,15.75,,236.25,5.00,,,\r\n',
    );
  });

  test('without notes and totals', () {
    final csv = buildCsv(
      _rows.take(1).toList(),
      const CsvOptions(labels: _de, includeNotes: false, includeTotals: false),
    );
    expect(
      csv,
      'Datum;Start;Ende;Pause (min);Stunden;Stundenlohn;Betrag;Trinkgeld;'
      'Status;Job\r\n'
      '28.09.2026;08:00;16:15;30;7,75;15,00;116,25;5,00;Offen;'
      'Catering Müller\r\n',
    );
  });

  test('no rows: header and zero totals', () {
    final csv = buildCsv(const [], const CsvOptions(labels: _de));
    expect(csv.split('\r\n'), [
      'Datum;Start;Ende;Pause (min);Stunden;Stundenlohn;Betrag;Trinkgeld;'
          'Status;Job;Notiz',
      'Summe;;;0;0,00;;0,00;0,00;;;',
      '',
    ]);
  });

  group('escaping', () {
    test('quotes fields with separators, quotes, line breaks and spaces', () {
      const d = CsvDialect.excelGerman;
      expect(csvField('plain', d), 'plain');
      expect(csvField('a;b', d), '"a;b"');
      expect(csvField('a,b', d), 'a,b');
      expect(csvField('a,b', CsvDialect.international), '"a,b"');
      expect(csvField('say "hi"', d), '"say ""hi"""');
      expect(csvField('line 1\nline 2', d), '"line 1\nline 2"');
      expect(csvField('cr\r\nlf', d), '"cr\r\nlf"');
      expect(csvField(' padded ', d), '" padded "');
      expect(csvField('', d), '');
    });

    test('neutralises spreadsheet formulas', () {
      const d = CsvDialect.excelGerman;
      expect(csvField('=SUM(A1:A9)', d), "'=SUM(A1:A9)");
      expect(csvField('+49 170', d), "'+49 170");
      expect(csvField('-5', d), "'-5");
      expect(csvField('@home', d), "'@home");
      expect(csvField('=1;2', d), '"\'=1;2"');
    });

    test('a note with a line break stays one record', () {
      final csv = buildCsv([
        _row(
          date: LocalDate(2026, 9, 1),
          start: DateTime(2026, 9, 1, 8),
          end: DateTime(2026, 9, 1, 9),
          note: 'Zeile 1\nZeile 2',
        ),
      ], const CsvOptions(labels: _de, includeTotals: false));
      expect(csv, endsWith(';"Zeile 1\nZeile 2"\r\n'));
      expect('\r\n'.allMatches(csv).length, 2);
    });
  });

  test('decimals are exact integer arithmetic', () {
    expect(csvDecimal(0, CsvDialect.excelGerman), '0,00');
    expect(csvDecimal(5, CsvDialect.excelGerman), '0,05');
    expect(csvDecimal(123456, CsvDialect.excelGerman), '1234,56');
    expect(csvDecimal(123456, CsvDialect.international), '1234.56');
    expect(csvDecimal(-250, CsvDialect.excelGerman), '-2,50');
  });

  test('dialect follows the locale decimal separator', () {
    expect(CsvDialect.forDecimalSeparator(','), CsvDialect.excelGerman);
    expect(CsvDialect.forDecimalSeparator('.'), CsvDialect.international);
  });
}
