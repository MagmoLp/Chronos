import 'package:chronos/app/providers/providers.dart';
import 'package:chronos/app/theme/theme.dart';
import 'package:chronos/core/format.dart';
import 'package:chronos/core/local_date.dart';
import 'package:chronos/domain/job.dart';
import 'package:chronos/features/settings/job_editor_page.dart';
import 'package:chronos/features/settings/jobs_page.dart';
import 'package:chronos/features/settings/widgets/job_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/feature_harness.dart';
import '../insights/seed.dart';

final _de = l10nFor(const Locale('de'));
final _fmt = Fmt(const Locale('de'));

Future<FeatureHarness> _pumpJobs(
  WidgetTester tester, {
  Future<void> Function(ProviderHarness h)? seed,
  TestConfig config = const TestConfig(size: TestScreens.phoneLarge),
}) => pumpFeature(
  tester,
  const JobsPage(),
  config: config,
  seed: seed ?? (h) async => h.job(),
);

Future<List<Job>> _jobs(FeatureHarness f) =>
    f.data.read(jobRepositoryProvider).getJobs();

Future<void> _openEditor(WidgetTester tester, String name) async {
  await tester.tap(find.text(name));
  await settleData(tester);
  expect(find.byType(JobEditorPage), findsOneWidget);
}

Future<void> _save(WidgetTester tester) async {
  await tester.tap(find.text(_de.commonSave));
  await settleData(tester);
}

void main() {
  testWidgets('lists jobs with colour and current wage', (tester) async {
    await _pumpJobs(
      tester,
      seed: (h) async {
        final job = await h.job();
        await h
            .read(jobRepositoryProvider)
            .addRate(
              job.id,
              validFrom: LocalDate(2026, 7, 1),
              centsPerHour: 1600,
            );
        // A future raise does not count yet.
        await h
            .read(jobRepositoryProvider)
            .addRate(
              job.id,
              validFrom: LocalDate(2026, 12, 1),
              centsPerHour: 1700,
            );
      },
    );
    expect(find.text('Catering'), findsOneWidget);
    expect(
      find.text(_de.jobsRateSince(_fmt.rate(1600), '01.07.2026')),
      findsOneWidget,
    );
    expect(find.byType(JobColorDot), findsOneWidget);
    // One section only while nothing is archived.
    expect(find.text(_de.jobsArchivedSection), findsNothing);
  });

  testWidgets('create a job with wage, colour and rounding', (tester) async {
    final f = await _pumpJobs(tester);
    await tester.tap(find.text(_de.jobsAdd));
    await settleData(tester);
    expect(find.text(_de.jobsNewTitle), findsOneWidget);

    // Name and wage are required.
    await _save(tester);
    expect(find.text(_de.errorRequired), findsNWidgets(2));

    await tester.enterText(
      find.widgetWithText(TextFormField, _de.jobsName),
      'Bar am Hafen',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, _de.jobsRate),
      '12,5',
    );
    await tester.tap(find.bySemanticsLabel(_de.jobsColorTeal));
    await tester.tap(find.text(_fmt.minutes(15)));
    await tester.pumpAndSettle();
    await _save(tester);

    expect(find.byType(JobEditorPage), findsNothing);
    final bar = (await _jobs(f)).firstWhere((j) => j.name == 'Bar am Hafen');
    expect(bar.rounding, RoundingRule.nearest15);
    expect(bar.colorArgb, ChronosColors.light.jobPalette[1].toARGB32());
    final rates = await f.data.read(jobRepositoryProvider).getRates(bar.id);
    expect(rates.single.centsPerHour, 1250);
    expect(rates.single.validFrom, LocalDate(2026, 9, 30));
    expect(find.text('Bar am Hafen'), findsOneWidget);
    expect(
      find.text(_de.jobsRateSince(_fmt.rate(1250), '30.09.2026')),
      findsOneWidget,
    );
  });

  testWidgets('new job gets the first unused colour', (tester) async {
    await _pumpJobs(tester);
    await tester.tap(find.text(_de.jobsAdd));
    await settleData(tester);
    expect(
      tester.getSemantics(find.bySemanticsLabel(_de.jobsColorTeal)),
      isSemantics(isSelected: true, isButton: true),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel(_de.jobsColorBlue)),
      isSemantics(isSelected: false),
    );
  });

  testWidgets('edit name and rounding', (tester) async {
    final f = await _pumpJobs(tester);
    await _openEditor(tester, 'Catering');
    expect(find.text(_de.jobsEditTitle), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, _de.jobsName),
      'Catering Müller',
    );
    await tester.tap(find.text(_fmt.minutes(5)));
    await tester.pumpAndSettle();
    await _save(tester);
    final job = (await _jobs(f)).single;
    expect(job.name, 'Catering Müller');
    expect(job.rounding, RoundingRule.nearest5);
    expect(find.text('Catering Müller'), findsOneWidget);
  });

  testWidgets('leaving with unsaved changes asks first', (tester) async {
    final f = await _pumpJobs(tester);
    await _openEditor(tester, 'Catering');
    await tester.enterText(
      find.widgetWithText(TextFormField, _de.jobsName),
      'Anders',
    );
    await tester.pumpAndSettle();
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    await navigator.maybePop();
    await tester.pumpAndSettle();
    expect(find.text(_de.jobsDiscardTitle), findsOneWidget);
    await tester.tap(find.text(_de.commonCancel));
    await tester.pumpAndSettle();
    expect(find.byType(JobEditorPage), findsOneWidget);

    await navigator.maybePop();
    await tester.pumpAndSettle();
    await tester.tap(find.text(_de.commonDiscard));
    await settleData(tester);
    expect(find.byType(JobEditorPage), findsNothing);
    expect((await _jobs(f)).single.name, 'Catering');
  });

  group('wage history', () {
    testWidgets('new wage with recalculation changes open, not paid shifts', (
      tester,
    ) async {
      late int openId;
      late int paidId;
      final f = await _pumpJobs(
        tester,
        seed: (h) async {
          final job = await h.job();
          openId = (await addShift(h, job, LocalDate(2026, 9, 28))).id;
          paidId = (await addShift(
            h,
            job,
            LocalDate(2026, 9, 29),
            end: 12,
            paid: true,
          )).id;
        },
      );
      await _openEditor(tester, 'Catering');
      await tapVisible(tester, find.text(_de.jobsRateAdd));
      await tester.pumpAndSettle();
      expect(find.byType(RateDialog), findsOneWidget);

      await tester.enterText(
        find.descendant(
          of: find.byType(RateDialog),
          matching: find.byType(TextFormField),
        ),
        '20',
      );
      // Valid from 28 Sep (date picker).
      await tester.tap(find.byIcon(Icons.event_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text('28'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.text(_fmt.dateMedium(DateTime(2026, 9, 28))), findsOneWidget);
      await tester.tap(find.text(_de.jobsRateRecalc));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(RateDialog),
          matching: find.text(_de.commonSave),
        ),
      );
      await settleData(tester);

      expect(find.byType(RateDialog), findsNothing);
      expect(find.text(_de.jobsRateSaved(1)), findsOneWidget);
      final shifts = f.data.read(shiftRepositoryProvider);
      final open = await shifts.getById(openId);
      final paid = await shifts.getById(paidId);
      expect(open!.rateCentsPerHour, 2000);
      expect(open.earnedCents, 16000);
      expect(paid!.rateCentsPerHour, 1500);
      expect(paid.earnedCents, 6000);
      // History shows both, the new one as current.
      expect(find.text(_fmt.rate(2000)), findsOneWidget);
      expect(find.text(_fmt.rate(1500)), findsOneWidget);
      expect(find.text(_de.jobsRateCurrent), findsOneWidget);
    });

    testWidgets('new wage without recalculation keeps snapshots', (
      tester,
    ) async {
      late int openId;
      final f = await _pumpJobs(
        tester,
        seed: (h) async {
          final job = await h.job();
          openId = (await addShift(
            h,
            job,
            LocalDate(2026, 9, 30),
            start: 6,
          )).id;
        },
      );
      await _openEditor(tester, 'Catering');
      await tapVisible(tester, find.text(_de.jobsRateAdd));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byType(RateDialog),
          matching: find.byType(TextFormField),
        ),
        '18,00',
      );
      await tester.tap(
        find.descendant(
          of: find.byType(RateDialog),
          matching: find.text(_de.commonSave),
        ),
      );
      await settleData(tester);
      expect(find.text(_de.jobsRateSaved(0)), findsOneWidget);
      final open = await f.data.read(shiftRepositoryProvider).getById(openId);
      expect(open!.rateCentsPerHour, 1500);
    });

    testWidgets('delete a wage (not the last one) with undo', (tester) async {
      final f = await _pumpJobs(
        tester,
        seed: (h) async {
          final job = await h.job();
          await h
              .read(jobRepositoryProvider)
              .addRate(
                job.id,
                validFrom: LocalDate(2026, 7, 1),
                centsPerHour: 1600,
              );
        },
      );
      await _openEditor(tester, 'Catering');
      final delete = find.byTooltip(_de.jobsRateDelete);
      await tester.ensureVisible(delete.first);
      expect(delete, findsNWidgets(2));
      await tester.tap(delete.first);
      await settleData(tester);
      expect(find.text(_de.jobsRateDeleted), findsOneWidget);
      final jobId = (await _jobs(f)).single.id;
      var rates = await f.data.read(jobRepositoryProvider).getRates(jobId);
      expect(rates.single.centsPerHour, 1500);
      // The last wage cannot be deleted.
      expect(find.byTooltip(_de.jobsRateDelete), findsNothing);
      expect(find.text(_de.jobsRateDeleteLast), findsOneWidget);

      await tester.tap(find.text(_de.commonUndo));
      await settleData(tester);
      rates = await f.data.read(jobRepositoryProvider).getRates(jobId);
      expect(rates.map((r) => r.centsPerHour), [1600, 1500]);
    });
  });

  group('archive', () {
    testWidgets('the only active job cannot be archived', (tester) async {
      await _pumpJobs(tester);
      await _openEditor(tester, 'Catering');
      await tester.scrollUntilVisible(
        find.text(_de.jobsArchive),
        200,
        scrollable: topScrollable(),
      );
      final tile = tester.widget<ListTile>(
        find.ancestor(
          of: find.text(_de.jobsArchive),
          matching: find.byType(ListTile),
        ),
      );
      expect(tile.enabled, isFalse);
      expect(find.text(_de.jobsArchiveLastActive), findsOneWidget);
    });

    testWidgets('archive with undo, restore from the archived section', (
      tester,
    ) async {
      final f = await _pumpJobs(
        tester,
        seed: (h) async {
          await h.job();
          await h.job(name: 'Bar');
        },
      );
      await _openEditor(tester, 'Bar');
      await tapVisible(tester, find.text(_de.jobsArchive));
      await settleData(tester);
      expect(find.byType(JobEditorPage), findsNothing);
      expect(find.text(_de.jobsArchived('Bar')), findsOneWidget);
      expect(find.text(_de.jobsArchivedSection), findsOneWidget);
      expect(
        (await _jobs(f)).firstWhere((j) => j.name == 'Bar').archived,
        isTrue,
      );

      await tester.tap(find.text(_de.commonUndo));
      await settleData(tester);
      expect(
        (await _jobs(f)).firstWhere((j) => j.name == 'Bar').archived,
        isFalse,
      );
      expect(find.text(_de.jobsArchivedSection), findsNothing);

      // Archive again and restore through the editor.
      await _openEditor(tester, 'Bar');
      await tapVisible(tester, find.text(_de.jobsArchive));
      await settleData(tester);
      await tester.pump(const Duration(seconds: 10));
      await tester.pumpAndSettle();
      await _openEditor(tester, 'Bar');
      await tapVisible(tester, find.text(_de.jobsUnarchive));
      await settleData(tester);
      expect(find.text(_de.jobsUnarchived('Bar')), findsOneWidget);
      expect(
        (await _jobs(f)).firstWhere((j) => j.name == 'Bar').archived,
        isFalse,
      );
    });
  });

  group('layout', () {
    Future<void> seed(ProviderHarness h) async {
      final job = await h.job(name: 'Catering Müller & Söhne Eventservice');
      await h
          .read(jobRepositoryProvider)
          .addRate(
            job.id,
            validFrom: LocalDate(2026, 7, 1),
            centsPerHour: 1600,
          );
      final old = await h.job(name: 'Alter Job');
      await h.job(name: 'Bar');
      await h.read(jobRepositoryProvider).setArchived(old.id, true);
    }

    for (final config in TestConfig.matrix()) {
      testWidgets('jobs list and editor: $config', (tester) async {
        await _pumpJobs(tester, config: config, seed: seed);
        await scrollThrough(
          tester,
          within: find.byType(JobsPage),
          context: config,
        );
        await tapVisible(
          tester,
          find.text('Catering Müller & Söhne Eventservice'),
          delta: -200,
        );
        await settleData(tester);
        await scrollThrough(
          tester,
          within: find.byType(JobEditorPage),
          context: config,
        );
        await tapVisible(
          tester,
          find.text(l10nFor(config.locale).jobsRateAdd),
          delta: -200,
        );
        await tester.pumpAndSettle();
        expectNoLayoutErrors(tester, config);
        expect(find.byType(RateDialog), findsOneWidget);
      });
    }

    for (final config in TestConfig.matrix(
      sizes: [TestScreens.phoneSmall, TestScreens.landscapeSmall],
    )) {
      testWidgets('new job editor: $config', (tester) async {
        await pumpFeature(
          tester,
          const JobEditorPage(),
          config: config,
          seed: (h) async => h.job(),
        );
        await scrollThrough(
          tester,
          within: find.byType(JobEditorPage),
          context: config,
        );
      });
    }
  });

  group('accessibility', () {
    for (final brightness in Brightness.values) {
      testWidgets('jobs and editor meet guidelines (${brightness.name})', (
        tester,
      ) async {
        await _pumpJobs(
          tester,
          config: TestConfig(
            brightness: brightness,
            size: TestScreens.phoneLarge,
          ),
          seed: (h) async {
            await h.job();
            await h.job(name: 'Bar');
          },
        );
        await expectMeetsAccessibilityGuidelines(tester);
        await _openEditor(tester, 'Catering');
        await expectMeetsAccessibilityGuidelines(tester);
      });
    }
  });

  test('stored colours map to the theme palette', () {
    for (var i = 0; i < ChronosColors.jobColorCount; i++) {
      expect(JobColors.indexOf(JobColors.argbFor(i)), i);
    }
    expect(JobColors.indexOf(kDefaultJobColorArgb), 0);
    expect(JobColors.indexOf(0xFF123456), isNull);
  });
}
