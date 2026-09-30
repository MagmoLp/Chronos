import 'dart:async';

import 'package:chronos/app/providers/providers.dart';
import 'package:chronos/app/shell.dart';
import 'package:chronos/app/startup/home_shell.dart';
import 'package:chronos/app/startup/splash_screen.dart';
import 'package:chronos/app/startup/startup_gate.dart';
import 'package:chronos/app/startup/wage_check_page.dart';
import 'package:chronos/app/theme/theme.dart';
import 'package:chronos/data/legacy/legacy_models.dart';
import 'package:chronos/features/onboarding/onboarding_page.dart';
import 'package:chronos/features/recovery/recovery_screen.dart';
import 'package:chronos/features/review/review_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fixtures/legacy_v1.dart';
import 'app_harness.dart';

final LegacyRawData legacyGerman = LegacyRawData(
  workEntries: LegacyV1.workEntries,
  appSettings: LegacyV1.settingsGerman,
  activeSession: LegacyV1.activeSession,
);

final LegacyRawData legacy1250 = LegacyRawData(
  workEntries: LegacyV1.workEntries,
  appSettings: LegacyV1.settings1250,
);

Future<AppHarness> _pumpGate(
  WidgetTester tester, {
  Future<void> Function(AppHarness h)? seed,
  LegacyRawData legacy = const LegacyRawData(),
  TestConfig config = const TestConfig(),
}) async {
  final h = AppHarness(legacy: legacy);
  if (seed != null) await seed(h);
  await pumpOnHarness(tester, h, const StartupGate(), config: config);
  return h;
}

int _selectedTab(WidgetTester tester) =>
    tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex;

void main() {
  group('StartupGate', () {
    testWidgets('shows the calm splash while the start sequence runs', (
      tester,
    ) async {
      final pending = Completer<BootstrapResult>();
      final h = AppHarness(
        overrides: [bootstrapProvider.overrideWith((ref) => pending.future)],
      );
      await pumpOnHarness(tester, h, const StartupGate(), settle: false);
      await tester.pump();
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.bySemanticsLabel('Chronos startet …'), findsOneWidget);
      // No spinner for a quick start …
      expect(find.byType(LinearProgressIndicator), findsNothing);
      // … only when it takes noticeably long.
      await tester.pump(SplashScreen.progressDelay);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      final material = tester.widget<Material>(
        find
            .descendant(
              of: find.byType(SplashScreen),
              matching: find.byType(Material),
            )
            .first,
      );
      // Same colour as the Android splash (#F6F9FC).
      expect(material.color, ChronosTheme.light.colorScheme.surface);
      expect(material.color, ChronosBrand.splashDay);
    });

    testWidgets('a failed start shows recovery; retry runs it again', (
      tester,
    ) async {
      final h = await _pumpGate(
        tester,
        seed: (h) async => h.legacySource.fail = true,
      );
      expect(find.byType(RecoveryScreen), findsOneWidget);
      expect(find.text('Chronos konnte nicht starten'), findsOneWidget);
      expect(await h.errorLog.read(), contains('bootstrap'));

      h.legacySource.fail = false;
      await tester.tap(find.text('Erneut versuchen'));
      await settleApp(tester);
      expect(find.byType(RecoveryScreen), findsNothing);
      expect(find.byType(OnboardingPage), findsOneWidget);
    });

    testWidgets('without data: onboarding → job created → shell', (
      tester,
    ) async {
      final h = await _pumpGate(tester);
      expect(find.byType(OnboardingPage), findsOneWidget);

      await tester.tap(find.text('Los geht’s'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Stundenlohn'),
        '13,90',
      );
      await tester.tap(find.text('Fertig'));
      await settleApp(tester);

      expect(find.byType(OnboardingPage), findsNothing);
      expect(find.byType(HomeShell), findsOneWidget);
      final jobs = await h.read(jobRepositoryProvider).getJobs();
      expect(jobs.single.name, 'Mein Job');
      expect(h.read(settingsProvider).onboardingDone, isTrue);
    });

    testWidgets('with an active job: the shell with three tabs', (
      tester,
    ) async {
      await _pumpGate(tester, seed: (h) => h.job());
      expect(find.byType(AdaptiveShell), findsOneWidget);
      expect(find.byType(NavigationDestination), findsNWidgets(3));
      for (final label in ['Heute', 'Schichten', 'Übersicht']) {
        expect(find.text(label), findsOneWidget);
      }
      expect(find.byType(OnboardingPage), findsNothing);
      expect(find.byType(WageCheckPage), findsNothing);
      expect(find.byType(SplashScreen), findsNothing);
    });

    testWidgets('when all jobs are gone (data wiped) onboarding comes back', (
      tester,
    ) async {
      final h = await _pumpGate(tester, seed: (h) => h.job());
      expect(find.byType(HomeShell), findsOneWidget);

      // What "Alle Daten löschen" leaves behind: no jobs at all.
      await h.db.delete(h.db.wageRates).go();
      await h.db.delete(h.db.jobs).go();
      await settleApp(tester);
      expect(find.byType(HomeShell), findsNothing);
      expect(find.byType(OnboardingPage), findsOneWidget);
    });
  });

  group('v1 migration', () {
    testWidgets('1250 €/h asks once; the suggested fix updates everything', (
      tester,
    ) async {
      final h = await _pumpGate(tester, legacy: legacy1250);
      expect(find.byType(WageCheckPage), findsOneWidget);
      expect(
        find.text('1.250,00\u00A0€/h übernommen – stimmt das?'),
        findsOneWidget,
      );
      // Prefilled with the likely intended wage.
      expect(find.widgetWithText(TextFormField, '12,50'), findsOneWidget);

      await tester.tap(find.text('Diesen Lohn verwenden'));
      await settleApp(tester);

      expect(find.byType(WageCheckPage), findsNothing);
      expect(find.byType(HomeShell), findsOneWidget);
      expect(find.textContaining('Stundenlohn korrigiert'), findsOneWidget);
      final shifts = await h.shiftRows();
      expect(shifts, hasLength(LegacyV1.importable));
      expect(shifts.every((s) => s.rateCentsPerHour == 1250), isTrue);
      expect(await h.read(pendingWageCheckProvider.future), isNull);
    });

    testWidgets('a typed correction is used (dot as separator)', (
      tester,
    ) async {
      final h = await _pumpGate(tester, legacy: legacy1250);
      await tester.enterText(find.byType(TextFormField), '13.5');
      await tester.tap(find.text('Diesen Lohn verwenden'));
      await settleApp(tester);
      expect(find.byType(HomeShell), findsOneWidget);
      final shifts = await h.shiftRows();
      expect(shifts.every((s) => s.rateCentsPerHour == 1350), isTrue);
    });

    testWidgets('keeping the wage confirms it', (tester) async {
      final h = await _pumpGate(tester, legacy: legacy1250);
      final keep = find.textContaining('beibehalten');
      await tester.ensureVisible(keep);
      await tester.tap(keep);
      await settleApp(tester);
      expect(find.byType(HomeShell), findsOneWidget);
      final shifts = await h.shiftRows();
      expect(shifts.every((s) => s.rateCentsPerHour == 125000), isTrue);
      expect(await h.read(pendingWageCheckProvider.future), isNull);
    });

    testWidgets('an empty correction is refused', (tester) async {
      await _pumpGate(tester, legacy: legacy1250);
      await tester.enterText(find.byType(TextFormField), '');
      await tester.tap(find.text('Diesen Lohn verwenden'));
      await settleApp(tester);
      expect(find.byType(WageCheckPage), findsOneWidget);
      expect(find.text('Bitte gib einen Wert ein'), findsOneWidget);
    });

    testWidgets('v1 data end to end: shifts, running shift, review hint', (
      tester,
    ) async {
      final h = await _pumpGate(tester, legacy: legacyGerman);
      // No onboarding, no wage question (15 €/h is plausible).
      expect(find.byType(OnboardingPage), findsNothing);
      expect(find.byType(WageCheckPage), findsNothing);
      expect(find.byType(HomeShell), findsOneWidget);

      expect(await h.doneRows(), hasLength(LegacyV1.importable));
      expect(await h.read(shiftRepositoryProvider).getRunning(), isNotNull);
      final jobs = await h.read(jobRepositoryProvider).getJobs();
      expect(jobs.single.name, 'Mein Job');
      // The running v1 session got its notification.
      expect(h.notifications.posted, isNotEmpty);

      // One-time notice with a way to the review list.
      expect(
        find.text('${LegacyV1.importable} Einträge aus Chronos 1 übernommen'),
        findsOneWidget,
      );
      await tester.tap(find.text('Prüfen'));
      await settleApp(tester);
      expect(find.byType(ReviewPage), findsOneWidget);
      expect(find.text('Einträge prüfen'), findsOneWidget);
      expect(find.text('Passt so'), findsWidgets);
    });

    testWidgets('the notice is shown only once per session', (tester) async {
      final h = await _pumpGate(tester, legacy: legacyGerman);
      expect(find.textContaining('übernommen'), findsOneWidget);
      expect(h.read(migrationNoticeProvider), isTrue);
      expect(h.read(migrationNoticeProvider.notifier).claim(), isFalse);
    });
  });

  group('app requests', () {
    for (final kind in AppRequestKind.values) {
      testWidgets('${kind.name} brings Today to the front', (tester) async {
        final h = await _pumpGate(tester, seed: (h) => h.job());
        await tester.tap(find.text('Schichten'));
        await tester.pumpAndSettle();
        expect(_selectedTab(tester), ShellTab.shifts.index);

        h.read(appRequestProvider.notifier).request(kind);
        await tester.pumpAndSettle();
        expect(_selectedTab(tester), ShellTab.today.index);
        // Today consumes the finish-sheet request itself.
        final pending = h.read(appRequestProvider);
        if (kind == AppRequestKind.showToday) {
          expect(pending, isNull);
        } else {
          expect(pending?.kind, AppRequestKind.openFinishSheet);
        }
      });
    }

    testWidgets('a request posted before the shell exists is handled', (
      tester,
    ) async {
      final h = await _pumpGate(tester, legacy: legacy1250);
      expect(find.byType(WageCheckPage), findsOneWidget);
      h.read(appRequestProvider.notifier).request(AppRequestKind.showToday);
      await tester.pump();
      await tester.tap(find.text('Diesen Lohn verwenden'));
      await settleApp(tester);
      expect(find.byType(HomeShell), findsOneWidget);
      expect(h.read(appRequestProvider), isNull);
    });

    testWidgets('routes above the shell are closed', (tester) async {
      final h = await _pumpGate(tester, seed: (h) => h.job());
      unawaited(openReviewPage(tester.element(find.byType(HomeShell))));
      await tester.pumpAndSettle();
      expect(find.byType(ReviewPage), findsOneWidget);

      h.read(appRequestProvider.notifier).request(AppRequestKind.showToday);
      await tester.pumpAndSettle();
      expect(find.byType(ReviewPage), findsNothing);
    });
  });
}
