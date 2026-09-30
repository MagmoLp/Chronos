import 'package:chronos/features/today/today_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'today_test_support.dart';

double _maxScroll(WidgetTester tester) => tester
    .state<ScrollableState>(
      find.descendant(
        of: find.byKey(const ValueKey<String>('today-scroll')),
        matching: find.byType(Scrollable),
      ),
    )
    .position
    .maxScrollExtent;

/// Phone landscape (NavigationRail, two columns) must show everything
/// without scrolling at 100 % text. Measured with the real Roboto metrics:
/// the square test glyphs are about twice as wide and would wrap every line.
void main() {
  setUpAll(loadAppFonts);

  for (final state in <String, Future<void> Function(ProviderHarness)>{
    'idle, single job': TodayScenarios.idleSingle,
    'idle, worked today, two jobs': TodayScenarios.idleWorked,
    'running with break': TodayScenarios.running,
    'paused': TodayScenarios.paused,
  }.entries) {
    testWidgets('no scrolling needed: ${state.key}', (tester) async {
      for (final config in TestConfig.matrix(
        sizes: const [TestScreens.landscapeSmall, TestScreens.landscapeLarge],
        textScales: const [1.0],
      )) {
        await pumpFeature(
          tester,
          todayInShell(),
          config: config,
          seed: state.value,
        );
        expect(find.byType(NavigationRail), findsOneWidget);
        expect(find.byType(TodayActions), findsOneWidget);
        expect(_maxScroll(tester), 0, reason: '${state.key} $config');
        await tester.pumpWidget(const SizedBox.shrink());
      }
    });
  }
}
