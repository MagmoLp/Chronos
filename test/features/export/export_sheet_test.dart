import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:chronos/core/format.dart';
import 'package:chronos/core/local_date.dart';
import 'package:chronos/core/time.dart';
import 'package:chronos/data/export/export.dart';
import 'package:chronos/features/export/export_controller.dart';
import 'package:chronos/features/export/export_sheet.dart';
import 'package:chronos/features/export/export_texts.dart';
import 'package:chronos/platform/share_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../data/export/pdf_text.dart';
import '../../support/feature_harness.dart';
import '../insights/seed.dart';

final _de = l10nFor(const Locale('de'));
final _fmt = Fmt(const Locale('de'));

/// A page with a button that opens the export sheet.
class _Host extends StatelessWidget {
  const _Host({this.range, this.jobId});

  final LocalDateRange? range;
  final int? jobId;

  @override
  Widget build(BuildContext context) => Center(
    child: FilledButton(
      onPressed: () => showExportSheet(context, range: range, jobId: jobId),
      child: const Text('open'),
    ),
  );
}

/// Catering: Mon 28 Sep 8–16 (30 min break, 5 € tips, note), Tue 29 Sep
/// 8–12 paid; Aug 15 8–16.
Future<void> _seed(ProviderHarness h) async {
  final job = await h.job(name: 'Café Müller');
  await addShift(
    h,
    job,
    LocalDate(2026, 9, 28),
    breakMinutes: 30,
    tips: 500,
    note: 'Aufbau; "Gala"',
  );
  await addShift(h, job, LocalDate(2026, 9, 29), end: 12, paid: true);
  await addShift(h, job, LocalDate(2026, 8, 15));
}

Future<FeatureHarness> _open(
  WidgetTester tester, {
  LocalDateRange? range,
  int? jobId,
  FutureOr<void> Function(ProviderHarness h) seed = _seed,
  TestConfig config = const TestConfig(size: TestScreens.phoneLarge),
}) async {
  final f = await pumpFeature(
    tester,
    _Host(range: range, jobId: jobId),
    wrapInScaffold: true,
    seed: seed,
    config: config,
  );
  await tester.tap(find.text('open'));
  await settleData(tester);
  expect(find.byType(ExportSheet), findsOneWidget);
  return f;
}

Future<void> _share(WidgetTester tester, FeatureHarness f) async {
  await tapVisible(tester, find.text(_de.commonShare));
  await pumpUntil(tester, () => f.share.sharedFiles.isNotEmpty);
}

void main() {
  testWidgets('defaults to this month, PDF, summary of the shifts', (
    tester,
  ) async {
    await _open(tester);
    expect(find.text('01.09.2026 – 30.09.2026'), findsOneWidget);
    final chip = tester.widget<ChoiceChip>(
      find.ancestor(
        of: find.text(_de.exportRangeThisMonth),
        matching: find.byType(ChoiceChip),
      ),
    );
    expect(chip.selected, isTrue);
    expect(
      find.text(_de.exportSummary(2, _fmt.hours(41400000), _fmt.money(17250))),
      findsOneWidget,
    );
    // One job: no job selector.
    expect(find.text(_de.exportJob), findsNothing);
    expect(find.text(_de.exportFormatPdfHelp), findsOneWidget);
  });

  testWidgets('shares a CSV (Excel-DE, BOM, notes) and closes', (tester) async {
    final f = await _open(tester);
    await tester.tap(find.text(_de.exportFormatCsv));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text(_de.exportIncludeNotes));
    await tester.pumpAndSettle();
    await _share(tester, f);

    final shared = f.share.sharedFiles.single;
    expect(shared.mimeType, ShareMimeTypes.csv);
    expect(
      shared.path,
      endsWith('chronos_stundenzettel_2026-09-01_2026-09-30.csv'),
    );
    expect(shared.subject, _de.exportSubject('01.09.2026 – 30.09.2026'));
    final bytes = (await tester.runAsync(
      () => File(shared.path).readAsBytes(),
    ))!;
    expect(bytes.take(3), [0xEF, 0xBB, 0xBF]);
    final csv = utf8.decode(bytes.skip(3).toList());
    expect(
      csv,
      'Datum;Start;Ende;Pause (min);Stunden;Stundenlohn;Betrag;Trinkgeld;'
      'Status;Job;Notiz\r\n'
      '28.09.2026;08:00;16:00;30;7,50;15,00;112,50;5,00;Offen;Café Müller;'
      '"Aufbau; ""Gala"""\r\n'
      '29.09.2026;08:00;12:00;0;4,00;15,00;60,00;0,00;Bezahlt;Café Müller;'
      '\r\n'
      'Summe;;;30;11,50;;172,50;5,00;;;\r\n',
    );
    expect(find.byType(ExportSheet), findsNothing);
  });

  testWidgets('English UI shares an international CSV without notes', (
    tester,
  ) async {
    final f = await _open(
      tester,
      config: const TestConfig(
        locale: Locale('en'),
        size: TestScreens.phoneLarge,
      ),
    );
    final en = l10nFor(const Locale('en'));
    await tester.tap(find.text(en.exportFormatCsv));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text(en.commonShare));
    await pumpUntil(tester, () => f.share.sharedFiles.isNotEmpty);
    final path = f.share.sharedFiles.single.path;
    final bytes = (await tester.runAsync(() => File(path).readAsBytes()))!;
    final csv = utf8.decode(bytes.skip(3).toList());
    expect(
      csv.split('\r\n').first,
      'Date,Start,End,Break (min),Hours,Hourly rate,Amount,Tips,Status,Job',
    );
    expect(
      csv,
      contains('2026-09-28,08:00,16:00,30,7.50,15.00,112.50,5.00,Unpaid,'),
    );
  });

  testWidgets('shares a PDF timesheet with name, job and totals', (
    tester,
  ) async {
    final f = await _open(tester);
    await tester.enterText(
      find.widgetWithText(TextField, _de.exportName),
      'Jörg Weiß',
    );
    await tester.pumpAndSettle();
    await _share(tester, f);

    final shared = f.share.sharedFiles.single;
    expect(shared.mimeType, ShareMimeTypes.pdf);
    expect(shared.path, endsWith('.pdf'));
    final bytes = (await tester.runAsync(
      () => File(shared.path).readAsBytes(),
    ))!;
    expect(latin1.decode(bytes.take(5).toList()), '%PDF-');
    expect(bytes.length, greaterThan(5000));
    expect(find.byType(ExportSheet), findsNothing);
  });

  testWidgets('PDF content (uncompressed build with the sheet texts)', (
    tester,
  ) async {
    // Same texts/format as the sheet, built directly to read the text.
    final fonts = (await tester.runAsync(
      () => Future.value(
        TimesheetFonts(
          regular: ByteData.sublistView(
            File('assets/fonts/Roboto-Regular.ttf').readAsBytesSync(),
          ),
          bold: ByteData.sublistView(
            File('assets/fonts/Roboto-Bold.ttf').readAsBytesSync(),
          ),
        ),
      ),
    ))!;
    final start = DateTime(2026, 9, 28, 8);
    final bytes = (await tester.runAsync(
      () => buildTimesheetPdf(
        data: TimesheetData(
          rows: [
            ExportRow(
              date: LocalDate(2026, 9, 28),
              start: start,
              end: DateTime(2026, 9, 28, 16),
              breakMs: 30 * 60000,
              workedMs: 7 * 3600000 + 30 * 60000,
              rateCentsPerHour: 1500,
              amountCents: 11250,
              tipsCents: 0,
              paid: false,
              jobId: 1,
              jobName: 'Café Müller',
            ),
          ],
          period: LocalDateRange.month(2026, 9),
          jobLabel: 'Café Müller',
          createdOn: LocalDate(2026, 9, 30),
        ),
        labels: timesheetLabelsFor(_de),
        format: timesheetFormatFor(_de, _fmt),
        fonts: fonts,
        compress: false,
      ),
    ))!;
    final text = pdfTextRuns(bytes);
    for (final word in [
      'Stundenzettel',
      'Café',
      'Müller',
      '28.09.2026',
      '08:00',
      '16:00',
      '30',
      '7,50',
      '112,50',
      '€',
      'Summe',
      'Unterschrift',
      'Arbeitgeber:in',
    ]) {
      expect(text, contains(word), reason: word);
    }
  });

  testWidgets('range presets', (tester) async {
    await _open(tester);
    await tester.tap(find.text(_de.exportRangeThisWeek));
    await settleData(tester);
    expect(find.text('28.09.2026 – 04.10.2026'), findsOneWidget);
    await tester.tap(find.text(_de.exportRangeLastMonth));
    await settleData(tester);
    expect(find.text('01.08.2026 – 31.08.2026'), findsOneWidget);
    expect(
      find.text(
        _de.exportSummary(1, _fmt.hours(8 * 3600000), _fmt.money(12000)),
      ),
      findsOneWidget,
    );
  });

  testWidgets('no shifts: friendly message, share disabled', (tester) async {
    await _open(
      tester,
      seed: (h) async {
        await h.job();
      },
    );
    expect(find.text(_de.exportEmpty), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text(_de.commonShare),
        matching: find.byWidgetPredicate((w) => w is FilledButton),
      ),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('job selector with several jobs filters the export', (
    tester,
  ) async {
    late int barId;
    final f = await _open(
      tester,
      seed: (h) async {
        await _seed(h);
        final bar = await h.job(name: 'Bar', centsPerHour: 1200);
        barId = bar.id;
        await addShift(h, bar, LocalDate(2026, 9, 26), start: 18, end: 22);
      },
    );
    expect(find.text(_de.exportJob), findsOneWidget);
    expect(
      find.text(_de.exportSummary(3, _fmt.hours(55800000), _fmt.money(22050))),
      findsOneWidget,
    );
    await tester.tap(find.text(_de.exportAllJobs));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bar').last);
    await tester.pumpAndSettle();
    expect(
      find.text(
        _de.exportSummary(1, _fmt.hours(4 * 3600000), _fmt.money(4800)),
      ),
      findsOneWidget,
    );
    await tester.tap(find.text(_de.exportFormatCsv));
    await tester.pumpAndSettle();
    await _share(tester, f);
    final path = f.share.sharedFiles.single.path;
    final csv = utf8.decode(
      (await tester.runAsync(() => File(path).readAsBytes()))!.skip(3).toList(),
    );
    expect(csv, isNot(contains('Café Müller')));
    expect(csv, contains(';Bar'));
    expect(barId, greaterThan(0));
  });

  testWidgets('preset job and range from the caller', (tester) async {
    await _open(
      tester,
      range: LocalDateRange(LocalDate(2026, 9, 28), LocalDate(2026, 9, 29)),
    );
    expect(find.text('28.09.2026 – 28.09.2026'), findsOneWidget);
    final custom = tester.widget<ChoiceChip>(
      find.ancestor(
        of: find.text(_de.exportRangeCustom),
        matching: find.byType(ChoiceChip),
      ),
    );
    expect(custom.selected, isTrue);
    expect(
      find.text(_de.exportSummary(1, _fmt.hours(27000000), _fmt.money(11250))),
      findsOneWidget,
    );
  });

  testWidgets('custom range via the date range picker', (tester) async {
    await _open(tester);
    await tester.tap(find.text(_de.exportRangeCustom));
    await tester.pumpAndSettle();
    expect(find.byType(DateRangePickerDialog), findsOneWidget);
    await tester.tap(find.text('29').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('30').first);
    await tester.pumpAndSettle();
    final localizations = MaterialLocalizations.of(
      tester.element(find.byType(DateRangePickerDialog)),
    );
    await tester.tap(find.text(localizations.saveButtonLabel));
    await settleData(tester);
    expect(find.text('29.09.2026 – 30.09.2026'), findsOneWidget);
    expect(
      find.text(
        _de.exportSummary(1, _fmt.hours(4 * 3600000), _fmt.money(6000)),
      ),
      findsOneWidget,
    );
  });

  testWidgets('busy while generating; errors are shown in the sheet', (
    tester,
  ) async {
    final fonts = Completer<TimesheetFonts>();
    final f = await pumpFeature(
      tester,
      const _Host(),
      wrapInScaffold: true,
      seed: _seed,
      config: const TestConfig(size: TestScreens.phoneLarge),
      overrides: [
        timesheetFontLoaderProvider.overrideWithValue(() => fonts.future),
      ],
    );
    await tester.tap(find.text('open'));
    await settleData(tester);
    await tapVisible(tester, find.text(_de.commonShare));
    await tester.pump();
    await tester.pump();
    expect(find.text(_de.exportPreparing), findsOneWidget);
    expect(f.read(exportControllerProvider), isTrue);
    final button = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text(_de.exportPreparing),
        matching: find.byWidgetPredicate((w) => w is FilledButton),
      ),
    );
    expect(button.onPressed, isNull);

    fonts.completeError(StateError('no fonts'));
    await pumpUntil(tester, () => !f.read(exportControllerProvider));
    expect(find.text(_de.exportFailed), findsOneWidget);
    expect(f.share.sharedFiles, isEmpty);
    expect(find.byType(ExportSheet), findsOneWidget);
  });

  group('layout', () {
    for (final config in TestConfig.matrix()) {
      testWidgets('no overflow: $config', (tester) async {
        await _open(
          tester,
          config: config,
          seed: (h) async {
            await _seed(h);
            await h.job(name: 'Eventhalle am Stadtpark');
          },
        );
        await scrollThrough(
          tester,
          within: find.byType(ExportSheet),
          context: config,
        );
        expectNoLayoutErrors(tester, config);
      });
    }
  });

  group('accessibility', () {
    for (final brightness in Brightness.values) {
      testWidgets('meets guidelines (${brightness.name})', (tester) async {
        await _open(
          tester,
          config: TestConfig(
            brightness: brightness,
            size: TestScreens.phoneLarge,
          ),
        );
        await expectMeetsAccessibilityGuidelines(tester);
      });
    }
  });
}
