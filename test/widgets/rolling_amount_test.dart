import 'package:chronos/app/theme/theme.dart';
import 'package:chronos/widgets/rolling_amount.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_app.dart';

const nbsp = '\u00A0';

/// Restricts [finder] to the inside of the (single) RollingAmount, so page
/// transitions of the test route do not count.
Finder _inAmount(Finder finder) =>
    find.descendant(of: find.byType(RollingAmount), matching: finder);

/// A host whose amount can be changed from the test.
class _Host extends StatefulWidget {
  const _Host({required this.initial, required this.builder});

  final String initial;
  final Widget Function(String value) builder;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late String value = widget.initial;

  void set(String next) => setState(() => value = next);

  @override
  Widget build(BuildContext context) => Center(child: widget.builder(value));
}

Future<_HostState> _pumpHost(
  WidgetTester tester,
  String initial, {
  bool disableAnimations = false,
  TestConfig config = const TestConfig(),
  Widget Function(String value)? builder,
}) async {
  await pumpApp(
    tester,
    _Host(
      initial: initial,
      builder:
          builder ??
          (v) => RollingAmount(text: v, style: const TextStyle(fontSize: 40)),
    ),
    config: config,
    disableAnimations: disableAnimations,
  );
  return tester.state<_HostState>(find.byType(_Host));
}

void main() {
  testWidgets('shows the full value with one semantics label', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpApp(tester, const Center(child: RollingAmount.cents(4783)));
    expect(find.bySemanticsLabel('47,83$nbsp€'), findsOneWidget);
    // The individual glyphs are not separate semantics nodes.
    expect(find.bySemanticsLabel('4'), findsNothing);
    expect(find.byType(RepaintBoundary), findsWidgets);
    handle.dispose();
  });

  testWidgets('cents constructor follows the locale', (tester) async {
    await pumpApp(
      tester,
      const Center(
        child: RollingAmount.cents(123456, semanticsLabel: 'Heute verdient'),
      ),
      config: const TestConfig(locale: Locale('en')),
    );
    final glyphs = tester
        .widgetList<Text>(_inAmount(find.byType(Text)))
        .map((t) => t.data)
        .join();
    expect(glyphs, '€1,234.56');
    final handle = tester.ensureSemantics();
    expect(find.bySemanticsLabel('Heute verdient'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('only the changed digit animates and it slides in from the top', (
    tester,
  ) async {
    final host = await _pumpHost(tester, '12,34 €');
    expect(_inAmount(find.byType(SlideTransition)), findsNothing);

    host.set('12,35 €');
    await tester.pump();
    // One slot animates: outgoing "4" and incoming "5".
    expect(_inAmount(find.byType(SlideTransition)), findsNWidgets(2));
    expect(_inAmount(find.byType(ClipRect)), findsWidgets);
    expect(_inAmount(find.byType(Opacity)), findsNothing);
    expect(_inAmount(find.byType(FadeTransition)), findsNothing);

    await tester.pump(const Duration(milliseconds: 60));
    final restingTop = tester.getTopLeft(find.text('3')).dy;
    expect(
      tester.getTopLeft(find.text('5')).dy,
      lessThan(restingTop),
      reason: 'new digit enters from above',
    );
    expect(
      tester.getTopLeft(find.text('4')).dy,
      greaterThan(restingTop),
      reason: 'old digit leaves downwards',
    );

    await tester.pumpAndSettle();
    expect(_inAmount(find.byType(SlideTransition)), findsNothing);
    expect(find.text('4'), findsNothing);
    expect(tester.getTopLeft(find.text('5')).dy, restingTop);
  });

  testWidgets(
    'slots are keyed from the right so cents stay stable when the number grows',
    (tester) async {
      final host = await _pumpHost(tester, '9,99 €');
      final centsSlot = find.byKey(const ValueKey<int>(3));
      final before = tester.element(centsSlot);

      host.set('10,00 €');
      await tester.pump();
      expect(identical(tester.element(centsSlot), before), isTrue);
      // Three digits changed (9→0 three times); the new leading "1" appears without rolling.
      expect(_inAmount(find.byType(SlideTransition)), findsNWidgets(6));
      await tester.pumpAndSettle();
      final glyphs = tester
          .widgetList<Text>(_inAmount(find.byType(Text)))
          .map((t) => t.data)
          .join();
      expect(glyphs, '10,00 €');
    },
  );

  testWidgets('non-digit changes swap instantly', (tester) async {
    final host = await _pumpHost(tester, '12,34 €');
    host.set('12,34 \$');
    await tester.pump();
    expect(_inAmount(find.byType(SlideTransition)), findsNothing);
    expect(find.text('\$'), findsOneWidget);
  });

  testWidgets('respects disableAnimations', (tester) async {
    final host = await _pumpHost(tester, '12,34 €', disableAnimations: true);
    host.set('12,35 €');
    await tester.pump();
    expect(_inAmount(find.byType(SlideTransition)), findsNothing);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('4'), findsNothing);
  });

  testWidgets('uses tabular figures and scales the minor part', (tester) async {
    await pumpApp(
      tester,
      const Center(
        child: RollingAmount(
          text: '47,83 €',
          fractionSeparator: ',',
          fractionScale: 0.5,
          style: TextStyle(fontSize: 40),
        ),
      ),
    );
    final styles = {
      for (final t in tester.widgetList<Text>(_inAmount(find.byType(Text))))
        t.data: t.style!,
    };
    for (final style in styles.values) {
      expect(style.fontFeatures, contains(const FontFeature.tabularFigures()));
    }
    expect(styles['4']!.fontSize, 40);
    expect(styles['7']!.fontSize, 40);
    expect(styles[',']!.fontSize, 20);
    expect(styles['8']!.fontSize, 20);
    expect(styles['€']!.fontSize, 20);
  });

  testWidgets('fraction colour applies to the minor part only', (tester) async {
    await pumpApp(
      tester,
      Builder(
        builder: (context) => RollingAmount.cents(
          4783,
          fractionScale: 0.6,
          fractionColor: Theme.of(context).colorScheme.onSurfaceVariant,
          style: ChronosTextStyles.of(context).moneyHero,
        ),
      ),
    );
    final scheme = ChronosTheme.light.colorScheme;
    expect(
      tester.widget<Text>(find.text('8')).style!.color,
      scheme.onSurfaceVariant,
    );
    expect(
      tester.widget<Text>(find.text('4')).style!.color,
      isNot(scheme.onSurfaceVariant),
    );
  });

  testWidgets('scales down instead of overflowing', (tester) async {
    for (final config in TestConfig.matrix()) {
      await pumpApp(
        tester,
        Builder(
          builder: (context) => Center(
            child: SizedBox(
              width: 120,
              child: RollingAmount.cents(
                123456789,
                style: ChronosTextStyles.of(context).moneyHeroLarge,
              ),
            ),
          ),
        ),
        config: config,
      );
      expect(
        tester.getSize(find.byType(RollingAmount)).width,
        lessThanOrEqualTo(120),
        reason: '$config',
      );
    }
  });

  testWidgets('hero amount meets the accessibility guidelines in both themes', (
    tester,
  ) async {
    for (final brightness in Brightness.values) {
      await pumpApp(
        tester,
        Builder(
          builder: (context) => Center(
            child: RollingAmount.cents(
              4783,
              style: ChronosTextStyles.of(context).moneyHero,
            ),
          ),
        ),
        config: TestConfig(brightness: brightness),
      );
      await expectMeetsAccessibilityGuidelines(tester);
    }
  });
}
