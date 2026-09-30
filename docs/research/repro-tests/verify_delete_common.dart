// Shared helpers for verify_delete_*_test.dart (delete bug hunt through the REAL UI).
import 'dart:convert';

import 'package:chronos/screens/home_screen.dart';
import 'package:chronos/screens/work_log_screen.dart';
import 'package:chronos/widgets/animated_money_display.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

// ignore: avoid_print
void obs(String s) => print('OBS: $s');

Map<String, Object> ent(String id, DateTime start, Duration dur, {bool paid = false}) => {
      'id': id,
      'date': DateTime(start.year, start.month, start.day).toIso8601String(),
      'startTime': start.toIso8601String(),
      'endTime': start.add(dur).toIso8601String(),
      'isPaid': paid,
    };

/// A: 29.09 open, B: 20.09 paid, C: 10.09 open, D: 15.08 open (only Aug), E: 05.07 paid (only Jul)
/// Unique time ranges so rows are identifiable. Wage 15 -> open total = 121.25+123.75+125.00 = 370.00
List<Map<String, Object>> baseEntries() => [
      ent('A', DateTime(2026, 9, 29, 8), const Duration(hours: 8, minutes: 5)),
      ent('B', DateTime(2026, 9, 20, 8), const Duration(hours: 8, minutes: 10), paid: true),
      ent('C', DateTime(2026, 9, 10, 8), const Duration(hours: 8, minutes: 15)),
      ent('D', DateTime(2026, 8, 15, 8), const Duration(hours: 8, minutes: 20)),
      ent('E', DateTime(2026, 7, 5, 8), const Duration(hours: 8, minutes: 25), paid: true),
    ];

const rA = '08:00 – 16:05', rB = '08:00 – 16:10', rC = '08:00 – 16:15', rD = '08:00 – 16:20', rE = '08:00 – 16:25';

Future<AppHarness> startApp(WidgetTester tester,
    {List<Map<String, Object>>? entries, String lang = 'german', Map<String, Object> extra = const {}, Size size = const Size(500, 1600)}) async {
  installNotificationStub();
  setScreen(tester, size);
  final h = await bootApp({
    'app_settings': settingsJson(language: lang),
    if (entries != null) 'work_entries': json.encode(entries),
    ...extra,
  });
  await tester.pumpWidget(h.app);
  await tester.pumpAndSettle();
  return h;
}

final _rangeRe = RegExp(r'^\d\d:\d\d.* – \d\d:\d\d');
final _headerRe = RegExp(r'^[A-ZÄÖÜ]{3,}( \d{4})?$');

/// Time-range texts of the rows, top to bottom, of every mounted WorkLogScreen
/// (normally one). Rows whose opacity ancestor is 0 are still counted.
List<String> logRows(WidgetTester t) {
  final f = find.descendant(
      of: find.byType(WorkLogScreen),
      matching: find.byWidgetPredicate((w) => w is Text && w.data != null && _rangeRe.hasMatch(w.data!)),
      skipOffstage: false);
  final els = f.evaluate().toList();
  els.sort((a, b) => t.getTopLeft(find.byElementPredicate((e) => e == a, skipOffstage: false)).dy
      .compareTo(t.getTopLeft(find.byElementPredicate((e) => e == b, skipOffstage: false)).dy));
  return els.map((e) => (e.widget as Text).data!).toList();
}

List<String> logHeaders(WidgetTester t) {
  final f = find.descendant(
      of: find.byType(WorkLogScreen),
      matching: find.byWidgetPredicate((w) => w is Text && w.data != null && _headerRe.hasMatch(w.data!)),
      skipOffstage: false);
  return f.evaluate().map((e) => (e.widget as Text).data!).toList();
}

bool logEmptyShown(WidgetTester t) =>
    find.text('Keine Einträge vorhanden', skipOffstage: false).evaluate().isNotEmpty ||
    find.text('No entries available', skipOffstage: false).evaluate().isNotEmpty;

int workLogScreens(WidgetTester t) => find.byType(WorkLogScreen, skipOffstage: false).evaluate().length;
int homeScreens(WidgetTester t) => find.byType(HomeScreen, skipOffstage: false).evaluate().length;

/// Amounts configured on the two money displays on Home (current, open total).
List<double> homeAmounts(WidgetTester t) => t
    .widgetList<AnimatedMoneyDisplay>(find.byType(AnimatedMoneyDisplay, skipOffstage: false))
    .map((w) => w.amount)
    .toList();

/// What the second money display paints (all Text descendants concatenated; during
/// digit AnimatedSwitcher transitions old+new digits both appear).
String homeOpenPainted(WidgetTester t) {
  final disp = find.byType(AnimatedMoneyDisplay, skipOffstage: false);
  if (disp.evaluate().length < 2) return '<no home>';
  final texts = find.descendant(of: disp.at(1), matching: find.byType(Text), skipOffstage: false);
  return texts.evaluate().map((e) => (e.widget as Text).data).join();
}

Future<List<String>> storedIds() async {
  final p = await SharedPreferences.getInstance();
  final s = p.getString('work_entries');
  if (s == null) return ['<key absent>'];
  return (json.decode(s) as List).map((e) => e['id'] as String).toList();
}

String snap(WidgetTester t, String label) {
  final s = '[$label] logScreens=${workLogScreens(t)} rows=${logRows(t)} headers=${logHeaders(t)} '
      'empty=${logEmptyShown(t)} homeScreens=${homeScreens(t)} homeAmounts=${homeAmounts(t)}';
  obs(s);
  return s;
}

Future<void> goLog(WidgetTester t, {bool settle = true}) async {
  await t.tap(find.byIcon(Icons.format_list_bulleted));
  if (settle) await t.pumpAndSettle();
}

Future<void> goHome(WidgetTester t, {bool settle = true}) async {
  await t.tap(find.byIcon(Icons.timer));
  if (settle) await t.pumpAndSettle();
}

String deleteLabel(String lang) => lang == 'english' ? 'Delete' : 'Löschen';

/// Opens the row's option sheet (tap or long-press), taps delete, confirms.
/// [fast]: no settling between steps (a single 1-frame pump only).
Future<void> uiDeleteRow(WidgetTester t, String range,
    {bool longPress = false, bool fast = false, String lang = 'german', bool confirm = true}) async {
  final row = find.text(range);
  expect(row, findsWidgets, reason: 'row $range must be visible before delete');
  if (longPress) {
    await t.longPress(row.first);
  } else {
    await t.tap(row.first);
  }
  final sheetDelete = find.descendant(of: find.byType(BottomSheet), matching: find.text(deleteLabel(lang)));
  if (fast) {
    // pump single 16ms frames only until the option has slid on-screen far enough to be hit
    await t.pump();
    var ms = 0;
    final h = t.view.physicalSize.height / t.view.devicePixelRatio;
    while (t.getCenter(sheetDelete).dy > h - 12 && ms < 1000) {
      await t.pump(const Duration(milliseconds: 16));
      ms += 16;
    }
    obs('fast: sheet option reachable after ${ms}ms (y=${t.getCenter(sheetDelete).dy.toStringAsFixed(0)} of $h)');
  } else {
    await t.pumpAndSettle();
  }
  expect(sheetDelete, findsOneWidget, reason: 'sheet delete option');
  await t.tap(sheetDelete, warnIfMissed: true);
  if (fast) {
    await t.pump();
  } else {
    await t.pumpAndSettle();
  }
  final btn = find.widgetWithText(ElevatedButton, deleteLabel(lang));
  expect(btn, findsOneWidget, reason: 'confirm button');
  await t.tap(confirm ? btn : find.widgetWithText(TextButton, lang == 'english' ? 'Cancel' : 'Abbrechen'));
}
