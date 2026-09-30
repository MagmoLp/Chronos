import 'dart:async';

import 'package:chronos/app/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pump_app.dart';

void main() {
  testWidgets(
    'pumpApp applies theme, locale, size, text scale and 24 h setting',
    (tester) async {
      late BuildContext ctx;
      await pumpApp(
        tester,
        Builder(
          builder: (context) {
            ctx = context;
            return const SizedBox();
          },
        ),
        config: const TestConfig(
          brightness: Brightness.dark,
          locale: Locale('en'),
          size: TestScreens.landscapeSmall,
          textScale: 2,
        ),
      );
      expect(Theme.of(ctx).colorScheme, ChronosTheme.dark.colorScheme);
      expect(Localizations.localeOf(ctx), const Locale('en'));
      expect(MediaQuery.sizeOf(ctx), const Size(800, 360));
      expect(MediaQuery.textScalerOf(ctx).scale(10), 20);
      expect(MediaQuery.alwaysUse24HourFormatOf(ctx), isFalse);

      await pumpApp(
        tester,
        Builder(
          builder: (context) =>
              Text(MaterialLocalizations.of(context).okButtonLabel),
        ),
      );
      expect(find.text('OK'), findsOneWidget);
    },
  );

  testWidgets('expectNoLayoutErrors fails on a RenderFlex overflow', (
    tester,
  ) async {
    setScreenSize(tester, TestScreens.phoneSmall);
    await tester.pumpWidget(
      buildTestApp(
        const Row(children: <Widget>[SizedBox(width: 500, height: 10)]),
      ),
    );
    expect(
      () => expectNoLayoutErrors(tester, 'overflow probe'),
      throwsA(isA<TestFailure>()),
    );
  });

  test(
    'the matrix covers both themes, both locales, all sizes and 2 text scales',
    () {
      final configs = TestConfig.matrix().toList();
      expect(configs, hasLength(2 * 2 * TestScreens.all.length * 2));
      expect(configs.map((c) => c.textScale).toSet(), {1.0, 2.0});
      expect(configs.first.toString(), 'light/de/360x640/1.0x');
    },
  );

  test('TimerTracker counts pending timers created in its zone', () async {
    final tracker = TimerTracker();
    late Timer timer;
    await tracker.run(() async {
      timer = Timer(const Duration(hours: 1), () {});
      Timer(Duration.zero, () {});
    });
    expect(tracker.created, 2);
    await Future<void>.delayed(Duration.zero);
    expect(tracker.pending, 1);
    timer.cancel();
    expect(tracker.pending, 0);
  });
}
