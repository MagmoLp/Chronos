// Attribution check for the date-picker overflow seen in layout_overflow_test:
// is it the framework, or the app's global textTheme.headlineLarge (56 px,
// lib/theme/app_theme.dart:94) leaking into DatePickerDialog's header?

import 'package:chronos/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

// ignore: avoid_print
void obs(String s) => print('OBS: $s');

void main() {
  setUpAll(() async => loadRealFonts());

  for (final themeName in ['app darkTheme', 'plain ThemeData.dark()']) {
    for (final scale in [1.0, 1.3]) {
      testWidgets('date picker header with $themeName @${scale}x', (tester) async {
        setScreen(tester, const Size(412, 915), textScale: scale);
        final theme = themeName == 'app darkTheme' ? AppThemeData.darkTheme : ThemeData.dark(useMaterial3: true);
        await tester.pumpWidget(MaterialApp(
          theme: theme,
          locale: const Locale('de'),
          supportedLocales: const [Locale('de'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => showDatePicker(
                  context: context,
                  initialDate: DateTime(2026, 9, 30),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ));
        final errs = await captureErrors(() async {
          await tester.tap(find.text('open'));
          await tester.pumpAndSettle();
        });
        final header = tester.allRenderObjects
            .whereType<RenderParagraph>()
            .where((p) => p.text.toPlainText().contains('Sept'))
            .map((p) => '"${p.text.toPlainText()}" fontSize=${p.text.style?.fontSize}')
            .toSet();
        obs('[$themeName @${scale}x] header: $header ; errors: ${errs.map((e) => e.summary).toSet()}');
        resetScreen(tester);
      });
    }
  }
}
