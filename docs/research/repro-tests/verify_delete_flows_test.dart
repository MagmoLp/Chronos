// Task A.4/A.5: delete combined with timer / add / edit / paid toggle / timer-created entries / duplicates.
import 'dart:convert';

import 'package:chronos/main.dart';
import 'package:chronos/widgets/animated_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';
import 'verify_delete_common.dart';

Future<void> pumpMs(WidgetTester t, int ms) async {
  for (var i = 0; i < ms ~/ 50; i++) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

Finder rowItem(String range) => find.ancestor(of: find.text(range), matching: find.byType(AnimatedListItem)).first;

Finder paidBox(String range) => find.descendant(
    of: rowItem(range),
    matching: find.byWidgetPredicate((w) => w is AnimatedContainer && w.constraints == const BoxConstraints.tightFor(width: 28, height: 28)));

Future<void> tapAdd(WidgetTester t, {bool settle = true}) async {
  await t.tap(find.byIcon(Icons.add));
  await t.pumpAndSettle();
  await t.tap(find.widgetWithText(ElevatedButton, 'Speichern'));
  if (settle) await t.pumpAndSettle();
}

void main() {
  setUpAll(() async => loadRealFonts());

  testWidgets('delete while timer is running (started via START button)', (t) async {
    final h = await startApp(t, entries: baseEntries());
    await t.tap(find.text('START'));
    await pumpMs(t, 1200);
    obs('timer running=${h.timer.isRunning}, home amounts=${homeAmounts(t)}');
    await goLog(t, settle: false);
    await pumpMs(t, 500);
    await uiDeleteRow(t, rC);
    await t.pump();
    snap(t, 'timer running: 1 frame after confirm');
    await pumpMs(t, 1500);
    snap(t, 'timer running: 1.5s later');
    expect(logRows(t), isNot(contains(rC)));
    await goHome(t, settle: false);
    await pumpMs(t, 1200);
    obs('home amounts after delete with timer running: ${homeAmounts(t)}  (open 370-123.75=246.25 + running)');
    expect(homeAmounts(t)[1] - homeAmounts(t)[0], closeTo(246.25, 0.01));
    await h.dispose(t);
    resetScreen(t);
  });

  testWidgets('delete right after ADD (manual uuid entry)', (t) async {
    final h = await startApp(t, entries: baseEntries());
    await goLog(t);
    await tapAdd(t);
    final today = logRows(t);
    snap(t, 'after add');
    final newId = h.entries.entries.firstWhere((e) => !['A', 'B', 'C', 'D', 'E'].contains(e.id)).id;
    obs('new id = $newId');
    await uiDeleteRow(t, '08:00 – 16:00');
    await t.pump();
    snap(t, 'after deleting the added entry, 1 frame');
    await t.pumpAndSettle();
    expect(logRows(t), isNot(contains('08:00 – 16:00')));
    expect(await storedIds(), isNot(contains(newId)));
    expect(today.length, 6);
    await h.dispose(t);
    resetScreen(t);
  });

  testWidgets('delete right after EDIT (sheet -> Eintrag bearbeiten -> Speichern)', (t) async {
    final h = await startApp(t, entries: baseEntries());
    await goLog(t);
    await t.tap(find.text(rB));
    await t.pumpAndSettle();
    await t.tap(find.text('Eintrag bearbeiten'));
    await t.pumpAndSettle();
    await t.tap(find.widgetWithText(ElevatedButton, 'Speichern'));
    await t.pump();
    snap(t, 'edit saved, 1 frame');
    await t.pumpAndSettle();
    await uiDeleteRow(t, rB);
    await t.pump();
    snap(t, 'delete after edit, 1 frame');
    await t.pumpAndSettle();
    expect(logRows(t), isNot(contains(rB)));
    expect(await storedIds(), isNot(contains('B')));
    await h.dispose(t);
    resetScreen(t);
  });

  testWidgets('delete right after toggling paid (open->paid, and paid->open via confirm)', (t) async {
    final h = await startApp(t, entries: baseEntries());
    await goLog(t);
    await t.tap(paidBox(rA));
    await t.pump();
    obs('A paid after toggle tap + 1 frame: ${h.entries.entries.firstWhere((e) => e.id == 'A').isPaid}');
    await uiDeleteRow(t, rA, fast: true); // immediately, while the toggle highlight animates
    await t.pump();
    snap(t, 'delete right after toggle, 1 frame');
    await t.pumpAndSettle();
    expect(logRows(t), isNot(contains(rA)));
    // paid -> open requires a confirm dialog
    await t.tap(paidBox(rB));
    await t.pumpAndSettle();
    await t.tap(find.text('Bestätigen'));
    await t.pump();
    await uiDeleteRow(t, rB, fast: true);
    await t.pumpAndSettle();
    snap(t, 'after unpay+delete B');
    expect(logRows(t), isNot(contains(rB)));
    expect(await storedIds(), ['C', 'D', 'E']);
    await h.dispose(t);
    resetScreen(t);
  });

  testWidgets('delete an entry created by the timer STOP flow (id = millisecondsSinceEpoch)', (t) async {
    final start = DateTime.now().subtract(const Duration(hours: 2, minutes: 3));
    final h = await startApp(t, entries: baseEntries(), extra: {'active_session': start.toIso8601String()});
    await pumpMs(t, 1100);
    await t.tap(find.text('STOPP'));
    await pumpMs(t, 400);
    await t.tap(find.text('Bestätigen'));
    await pumpMs(t, 600);
    final timerEntry = h.entries.entries.firstWhere((e) => !['A', 'B', 'C', 'D', 'E'].contains(e.id));
    obs('timer-created entry id=${timerEntry.id} range=${timerEntry.formattedTimeRange}');
    expect(int.tryParse(timerEntry.id), isNotNull);
    await goLog(t);
    await uiDeleteRow(t, timerEntry.formattedTimeRange);
    await t.pump();
    snap(t, 'timer entry deleted, 1 frame');
    await t.pumpAndSettle();
    expect(logRows(t), isNot(contains(timerEntry.formattedTimeRange)));
    expect(await storedIds(), isNot(contains(timerEntry.id)));
    await h.dispose(t);
    resetScreen(t);
  });

  group('duplicates', () {
    testWidgets('two entries with the SAME id: delete one row -> what disappears?', (t) async {
      final list = baseEntries()
        ..add(ent('X', DateTime(2026, 9, 25, 8), const Duration(hours: 8, minutes: 30)))
        ..add(ent('X', DateTime(2026, 9, 26, 8), const Duration(hours: 8, minutes: 35)));
      final h = await startApp(t, entries: list);
      await goLog(t);
      snap(t, 'dup-id before');
      await uiDeleteRow(t, '08:00 – 16:30');
      await t.pumpAndSettle();
      snap(t, 'dup-id after deleting the 16:30 row');
      obs('stored after: ${await storedIds()}');
      expect(logRows(t), isNot(contains('08:00 – 16:35')), reason: 'removeWhere removes both');
      await h.dispose(t);
      resetScreen(t);
    });

    testWidgets('two entries with the SAME id: toggling paid on one corrupts the other', (t) async {
      final list = [
        ent('X', DateTime(2026, 9, 25, 8), const Duration(hours: 8, minutes: 30)), // stored first
        ent('X', DateTime(2026, 9, 26, 8), const Duration(hours: 8, minutes: 35)), // shown first (newer)
      ];
      final h = await startApp(t, entries: list);
      await goLog(t);
      await t.tap(paidBox('08:00 – 16:35'));
      await t.pumpAndSettle();
      final p = await SharedPreferences.getInstance();
      obs('after toggling the 16:35 row: rows=${logRows(t)} stored=${p.getString('work_entries')}');
      await h.dispose(t);
      resetScreen(t);
    });

    testWidgets('two identical-looking entries (different ids): delete one -> identical row stays', (t) async {
      final list = baseEntries()
        ..add(ent('P', DateTime(2026, 9, 27, 8), const Duration(hours: 8, minutes: 40)))
        ..add(ent('Q', DateTime(2026, 9, 27, 8), const Duration(hours: 8, minutes: 40)));
      final h = await startApp(t, entries: list);
      await goLog(t);
      snap(t, 'identical before');
      await uiDeleteRow(t, '08:00 – 16:40');
      await t.pumpAndSettle();
      snap(t, 'identical after deleting one');
      obs('stored after: ${await storedIds()}');
      expect(logRows(t).where((r) => r == '08:00 – 16:40').length, 1);
      await h.dispose(t);
      resetScreen(t);
    });
  });

  group('double taps (B13 and the delete dialog)', () {
    testWidgets('Add dialog: Save tapped twice within the same frame', (t) async {
      final h = await startApp(t, entries: baseEntries());
      await goLog(t);
      await t.tap(find.byIcon(Icons.add));
      await t.pumpAndSettle();
      final save = find.widgetWithText(ElevatedButton, 'Speichern');
      final errs = await captureErrors(() async {
        await t.tap(save);
        await t.tap(save, warnIfMissed: false);
        await t.pump();
        snap(t, 'double save same frame, 1 frame');
        await t.pumpAndSettle();
      });
      snap(t, 'double save same frame, settled');
      obs('entries=${h.entries.entries.length} stored=${await storedIds()} MainScreen mounted=${find.byType(MainScreen).evaluate().length} '
          'errors=${errs.map((e) => e.summary).toList()} texts=${visibleTexts(t).take(12).toList()}');
      await h.dispose(t);
      resetScreen(t);
    });

    testWidgets('Add dialog: Save tapped twice 1 frame (16ms) apart', (t) async {
      final h = await startApp(t, entries: baseEntries());
      await goLog(t);
      await t.tap(find.byIcon(Icons.add));
      await t.pumpAndSettle();
      final save = find.widgetWithText(ElevatedButton, 'Speichern');
      await t.tap(save);
      await t.pump(const Duration(milliseconds: 16));
      await t.tap(save, warnIfMissed: false);
      await t.pumpAndSettle();
      obs('16ms apart: entries=${h.entries.entries.length} MainScreen mounted=${find.byType(MainScreen).evaluate().length}');
      await h.dispose(t);
      resetScreen(t);
    });

    testWidgets('Delete confirm tapped twice within the same frame', (t) async {
      final h = await startApp(t, entries: baseEntries());
      await goLog(t);
      await t.tap(find.text(rA));
      await t.pumpAndSettle();
      await t.tap(find.descendant(of: find.byType(BottomSheet), matching: find.text('Löschen')));
      await t.pumpAndSettle();
      final btn = find.widgetWithText(ElevatedButton, 'Löschen');
      final errs = await captureErrors(() async {
        await t.tap(btn);
        await t.tap(btn, warnIfMissed: false);
        await t.pump();
        await t.pumpAndSettle();
      });
      obs('delete double-confirm: entries=${h.entries.entries.length} MainScreen mounted=${find.byType(MainScreen).evaluate().length} '
          'errors=${errs.map((e) => e.summary).toList()} visible=${visibleTexts(t).take(10).toList()}');
      await h.dispose(t);
      resetScreen(t);
    });

    testWidgets('Sheet "Löschen" tapped twice within the same frame', (t) async {
      final h = await startApp(t, entries: baseEntries());
      await goLog(t);
      await t.tap(find.text(rA));
      await t.pumpAndSettle();
      final opt = find.descendant(of: find.byType(BottomSheet), matching: find.text('Löschen'));
      final errs = await captureErrors(() async {
        await t.tap(opt);
        await t.tap(opt, warnIfMissed: false);
        await t.pumpAndSettle();
      });
      obs('sheet double tap: dialogs=${find.byType(AlertDialog).evaluate().length} errors=${errs.map((e) => e.summary).toList()}');
      if (find.byType(AlertDialog).evaluate().isNotEmpty) {
        await t.tap(find.widgetWithText(ElevatedButton, 'Löschen'));
        await t.pumpAndSettle();
      }
      snap(t, 'after sheet double tap + confirm');
      await h.dispose(t);
      resetScreen(t);
    });
  });

  testWidgets('storage vs memory consistency: "restart" (fresh providers on same prefs) after each delete', (t) async {
    final h = await startApp(t, entries: baseEntries());
    await goLog(t);
    await uiDeleteRow(t, rB);
    await t.pumpAndSettle();
    final visible = logRows(t);
    final p = await SharedPreferences.getInstance();
    final raw = p.getString('work_entries')!;
    final restartedIds = (json.decode(raw) as List).map((e) => e['id']).toList();
    obs('visible after delete=$visible ; persisted ids (what a restart would load)=$restartedIds');
    expect(restartedIds, ['A', 'C', 'D', 'E']);
    expect(visible, [rA, rC, rD, rE]);
    await h.dispose(t);
    resetScreen(t);
  });
}
