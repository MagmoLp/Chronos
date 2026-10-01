import 'package:chronos/app/providers/providers.dart';
import 'package:chronos/app/shell.dart';
import 'package:chronos/app/theme/theme.dart';
import 'package:chronos/core/format.dart';
import 'package:chronos/core/local_date.dart';
import 'package:chronos/domain/app_settings.dart';
import 'package:chronos/domain/job.dart';
import 'package:chronos/features/export/export_sheet.dart';
import 'package:chronos/features/insights/insights_page.dart';
import 'package:chronos/features/insights/insights_sections.dart';
import 'package:chronos/features/settings/goal_dialog.dart';
import 'package:chronos/widgets/widgets.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/feature_harness.dart';
import 'seed.dart';

final _de = l10nFor(const Locale('de'));
final _fmt = Fmt(const Locale('de'));

/// Catering (15 €/h): Mon 28 Sep 8–16 open with 5 € tips, Tue 29 Sep 8–12
/// paid, Sat 15 Aug 8–16 open.
Future<Job> _seedBasic(ProviderHarness h) async {
  final job = await h.job();
  await addShift(h, job, LocalDate(2026, 9, 28), tips: 500);
  await addShift(h, job, LocalDate(2026, 9, 29), end: 12, paid: true);
  await addShift(h, job, LocalDate(2026, 8, 15));
  return job;
}

Finder _card(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(StatCard));

void _expectCard(String label, String value) {
  expect(
    find.descendant(of: _card(label), matching: find.text(value)),
    findsOneWidget,
    reason: '$label = $value',
  );
}

void main() {
  group('figures', () {
    testWidgets('month view shows hours, earned, unpaid, average, tips', (
      tester,
    ) async {
      await pumpFeature(tester, const InsightsPage(), seed: _seedBasic);

      expect(find.text('September 2026'), findsOneWidget);
      _expectCard(_de.insightsStatHours, _fmt.hours(12 * 3600000));
      _expectCard(_de.insightsStatEarned, _fmt.money(18000));
      _expectCard(_de.insightsStatOpen, _fmt.money(12000));
      // (180 € + 5 € tips) / 12 h = 15,42 €.
      _expectCard(_de.insightsStatAverage, _fmt.money(1542));
      _expectCard(_de.insightsStatTips, _fmt.money(500));
      expect(find.text(_de.insightsShiftCount(2)), findsOneWidget);
    });

    testWidgets('tips card is hidden without tips; empty period', (
      tester,
    ) async {
      await pumpFeature(
        tester,
        const InsightsPage(),
        seed: (h) async {
          final job = await h.job();
          await addShift(h, job, LocalDate(2026, 8, 3));
        },
      );
      expect(find.text(_de.insightsStatTips), findsNothing);
      _expectCard(_de.insightsStatAverage, _de.insightsNoValue);
      expect(find.text(_de.insightsChartEmpty), findsOneWidget);
      expect(find.byType(BarChart), findsNothing);
    });

    testWidgets('steps back and forth, never past the current period', (
      tester,
    ) async {
      await pumpFeature(tester, const InsightsPage(), seed: _seedBasic);
      final next = find.byTooltip(_de.insightsNext);
      final previous = find.byTooltip(_de.insightsPrevious);
      expect(
        tester
            .widget<IconButton>(
              find.ancestor(
                of: find.byIcon(Icons.chevron_right),
                matching: find.byType(IconButton),
              ),
            )
            .onPressed,
        isNull,
      );

      await tester.tap(previous);
      await settleData(tester);
      expect(find.text('August 2026'), findsOneWidget);
      _expectCard(_de.insightsStatEarned, _fmt.money(12000));
      _expectCard(_de.insightsStatOpen, _fmt.money(12000));

      await tester.tap(next);
      await settleData(tester);
      expect(find.text('September 2026'), findsOneWidget);
      await tester.tap(next);
      await settleData(tester);
      expect(find.text('September 2026'), findsOneWidget);
    });

    testWidgets('week and year views', (tester) async {
      await pumpFeature(tester, const InsightsPage(), seed: _seedBasic);

      await tester.tap(find.text(_de.insightsPeriodWeek));
      await settleData(tester);
      final monday = DateTime(2026, 9, 28);
      final sunday = DateTime(2026, 10, 4);
      expect(
        find.text(
          _de.insightsWeekTitle(
            _fmt.dayMonth(monday),
            _fmt.dayMonth(sunday),
            '2026',
          ),
        ),
        findsOneWidget,
      );
      _expectCard(_de.insightsStatEarned, _fmt.money(18000));
      expect(find.text(_de.insightsChartDays), findsOneWidget);

      // The week before has no shifts.
      await tester.tap(find.byTooltip(_de.insightsPrevious));
      await settleData(tester);
      _expectCard(_de.insightsStatEarned, _fmt.money(0));

      await tester.tap(find.text(_de.insightsPeriodYear));
      await settleData(tester);
      expect(find.text('2026'), findsOneWidget);
      _expectCard(_de.insightsStatEarned, _fmt.money(30000));
      expect(find.text(_de.insightsChartMonths), findsOneWidget);

      await tester.tap(find.text(_de.insightsPeriodMonth));
      await settleData(tester);
      expect(find.text('September 2026'), findsOneWidget);
    });

    testWidgets('a new day moves the current period along', (tester) async {
      final f = await pumpFeature(
        tester,
        const InsightsPage(),
        seed: _seedBasic,
      );
      f.data.clock.advance(const Duration(days: 2));
      f.read(currentDateProvider.notifier).refresh();
      await settleData(tester);
      expect(find.text('Oktober 2026'), findsOneWidget);
      _expectCard(_de.insightsStatEarned, _fmt.money(0));
    });
  });

  group('chart', () {
    testWidgets('bars have spoken labels; tapping a bar shows its values', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpFeature(
        tester,
        const InsightsPage(),
        seed: _seedBasic,
        config: const TestConfig(size: TestScreens.tabletPortrait),
      );
      expect(find.byType(BarChart), findsOneWidget);
      expect(find.text(_de.insightsChartHint), findsOneWidget);

      final day = DateTime(2026, 9, 28);
      final label = _de.insightsChartBar(
        _fmt.dateLong(day),
        _fmt.money(12000),
        _fmt.durationSpoken(8 * 3600000),
      );
      final bar = find.bySemanticsLabel(label);
      expect(bar, findsOneWidget);
      // Every day of September has a node for TalkBack.
      expect(
        find.bySemanticsLabel(RegExp(r'September 2026: ')),
        findsNWidgets(30),
      );

      // The bar nodes only carry semantics (their spoken label already says
      // everything); the tap lands on the chart's gesture detector.
      await tester.tap(bar, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(
        find.text(
          _de.insightsChartSelection(
            _fmt.dateShort(day),
            _fmt.money(12000),
            _fmt.durationHm(8 * 3600000),
          ),
        ),
        findsOneWidget,
      );
      semantics.dispose();
    });

    testWidgets('bars use the theme colour and euros', (tester) async {
      await pumpFeature(tester, const InsightsPage(), seed: _seedBasic);
      final chart = tester.widget<BarChart>(find.byType(BarChart));
      final context = tester.element(find.byType(BarChart));
      final rods = [for (final g in chart.data.barGroups) g.barRods.single];
      expect(rods, hasLength(30));
      expect(rods[27].toY, 120);
      expect(rods[28].toY, 60);
      expect(
        rods.every((r) => r.color == Theme.of(context).colorScheme.primary),
        isTrue,
      );
    });
  });

  group('monthly goal', () {
    Future<void> pumpWithGoal(
      WidgetTester tester,
      int? cents,
      MonthlyGoalType type,
    ) => pumpFeature(
      tester,
      const InsightsPage(),
      seed: (h) async {
        await _seedBasic(h);
        await h.read(settingsStoreProvider.future);
        await h.read(settingsRepositoryProvider.future);
        await h
            .read(settingsProvider.notifier)
            .setMonthlyGoal(cents, type: type);
      },
    );

    Color barColor(WidgetTester tester) => tester
        .widget<LinearProgressIndicator>(
          find.descendant(
            of: find.byType(MonthlyGoalCard),
            matching: find.byType(LinearProgressIndicator),
          ),
        )
        .color!;

    testWidgets('goal: normal colour and remaining amount', (tester) async {
      await pumpWithGoal(tester, 60300, MonthlyGoalType.goal);
      await tester.scrollUntilVisible(find.byType(MonthlyGoalCard), 200);
      expect(find.text(_de.insightsGoalTitle), findsOneWidget);
      expect(
        find.text(
          _de.insightsGoalProgress(_fmt.money(18000), _fmt.money(60300)),
        ),
        findsOneWidget,
      );
      expect(
        find.text(_de.insightsGoalRemaining(_fmt.money(42300))),
        findsOneWidget,
      );
      final context = tester.element(find.byType(MonthlyGoalCard));
      expect(barColor(tester), Theme.of(context).colorScheme.primary);
    });

    testWidgets('limit ≥ 80 %: warning colour', (tester) async {
      await pumpWithGoal(tester, 20000, MonthlyGoalType.limit);
      await tester.scrollUntilVisible(find.byType(MonthlyGoalCard), 200);
      expect(find.text(_de.insightsLimitTitle), findsOneWidget);
      expect(
        find.text(_de.insightsLimitWarning(_fmt.money(2000))),
        findsOneWidget,
      );
      final context = tester.element(find.byType(MonthlyGoalCard));
      expect(barColor(tester), ChronosColors.of(context).warning);
    });

    testWidgets('limit exceeded: error colour', (tester) async {
      await pumpWithGoal(tester, 15000, MonthlyGoalType.limit);
      await tester.scrollUntilVisible(find.byType(MonthlyGoalCard), 200);
      expect(
        find.text(_de.insightsLimitExceeded(_fmt.money(3000))),
        findsOneWidget,
      );
      final context = tester.element(find.byType(MonthlyGoalCard));
      expect(barColor(tester), Theme.of(context).colorScheme.error);
    });

    testWidgets('not configured: link opens the goal dialog', (tester) async {
      await pumpFeature(tester, const InsightsPage(), seed: _seedBasic);
      expect(find.byType(MonthlyGoalCard), findsNothing);
      await tester.scrollUntilVisible(find.text(_de.insightsGoalSetUp), 200);
      await tapVisible(tester, find.text(_de.insightsGoalSetUp));
      await tester.pumpAndSettle();
      expect(find.byType(MonthlyGoalDialog), findsOneWidget);
    });
  });

  testWidgets('per-job breakdown only with more than one job', (tester) async {
    await pumpFeature(tester, const InsightsPage(), seed: _seedBasic);
    expect(find.text(_de.insightsByJob), findsNothing);
  });

  testWidgets('per-job breakdown lists jobs with hours and earnings', (
    tester,
  ) async {
    await pumpFeature(
      tester,
      const InsightsPage(),
      seed: (h) async {
        final catering = await _seedBasic(h);
        final bar = await h.job(name: 'Bar', centsPerHour: 1200);
        await addShift(h, bar, LocalDate(2026, 9, 26), start: 18, end: 22);
        expect(catering.id, isNot(bar.id));
      },
    );
    await tester.scrollUntilVisible(find.text(_de.insightsByJob), 200);
    expect(find.text('Catering'), findsOneWidget);
    expect(find.text('Bar'), findsOneWidget);
    expect(
      find.text(
        _de.insightsJobLine(_fmt.hours(12 * 3600000), _fmt.money(18000)),
      ),
      findsOneWidget,
    );
    expect(
      find.text(_de.insightsJobLine(_fmt.hours(4 * 3600000), _fmt.money(4800))),
      findsOneWidget,
    );
  });

  testWidgets('payouts of the period with difference', (tester) async {
    await pumpFeature(
      tester,
      const InsightsPage(),
      seed: (h) async {
        await _seedBasic(h);
        await h
            .read(payoutRepositoryProvider)
            .create(until: LocalDate(2026, 9, 28), receivedCents: 25000);
      },
    );
    await tester.scrollUntilVisible(find.text(_de.insightsPayouts), 200);
    // Aug 15 (120 €) + Sep 28 (120 €) settled → expected 240 €, received 250 €.
    expect(find.text(_fmt.dateShort(DateTime(2026, 9, 30))), findsOneWidget);
    expect(find.text(_de.exportAllJobs), findsOneWidget);
    expect(find.text(_fmt.money(25000)), findsOneWidget);
    expect(find.text(_de.insightsPayoutMore(_fmt.money(1000))), findsOneWidget);

    await tapVisible(tester, find.byTooltip(_de.insightsPrevious), delta: -200);
    await settleData(tester);
    await tester.scrollUntilVisible(find.text(_de.insightsPayouts), 200);
    expect(find.text(_de.insightsPayoutsEmpty), findsOneWidget);
  });

  testWidgets('export button opens the export sheet for the period', (
    tester,
  ) async {
    await pumpFeature(tester, const InsightsPage(), seed: _seedBasic);
    await tester.tap(find.byTooltip(_de.insightsPrevious));
    await settleData(tester);
    await tapVisible(tester, find.text(_de.insightsExport));
    await settleData(tester);
    expect(find.byType(ExportSheet), findsOneWidget);
    expect(find.text('01.08.2026 – 31.08.2026'), findsOneWidget);
    final chip = tester.widget<ChoiceChip>(
      find.ancestor(
        of: find.text(_de.exportRangeLastMonth),
        matching: find.byType(ChoiceChip),
      ),
    );
    expect(chip.selected, isTrue);
  });

  testWidgets('settings gear is in the app bar', (tester) async {
    await pumpFeature(tester, const InsightsPage(), seed: _seedBasic);
    expect(find.byType(ShellSettingsButton), findsOneWidget);
  });

  group('layout', () {
    Future<void> seedFull(ProviderHarness h) async {
      await _seedBasic(h);
      final bar = await h.job(
        name: 'Eventhalle am Stadtpark',
        centsPerHour: 1420,
      );
      await addShift(h, bar, LocalDate(2026, 9, 26), start: 18, end: 26);
      await h
          .read(payoutRepositoryProvider)
          .create(until: LocalDate(2026, 9, 1), receivedCents: 11500);
      await h.read(settingsStoreProvider.future);
      await h.read(settingsRepositoryProvider.future);
      await h
          .read(settingsProvider.notifier)
          .setMonthlyGoal(60300, type: MonthlyGoalType.limit);
    }

    for (final config in TestConfig.matrix()) {
      testWidgets('no overflow in the shell: $config', (tester) async {
        await pumpFeature(
          tester,
          AdaptiveShell(
            controller: ShellController(ShellTab.insights),
            todayBuilder: (_) => const SizedBox.shrink(),
            shiftsBuilder: (_) => const SizedBox.shrink(),
            insightsBuilder: (_) => const InsightsPage(),
          ),
          config: config,
          seed: seedFull,
        );
        await scrollThrough(
          tester,
          within: find.byType(InsightsPage),
          context: config,
        );
        expect(
          find.text(l10nFor(config.locale).insightsExport),
          findsOneWidget,
        );
      });
    }
  });

  group('accessibility', () {
    for (final brightness in Brightness.values) {
      testWidgets('meets guidelines (${brightness.name})', (tester) async {
        await pumpFeature(
          tester,
          const InsightsPage(),
          config: TestConfig(
            brightness: brightness,
            size: TestScreens.phoneLarge,
          ),
          seed: (h) async {
            await _seedBasic(h);
            await h.read(settingsStoreProvider.future);
            await h.read(settingsRepositoryProvider.future);
            await h
                .read(settingsProvider.notifier)
                .setMonthlyGoal(20000, type: MonthlyGoalType.limit);
          },
        );
        await expectMeetsAccessibilityGuidelines(tester);
        await scrollThrough(tester, within: find.byType(InsightsPage));
        await expectMeetsAccessibilityGuidelines(tester);
      });
    }
  });
}
