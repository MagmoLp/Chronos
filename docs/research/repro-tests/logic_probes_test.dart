// Item 5: Logic probes (unit + small widget tests).
//
// Every test PRINTS what it observed ("OBS: ...") and asserts the CURRENT
// behaviour of the app, so the file documents the behaviour and turns red when
// someone fixes / changes it. Tests whose name starts with "BUG" assert the
// buggy behaviour on purpose.

import 'dart:io';

import 'package:chronos/main.dart' as app;
import 'package:chronos/models/app_settings.dart';
import 'package:chronos/models/work_entry.dart';
import 'package:chronos/providers/settings_provider.dart';
import 'package:chronos/providers/timer_provider.dart';
import 'package:chronos/providers/work_entries_provider.dart';
import 'package:chronos/services/storage_service.dart';
import 'package:chronos/widgets/animated_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

// ignore: avoid_print
void obs(String s) => print('OBS: $s');

WorkEntry entry(String id, DateTime start, DateTime end, {bool paid = false}) => WorkEntry(
      id: id,
      date: DateTime(start.year, start.month, start.day),
      startTime: start,
      endTime: end,
      isPaid: paid,
    );

/// Exact copy of HomeScreen._roundToQuarter (lib/screens/home_screen.dart:198-206).
/// A test below verifies that the source still contains exactly these lines.
DateTime roundToQuarterCopy(DateTime time) {
  final totalMinutes = time.hour * 60 + time.minute;
  final remainder = totalMinutes % 15;
  final rounded = remainder < 7
      ? totalMinutes - remainder
      : totalMinutes + (15 - remainder);
  final base = DateTime(time.year, time.month, time.day);
  return base.add(Duration(minutes: rounded));
}

/// Exact copy of the end-time computation in the add/edit dialogs
/// (lib/screens/work_log_screen.dart:536-553 and 735-752).
DateTime dialogEnd(DateTime selectedDate, TimeOfDay start, TimeOfDay end) {
  final startDateTime =
      DateTime(selectedDate.year, selectedDate.month, selectedDate.day, start.hour, start.minute);
  DateTime endDateTime =
      DateTime(selectedDate.year, selectedDate.month, selectedDate.day, end.hour, end.minute);
  if (!endDateTime.isAfter(startDateTime)) {
    endDateTime = endDateTime.add(const Duration(days: 1));
  }
  return endDateTime;
}

void main() {
  setUpAll(() async => loadRealFonts());

  group('copies are faithful', () {
    test('roundToQuarterCopy matches source', () {
      final src = File('lib/screens/home_screen.dart').readAsStringSync();
      for (final line in [
        'final totalMinutes = time.hour * 60 + time.minute;',
        'final remainder = totalMinutes % 15;',
        'final rounded = remainder < 7',
        '? totalMinutes - remainder',
        ': totalMinutes + (15 - remainder);',
        'final base = DateTime(time.year, time.month, time.day);',
        'return base.add(Duration(minutes: rounded));',
      ]) {
        expect(src.contains(line), isTrue, reason: line);
      }
      final wl = File('lib/screens/work_log_screen.dart').readAsStringSync();
      expect(RegExp(r'if \(!endDateTime\.isAfter\(startDateTime\)\) \{\s*endDateTime = endDateTime\.add\(const Duration\(days: 1\)\);')
              .allMatches(wl)
              .length,
          2);
    });
  });

  group('wage calculation precision', () {
    test('12.82 EUR/h for 7h13m', () {
      final s = DateTime(2026, 9, 1, 8, 0);
      final e = entry('a', s, s.add(const Duration(hours: 7, minutes: 13)));
      final v = e.calculateEarnings(12.82);
      obs('7h13m @ 12.82 = $v -> "${v.toStringAsFixed(2)}" (exact 92.51766..)');
      expect(v.toStringAsFixed(2), '92.52');
    });

    test('BUG: seconds are truncated in stored entries but not in live counter', () {
      final s = DateTime(2026, 9, 1, 8, 0);
      final e = entry('a', s, s.add(const Duration(minutes: 59, seconds: 59)));
      obs('59m59s @ 60 EUR/h -> entry ${e.calculateEarnings(60)} (inMinutes truncation)');
      expect(e.calculateEarnings(60), 59.0);
    });

    test('BUG: float rounding: toStringAsFixed(2) disagrees with commercial (half-up) rounding', () {
      // Exhaustive: every wage 0.01..60.00 EUR x every quarter-hour duration up to 12h.
      var mismatches = 0;
      var total = 0;
      final examples = <String>[];
      for (var cents = 1; cents <= 6000; cents++) {
        for (var q = 1; q <= 48; q++) {
          final minutes = q * 15;
          final s = DateTime(2026, 9, 1, 0, 0);
          final e = entry('x', s, s.add(Duration(minutes: minutes)));
          final shown = e.calculateEarnings(cents / 100).toStringAsFixed(2);
          // exact: cents*minutes/60 cents, half-up
          final num = cents * minutes; // in 1/60 cent
          final exactCents = (num * 2 + 60) ~/ 120; // floor(x + 0.5)
          final exact = '${exactCents ~/ 100}.${(exactCents % 100).toString().padLeft(2, '0')}';
          total++;
          if (shown != exact) {
            mismatches++;
            if (examples.length < 5 || (cents >= 1000 && cents % 5 == 0 && examples.length < 12)) {
              examples.add('${(cents / 100).toStringAsFixed(2)} EUR/h x ${minutes}min: app shows $shown, correct $exact');
            }
          }
        }
      }
      obs('rounding mismatches: $mismatches / $total combinations; e.g. ${examples.join('; ')}');
      expect(mismatches, greaterThan(0));
    });

    test('BUG: total != sum of displayed rows (sum of unrounded values)', () async {
      SharedPreferences.setMockInitialValues({});
      await StorageService().init();
      final p = WorkEntriesProvider();
      for (var i = 0; i < 3; i++) {
        final s = DateTime(2026, 9, 1 + i, 8, 0);
        await p.saveEntry(entry('r$i', s, s.add(const Duration(hours: 7, minutes: 13))));
      }
      final rows = p.entries.map((e) => double.parse(e.calculateEarnings(12.82).toStringAsFixed(2)));
      final sumRows = rows.reduce((a, b) => a + b);
      final total = p.totalOpenEarnings(12.82);
      obs('3 x 7h13m @12.82: rows show ${rows.toList()}, sum ${sumRows.toStringAsFixed(2)}; '
          'Home "total open" shows ${total.toStringAsFixed(2)}');
      expect(total.toStringAsFixed(2), isNot(sumRows.toStringAsFixed(2)));
    });
  });

  group('quarter-hour rounding (stop flow)', () {
    test('rounding table + minimum 15 min', () {
      String f(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
      final table = <String>[];
      for (final m in [0, 6, 7, 8, 14]) {
        final t = DateTime(2026, 9, 1, 8, m, 59);
        table.add('08:${m.toString().padLeft(2, '0')}:59->${f(roundToQuarterCopy(t))}');
      }
      obs('roundToQuarter: ${table.join(', ')}  (08:07 is 7 min from 08:00 and 8 min from 08:15, '
          'but rounds UP although the doc says "nearest")');
      expect(roundToQuarterCopy(DateTime(2026, 9, 1, 8, 7)), DateTime(2026, 9, 1, 8, 15));

      // 14 minutes of real work 08:07 -> 08:21 is rounded to 08:15 -> 08:15 = 0 min and DISCARDED,
      // while 08:06 -> 08:22 (16 min) becomes 08:00 -> 08:30 = 30 min.
      final lost = roundToQuarterCopy(DateTime(2026, 9, 1, 8, 21))
          .difference(roundToQuarterCopy(DateTime(2026, 9, 1, 8, 7)));
      final gained = roundToQuarterCopy(DateTime(2026, 9, 1, 8, 22))
          .difference(roundToQuarterCopy(DateTime(2026, 9, 1, 8, 6)));
      obs('08:07-08:21 (14 real min) -> $lost (discarded, <15min); 08:06-08:22 (16 real min) -> $gained');
      // 22 real minutes (08:08 -> 08:30) -> 08:15-08:30 = 15 min, 20 real min 08:07-08:27 -> 08:15-08:30
      final long = roundToQuarterCopy(DateTime(2026, 9, 1, 8, 36))
          .difference(roundToQuarterCopy(DateTime(2026, 9, 1, 8, 22)));
      obs('08:22-08:36 (14 real min) -> $long -> kept? ${long >= const Duration(minutes: 15)}');
    });

    test('midnight: 23:53 rounds to next day 00:00', () {
      final r = roundToQuarterCopy(DateTime(2026, 9, 1, 23, 53));
      obs('23:53 -> $r');
      expect(r, DateTime(2026, 9, 2));
    });
  });

  group('entries spanning midnight', () {
    test('22:00 -> 06:00 next day', () {
      final s = DateTime(2026, 9, 1, 22, 0);
      final e = entry('n', s, DateTime(2026, 9, 2, 6, 0));
      obs('duration=${e.duration} overnight=${e.isOvernightShift} range="${e.formattedTimeRange}" '
          'dur="${e.formattedDuration}" earnings@15=${e.calculateEarnings(15)}');
      expect(e.duration, const Duration(hours: 8));
      expect(e.calculateEarnings(15), 120);
    });

    test('BUG: add/edit dialog silently turns end<start (or end==start) into an overnight shift', () {
      final d = DateTime(2026, 9, 1);
      final end1 = dialogEnd(d, const TimeOfDay(hour: 8, minute: 0), const TimeOfDay(hour: 7, minute: 0));
      final end2 = dialogEnd(d, const TimeOfDay(hour: 8, minute: 0), const TimeOfDay(hour: 8, minute: 0));
      obs('start 08:00 end 07:00 -> end $end1 (${end1.difference(DateTime(2026, 9, 1, 8))}); '
          'start==end 08:00 -> ${end2.difference(DateTime(2026, 9, 1, 8))} entry. '
          'l10n key endAfterStart is never used.');
      expect(end1.difference(DateTime(2026, 9, 1, 8)), const Duration(hours: 23));
      expect(end2.difference(DateTime(2026, 9, 1, 8)), const Duration(hours: 24));
      final src = File('lib/screens/work_log_screen.dart').readAsStringSync();
      expect(src.contains('endAfterStart'), isFalse);
    });
  });

  group('storage robustness', () {
    Future<Object?> load(Map<String, Object> prefs, Future<void> Function() f) async {
      SharedPreferences.setMockInitialValues(prefs);
      await StorageService().init();
      try {
        await f();
        return null;
      } catch (e) {
        return e;
      }
    }

    test('BUG: malformed / wrongly-typed prefs values throw on load', () async {
      final cases = <String, Map<String, Object>>{
        'work_entries = "not json"': {'work_entries': 'not json'},
        'work_entries = "{}" (object instead of list)': {'work_entries': '{}'},
        'work_entries entry without id': {
          'work_entries': '[{"date":"2026-09-01T00:00:00.000","startTime":"2026-09-01T08:00:00.000","endTime":"2026-09-01T16:00:00.000"}]'
        },
        'work_entries with bad date': {
          'work_entries': '[{"id":"x","date":"yesterday","startTime":"2026-09-01T08:00:00.000","endTime":"2026-09-01T16:00:00.000"}]'
        },
        'app_settings = "{bad"': {'app_settings': '{bad'},
        'app_settings hourlyWage as string': {'app_settings': '{"hourlyWage":"15"}'},
        'active_session = "garbage"': {'active_session': 'garbage'},
      };
      final out = <String>[];
      for (final c in cases.entries) {
        final e1 = await load(c.value, () => WorkEntriesProvider().loadEntries());
        final e2 = await load(c.value, () => SettingsProvider().loadSettings());
        final e3 = await load(c.value, () async {
          final t = TimerProvider();
          await t.loadActiveSession();
          t.dispose();
        });
        final err = e1 ?? e2 ?? e3;
        out.add('${c.key}: ${err == null ? 'loads fine' : 'THROWS ${err.runtimeType}: ${err.toString().split('\n').first}'}');
      }
      obs('prefs robustness:\n   ${out.join('\n   ')}');
      expect(out.where((o) => o.contains('THROWS')).length, 7);
    });

    testWidgets('BUG: real main() with corrupt work_entries shows permanent "Startup Error" screen',
        (tester) async {
      installNotificationStub();
      SharedPreferences.setMockInitialValues({'work_entries': 'not json'});
      await StorageService().init();
      app.main();
      await tester.pumpAndSettle();
      final texts = visibleTexts(tester);
      obs('screen after main(): $texts');
      expect(texts.any((t) => t.startsWith('Startup Error')), isTrue);
    });
  });

  group('app restart while timer runs', () {
    testWidgets('persisted start time is restored; first second shows 00:00:00', (tester) async {
      installNotificationStub();
      setScreen(tester, const Size(800, 1280));
      final start = DateTime.now().subtract(const Duration(hours: 3, minutes: 5));
      final h = await bootApp({'active_session': start.toIso8601String(), 'app_settings': settingsJson()});
      obs('restored startTime=${h.timer.startTime} (persisted $start) isRunning=${h.timer.isRunning} '
          'elapsed right after load=${h.timer.elapsed}');
      expect(h.timer.startTime, start);
      await tester.pumpWidget(h.app);
      final first = visibleTexts(tester).where((t) => RegExp(r'^\d\d:\d\d:\d\d$').hasMatch(t)).toList();
      final earnFirst = h.timer.getCurrentEarnings(15);
      await tester.pump(const Duration(seconds: 1));
      final after = visibleTexts(tester).where((t) => RegExp(r'^\d\d:\d\d:\d\d$').hasMatch(t)).toList();
      obs('timer text first frame=$first (earnings $earnFirst) ; after first tick=$after');
      expect(first, ['00:00:00']);
      expect(after.single.startsWith('03:05'), isTrue);
      final shows = countNotif('show');
      obs('notification show() calls after restart + 1 tick: $shows');
      await h.dispose(tester);
    });

    test('BUG (DST, needs TZ=Europe/Berlin): active_session stored as local time without offset', () {
      final tz = DateTime(2026, 7, 1).timeZoneName;
      // On 2026-10-25 the wall-clock hour 02:00-03:00 happens twice in Berlin:
      // 00:30Z == 02:30 CEST (first pass), 01:30Z == 02:30 CET (second pass).
      final out = <String>[];
      var anyDiff = false;
      for (final utc in [DateTime.utc(2026, 10, 25, 0, 30), DateTime.utc(2026, 10, 25, 1, 30)]) {
        final real = DateTime.fromMillisecondsSinceEpoch(utc.millisecondsSinceEpoch);
        final stored = real.toIso8601String(); // what StorageService.saveActiveSession writes
        final restored = DateTime.parse(stored); // what getActiveSession returns
        final diff = restored.difference(real);
        if (diff != Duration.zero) anyDiff = true;
        out.add('real ${utc.toIso8601String()} (${real.timeZoneName}) stored "$stored" -> restored off by $diff');
      }
      obs('TZ summer=$tz: ${out.join(' | ')}');
      if (tz == 'CEST') {
        expect(anyDiff, isTrue);
      }
    });

    test('BUG (DST, needs TZ=Europe/Berlin): quarter rounding & overnight dialog shift by 1h on DST days', () {
      final tz = DateTime(2026, 7, 1).timeZoneName;
      final spring = roundToQuarterCopy(DateTime(2026, 3, 29, 8, 0));
      final autumn = roundToQuarterCopy(DateTime(2026, 10, 25, 8, 0));
      final nightStart = DateTime(2026, 10, 24, 22, 0);
      final nightEnd = dialogEnd(DateTime(2026, 10, 24), const TimeOfDay(hour: 22, minute: 0),
          const TimeOfDay(hour: 6, minute: 0));
      obs('TZ summer=$tz: roundToQuarter(29.03. 08:00)=$spring ; roundToQuarter(25.10. 08:00)=$autumn ; '
          'dialog 24.10. 22:00-06:00 -> end=$nightEnd (duration ${nightEnd.difference(nightStart)})');
      if (tz == 'CEST') {
        expect(spring.hour, 9);
        expect(autumn.hour, 7);
        expect(nightEnd.hour, 5);
      }
    });
  });

  group('wage changes', () {
    testWidgets('BUG: changing the wage retroactively changes old (even paid) entries', (tester) async {
      installNotificationStub();
      setScreen(tester, const Size(800, 1280));
      final s = DateTime(2026, 9, 1, 8);
      final h = await bootApp({
        'app_settings': settingsJson(wage: 15),
        'work_entries':
            '[{"id":"a","date":"2026-09-01T00:00:00.000","startTime":"${s.toIso8601String()}","endTime":"${s.add(const Duration(hours: 8)).toIso8601String()}","isPaid":true}]',
      });
      await tester.pumpWidget(h.app);
      await tester.tap(find.byIcon(Icons.format_list_bulleted));
      await tester.pumpAndSettle();
      final before = visibleTexts(tester).where((t) => t.contains('€')).toList();
      await h.settings.setHourlyWage(20);
      await tester.pumpAndSettle();
      final after = visibleTexts(tester).where((t) => t.contains('€')).toList();
      obs('paid 8h entry before wage change: $before ; after 15->20: $after');
      expect(before, contains('Verdient: 120.00 €'));
      expect(after, contains('Verdient: 160.00 €'));
      await h.dispose(tester);
      resetScreen(tester);
    });

    testWidgets('BUG: wage changed while timer runs and Home tab not mounted -> notification uses stale wage',
        (tester) async {
      installNotificationStub();
      setScreen(tester, const Size(800, 1280));
      final start = DateTime.now().subtract(const Duration(hours: 2));
      final h = await bootApp({'app_settings': settingsJson(wage: 15), 'active_session': start.toIso8601String()});
      await tester.pumpWidget(h.app);
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.byIcon(Icons.format_list_bulleted)); // Home unmounted (AnimatedSwitcher)
      await tester.pumpAndSettle();
      await h.settings.setHourlyWage(30); // what SettingsScreen's _WageInputField does
      await tester.pump();
      notificationCalls.clear();
      // _maybeUpdateNotification needs >=15s of *real* elapsed time since last post
      await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 16)));
      await tester.pump(const Duration(seconds: 1));
      final shows = notificationCalls.where((c) => c.method == 'show').toList();
      final body = shows.isEmpty ? '(none)' : (shows.last.arguments as Map)['body'];
      obs('after wage 15->30 while on Log tab: notification body="$body" '
          '(2h @30 would be 60.00, @15 is 30.00)');
      expect(body, startsWith('Verdient: 30.0'));
      // Going back to Home re-syncs (setHourlyWage is called from HomeScreen.build)
      await tester.tap(find.byIcon(Icons.timer));
      await tester.pumpAndSettle();
      await h.dispose(tester);
      resetScreen(tester);
    }, timeout: const Timeout(Duration(minutes: 2)));
  });

  group('wage input', () {
    Future<(String, double)> typeWage(WidgetTester tester, AppHarness h, String keys,
        {bool charByChar = true}) async {
      final field = find.byType(TextField).first;
      await tester.enterText(field, '');
      await tester.pump();
      if (charByChar) {
        for (final ch in keys.split('')) {
          final cur = tester.widget<TextField>(field).controller!.text;
          await tester.enterText(field, cur + ch);
          await tester.pump();
        }
      } else {
        await tester.enterText(field, keys);
        await tester.pump();
      }
      return (tester.widget<TextField>(field).controller!.text, h.settings.hourlyWage);
    }

    testWidgets('BUG: decimal comma "12,50" is swallowed -> wage becomes 1250', (tester) async {
      installNotificationStub();
      setScreen(tester, const Size(800, 1280));
      final h = await bootApp({'app_settings': settingsJson(wage: 15)});
      await tester.pumpWidget(h.app);
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();
      final res = <String>[];
      for (final input in ['12,50', '12.50', '0', '12.505', '1e3']) {
        final (text, wage) = await typeWage(tester, h, input);
        res.add('typed "$input" -> field "$text", saved wage $wage');
      }
      final (pasted, pastedWage) = await typeWage(tester, h, '12,50', charByChar: false);
      res.add('pasted "12,50" -> field "$pasted", saved wage $pastedWage');
      final stored = (await SharedPreferences.getInstance()).getString('app_settings');
      obs('wage input:\n   ${res.join('\n   ')}\n   prefs app_settings=$stored');
      expect(res.first, contains('saved wage 1250.0'));
      await h.dispose(tester);
      resetScreen(tester);
    });
  });

  group('entries provider', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await StorageService().init();
    });

    test('sorting newest first, re-sorted after edit', () async {
      final p = WorkEntriesProvider();
      await p.saveEntry(entry('b', DateTime(2026, 9, 5, 8), DateTime(2026, 9, 5, 9)));
      await p.saveEntry(entry('a', DateTime(2026, 8, 1, 8), DateTime(2026, 8, 1, 9)));
      await p.saveEntry(entry('c', DateTime(2026, 9, 20, 8), DateTime(2026, 9, 20, 9)));
      final order1 = p.entries.map((e) => e.id).join();
      await p.saveEntry(p.entries.firstWhere((e) => e.id == 'a')
          .copyWith(startTime: DateTime(2026, 9, 30, 8), endTime: DateTime(2026, 9, 30, 9)));
      final order2 = p.entries.map((e) => e.id).join();
      obs('order after inserts=$order1, after moving a to 30.09.=$order2');
      expect(order1, 'cba');
      expect(order2, 'acb');
    });

    test('paid / unpaid totals and delete-all', () async {
      final p = WorkEntriesProvider();
      await p.saveEntry(entry('u1', DateTime(2026, 9, 1, 8), DateTime(2026, 9, 1, 16)));
      await p.saveEntry(entry('u2', DateTime(2026, 9, 2, 8), DateTime(2026, 9, 2, 12)));
      await p.saveEntry(entry('p1', DateTime(2026, 9, 3, 8), DateTime(2026, 9, 3, 18), paid: true));
      final open1 = p.totalOpenEarnings(15);
      await p.togglePaidStatus('u2');
      final open2 = p.totalOpenEarnings(15);
      await p.togglePaidStatus('p1');
      final open3 = p.totalOpenEarnings(15);
      obs('open total: initial=$open1 (expect 180), after paying u2=$open2 (expect 120), after un-paying p1=$open3 (expect 270)');
      expect([open1, open2, open3], [180, 120, 270]);

      // delete all while a timer session is active
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('active_session', DateTime(2026, 9, 30, 8).toIso8601String());
      await p.deleteAllEntries();
      final reloaded = WorkEntriesProvider();
      await reloaded.loadEntries();
      obs('after deleteAll: entries=${p.entries.length}, reloaded=${reloaded.entries.length}, '
          'active_session kept=${prefs.getString('active_session') != null}, keys=${prefs.getKeys()}');
      expect(reloaded.entries, isEmpty);
    });

    test('settings defaults & theme persisted but unused', () async {
      final s = SettingsProvider();
      await s.loadSettings();
      await s.setTheme(AppTheme.light);
      obs('themeMode getter=${s.themeMode} persisted=${(await SharedPreferences.getInstance()).getString('app_settings')}');
      expect(s.themeMode, ThemeMode.light);
    });
  });

  group('edit dialog end < start via real UI', () {
    testWidgets('BUG: edit 08:00-16:00 -> end 07:00 saves a 23h entry without warning', (tester) async {
      installNotificationStub();
      // German Android devices report 24h format; without this the Material time
      // picker's input mode parses "07" as 7 PM (framework checks only
      // MediaQuery.alwaysUse24HourFormat, not the locale) -> 19:00.
      tester.platformDispatcher.alwaysUse24HourFormatTestValue = true;
      addTearDown(tester.platformDispatcher.clearAlwaysUse24HourTestValue);
      setScreen(tester, const Size(800, 1280));
      final s = DateTime(2026, 9, 1, 8);
      final h = await bootApp({
        'app_settings': settingsJson(wage: 15),
        'work_entries':
            '[{"id":"a","date":"2026-09-01T00:00:00.000","startTime":"${s.toIso8601String()}","endTime":"${s.add(const Duration(hours: 8)).toIso8601String()}","isPaid":false}]',
      });
      await tester.pumpWidget(h.app);
      await tester.tap(find.byIcon(Icons.format_list_bulleted));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(AnimatedListItem).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();
      // 3rd tile = end time
      await tester.tap(find.byIcon(Icons.access_time).last);
      await tester.pumpAndSettle();
      // switch the Material time picker to text input mode
      await tester.tap(find.byIcon(Icons.keyboard_outlined));
      await tester.pumpAndSettle();
      final fields = find.descendant(of: find.byType(Dialog).last, matching: find.byType(TextField));
      obs('time picker (input mode) texts: ${visibleTexts(tester).skipWhile((t) => t != 'Endzeit').toList()} '
          'fields=${fields.evaluate().length}');
      await tester.enterText(fields.at(0), '07');
      await tester.enterText(fields.at(1), '00');
      await tester.pumpAndSettle();
      obs('time picker after typing: ${visibleTexts(tester).skipWhile((t) => t != 'Endzeit').toList()}');
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      final dialogTexts = visibleTexts(tester);
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();
      final e = h.entries.entries.single;
      obs('edit dialog showed $dialogTexts; saved entry: ${e.startTime} -> ${e.endTime} '
          '(${e.formattedDuration}, ${e.calculateEarnings(15).toStringAsFixed(2)} EUR); '
          'list shows ${visibleTexts(tester).where((t) => t.contains('h') || t.contains('€')).toList()}');
      expect(e.duration, const Duration(hours: 23));
      await h.dispose(tester);
      resetScreen(tester);
    });
  });

  group('stop flow side effects', () {
    testWidgets('stopping < 15 min discards the session irrecoverably', (tester) async {
      installNotificationStub();
      setScreen(tester, const Size(800, 1280));
      // 20 real minutes ago -> after quarter rounding may be 15 or 30 minutes, always kept;
      // 2 minutes ago -> discarded
      final start = DateTime.now().subtract(const Duration(minutes: 2));
      final h = await bootApp({'app_settings': settingsJson(), 'active_session': start.toIso8601String()});
      await tester.pumpWidget(h.app);
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.text('STOPP'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bestätigen'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      final texts = visibleTexts(tester);
      final prefs = await SharedPreferences.getInstance();
      obs('after stop: snackbar=${texts.where((t) => t.contains('kurz')).toList()} '
          'entries=${h.entries.entries.length} active_session=${prefs.getString('active_session')} '
          'notification cancel calls=${countNotif('cancel')}');
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await h.dispose(tester);
      resetScreen(tester);
    });
  });

  test('services: SystemChrome style is never set by app code', () {
    final hits = <String>[];
    for (final f in Directory('lib').listSync(recursive: true).whereType<File>()) {
      final src = f.readAsStringSync();
      if (src.contains('SystemChrome') || src.contains('SystemUiOverlayStyle')) hits.add(f.path);
    }
    obs('files referencing SystemChrome/SystemUiOverlayStyle: $hits');
    expect(hits, isEmpty);
    // keep import used
    expect(SystemUiOverlayStyle.light, isNotNull);
  });
}
