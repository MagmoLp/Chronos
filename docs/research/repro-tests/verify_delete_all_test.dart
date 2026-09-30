// Task A.3: "Alle Einträge löschen" from Settings, opened from Home and from Log, DE + EN.
import 'package:chronos/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';
import 'verify_delete_common.dart';

Future<void> openSettings(WidgetTester t) async {
  await t.tap(find.byIcon(Icons.settings).last);
  await t.pumpAndSettle();
  expect(find.byType(SettingsScreen), findsOneWidget);
}

Future<void> openDeleteAllDialog(WidgetTester t) async {
  await t.tap(find.text('Alle Einträge löschen'));
  await t.pumpAndSettle();
  expect(find.text('Alle Daten löschen?'), findsOneWidget);
}

bool confirmEnabled(WidgetTester t, String lang) {
  final b = t.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, deleteLabel(lang)));
  return b.onPressed != null;
}

Future<void> runDeleteAll(WidgetTester t, {required bool fromLog, required String lang}) async {
  final h = await startApp(t, entries: baseEntries(), lang: lang);
  obs('[$lang fromLog=$fromLog] home before: ${homeAmounts(t)} painted=${homeOpenPainted(t)}');
  if (fromLog) await goLog(t);
  await openSettings(t);
  await openDeleteAllDialog(t);
  final dialogTexts = visibleTexts(t).where((s) => !s.startsWith('08:')).toList();
  obs('[$lang] dialog texts: $dialogTexts');
  final field = find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextField));
  final results = <String>[];
  for (final input in ['Delete', 'delete', 'DELETE', 'löschen', 'LÖSCHEN', 'Löschen ', ' Löschen', 'Loeschen', 'loeschen', 'Löschen.', 'Löschen']) {
    await t.enterText(field, input);
    await t.pump();
    results.add('"$input" -> ${confirmEnabled(t, lang) ? 'ENABLED' : 'disabled'}');
  }
  obs('[$lang] confirm button state by input: ${results.join(', ')}');
  // Try tapping the disabled button with "Delete" typed (what an English user would do)
  await t.enterText(field, 'Delete');
  await t.pump();
  await t.tap(find.widgetWithText(ElevatedButton, deleteLabel(lang)), warnIfMissed: false);
  await t.pumpAndSettle();
  obs('[$lang] after tapping confirm with "Delete": dialog still open=${find.text('Alle Daten löschen?').evaluate().isNotEmpty} '
      'entries=${h.entries.entries.length} stored=${(await storedIds()).length}');
  expect(h.entries.entries.length, 5);
  // Now the working input
  await t.enterText(field, 'Löschen');
  await t.pump();
  await t.tap(find.widgetWithText(ElevatedButton, deleteLabel(lang)));
  await t.pump();
  obs('[$lang] 1 frame after confirm: provider entries=${h.entries.entries.length} stored=${await storedIds()}');
  await t.pumpAndSettle();
  final snack = visibleTexts(t).where((s) => s.contains('gelöscht') || s.contains('deleted')).toList();
  obs('[$lang] settled on Settings: snackbar=$snack settingsVisible=${find.byType(SettingsScreen).evaluate().length}');
  // Pop back with the AppBar back arrow
  await t.tap(find.byIcon(Icons.arrow_back));
  await t.pump();
  snap(t, '[$lang fromLog=$fromLog] 1 frame after popping Settings');
  await t.pumpAndSettle();
  snap(t, '[$lang fromLog=$fromLog] settled after popping Settings');
  if (fromLog) {
    expect(logEmptyShown(t), isTrue);
    expect(logRows(t), isEmpty);
    await goHome(t);
  } else {
    obs('home after delete-all: ${homeAmounts(t)} painted=${homeOpenPainted(t)}');
    expect(homeAmounts(t)[1], 0.0);
    await goLog(t);
    snap(t, 'Log after delete-all from Home');
    expect(logEmptyShown(t), isTrue);
    await goHome(t);
  }
  obs('home painted at end: ${homeOpenPainted(t)}');
  expect(homeOpenPainted(t), '0,00€');
  // Add an entry afterwards: does it work & do the old ones come back?
  await goLog(t);
  await t.tap(find.byIcon(Icons.add));
  await t.pumpAndSettle();
  await t.tap(find.widgetWithText(ElevatedButton, lang == 'english' ? 'Save' : 'Speichern'));
  await t.pumpAndSettle();
  snap(t, 'after adding one entry post delete-all');
  expect(logRows(t).length, 1);
  await h.dispose(t);
  resetScreen(t);
}

void main() {
  setUpAll(() async => loadRealFonts());

  testWidgets('DE, Settings opened from Home', (t) => runDeleteAll(t, fromLog: false, lang: 'german'));
  testWidgets('DE, Settings opened from Log', (t) => runDeleteAll(t, fromLog: true, lang: 'german'));
  testWidgets('EN, Settings opened from Home', (t) => runDeleteAll(t, fromLog: false, lang: 'english'));
  testWidgets('EN, Settings opened from Log', (t) => runDeleteAll(t, fromLog: true, lang: 'english'));

  testWidgets('delete-all while the Log tab is mid cross-fade & Android back instead of arrow', (t) async {
    final h = await startApp(t, entries: baseEntries());
    await goLog(t);
    await openSettings(t);
    await openDeleteAllDialog(t);
    await t.enterText(find.byType(TextField).last, 'Löschen');
    await t.pump();
    await t.tap(find.widgetWithText(ElevatedButton, 'Löschen'));
    await t.pumpAndSettle();
    // system back (Android back button)
    final popped = await t.binding.handlePopRoute();
    await t.pump();
    snap(t, 'after system back from Settings (handlePopRoute=$popped), 1 frame');
    await t.pumpAndSettle();
    snap(t, 'after system back settled');
    expect(logEmptyShown(t), isTrue);
    // quickly switch tabs back and forth inside the 300ms cross-fade
    await goHome(t, settle: false);
    await t.pump(const Duration(milliseconds: 50));
    await goLog(t, settle: false);
    await t.pump(const Duration(milliseconds: 50));
    snap(t, 'mid cross-fade (Home->Log within 50ms)');
    await t.pumpAndSettle();
    snap(t, 'cross-fade settled');
    expect(logEmptyShown(t), isTrue);
    await h.dispose(t);
    resetScreen(t);
  });
}
