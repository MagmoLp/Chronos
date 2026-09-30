// Item 2: Localization leftovers.
//
// Walks every screen / dialog / sheet / snackbar in English and in German,
// collects every painted string and flags strings that belong to the other
// language (or locale-specific number/date formats of the other language).
// Also inspects what the app sends to the notification plugin.

import 'package:chronos/widgets/animated_card.dart';
import 'package:chronos/widgets/animated_money_display.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

final _germanMarkers = RegExp(
    r'[äöüÄÖÜß]|\b(Alle|Einträge|Eintrag|löschen|Löschen|Daten|Datenverwaltung|Diese|Aktion|kann|nicht|werden|Zum|gebe|Wort|ein|Verdient|Arbeite|unwiderruflich|gelöscht|Löscht|rückgängig|gemacht|Arbeitssession|Zeigt|Gesamter|Stundenlohn|Beispiel|oder|Abgerechnet)\b');
final _englishMarkers = RegExp(
    r'\b(Delete|Cancel|Save|Entry|Entries|Time|Date|Settings|Language|Paid|Earned|Total|Current|Work|Log|Live|Hourly|Wage|Enter|Example|Really|Remove|Confirm|Stop|Theme|Dark|Light|Mode|AM|PM|Earnings|Amount|all|data|the|and|type|word)\b');
// dd.MM.yyyy or dd.MM. (German date format) and "12,34" decimal comma
final _germanDate = RegExp(r'\b\d{2}\.\d{2}\.(\d{4})?');
final _decimalComma = RegExp(r'\d,\d{2}\b');
final _decimalPoint = RegExp(r'\d\.\d{2} ?€');

final report = <String>[];

Future<Map<String, List<String>>> walkAllScreens(WidgetTester tester, AppHarness h, String lang) async {
  final pages = <String, List<String>>{};
  void grab(String name) => pages[name] = visibleTexts(tester);
  void popTop() => tester.state<NavigatorState>(find.byType(Navigator).first).pop();

  await tester.pumpWidget(h.app);
  await tester.pumpAndSettle();
  grab('home (stopped)');
  // AnimatedMoneyDisplay renders one Text per character; join them.
  for (final m in find.byType(AnimatedMoneyDisplay).evaluate()) {
    final joined = find
        .descendant(of: find.byWidget(m.widget), matching: find.byType(Text))
        .evaluate()
        .map((e) => (e.widget as Text).data ?? '')
        .join();
    report.add('[$lang] home money display renders "$joined"');
  }
  // time format used in dialogs vs list


  // start + immediately stop -> "too short" snackbar
  await h.timer.start();
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
  grab('home (running)');
  await tester.tap(find.text(lang == 'english' ? 'STOP' : 'STOPP'));
  await tester.pumpAndSettle();
  grab('stop confirmation dialog');
  await tester.tap(find.byType(ElevatedButton).last);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  grab('too-short snackbar');
  await tester.pumpAndSettle(const Duration(seconds: 5));

  await tester.tap(find.byIcon(Icons.format_list_bulleted));
  await tester.pumpAndSettle();
  grab('work log');

  await tester.tap(find.byType(AnimatedListItem).first);
  await tester.pumpAndSettle();
  grab('entry options sheet');
  await tester.tap(find.byIcon(Icons.edit));
  await tester.pumpAndSettle();
  grab('edit entry dialog');
  popTop();
  await tester.pumpAndSettle();

  await tester.tap(find.byType(AnimatedListItem).first);
  await tester.pumpAndSettle();
  await tester.tap(find.byIcon(Icons.delete));
  await tester.pumpAndSettle();
  grab('delete confirmation dialog');
  await tester.tap(find.byType(ElevatedButton).last);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  grab('entry deleted snackbar');
  await tester.pumpAndSettle(const Duration(seconds: 5));

  await tester.tap(find.byIcon(Icons.add));
  await tester.pumpAndSettle();
  grab('add entry dialog');
  await tester.tap(find.byIcon(Icons.access_time).first);
  await tester.pumpAndSettle();
  grab('time picker');
  popTop();
  await tester.pumpAndSettle();
  await tester.tap(find.byIcon(Icons.calendar_today).first);
  await tester.pumpAndSettle();
  grab('date picker');
  popTop();
  await tester.pumpAndSettle();
  await tester.tap(find.byType(ElevatedButton).last); // save
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  grab('entry saved snackbar');
  await tester.pumpAndSettle(const Duration(seconds: 5));

  final check = find.byIcon(Icons.check);
  await tester.ensureVisible(check.first);
  await tester.pumpAndSettle();
  await tester.tap(check.first);
  await tester.pumpAndSettle();
  grab('unmark paid dialog');
  popTop();
  await tester.pumpAndSettle();

  await tester.tap(find.byIcon(Icons.settings).first);
  await tester.pumpAndSettle();
  grab('settings (top)');
  await tester.drag(find.byType(ListView).first, const Offset(0, -2000));
  await tester.pumpAndSettle();
  grab('settings (bottom)');
  await tester.tap(find.byIcon(Icons.delete_forever));
  await tester.pumpAndSettle();
  grab('delete-all dialog');

  // Can an English user confirm with the English word?
  final dialogField = find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextField));
  await tester.enterText(dialogField, lang == 'english' ? 'Delete' : 'Löschen');
  await tester.pumpAndSettle();
  final confirmBtn = tester.widget<ElevatedButton>(
      find.descendant(of: find.byType(AlertDialog), matching: find.byType(ElevatedButton)));
  report.add('[$lang] delete-all dialog: typing "${lang == 'english' ? 'Delete' : 'Löschen'}" '
      'enables the confirm button: ${confirmBtn.onPressed != null}');
  await tester.enterText(dialogField, 'Löschen');
  await tester.pumpAndSettle();
  // an earlier "entry saved" snackbar is still queued (its timer does not run
  // while another route is on top); clear it so the next one becomes visible
  tester.state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger)).clearSnackBars();
  await tester.pumpAndSettle();
  await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.byType(ElevatedButton)));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 800));
  grab('all-deleted snackbar');
  await tester.pumpAndSettle(const Duration(seconds: 5));
  return pages;
}

void main() {
  setUpAll(() async => loadRealFonts());

  tearDownAll(() {
    // ignore: avoid_print
    print('\n===== L10N REPORT =====\n${report.join('\n')}');
  });

  for (final lang in ['english', 'german']) {
    testWidgets('l10n leftovers scan: $lang', (tester) async {
      installNotificationStub();
      setScreen(tester, const Size(412, 915));
      final h = await bootApp({
        'app_settings': settingsJson(language: lang),
        'work_entries': sampleEntriesJson(),
      });
      late Map<String, List<String>> pages;
      final errs = await captureErrors(() async {
        pages = await walkAllScreens(tester, h, lang);
      });
      for (final e in errs.map((e) => e.summary).toSet()) {
        report.add('[$lang] (layout error during walk) $e');
      }

      final flagged = <String>{};
      pages.forEach((page, texts) {
        for (final t in texts) {
          final String? why;
          if (lang == 'english') {
            if (_germanMarkers.hasMatch(t)) {
              why = 'GERMAN TEXT';
            } else if (_germanDate.hasMatch(t)) {
              why = 'German date format dd.MM.yyyy';
            } else if (_decimalComma.hasMatch(t)) {
              why = 'German decimal comma';
            } else if (RegExp(r'\b(AM|PM)\b').hasMatch(t)) {
              why = '12h clock in dialog (list uses 24h HH:mm)';
            } else {
              why = null;
            }
          } else {
            if (_englishMarkers.hasMatch(t) && t != 'English') {
              why = 'ENGLISH TEXT';
            } else if (_decimalPoint.hasMatch(t)) {
              why = 'English decimal point in German UI';
            } else if (RegExp(r'\b(AM|PM)\b').hasMatch(t)) {
              why = '12h clock';
            } else {
              why = null;
            }
          }
          if (why != null && flagged.add('$why: "$t"')) {
            report.add('[$lang] $page: $why -> "${t.replaceAll('\n', r'\n')}"');
          }
        }
      });
      // Dump everything so a human can double check the heuristics.
      pages.forEach((page, texts) {
        report.add('[$lang] ALL TEXT on "$page": ${texts.map((t) => t.replaceAll('\n', r'\n')).toSet().join(' | ')}');
      });

      // What the notification shows while running in this language
      final shows = notificationCalls.where((c) => c.method == 'show').toList();
      if (shows.isNotEmpty) {
        final a = Map<String, Object?>.from(shows.first.arguments as Map);
        final details = Map<String, Object?>.from(a['platformSpecifics'] as Map? ?? {});
        report.add('[$lang] NOTIFICATION show(): title="${a['title']}" body="${a['body']}" '
            'channelName="${details['channelName']}" channelDescription="${details['channelDescription']}"');
      } else {
        report.add('[$lang] NOTIFICATION: no show() call captured');
      }

      await h.dispose(tester);
      resetScreen(tester);
    });
  }
}
