import 'package:chronos/app/providers/providers.dart';
import 'package:chronos/core/local_date.dart';
import 'package:chronos/core/time.dart';
import 'package:chronos/domain/job.dart';
import 'package:chronos/domain/shift.dart';
import 'package:chronos/features/today/finish_shift_sheet.dart';
import 'package:chronos/features/today/notification_primer.dart';
import 'package:chronos/features/today/time_dialog.dart';
import 'package:chronos/features/today/today_actions.dart';
import 'package:chronos/features/today/today_hero.dart';
import 'package:chronos/features/today/today_page.dart';
import 'package:chronos/features/today/today_summaries.dart';
import 'package:chronos/l10n/app_localizations.dart';
import 'package:chronos/widgets/live_ticker.dart';
import 'package:chronos/widgets/rolling_amount.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'today_test_support.dart';

final AppLocalizations l10n = l10nFor(const Locale('de'));
final fmt = fmtFor(const Locale('de'));

/// Pumps Today (German, 360×640) with a recording navigation.
///
/// [notificationsEnabled] / [grantOnRequest] configure the fake notification
/// service before the first frame.
Future<(FeatureHarness, RecordingNavigation)> pumpToday(
  WidgetTester tester, {
  Future<void> Function(ProviderHarness h)? seed,
  TestConfig config = const TestConfig(),
  bool notificationsEnabled = true,
  bool grantOnRequest = true,
}) async {
  final nav = RecordingNavigation();
  final f = await pumpFeature(
    tester,
    TodayPage(navigation: nav),
    config: config,
    seed: (h) async {
      notificationsOf(h)
        ..enabled = notificationsEnabled
        ..grantOnRequest = grantOnRequest;
      await seed?.call(h);
    },
  );
  return (f, nav);
}

/// Scrolls the sheet's Save button into view and taps it.
Future<void> tapSave(WidgetTester tester) async {
  await tester.ensureVisible(find.text(l10n.commonSave));
  await tester.tap(find.text(l10n.commonSave));
  await settleData(tester);
}

Future<Shift?> running(FeatureHarness f) =>
    f.read(shiftRepositoryProvider).getRunning();

/// The hero amount in cents (RollingAmount inside the hero card).
int heroCents(WidgetTester tester) =>
    tester.widget<RollingAmount>(find.byType(RollingAmount).first).cents!;

String worked(WidgetTester tester) =>
    textOf(tester, const ValueKey<String>('today-worked'));

/// Types [time] into the time dialog and confirms.
Future<void> enterTime(WidgetTester tester, ClockTimeLike time) async {
  final field = find.descendant(
    of: find.byType(TodayTimeDialog),
    matching: find.byType(TextField),
  );
  await tester.enterText(field, fmt.clockTime(time));
  await tester.tap(find.text(l10n.commonOk));
  await settleData(tester);
}

typedef ClockTimeLike = ({int hour, int minute});

ClockTimeLike localTimeOf(DateTime utc) {
  final l = utc.toLocal();
  return (hour: l.hour, minute: l.minute);
}

void main() {
  group('hero card', () {
    testWidgets('idle without work: unpaid balance and "record payout"', (
      tester,
    ) async {
      final (_, nav) = await pumpToday(
        tester,
        seed: (h) async {
          final job = await TodaySeed.job(h);
          await TodaySeed.done(
            h,
            job,
            startAgo: const Duration(days: 2, hours: 8),
            endAgo: const Duration(days: 2, hours: 2),
          );
          await TodaySeed.done(
            h,
            job,
            startAgo: const Duration(days: 3, hours: 8),
            endAgo: const Duration(days: 3, hours: 6),
            paid: true,
          );
        },
      );
      expect(find.text(fmt.todayTitle(kFeatureNow.toLocal())), findsOneWidget);
      expect(find.text(l10n.todayOpenLabel), findsOneWidget);
      expect(heroCents(tester), 9000);
      expect(
        find.text(l10n.todayShiftsHours(1, fmt.hours(6 * msPerHour))),
        findsOneWidget,
      );
      // The balance is the hero, so no extra "Offen gesamt" line.
      expect(find.text(l10n.todayOpenTotal), findsNothing);
      expect(find.text(l10n.todayStartShift), findsOneWidget);

      await tester.tap(find.text(l10n.todayRecordPayout));
      await tester.pump();
      expect(nav.calls, ['payout']);
    });

    testWidgets('nothing open: no payout button', (tester) async {
      await pumpToday(tester, seed: (h) => TodaySeed.job(h));
      expect(find.text(l10n.todayOpenLabel), findsOneWidget);
      expect(heroCents(tester), 0);
      expect(find.text(l10n.todayNothingOpen), findsOneWidget);
      expect(find.text(l10n.todayRecordPayout), findsNothing);
    });

    testWidgets('idle with work today: static "earned today" + open total', (
      tester,
    ) async {
      await pumpToday(
        tester,
        seed: (h) async {
          final job = await TodaySeed.job(h);
          await TodaySeed.done(
            h,
            job,
            startAgo: const Duration(hours: 7),
            endAgo: const Duration(hours: 4),
            breakMinutes: 30,
          );
          await TodaySeed.done(
            h,
            job,
            startAgo: const Duration(days: 1, hours: 8),
            endAgo: const Duration(days: 1, hours: 6),
          );
        },
      );
      expect(find.text(l10n.todayEarnedToday), findsOneWidget);
      expect(heroCents(tester), 3750);
      expect(find.text(l10n.todayShiftsHours(1, '2:30 h')), findsOneWidget);
      expect(find.text(l10n.todayOpenTotal), findsOneWidget);
      expect(find.text(fmt.money(6750)), findsOneWidget);
      expect(find.text(l10n.todayThisShift), findsNothing);
    });

    testWidgets('running: live amount per cent and clock per second', (
      tester,
    ) async {
      final (f, _) = await pumpToday(
        tester,
        seed: (h) async {
          final job = await TodaySeed.job(h);
          await TodaySeed.done(
            h,
            job,
            startAgo: const Duration(hours: 7),
            endAgo: const Duration(hours: 5),
          );
          await TodaySeed.running(h, job);
        },
      );
      final start = f.data.clock.now.subtract(const Duration(hours: 2));
      expect(find.text(l10n.statusRunning), findsOneWidget);
      expect(find.text(l10n.todayEarnedToday), findsOneWidget);
      expect(heroCents(tester), 6000);
      expect(worked(tester), '2:00:00');
      expect(
        find.text(l10n.todaySince(fmt.time(start.toLocal()))),
        findsOneWidget,
      );
      expect(find.text(fmt.rate(1500)), findsOneWidget);
      expect(find.text(l10n.todayOpenTotal), findsOneWidget);
      expect(find.text(l10n.todayThisShift), findsOneWidget);
      expect(find.text(fmt.money(3000)), findsOneWidget);

      // One second later only the clock has moved.
      f.data.clock.advance(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(worked(tester), '2:00:01');
      expect(heroCents(tester), 6000);

      // The next cent (at 15 €/h: 1.2 s after 2:00:00, half-up) shows up.
      f.data.clock.advance(const Duration(milliseconds: 250));
      await tester.pump(const Duration(milliseconds: 300));
      expect(heroCents(tester), 6001);

      f.data.clock.advance(const Duration(minutes: 10));
      await tester.pump(const Duration(seconds: 3));
      expect(heroCents(tester), 6251);
      expect(worked(tester), '2:10:01');
      expect(find.text(fmt.money(3251)), findsOneWidget);
      expect(find.text(fmt.money(6251)), findsOneWidget);
    });

    testWidgets('high wages update the amount at most 4× per second', (
      tester,
    ) async {
      final (f, _) = await pumpToday(
        tester,
        seed: (h) async =>
            TodaySeed.running(h, await TodaySeed.job(h, centsPerHour: 100000)),
      );
      // 1.000 €/h: a new cent every 36 ms.
      var last = heroCents(tester);
      var changes = 0;
      for (var i = 0; i < 40; i++) {
        f.data.clock.advance(const Duration(milliseconds: 25));
        await tester.pump(const Duration(milliseconds: 25));
        final now = heroCents(tester);
        if (now != last) {
          changes++;
          last = now;
        }
      }
      // Throttled to one update per 250 ms (instead of ~28 per second).
      expect(changes, inInclusiveRange(3, 4));
      expect(last, greaterThan(200000 + 18));
    });

    testWidgets('ticks rebuild only the live numbers', (tester) async {
      final (f, _) = await pumpToday(tester, seed: TodayScenarios.running);
      final rebuilt = <Type>{};
      debugOnRebuildDirtyWidget = (element, _) =>
          rebuilt.add(element.widget.runtimeType);
      addTearDown(() => debugOnRebuildDirtyWidget = null);

      for (var i = 0; i < 3; i++) {
        f.data.clock.advance(const Duration(seconds: 1));
        await tester.pump(const Duration(seconds: 1));
      }
      expect(rebuilt, contains(LiveTicker));
      expect(rebuilt, contains(RollingAmount));
      for (final type in <Type>[
        TodayPage,
        TodayHeroCard,
        TodayActions,
        TodayWeekAndLastShift,
        TodayOpenLines,
        AppBar,
      ]) {
        expect(rebuilt, isNot(contains(type)), reason: '$type rebuilt');
      }
    });

    testWidgets('job name in the header only with more than one job', (
      tester,
    ) async {
      await pumpToday(
        tester,
        seed: (h) async {
          final job = await TodaySeed.job(h);
          await TodaySeed.job(h, name: 'Eventhalle');
          await TodaySeed.running(h, job);
        },
      );
      expect(
        find.text(l10n.todayStatusWithJob(l10n.statusRunning, 'Catering')),
        findsOneWidget,
      );
    });
  });

  group('actions', () {
    testWidgets('start, pause (clock stands still), resume', (tester) async {
      final (f, _) = await pumpToday(tester, seed: (h) => TodaySeed.job(h));
      await tester.tap(find.text(l10n.todayStartShift));
      await settleData(tester);
      expect(await running(f), isNotNull);
      expect(f.data.effects.calls.last.running, isNotNull);
      expect(find.text(l10n.todayPause), findsOneWidget);
      expect(find.text(l10n.todayFinish), findsOneWidget);
      expect(find.text(l10n.todayStartShift), findsNothing);

      f.data.clock.advance(const Duration(minutes: 30));
      await tester.pump(const Duration(seconds: 2));
      expect(worked(tester), '0:30:00');
      expect(heroCents(tester), 750);

      await tester.tap(find.text(l10n.todayPause));
      await settleData(tester);
      final pausedAt = f.data.clock.now;
      expect((await running(f))!.isPaused, isTrue);
      expect(
        find.text(l10n.todayPausedSince(fmt.time(pausedAt.toLocal()))),
        findsOneWidget,
      );
      expect(find.text(l10n.todayResume), findsOneWidget);

      // Paused: time and amount stand still, the break counts.
      f.data.clock.advance(const Duration(minutes: 10));
      await tester.pump(const Duration(seconds: 31));
      expect(worked(tester), '0:30:00');
      expect(heroCents(tester), 750);
      expect(
        textOf(tester, const ValueKey<String>('today-rate')),
        '${fmt.rate(1500)} · ${l10n.todayBreak('0:10')}',
      );

      await tester.tap(find.text(l10n.todayResume));
      await settleData(tester);
      expect((await running(f))!.isPaused, isFalse);
      expect((await running(f))!.breakMs, 10 * msPerMinute);
      f.data.clock.advance(const Duration(minutes: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(worked(tester), '0:31:00');
    });

    testWidgets('job chip: only with >1 job; the choice is used and kept', (
      tester,
    ) async {
      late Job second;
      final (f, _) = await pumpToday(
        tester,
        seed: (h) async {
          await TodaySeed.job(h);
          second = await TodaySeed.job(h, name: 'Eventhalle');
        },
      );
      expect(find.byType(ActionChip), findsOneWidget);
      expect(find.text('Catering'), findsOneWidget);

      await tester.tap(find.byType(ActionChip));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Eventhalle').last);
      await tester.pumpAndSettle();
      expect(find.text('Eventhalle'), findsOneWidget);

      await tester.tap(find.text(l10n.todayStartShift));
      await settleData(tester);
      expect((await running(f))!.jobId, second.id);

      f.data.clock.advance(const Duration(hours: 1));
      await tester.tap(find.text(l10n.todayFinish));
      await settleData(tester);
      await tapSave(tester);
      // Still the chosen job after finishing.
      expect(find.text('Eventhalle'), findsOneWidget);
    });

    testWidgets('single job: no chip', (tester) async {
      await pumpToday(tester, seed: (h) => TodaySeed.job(h));
      expect(find.byType(ActionChip), findsNothing);
    });

    testWidgets('started earlier: starts at the picked time', (tester) async {
      final (f, _) = await pumpToday(tester, seed: (h) => TodaySeed.job(h));
      final target = f.data.clock.now.subtract(
        const Duration(hours: 1, minutes: 30),
      );
      await tester.tap(find.text(l10n.todayStartedEarlier));
      await tester.pumpAndSettle();
      expect(find.text(l10n.todayStartTimeHelp), findsOneWidget);
      await enterTime(tester, localTimeOf(target));
      final shift = await running(f);
      expect(shift!.startUtc, target);
      expect(worked(tester), '1:30:00');
    });

    testWidgets('started earlier: a future time is rejected', (tester) async {
      final (f, _) = await pumpToday(tester, seed: (h) => TodaySeed.job(h));
      await tester.tap(find.text(l10n.todayStartedEarlier));
      await tester.pumpAndSettle();
      await enterTime(
        tester,
        localTimeOf(f.data.clock.now.add(const Duration(minutes: 30))),
      );
      expect(await running(f), isNull);
      expect(find.text(l10n.todayErrorStartInFuture), findsOneWidget);
    });

    testWidgets('started earlier: overlap asks first', (tester) async {
      final (f, _) = await pumpToday(
        tester,
        seed: (h) async {
          final job = await TodaySeed.job(h);
          await TodaySeed.done(
            h,
            job,
            startAgo: const Duration(hours: 7),
            endAgo: const Duration(hours: 5),
          );
        },
      );
      final target = f.data.clock.now.subtract(const Duration(hours: 6));

      await tester.tap(find.text(l10n.todayStartedEarlier));
      await tester.pumpAndSettle();
      await enterTime(tester, localTimeOf(target));
      expect(find.text(l10n.todayOverlapTitle), findsOneWidget);
      await tester.tap(find.text(l10n.commonCancel));
      await settleData(tester);
      expect(await running(f), isNull);

      await tester.tap(find.text(l10n.todayStartedEarlier));
      await tester.pumpAndSettle();
      await enterTime(tester, localTimeOf(target));
      await tester.tap(find.text(l10n.todayOverlapStartAnyway));
      await settleData(tester);
      expect((await running(f))!.startUtc, target);
    });

    testWidgets('tap on "since" moves the start, with undo', (tester) async {
      final (f, _) = await pumpToday(
        tester,
        seed: (h) async => TodaySeed.running(h, await TodaySeed.job(h)),
      );
      final original = (await running(f))!.startUtc;
      final target = f.data.clock.now.subtract(const Duration(hours: 3));

      await tester.tap(
        find.text(l10n.todaySince(fmt.time(original.toLocal()))),
      );
      await tester.pumpAndSettle();
      await enterTime(tester, localTimeOf(target));
      expect((await running(f))!.startUtc, target);
      expect(worked(tester), '3:00:00');
      expect(
        find.text(l10n.todayStartChanged(fmt.time(target.toLocal()))),
        findsOneWidget,
      );

      await tester.tap(find.text(l10n.commonUndo));
      await settleData(tester);
      expect((await running(f))!.startUtc, original);
    });

    testWidgets('moving the start over an earlier shift asks first', (
      tester,
    ) async {
      final (f, _) = await pumpToday(
        tester,
        seed: (h) async {
          final job = await TodaySeed.job(h);
          await TodaySeed.done(
            h,
            job,
            startAgo: const Duration(hours: 7),
            endAgo: const Duration(hours: 5),
          );
          await TodaySeed.running(h, job);
        },
      );
      final original = (await running(f))!.startUtc;
      final target = f.data.clock.now.subtract(const Duration(hours: 6));
      Future<void> openAndEnter() async {
        await tester.tap(find.byTooltip(l10n.todayAdjustStart));
        await tester.pumpAndSettle();
        await enterTime(tester, localTimeOf(target));
      }

      await openAndEnter();
      expect(find.text(l10n.todayOverlapTitle), findsOneWidget);
      await tester.tap(find.text(l10n.commonCancel));
      await settleData(tester);
      expect((await running(f))!.startUtc, original);

      await openAndEnter();
      await tester.tap(find.text(l10n.todayOverlapChangeAnyway));
      await settleData(tester);
      expect((await running(f))!.startUtc, target);
    });

    testWidgets('moving the start into the future is rejected', (tester) async {
      final (f, _) = await pumpToday(
        tester,
        seed: (h) async => TodaySeed.running(h, await TodaySeed.job(h)),
      );
      final original = (await running(f))!.startUtc;
      await tester.tap(
        find.text(l10n.todaySince(fmt.time(original.toLocal()))),
      );
      await tester.pumpAndSettle();
      await enterTime(
        tester,
        localTimeOf(f.data.clock.now.add(const Duration(minutes: 5))),
      );
      expect((await running(f))!.startUtc, original);
      expect(find.text(l10n.todayErrorStartInFuture), findsOneWidget);
    });
  });

  group('finish sheet', () {
    Future<(FeatureHarness, RecordingNavigation)> pumpRunning(
      WidgetTester tester, {
      RoundingRule rounding = RoundingRule.none,
      Duration ago = const Duration(hours: 2),
    }) => pumpToday(
      tester,
      seed: (h) async => TodaySeed.running(
        h,
        await TodaySeed.job(h, rounding: rounding),
        ago: ago,
      ),
    );

    Future<void> openSheet(WidgetTester tester) async {
      await tester.tap(find.text(l10n.todayFinish));
      await settleData(tester);
      expect(find.byType(FinishShiftSheet), findsOneWidget);
    }

    testWidgets('save → snackbar with duration and amount → undo', (
      tester,
    ) async {
      final (f, _) = await pumpRunning(tester);
      await openSheet(tester);
      expect(find.text(l10n.todayFinishSheetTitle), findsOneWidget);
      expect(textOf(tester, const ValueKey<String>('finish-worked')), '2:00 h');
      expect(
        textOf(tester, const ValueKey<String>('finish-amount')),
        fmt.money(3000),
      );
      expect(
        find.text(l10n.todayFinishCalculation('2:00 h', fmt.rate(1500))),
        findsOneWidget,
      );

      await tapSave(tester);
      expect(find.byType(FinishShiftSheet), findsNothing);
      expect(await running(f), isNull);
      final saved = await f.read(shiftRepositoryProvider).lastDone();
      expect(saved!.amountCents, 3000);
      expect(
        find.text(l10n.todayShiftSaved('2:00 h', fmt.money(3000))),
        findsOneWidget,
      );
      expect(find.text(l10n.todayEarnedToday), findsOneWidget);

      await tester.tap(find.text(l10n.commonUndo));
      await settleData(tester);
      expect(await running(f), isNotNull);
      expect(find.text(l10n.todayFinish), findsOneWidget);
    });

    testWidgets('rounding shows recorded → billed times', (tester) async {
      final (f, _) = await pumpRunning(
        tester,
        rounding: RoundingRule.nearest15,
        ago: const Duration(hours: 2, minutes: 2),
      );
      final start = (await running(f))!.startUtc;
      await openSheet(tester);
      // Recorded start → billed start (the job rounds to 15 minutes).
      expect(find.text(fmt.time(start.toLocal())), findsOneWidget);
      expect(
        textOf(tester, const ValueKey<String>('finish-start')),
        fmt.time(start.add(const Duration(minutes: 2)).toLocal()),
      );
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
      expect(find.text(l10n.todayFinishRoundingNote(15)), findsOneWidget);
      expect(textOf(tester, const ValueKey<String>('finish-worked')), '2:00 h');
    });

    testWidgets('break, tips and note are saved', (tester) async {
      final (f, _) = await pumpRunning(tester);
      await openSheet(tester);
      await tester.enterText(
        find.byKey(const ValueKey<String>('finish-break')),
        '30',
      );
      await settleData(tester);
      expect(textOf(tester, const ValueKey<String>('finish-worked')), '1:30 h');
      expect(
        textOf(tester, const ValueKey<String>('finish-amount')),
        fmt.money(2250),
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('finish-tips')),
        '5,50',
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('finish-note')),
        'Hochzeit',
      );
      await tapSave(tester);
      final saved = await f.read(shiftRepositoryProvider).lastDone();
      expect(saved!.breakMs, 30 * msPerMinute);
      expect(saved.tipsCents, 550);
      expect(saved.note, 'Hochzeit');
      expect(saved.amountCents, 2250);
    });

    testWidgets('break as long as the shift blocks saving', (tester) async {
      final (f, _) = await pumpRunning(tester);
      await openSheet(tester);
      await tester.enterText(
        find.byKey(const ValueKey<String>('finish-break')),
        '120',
      );
      await settleData(tester);
      expect(find.text(l10n.todayFinishErrorBreakTooLong), findsOneWidget);
      await tapSave(tester);
      expect(await running(f), isNotNull);
    });

    testWidgets('editing the end: earlier end, future end is an error', (
      tester,
    ) async {
      final (f, _) = await pumpRunning(tester);
      await openSheet(tester);
      final endField = find.descendant(
        of: find.byKey(const ValueKey<String>('finish-end')),
        matching: find.byType(TextField),
      );
      final earlier = f.data.clock.now.subtract(const Duration(minutes: 45));
      await tester.enterText(endField, fmt.clockTime(localTimeOf(earlier)));
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await settleData(tester);
      expect(textOf(tester, const ValueKey<String>('finish-worked')), '1:15 h');

      final later = f.data.clock.now.add(const Duration(minutes: 30));
      await tester.enterText(endField, fmt.clockTime(localTimeOf(later)));
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await settleData(tester);
      expect(find.text(l10n.todayFinishErrorEndInFuture), findsOneWidget);

      await tester.enterText(endField, fmt.clockTime(localTimeOf(earlier)));
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await settleData(tester);
      await tapSave(tester);
      final saved = await f.read(shiftRepositoryProvider).lastDone();
      expect(saved!.endUtc, earlier);
    });

    testWidgets('"keep running" and swiping away keep the shift running', (
      tester,
    ) async {
      final (f, _) = await pumpRunning(tester);
      await openSheet(tester);
      await tester.ensureVisible(find.text(l10n.todayFinishKeepRunning));
      await tester.tap(find.text(l10n.todayFinishKeepRunning));
      await settleData(tester);
      expect(find.byType(FinishShiftSheet), findsNothing);
      expect(await running(f), isNotNull);

      await openSheet(tester);
      // System back dismisses the sheet like swiping it away.
      await tester.binding.handlePopRoute();
      await settleData(tester);
      expect(find.byType(FinishShiftSheet), findsNothing);
      expect(await running(f), isNotNull);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('discard asks, then removes the shift with undo', (
      tester,
    ) async {
      final (f, _) = await pumpRunning(tester);
      await openSheet(tester);
      await tester.ensureVisible(find.text(l10n.commonDiscard));
      await tester.tap(find.text(l10n.commonDiscard));
      await tester.pumpAndSettle();
      expect(find.text(l10n.todayDiscardTitle), findsOneWidget);
      await tester.tap(find.text(l10n.commonCancel));
      await tester.pumpAndSettle();
      expect(find.byType(FinishShiftSheet), findsOneWidget);
      expect(await running(f), isNotNull);

      await tester.tap(find.text(l10n.commonDiscard));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text(l10n.commonDiscard),
        ),
      );
      await settleData(tester);
      expect(find.byType(FinishShiftSheet), findsNothing);
      expect(await running(f), isNull);
      expect(find.text(l10n.todayShiftDiscarded), findsOneWidget);
      expect(find.text(l10n.todayStartShift), findsOneWidget);

      await tester.tap(find.text(l10n.commonUndo));
      await settleData(tester);
      expect(await running(f), isNotNull);
    });

    testWidgets('notification "finish" request opens the sheet once', (
      tester,
    ) async {
      final (f, _) = await pumpRunning(tester);
      f
          .read(appRequestProvider.notifier)
          .request(AppRequestKind.openFinishSheet);
      await settleData(tester);
      expect(find.byType(FinishShiftSheet), findsOneWidget);
      expect(f.read(appRequestProvider), isNull);
    });

    testWidgets('a request posted before start is handled on the first frame', (
      tester,
    ) async {
      final nav = RecordingNavigation();
      final f = await pumpFeature(
        tester,
        TodayPage(navigation: nav),
        seed: (h) async {
          await TodaySeed.running(h, await TodaySeed.job(h));
          h
              .read(appRequestProvider.notifier)
              .request(AppRequestKind.openFinishSheet);
        },
      );
      expect(find.byType(FinishShiftSheet), findsOneWidget);
      expect(f.read(appRequestProvider), isNull);
    });

    testWidgets('finish request without running shift is just consumed', (
      tester,
    ) async {
      final (f, _) = await pumpToday(tester, seed: (h) => TodaySeed.job(h));
      f
          .read(appRequestProvider.notifier)
          .request(AppRequestKind.openFinishSheet);
      await settleData(tester);
      expect(find.byType(FinishShiftSheet), findsNothing);
      expect(f.read(appRequestProvider), isNull);
    });

    testWidgets('the sheet closes when the shift ends elsewhere', (
      tester,
    ) async {
      final (f, _) = await pumpRunning(tester);
      await openSheet(tester);
      // E.g. "Beenden" from the notification on another path.
      await f.read(shiftRepositoryProvider).discardRunning();
      await settleData(tester);
      expect(find.byType(FinishShiftSheet), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('"show today" requests are left for the shell', (tester) async {
      final (f, _) = await pumpRunning(tester);
      f.read(appRequestProvider.notifier).request(AppRequestKind.showToday);
      await settleData(tester);
      expect(find.byType(FinishShiftSheet), findsNothing);
      expect(f.read(appRequestProvider)?.kind, AppRequestKind.showToday);
    });
  });

  group('summaries and navigation', () {
    testWidgets('this week and the last shift (→ editor)', (tester) async {
      late Shift last;
      final (_, nav) = await pumpToday(
        tester,
        seed: (h) async {
          final job = await TodaySeed.job(h);
          last = await TodaySeed.done(
            h,
            job,
            startAgo: const Duration(hours: 7),
            endAgo: const Duration(hours: 5),
            breakMinutes: 15,
          );
        },
      );
      expect(find.text(l10n.todayThisWeek), findsOneWidget);
      expect(
        textOf(tester, const ValueKey<String>('today-week')),
        l10n.todayWeekFigures(fmt.hours(105 * msPerMinute), fmt.money(2625)),
      );
      final start = last.startUtc.toLocal();
      expect(
        find.text(
          l10n.todayLastShiftDetails(
            fmt.dateShort(start),
            fmt.timeRange(start, last.endUtc!.toLocal()),
            '1:45 h',
          ),
        ),
        findsOneWidget,
      );
      await tester.tap(find.text(l10n.todayLastShift));
      await tester.pump();
      expect(nav.calls, ['editor:${last.id}']);
    });

    testWidgets('settings gear', (tester) async {
      final (_, nav) = await pumpToday(tester, seed: (h) => TodaySeed.job(h));
      await tester.tap(find.byTooltip(l10n.commonSettings));
      await tester.pump();
      expect(nav.calls, ['settings']);
    });

    testWidgets('review hint → review page', (tester) async {
      final (_, nav) = await pumpToday(
        tester,
        seed: (h) async {
          final job = await TodaySeed.job(h);
          final a = await TodaySeed.done(
            h,
            job,
            startAgo: const Duration(days: 3, hours: 20),
            endAgo: const Duration(days: 3, hours: 2),
          );
          final b = await TodaySeed.done(
            h,
            job,
            startAgo: const Duration(days: 5, hours: 20),
            endAgo: const Duration(days: 5, hours: 2),
          );
          await TodaySeed.review(h, [a, b]);
        },
      );
      expect(find.text(l10n.todayReviewHint(2)), findsOneWidget);
      await tester.tap(find.text(l10n.todayReviewAction));
      await tester.pump();
      expect(nav.calls, ['review']);
    });

    testWidgets('no review hint without review items', (tester) async {
      await pumpToday(tester, seed: (h) => TodaySeed.job(h));
      expect(
        find.byKey(const ValueKey<String>('today-review-hint')),
        findsNothing,
      );
    });

    testWidgets('expanded: side pane lists today\'s shifts (→ editor)', (
      tester,
    ) async {
      late Shift today;
      final (_, nav) = await pumpToday(
        tester,
        config: const TestConfig(size: TestScreens.tabletLandscape),
        seed: (h) async {
          final job = await TodaySeed.job(h);
          today = await TodaySeed.done(
            h,
            job,
            startAgo: const Duration(hours: 7),
            endAgo: const Duration(hours: 5),
          );
          await TodaySeed.done(
            h,
            job,
            startAgo: const Duration(days: 1, hours: 7),
            endAgo: const Duration(days: 1, hours: 5),
          );
        },
      );
      final pane = find.byKey(const ValueKey<String>('today-shifts-pane'));
      expect(pane, findsOneWidget);
      expect(find.text(l10n.todayShiftsTodayTitle), findsOneWidget);
      final tiles = find.descendant(of: pane, matching: find.byType(ListTile));
      expect(tiles, findsOneWidget);
      await tester.tap(tiles);
      await tester.pump();
      expect(nav.calls, ['editor:${today.id}']);
    });

    testWidgets('compact: no side pane', (tester) async {
      await pumpToday(tester, seed: (h) => TodaySeed.job(h));
      expect(
        find.byKey(const ValueKey<String>('today-shifts-pane')),
        findsNothing,
      );
    });
  });

  group('notification permission', () {
    Future<void> seedFirstStart(ProviderHarness h) =>
        TodaySeed.job(h, primerShown: false);

    testWidgets('first start explains, asks, and starts (granted)', (
      tester,
    ) async {
      final (f, _) = await pumpToday(
        tester,
        seed: seedFirstStart,
        notificationsEnabled: false,
      );
      // No hint before the primer was shown.
      expect(find.text(l10n.todayNotificationsOff), findsNothing);
      await tester.tap(find.text(l10n.todayStartShift));
      await tester.pumpAndSettle();
      expect(find.byType(NotificationPrimerSheet), findsOneWidget);
      expect(find.text(l10n.todayPrimerTitle), findsOneWidget);
      expect(await running(f), isNull);

      await tester.tap(find.text(l10n.todayPrimerAllow));
      await settleData(tester);
      expect(f.notifications.permissionRequests, 1);
      expect(f.read(settingsProvider).notificationPrimerShown, isTrue);
      expect(await running(f), isNotNull);
      expect(
        find.byKey(const ValueKey<String>('today-notifications-hint')),
        findsNothing,
      );
    });

    testWidgets('denied: the shift still starts, a hint opens the settings; '
        'resume re-checks', (tester) async {
      final (f, _) = await pumpToday(
        tester,
        seed: seedFirstStart,
        notificationsEnabled: false,
        grantOnRequest: false,
      );
      await tester.tap(find.text(l10n.todayStartShift));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.todayPrimerAllow));
      await settleData(tester);
      expect(f.notifications.permissionRequests, 1);
      expect(await running(f), isNotNull);
      expect(find.text(l10n.todayNotificationsOff), findsOneWidget);

      await tester.tap(find.text(l10n.commonOpenSettings));
      await settleData(tester);
      expect(f.notifications.settingsOpened, 1);

      // The user allowed notifications in the system settings.
      f.notifications.enabled = true;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await settleData(tester);
      expect(find.text(l10n.todayNotificationsOff), findsNothing);
    });

    testWidgets('"not now": no system dialog, the shift starts, hint shown', (
      tester,
    ) async {
      final (f, _) = await pumpToday(
        tester,
        seed: seedFirstStart,
        notificationsEnabled: false,
      );
      await tester.tap(find.text(l10n.todayStartShift));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.todayPrimerLater));
      await settleData(tester);
      expect(f.notifications.permissionRequests, 0);
      expect(f.read(settingsProvider).notificationPrimerShown, isTrue);
      expect(await running(f), isNotNull);
      expect(find.text(l10n.todayNotificationsOff), findsOneWidget);
    });

    testWidgets('already allowed: no primer at all', (tester) async {
      final (f, _) = await pumpToday(tester, seed: seedFirstStart);
      await tester.tap(find.text(l10n.todayStartShift));
      await settleData(tester);
      expect(find.byType(NotificationPrimerSheet), findsNothing);
      expect(f.notifications.permissionRequests, 0);
      expect(f.read(settingsProvider).notificationPrimerShown, isTrue);
      expect(await running(f), isNotNull);
    });

    testWidgets('primer only once', (tester) async {
      final (f, _) = await pumpToday(
        tester,
        seed: (h) => TodaySeed.job(h),
        notificationsEnabled: false,
      );
      await tester.tap(find.text(l10n.todayStartShift));
      await settleData(tester);
      expect(find.byType(NotificationPrimerSheet), findsNothing);
      expect(await running(f), isNotNull);
      // Primer was shown before and notifications are off: hint.
      expect(find.text(l10n.todayNotificationsOff), findsOneWidget);
    });
  });

  group('lifecycle', () {
    testWidgets('no timer is pending while the app is hidden', (tester) async {
      final timers = TimerTracker();
      await timers.run(() async {
        final (f, _) = await pumpToday(
          tester,
          seed: (h) async => TodaySeed.running(h, await TodaySeed.job(h)),
        );
        await tester.pump(const Duration(seconds: 2));
        expect(timers.pending, greaterThan(0), reason: 'ticking while visible');

        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        await tester.pump();
        expect(timers.pending, 0);

        // Back in the foreground: fresh values right away, ticking again.
        f.data.clock.advance(const Duration(hours: 1));
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pump();
        expect(worked(tester), '3:00:00');
        expect(timers.pending, greaterThan(0));
      });
    });

    testWidgets('idle: no timer and no frames', (tester) async {
      final timers = TimerTracker();
      await timers.run(() async {
        await pumpToday(
          tester,
          seed: (h) async {
            final job = await TodaySeed.job(h);
            await TodaySeed.done(
              h,
              job,
              startAgo: const Duration(hours: 7),
              endAgo: const Duration(hours: 5),
            );
          },
        );
        await tester.pump(const Duration(seconds: 5));
        expect(timers.pending, 0);
        expect(tester.binding.hasScheduledFrame, isFalse);
      });
    });

    testWidgets('paused: only the break minute ticks', (tester) async {
      final timers = TimerTracker();
      await timers.run(() async {
        await pumpToday(tester, seed: TodayScenarios.paused);
        await tester.pump(const Duration(seconds: 5));
        // One timer: the next minute of the break. No clock, no cents.
        expect(timers.pending, 1);
      });
    });

    testWidgets('resume refreshes the date (new day)', (tester) async {
      final (f, _) = await pumpToday(tester, seed: (h) => TodaySeed.job(h));
      f.data.clock.advance(const Duration(days: 1));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await settleData(tester);
      expect(f.read(currentDateProvider), LocalDate(2026, 10, 1));
      expect(
        find.text(fmt.todayTitle(f.data.clock.now.toLocal())),
        findsOneWidget,
      );
    });
  });
}
