import 'dart:async';
import 'dart:ui' show AppLifecycleState;

import 'package:chronos/app/providers/providers.dart';
import 'package:chronos/core/local_date.dart';
import 'package:flutter_test/flutter_test.dart';

import 'startup/app_harness.dart';

/// Sends the app to the background and back, through the valid states.
Future<void> _backgroundAndResume(WidgetTester tester) async {
  for (final state in const [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(state);
    await tester.pump();
  }
  await settleApp(tester);
}

void main() {
  testWidgets('resume reconciles the notification once and refreshes today', (
    tester,
  ) async {
    final h = AppHarness();
    final job = await h.job();
    // A shift that runs (e.g. started from the notification's app before).
    await h.read(shiftRepositoryProvider).start(job.id);
    await pumpChronosApp(tester, h);
    // The start sequence reconciled once.
    expect(h.notifications.posted, hasLength(1));
    expect(h.read(currentDateProvider), LocalDate(2026, 9, 30));

    h.notifications.clearRecords();
    h.clock.advance(const Duration(days: 1));
    await _backgroundAndResume(tester);

    expect(h.notifications.posted, hasLength(1));
    // 24 h after the start the 10 h reminder is overdue: removed, not re-armed.
    expect(h.notifications.scheduled, isEmpty);
    expect(h.notifications.remindersCancelled, 1);
    expect(h.read(currentDateProvider), LocalDate(2026, 10, 1));
  });

  testWidgets('today switches at midnight while the app stays visible', (
    tester,
  ) async {
    final h = AppHarness(now: DateTime(2026, 9, 30, 23, 59, 30).toUtc());
    await h.job();
    await pumpChronosApp(tester, h);
    expect(h.read(currentDateProvider), LocalDate(2026, 9, 30));

    h.clock.advance(const Duration(seconds: 31));
    await tester.pump(const Duration(seconds: 32));
    await settleApp(tester);
    expect(h.read(currentDateProvider), LocalDate(2026, 10, 1));
  });

  testWidgets('the midnight timer is not armed while the app is hidden', (
    tester,
  ) async {
    final h = AppHarness(now: DateTime(2026, 9, 30, 23, 59, 30).toUtc());
    await h.job();
    await pumpChronosApp(tester, h);
    for (final state in const [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
      await tester.pump();
    }
    h.clock.advance(const Duration(seconds: 31));
    await tester.pump(const Duration(seconds: 32));
    // Still the old day: nothing ran while hidden (resume refreshes it).
    expect(h.read(currentDateProvider), LocalDate(2026, 9, 30));
    for (final state in const [
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
      await tester.pump();
    }
    await settleApp(tester);
    expect(h.read(currentDateProvider), LocalDate(2026, 10, 1));
  });

  testWidgets('resume without a running shift clears stale notifications', (
    tester,
  ) async {
    final h = AppHarness();
    await h.job();
    await pumpChronosApp(tester, h);
    h.notifications.clearRecords();

    await _backgroundAndResume(tester);
    expect(h.notifications.posted, isEmpty);
    expect(h.notifications.cancelled, 1);
    expect(h.notifications.remindersCancelled, 1);
  });

  testWidgets('no reconcile before the start sequence finished', (
    tester,
  ) async {
    final pending = Completer<BootstrapResult>();
    final h = AppHarness(
      overrides: [bootstrapProvider.overrideWith((ref) => pending.future)],
    );
    await pumpChronosApp(tester, h, settle: false);
    await tester.pump();
    await _backgroundAndResumeNoSettle(tester);
    expect(h.notifications.postingCalls, 0);
  });

  testWidgets('temporary share files are removed at start, once', (
    tester,
  ) async {
    final h = AppHarness();
    await pumpChronosApp(tester, h);
    await _backgroundAndResume(tester);
    expect(h.share.clears, 1);
  });

  testWidgets('no timers are left running in the background', (tester) async {
    final h = AppHarness();
    await h.job();
    await pumpChronosApp(tester, h);
    for (final state in const [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
      await tester.pump();
    }
    expect(tester.binding.hasScheduledFrame, isFalse);
    // Returning works as usual.
    for (final state in const [
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
      await tester.pump();
    }
    await settleApp(tester);
  });
}

Future<void> _backgroundAndResumeNoSettle(WidgetTester tester) async {
  for (final state in const [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(state);
    await tester.pump();
  }
}
