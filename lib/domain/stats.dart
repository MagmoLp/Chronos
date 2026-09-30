import '../core/local_date.dart';
import '../core/money.dart';
import '../core/time.dart';
import 'app_settings.dart';
import 'shift.dart';

/// Granularity of the overview.
enum StatsPeriodKind {
  /// Monday–Sunday.
  week,

  /// Calendar month.
  month,

  /// Calendar year.
  year,
}

/// A concrete week, month or year (normalised to its first day).
final class StatsPeriod {
  /// The period of [kind] that contains [anyDay].
  factory StatsPeriod(StatsPeriodKind kind, LocalDate anyDay) =>
      StatsPeriod._(kind, switch (kind) {
        StatsPeriodKind.week => anyDay.startOfWeek,
        StatsPeriodKind.month => anyDay.firstOfMonth,
        StatsPeriodKind.year => LocalDate(anyDay.year, 1, 1),
      });

  const StatsPeriod._(this.kind, this.start);

  /// The week containing [anyDay].
  factory StatsPeriod.week(LocalDate anyDay) =>
      StatsPeriod(StatsPeriodKind.week, anyDay);

  /// The month containing [anyDay].
  factory StatsPeriod.month(LocalDate anyDay) =>
      StatsPeriod(StatsPeriodKind.month, anyDay);

  /// The year containing [anyDay].
  factory StatsPeriod.year(LocalDate anyDay) =>
      StatsPeriod(StatsPeriodKind.year, anyDay);

  /// Week, month or year.
  final StatsPeriodKind kind;

  /// First day of the period.
  final LocalDate start;

  /// The days of the period.
  LocalDateRange get range => switch (kind) {
    StatsPeriodKind.week => LocalDateRange.week(start),
    StatsPeriodKind.month => LocalDateRange.monthOf(start),
    StatsPeriodKind.year => LocalDateRange.year(start.year),
  };

  /// The period before this one.
  StatsPeriod get previous => switch (kind) {
    StatsPeriodKind.week => StatsPeriod._(kind, start.addDays(-7)),
    StatsPeriodKind.month => StatsPeriod._(kind, start.addMonths(-1)),
    StatsPeriodKind.year => StatsPeriod._(
      kind,
      LocalDate(start.year - 1, 1, 1),
    ),
  };

  /// The period after this one.
  StatsPeriod get next => switch (kind) {
    StatsPeriodKind.week => StatsPeriod._(kind, start.addDays(7)),
    StatsPeriodKind.month => StatsPeriod._(kind, start.addMonths(1)),
    StatsPeriodKind.year => StatsPeriod._(
      kind,
      LocalDate(start.year + 1, 1, 1),
    ),
  };

  /// Whether [today] lies in this period.
  bool isCurrent(LocalDate today) => range.contains(today);

  /// Whether the stepper may go forward (never past the current period).
  bool canGoNext(LocalDate today) => next.start.isOnOrBefore(today);

  @override
  bool operator ==(Object other) =>
      other is StatsPeriod && other.kind == kind && other.start == start;

  @override
  int get hashCode => Object.hash(kind, start);

  @override
  String toString() => 'StatsPeriod(${kind.name} $start)';
}

/// One bar of the chart: a day (week/month view) or a month (year view).
final class StatsBucket {
  /// Creates a bucket.
  const StatsBucket({
    required this.range,
    this.workedMs = 0,
    this.earnedCents = 0,
    this.tipsCents = 0,
    this.shiftCount = 0,
  });

  /// Days covered by the bucket.
  final LocalDateRange range;

  /// First day of the bucket.
  LocalDate get start => range.start;

  /// Worked time.
  final int workedMs;

  /// Wage earned (without tips).
  final int earnedCents;

  /// Tips.
  final int tipsCents;

  /// Number of shifts.
  final int shiftCount;

  @override
  bool operator ==(Object other) =>
      other is StatsBucket &&
      other.range == range &&
      other.workedMs == workedMs &&
      other.earnedCents == earnedCents &&
      other.tipsCents == tipsCents &&
      other.shiftCount == shiftCount;

  @override
  int get hashCode =>
      Object.hash(range, workedMs, earnedCents, tipsCents, shiftCount);

  @override
  String toString() =>
      'StatsBucket($start, ${workedMs}ms, $earnedCents ct, $shiftCount)';
}

/// Totals of one job within a period.
final class JobStats {
  /// Creates job totals.
  const JobStats({
    required this.jobId,
    this.workedMs = 0,
    this.earnedCents = 0,
    this.openCents = 0,
    this.tipsCents = 0,
    this.shiftCount = 0,
  });

  /// The job.
  final int jobId;

  /// Worked time.
  final int workedMs;

  /// Wage earned (without tips).
  final int earnedCents;

  /// Unpaid wage.
  final int openCents;

  /// Tips.
  final int tipsCents;

  /// Number of shifts.
  final int shiftCount;

  @override
  bool operator ==(Object other) =>
      other is JobStats &&
      other.jobId == jobId &&
      other.workedMs == workedMs &&
      other.earnedCents == earnedCents &&
      other.openCents == openCents &&
      other.tipsCents == tipsCents &&
      other.shiftCount == shiftCount;

  @override
  int get hashCode => Object.hash(
    jobId,
    workedMs,
    earnedCents,
    openCents,
    tipsCents,
    shiftCount,
  );

  @override
  String toString() => 'JobStats($jobId, ${workedMs}ms, $earnedCents ct)';
}

/// Key figures and chart series of a period (finished shifts only).
final class PeriodStats {
  /// Creates stats.
  const PeriodStats({
    required this.period,
    required this.workedMs,
    required this.earnedCents,
    required this.openCents,
    required this.tipsCents,
    required this.shiftCount,
    required this.avgHourlyInclTipsCents,
    required this.buckets,
    required this.perJob,
  });

  /// The period.
  final StatsPeriod period;

  /// Worked time.
  final int workedMs;

  /// Wage earned (without tips).
  final int earnedCents;

  /// Unpaid wage of shifts in the period.
  final int openCents;

  /// Tips.
  final int tipsCents;

  /// Number of shifts.
  final int shiftCount;

  /// (Wage + tips) per worked hour; `null` if nothing was worked.
  final int? avgHourlyInclTipsCents;

  /// Chart series: 7 days, the days of the month, or 12 months.
  final List<StatsBucket> buckets;

  /// Totals per job, highest earnings first.
  final List<JobStats> perJob;

  /// Whether the period has no shifts.
  bool get isEmpty => shiftCount == 0;

  @override
  bool operator ==(Object other) =>
      other is PeriodStats &&
      other.period == period &&
      other.workedMs == workedMs &&
      other.earnedCents == earnedCents &&
      other.openCents == openCents &&
      other.tipsCents == tipsCents &&
      other.shiftCount == shiftCount &&
      other.avgHourlyInclTipsCents == avgHourlyInclTipsCents &&
      _listEquals(other.buckets, buckets) &&
      _listEquals(other.perJob, perJob);

  @override
  int get hashCode => Object.hash(
    period,
    workedMs,
    earnedCents,
    openCents,
    tipsCents,
    shiftCount,
    avgHourlyInclTipsCents,
    Object.hashAll(buckets),
    Object.hashAll(perJob),
  );

  @override
  String toString() =>
      'PeriodStats($period, ${workedMs}ms, $earnedCents ct, open $openCents, '
      'tips $tipsCents, $shiftCount shifts)';
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

class _Acc {
  int workedMs = 0;
  int earnedCents = 0;
  int openCents = 0;
  int tipsCents = 0;
  int count = 0;

  void add(Shift s) {
    workedMs += s.workedMs;
    earnedCents += s.earnedCents;
    tipsCents += s.tipsCents;
    if (!s.isPaid) openCents += s.earnedCents;
    count++;
  }
}

/// Computes the overview for [period] from [shifts].
///
/// Counts finished, non-deleted shifts whose local start date lies in the
/// period (a running shift is not included).
PeriodStats computeStats(StatsPeriod period, Iterable<Shift> shifts) {
  final range = period.range;
  final bucketRanges = switch (period.kind) {
    StatsPeriodKind.week || StatsPeriodKind.month => [
      for (final day in range.days) LocalDateRange.day(day),
    ],
    StatsPeriodKind.year => [
      for (var m = 1; m <= 12; m++) LocalDateRange.month(range.start.year, m),
    ],
  };
  final bucketAcc = List.generate(bucketRanges.length, (_) => _Acc());
  final total = _Acc();
  final perJob = <int, _Acc>{};

  for (final shift in shifts) {
    if (!shift.isDone || shift.isDeleted) continue;
    final date = shift.localStartDate;
    if (!range.contains(date)) continue;
    total.add(shift);
    perJob.putIfAbsent(shift.jobId, _Acc.new).add(shift);
    final index = period.kind == StatsPeriodKind.year
        ? date.month - 1
        : range.start.daysUntil(date);
    bucketAcc[index].add(shift);
  }

  final jobStats =
      [
        for (final entry in perJob.entries)
          JobStats(
            jobId: entry.key,
            workedMs: entry.value.workedMs,
            earnedCents: entry.value.earnedCents,
            openCents: entry.value.openCents,
            tipsCents: entry.value.tipsCents,
            shiftCount: entry.value.count,
          ),
      ]..sort((a, b) {
        final byEarned = b.earnedCents.compareTo(a.earnedCents);
        return byEarned != 0 ? byEarned : a.jobId.compareTo(b.jobId);
      });

  return PeriodStats(
    period: period,
    workedMs: total.workedMs,
    earnedCents: total.earnedCents,
    openCents: total.openCents,
    tipsCents: total.tipsCents,
    shiftCount: total.count,
    avgHourlyInclTipsCents: averageHourlyCents(
      total.earnedCents + total.tipsCents,
      total.workedMs,
    ),
    buckets: List.unmodifiable([
      for (var i = 0; i < bucketRanges.length; i++)
        StatsBucket(
          range: bucketRanges[i],
          workedMs: bucketAcc[i].workedMs,
          earnedCents: bucketAcc[i].earnedCents,
          tipsCents: bucketAcc[i].tipsCents,
          shiftCount: bucketAcc[i].count,
        ),
    ]),
    perJob: List.unmodifiable(jobStats),
  );
}

/// Colour level of the monthly progress bar.
enum GoalLevel {
  /// Normal colour.
  normal,

  /// Limit: 80 % or more reached.
  warning,

  /// Limit: 100 % or more reached.
  exceeded,
}

/// Progress of the current month towards the monthly goal or limit.
final class GoalProgress {
  /// Creates progress.
  const GoalProgress({
    required this.earnedCents,
    required this.targetCents,
    required this.type,
  });

  /// Earned this month (wage without tips).
  final int earnedCents;

  /// The goal or limit.
  final int targetCents;

  /// Goal or limit.
  final MonthlyGoalType type;

  /// Share reached (may exceed 1); 0 for a non-positive target.
  double get fraction => targetCents <= 0 ? 0 : earnedCents / targetCents;

  /// Whether the target was reached.
  bool get reached => earnedCents >= targetCents;

  /// Remaining amount until the target (0 if reached).
  int get remainingCents =>
      earnedCents >= targetCents ? 0 : targetCents - earnedCents;

  /// Colour level: limits warn from 80 % and are exceeded from 100 %.
  GoalLevel get level {
    if (type != MonthlyGoalType.limit) return GoalLevel.normal;
    if (earnedCents >= targetCents) return GoalLevel.exceeded;
    if (earnedCents * 100 >= targetCents * 80) return GoalLevel.warning;
    return GoalLevel.normal;
  }

  @override
  bool operator ==(Object other) =>
      other is GoalProgress &&
      other.earnedCents == earnedCents &&
      other.targetCents == targetCents &&
      other.type == type;

  @override
  int get hashCode => Object.hash(earnedCents, targetCents, type);

  @override
  String toString() => 'GoalProgress($earnedCents / $targetCents ${type.name})';
}

/// Monthly progress for [settings], or `null` if no goal is set.
GoalProgress? monthlyGoalProgress(AppSettings settings, int earnedCents) {
  final target = settings.monthlyGoalCents;
  if (target == null || target <= 0) return null;
  return GoalProgress(
    earnedCents: earnedCents,
    targetCents: target,
    type: settings.monthlyGoalType,
  );
}
