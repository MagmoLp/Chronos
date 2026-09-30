import 'package:chronos/app/startup/app_mark.dart';
import 'package:chronos/app/startup/splash_screen.dart';
import 'package:chronos/app/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/pump_app.dart';

Future<void> _pump(WidgetTester tester, TestConfig config) => pumpApp(
  tester,
  const SplashScreen(),
  config: config,
  wrapInScaffold: false,
  settle: false,
);

void main() {
  for (final (brightness, color) in [
    (Brightness.light, ChronosBrand.splashDay),
    (Brightness.dark, ChronosBrand.splashNight),
  ]) {
    testWidgets('matches the Android splash (${brightness.name})', (
      tester,
    ) async {
      await _pump(tester, TestConfig(brightness: brightness));
      final material = tester.widget<Material>(
        find
            .descendant(
              of: find.byType(SplashScreen),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(material.color, color);
      expect(find.byType(AppMark), findsOneWidget);
      final region = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
        find.byType(AnnotatedRegion<SystemUiOverlayStyle>).first,
      );
      expect(
        region.value.statusBarIconBrightness,
        brightness == Brightness.dark ? Brightness.light : Brightness.dark,
      );
    });
  }

  testWidgets('the progress bar only appears after a delay', (tester) async {
    await _pump(tester, const TestConfig());
    expect(find.byType(LinearProgressIndicator), findsNothing);
    await tester.pump(SplashScreen.progressDelay ~/ 2);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    await tester.pump(SplashScreen.progressDelay);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('announced as "Chronos startet …"', (tester) async {
    await _pump(tester, const TestConfig());
    expect(find.bySemanticsLabel('Chronos startet …'), findsOneWidget);
    await _pump(tester, const TestConfig(locale: Locale('en')));
    expect(find.bySemanticsLabel('Starting Chronos…'), findsOneWidget);
  });

  testWidgets('no overflow in every configuration', (tester) async {
    for (final config in TestConfig.matrix()) {
      await _pump(tester, config);
      await tester.pump(SplashScreen.progressDelay);
      expectNoLayoutErrors(tester, config);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  for (final brightness in Brightness.values) {
    testWidgets('accessibility guidelines (${brightness.name})', (
      tester,
    ) async {
      await _pump(tester, TestConfig(brightness: brightness));
      await expectMeetsAccessibilityGuidelines(tester);
    });
  }
}
