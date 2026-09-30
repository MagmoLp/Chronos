// Task A.5/A.6/A.7: delete with a realistic (slow / failing) platform store, tab switches mid cross-fade,
// double taps (B13) under write latency, and error injection.
import 'dart:async';
import 'dart:convert';

import 'package:chronos/main.dart';
import 'package:chronos/providers/settings_provider.dart';
import 'package:chronos/providers/timer_provider.dart';
import 'package:chronos/providers/work_entries_provider.dart';
import 'package:chronos/services/notification_service.dart';
import 'package:chronos/services/storage_service.dart';
import 'package:chronos/widgets/animated_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import 'helpers.dart';
import 'verify_delete_common.dart';

/// Emulates the Android legacy plugin: every write is a platform round trip that
/// completes after [latency] (commit() on a background task queue). Optionally the
/// next write throws after it hit "disk" (reply lost) or before (write failed), or never replies.
class SlowStore extends InMemorySharedPreferencesStore {
  SlowStore(Map<String, Object> data) : super.withData(data) {
    _disk.addAll(data);
  }
  Duration latency = Duration.zero;
  String? failNext; // 'afterWrite' | 'beforeWrite' | 'hang'
  Map<String, Object> get disk => _disk;
  final Map<String, Object> _disk = {};

  Future<bool> _io(Future<bool> Function() op) async {
    final mode = failNext;
    failNext = null;
    if (latency > Duration.zero) await Future<void>.delayed(latency);
    if (mode == 'hang') return Completer<bool>().future;
    if (mode == 'beforeWrite') throw PlatformException(code: 'error', message: 'commit failed');
    final r = await op();
    _disk
      ..clear()
      ..addAll(await getAll());
    if (mode == 'afterWrite') throw PlatformException(code: 'error', message: 'reply lost');
    return r;
  }

  @override
  Future<bool> setValue(String valueType, String key, Object value) => _io(() => super.setValue(valueType, key, value));
  @override
  Future<bool> remove(String key) => _io(() => super.remove(key));
}

late SlowStore store;

Future<AppHarness> bootSlow(WidgetTester t, Map<String, Object> prefs) async {
  installNotificationStub();
  setScreen(t, const Size(500, 1600));
  SharedPreferences.setMockInitialValues({});
  store = SlowStore({for (final e in prefs.entries) 'flutter.${e.key}': e.value});
  SharedPreferencesStorePlatform.instance = store;
  await StorageService().init();
  final settings = SettingsProvider();
  await settings.loadSettings();
  final entries = WorkEntriesProvider();
  await entries.loadEntries();
  await NotificationService().init();
  final timer = TimerProvider();
  timer.setHourlyWage(settings.hourlyWage);
  await timer.loadActiveSession();
  final h = AppHarness(settings, entries, timer);
  await t.pumpWidget(h.app);
  await t.pumpAndSettle();
  return h;
}

List<String> diskIds() {
  final s = store.disk['flutter.work_entries'] as String?;
  if (s == null) return ['<absent>'];
  return (json.decode(s) as List).map((e) => e['id'] as String).toList();
}

Finder rowItem(String range) => find.ancestor(of: find.text(range), matching: find.byType(AnimatedListItem)).first;
Finder paidBox(String range) => find.descendant(
    of: rowItem(range),
    matching: find.byWidgetPredicate((w) => w is AnimatedContainer && w.constraints == const BoxConstraints.tightFor(width: 28, height: 28)));

Map<String, Object> basePrefs() => {'app_settings': settingsJson(), 'work_entries': json.encode(baseEntries())};

void main() {
  setUpAll(() async => loadRealFonts());

  testWidgets('latency 250ms: how long does the deleted row stay visible?', (t) async {
    final h = await bootSlow(t, basePrefs());
    store.latency = const Duration(milliseconds: 250);
    await goLog(t);
    await uiDeleteRow(t, rA);
    final seen = <String>[];
    for (var ms = 0; ms <= 400; ms += 50) {
      seen.add('${ms}ms:${logRows(t).contains(rA) ? 'A visible' : 'A gone'}');
      await t.pump(const Duration(milliseconds: 50));
    }
    obs('row visibility over time with 250ms write latency: $seen');
    await t.pumpAndSettle();
    expect(logRows(t), isNot(contains(rA)));
    await h.dispose(t);
    resetScreen(t);
  });

  testWidgets('latency 250ms: toggle paid on the row being deleted inside the window -> resurrection?', (t) async {
    final h = await bootSlow(t, basePrefs());
    store.latency = const Duration(milliseconds: 250);
    await goLog(t);
    await uiDeleteRow(t, rA);
    await t.pump(const Duration(milliseconds: 60)); // dialog fading out, row still shown
    final stillThere = logRows(t).contains(rA);
    if (stillThere) {
      await t.tap(paidBox(rA), warnIfMissed: false);
    }
    await t.pump(const Duration(milliseconds: 600));
    await t.pumpAndSettle();
    snap(t, 'after delete A + toggle A within window (tapped=$stillThere)');
    obs('provider=${h.entries.entries.map((e) => '${e.id}${e.isPaid ? '(paid)' : ''}').toList()} disk=${diskIds()}');
    await h.dispose(t);
    resetScreen(t);
  });

  testWidgets('latency 250ms: open the same row again & delete a second time within the window', (t) async {
    final h = await bootSlow(t, basePrefs());
    store.latency = const Duration(milliseconds: 250);
    await goLog(t);
    await uiDeleteRow(t, rC);
    await t.pump(const Duration(milliseconds: 60));
    final errs = await captureErrors(() async {
      if (logRows(t).contains(rC)) {
        await t.tap(find.text(rC), warnIfMissed: false);
        for (var i = 0; i < 20; i++) {
          await t.pump(const Duration(milliseconds: 16));
        }
        obs('sheet open after re-tap: ${find.byType(BottomSheet).evaluate().length}; rows now=${logRows(t)}');
        if (find.byType(BottomSheet).evaluate().isNotEmpty) {
          await t.tap(find.descendant(of: find.byType(BottomSheet), matching: find.text('Löschen')));
          for (var i = 0; i < 20; i++) {
            await t.pump(const Duration(milliseconds: 16));
          }
          await t.tap(find.widgetWithText(ElevatedButton, 'Löschen'));
        }
      }
      await t.pumpAndSettle();
    });
    snap(t, 'after double delete of C');
    obs('errors=${errs.map((e) => e.summary).toList()} disk=${diskIds()}');
    expect(logRows(t), isNot(contains(rC)));
    await h.dispose(t);
    resetScreen(t);
  });

  for (final lat in [50, 120, 200, 400]) {
    testWidgets('B13 latency ${lat}ms: Save double-tapped 90ms apart in Add dialog', (t) async {
      final h = await bootSlow(t, basePrefs());
      store.latency = Duration(milliseconds: lat);
      await goLog(t);
      await t.tap(find.byIcon(Icons.add));
      await t.pumpAndSettle();
      final save = find.widgetWithText(ElevatedButton, 'Speichern');
      final errs = await captureErrors(() async {
        await t.tap(save);
        for (var i = 0; i < 6; i++) {
          await t.pump(const Duration(milliseconds: 15));
        }
        await t.tap(save, warnIfMissed: false);
        for (var i = 0; i < 60; i++) {
          await t.pump(const Duration(milliseconds: 25));
        }
      });
      final main = find.byType(MainScreen).evaluate().length;
      obs('latency ${lat}ms: provider entries=${h.entries.entries.length} disk=${diskIds().length} '
          'MainScreen mounted=$main visibleTexts=${visibleTexts(t).take(6).toList()} errors=${errs.map((e) => e.summary).toList()}');
      await h.dispose(t);
      resetScreen(t);
    });
  }

  testWidgets('latency 300ms: delete, then immediately switch to Home and back (mid cross-fade)', (t) async {
    final h = await bootSlow(t, basePrefs());
    store.latency = const Duration(milliseconds: 300);
    await goLog(t);
    await uiDeleteRow(t, rA);
    await t.pump(const Duration(milliseconds: 20));
    await goHome(t, settle: false);
    await t.pump(const Duration(milliseconds: 100));
    snap(t, '120ms: switched to Home mid-delete');
    await goLog(t, settle: false);
    await t.pump(const Duration(milliseconds: 100));
    snap(t, '220ms: switched back to Log (cross-fade)');
    await t.pump(const Duration(milliseconds: 200));
    snap(t, '420ms: write done');
    await t.pumpAndSettle();
    snap(t, 'settled');
    expect(logRows(t), isNot(contains(rA)));
    await h.dispose(t);
    resetScreen(t);
  });

  for (final mode in ['afterWrite', 'beforeWrite', 'hang']) {
    testWidgets('error injection "$mode" on the delete write', (t) async {
      final h = await bootSlow(t, basePrefs());
      await goLog(t);
      store.failNext = mode;
      final errs = <Object>[];
      await runZonedGuarded(() async {
        await uiDeleteRow(t, rB);
        await t.pumpAndSettle();
      }, (e, s) => errs.add(e));
      final snackbar = visibleTexts(t).any((s) => s.contains('Eintrag gelöscht'));
      snap(t, '[$mode] after delete');
      obs('[$mode] snackbar=$snackbar providerIds=${h.entries.entries.map((e) => e.id).toList()} '
          'prefsCache=${await storedIds()} disk(=after restart)=${diskIds()} uncaught=$errs '
          'takeErrors=${t.takeException()}');
      // next unrelated action that reloads: toggle paid on A
      await t.tap(paidBox(rA));
      await t.pumpAndSettle();
      snap(t, '[$mode] after an unrelated paid toggle');
      await h.dispose(t);
      resetScreen(t);
    });
  }
}
