// Task A.1/A.2: single-entry delete through the real UI.
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';
import 'verify_delete_common.dart';

Future<void> checkDelete(WidgetTester tester, String target, String targetId,
    {bool longPress = false, bool fast = false, List<Map<String, Object>>? entries, String lang = 'german'}) async {
  final h = await startApp(tester, entries: entries ?? baseEntries(), lang: lang);
  final homeBefore = homeAmounts(tester);
  await goLog(tester);
  final before = logRows(tester);
  snap(tester, 'before delete $target');
  final errs = await captureErrors(() async {
    await uiDeleteRow(tester, target, longPress: longPress, fast: fast, lang: lang);
    snap(tester, 'right after confirm tap (no pump)');
    await tester.pump();
    snap(tester, 'after pump()');
    await tester.pump(const Duration(milliseconds: 16));
    snap(tester, 'after pump(16ms)');
    await tester.pumpAndSettle();
    snap(tester, 'after pumpAndSettle');
  });
  final afterRows = logRows(tester);
  expect(afterRows.contains(target), isFalse, reason: 'deleted row still visible: $afterRows');
  expect(afterRows.length, before.length - 1);
  expect(await storedIds(), isNot(contains(targetId)));
  expect(h.entries.entries.any((e) => e.id == targetId), isFalse);
  await goHome(tester);
  snap(tester, 'after going Home (before=$homeBefore)');
  await goLog(tester);
  snap(tester, 'after going back to Log');
  expect(logRows(tester), afterRows);
  obs('errors: ${errs.map((e) => e.summary).toList()}');
  expect(errs, isEmpty);
  await h.dispose(tester);
  resetScreen(tester);
}

void main() {
  setUpAll(() async => loadRealFonts());

  group('single delete via tap', () {
    testWidgets('first row (A, open, Sep)', (t) => checkDelete(t, rA, 'A'));
    testWidgets('middle row (B, paid)', (t) => checkDelete(t, rB, 'B'));
    testWidgets('row alone in its month (D, Aug) -> header disappears', (t) async {
      await checkDelete(t, rD, 'D');
    });
    testWidgets('last row (E, paid, alone in Jul)', (t) => checkDelete(t, rE, 'E'));
    testWidgets('English UI', (t) => checkDelete(t, rC, 'C', lang: 'english'));
  });

  group('single delete via long-press', () {
    testWidgets('first row', (t) => checkDelete(t, rA, 'A', longPress: true));
    testWidgets('last row', (t) => checkDelete(t, rE, 'E', longPress: true));
  });

  group('fast taps (1 frame between steps)', () {
    testWidgets('tap path', (t) => checkDelete(t, rC, 'C', fast: true));
    testWidgets('long-press path', (t) => checkDelete(t, rB, 'B', longPress: true, fast: true));
  });

  testWidgets('only row -> empty state; Home open total -> 0', (t) async {
    final h = await startApp(t, entries: [baseEntries().first]);
    obs('home before: ${homeAmounts(t)} painted=${homeOpenPainted(t)}');
    await goLog(t);
    await uiDeleteRow(t, rA);
    await t.pump();
    snap(t, 'only-row after 1 pump');
    await t.pumpAndSettle();
    snap(t, 'only-row settled');
    expect(logEmptyShown(t), isTrue);
    await goHome(t);
    obs('home after: ${homeAmounts(t)} painted=${homeOpenPainted(t)}');
    expect(homeAmounts(t)[1], 0.0);
    expect(homeOpenPainted(t), '0,00€');
    await h.dispose(t);
    resetScreen(t);
  });

  testWidgets('delete every row one after another', (t) async {
    final h = await startApp(t, entries: baseEntries());
    await goLog(t);
    for (final r in [rC, rA, rE, rB, rD]) {
      await uiDeleteRow(t, r);
      await t.pumpAndSettle();
      snap(t, 'after deleting $r');
      expect(logRows(t), isNot(contains(r)));
    }
    expect(logEmptyShown(t), isTrue);
    expect(await storedIds(), isEmpty);
    await h.dispose(t);
    resetScreen(t);
  });

  testWidgets('Home open total after deleting open (A) vs paid (B)', (t) async {
    final h = await startApp(t, entries: baseEntries());
    obs('home before: ${homeAmounts(t)} painted=${homeOpenPainted(t)}');
    await goLog(t);
    await uiDeleteRow(t, rB);
    await t.pumpAndSettle();
    await goHome(t);
    obs('home after deleting paid B: ${homeAmounts(t)} painted=${homeOpenPainted(t)}');
    expect(homeAmounts(t)[1], closeTo(370.0, 1e-9));
    await goLog(t);
    await uiDeleteRow(t, rA);
    await t.pumpAndSettle();
    await goHome(t);
    obs('home after deleting open A: ${homeAmounts(t)} painted=${homeOpenPainted(t)}');
    expect(homeAmounts(t)[1], closeTo(248.75, 1e-9));
    expect(homeOpenPainted(t), '248,75€');
    await h.dispose(t);
    resetScreen(t);
  });

  group('animations disabled / time dilation', () {
    testWidgets('disableAnimations=true', (t) async {
      t.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
      await checkDelete(t, rA, 'A');
      await checkDelete(t, rB, 'B', fast: true);
      t.platformDispatcher.clearAccessibilityFeaturesTestValue();
    });
    testWidgets('timeDilation=5 (slow animations), fast taps', (t) async {
      timeDilation = 5.0;
      try {
        await checkDelete(t, rD, 'D', fast: true);
      } finally {
        timeDilation = 1.0;
      }
    });
    testWidgets('timeDilation=0.05 (near-instant animations)', (t) async {
      timeDilation = 0.05;
      try {
        await checkDelete(t, rC, 'C', fast: true);
      } finally {
        timeDilation = 1.0;
      }
    });
  });

  testWidgets('tap sheet option & confirm with ZERO frames pumped in between', (t) async {
    final h = await startApp(t, entries: baseEntries());
    await goLog(t);
    await t.tap(find.text(rA));
    await t.pump(); // sheet route pushed, first frame (animation value ~0)
    final opt = find.descendant(of: find.byType(BottomSheet), matching: find.text('Löschen'));
    obs('sheet option y at t=0: ${t.getCenter(opt).dy} (screen 1600) -> off-screen, a real finger cannot hit it');
    await t.pump(const Duration(milliseconds: 120));
    final errs = await captureErrors(() async {
      // sheet at t=0 of its entrance animation: is the option hittable?
      await t.tap(find.descendant(of: find.byType(BottomSheet), matching: find.text('Löschen')), warnIfMissed: false);
      await t.pump();
      obs('dialog shown after 1 frame: ${find.byType(AlertDialog).evaluate().length}');
      await t.tap(find.widgetWithText(ElevatedButton, 'Löschen'), warnIfMissed: false);
      await t.pump();
      snap(t, 'zero-frame path after 1 pump');
      await t.pumpAndSettle();
      snap(t, 'zero-frame path settled');
    });
    obs('errors: ${errs.map((e) => e.summary).toList()}');
    expect(logRows(t), isNot(contains(rA)));
    await h.dispose(t);
    resetScreen(t);
  });
}
