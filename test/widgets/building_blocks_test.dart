import 'package:chronos/app/theme/theme.dart';
import 'package:chronos/widgets/date_block.dart';
import 'package:chronos/widgets/empty_state.dart';
import 'package:chronos/widgets/hint_card.dart';
import 'package:chronos/widgets/responsive_center.dart';
import 'package:chronos/widgets/section_header.dart';
import 'package:chronos/widgets/stat_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_app.dart';

final DateTime wed = DateTime(2026, 9, 30);

/// A realistic screen that uses every building block, so the layout is
/// checked in context (scrollable, like a real page).
Widget _sampleScreen() {
  return Builder(
    builder: (context) {
      final l10n = l10nFor(Localizations.localeOf(context));
      return ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          HintCard(
            tone: HintTone.warning,
            title: 'Benachrichtigungen sind aus',
            message: 'Aktiviere sie, damit du die laufende Schicht immer im Blick hast.',
            actionLabel: l10n.commonOpenSettings,
            onAction: () {},
            onDismiss: () {},
          ),
          const SizedBox(height: 16),
          const HintCard(message: '3 übernommene Einträge prüfen'),
          SectionHeader(
            'September 2026',
            subtitle: '42,5 h · 637,50 € · 318,75 € offen',
            trailing: TextButton(onPressed: () {}, child: Text(l10n.commonAll)),
          ),
          Row(
            children: <Widget>[
              DateBlock(date: wed, highlighted: true),
              const SizedBox(width: 16),
              DateBlock(date: wed.subtract(const Duration(days: 3))),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: StatCard(
                  label: 'Verdient',
                  value: '12.637,50 €',
                  caption: '42,5 h',
                  icon: Icons.euro,
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: StatCard(
                  label: 'Ø Stundenlohn inkl. Trinkgeld',
                  value: '15,75 €/h',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 420,
            child: EmptyState(
              icon: Icons.work_history_outlined,
              title: 'Noch keine Schichten',
              message:
                  'Starte deine erste Schicht oder trag eine vergangene nach.',
              action: FilledButton(
                onPressed: () {},
                child: const Text('Schicht starten'),
              ),
              secondaryAction: TextButton(
                onPressed: () {},
                child: const Text('Schicht nachtragen'),
              ),
            ),
          ),
        ],
      );
    },
  );
}

void main() {
  testWidgets('no overflow in any theme, locale, screen size or text scale', (
    tester,
  ) async {
    for (final config in TestConfig.matrix()) {
      await pumpApp(tester, _sampleScreen(), config: config);
      // Scroll to the end to lay out every child.
      await tester.drag(find.byType(ListView), const Offset(0, -3000));
      await tester.pumpAndSettle();
      expectNoLayoutErrors(tester, config);
    }
  });

  testWidgets(
    'meets tap-target, label and contrast guidelines in both themes',
    (tester) async {
      for (final brightness in Brightness.values) {
        for (final locale in const [Locale('de'), Locale('en')]) {
          await pumpApp(
            tester,
            _sampleScreen(),
            config: TestConfig(
              brightness: brightness,
              locale: locale,
              size: TestScreens.phoneLarge,
            ),
          );
          await expectMeetsAccessibilityGuidelines(tester);
        }
      }
    },
  );

  group('DateBlock', () {
    testWidgets('shows day and weekday and reads the full date', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpApp(tester, Center(child: DateBlock(date: wed)));
      expect(find.text('30'), findsOneWidget);
      expect(find.text('Mi'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Mittwoch, 30. September 2026'),
        findsOneWidget,
      );
      expect(
        tester.getSize(find.byType(DateBlock)).width,
        greaterThanOrEqualTo(DateBlock.size),
      );

      await pumpApp(
        tester,
        Center(child: DateBlock(date: wed)),
        config: const TestConfig(locale: Locale('en')),
      );
      expect(find.text('Wed'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Wednesday, September 30, 2026'),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('highlight uses the primary container', (tester) async {
      await pumpApp(
        tester,
        Center(child: DateBlock(date: wed, highlighted: true)),
      );
      final box = tester.widget<DecoratedBox>(
        find.descendant(
          of: find.byType(DateBlock),
          matching: find.byType(DecoratedBox),
        ),
      );
      expect(
        (box.decoration as BoxDecoration).color,
        ChronosTheme.light.colorScheme.primaryContainer,
      );
    });

    testWidgets('fits a tight 72 dp list row at 200 % text', (tester) async {
      await pumpApp(
        tester,
        Center(
          child: SizedBox(width: 56, height: 56, child: DateBlock(date: wed)),
        ),
        config: const TestConfig(textScale: 2),
      );
    });
  });

  group('SectionHeader', () {
    testWidgets('title is a semantic header', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpApp(
        tester,
        const SectionHeader('September 2026', subtitle: '42,5 h'),
      );
      expect(
        tester.getSemantics(find.text('September 2026')),
        isSemantics(isHeader: true),
      );
      expect(find.text('42,5 h'), findsOneWidget);
      handle.dispose();
    });
  });

  group('StatCard', () {
    testWidgets('is read as one unit and can be tapped', (tester) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      await pumpApp(
        tester,
        Center(
          child: StatCard(
            label: 'Offen',
            value: '318,75 €',
            onTap: () => taps++,
          ),
        ),
      );
      expect(
        tester.getSemantics(find.byType(StatCard)),
        isSemantics(
          label: 'Offen\n318,75 €',
          isButton: true,
          hasTapAction: true,
        ),
      );
      await tester.tap(find.byType(StatCard));
      expect(taps, 1);
      handle.dispose();
    });

    testWidgets(
      'value uses the stat role with tabular figures and scales down',
      (tester) async {
        await pumpApp(
          tester,
          const Center(
            child: SizedBox(
              width: 120,
              child: StatCard(label: 'Verdient', value: '123.456,78 €'),
            ),
          ),
          config: const TestConfig(textScale: 2),
        );
        final value = tester.widget<Text>(find.text('123.456,78 €'));
        expect(
          value.style!.fontFeatures,
          contains(const FontFeature.tabularFigures()),
        );
        expect(tester.getSize(find.byType(StatCard)).width, 120);
      },
    );

    testWidgets('uses the tonal card surface without elevation', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const StatCard(label: 'Stunden', value: '42,5 h'),
        config: const TestConfig(brightness: Brightness.dark),
      );
      final material = tester.widget<Material>(
        find
            .descendant(of: find.byType(Card), matching: find.byType(Material))
            .first,
      );
      expect(material.color, ChronosTheme.dark.colorScheme.surfaceContainerLow);
      expect(material.elevation, 0);
    });
  });

  group('HintCard', () {
    testWidgets('action and dismiss work and are labelled', (tester) async {
      var actions = 0;
      var dismissed = 0;
      await pumpApp(
        tester,
        HintCard(
          message: 'Benachrichtigungen sind aus',
          actionLabel: 'Einstellungen öffnen',
          onAction: () => actions++,
          onDismiss: () => dismissed++,
        ),
      );
      await tester.tap(find.text('Einstellungen öffnen'));
      await tester.tap(find.byTooltip('Ausblenden'));
      expect(actions, 1);
      expect(dismissed, 1);
    });

    testWidgets('warning tone uses the amber container', (tester) async {
      await pumpApp(
        tester,
        const HintCard(message: 'x', tone: HintTone.warning),
      );
      final material = tester.widget<Material>(
        find
            .descendant(
              of: find.byType(HintCard),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(material.color, ChronosColors.light.warningContainer);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });
  });

  group('EmptyState', () {
    testWidgets('title is a header and actions are shown', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpApp(
        tester,
        EmptyState(
          icon: Icons.inbox_outlined,
          title: 'Noch keine Schichten',
          action: FilledButton(
            onPressed: () {},
            child: const Text('Schicht starten'),
          ),
        ),
      );
      expect(
        tester.getSemantics(find.text('Noch keine Schichten')),
        isSemantics(isHeader: true),
      );
      expect(find.text('Schicht starten'), findsOneWidget);
      handle.dispose();
    });
  });

  group('ResponsiveCenter', () {
    const key = Key('content');
    for (final (width, expectedLeft, expectedWidth)
        in <(double, double, double)>[
          (360, 16, 328),
          (700, 24, 652),
          (1280, 220, 840),
        ]) {
      testWidgets('at ${width.toInt()} dp width', (tester) async {
        await pumpApp(
          tester,
          const ResponsiveCenter(
            child: SizedBox(key: key, height: 10, width: double.infinity),
          ),
          config: TestConfig(size: Size(width, 800)),
        );
        expect(tester.getTopLeft(find.byKey(key)).dx, expectedLeft);
        expect(tester.getSize(find.byKey(key)).width, expectedWidth);

        await pumpApp(
          tester,
          const CustomScrollView(
            slivers: <Widget>[
              SliverResponsiveCenter(
                sliver: SliverToBoxAdapter(
                  child: SizedBox(key: key, height: 10),
                ),
              ),
            ],
          ),
          config: TestConfig(size: Size(width, 800)),
        );
        expect(tester.getTopLeft(find.byKey(key)).dx, expectedLeft);
        expect(tester.getSize(find.byKey(key)).width, expectedWidth);
      });
    }

    test('horizontalPaddingFor', () {
      expect(ResponsiveCenter.horizontalPaddingFor(360), 16);
      expect(ResponsiveCenter.horizontalPaddingFor(1000), 80);
      expect(ResponsiveCenter.horizontalPaddingFor(360, applyMargin: false), 0);
      expect(ResponsiveCenter.horizontalPaddingFor(600, maxWidth: 560), 24);
    });
  });
}
