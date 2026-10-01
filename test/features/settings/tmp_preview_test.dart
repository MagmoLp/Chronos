import 'package:chronos/app/providers/providers.dart';
import 'package:chronos/core/local_date.dart';
import 'package:chronos/domain/app_settings.dart';
import 'package:chronos/features/export/export_sheet.dart';
import 'package:chronos/features/settings/about.dart';
import 'package:chronos/features/settings/data_actions.dart';
import 'package:chronos/features/settings/goal_dialog.dart';
import 'package:chronos/features/settings/job_editor_page.dart';
import 'package:chronos/features/settings/jobs_page.dart';
import 'package:chronos/features/settings/settings_page.dart';
import 'package:chronos/data/backup/backup_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/feature_harness.dart';
import '../insights/seed.dart';

const _dir =
    '/tmp/claude-0/-home-user-Chronos/bf910a26-5d5a-5255-844b-dfb5f32e4695/scratchpad/shots';

void main() {
  Future<void> seed(ProviderHarness h) async {
    final job = await h.job(name: 'Catering Müller');
    await h.read(jobRepositoryProvider).addRate(
      job.id,
      validFrom: LocalDate(2026, 7, 1),
      centsPerHour: 1600,
    );
    await addShift(h, job, LocalDate(2026, 9, 28));
    await h.job(name: 'Eventhalle', centsPerHour: 1420);
    final old = await h.job(name: 'Alter Job', centsPerHour: 1250);
    await h.job(name: 'Zweiter', centsPerHour: 1250);
    await h.read(jobRepositoryProvider).setArchived(old.id, true);
    await h.read(settingsStoreProvider.future);
    await h.read(settingsRepositoryProvider.future);
    await h
        .read(settingsProvider.notifier)
        .setMonthlyGoal(60300, type: MonthlyGoalType.limit);
  }

  final configs = [
    ('light', const TestConfig(size: Size(412, 1900))),
    (
      'dark_en',
      const TestConfig(
        size: Size(412, 1900),
        brightness: Brightness.dark,
        locale: Locale('en'),
      ),
    ),
    ('x2', const TestConfig(size: Size(360, 3000), textScale: 2)),
    ('tablet', const TestConfig(size: Size(1280, 1400))),
  ];

  for (final (name, config) in configs) {
    testWidgets('settings $name', (tester) async {
      await loadAppFonts();
      await pumpFeature(tester, const SettingsPage(), config: config, seed: seed);
      await expectLater(
        find.byType(SettingsPage),
        matchesGoldenFile('$_dir/settings_$name.png'),
      );
    });
  }

  for (final (name, config) in configs.take(3)) {
    testWidgets('jobs $name', (tester) async {
      await loadAppFonts();
      await pumpFeature(tester, const JobsPage(), config: config, seed: seed);
      await expectLater(
        find.byType(JobsPage),
        matchesGoldenFile('$_dir/jobs_$name.png'),
      );
    });

    testWidgets('editor $name', (tester) async {
      await loadAppFonts();
      await pumpFeature(
        tester,
        Consumer(
          builder: (context, ref, _) {
            final jobs = ref.watch(jobsProvider).value;
            if (jobs == null) return const SizedBox.shrink();
            return JobEditorPage(job: jobs.first);
          },
        ),
        config: config,
        seed: seed,
      );
      await expectLater(
        find.byType(JobEditorPage),
        matchesGoldenFile('$_dir/editor_$name.png'),
      );
    });

    testWidgets('export $name', (tester) async {
      await loadAppFonts();
      await pumpFeature(
        tester,
        Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () => showExportSheet(context),
              child: const Text('open'),
            ),
          ),
        ),
        wrapInScaffold: true,
        config: TestConfig(
          size: Size(config.size.width, 1000),
          brightness: config.brightness,
          locale: config.locale,
          textScale: config.textScale,
        ),
        seed: seed,
      );
      await tester.tap(find.text('open'));
      await settleData(tester);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('$_dir/export_$name.png'),
      );
    });

    testWidgets('dialogs $name', (tester) async {
      await loadAppFonts();
      await pumpFeature(
        tester,
        Builder(
          builder: (context) => Column(
            children: [
              TextButton(
                onPressed: () => showMonthlyGoalDialog(context),
                child: const Text('goal'),
              ),
              TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => RestoreBackupDialog(
                    summary: BackupSummary(
                      formatVersion: 1,
                      jobCount: 2,
                      shiftCount: 214,
                      payoutCount: 3,
                      hasRunningShift: false,
                      exportedAt: DateTime.utc(2026, 9, 12, 10),
                      firstShiftUtc: DateTime.utc(2026, 1, 2, 8),
                      lastShiftUtc: DateTime.utc(2026, 9, 11, 8),
                    ),
                  ),
                ),
                child: const Text('restore'),
              ),
              TextButton(
                onPressed: () => showReminderDialog(context),
                child: const Text('reminder'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const PrivacyPage()),
                ),
                child: const Text('privacy'),
              ),
            ],
          ),
        ),
        wrapInScaffold: true,
        config: TestConfig(
          size: Size(config.size.width, 900),
          brightness: config.brightness,
          locale: config.locale,
          textScale: config.textScale,
        ),
        seed: seed,
      );
      for (final d in ['goal', 'restore', 'reminder', 'privacy']) {
        await tester.tap(find.text(d));
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('$_dir/dialog_${d}_$name.png'),
        );
        tester.state<NavigatorState>(find.byType(Navigator).first).pop();
        await tester.pumpAndSettle();
      }
    });
  }
}
