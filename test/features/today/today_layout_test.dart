import 'package:chronos/domain/job.dart';
import 'package:chronos/features/today/finish_shift_sheet.dart';
import 'package:chronos/features/today/notification_primer.dart';
import 'package:chronos/features/today/time_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'today_test_support.dart';

const _states = <String, Future<void> Function(ProviderHarness)>{
  'idle with hints': TodayScenarios.idleWithHints,
  'idle, worked today': TodayScenarios.idleWorked,
  'running': TodayScenarios.running,
  'paused': TodayScenarios.paused,
};

/// Both themes × both locales × 100 %/200 % text at [size].
Iterable<TestConfig> _configsAt(Size size) =>
    TestConfig.matrix(sizes: <Size>[size]);

/// Every screen size, theme, locale and text scale without layout errors
/// (inside the real shell, so with NavigationBar or NavigationRail).
void main() {
  for (final screen in TestScreens.all.entries) {
    group(screen.key, () {
      for (final state in _states.entries) {
        testWidgets(state.key, (tester) async {
          for (final config in _configsAt(screen.value)) {
            await pumpFeature(
              tester,
              todayInShell(),
              config: config,
              seed: state.value,
            );
            expectNoLayoutErrors(tester, '${state.key} $config');
            await tester.pumpWidget(const SizedBox.shrink());
          }
        });
      }

      testWidgets('finish sheet', (tester) async {
        for (final config in _configsAt(screen.value)) {
          await pumpFeature(
            tester,
            todayInShell(),
            config: config,
            seed: (h) async {
              final job = await TodaySeed.job(
                h,
                rounding: RoundingRule.nearest15,
              );
              // Over midnight: the end shows its date, the start is rounded.
              await TodaySeed.running(
                h,
                job,
                ago: const Duration(days: 1, hours: 1, minutes: 7),
              );
            },
          );
          final l10n = l10nFor(config.locale);
          await tester.ensureVisible(find.text(l10n.todayFinish));
          await tester.tap(find.text(l10n.todayFinish));
          await settleData(tester);
          expect(find.byType(FinishShiftSheet), findsOneWidget);
          expectNoLayoutErrors(tester, 'finish sheet $config');
          await tester.pumpWidget(const SizedBox.shrink());
        }
      });

      testWidgets('permission primer and time dialog', (tester) async {
        for (final config in _configsAt(screen.value)) {
          await pumpFeature(
            tester,
            todayInShell(),
            config: config,
            seed: (h) async {
              notificationsOf(h).enabled = false;
              await TodaySeed.job(h, primerShown: false);
            },
          );
          final l10n = l10nFor(config.locale);
          await tester.ensureVisible(find.text(l10n.todayStartShift));
          await tester.tap(find.text(l10n.todayStartShift));
          await tester.pumpAndSettle();
          expect(find.byType(NotificationPrimerSheet), findsOneWidget);
          expectNoLayoutErrors(tester, 'primer $config');
          await tester.ensureVisible(find.text(l10n.todayPrimerLater));
          await tester.tap(find.text(l10n.todayPrimerLater));
          await settleData(tester);

          // The shift runs now: change its start (the same dialog as
          // "Früher angefangen?").
          final since = find.byTooltip(l10n.todayAdjustStart);
          await tester.ensureVisible(since);
          await tester.tap(since);
          await tester.pumpAndSettle();
          expect(find.byType(TodayTimeDialog), findsOneWidget);
          expectNoLayoutErrors(tester, 'time dialog $config');
          await tester.pumpWidget(const SizedBox.shrink());
        }
      });
    });
  }
}
