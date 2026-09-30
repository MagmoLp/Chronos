import 'package:chronos/app/providers/providers.dart';
import 'package:chronos/app/shell.dart';
import 'package:chronos/core/format.dart';
import 'package:chronos/domain/job.dart';
import 'package:chronos/domain/review.dart';
import 'package:chronos/domain/shift.dart';
import 'package:chronos/domain/shift_draft.dart';
import 'package:chronos/features/today/today_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/feature_harness.dart';

export '../../support/feature_harness.dart';

/// Records what Today asked other features to open.
class RecordingNavigation extends TodayNavigation {
  /// Every call as a readable string ("settings", "editor:3", …).
  final List<String> calls = <String>[];

  @override
  Future<void> openSettings(BuildContext context) async =>
      calls.add('settings');

  @override
  Future<void> openShiftEditor(BuildContext context, int shiftId) async =>
      calls.add('editor:$shiftId');

  @override
  Future<void> openPayoutSheet(BuildContext context) async =>
      calls.add('payout');

  @override
  Future<void> openReview(BuildContext context) async => calls.add('review');
}

/// Common test data.
class TodaySeed {
  TodaySeed._();

  /// Creates the default job (15,00 €/h) and marks the primer as shown.
  static Future<Job> job(
    ProviderHarness h, {
    String name = 'Catering',
    int centsPerHour = 1500,
    RoundingRule rounding = RoundingRule.none,
    bool primerShown = true,
  }) async {
    final job = await h.job(
      name: name,
      centsPerHour: centsPerHour,
      rounding: rounding,
    );
    if (primerShown) {
      await h.read(settingsProvider.notifier).setNotificationPrimerShown(true);
    }
    return job;
  }

  /// A finished shift from `now − startAgo` to `now − endAgo`.
  static Future<Shift> done(
    ProviderHarness h,
    Job job, {
    required Duration startAgo,
    required Duration endAgo,
    int breakMinutes = 0,
    bool paid = false,
  }) {
    final now = h.clock.now;
    return h
        .read(shiftRepositoryProvider)
        .insertManual(
          ShiftDraft(
            jobId: job.id,
            startUtc: now.subtract(startAgo),
            endUtc: now.subtract(endAgo),
            breakMs: breakMinutes * 60000,
            paid: paid,
          ),
        );
  }

  /// Starts a timer shift `ago` before now.
  static Future<Shift> running(
    ProviderHarness h,
    Job job, {
    Duration ago = const Duration(hours: 2),
  }) => h
      .read(shiftRepositoryProvider)
      .start(job.id, startUtc: h.clock.now.subtract(ago));

  /// Puts review items for [shifts].
  static Future<void> review(ProviderHarness h, List<Shift> shifts) =>
      h.read(reviewRepositoryProvider).putItems([
        for (final s in shifts)
          ReviewItem(shiftId: s.id, reasons: const {ReviewReason.tooLong16h}),
      ]);
}

/// The fake notification service of [h] (configure it in `seed`).
FakeNotificationService notificationsOf(ProviderHarness h) =>
    h.read(notificationServiceProvider) as FakeNotificationService;

/// Formatter for [locale] with the test default 12/24 h setting.
Fmt fmtFor(Locale locale) =>
    Fmt(locale, use24HourFormat: locale.languageCode != 'en');

/// Pumps [duration] in steps of [step] so every timer gets its own frame.
Future<void> pumpFor(
  WidgetTester tester,
  Duration duration, {
  Duration step = const Duration(milliseconds: 250),
}) async {
  var elapsed = Duration.zero;
  while (elapsed < duration) {
    await tester.pump(step);
    elapsed += step;
  }
}

/// Text of the widget with [key].
String textOf(WidgetTester tester, Key key) =>
    tester.widget<Text>(find.byKey(key)).data!;

/// Semantics label of the hero amount (`RollingAmount` exposes the full
/// value as one label).
Finder amountLabelled(String value) => find.bySemanticsLabel(value);

/// Today inside the real adaptive shell (bar or rail).
Widget todayInShell({TodayNavigation? navigation}) => AdaptiveShell(
  todayBuilder: (_) =>
      TodayPage(navigation: navigation ?? RecordingNavigation()),
  shiftsBuilder: (_) => const SizedBox.shrink(),
  insightsBuilder: (_) => const SizedBox.shrink(),
);

/// Seeds for the main states of Today.
abstract final class TodayScenarios {
  /// Idle, nothing worked today, two jobs (chip), both hint cards.
  static Future<void> idleWithHints(ProviderHarness h) async {
    notificationsOf(h).enabled = false;
    final job = await TodaySeed.job(h, name: 'Catering Müller & Söhne');
    await TodaySeed.job(h, name: 'Eventhalle Nord');
    final a = await TodaySeed.done(
      h,
      job,
      startAgo: const Duration(days: 2, hours: 8),
      endAgo: const Duration(days: 2, hours: 1),
      breakMinutes: 30,
    );
    await TodaySeed.review(h, [a]);
  }

  /// Idle, worked today, two jobs.
  static Future<void> idleWorked(ProviderHarness h) async {
    final job = await TodaySeed.job(h);
    await TodaySeed.job(h, name: 'Eventhalle Nord');
    await TodaySeed.done(
      h,
      job,
      startAgo: const Duration(hours: 7),
      endAgo: const Duration(hours: 3),
    );
  }

  /// Idle, single job, nothing today.
  static Future<void> idleSingle(ProviderHarness h) async {
    final job = await TodaySeed.job(h);
    await TodaySeed.done(
      h,
      job,
      startAgo: const Duration(days: 1, hours: 8),
      endAgo: const Duration(days: 1, hours: 2),
    );
  }

  /// Running with a break, after an earlier shift today, two jobs.
  static Future<void> running(ProviderHarness h) async {
    final job = await TodaySeed.job(h, name: 'Catering Müller & Söhne');
    await TodaySeed.job(h, name: 'Eventhalle Nord');
    await TodaySeed.done(
      h,
      job,
      startAgo: const Duration(hours: 7),
      endAgo: const Duration(hours: 5),
    );
    await TodaySeed.running(h, job, ago: const Duration(hours: 3, minutes: 11));
    final shifts = h.read(shiftRepositoryProvider);
    final now = h.clock.now;
    await shifts.pause(atUtc: now.subtract(const Duration(minutes: 40)));
    await shifts.resume(atUtc: now.subtract(const Duration(minutes: 10)));
  }

  /// Paused.
  static Future<void> paused(ProviderHarness h) async {
    final job = await TodaySeed.job(h);
    await TodaySeed.running(h, job, ago: const Duration(hours: 5));
    await h
        .read(shiftRepositoryProvider)
        .pause(atUtc: h.clock.now.subtract(const Duration(minutes: 20)));
  }
}
