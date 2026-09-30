import 'package:chronos/app/providers/providers.dart';
import 'package:chronos/core/local_date.dart';
import 'package:chronos/core/time.dart';
import 'package:chronos/domain/app_settings.dart';
import 'package:chronos/domain/job.dart';
import 'package:chronos/domain/shift_draft.dart';
import 'package:chronos/domain/stats.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fixtures/provider_harness.dart';
import '../../fixtures/shifts.dart';

void main() {
  late ProviderHarness h;
  late Job job;

  setUp(() async {
    // Wednesday.
    h = ProviderHarness(local(2026, 9, 30, 12));
    job = await h.job();
  });

  Future<void> add(DateTime start, DateTime end, {bool paid = false}) => h
      .read(shiftRepositoryProvider)
      .insertManual(
        ShiftDraft(jobId: job.id, startUtc: start, endUtc: end, paid: paid),
      );

  test('today, week and open summaries follow the database', () async {
    await add(local(2026, 9, 30, 6), local(2026, 9, 30, 8)); // today
    await add(local(2026, 9, 28, 8), local(2026, 9, 28, 16), paid: true); // Mon
    await add(local(2026, 9, 27, 8), local(2026, 9, 27, 10)); // last week

    final today = await h.settle(todaySummaryProvider);
    expect(today.date, LocalDate(2026, 9, 30));
    expect(today.doneEarnedCents, 3000);
    expect(today.running, isNull);

    final week = await h.settle(weekSummaryProvider);
    expect(week.range, LocalDateRange.week(LocalDate(2026, 9, 30)));
    expect(week.shiftCount, 2);
    expect(week.earnedCents, 15000);

    final open = await h.settle(openSummaryProvider);
    expect(open.shiftCount, 2);
    expect(open.openCents, 3000 + 3000);

    // A running shift appears everywhere without any ticking provider.
    await h.read(activeShiftControllerProvider.notifier).start(job.id);
    final liveToday = await h.settle(todaySummaryProvider);
    expect(liveToday.running, isNotNull);
    final later = local(2026, 9, 30, 14);
    expect(liveToday.earnedCentsAt(later), 3000 + 3000);
    expect((await h.settle(openSummaryProvider)).openCentsAt(later), 9000);
    expect((await h.settle(weekSummaryProvider)).earnedCentsAt(later), 18000);
  });

  test('currentDate refresh switches the day only when it changed', () async {
    h.keepAlive(todaySummaryProvider);
    await add(local(2026, 9, 30, 6), local(2026, 9, 30, 8));
    expect((await h.settle(todaySummaryProvider)).doneCount, 1);
    final notifier = h.read(currentDateProvider.notifier);
    notifier.refresh();
    expect(h.read(currentDateProvider), LocalDate(2026, 9, 30));
    h.clock.set(local(2026, 10, 1, 0, 5));
    notifier.refresh();
    expect(h.read(currentDateProvider), LocalDate(2026, 10, 1));
    final today = await h.settle(todaySummaryProvider);
    expect(today.date, LocalDate(2026, 10, 1));
    expect(today.doneCount, 0);
  });

  test('stats and monthly goal', () async {
    await add(local(2026, 9, 1, 8), local(2026, 9, 1, 16));
    await add(local(2026, 9, 2, 8), local(2026, 9, 2, 12), paid: true);
    final stats = await h.settle(
      statsProvider(StatsPeriod.month(LocalDate(2026, 9, 30))),
    );
    expect(stats.earnedCents, 18000);
    expect(stats.openCents, 12000);
    expect(stats.buckets, hasLength(30));
    expect(stats.workedMs, 12 * msPerHour);

    expect(await h.settle(monthlyGoalProvider), isNull);
    await h.read(bootstrapProvider.future);
    await h
        .read(settingsProvider.notifier)
        .setMonthlyGoal(60300, type: MonthlyGoalType.limit);
    final goal = (await h.settle(monthlyGoalProvider))!;
    expect(goal.earnedCents, 18000);
    expect(goal.targetCents, 60300);
    expect(goal.level, GoalLevel.normal);
  });

  test('last shift, default job, onboarding needed', () async {
    expect(await h.settle(lastShiftProvider), isNull);
    final other = await h.job(name: 'Bar');
    // Without shifts the first active job is the default.
    expect((await h.settle(defaultJobProvider))!.id, job.id);
    await h
        .read(shiftRepositoryProvider)
        .insertManual(
          ShiftDraft(
            jobId: other.id,
            startUtc: local(2026, 9, 29, 8),
            endUtc: local(2026, 9, 29, 9),
          ),
        );
    expect((await h.settle(lastShiftProvider))!.jobId, other.id);
    expect((await h.settle(defaultJobProvider))!.id, other.id);
    // The running shift's job wins.
    await h.read(activeShiftControllerProvider.notifier).start(job.id);
    expect((await h.settle(defaultJobProvider))!.id, job.id);
    expect(await h.settle(onboardingNeededProvider), isFalse);
  });

  test('onboarding needed without jobs', () async {
    final fresh = ProviderHarness(local(2026, 9, 30, 12));
    expect(await fresh.settle(onboardingNeededProvider), isTrue);
    expect(await fresh.settle(defaultJobProvider), isNull);
  });
}
