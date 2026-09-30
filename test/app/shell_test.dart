import 'package:chronos/app/shell.dart';
import 'package:chronos/widgets/live_ticker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_app.dart';

/// A page like the real ones: own Scaffold, app bar with the settings action,
/// a scrollable body and some local state.
class _Page extends StatefulWidget {
  const _Page(this.title, {this.onBuild, this.body});

  final String title;
  final VoidCallback? onBuild;
  final Widget? body;

  @override
  State<_Page> createState() => _PageState();
}

class _PageState extends State<_Page> {
  int count = 0;

  @override
  Widget build(BuildContext context) {
    widget.onBuild?.call();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: <Widget>[ShellSettingsButton(onPressed: () {})],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text('${widget.title}: $count'),
          FilledButton(
            onPressed: () => setState(() => count++),
            child: Text('${widget.title} +1'),
          ),
          ?widget.body,
        ],
      ),
    );
  }
}

Widget _shell({
  ShellController? controller,
  ValueChanged<ShellTab>? onTabChanged,
  VoidCallback? onShiftsBuilt,
  Widget? todayBody,
}) {
  return AdaptiveShell(
    controller: controller,
    onTabChanged: onTabChanged,
    todayBuilder: (_) => _Page('Today page', body: todayBody),
    shiftsBuilder: (_) => _Page('Shifts page', onBuild: onShiftsBuilt),
    insightsBuilder: (_) => const _Page('Insights page'),
  );
}

Future<void> _pumpShell(
  WidgetTester tester,
  Widget shell, {
  TestConfig config = const TestConfig(),
}) => pumpApp(tester, shell, config: config, wrapInScaffold: false);

void main() {
  group('navigation type', () {
    for (final (size, rail) in <(Size, bool)>[
      (TestScreens.phoneSmall, false),
      (TestScreens.phoneLarge, false),
      (const Size(599, 800), false),
      (const Size(600, 800), true),
      (const Size(400, 479), true),
      (TestScreens.landscapeSmall, true),
      (TestScreens.landscapeLarge, true),
      (TestScreens.tabletPortrait, true),
      (TestScreens.tabletLandscape, true),
    ]) {
      testWidgets(
        '${size.width.toInt()}x${size.height.toInt()} uses ${rail ? 'rail' : 'bar'}',
        (tester) async {
          await _pumpShell(tester, _shell(), config: TestConfig(size: size));
          expect(
            find.byType(NavigationRail),
            rail ? findsOneWidget : findsNothing,
          );
          expect(
            find.byType(NavigationBar),
            rail ? findsNothing : findsOneWidget,
          );
          expect(AdaptiveShell.usesRail(size), rail);
          for (final label in ['Heute', 'Schichten', 'Übersicht']) {
            expect(
              find.text(label),
              findsOneWidget,
              reason: 'labels are always visible',
            );
          }
        },
      );
    }

    testWidgets('switches live when the window is resized, keeping the tab', (
      tester,
    ) async {
      await _pumpShell(tester, _shell());
      await tester.tap(find.text('Schichten'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Shifts page +1'));
      await tester.pump();

      setScreenSize(tester, TestScreens.landscapeSmall);
      await tester.pumpAndSettle();
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.text('Shifts page: 1'), findsOneWidget);
      expect(
        tester
            .widget<NavigationRail>(find.byType(NavigationRail))
            .selectedIndex,
        1,
      );
    });
  });

  testWidgets('English labels', (tester) async {
    await _pumpShell(
      tester,
      _shell(),
      config: const TestConfig(locale: Locale('en')),
    );
    for (final label in ['Today', 'Shifts', 'Insights']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.byTooltip('Settings'), findsOneWidget);
  });

  testWidgets('tabs keep their state and are built lazily', (tester) async {
    var shiftsBuilds = 0;
    await _pumpShell(tester, _shell(onShiftsBuilt: () => shiftsBuilds++));
    expect(shiftsBuilds, 0, reason: 'not built before the first visit');

    await tester.tap(find.text('Today page +1'));
    await tester.tap(find.text('Today page +1'));
    await tester.pump();
    expect(find.text('Today page: 2'), findsOneWidget);

    await tester.tap(find.text('Schichten'));
    await tester.pumpAndSettle();
    expect(shiftsBuilds, greaterThan(0));
    expect(find.text('Shifts page: 0'), findsOneWidget);
    expect(
      find.text('Today page: 2'),
      findsNothing,
      reason: 'hidden tab is not shown',
    );

    await tester.tap(find.text('Heute'));
    await tester.pumpAndSettle();
    expect(find.text('Today page: 2'), findsOneWidget);
  });

  testWidgets('system back on Shifts/Insights returns to Today, then leaves', (
    tester,
  ) async {
    final changes = <ShellTab>[];
    await _pumpShell(tester, _shell(onTabChanged: changes.add));

    await tester.tap(find.text('Übersicht'));
    await tester.pumpAndSettle();
    expect(find.text('Insights page: 0'), findsOneWidget);

    expect(
      await tester.binding.handlePopRoute(),
      isTrue,
      reason: 'back is consumed',
    );
    await tester.pumpAndSettle();
    expect(find.text('Today page: 0'), findsOneWidget);

    final systemCalls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        systemCalls.add(call);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    expect(
      await tester.binding.handlePopRoute(),
      isFalse,
      reason: 'on Today back leaves the app',
    );
    expect(systemCalls.map((c) => c.method), contains('SystemNavigator.pop'));
    expect(changes, [ShellTab.insights, ShellTab.today]);
  });

  testWidgets('back closes a pushed route before switching tabs', (
    tester,
  ) async {
    await _pumpShell(tester, _shell());
    await tester.tap(find.text('Schichten'));
    await tester.pumpAndSettle();
    final navigator = Navigator.of(tester.element(find.text('Shifts page: 0')));
    navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Settings screen')),
      ),
    );
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Settings screen'), findsNothing);
    expect(find.text('Shifts page: 0'), findsOneWidget);
  });

  testWidgets('controller and selectTab switch tabs from outside and inside', (
    tester,
  ) async {
    final controller = ShellController();
    addTearDown(controller.dispose);
    await _pumpShell(tester, _shell(controller: controller));

    controller.select(ShellTab.insights);
    await tester.pumpAndSettle();
    expect(find.text('Insights page: 0'), findsOneWidget);

    AdaptiveShell.selectTab(
      tester.element(find.text('Insights page: 0')),
      ShellTab.shifts,
    );
    await tester.pumpAndSettle();
    expect(find.text('Shifts page: 0'), findsOneWidget);
    expect(controller.value, ShellTab.shifts);
    expect(
      AdaptiveShell.controllerOf(tester.element(find.text('Shifts page: 0'))),
      same(controller),
    );
  });

  testWidgets('hidden tabs stop their live tickers', (tester) async {
    var ticks = 0;
    await _pumpShell(
      tester,
      _shell(
        todayBody: LiveTicker(
          builder: (context, now) {
            ticks++;
            return const SizedBox();
          },
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(ticks, greaterThanOrEqualTo(2));

    await tester.tap(find.text('Schichten'));
    await tester.pumpAndSettle();
    final hiddenStart = ticks;
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    expect(ticks, hiddenStart, reason: 'no ticks while Today is not visible');

    await tester.tap(find.text('Heute'));
    await tester.pumpAndSettle();
    expect(ticks, greaterThan(hiddenStart));
  });

  testWidgets('pages do not pad for the bar twice and the keyboard is offset', (
    tester,
  ) async {
    late MediaQueryData pageMedia;
    setScreenSize(tester, TestScreens.phoneSmall);
    tester.view
      ..padding = const FakeViewPadding(bottom: 24)
      ..viewPadding = const FakeViewPadding(bottom: 24)
      ..viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpWidget(
      buildTestApp(
        AdaptiveShell(
          todayBuilder: (context) {
            pageMedia = MediaQuery.of(context);
            return const SizedBox.expand();
          },
          shiftsBuilder: (_) => const SizedBox(),
          insightsBuilder: (_) => const SizedBox(),
        ),
        wrapInScaffold: false,
      ),
    );
    expect(pageMedia.padding.bottom, 0);
    expect(pageMedia.viewPadding.bottom, 0);
    expect(pageMedia.viewInsets.bottom, 300 - 80 - 24);
  });

  testWidgets('no overflow in any theme, locale, size or text scale', (
    tester,
  ) async {
    for (final config in TestConfig.matrix()) {
      await _pumpShell(tester, _shell(), config: config);
      for (final label in [
        l10nFor(config.locale).navShifts,
        l10nFor(config.locale).navInsights,
      ]) {
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
        expectNoLayoutErrors(tester, config);
      }
    }
  });

  testWidgets(
    'meets the accessibility guidelines with bar and rail in both themes',
    (tester) async {
      for (final brightness in const [Brightness.light, Brightness.dark]) {
        for (final size in const [
          TestScreens.phoneSmall,
          TestScreens.landscapeSmall,
        ]) {
          await _pumpShell(
            tester,
            _shell(),
            config: TestConfig(brightness: brightness, size: size),
          );
          await expectMeetsAccessibilityGuidelines(tester);
        }
      }
    },
  );

  testWidgets('settings button has a tooltip and a 48 dp target', (
    tester,
  ) async {
    var pressed = 0;
    await pumpApp(
      tester,
      Center(child: ShellSettingsButton(onPressed: () => pressed++)),
    );
    await tester.tap(find.byTooltip('Einstellungen'));
    expect(pressed, 1);
    final size = tester.getSize(find.byType(ShellSettingsButton));
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));
  });
}
