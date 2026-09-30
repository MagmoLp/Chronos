import 'package:chronos/app/providers/providers.dart';
import 'package:chronos/app/shell.dart';
import 'package:chronos/core/local_date.dart';
import 'package:chronos/domain/shift.dart';
import 'package:chronos/features/shifts/payout_sheet.dart';
import 'package:chronos/features/shifts/shift_editor.dart';
import 'package:chronos/features/shifts/shifts_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import 'shifts_test_utils.dart';

/// Seeds one job and three shifts: an open one on Mon 28 Sep (with break),
/// a paid overnight one on Fri 25 Sep (with tips) and an open one in August.
Future<void> _seedThree(ProviderHarness h) async {
  final job = await h.job();
  await addShift(
    h,
    job,
    LocalDate(2026, 9, 28),
    (h: 8, m: 0),
    (h: 16, m: 15),
    breakMinutes: 30,
  );
  await addShift(
    h,
    job,
    LocalDate(2026, 9, 25),
    (h: 18, m: 0),
    (h: 2, m: 0),
    paid: true,
    tipsCents: 500,
  );
  await addShift(h, job, LocalDate(2026, 8, 14), (h: 9, m: 0), (h: 17, m: 0));
}

Future<FeatureHarness> _pumpPage(
  WidgetTester tester, {
  Future<void> Function(ProviderHarness h)? seed,
  TestConfig config = const TestConfig(size: TestScreens.phoneLarge),
}) => pumpFeature(
  tester,
  const ShiftsPage(),
  now: kShiftsNow,
  config: config,
  seed: seed ?? _seedThree,
);

Finder _row(int id) => find.byKey(ValueKey<int>(id));

void main() {
  group('list', () {
    testWidgets('groups shifts by month, newest first, with month totals', (
      tester,
    ) async {
      await _pumpPage(tester);

      final september = find.text('September 2026');
      final august = find.text('August 2026');
      expect(september, findsOneWidget);
      expect(august, findsOneWidget);
      expect(
        tester.getTopLeft(september).dy,
        lessThan(tester.getTopLeft(august).dy),
      );

      // 7:45 h + 8:00 h; 116,25 € + 120,00 €; only the first is open.
      const nb = '\u00A0';
      expect(
        find.text('15,75 h · 236,25$nb€ · 116,25$nb€ offen'),
        findsOneWidget,
      );
      expect(find.text('8 h · 120,00$nb€ · 120,00$nb€ offen'), findsOneWidget);

      // Rows: newest first inside the month, "+1" for the overnight shift.
      final first = find.text('08:00–16:15 · 7:45 h');
      final second = find.text('18:00–02:00$nb+1 · 8:00 h');
      expect(first, findsOneWidget);
      expect(second, findsOneWidget);
      expect(
        tester.getTopLeft(first).dy,
        lessThan(tester.getTopLeft(second).dy),
      );
      expect(find.text('Pause 30 min'), findsOneWidget);
      expect(find.text('Trinkgeld 5,00$nb€'), findsOneWidget);
      expect(find.text('116,25$nb€'), findsOneWidget);

      // Status icons: one paid (check), two open (clock).
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byIcon(Icons.schedule), findsNWidgets(2));
    });

    testWidgets('month header without open wage omits the open part', (
      tester,
    ) async {
      await _pumpPage(
        tester,
        seed: (h) async {
          final job = await h.job();
          await addShift(
            h,
            job,
            LocalDate(2026, 9, 1),
            (h: 8, m: 0),
            (h: 12, m: 0),
            paid: true,
          );
        },
      );
      expect(find.text('4 h · 60,00\u00A0€'), findsOneWidget);
    });

    testWidgets('shows the job name only when there is more than one job', (
      tester,
    ) async {
      await _pumpPage(
        tester,
        seed: (h) async {
          final cafe = await h.job(name: 'Café');
          final bar = await h.job(name: 'Bar', centsPerHour: 1200);
          await addShift(
            h,
            cafe,
            LocalDate(2026, 9, 28),
            (h: 8, m: 0),
            (h: 12, m: 0),
            note: 'Hochzeit Müller',
          );
          await addShift(
            h,
            bar,
            LocalDate(2026, 9, 27),
            (h: 18, m: 0),
            (h: 22, m: 0),
          );
        },
      );
      expect(find.text('Café · Hochzeit Müller'), findsOneWidget);
      expect(find.text('Bar'), findsOneWidget);
    });

    testWidgets('filter chips show all, open or paid shifts', (tester) async {
      await _pumpPage(tester);
      final paidTitle = find.text('18:00–02:00\u00A0+1 · 8:00 h');
      final openTitle = find.text('08:00–16:15 · 7:45 h');

      await tester.tap(find.byKey(ShiftsPageKeys.filter(ShiftFilter.open)));
      await settle(tester);
      expect(paidTitle, findsNothing);
      expect(openTitle, findsOneWidget);
      expect(find.text('09:00–17:00 · 8:00 h'), findsOneWidget);

      await tester.tap(find.byKey(ShiftsPageKeys.filter(ShiftFilter.paid)));
      await settle(tester);
      expect(paidTitle, findsOneWidget);
      expect(openTitle, findsNothing);
      expect(find.text('August 2026'), findsNothing);

      await tester.tap(find.byKey(ShiftsPageKeys.filter(ShiftFilter.all)));
      await settle(tester);
      expect(paidTitle, findsOneWidget);
      expect(openTitle, findsOneWidget);
    });

    testWidgets('filters without matches explain and offer "show all"', (
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
            (h: 8, m: 0),
            (h: 12, m: 0),
          );
        },
      );
      await tester.tap(find.byKey(ShiftsPageKeys.filter(ShiftFilter.paid)));
      await settle(tester);
      expect(find.text('Noch keine bezahlten Schichten'), findsOneWidget);

      await tester.tap(find.text('Alle Schichten anzeigen'));
      await settle(tester);
      expect(find.text('08:00–12:00 · 4:00 h'), findsOneWidget);
    });

    testWidgets('running shift tile on top switches to Today', (tester) async {
      final controller = ShellController(ShellTab.shifts);
      addTearDown(controller.dispose);
      await pumpFeature(
        tester,
        shellWithShifts(controller),
        now: kShiftsNow,
        config: const TestConfig(size: TestScreens.phoneLarge),
        seed: (h) async {
          await _seedThree(h);
          final job = (await h.read(jobRepositoryProvider).getJobs()).first;
          await h
              .read(shiftRepositoryProvider)
              .start(job.id, startUtc: DateTime(2026, 9, 30, 8, 2).toUtc());
        },
      );
      final tile = find.byKey(ShiftsPageKeys.runningTile);
      expect(tile, findsOneWidget);
      expect(find.text('Läuft seit 08:02'), findsOneWidget);
      expect(
        tester.getTopLeft(tile).dy,
        lessThan(tester.getTopLeft(find.text('September 2026')).dy),
      );

      await tester.tap(tile);
      await tester.pumpAndSettle();
      expect(controller.value, ShellTab.today);
      expect(find.text('TODAY-PAGE'), findsOneWidget);
    });

    testWidgets('paused running shift says since when it is paused', (
      tester,
    ) async {
      await _pumpPage(
        tester,
        seed: (h) async {
          final job = await h.job();
          final shifts = h.read(shiftRepositoryProvider);
          await shifts.start(
            job.id,
            startUtc: DateTime(2026, 9, 30, 8, 2).toUtc(),
          );
          await shifts.pause(atUtc: DateTime(2026, 9, 30, 14, 32).toUtc());
        },
      );
      expect(find.text('Pausiert seit 14:32'), findsOneWidget);
      // No finished shifts: the running tile, but no empty-state text.
      expect(find.text('Noch keine Schichten'), findsNothing);
    });
  });

  group('row actions', () {
    testWidgets('tap opens the editor for the shift', (tester) async {
      await _pumpPage(tester);
      await tester.tap(find.text('08:00–16:15 · 7:45 h'));
      await settle(tester);
      expect(find.text('Schicht bearbeiten'), findsOneWidget);
      expect(find.byKey(ShiftEditorKeys.delete), findsOneWidget);
    });

    testWidgets('swipe right marks paid, keeps the row, and undo reverts', (
      tester,
    ) async {
      final f = await _pumpPage(tester);
      final shift = (await doneShifts(f)).firstWhere((s) => !s.isPaid);
      final row = _row(shift.id);

      await tester.drag(row, const Offset(500, 0));
      await settle(tester);
      expect(row, findsOneWidget);
      expect(find.text('Als bezahlt markiert'), findsOneWidget);
      expect(
        (await f.read(shiftRepositoryProvider).getById(shift.id))!.isPaid,
        isTrue,
      );
      expect(
        find.descendant(of: row, matching: find.byIcon(Icons.check_circle)),
        findsOneWidget,
      );

      await tester.tap(find.text('Rückgängig'));
      await settle(tester);
      expect(
        (await f.read(shiftRepositoryProvider).getById(shift.id))!.isPaid,
        isFalse,
      );
      expect(
        find.descendant(of: row, matching: find.byIcon(Icons.schedule)),
        findsOneWidget,
      );
    });

    testWidgets('swipe right on a paid shift marks it open', (tester) async {
      final f = await _pumpPage(tester);
      final shift = (await doneShifts(f)).firstWhere((s) => s.isPaid);
      await tester.drag(_row(shift.id), const Offset(500, 0));
      await settle(tester);
      expect(find.text('Als offen markiert'), findsOneWidget);
      expect(
        (await f.read(shiftRepositoryProvider).getById(shift.id))!.isPaid,
        isFalse,
      );
    });

    testWidgets('swipe left deletes with undo', (tester) async {
      final f = await _pumpPage(tester);
      final shift = (await doneShifts(f)).first;

      await tester.drag(_row(shift.id), const Offset(-500, 0));
      await settle(tester);
      expect(_row(shift.id), findsNothing);
      expect(find.text('Schicht gelöscht'), findsOneWidget);
      expect(await doneShifts(f), hasLength(2));

      await tester.tap(find.text('Rückgängig'));
      await settle(tester);
      expect(_row(shift.id), findsOneWidget);
      expect(await doneShifts(f), hasLength(3));
    });

    testWidgets('long-press menu: mark paid, delete, edit, duplicate', (
      tester,
    ) async {
      final f = await _pumpPage(tester);
      final shift = (await doneShifts(f)).firstWhere((s) => !s.isPaid);
      final row = _row(shift.id);

      await tester.longPress(row);
      await tester.pumpAndSettle();
      expect(find.text('Bearbeiten'), findsOneWidget);
      expect(find.text('Duplizieren'), findsOneWidget);
      expect(find.text('Löschen'), findsOneWidget);
      await tester.tap(find.text('Als bezahlt markieren'));
      await settle(tester);
      expect(
        (await f.read(shiftRepositoryProvider).getById(shift.id))!.isPaid,
        isTrue,
      );

      await tester.longPress(row);
      await tester.pumpAndSettle();
      expect(find.text('Als offen markieren'), findsOneWidget);
      await tester.tap(find.text('Bearbeiten'));
      await settle(tester);
      expect(find.text('Schicht bearbeiten'), findsOneWidget);
      await tester.tap(find.byTooltip('Schließen'));
      await settle(tester);
      expect(find.text('Schicht bearbeiten'), findsNothing);

      await tester.longPress(row);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Duplizieren'));
      await settle(tester);
      final all = await doneShifts(f);
      expect(all, hasLength(4));
      final copy = all.firstWhere((s) => s.localStartDate == kToday);
      expect(copy.isPaid, isFalse);
      expect(
        find.text(
          'Kopie für heute angelegt. Pass sie an oder lösch sie wieder.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('Schließen'));
      await settle(tester);

      await tester.longPress(row);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Löschen'));
      await settle(tester);
      expect(row, findsNothing);
      expect(find.text('Schicht gelöscht'), findsOneWidget);
    });

    testWidgets('all row actions are screen-reader actions', (tester) async {
      final handle = tester.ensureSemantics();
      final f = await _pumpPage(tester);
      final shift = (await doneShifts(f)).firstWhere((s) => !s.isPaid);
      final node = tester.getSemantics(
        find.bySemanticsLabel(RegExp('Montag, 28. September 2026')),
      );
      final data = node.getSemanticsData();
      expect(data.label, contains('Montag, 28. September 2026'));
      expect(data.label, contains('7 Stunden 45 Minuten'));
      expect(data.label, contains('Offen'));
      expect(data.hasAction(SemanticsAction.tap), isTrue);
      expect(data.hasAction(SemanticsAction.longPress), isTrue);
      final labels = <String?>[
        for (final id in data.customSemanticsActionIds!)
          CustomSemanticsAction.getAction(id)!.label,
      ];
      expect(
        labels,
        containsAll(<String>[
          'Bearbeiten',
          'Duplizieren',
          'Als bezahlt markieren',
          'Löschen',
        ]),
      );

      final markPaid = data.customSemanticsActionIds!.firstWhere(
        (id) =>
            CustomSemanticsAction.getAction(id)!.label ==
            'Als bezahlt markieren',
      );
      node.owner!.performAction(
        node.id,
        SemanticsAction.customAction,
        markPaid,
      );
      await settle(tester);
      expect(
        (await f.read(shiftRepositoryProvider).getById(shift.id))!.isPaid,
        isTrue,
      );
      handle.dispose();
    });
  });

  group('empty state and actions', () {
    testWidgets('empty list offers starting and adding a shift', (
      tester,
    ) async {
      final controller = ShellController(ShellTab.shifts);
      addTearDown(controller.dispose);
      await pumpFeature(
        tester,
        shellWithShifts(controller),
        now: kShiftsNow,
        seed: (h) => h.job(),
      );
      expect(find.text('Noch keine Schichten'), findsOneWidget);

      await tester.tap(find.text('Schicht nachtragen'));
      await settle(tester);
      expect(find.text('Neue Schicht'), findsOneWidget);
      await tester.tap(find.byTooltip('Schließen'));
      await settle(tester);

      await tester.tap(find.text('Schicht starten'));
      await tester.pumpAndSettle();
      expect(controller.value, ShellTab.today);
    });

    testWidgets('FAB opens the editor for a new shift', (tester) async {
      await _pumpPage(tester);
      await tester.tap(find.byKey(ShiftsPageKeys.fab));
      await settle(tester);
      expect(find.text('Neue Schicht'), findsOneWidget);
    });

    testWidgets('overflow menu opens the payout sheet', (tester) async {
      await _pumpPage(tester);
      await tester.tap(find.byKey(ShiftsPageKeys.menu));
      await tester.pumpAndSettle();
      expect(find.text('Exportieren'), findsOneWidget);
      await tester.tap(find.text('Auszahlung erfassen'));
      await settle(tester);
      expect(find.byKey(PayoutSheetKeys.sheet), findsOneWidget);
    });

    testWidgets('English texts', (tester) async {
      await _pumpPage(
        tester,
        config: const TestConfig(
          size: TestScreens.phoneLarge,
          locale: Locale('en'),
        ),
      );
      expect(find.text('Shifts'), findsWidgets);
      expect(find.text('Unpaid'), findsOneWidget);
      expect(find.textContaining('€116.25 unpaid'), findsOneWidget);
      final range = fmtEn.timeRange(
        DateTime(2026, 9, 28, 8),
        DateTime(2026, 9, 28, 16, 15),
      );
      expect(find.text('$range · 7:45 h'), findsOneWidget);
    });
  });
}
