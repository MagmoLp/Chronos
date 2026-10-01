// Acceptance checks for spec items (docs/SPEC_2_0.md) and v1 bugs
// (docs/UMBAUPLAN.md §2.2) that no other test pinned down.

import 'package:chronos/app/providers/providers.dart';
import 'package:chronos/core/local_date.dart';
import 'package:chronos/data/job_repository.dart';
import 'package:chronos/data/legacy/legacy_migration.dart';
import 'package:chronos/data/legacy/legacy_models.dart';
import 'package:chronos/data/shift_repository.dart';
import 'package:chronos/domain/shift.dart';
import 'package:chronos/domain/shift_draft.dart';
import 'package:chronos/features/settings/settings_page.dart';
import 'package:chronos/features/shifts/shift_actions.dart';
import 'package:chronos/features/shifts/shift_editor.dart';
import 'package:chronos/features/shifts/shifts_page.dart';
import 'package:chronos/features/today/today_page.dart';
import 'package:chronos/widgets/rolling_amount.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app/startup/app_harness.dart' as app;
import '../features/insights/seed.dart' show pumpUntil, tapVisible;
import '../features/today/today_test_support.dart';
import '../fixtures/db.dart';
import '../fixtures/legacy_v1.dart';
import '../fixtures/shifts.dart' show local;
import '../fixtures/test_clock.dart';

final _de = l10nFor(const Locale('de'));
final _en = l10nFor(const Locale('en'));

class _Source implements LegacySource {
  _Source(this.data);

  final LegacyRawData data;

  @override
  Future<LegacyRawData> read() async => data;
}

void main() {
  group('v1 data', () {
    test(
      'the old shared_preferences keys are read but never deleted',
      () async {
        final v1 = <String, Object>{
          SharedPreferencesLegacySource.keyWorkEntries: LegacyV1.workEntries,
          SharedPreferencesLegacySource.keyAppSettings: LegacyV1.settingsGerman,
          SharedPreferencesLegacySource.keyActiveSession:
              LegacyV1.activeSession,
        };
        SharedPreferences.setMockInitialValues(v1);
        final db = memoryDb();
        final report = await LegacyMigrator(
          db: db,
          source: const SharedPreferencesLegacySource(),
          backupDirectory: () async => tempDir(),
          clock: TestClock(local(2026, 9, 30, 12)).clock,
        ).run(defaultJobName: 'Mein Job');
        expect(report.migrated, isTrue);
        expect(report.importedCount, LegacyV1.importable);

        final prefs = await SharedPreferences.getInstance();
        await prefs.reload();
        for (final entry in v1.entries) {
          expect(prefs.get(entry.key), entry.value, reason: entry.key);
        }
      },
    );

    test('D12: duplicate v1 ids stay separate shifts; a deleted shift '
        'is not brought back by "paid"', () async {
      final db = memoryDb();
      final clock = TestClock(local(2026, 9, 30, 12));
      await LegacyMigrator(
        db: db,
        source: _Source(
          LegacyRawData(
            workEntries: LegacyV1.workEntries,
            appSettings: LegacyV1.settingsGerman,
          ),
        ),
        backupDirectory: () async => tempDir(),
        clock: clock.clock,
      ).run(defaultJobName: 'Mein Job');
      final jobs = JobRepository(db, clock: clock.clock);
      final shifts = ShiftRepository(db, clock: clock.clock, jobs: jobs);

      // v1 entries 0 and 6 share one id; v1 let one overwrite the other.
      final twins = [
        for (final s in await shifts.getDone())
          if (s.legacyId == LegacyV1.timerId) s,
      ];
      expect(twins, hasLength(2));
      final [a, b] = twins;
      expect(a.id, isNot(b.id));
      expect(a.isPaid, isFalse);
      expect(b.isPaid, isFalse);

      await shifts.setPaid([a.id], true);
      expect((await shifts.getById(a.id))!.isPaid, isTrue);
      expect((await shifts.getById(b.id))!.isPaid, isFalse);

      // Zombie row: marking a just-deleted shift paid must not revive it.
      await shifts.softDelete([b.id]);
      expect(await shifts.setPaid([b.id], true), isEmpty);
      final deleted = (await shifts.getById(b.id))!;
      expect(deleted.isDeleted, isTrue);
      expect(deleted.isPaid, isFalse);
      expect((await shifts.getDone()).map((s) => s.id), isNot(contains(b.id)));
    });
  });

  testWidgets('2.2a: a failed list action is reported, not swallowed, and '
      'does not revive a deleted shift', (tester) async {
    late Shift shift;
    final f = await pumpFeature(
      tester,
      const ShiftsPage(),
      config: const TestConfig(size: TestScreens.phoneLarge),
      seed: (h) async {
        shift = await TodaySeed.done(
          h,
          await TodaySeed.job(h),
          startAgo: const Duration(days: 1, hours: 8),
          endAgo: const Duration(days: 1),
        );
      },
    );
    // Deleted elsewhere (e.g. "Verwerfen" in another place) while the row
    // was still on screen; then "mark paid" arrives for it.
    final context = tester.element(find.byKey(ValueKey<int>(shift.id)));
    await f.read(shiftRepositoryProvider).softDelete([shift.id]);
    await togglePaidWithUndo(context, shift.id);
    await settleData(tester);
    expect(find.text(_de.shiftsErrorNotFound), findsOneWidget);
    final stored = (await f.read(shiftRepositoryProvider).getById(shift.id))!;
    expect(stored.isDeleted, isTrue);
    expect(stored.isPaid, isFalse);
    expect(find.byKey(ValueKey<int>(shift.id)), findsNothing);
  });

  test('the reminder is re-planned when the start changes', () async {
    final h = app.AppHarness();
    await h.read(settingsRepositoryProvider.future);
    final job = await h.job();
    final active = h.read(activeShiftControllerProvider.notifier);
    await active.start(job.id);
    expect(
      h.notifications.scheduled.last.at,
      app.kAppNow.add(const Duration(hours: 10)),
    );
    final earlier = app.kAppNow.subtract(const Duration(hours: 1));
    await active.adjustStart(earlier);
    expect(h.notifications.scheduled, hasLength(2));
    expect(
      h.notifications.scheduled.last.at,
      earlier.add(const Duration(hours: 10)),
    );
    await active.finish();
    expect(h.notifications.remindersCancelled, greaterThan(0));
  });

  testWidgets('K1: "Delete all data" works in English', (tester) async {
    final f = await pumpFeature(
      tester,
      const SettingsPage(),
      config: const TestConfig(
        size: TestScreens.phoneLarge,
        locale: Locale('en'),
      ),
      seed: (h) async {
        final job = await TodaySeed.job(h);
        await TodaySeed.done(
          h,
          job,
          startAgo: const Duration(days: 1, hours: 8),
          endAgo: const Duration(days: 1),
        );
      },
    );
    await tapVisible(tester, find.text(_en.dataDeleteAll));
    await settleData(tester);
    // No typed confirmation word: a dialog with the counts, in English.
    expect(find.text('Delete 1 shift and 1 job?'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    await tester.tap(find.text(_en.commonDelete));
    await pumpUntil(tester, () => !f.read(dataControllerProvider));
    await pumpUntil(tester, () => find.byType(SnackBar).evaluate().isNotEmpty);
    expect(find.text(_en.dataDeleted), findsOneWidget);
    expect(find.text(_de.dataDeleted), findsNothing);
    final counts = await f.read(dataControllerProvider.notifier).counts();
    expect(counts.isEmpty, isTrue);
  });

  testWidgets('v1 "date picker ends 2029": shifts can be added in 2030', (
    tester,
  ) async {
    final f = await pumpFeature(
      tester,
      const ShiftsPage(),
      now: DateTime(2030, 1, 15, 20).toUtc(),
      config: const TestConfig(size: TestScreens.phoneLarge),
      seed: (h) => h.job(),
    );
    await tester.tap(find.text(_de.shiftsAddPastShift));
    await settleData(tester);
    expect(find.byKey(ShiftEditorKeys.editor), findsOneWidget);

    await tapVisible(tester, find.byKey(ShiftEditorKeys.date));
    await settleData(tester);
    await tester.tap(find.text('14'));
    await tester.tap(find.text('OK'));
    await settleData(tester);
    await tapVisible(tester, find.byKey(ShiftEditorKeys.save));
    await settleData(tester);

    final saved = (await f.read(shiftRepositoryProvider).getDone()).single;
    expect(saved.localStartDate, LocalDate(2030, 1, 14));
    expect(saved.amountCents, 12000);
  });

  testWidgets('Today: "Pause" is tonal, "Beenden" is the primary button', (
    tester,
  ) async {
    await pumpFeature(
      tester,
      TodayPage(navigation: RecordingNavigation()),
      seed: (h) async => TodaySeed.running(h, await TodaySeed.job(h)),
    );
    final scheme = Theme.of(tester.element(find.byType(TodayPage))).colorScheme;
    Color? background(String label) => tester
        .widget<Material>(
          find
              .descendant(
                of: find.ancestor(
                  of: find.text(label),
                  matching: find.byWidgetPredicate((w) => w is FilledButton),
                ),
                matching: find.byType(Material),
              )
              .first,
        )
        .color;
    expect(background(_de.todayPause), scheme.secondaryContainer);
    expect(background(_de.todayFinish), scheme.primary);
  });

  group('full app', () {
    testWidgets('v1 "tab switch loses the scroll position": Schichten keeps '
        'it', (tester) async {
      tester.platformDispatcher.localesTestValue = const [Locale('de', 'DE')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      final h = app.AppHarness();
      final job = await h.job();
      for (var day = 1; day <= 40; day++) {
        await h
            .read(shiftRepositoryProvider)
            .insertManual(
              ShiftDraft.fromLocal(
                jobId: job.id,
                date: LocalDate(2026, 9, 29).addDays(-day),
                startHour: 8,
                startMinute: 0,
                endHour: 16,
                endMinute: 0,
              ),
            );
      }
      await app.pumpChronosApp(tester, h);
      Finder tab(String label) => find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(label),
      );
      ScrollPosition position() => tester
          .state<ScrollableState>(
            find
                .descendant(
                  of: find.byType(ShiftsPage),
                  matching: find.byType(Scrollable),
                )
                .first,
          )
          .position;

      await tester.tap(tab(_de.navShifts));
      await app.settleApp(tester);
      await tester.drag(find.byType(ShiftsPage), const Offset(0, -900));
      await app.settleApp(tester);
      final scrolled = position().pixels;
      expect(scrolled, greaterThan(0));

      await tester.tap(tab(_de.navToday));
      await app.settleApp(tester);
      await tester.tap(tab(_de.navShifts));
      await app.settleApp(tester);
      expect(position().pixels, scrolled);
    });

    testWidgets('every destination has the settings gear', (tester) async {
      tester.platformDispatcher.localesTestValue = const [Locale('de', 'DE')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      final h = app.AppHarness();
      await h.job();
      await app.pumpChronosApp(tester, h);
      for (final tab in [_de.navToday, _de.navShifts, _de.navInsights]) {
        await tester.tap(
          find.descendant(
            of: find.byType(NavigationBar),
            matching: find.text(tab),
          ),
        );
        await app.settleApp(tester);
        final gear = find.byTooltip(_de.commonSettings);
        expect(gear, findsOneWidget, reason: tab);
        await tester.tap(gear);
        await app.settleApp(tester);
        expect(find.byType(SettingsPage), findsOneWidget, reason: tab);
        await tester.tap(find.byType(BackButton));
        await app.settleApp(tester);
        expect(find.byType(SettingsPage), findsNothing);
      }
    });

    testWidgets('v1 "00:00:00 after a restart": a running shift shows its '
        'time and pay from the first frame', (tester) async {
      tester.platformDispatcher.localesTestValue = const [Locale('de', 'DE')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      final h = app.AppHarness();
      final job = await h.job();
      await h
          .read(shiftRepositoryProvider)
          .start(
            job.id,
            startUtc: app.kAppNow.subtract(const Duration(hours: 3)),
          );
      await app.pumpChronosApp(tester, h, settle: false);

      final worked = find.byKey(const ValueKey<String>('today-worked'));
      var shown = false;
      for (var frame = 0; frame < 120; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        // The balance card ("Offen") must not flash before the running one.
        expect(find.text(_de.todayOpenLabel), findsNothing);
        if (worked.evaluate().isEmpty) continue;
        shown = true;
        expect(tester.widget<Text>(worked).data, '3:00:00', reason: '$frame');
        expect(
          tester.widget<RollingAmount>(find.byType(RollingAmount).first).cents,
          4500,
          reason: '$frame',
        );
      }
      expect(shown, isTrue);
      expect(find.text(_de.statusRunning), findsOneWidget);
      // The shift was not touched by the restart.
      expect(
        (await h.read(shiftRepositoryProvider).getRunning())!.status,
        ShiftStatus.running,
      );
    });
  });
}
