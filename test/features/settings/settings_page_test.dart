import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:chronos/app/providers/providers.dart';
import 'package:chronos/core/format.dart';
import 'package:chronos/core/local_date.dart';
import 'package:chronos/data/backup/backup_models.dart';
import 'package:chronos/data/settings_repository.dart';
import 'package:chronos/domain/app_settings.dart';
import 'package:chronos/features/export/export_sheet.dart';
import 'package:chronos/features/settings/about.dart';
import 'package:chronos/features/settings/data_actions.dart';
import 'package:chronos/features/settings/goal_dialog.dart';
import 'package:chronos/features/settings/jobs_page.dart';
import 'package:chronos/features/settings/settings_page.dart';
import 'package:chronos/features/settings/widgets/settings_group.dart';
import 'package:chronos/platform/share_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/feature_harness.dart';
import '../insights/seed.dart';

final _de = l10nFor(const Locale('de'));
final _fmt = Fmt(const Locale('de'));

/// Catering (15 €/h) with two shifts (one paid).
Future<void> _seed(ProviderHarness h) async {
  final job = await h.job();
  await addShift(h, job, LocalDate(2026, 9, 28));
  await addShift(h, job, LocalDate(2026, 9, 29), end: 12, paid: true);
}

Future<FeatureHarness> _pump(
  WidgetTester tester, {
  Future<void> Function(ProviderHarness h) seed = _seed,
  TestConfig config = const TestConfig(size: TestScreens.phoneLarge),
}) => pumpFeature(tester, const SettingsPage(), seed: seed, config: config);

AppSettings _stored(FeatureHarness f) => SettingsRepository(f.data.store).load();

void _expectSnack(String text) => expect(
  find.descendant(of: find.byType(SnackBar), matching: find.text(text)),
  findsOneWidget,
);

void main() {
  group('general', () {
    testWidgets('language switch persists', (tester) async {
      final f = await _pump(tester);
      await tester.tap(find.text(_de.settingsLanguageEnglish));
      await settleData(tester);
      expect(f.read(settingsProvider).language, AppLanguage.en);
      expect(_stored(f).language, AppLanguage.en);
      // The notification is re-posted in the new language.
      expect(f.data.effects.calls, isNotEmpty);

      await tester.tap(
        find.descendant(
          of: find.ancestor(
            of: find.text(_de.settingsLanguage),
            matching: find.byType(SettingsControlTile),
          ),
          matching: find.text(_de.settingsLanguageSystem),
        ),
      );
      await settleData(tester);
      expect(_stored(f).language, AppLanguage.system);
    });

    testWidgets('theme switch persists', (tester) async {
      final f = await _pump(tester);
      await tester.tap(find.text(_de.settingsThemeDark));
      await settleData(tester);
      expect(f.read(settingsProvider).themeMode, AppThemeMode.dark);
      expect(_stored(f).themeMode, AppThemeMode.dark);
      await tester.tap(find.text(_de.settingsThemeLight));
      await settleData(tester);
      expect(_stored(f).themeMode, AppThemeMode.light);
    });
  });

  group('work', () {
    testWidgets('jobs entry shows the wage and opens the jobs list', (
      tester,
    ) async {
      await _pump(tester);
      expect(
        find.text(_de.settingsJobsOne('Catering', _fmt.rate(1500))),
        findsOneWidget,
      );
      await tester.tap(find.text(_de.settingsJobs));
      await settleData(tester);
      expect(find.byType(JobsPage), findsOneWidget);
    });

    testWidgets('monthly goal: set a limit, then switch it off', (
      tester,
    ) async {
      final f = await _pump(tester);
      expect(find.text(_de.settingsGoalOff), findsOneWidget);

      await tester.tap(find.text(_de.settingsGoal));
      await tester.pumpAndSettle();
      expect(find.byType(MonthlyGoalDialog), findsOneWidget);
      await tester.tap(find.text(_de.settingsGoalTypeLimit));
      await tester.pumpAndSettle();
      // Saving without an amount is refused.
      await tester.tap(find.text(_de.commonSave));
      await tester.pumpAndSettle();
      expect(find.text(_de.errorRequired), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextFormField, _de.settingsGoalAmount),
        '603',
      );
      await tester.tap(find.text(_de.commonSave));
      await settleData(tester);
      expect(find.byType(MonthlyGoalDialog), findsNothing);
      expect(f.read(settingsProvider).monthlyGoalCents, 60300);
      expect(f.read(settingsProvider).monthlyGoalType, MonthlyGoalType.limit);
      expect(_stored(f).monthlyGoalCents, 60300);
      expect(
        find.text(_de.settingsGoalLimitValue(_fmt.money(60300))),
        findsOneWidget,
      );

      await tester.tap(find.text(_de.settingsGoal));
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(TextFormField, _de.settingsGoalAmount),
        findsOneWidget,
      );
      await tester.tap(find.text(_de.settingsGoalTypeGoal));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_de.commonSave));
      await settleData(tester);
      expect(f.read(settingsProvider).monthlyGoalType, MonthlyGoalType.goal);
      expect(
        find.text(_de.settingsGoalGoalValue(_fmt.money(60300))),
        findsOneWidget,
      );

      await tester.tap(find.text(_de.settingsGoal));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_de.settingsGoalOff).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text(_de.commonSave));
      await settleData(tester);
      expect(f.read(settingsProvider).monthlyGoalCents, isNull);
      expect(_stored(f).monthlyGoalCents, isNull);
    });

    testWidgets('reminder: choose 6 h, then off', (tester) async {
      final f = await _pump(tester);
      expect(find.text(_de.settingsReminderHours(10)), findsOneWidget);
      await tester.tap(find.text(_de.settingsReminder));
      await tester.pumpAndSettle();
      expect(find.byType(RadioListTile<int>), findsNWidgets(5));
      await tester.tap(find.text(_de.settingsReminderHours(6)));
      await settleData(tester);
      expect(find.byType(ReminderDialog), findsNothing);
      expect(f.read(settingsProvider).reminderHours, 6);
      expect(_stored(f).reminderHours, 6);
      expect(find.text(_de.settingsReminderHours(6)), findsOneWidget);

      await tester.tap(find.text(_de.settingsReminder));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(ReminderDialog),
          matching: find.text(_de.settingsReminderOff),
        ),
      );
      await settleData(tester);
      expect(f.read(settingsProvider).reminderHours, 0);
    });
  });

  group('notifications', () {
    testWidgets('shows allowed; tap opens the system settings', (
      tester,
    ) async {
      final f = await _pump(tester);
      expect(find.text(_de.settingsNotificationsOn), findsOneWidget);
      await tester.tap(find.text(_de.settingsNotificationsOn));
      await settleData(tester);
      expect(f.notifications.settingsOpened, 1);
    });

    testWidgets('shows blocked and re-checks after returning', (tester) async {
      final f = await _pump(tester);
      f.notifications.enabled = false;
      await tester.tap(find.text(_de.settingsNotificationsOn));
      await settleData(tester);
      expect(find.text(_de.settingsNotificationsOffTitle), findsOneWidget);
      expect(find.text(_de.settingsNotificationsOff), findsOneWidget);

      f.notifications.enabled = true;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await settleData(tester);
      expect(find.text(_de.settingsNotificationsOn), findsOneWidget);
    });
  });

  group('data', () {
    testWidgets('export opens the export sheet', (tester) async {
      await _pump(tester);
      await tapVisible(tester, find.text(_de.dataExport));
      await settleData(tester);
      expect(find.byType(ExportSheet), findsOneWidget);
    });

    testWidgets('backup create shares a JSON file', (tester) async {
      final f = await _pump(tester);
      await tapVisible(tester, find.text(_de.dataBackupCreate));
      await pumpUntil(tester, () => f.share.sharedFiles.isNotEmpty);
      final shared = f.share.sharedFiles.single;
      expect(shared.mimeType, ShareMimeTypes.json);
      expect(shared.path, endsWith('chronos-backup-2026-09-30.json'));
      expect(shared.subject, _de.dataBackupSubject('30.09.2026'));
      final json = (await tester.runAsync(
        () => File(shared.path).readAsString(),
      ))!;
      final map = jsonDecode(json) as Map<String, Object?>;
      expect(map['formatVersion'], 1);
      expect(jsonEncode(map['jobs']), contains('Catering'));
    });

    Future<String> backupJson(ProviderHarness h) async =>
        (await h.read(dataControllerProvider.notifier).exportBackup()).json;

    testWidgets('restore: summary, then replace', (tester) async {
      late String json;
      final f = await _pump(
        tester,
        seed: (h) async {
          await _seed(h);
          json = await backupJson(h);
          final bar = await h.job(name: 'Bar');
          await addShift(h, bar, LocalDate(2026, 9, 27));
        },
      );
      f.share.nextPick = PickedFile(
        name: 'backup.json',
        bytes: Uint8List.fromList(utf8.encode(json)),
      );
      await tapVisible(tester, find.text(_de.dataBackupRestore));
      await settleData(tester);
      expect(find.byType(RestoreBackupDialog), findsOneWidget);
      expect(find.text(_de.dataCountShifts(2)), findsOneWidget);
      expect(find.text(_de.dataCountJobs(1)), findsOneWidget);
      expect(find.text(_de.dataCountPayouts(0)), findsOneWidget);
      expect(
        find.text(_de.dataRestoreRange('28.09.2026', '29.09.2026')),
        findsOneWidget,
      );
      expect(find.text(_de.dataRestoreCreated('30.09.2026')), findsOneWidget);

      await tester.tap(find.text(_de.dataRestoreReplace));
      await pumpUntil(tester, () => !f.read(dataControllerProvider));
      _expectSnack(_de.dataRestoreDone(2));
      final jobs = await f.data.read(jobRepositoryProvider).getJobs();
      expect(jobs.map((j) => j.name), ['Catering']);
    });

    testWidgets('restore: merge adds what is missing, keeps the rest', (
      tester,
    ) async {
      final f = await _pump(tester);
      final json = await runInApp(tester, () => backupJson(f.data));
      await runInApp(tester, () async {
        await f.read(dataControllerProvider.notifier).wipeAll();
        final other = await f.data.job(name: 'Neu');
        await addShift(f.data, other, LocalDate(2026, 9, 25));
      });
      f.share.nextPick = PickedFile(
        name: 'backup.json',
        bytes: Uint8List.fromList(utf8.encode(json)),
      );
      await tapVisible(tester, find.text(_de.dataBackupRestore));
      await settleData(tester);
      await tester.tap(find.text(_de.dataRestoreMerge));
      await pumpUntil(tester, () => !f.read(dataControllerProvider));
      _expectSnack(_de.dataMergeDone(2));
      final jobs = await f.data.read(jobRepositoryProvider).getJobs();
      expect(jobs.map((j) => j.name).toSet(), {'Neu', 'Catering'});
      final done = await f.data.read(shiftRepositoryProvider).getDone();
      expect(done, hasLength(3));
    });

    testWidgets('restore: cancel in the summary changes nothing', (
      tester,
    ) async {
      late String json;
      final f = await _pump(
        tester,
        seed: (h) async {
          await _seed(h);
          json = await backupJson(h);
        },
      );
      f.share.nextPick = PickedFile(
        name: 'backup.json',
        bytes: Uint8List.fromList(utf8.encode(json)),
      );
      await tapVisible(tester, find.text(_de.dataBackupRestore));
      await settleData(tester);
      await tester.tap(find.text(_de.commonCancel));
      await settleData(tester);
      expect(find.byType(RestoreBackupDialog), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('restore: no file picked does nothing', (tester) async {
      await _pump(tester);
      await tapVisible(tester, find.text(_de.dataBackupRestore));
      await settleData(tester);
      expect(find.byType(RestoreBackupDialog), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
    });

    for (final (name, bytes, message) in [
      ('not JSON', utf8.encode('hello'), _de.dataRestoreInvalid),
      ('not UTF-8', <int>[0xFF, 0xFE, 0xFD], _de.dataRestoreInvalid),
      (
        'newer format',
        utf8.encode('{"formatVersion": 99}'),
        _de.dataRestoreNewer,
      ),
    ]) {
      testWidgets('restore: $name → localized error', (tester) async {
        final f = await _pump(tester);
        f.share.nextPick = PickedFile(
          name: 'x.json',
          bytes: Uint8List.fromList(bytes),
        );
        await tapVisible(tester, find.text(_de.dataBackupRestore));
        await settleData(tester);
        expect(find.byType(RestoreBackupDialog), findsNothing);
        _expectSnack(message);
      });
    }

    testWidgets('delete all: confirm with counts, then undo', (tester) async {
      final f = await _pump(tester);
      await tapVisible(tester, find.text(_de.dataDeleteAll));
      await settleData(tester);
      expect(
        find.text(
          _de.dataDeleteTitle(_de.dataCountShifts(2), _de.dataCountJobs(1)),
        ),
        findsOneWidget,
      );
      expect(find.text(_de.dataDeleteMessage), findsOneWidget);
      await tester.tap(find.text(_de.commonDelete));
      await pumpUntil(tester, () => !f.read(dataControllerProvider));
      await pumpUntil(tester, () => find.byType(SnackBar).evaluate().isNotEmpty);
      _expectSnack(_de.dataDeleted);
      var counts = await f.data.read(dataControllerProvider.notifier).counts();
      expect(counts.isEmpty, isTrue);

      await tester.tap(find.text(_de.commonUndo));
      await pumpUntil(tester, () => !f.read(dataControllerProvider));
      counts = await f.data.read(dataControllerProvider.notifier).counts();
      expect(counts.shifts, 2);
      expect(counts.jobs, 1);
    });

    testWidgets('delete all: cancel keeps the data', (tester) async {
      final f = await _pump(tester);
      await tapVisible(tester, find.text(_de.dataDeleteAll));
      await settleData(tester);
      await tester.tap(find.text(_de.commonCancel));
      await settleData(tester);
      final counts = await f.data.read(dataControllerProvider.notifier).counts();
      expect(counts.shifts, 2);
    });

    testWidgets('delete all with nothing to delete', (tester) async {
      await _pump(tester, seed: (_) async {});
      await tapVisible(tester, find.text(_de.dataDeleteAll));
      await settleData(tester);
      _expectSnack(_de.dataNothingToDelete);
    });
  });

  group('about', () {
    testWidgets('version from the app info', (tester) async {
      await _pump(tester);
      await tester.scrollUntilVisible(find.text(_de.aboutVersion), 200);
      expect(find.text(_de.aboutVersionValue('2.0.0', '2')), findsOneWidget);
    });

    testWidgets('privacy policy page (German and English)', (tester) async {
      await _pump(tester);
      await tapVisible(tester, find.text(_de.aboutPrivacy));
      await settleData(tester);
      expect(find.byType(PrivacyPage), findsOneWidget);
      expect(find.text(_de.privacyShortTitle), findsOneWidget);
      expect(find.text(_de.privacyShortBody), findsOneWidget);
      expect(_de.privacyShortBody, contains('Internet-Berechtigung'));
      final en = l10nFor(const Locale('en'));
      expect(en.privacyShortBody, contains('no internet permission'));
      expect(en.privacyAutoBackupBody, contains('Google account'));
    });

    testWidgets('open-source licenses', (tester) async {
      await _pump(tester);
      await tapVisible(tester, find.text(_de.aboutLicenses));
      await tester.pumpAndSettle();
      expect(find.byType(LicensePage), findsOneWidget);
    });

    testWidgets('error report: empty log says so', (tester) async {
      final f = await _pump(tester);
      await tapVisible(tester, find.text(_de.aboutErrorReport));
      await pumpUntil(
        tester,
        () => find.byType(SnackBar).evaluate().isNotEmpty,
      );
      _expectSnack(_de.aboutErrorReportEmpty);
      expect(f.share.sharedFiles, isEmpty);
    });

    testWidgets('error report: shares the log as a text file', (tester) async {
      final f = await _pump(tester);
      await tester.runAsync(
        () => f.data.errorLog.record(StateError('boom'), StackTrace.current),
      );
      await tapVisible(tester, find.text(_de.aboutErrorReport));
      await pumpUntil(tester, () => f.share.sharedFiles.isNotEmpty);
      final shared = f.share.sharedFiles.single;
      expect(shared.mimeType, ShareMimeTypes.text);
      expect(shared.subject, _de.aboutErrorReportSubject);
      final text = (await tester.runAsync(
        () => File(shared.path).readAsString(),
      ))!;
      expect(text, startsWith('Chronos 2.0.0+2'));
      expect(text, contains('boom'));
    });
  });

  group('layout', () {
    for (final config in TestConfig.matrix()) {
      testWidgets('settings: $config', (tester) async {
        await _pump(tester, config: config);
        await scrollThrough(
          tester,
          within: find.byType(SettingsPage),
          context: config,
        );
      });
    }

    for (final config in TestConfig.matrix(
      sizes: [TestScreens.phoneSmall, TestScreens.landscapeSmall],
    )) {
      testWidgets('privacy + dialogs: $config', (tester) async {
        await pumpFeature(
          tester,
          const PrivacyPage(),
          config: config,
          seed: _seed,
        );
        await scrollThrough(
          tester,
          within: find.byType(PrivacyPage),
          context: config,
        );
        final context = tester.element(find.byType(PrivacyPage));
        for (final open in [
          () => showMonthlyGoalDialog(context),
          () => showReminderDialog(context),
          () => showDialog<void>(
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
        ]) {
          final future = open();
          await tester.pumpAndSettle();
          expectNoLayoutErrors(tester, config);
          Navigator.of(context).pop();
          await tester.pumpAndSettle();
          await future;
        }
      });
    }
  });

  group('accessibility', () {
    for (final brightness in Brightness.values) {
      testWidgets('settings meets guidelines (${brightness.name})', (
        tester,
      ) async {
        await _pump(
          tester,
          config: TestConfig(
            brightness: brightness,
            size: TestScreens.phoneLarge,
          ),
        );
        await expectMeetsAccessibilityGuidelines(tester);
        await scrollThrough(tester, within: find.byType(SettingsPage));
        await expectMeetsAccessibilityGuidelines(tester);
      });
    }
  });
}
