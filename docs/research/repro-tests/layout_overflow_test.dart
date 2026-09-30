// Item 1: Layout / overflow reproduction across screen sizes and text scales.
//
// Visits every screen, dialog and sheet of the app at several logical screen
// sizes and text scale factors and records every FlutterError (RenderFlex
// overflows etc.) together with the widget that caused it.
//
// Uses the real Roboto font (loaded from the Flutter SDK cache) so pixel counts
// approximate a real Android device. Set env CHRONOS_TEST_FONT=1 to use the
// default square test font instead.

import 'dart:io';

import 'package:chronos/screens/settings_screen.dart';
import 'package:chronos/screens/work_log_screen.dart';
import 'package:chronos/widgets/animated_button.dart';
import 'package:chronos/widgets/animated_card.dart';
import 'package:chronos/widgets/custom_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

class Cfg {
  const Cfg(this.name, this.size, this.scale);
  final String name;
  final Size size;
  final double scale;
  @override
  String toString() => '$name ${size.width.toInt()}x${size.height.toInt()} @${scale}x';
}

const sizes = <String, Size>{
  'phone-portrait': Size(412, 915),
  'small-phone': Size(360, 640),
  'phone-landscape': Size(915, 412),
  'phone-landscape-small': Size(800, 360),
  'tablet-portrait': Size(800, 1280),
  'tablet-landscape': Size(1280, 800),
};
const scales = [1.0, 1.3, 2.0];

final results = <String>[];

/// AnimatedButton (lib/widgets/animated_button.dart:109) replaces the ambient
/// DefaultTextStyle with a style WITHOUT fontFamily, so under flutter_test the
/// START/STOP labels use the square test font while a device uses Roboto.
/// Correct the measured row width by the per-label width difference.
String controlRowReport(WidgetTester tester, double scale, String lang) {
  final btn = find.byType(AnimatedButton);
  if (btn.evaluate().length < 2) return 'buttons not found';
  final row = tester.renderObject<RenderFlex>(
      find.ancestor(of: btn.first, matching: find.byType(Row)).first);
  final avail = row.constraints.maxWidth;
  var natural = 0.0;
  var child = row.firstChild;
  while (child != null) {
    natural += child.size.width;
    child = (child.parentData as FlexParentData).nextSibling;
  }
  double w(String s, String? family) {
    final tp = TextPainter(
      text: TextSpan(
          text: s,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: 0.5, fontFamily: family)),
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.linear(scale),
    )..layout();
    return tp.width;
  }
  final labels = ['START', lang == 'english' ? 'STOP' : 'STOPP'];
  final delta = labels.fold<double>(0, (a, l) => a + w(l, null) - w(l, 'Roboto'));
  final corrected = natural - delta;
  return 'available ${avail.toStringAsFixed(1)} | measured(test font labels) ${natural.toStringAsFixed(1)} | '
      'Roboto-corrected ${corrected.toStringAsFixed(1)} -> '
      '${corrected > avail ? 'OVERFLOWS by ${(corrected - avail).toStringAsFixed(1)} px on device' : 'fits on device'}';
}

bool isHittable(WidgetTester tester, Finder f) {
  if (f.evaluate().isEmpty) return false;
  final ro = tester.renderObject(f.first);
  final center = tester.getCenter(f.first);
  final result = tester.hitTestOnBinding(center);
  return result.path.any((e) => identical(e.target, ro));
}

/// Where do the START/STOP buttons end up relative to the visible body?
String homeGeometry(WidgetTester tester) {
  final btn = find.byType(AnimatedButton);
  if (btn.evaluate().isEmpty) return 'no buttons';
  final body = tester.getRect(find.byType(SafeArea).first);
  final b = tester.getRect(btn.first);
  final nav = find.byType(CustomBottomNavigation);
  final navTop = nav.evaluate().isEmpty ? double.infinity : tester.getRect(nav).top;
  return 'body ${body.top.toStringAsFixed(0)}..${body.bottom.toStringAsFixed(0)}, START button '
      '${b.top.toStringAsFixed(0)}..${b.bottom.toStringAsFixed(0)}, bottom nav top ${navTop.toStringAsFixed(0)}'
      '${b.top >= body.bottom ? ' -> BUTTONS ENTIRELY OUTSIDE BODY (untappable)' : b.bottom > body.bottom ? ' -> buttons partly outside body' : ''}';
}

void main() {
  final useTestFont = Platform.environment['CHRONOS_TEST_FONT'] == '1';
  final lang = Platform.environment['CHRONOS_LANG'] ?? 'german';

  setUpAll(() async {
    if (!useTestFont) await loadRealFonts();
  });

  tearDownAll(() {
    // ignore: avoid_print
    print('\n===== LAYOUT RESULTS (${useTestFont ? 'test font' : 'Roboto'}, $lang) =====');
    for (final r in results) {
      // ignore: avoid_print
      print(r);
    }
  });

  for (final e in sizes.entries) {
    for (final s in scales) {
      final cfg = Cfg(e.key, e.value, s);
      testWidgets('layout $cfg', (tester) async {
        installNotificationStub();
        setScreen(tester, cfg.size, textScale: cfg.scale);
        final h = await bootApp({
          'app_settings': settingsJson(language: lang, wage: 15.0),
          'work_entries': sampleEntriesJson(),
        });

        Future<void> step(String name, Future<void> Function() body) async {
          final errs = await captureErrors(body);
          final uniq = errs.map((e) => e.summary).toSet();
          if (Platform.environment['CHRONOS_VERBOSE'] == '1') {
            for (final d in errs) {
              // ignore: avoid_print
              print('---- FULL ERROR [$cfg | $name] ----\n${d.full}');
            }
          }
          if (uniq.isEmpty) {
            results.add('$cfg | $name | OK');
          } else {
            for (final u in uniq) {
              results.add('$cfg | $name | $u');
            }
          }
        }

        Future<bool> tapIf(Finder f) async {
          if (f.evaluate().isEmpty) return false;
          try {
            await tester.ensureVisible(f.first);
            await tester.pumpAndSettle();
          } catch (_) {}
          await tester.tap(f.first, warnIfMissed: false);
          await tester.pumpAndSettle();
          return true;
        }

        Future<bool> tryTap(Finder f, String what, String stepName) async {
          if (f.evaluate().isEmpty) {
            results.add('$cfg | $stepName | $what not found in tree');
            return false;
          }
          await tester.tap(f.first, warnIfMissed: false);
          return true;
        }

        void popTop() {
          final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
          if (nav.canPop()) nav.pop();
        }

        await step('home (stopped)', () async {
          await tester.pumpWidget(h.app);
          await tester.pumpAndSettle();
        });
        if (!useTestFont) {
          results.add('$cfg | control-row Roboto-corrected | ${controlRowReport(tester, cfg.scale, lang)}');
          results.add('$cfg | home geometry | ${homeGeometry(tester)}');
        }

        await step('home (running)', () async {
          final startFinder = find.text('START');
          await tryTap(startFinder, 'START text', 'home (running)');
          await tester.pump();
          await tester.pump(const Duration(seconds: 1));
          await tester.pumpAndSettle();
          if (!h.timer.isRunning) {
            results.add('$cfg | home (running) | START button NOT hittable (tap missed) -> started programmatically');
            await h.timer.start();
            await tester.pump(const Duration(seconds: 1));
            await tester.pumpAndSettle();
          }
        });

        await step('stop-confirm dialog', () async {
          final stopText = lang == 'english' ? 'STOP' : 'STOPP';
          if (!await tryTap(find.text(stopText), 'STOP text', 'stop-confirm dialog')) return;
          await tester.pumpAndSettle();
          if (find.byType(AlertDialog).evaluate().isEmpty) {
            results.add('$cfg | stop-confirm dialog | STOP button NOT hittable (tap missed)');
          } else {
            popTop();
            await tester.pumpAndSettle();
          }
        });
        await h.timer.stop();
        await tester.pumpAndSettle();

        await step('work log', () async {
          if (!await tryTap(find.byIcon(Icons.format_list_bulleted), 'nav item Log', 'work log')) return;
          await tester.pumpAndSettle();
          if (find.byType(WorkLogScreen).evaluate().isEmpty) {
            final r = tester.getRect(find.byIcon(Icons.format_list_bulleted));
            results.add('$cfg | work log | "Log" nav item NOT hittable (icon rect $r, screen width '
                '${cfg.size.width}) -> switched programmatically');
            tester.widget<CustomBottomNavigation>(find.byType(CustomBottomNavigation)).onTap(1);
            await tester.pumpAndSettle();
          }
        });

        await step('entry options sheet', () async {
          final ok = await tapIf(find.byType(AnimatedListItem));
          if (!ok || find.byIcon(Icons.edit).evaluate().isEmpty) {
            results.add('$cfg | entry options sheet | could not open');
          }
        });

        await step('edit dialog', () async {
          if (find.byIcon(Icons.edit).evaluate().isNotEmpty) {
            await tester.tap(find.byIcon(Icons.edit), warnIfMissed: false);
            await tester.pumpAndSettle();
            if (find.byType(AlertDialog).evaluate().isEmpty) {
              results.add('$cfg | edit dialog | could not open');
            } else {
              popTop();
              await tester.pumpAndSettle();
            }
          }
        });

        await step('delete-confirm dialog', () async {
          final ok = await tapIf(find.byType(AnimatedListItem));
          if (ok && find.byIcon(Icons.delete).evaluate().isNotEmpty) {
            await tester.tap(find.byIcon(Icons.delete), warnIfMissed: false);
            await tester.pumpAndSettle();
            if (find.byType(AlertDialog).evaluate().isNotEmpty) {
              popTop();
              await tester.pumpAndSettle();
            } else {
              results.add('$cfg | delete-confirm dialog | could not open');
            }
          }
        });

        await step('add-entry dialog', () async {
          if (!await tryTap(find.byIcon(Icons.add), 'AppBar + button', 'add-entry dialog')) return;
          await tester.pumpAndSettle();
          if (find.byType(AlertDialog).evaluate().isEmpty) {
            results.add('$cfg | add-entry dialog | could not open');
          } else {
            final dlg = find.byType(AlertDialog);
            final parts = <String, Finder>{
              'date tile': find.descendant(of: dlg, matching: find.byIcon(Icons.calendar_today)),
              'start tile': find.descendant(of: dlg, matching: find.byIcon(Icons.access_time)).first,
              'end tile': find.descendant(of: dlg, matching: find.byIcon(Icons.access_time)).last,
              'save button': find.descendant(of: dlg, matching: find.byType(ElevatedButton)),
            };
            final bad = parts.entries.where((e) => !isHittable(tester, e.value)).map((e) => e.key).toList();
            if (bad.isNotEmpty) results.add('$cfg | add-entry dialog | NOT hittable: $bad');
          }
        });

        await step('time picker (from add dialog)', () async {
          if (find.byIcon(Icons.access_time).evaluate().isNotEmpty) {
            await tester.tap(find.byIcon(Icons.access_time).first, warnIfMissed: false);
            await tester.pumpAndSettle();
            if (find.byType(TimePickerDialog).evaluate().isEmpty) {
              results.add('$cfg | time picker (from add dialog) | start-time tile NOT hittable');
            } else {
              popTop();
              await tester.pumpAndSettle();
            }
          }
        });

        await step('date picker (from add dialog)', () async {
          if (find.byIcon(Icons.calendar_today).evaluate().isNotEmpty) {
            await tester.tap(find.byIcon(Icons.calendar_today).first, warnIfMissed: false);
            await tester.pumpAndSettle();
            if (find.byType(DatePickerDialog).evaluate().isEmpty) {
              results.add('$cfg | date picker (from add dialog) | date tile NOT hittable');
            } else {
              popTop();
              await tester.pumpAndSettle();
            }
          }
          if (find.byType(AlertDialog).evaluate().isNotEmpty) {
            popTop();
            await tester.pumpAndSettle();
          }
        });

        await step('unmark-paid dialog', () async {
          if (find.byIcon(Icons.check).evaluate().isEmpty && find.byType(Scrollable).evaluate().isNotEmpty) {
            try {
              await tester.scrollUntilVisible(find.byIcon(Icons.check), 100,
                  scrollable: find.byType(Scrollable).first, maxScrolls: 60);
            } catch (_) {}
          }
          final ok = await tapIf(find.byIcon(Icons.check));
          if (ok && find.byType(AlertDialog).evaluate().isNotEmpty) {
            popTop();
            await tester.pumpAndSettle();
          } else {
            final chk = find.byIcon(Icons.check);
            final lv = find.byType(ListView);
            results.add('$cfg | unmark-paid dialog | could not open (harness): check icon '
                '${chk.evaluate().isEmpty ? 'not built' : tester.getRect(chk.first).toString()} '
                'list viewport ${lv.evaluate().isEmpty ? '-' : tester.getRect(lv.first).toString()}');
          }
        });

        await step('settings', () async {
          if (find.byIcon(Icons.settings).evaluate().isEmpty) {
            results.add('$cfg | settings | settings icon not in tree; visible texts: ${visibleTexts(tester).take(8).toList()}');
          } else {
            await tester.tap(find.byIcon(Icons.settings).first, warnIfMissed: false);
            await tester.pumpAndSettle();
          }
          if (find.byType(SettingsScreen).evaluate().isEmpty) {
            results.add('$cfg | settings | settings screen not reached via tap -> pushed programmatically');
            tester.state<NavigatorState>(find.byType(Navigator).first)
                .push(MaterialPageRoute<void>(builder: (_) => const SettingsScreen()));
            await tester.pumpAndSettle();
          }
          // scroll through the whole ListView so every child gets laid out
          final lv = find.byType(ListView);
          if (lv.evaluate().isNotEmpty) {
            await tester.drag(lv.first, const Offset(0, -2000));
            await tester.pumpAndSettle();
          }
        });

        await step('delete-all dialog', () async {
          final f = find.byIcon(Icons.delete_forever);
          if (f.evaluate().isNotEmpty) {
            await tester.tap(f, warnIfMissed: false);
            await tester.pumpAndSettle();
          }
          if (find.byType(AlertDialog).evaluate().isEmpty) {
            results.add('$cfg | delete-all dialog | could not open');
          }
        });

        await step('delete-all dialog + keyboard (viewInsets bottom = 45% of height)', () async {
          if (find.byType(AlertDialog).evaluate().isNotEmpty) {
            await tryTap(
                find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextField)),
                'dialog TextField', 'delete-all + keyboard');
            tester.view.viewInsets = FakeViewPadding(
                bottom: cfg.size.height * 0.45 * tester.view.devicePixelRatio);
            await tester.pumpAndSettle();
            tester.view.resetViewInsets();
            await tester.pumpAndSettle();
            popTop();
            await tester.pumpAndSettle();
          }
        });

        await step('settings wage field + keyboard', () async {
          final tf = find.byType(TextField);
          if (tf.evaluate().isNotEmpty) {
            if (find.byType(ListView).evaluate().isEmpty) return;
            await tester.drag(find.byType(ListView).first, const Offset(0, 2000));
            await tester.pumpAndSettle();
            await tester.tap(tf.first, warnIfMissed: false);
            tester.view.viewInsets = FakeViewPadding(
                bottom: cfg.size.height * 0.45 * tester.view.devicePixelRatio);
            await tester.pumpAndSettle();
            tester.view.resetViewInsets();
            await tester.pumpAndSettle();
          }
        });

        await h.dispose(tester);
        resetScreen(tester);
      });
    }
  }

  // Home screen with realistic Android system bars (status bar 24dp, 3-button
  // navigation bar 48dp in portrait / gesture bar 24dp).
  for (final e in {
    '360x640 status24 nav48': (const Size(360, 640), 24.0, 48.0),
    '360x740 status24 gesture24': (const Size(360, 740), 24.0, 24.0),
    '412x915 status24 nav48': (const Size(412, 915), 24.0, 48.0),
  }.entries) {
    for (final scale in [1.0, 1.15, 1.3]) {
      testWidgets('home with system bars ${e.key} @${scale}x', (tester) async {
        installNotificationStub();
        final (size, top, bottom) = e.value;
        setScreen(tester, size,
            textScale: scale, padding: FakeViewPadding(top: top * 3, bottom: bottom * 3));
        final h = await bootApp({'app_settings': settingsJson(), 'work_entries': sampleEntriesJson()});
        final errs = await captureErrors(() async {
          await tester.pumpWidget(h.app);
          await tester.pumpAndSettle();
        });
        final uniq = errs.map((x) => x.summary).where((x) => !x.contains('home_screen.dart:148')).toSet();
        results.add('home+systembars ${e.key} @${scale}x | ${uniq.isEmpty ? 'OK' : uniq.join(' || ')} | ${homeGeometry(tester)}');
        await h.dispose(tester);
        resetScreen(tester);
      });
    }
  }

  // Large amounts: horizontal overflow of AnimatedMoneyDisplay
  for (final amount in [999.99, 2400.0, 12345.67]) {
    for (final e in {'small-phone': const Size(360, 640), 'phone-portrait': const Size(412, 915)}.entries) {
      testWidgets('money display width, total open=$amount on ${e.key}', (tester) async {
        installNotificationStub();
        setScreen(tester, e.value);
        // one unpaid entry worth `amount` at 15 EUR/h:  minutes = amount/15*60
        final minutes = (amount / 15 * 60).round();
        final start = DateTime(2026, 1, 5, 0, 0);
        final end = start.add(Duration(minutes: minutes));
        final entries =
            '[{"id":"big","date":"${DateTime(2026, 1, 5).toIso8601String()}","startTime":"${start.toIso8601String()}","endTime":"${end.toIso8601String()}","isPaid":false}]';
        final h = await bootApp({'app_settings': settingsJson(), 'work_entries': entries});
        final errs = await captureErrors(() async {
          await tester.pumpWidget(h.app);
          await tester.pumpAndSettle();
        });
        final uniq = errs.map((e) => e.summary).toSet();
        results.add('money ${e.key} ${e.value.width.toInt()}x${e.value.height.toInt()} total=$amount | '
            '${uniq.isEmpty ? 'OK' : uniq.join(' || ')}');
        await h.dispose(tester);
        resetScreen(tester);
      });
    }
  }
}
