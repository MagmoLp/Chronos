import 'package:chronos/domain/job.dart';
import 'package:chronos/features/today/finish_shift_sheet.dart';
import 'package:chronos/features/today/notification_primer.dart';
import 'package:chronos/features/today/time_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'today_test_support.dart';

/// Tap targets ≥ 48 dp, labelled targets and text contrast in the main
/// states, in both themes.
void main() {
  for (final brightness in Brightness.values) {
    final config = TestConfig(
      brightness: brightness,
      size: TestScreens.phoneLarge,
    );
    final l10n = l10nFor(config.locale);

    group(brightness.name, () {
      for (final state in <String, Future<void> Function(ProviderHarness)>{
        'idle with hints and job chip': TodayScenarios.idleWithHints,
        'idle, worked today': TodayScenarios.idleWorked,
        'running': TodayScenarios.running,
        'paused': TodayScenarios.paused,
      }.entries) {
        testWidgets(state.key, (tester) async {
          await pumpFeature(
            tester,
            todayInShell(),
            config: config,
            seed: state.value,
          );
          await expectMeetsAccessibilityGuidelines(tester);
        });
      }

      testWidgets('expanded with side pane', (tester) async {
        await pumpFeature(
          tester,
          todayInShell(),
          config: TestConfig(
            brightness: brightness,
            size: TestScreens.tabletLandscape,
          ),
          seed: TodayScenarios.running,
        );
        await expectMeetsAccessibilityGuidelines(tester);
      });

      testWidgets('finish sheet', (tester) async {
        await pumpFeature(
          tester,
          todayInShell(),
          config: config,
          seed: (h) async {
            final job = await TodaySeed.job(
              h,
              rounding: RoundingRule.nearest15,
            );
            await TodaySeed.running(
              h,
              job,
              ago: const Duration(hours: 2, minutes: 7),
            );
          },
        );
        await tester.tap(find.text(l10n.todayFinish));
        await settleData(tester);
        expect(find.byType(FinishShiftSheet), findsOneWidget);
        await expectMeetsAccessibilityGuidelines(tester);
      });

      testWidgets('notification primer', (tester) async {
        await pumpFeature(
          tester,
          todayInShell(),
          config: config,
          seed: (h) async {
            notificationsOf(h).enabled = false;
            await TodaySeed.job(h, primerShown: false);
          },
        );
        await tester.tap(find.text(l10n.todayStartShift));
        await tester.pumpAndSettle();
        expect(find.byType(NotificationPrimerSheet), findsOneWidget);
        await expectMeetsAccessibilityGuidelines(tester);
      });

      testWidgets('start time dialog', (tester) async {
        await pumpFeature(
          tester,
          todayInShell(),
          config: config,
          seed: (h) => TodaySeed.job(h),
        );
        await tester.tap(find.text(l10n.todayStartedEarlier));
        await tester.pumpAndSettle();
        expect(find.byType(TodayTimeDialog), findsOneWidget);
        await expectMeetsAccessibilityGuidelines(tester);
      });
    });
  }

  testWidgets('screen reader labels', (tester) async {
    final handle = tester.ensureSemantics();
    final l10n = l10nFor(const Locale('de'));
    await pumpFeature(
      tester,
      todayInShell(),
      config: const TestConfig(size: TestScreens.phoneLarge),
      seed: TodayScenarios.running,
    );
    // Label and amount are read together.
    final fmt = fmtFor(const Locale('de'));
    // 2 h earlier today + 2:41 h running at 15 €/h.
    expect(
      find.bySemanticsLabel('${l10n.todayEarnedToday}\n${fmt.money(7025)}'),
      findsOneWidget,
    );
    // The stopwatch is spoken as a duration, not as digits.
    expect(
      find.bySemanticsLabel(
        l10n.todayWorkedSemantics(
          fmt.durationSpoken(
            const Duration(hours: 2, minutes: 41).inMilliseconds,
          ),
        ),
      ),
      findsOneWidget,
    );
    expect(find.byTooltip(l10n.todayAdjustStart), findsOneWidget);
    handle.dispose();
  });

  testWidgets('job chip is announced with its job', (tester) async {
    final handle = tester.ensureSemantics();
    final l10n = l10nFor(const Locale('de'));
    await pumpFeature(
      tester,
      todayInShell(),
      config: const TestConfig(size: TestScreens.phoneLarge),
      seed: TodayScenarios.idleWorked,
    );
    expect(
      find.bySemanticsLabel(l10n.todayJobSemantics('Catering')),
      findsOneWidget,
    );
    handle.dispose();
  });
}
