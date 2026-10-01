import 'package:chronos/app/providers/providers.dart';
import 'package:chronos/core/local_date.dart';
import 'package:chronos/domain/shift.dart';
import 'package:chronos/domain/shift_draft.dart';
import 'package:chronos/features/shifts/shift_editor.dart';
import 'package:chronos/features/shifts/shifts_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fixtures/tz.dart';
import 'shifts_test_utils.dart';

const String _nb = '\u00A0';

Future<FeatureHarness> _pumpPage(
  WidgetTester tester, {
  required Future<void> Function(ProviderHarness h) seed,
  DateTime? now,
}) => pumpFeature(
  tester,
  const ShiftsPage(),
  now: now ?? kShiftsNow,
  config: const TestConfig(size: TestScreens.phoneLarge),
  seed: seed,
);

/// Opens the editor for a new shift (FAB or empty-state button).
Future<void> _openNew(WidgetTester tester) async {
  final fab = find.byKey(ShiftsPageKeys.fab);
  if (fab.evaluate().isNotEmpty) {
    await tester.tap(fab);
  } else {
    await tester.tap(find.text('Schicht nachtragen'));
  }
  await settle(tester);
  expect(find.byKey(ShiftEditorKeys.editor), findsOneWidget);
}

/// Opens the editor of the row with [title].
Future<void> _openRow(WidgetTester tester, String title) async {
  await tester.tap(find.text(title));
  await settle(tester);
  expect(find.byKey(ShiftEditorKeys.editor), findsOneWidget);
}

Future<void> _tapKey(WidgetTester tester, Key key) async {
  await tester.ensureVisible(find.byKey(key));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(key));
  await settle(tester);
}

String _fieldText(WidgetTester tester, Key key) =>
    tester.widget<EditableText>(inputOf(key)).controller.text;

Finder _previewText(String text) => find.descendant(
  of: find.byKey(ShiftEditorKeys.preview),
  matching: find.text(text),
);

Future<Shift?> _byId(FeatureHarness f, int id) =>
    f.read(shiftRepositoryProvider).getById(id);

DateTime _local(Shift s, {bool end = false}) =>
    (end ? s.endUtc! : s.startUtc).toLocal();

void main() {
  group('new shift', () {
    testWidgets('defaults to today 08:00–16:00 without earlier shifts', (
      tester,
    ) async {
      await _pumpPage(tester, seed: (h) => h.job());
      await _openNew(tester);
      expect(find.text('Neue Schicht'), findsOneWidget);
      expect(find.text('Mi., 30. Sept. 2026'), findsOneWidget);
      expect(_fieldText(tester, ShiftEditorKeys.start), '08:00');
      expect(_fieldText(tester, ShiftEditorKeys.end), '16:00');
      expect(
        _previewText('8:00 h × 15,00$_nb€/h = 120,00$_nb€'),
        findsOneWidget,
      );
      // One job: no job selector; new shifts have no delete/duplicate.
      expect(find.byKey(ShiftEditorKeys.job), findsNothing);
      expect(find.byKey(ShiftEditorKeys.delete), findsNothing);
    });

    testWidgets('prefills the times of the last shift of the job', (
      tester,
    ) async {
      await _pumpPage(
        tester,
        seed: (h) async {
          final job = await h.job();
          await addShift(
            h,
            job,
            LocalDate(2026, 9, 28),
            (h: 7, m: 30),
            (h: 15, m: 45),
          );
        },
      );
      await _openNew(tester);
      expect(_fieldText(tester, ShiftEditorKeys.start), '07:30');
      expect(_fieldText(tester, ShiftEditorKeys.end), '15:45');
      expect(find.text('Mi., 30. Sept. 2026'), findsOneWidget);
    });

    testWidgets('adds a shift from typed times, with undo', (tester) async {
      final f = await _pumpPage(tester, seed: (h) => h.job());
      await _openNew(tester);

      await typeInto(tester, ShiftEditorKeys.start, '0815');
      await typeInto(tester, ShiftEditorKeys.end, '16:45');
      expect(_fieldText(tester, ShiftEditorKeys.start), '08:15');
      expect(
        _previewText('8:30 h × 15,00$_nb€/h = 127,50$_nb€'),
        findsOneWidget,
      );

      await _tapKey(tester, ShiftEditorKeys.save);
      expect(find.byKey(ShiftEditorKeys.editor), findsNothing);
      final saved = await doneShifts(f);
      expect(saved, hasLength(1));
      final shift = saved.single;
      expect(_local(shift), DateTime(2026, 9, 30, 8, 15));
      expect(_local(shift, end: true), DateTime(2026, 9, 30, 16, 45));
      expect(shift.rateCentsPerHour, 1500);
      expect(shift.amountCents, 12750);
      expect(shift.isPaid, isFalse);
      expect(
        find.text('Schicht gespeichert · 8:30 h · 127,50$_nb€'),
        findsOneWidget,
      );
      expect(find.text('08:15–16:45 · 8:30 h'), findsOneWidget);

      await tester.tap(find.text('Rückgängig'));
      await settle(tester);
      expect(await doneShifts(f), isEmpty);
    });

    testWidgets('a typed time is taken over when saving right away', (
      tester,
    ) async {
      final f = await _pumpPage(tester, seed: (h) => h.job());
      await _openNew(tester);
      await tester.ensureVisible(find.byKey(ShiftEditorKeys.end));
      await tester.pumpAndSettle();
      // Still focused, not committed yet.
      await tester.enterText(inputOf(ShiftEditorKeys.end), '1730');
      await _tapKey(tester, ShiftEditorKeys.save);
      final shift = (await doneShifts(f)).single;
      expect(_local(shift, end: true), DateTime(2026, 9, 30, 17, 30));
    });

    testWidgets('the date picker changes the date', (tester) async {
      final f = await _pumpPage(tester, seed: (h) => h.job());
      await _openNew(tester);
      await _tapKey(tester, ShiftEditorKeys.date);
      await tester.tap(find.text('28'));
      await tester.tap(find.text('OK'));
      await settle(tester);
      expect(find.text('Mo., 28. Sept. 2026'), findsOneWidget);
      await _tapKey(tester, ShiftEditorKeys.save);
      final shift = (await doneShifts(f)).single;
      expect(shift.localStartDate, LocalDate(2026, 9, 28));
    });

    testWidgets('end before start turns "ends next day" on and shows +1', (
      tester,
    ) async {
      final f = await _pumpPage(
        tester,
        seed: (h) => h.job(),
        now: DateTime(2026, 9, 30, 23, 30).toUtc(),
      );
      await _openNew(tester);
      await typeInto(tester, ShiftEditorKeys.start, '2200');
      await typeInto(tester, ShiftEditorKeys.end, '0600');

      final toggle = tester.widget<SwitchListTile>(
        find.descendant(
          of: find.byKey(ShiftEditorKeys.nextDay),
          matching: find.byType(SwitchListTile),
        ),
      );
      expect(toggle.value, isTrue);
      expect(
        find.text(
          'Automatisch eingeschaltet, weil das Ende vor dem Start liegt',
        ),
        findsOneWidget,
      );
      expect(_previewText('22:00–06:00$_nb+1'), findsOneWidget);
      expect(
        _previewText('8:00 h × 15,00$_nb€/h = 120,00$_nb€'),
        findsOneWidget,
      );

      await _tapKey(tester, ShiftEditorKeys.save);
      final shift = (await doneShifts(f)).single;
      expect(_local(shift, end: true), DateTime(2026, 10, 1, 6));
      expect(find.text('22:00–06:00$_nb+1 · 8:00 h'), findsOneWidget);
    });

    testWidgets('the automatic next-day switch turns off again', (
      tester,
    ) async {
      await _pumpPage(tester, seed: (h) => h.job());
      await _openNew(tester);
      await typeInto(tester, ShiftEditorKeys.end, '0600');
      SwitchListTile toggle() => tester.widget<SwitchListTile>(
        find.descendant(
          of: find.byKey(ShiftEditorKeys.nextDay),
          matching: find.byType(SwitchListTile),
        ),
      );
      expect(toggle().value, isTrue);
      await typeInto(tester, ShiftEditorKeys.end, '1200');
      expect(toggle().value, isFalse);
      expect(_previewText('08:00–12:00'), findsOneWidget);
    });

    testWidgets('end equal to start is an error and nothing is saved', (
      tester,
    ) async {
      final f = await _pumpPage(tester, seed: (h) => h.job());
      await _openNew(tester);
      await typeInto(tester, ShiftEditorKeys.end, '0800');
      expect(find.text('Das Ende muss nach dem Start liegen.'), findsOneWidget);
      await _tapKey(tester, ShiftEditorKeys.save);
      expect(find.byKey(ShiftEditorKeys.editor), findsOneWidget);
      expect(await doneShifts(f), isEmpty);
    });

    testWidgets('a break as long as the shift is an error', (tester) async {
      final f = await _pumpPage(tester, seed: (h) => h.job());
      await _openNew(tester);
      await typeInto(tester, ShiftEditorKeys.end, '0900');
      await typeInto(tester, ShiftEditorKeys.breakField, '60');
      expect(
        find.text('Die Pause muss kürzer als die Schicht sein.'),
        findsOneWidget,
      );
      await _tapKey(tester, ShiftEditorKeys.save);
      expect(await doneShifts(f), isEmpty);

      // The stepper fixes it: 55 min break.
      await _tapKey(tester, ShiftEditorKeys.breakLess);
      expect(_fieldText(tester, ShiftEditorKeys.breakField), '55');
      expect(
        find.text('Die Pause muss kürzer als die Schicht sein.'),
        findsNothing,
      );
      await _tapKey(tester, ShiftEditorKeys.save);
      final shift = (await doneShifts(f)).single;
      expect(shift.breakMs, 55 * 60 * 1000);
      expect(shift.workedMs, 5 * 60 * 1000);
    });

    testWidgets('longer than 16 h asks before saving', (tester) async {
      final f = await _pumpPage(tester, seed: (h) => h.job());
      await _openNew(tester);
      await typeInto(tester, ShiftEditorKeys.start, '0600');
      await typeInto(tester, ShiftEditorKeys.end, '2300');
      expect(find.text('Länger als 16 Stunden (17:00 h)'), findsOneWidget);

      await _tapKey(tester, ShiftEditorKeys.save);
      expect(find.text('Trotzdem speichern?'), findsOneWidget);
      await tester.tap(find.text('Abbrechen'));
      await settle(tester);
      expect(await doneShifts(f), isEmpty);
      expect(find.byKey(ShiftEditorKeys.editor), findsOneWidget);

      await _tapKey(tester, ShiftEditorKeys.save);
      await tester.tap(find.text('Trotzdem speichern'));
      await settle(tester);
      expect(await doneShifts(f), hasLength(1));
      expect(find.byKey(ShiftEditorKeys.editor), findsNothing);
    });

    testWidgets('an overlap names the other shift and asks before saving', (
      tester,
    ) async {
      final f = await _pumpPage(
        tester,
        seed: (h) async {
          final job = await h.job();
          await addShift(
            h,
            job,
            LocalDate(2026, 9, 30),
            (h: 8, m: 0),
            (h: 16, m: 0),
          );
        },
      );
      await _openNew(tester);
      await typeInto(tester, ShiftEditorKeys.start, '1500');
      await typeInto(tester, ShiftEditorKeys.end, '1900');
      final overlap = find.textContaining('Überschneidet sich mit');
      expect(overlap, findsOneWidget);
      expect(
        tester.widget<Text>(overlap).data,
        allOf(contains('30.'), contains('08:00–16:00')),
      );

      await _tapKey(tester, ShiftEditorKeys.save);
      expect(find.text('Trotzdem speichern?'), findsOneWidget);
      // The dialog lists the other shift too.
      expect(find.textContaining('08:00–16:00'), findsNWidgets(3));
      await tester.tap(find.text('Trotzdem speichern'));
      await settle(tester);
      expect(await doneShifts(f), hasLength(2));
    });

    testWidgets('a start in the future asks before saving', (tester) async {
      final f = await _pumpPage(tester, seed: (h) => h.job());
      await _openNew(tester);
      await typeInto(tester, ShiftEditorKeys.start, '2100');
      await typeInto(tester, ShiftEditorKeys.end, '2300');
      expect(find.text('Beginnt in der Zukunft'), findsOneWidget);
      await _tapKey(tester, ShiftEditorKeys.save);
      await tester.tap(find.text('Trotzdem speichern'));
      await settle(tester);
      expect(await doneShifts(f), hasLength(1));
    });

    testWidgets('tips with a decimal comma, note and paid status', (
      tester,
    ) async {
      final f = await _pumpPage(tester, seed: (h) => h.job());
      await _openNew(tester);
      await typeInto(tester, ShiftEditorKeys.tips, '5,50');
      expect(_previewText('plus 5,50$_nb€ Trinkgeld'), findsOneWidget);
      await typeInto(tester, ShiftEditorKeys.note, 'Hochzeit');
      await _tapKey(tester, ShiftEditorKeys.status);
      await tester.tap(find.text('Bezahlt').last);
      await settle(tester);

      await _tapKey(tester, ShiftEditorKeys.save);
      final shift = (await doneShifts(f)).single;
      expect(shift.tipsCents, 550);
      expect(shift.note, 'Hochzeit');
      expect(shift.isPaid, isTrue);
      expect(shift.amountCents, 12000);
    });

    testWidgets('double-tapping save creates exactly one shift', (
      tester,
    ) async {
      final f = await _pumpPage(tester, seed: (h) => h.job());
      await _openNew(tester);
      final save = find.byKey(ShiftEditorKeys.save);
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      await tester.tap(save);
      await tester.tap(save, warnIfMissed: false);
      await settle(tester);
      expect(await doneShifts(f), hasLength(1));
    });
  });

  group('edit shift', () {
    Future<Shift> seedOne(
      ProviderHarness h, {
      int rateCents = 1500,
      bool paid = false,
    }) async {
      final job = await h.job(centsPerHour: rateCents);
      return addShift(
        h,
        job,
        LocalDate(2026, 9, 28),
        (h: 8, m: 0),
        (h: 16, m: 0),
        breakMinutes: 30,
        tipsCents: 250,
        note: 'Messe',
        paid: paid,
      );
    }

    testWidgets('shows the stored values', (tester) async {
      await _pumpPage(tester, seed: (h) => seedOne(h, paid: true));
      await _openRow(tester, '08:00–16:00 · 7:30 h');
      expect(find.text('Schicht bearbeiten'), findsOneWidget);
      expect(find.text('Mo., 28. Sept. 2026'), findsOneWidget);
      expect(_fieldText(tester, ShiftEditorKeys.start), '08:00');
      expect(_fieldText(tester, ShiftEditorKeys.end), '16:00');
      expect(_fieldText(tester, ShiftEditorKeys.breakField), '30');
      expect(_fieldText(tester, ShiftEditorKeys.tips), '2,50');
      expect(_fieldText(tester, ShiftEditorKeys.note), 'Messe');
      final status = tester.widget<SegmentedButton<bool>>(
        find.byType(SegmentedButton<bool>),
      );
      expect(status.selected, <bool>{true});
    });

    testWidgets('keeps the stored wage although the rate changed', (
      tester,
    ) async {
      late Shift shift;
      final f = await _pumpPage(
        tester,
        seed: (h) async {
          shift = await seedOne(h);
          await h
              .read(jobRepositoryProvider)
              .addRate(
                shift.jobId,
                validFrom: LocalDate(2026, 9, 1),
                centsPerHour: 1800,
              );
        },
      );
      await _openRow(tester, '08:00–16:00 · 7:30 h');
      expect(
        _previewText('7:30 h × 15,00$_nb€/h = 112,50$_nb€'),
        findsOneWidget,
      );
      await typeInto(tester, ShiftEditorKeys.end, '1700');
      expect(
        _previewText('8:30 h × 15,00$_nb€/h = 127,50$_nb€'),
        findsOneWidget,
      );
      await _tapKey(tester, ShiftEditorKeys.save);
      final saved = (await _byId(f, shift.id))!;
      expect(saved.rateCentsPerHour, 1500);
      expect(saved.amountCents, 12750);
      expect(await doneShifts(f), hasLength(1));

      // A new shift on the same job takes the current rate.
      await _openNew(tester);
      expect(find.textContaining('18,00$_nb€/h'), findsOneWidget);
    });

    testWidgets('switching the job takes the other job\'s rate', (
      tester,
    ) async {
      late Shift shift;
      late int barId;
      final f = await _pumpPage(
        tester,
        seed: (h) async {
          shift = await seedOne(h);
          barId = (await h.job(name: 'Bar', centsPerHour: 1200)).id;
        },
      );
      await _openRow(tester, '08:00–16:00 · 7:30 h');
      expect(find.byKey(ShiftEditorKeys.job), findsOneWidget);
      await _tapKey(tester, ShiftEditorKeys.job);
      await tester.tap(find.text('Bar').last);
      await settle(tester);
      expect(
        _previewText('7:30 h × 12,00$_nb€/h = 90,00$_nb€'),
        findsOneWidget,
      );
      await _tapKey(tester, ShiftEditorKeys.save);
      final saved = (await _byId(f, shift.id))!;
      expect(saved.jobId, barId);
      expect(saved.rateCentsPerHour, 1200);
      expect(saved.amountCents, 9000);
    });

    testWidgets('delete closes the editor and offers undo on the page', (
      tester,
    ) async {
      late Shift shift;
      final f = await _pumpPage(
        tester,
        seed: (h) async => shift = await seedOne(h),
      );
      await _openRow(tester, '08:00–16:00 · 7:30 h');
      await _tapKey(tester, ShiftEditorKeys.delete);
      expect(find.byKey(ShiftEditorKeys.editor), findsNothing);
      expect(find.text('Schicht gelöscht'), findsOneWidget);
      expect((await _byId(f, shift.id))!.isDeleted, isTrue);
      expect(find.text('08:00–16:00 · 7:30 h'), findsNothing);

      await tester.tap(find.text('Rückgängig'));
      await settle(tester);
      expect((await _byId(f, shift.id))!.isDeleted, isFalse);
      expect(find.text('08:00–16:00 · 7:30 h'), findsOneWidget);
    });

    testWidgets('duplicate copies the shift to today and edits the copy', (
      tester,
    ) async {
      final f = await _pumpPage(tester, seed: (h) => seedOne(h, paid: true));
      await _openRow(tester, '08:00–16:00 · 7:30 h');
      await _tapKey(tester, ShiftEditorKeys.duplicate);
      expect(
        find.text(
          'Kopie für heute angelegt. Pass sie an oder lösch sie wieder.',
        ),
        findsOneWidget,
      );
      expect(find.text('Mi., 30. Sept. 2026'), findsOneWidget);
      final all = await doneShifts(f);
      expect(all, hasLength(2));
      final copy = all.firstWhere((s) => s.localStartDate == kToday);
      expect(copy.isPaid, isFalse);
      expect(copy.tipsCents, 0);
      expect(copy.breakMs, 30 * 60 * 1000);
    });

    testWidgets('closing with unsaved changes asks to discard', (tester) async {
      late Shift shift;
      final f = await _pumpPage(
        tester,
        seed: (h) async => shift = await seedOne(h),
      );
      await _openRow(tester, '08:00–16:00 · 7:30 h');
      await _tapKey(tester, ShiftEditorKeys.breakMore);
      expect(_fieldText(tester, ShiftEditorKeys.breakField), '35');

      await tester.tap(find.byTooltip('Schließen'));
      await settle(tester);
      expect(find.text('Änderungen verwerfen?'), findsOneWidget);
      await tester.tap(find.text('Weiter bearbeiten'));
      await settle(tester);
      expect(find.byKey(ShiftEditorKeys.editor), findsOneWidget);
      expect(_fieldText(tester, ShiftEditorKeys.breakField), '35');

      // System back asks as well.
      await tester.binding.handlePopRoute();
      await settle(tester);
      expect(find.text('Änderungen verwerfen?'), findsOneWidget);
      await tester.tap(find.text('Verwerfen'));
      await settle(tester);
      expect(find.byKey(ShiftEditorKeys.editor), findsNothing);
      expect((await _byId(f, shift.id))!.breakMs, 30 * 60 * 1000);
    });

    testWidgets('dragging the sheet down with unsaved changes asks too', (
      tester,
    ) async {
      await _pumpPage(tester, seed: seedOne);
      await _openRow(tester, '08:00–16:00 · 7:30 h');
      await _tapKey(tester, ShiftEditorKeys.breakMore);

      await tester.fling(
        find.text('Schicht bearbeiten'),
        const Offset(0, 500),
        2000,
      );
      await settle(tester);
      expect(find.text('Änderungen verwerfen?'), findsOneWidget);
      await tester.tap(find.text('Weiter bearbeiten'));
      await settle(tester);
      expect(find.byKey(ShiftEditorKeys.editor), findsOneWidget);
      expect(_fieldText(tester, ShiftEditorKeys.breakField), '35');
      // The sheet is fully back in place.
      expect(find.byKey(ShiftEditorKeys.save).hitTestable(), findsOneWidget);
    });

    testWidgets('closing without changes does not ask', (tester) async {
      await _pumpPage(tester, seed: seedOne);
      await _openRow(tester, '08:00–16:00 · 7:30 h');
      await tester.fling(
        find.text('Schicht bearbeiten'),
        const Offset(0, 500),
        2000,
      );
      await settle(tester);
      expect(find.text('Änderungen verwerfen?'), findsNothing);
      expect(find.byKey(ShiftEditorKeys.editor), findsNothing);
    });

    testWidgets('saving unchanged keeps a shift longer than a day (v1 D11)', (
      tester,
    ) async {
      late Shift shift;
      final f = await _pumpPage(
        tester,
        seed: (h) async {
          final job = await h.job();
          shift = await h
              .read(shiftRepositoryProvider)
              .insertManual(
                ShiftDraft(
                  jobId: job.id,
                  startUtc: DateTime(2026, 9, 28, 18).toUtc(),
                  endUtc: DateTime(2026, 9, 30, 10).toUtc(),
                ),
              );
        },
      );
      await _openRow(tester, '18:00–10:00$_nb+2 · 40:00 h');
      expect(
        _previewText('40:00 h × 15,00$_nb€/h = 600,00$_nb€'),
        findsOneWidget,
      );
      // Only the note changes.
      await tester.enterText(inputOf(ShiftEditorKeys.note), 'Messe');
      await _tapKey(tester, ShiftEditorKeys.save);
      await tester.tap(find.text('Trotzdem speichern'));
      await settle(tester);
      final saved = (await _byId(f, shift.id))!;
      expect(saved.note, 'Messe');
      expect(saved.startUtc, shift.startUtc);
      expect(saved.endUtc, shift.endUtc);
      expect(saved.amountCents, 60000);
    });

    testWidgets('saving unchanged keeps the seconds of a timer shift', (
      tester,
    ) async {
      late Shift shift;
      final f = await _pumpPage(
        tester,
        seed: (h) async {
          final job = await h.job();
          shift = await h
              .read(shiftRepositoryProvider)
              .insertManual(
                ShiftDraft(
                  jobId: job.id,
                  startUtc: DateTime(2026, 9, 28, 8, 0, 40).toUtc(),
                  endUtc: DateTime(2026, 9, 28, 16, 15, 10).toUtc(),
                ),
              );
        },
      );
      await _openRow(tester, '08:00–16:15 · 8:15 h');
      await tester.ensureVisible(find.byKey(ShiftEditorKeys.status));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byKey(ShiftEditorKeys.status),
          matching: find.text('Bezahlt'),
        ),
      );
      await settle(tester);
      await _tapKey(tester, ShiftEditorKeys.save);
      final saved = (await _byId(f, shift.id))!;
      expect(saved.isPaid, isTrue);
      expect(saved.startUtc, shift.startUtc);
      expect(saved.rawStartUtc, shift.rawStartUtc);
      expect(saved.endUtc, shift.endUtc);
      expect(saved.amountCents, shift.amountCents);
    });

    testWidgets('night of the clock change counts the extra hour', (
      tester,
    ) async {
      await _pumpPage(
        tester,
        now: DateTime(2026, 10, 26, 12).toUtc(),
        seed: (h) async {
          final job = await h.job();
          await addShift(
            h,
            job,
            LocalDate(2026, 10, 24),
            (h: 22, m: 0),
            (h: 6, m: 0),
          );
        },
      );
      await _openRow(tester, '22:00–06:00$_nb+1 · 9:00 h');
      expect(
        _previewText('9:00 h × 15,00$_nb€/h = 135,00$_nb€'),
        findsOneWidget,
      );
    }, skip: !isBerlinTz);

    testWidgets('English editor', (tester) async {
      await pumpFeature(
        tester,
        const ShiftsPage(),
        now: kShiftsNow,
        config: const TestConfig(
          size: TestScreens.phoneLarge,
          locale: Locale('en'),
        ),
        seed: seedOne,
      );
      await tester.tap(find.textContaining('7:30 h'));
      await settle(tester);
      expect(find.text('Edit shift'), findsOneWidget);
      expect(find.text('Ends the next day'), findsOneWidget);
      expect(find.textContaining('€15.00/h = €112.50'), findsOneWidget);
    });
  });

  group('presentation', () {
    Future<void> openOn(WidgetTester tester, Size size) async {
      await pumpFeature(
        tester,
        const ShiftsPage(),
        now: kShiftsNow,
        config: TestConfig(size: size),
        seed: (h) async {
          final job = await h.job();
          await addShift(
            h,
            job,
            LocalDate(2026, 9, 28),
            (h: 8, m: 0),
            (h: 16, m: 0),
          );
        },
      );
      await tester.tap(find.byKey(ShiftsPageKeys.fab));
      await settle(tester);
    }

    testWidgets('phone: bottom sheet with drag handle', (tester) async {
      await openOn(tester, TestScreens.phoneLarge);
      final sheet = tester.widget<BottomSheet>(find.byType(BottomSheet));
      expect(sheet.showDragHandle, isTrue);
      expect(find.byType(Dialog), findsNothing);
    });

    testWidgets('phone landscape: full-height sheet', (tester) async {
      await openOn(tester, TestScreens.landscapeSmall);
      expect(
        tester.getSize(find.byType(BottomSheet)).height,
        TestScreens.landscapeSmall.height,
      );
      expect(find.byKey(ShiftEditorKeys.save).hitTestable(), findsOneWidget);
    });

    testWidgets('tablet landscape: centred dialog at most 560 dp wide', (
      tester,
    ) async {
      await openOn(tester, TestScreens.tabletLandscape);
      expect(find.byType(BottomSheet), findsNothing);
      final dialog = find.byType(Dialog);
      expect(dialog, findsOneWidget);
      final rect = tester.getRect(
        find.descendant(of: dialog, matching: find.byType(Material)).first,
      );
      expect(rect.width, lessThanOrEqualTo(560));
      expect(
        rect.center.dx,
        moreOrLessEquals(TestScreens.tabletLandscape.width / 2),
      );

      // A tap on the barrier with unsaved changes asks first.
      await _tapKey(tester, ShiftEditorKeys.breakMore);
      await tester.tapAt(const Offset(20, 20));
      await settle(tester);
      expect(find.text('Änderungen verwerfen?'), findsOneWidget);
      await tester.tap(find.text('Verwerfen'));
      await settle(tester);
      expect(find.byType(Dialog), findsNothing);
    });
  });
}
