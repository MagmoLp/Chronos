import 'dart:io';
import 'dart:typed_data';

import 'package:chronos/core/local_date.dart';
import 'package:chronos/core/time.dart';
import 'package:chronos/data/export/export.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';

import 'pdf_text.dart';

ByteData _font(String name) =>
    ByteData.sublistView(File('assets/fonts/$name').readAsBytesSync());

final _fonts = TimesheetFonts(
  regular: _font('Roboto-Regular.ttf'),
  bold: _font('Roboto-Bold.ttf'),
);

String _two(int n) => n.toString().padLeft(2, '0');

final _format = TimesheetFormat(
  date: (d) => '${_two(d.day)}.${_two(d.month)}.${d.year}',
  rowDate: (d) => '${_two(d.day)}.${_two(d.month)}.',
  time: (t) => '${_two(t.hour)}:${_two(t.minute)}',
  hours: (ms) => csvDecimal(hundredthsOfHour(ms), CsvDialect.excelGerman),
  minutes: (m) => '$m min',
  money: (c) => '${csvDecimal(c, CsvDialect.excelGerman)} €',
);

final _labels = TimesheetLabels(
  title: 'Stundenzettel',
  name: 'Name',
  job: 'Job',
  period: 'Zeitraum',
  date: 'Datum',
  start: 'Start',
  end: 'Ende',
  breakTime: 'Pause',
  hours: 'Stunden',
  rate: 'Lohn',
  amount: 'Betrag',
  note: 'Notiz',
  total: 'Summe',
  signatureEmployee: 'Datum, Unterschrift Arbeitnehmerin',
  signatureEmployer: 'Datum, Unterschrift Arbeitgeber',
  createdOn: (d) => 'Erstellt am $d mit Chronos',
  pageOf: (p, n) => 'Seite $p von $n',
);

ExportRow _row(int day, {int startHour = 8, int hours = 8, String? note}) {
  final start = DateTime(2026, 9, day, startHour);
  final end = DateTime(2026, 9, day, startHour + hours);
  final worked = end.difference(start).inMilliseconds - 30 * 60000;
  return ExportRow(
    date: LocalDate(2026, 9, day),
    start: start,
    end: end,
    breakMs: 30 * 60000,
    workedMs: worked,
    rateCentsPerHour: 1550,
    amountCents: (worked * 1550 + 1800000) ~/ 3600000,
    tipsCents: 0,
    paid: false,
    jobId: 1,
    jobName: 'Café Müller',
    note: note,
  );
}

TimesheetData _data(List<ExportRow> rows, {String? name, bool notes = false}) =>
    TimesheetData(
      rows: rows,
      period: LocalDateRange.month(2026, 9),
      jobLabel: 'Café Müller',
      createdOn: LocalDate(2026, 9, 30),
      personName: name,
      includeNotes: notes,
    );

void main() {
  test('Roboto covers €, umlauts and ß', () {
    for (final data in [_fonts.regular, _fonts.bold]) {
      final glyphs = TtfParser(data).charToGlyphIndexMap;
      for (final char in '€äöüÄÖÜß–'.runes) {
        expect(glyphs, contains(char), reason: String.fromCharCode(char));
      }
    }
  });

  test(
    'builds an A4 timesheet with header, table, sums and signatures',
    () async {
      final bytes = await buildTimesheetPdf(
        data: _data(
          [_row(28, note: 'Aufbau'), _row(29, startHour: 18)],
          name: 'Jörg Weiß',
          notes: true,
        ),
        labels: _labels,
        format: _format,
        fonts: _fonts,
        compress: false,
      );
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
      expect(pdfPageCount(bytes), 1);
      // A4 in points.
      expect(String.fromCharCodes(bytes), contains('595.27'));

      final text = pdfTextRuns(bytes);
      for (final word in [
        'Stundenzettel',
        'Jörg',
        'Weiß',
        'Café',
        'Müller',
        '01.09.2026',
        '30.09.2026',
        'Datum',
        'Start',
        'Ende',
        'Pause',
        'Stunden',
        'Lohn',
        'Betrag',
        'Notiz',
        'Aufbau',
        '28.09.',
        '08:00',
        '16:00',
        '02:00',
        '+1',
        '7,50',
        '15,50',
        '116,25',
        '€',
        'Summe',
        '15,00',
        '232,50',
        'Unterschrift',
        'Arbeitgeber',
        'Seite',
      ]) {
        expect(text, contains(word), reason: word);
      }
    },
  );

  test(
    'without a name leaves a line to fill in; long lists get more pages',
    () async {
      final rows = [for (var i = 0; i < 90; i++) _row(1 + i % 28)];
      final bytes = await buildTimesheetPdf(
        data: _data(rows),
        labels: _labels,
        format: _format,
        fonts: _fonts,
        compress: false,
      );
      expect(pdfPageCount(bytes), greaterThan(1));
      final text = pdfTextRuns(bytes);
      expect(text, isNot(contains('Notiz')));
      // Header row repeats on every page.
      expect(
        text.where((t) => t == 'Betrag').length,
        greaterThanOrEqualTo(pdfPageCount(bytes)),
      );
    },
  );

  test('compressed output is produced and smaller', () async {
    final data = _data([_row(28)]);
    final compressed = await buildTimesheetPdf(
      data: data,
      labels: _labels,
      format: _format,
      fonts: _fonts,
    );
    final plain = await buildTimesheetPdf(
      data: data,
      labels: _labels,
      format: _format,
      fonts: _fonts,
      compress: false,
    );
    expect(compressed, isNotEmpty);
    expect(compressed.length, lessThan(plain.length));
  });
}
