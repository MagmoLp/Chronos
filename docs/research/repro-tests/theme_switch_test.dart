// Item 3: Dark/Light theme switch.
//
// 1. Switch the theme exactly like the app's state layer allows
//    (SettingsProvider.setTheme) and check whether anything on screen changes.
// 2. Force a light Theme around each screen to see which widgets would still
//    render with hard-coded dark colours if a light theme were wired up.
// 3. Inspect the SystemUiOverlayStyle that reaches the platform.

import 'dart:io';

import 'package:chronos/models/app_settings.dart';
import 'package:chronos/screens/home_screen.dart';
import 'package:chronos/screens/settings_screen.dart';
import 'package:chronos/screens/work_log_screen.dart';
import 'package:chronos/widgets/custom_bottom_nav.dart';
import 'package:chronos/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'helpers.dart';

// ignore: avoid_print
void obs(String s) => print('OBS: $s');

String hex(Color? c) => c == null ? 'null' : '0x${c.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';

/// Snapshot of the colours that are actually painted.
Map<String, String> colourSnapshot(WidgetTester tester) {
  final out = <String, String>{};
  final ctx = tester.element(find.byType(Scaffold).first);
  out['Theme.brightness'] = Theme.of(ctx).brightness.name;
  out['Theme.scaffoldBackgroundColor'] = hex(Theme.of(ctx).scaffoldBackgroundColor);
  out['Scaffold.backgroundColor (first)'] =
      hex(tester.widget<Scaffold>(find.byType(Scaffold).first).backgroundColor);
  final appBarMat = find.descendant(of: find.byType(AppBar).first, matching: find.byType(Material));
  if (appBarMat.evaluate().isNotEmpty) {
    out['AppBar Material.color'] = hex(tester.widget<Material>(appBarMat.first).color);
  }
  final textColours = <String, int>{};
  for (final r in tester.allRenderObjects.whereType<RenderParagraph>()) {
    final c = r.text.style?.color;
    textColours[hex(c)] = (textColours[hex(c)] ?? 0) + 1;
  }
  out['painted text colours'] = textColours.toString();
  final nav = find.byType(CustomBottomNavigation);
  if (nav.evaluate().isNotEmpty) {
    final cont = tester.widget<Container>(
        find.descendant(of: nav, matching: find.byType(Container)).first);
    out['bottom nav outer Container.color'] = hex(cont.color);
  }
  return out;
}

void main() {
  setUpAll(() async => loadRealFonts());

  testWidgets('BUG: SettingsProvider.setTheme(light) changes nothing on screen', (tester) async {
    installNotificationStub();
    setScreen(tester, const Size(800, 1280));
    final h = await bootApp({'app_settings': settingsJson(theme: 'dark')});
    await tester.pumpWidget(h.app);
    await tester.pumpAndSettle();
    final darkSnap = colourSnapshot(tester);
    final styleDark = SystemChrome.latestStyle;

    await h.settings.setTheme(AppTheme.light);
    await tester.pumpAndSettle();
    final lightSnap = colourSnapshot(tester);
    final styleLight = SystemChrome.latestStyle;

    final mat = tester.widget<MaterialApp>(find.byType(MaterialApp));
    obs('MaterialApp: theme.brightness=${mat.theme?.brightness} darkTheme=${mat.darkTheme} '
        'themeMode=${mat.themeMode}  (SettingsProvider.themeMode=${h.settings.themeMode} is never read)');
    obs('dark  snapshot: $darkSnap');
    obs('light snapshot: $lightSnap');
    obs('SystemChrome.latestStyle dark : $styleDark');
    obs('SystemChrome.latestStyle light: $styleLight');
    expect(lightSnap, darkSnap);
    expect(mat.darkTheme, isNull);

    // Platform in light mode -> still dark app
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    await tester.pumpAndSettle();
    obs('platformBrightness=light -> ${colourSnapshot(tester)['Theme.brightness']}');

    // Settings screen: no theme selector at all
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -2000));
    await tester.pumpAndSettle();
    final texts = visibleTexts(tester).toSet();
    obs('settings texts: $texts');
    expect(texts.contains('Erscheinungsbild') || texts.contains('Hellmodus'), isFalse);
    obs('SystemChrome.latestStyle on settings: ${SystemChrome.latestStyle}');

    await h.dispose(tester);
    resetScreen(tester);
  });

  testWidgets('persisted light theme after restart still renders dark', (tester) async {
    installNotificationStub();
    setScreen(tester, const Size(800, 1280));
    final h = await bootApp({'app_settings': settingsJson(theme: 'light')});
    await tester.pumpWidget(h.app);
    await tester.pumpAndSettle();
    final snap = colourSnapshot(tester);
    obs('restart with theme=light persisted: settings.theme=${h.settings.theme} -> $snap');
    expect(snap['Theme.brightness'], 'dark');
    await h.dispose(tester);
    resetScreen(tester);
  });

  // What would still be dark if a light ThemeData were provided (e.g. after
  // wiring themeMode in main.dart)?
  for (final screen in ['home', 'worklog', 'settings', 'bottomnav']) {
    testWidgets('hard-coded dark colours under a LIGHT ThemeData: $screen', (tester) async {
      installNotificationStub();
      setScreen(tester, const Size(800, 1280));
      final h = await bootApp({'app_settings': settingsJson(), 'work_entries': sampleEntriesJson()});
      final Widget body = switch (screen) {
        'home' => const HomeScreen(),
        'worklog' => const WorkLogScreen(),
        'settings' => const SettingsScreen(),
        _ => Scaffold(
            bottomNavigationBar: CustomBottomNavigation(
                currentIndex: 0,
                onTap: (_) {},
                items: const [NavItem(icon: Icons.timer, label: 'A'), NavItem(icon: Icons.list, label: 'B')]),
          ),
      };
      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: h.settings),
          ChangeNotifierProvider.value(value: h.entries),
          ChangeNotifierProvider.value(value: h.timer),
        ],
        child: MaterialApp(
          theme: ThemeData(brightness: Brightness.light, useMaterial3: true),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('de'), Locale('en')],
          locale: const Locale('de'),
          home: body,
        ),
      ));
      await tester.pumpAndSettle();
      // Collect every explicitly coloured box/text that is dark-palette.
      const darkPalette = {
        0xFF121212: 'background',
        0xFF1E1E1E: 'surface',
        0xFF2A2A2A: 'surfaceLight',
        0xFFFFFFFF: 'textPrimary(white)',
        0xFFB3B3B3: 'textSecondary',
      };
      final hits = <String, int>{};
      void count(Color? c, String kind) {
        if (c == null) return;
        final name = darkPalette[c.toARGB32()];
        if (name != null) hits['$kind:$name'] = (hits['$kind:$name'] ?? 0) + 1;
      }

      for (final r in tester.allRenderObjects) {
        if (r is RenderParagraph) count(r.text.style?.color, 'text');
        if (r is RenderDecoratedBox && r.decoration is BoxDecoration) {
          count((r.decoration as BoxDecoration).color, 'box');
        }
      }
      for (final s in tester.widgetList<Scaffold>(find.byType(Scaffold))) {
        count(s.backgroundColor, 'Scaffold.backgroundColor');
      }
      obs('[$screen] under light ThemeData, hard-coded dark-palette colours still painted: $hits');
      expect(hits, isNotEmpty);
      await h.dispose(tester);
      resetScreen(tester);
    });
  }

  test('static count of hard-coded palette references (lib/)', () {
    final re = RegExp(r'AppThemeData\.(background|surface|surfaceLight|textPrimary|textSecondary)\b|Colors\.white');
    final per = <String, int>{};
    for (final f in Directory('lib').listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart')) continue;
      final n = re.allMatches(f.readAsStringSync()).length;
      if (n > 0) per[f.path] = n;
    }
    obs('hard-coded palette references per file: $per (total ${per.values.fold(0, (a, b) => a + b)})');
  });
}
