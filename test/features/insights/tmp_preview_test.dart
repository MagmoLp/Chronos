import 'package:chronos/app/providers/providers.dart';
import 'package:chronos/app/shell.dart';
import 'package:chronos/core/local_date.dart';
import 'package:chronos/domain/app_settings.dart';
import 'package:chronos/features/insights/insights_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/feature_harness.dart';
import 'seed.dart';

void main() {
  Future<void> seedFull(ProviderHarness h) async {
    final job = await h.job(name: 'Catering Müller');
    await addShift(h, job, LocalDate(2026, 9, 28), tips: 500, breakMinutes: 30);
    await addShift(h, job, LocalDate(2026, 9, 29), end: 12, paid: true);
    await addShift(h, job, LocalDate(2026, 9, 2), end: 17);
    await addShift(h, job, LocalDate(2026, 9, 10), start: 10, end: 18);
    await addShift(h, job, LocalDate(2026, 9, 18), start: 9, end: 13);
    await addShift(h, job, LocalDate(2026, 8, 15));
    final bar = await h.job(name: 'Eventhalle', centsPerHour: 1420);
    await addShift(h, bar, LocalDate(2026, 9, 26), start: 18, end: 26);
    await h
        .read(payoutRepositoryProvider)
        .create(until: LocalDate(2026, 9, 5), receivedCents: 25000);
    await h.read(settingsStoreProvider.future);
    await h.read(settingsRepositoryProvider.future);
    await h
        .read(settingsProvider.notifier)
        .setMonthlyGoal(60300, type: MonthlyGoalType.limit);
  }

  for (final (name, config) in [
    ('phone_light', const TestConfig(size: Size(412, 1800))),
    (
      'phone_dark_en',
      const TestConfig(
        size: Size(412, 1800),
        brightness: Brightness.dark,
        locale: Locale('en'),
      ),
    ),
    ('tablet', const TestConfig(size: Size(1280, 1000))),
    ('landscape', const TestConfig(size: Size(915, 1100))),
    ('phone_2x', const TestConfig(size: Size(360, 2600), textScale: 2)),
  ]) {
    testWidgets('preview $name', (tester) async {
      await loadAppFonts();
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
      await expectLater(
        find.byType(AdaptiveShell),
        matchesGoldenFile('/tmp/claude-0/-home-user-Chronos/bf910a26-5d5a-5255-844b-dfb5f32e4695/scratchpad/shots/insights_$name.png'),
      );
    });
  }
}
