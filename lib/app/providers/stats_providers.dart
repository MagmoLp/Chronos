import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/stats.dart';
import 'settings_providers.dart';
import 'shift_providers.dart';
import 'summary_providers.dart';

/// Overview figures and chart series of a week, month or year (finished
/// shifts). Use `StatsPeriod.month(today)` etc. as key.
final statsProvider = Provider.autoDispose
    .family<AsyncValue<PeriodStats>, StatsPeriod>(
      (ref, period) => ref
          .watch(shiftsInRangeProvider(period.range))
          .whenData((shifts) => computeStats(period, shifts)),
      name: 'statsProvider',
    );

/// Progress of the current month towards the monthly goal/limit; `null`
/// data if no goal is set.
final monthlyGoalProvider = Provider.autoDispose<AsyncValue<GoalProgress?>>((
  ref,
) {
  final settings = ref.watch(settingsProvider);
  if (settings.monthlyGoalCents == null) return const AsyncData(null);
  final month = StatsPeriod.month(ref.watch(currentDateProvider));
  return ref
      .watch(statsProvider(month))
      .whenData((stats) => monthlyGoalProgress(settings, stats.earnedCents));
}, name: 'monthlyGoalProvider');
