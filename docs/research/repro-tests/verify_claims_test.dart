// Task B: adversarial verification of audit claims B04 B10 B12 B13 B16 B27 B28 B30 B35 B39.
import 'dart:async';
import 'dart:convert';

import 'package:chronos/main.dart' as app;
import 'package:chronos/main.dart';
import 'package:chronos/widgets/animated_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';
import 'verify_delete_common.dart';
import 'verify_delete_slowstore_test.dart' as slow show bootSlow, store, basePrefs, diskIds;

Future<void> frames(WidgetTester t, int ms) async {
  for (var i = 0; i < ms ~/ 16; i++) {
    await t.pump(const Duration(milliseconds: 16));
  }
}

Finder rowItem(String range) => find.ancestor(of: find.text(range), matching: find.byType(AnimatedListItem)).first;

void main() {
  setUpAll(() async => loadRealFonts());

  group('B04 stop() clears the session before the entry is saved', () {
    for (final (lat, switchTab) in [(400, false), (100, true), (250, true), (350, true), (400, true)]) {
      testWidgets('latency ${lat}ms, switch to Log right after confirming=$switchTab', (t) async {
        final start = DateTime.now().subtract(const Duration(hours: 2));
        final h = await slow.bootSlow(t, {
          ...slow.basePrefs(),
          'active_session': start.toIso8601String(),
        });
        slow.store.latency = Duration(milliseconds: lat);
        await frames(t, 1100);
        await t.tap(find.text('STOPP'));
        await frames(t, 400);
        final zoneErrors = <Object>[];
        await runZonedGuarded(() async {
          await t.tap(find.text('Bestätigen'));
          if (switchTab) {
            await frames(t, 48); // dialog is reversing -> its barrier ignores pointers
            await t.tap(find.byIcon(Icons.format_list_bulleted), warnIfMissed: true);
          }
          await frames(t, 2500);
        }, (e, s) => zoneErrors.add(e));
        final pending = t.takeException();
        obs('B04 latency=${lat}ms uncaught: ${zoneErrors.map((e) => e.toString().split('\n').first).toList()} '
            'framework-reported: ${pending?.toString().split('\n').first}');
        final p = await SharedPreferences.getInstance();
        obs('B04 latency=${lat}ms switchTab=$switchTab: entries=${h.entries.entries.length} (5 before) '
            'active_session in cache=${p.getString('active_session')} disk=${slow.store.disk.containsKey('flutter.active_session')} '
            'timer.isRunning=${h.timer.isRunning} diskIds=${slow.diskIds().length}');
        await h.dispose(t);
        resetScreen(t);
      });
    }
  });

  testWidgets('B13 Edit dialog: Save double-tapped 90ms apart with 200ms write latency', (t) async {
    final h = await slow.bootSlow(t, slow.basePrefs());
    await goLog(t);
    await t.tap(find.text(rA));
    await t.pumpAndSettle();
    await t.tap(find.text('Eintrag bearbeiten'));
    await t.pumpAndSettle();
    slow.store.latency = const Duration(milliseconds: 200);
    final save = find.widgetWithText(ElevatedButton, 'Speichern');
    await t.tap(save);
    await frames(t, 90);
    await t.tap(save, warnIfMissed: false);
    await frames(t, 1500);
    obs('B13-edit: entries=${h.entries.entries.length} MainScreen mounted=${find.byType(MainScreen).evaluate().length} '
        'visible=${visibleTexts(t).take(5).toList()}');
    await h.dispose(t);
    resetScreen(t);
  });

  testWidgets('B12 no overlap/duplicate detection: add the default 08:00-16:00 twice', (t) async {
    final h = await startApp(t, entries: baseEntries());
    await goLog(t);
    for (var i = 0; i < 2; i++) {
      await t.tap(find.byIcon(Icons.add));
      await t.pumpAndSettle();
      await t.tap(find.widgetWithText(ElevatedButton, 'Speichern'));
      await t.pumpAndSettle();
    }
    obs('B12: rows=${logRows(t)} warnings=${visibleTexts(t).where((s) => s.toLowerCase().contains('überl') || s.toLowerCase().contains('doppel')).toList()}');
    expect(logRows(t).where((r) => r == '08:00 – 16:00').length, 2);
    await h.dispose(t);
    resetScreen(t);
  });

  testWidgets('B10 first launch with device locale en_US', (t) async {
    t.platformDispatcher.localesTestValue = const [Locale('en', 'US')];
    t.platformDispatcher.localeTestValue = const Locale('en', 'US');
    installNotificationStub();
    setScreen(t, const Size(500, 1600));
    final h = await bootApp({}); // no app_settings -> first launch
    await t.pumpWidget(h.app);
    await t.pumpAndSettle();
    final texts = visibleTexts(t);
    obs('B10: settings.language=${h.settings.language} texts=${texts.take(8).toList()}');
    expect(texts, contains('Aktueller Verdienst'));
    await h.dispose(t);
    t.platformDispatcher.clearLocalesTestValue();
    t.platformDispatcher.clearLocaleTestValue();
    resetScreen(t);
  });

  testWidgets('B16 permission request pending -> runApp not called, no first frame', (t) async {
    installNotificationStub();
    final pending = Completer<bool>();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(notifChannel, (call) async {
      notificationCalls.add(call);
      if (call.method == 'requestNotificationsPermission') return pending.future;
      if (call.method == 'initialize') return true;
      return null;
    });
    SharedPreferences.setMockInitialValues({});
    setScreen(t, const Size(500, 1600));
    app.main();
    await t.pump(const Duration(seconds: 5));
    final before = find.byType(ChronosApp).evaluate().length;
    final calls = notificationCalls.map((c) => c.method).toList();
    pending.complete(true);
    await t.pump();
    await t.pump(const Duration(seconds: 1));
    final after = find.byType(ChronosApp).evaluate().length;
    obs('B16: ChronosApp mounted while permission dialog pending (5s)=$before ; after answer=$after ; channel calls=$calls');
    expect(before, 0);
    expect(after, 1);
    await t.pumpWidget(const SizedBox());
    resetScreen(t);
  });

  testWidgets('B30 unkeyed rows: paid highlight of deleted row B lingers on row C', (t) async {
    final h = await startApp(t, entries: baseEntries());
    await goLog(t);
    BoxDecoration deco(String r) {
      final db = find.descendant(of: rowItem(r), matching: find.byType(DecoratedBox)).first;
      return t.widget<DecoratedBox>(db).decoration as BoxDecoration;
    }
    final cBefore = deco(rC);
    final bBefore = deco(rB);
    await uiDeleteRow(t, rB);
    await t.pump(); // delete applied in this frame
    final samples = <String>[];
    for (var ms = 0; ms <= 350; ms += 50) {
      final d = deco(rC);
      samples.add('+${ms}ms border=${d.border != null} color=${d.color}');
      await t.pump(const Duration(milliseconds: 50));
    }
    obs('B30: C before: border=${cBefore.border != null} color=${cBefore.color}; B(paid) before: border=${bBefore.border != null} color=${bBefore.color}');
    obs('B30: row C after B deleted: $samples');
    await t.pumpAndSettle();
    await h.dispose(t);
    resetScreen(t);
  });

  testWidgets('B35 Android back on Log tab + scroll position after tab switch', (t) async {
    final list = <Map<String, Object>>[
      for (var i = 0; i < 40; i++) ent('s$i', DateTime(2026, 9, 29, 8).subtract(Duration(days: i)), const Duration(hours: 8)),
    ];
    final h = await startApp(t, entries: list, size: const Size(500, 900));
    final sysCalls = <String>[];
    t.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      sysCalls.add(call.method);
      return null;
    });
    await goLog(t);
    await t.drag(find.byType(ListView), const Offset(0, -1500));
    await t.pumpAndSettle();
    final before = t.state<ScrollableState>(find.byType(Scrollable).first).position.pixels;
    await goHome(t);
    await goLog(t);
    final after = t.state<ScrollableState>(find.byType(Scrollable).first).position.pixels;
    obs('B35: scroll before tab switch=$before after=$after');
    final handled = await t.binding.handlePopRoute();
    await t.pumpAndSettle();
    obs('B35: back on Log tab -> handlePopRoute=$handled platform calls=$sysCalls ; still on Log=${find.text('Arbeitszeit-Protokoll').evaluate().isNotEmpty}');
    t.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null);
    await h.dispose(t);
    resetScreen(t);
  });

  for (final year in [2031, 2019]) {
    testWidgets('B27 edit an entry dated $year -> open date picker', (t) async {
      final h = await startApp(t, entries: [ent('Y', DateTime(year, 3, 1, 8), const Duration(hours: 8))]);
      await goLog(t);
      await t.tap(find.text('08:00 – 16:00'));
      await t.pumpAndSettle();
      await t.tap(find.text('Eintrag bearbeiten'));
      await t.pumpAndSettle();
      final zoneErrors = <Object>[];
      await runZonedGuarded(() async {
        await t.tap(find.byIcon(Icons.calendar_today));
        await t.pump();
      }, (e, s) => zoneErrors.add(e));
      obs('B27 $year: pickers open=${find.byType(DatePickerDialog).evaluate().length} '
          'error=${zoneErrors.map((e) => e.toString().split('\n').first).toList()}');
      expect(zoneErrors, isNotEmpty);
      await t.pumpAndSettle();
      await h.dispose(t);
      resetScreen(t);
    });
  }

  testWidgets('B27 add dialog: lastDate & future dates', (t) async {
    final h = await startApp(t, entries: []);
    await goLog(t);
    await t.tap(find.byIcon(Icons.add));
    await t.pumpAndSettle();
    await t.tap(find.byIcon(Icons.calendar_today));
    await t.pumpAndSettle();
    final dp = t.widget<DatePickerDialog>(find.byType(DatePickerDialog));
    obs('B27 add: firstDate=${dp.firstDate} lastDate=${dp.lastDate} initial=${dp.initialDate} (today ${DateTime.now()})');
    await t.tap(find.text('Abbrechen').last);
    await t.pumpAndSettle();
    await h.dispose(t);
    resetScreen(t);
  });

  testWidgets('B28 edit a 30h entry and save unchanged', (t) async {
    final h = await startApp(t, entries: [ent('L', DateTime(2026, 9, 20, 8), const Duration(hours: 30))]);
    await goLog(t);
    final r = logRows(t).single;
    await t.tap(find.text(r));
    await t.pumpAndSettle();
    await t.tap(find.text('Eintrag bearbeiten'));
    await t.pumpAndSettle();
    await t.tap(find.widgetWithText(ElevatedButton, 'Speichern'));
    await t.pumpAndSettle();
    final e = h.entries.entries.single;
    obs('B28: before 30h ($r) -> after save: ${e.startTime} - ${e.endTime} = ${e.duration}');
    await h.dispose(t);
    resetScreen(t);
  });

  testWidgets('B39 current earnings after stopping a session today', (t) async {
    final start = DateTime.now().subtract(const Duration(hours: 2));
    final h = await startApp(t, entries: [], extra: {'active_session': start.toIso8601String()});
    await frames(t, 1100);
    final running = homeAmounts(t);
    await t.tap(find.text('STOPP'));
    await frames(t, 400);
    await t.tap(find.text('Bestätigen'));
    await frames(t, 800);
    obs('B39: while running=$running ; after stop (today has ${h.entries.entries.length} entry of ${h.entries.entries.firstOrNull?.duration}) '
        'current/open=${homeAmounts(t)}');
    await h.dispose(t);
    resetScreen(t);
  });

  testWidgets('NEW: double-tap on a row opens and immediately dismisses the sheet', (t) async {
    final h = await startApp(t, entries: baseEntries());
    await goLog(t);
    await t.tap(find.text(rA));
    await frames(t, 120);
    await t.tap(find.text(rA), warnIfMissed: false);
    await t.pumpAndSettle();
    obs('double-tap row: sheets open=${find.byType(BottomSheet).evaluate().length}');
    await h.dispose(t);
    resetScreen(t);
  });

  testWidgets('delete-all from Settings (opened on Home) while the timer runs', (t) async {
    final start = DateTime.now().subtract(const Duration(hours: 1));
    final h = await startApp(t, entries: baseEntries(), extra: {'active_session': start.toIso8601String()});
    await frames(t, 1100);
    await t.tap(find.byIcon(Icons.settings));
    await frames(t, 600);
    await t.tap(find.text('Alle Einträge löschen'));
    await frames(t, 400);
    await t.enterText(find.byType(TextField).last, 'Löschen');
    await t.pump();
    await t.tap(find.widgetWithText(ElevatedButton, 'Löschen'));
    await frames(t, 600);
    await t.tap(find.byIcon(Icons.arrow_back));
    await frames(t, 1200);
    final a = homeAmounts(t);
    obs('delete-all with timer running: home current/open=$a (open should equal current) stored=${await storedIds()}');
    expect((a[1] - a[0]).abs() < 0.01, isTrue);
    await h.dispose(t);
    resetScreen(t);
  });

  test('json sanity', () => expect(json.encode([1]), '[1]'));
}
