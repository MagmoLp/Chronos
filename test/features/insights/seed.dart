import 'package:chronos/app/providers/providers.dart';
import 'package:chronos/core/local_date.dart';
import 'package:chronos/domain/job.dart';
import 'package:chronos/domain/shift.dart';
import 'package:chronos/domain/shift_draft.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/feature_harness.dart';

/// Inserts a finished shift of [job] on [date] from [start] to [end] (local
/// hours, `end` may exceed 24 for a shift ending the next day).
Future<Shift> addShift(
  ProviderHarness h,
  Job job,
  LocalDate date, {
  int start = 8,
  int end = 16,
  int startMinute = 0,
  int endMinute = 0,
  int breakMinutes = 0,
  int tips = 0,
  bool paid = false,
  String? note,
}) => h
    .read(shiftRepositoryProvider)
    .insertManual(
      ShiftDraft.fromLocal(
        jobId: job.id,
        date: date,
        startHour: start,
        startMinute: startMinute,
        endHour: end % 24,
        endMinute: endMinute,
        endsNextDay: end >= 24,
        breakMs: breakMinutes * 60000,
        tipsCents: tips,
        paid: paid,
        note: note,
      ),
    );

/// Waits for real I/O (files, isolates) started by the UI and pumps until
/// [done] holds (or fails after [maxRounds]).
Future<void> pumpUntil(
  WidgetTester tester,
  bool Function() done, {
  int maxRounds = 200,
}) async {
  for (var i = 0; i < maxRounds; i++) {
    if (done()) {
      await tester.pumpAndSettle();
      return;
    }
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump();
  }
  fail('Condition not reached after $maxRounds rounds');
}

/// Scrolls the first [Scrollable] under [within] to its end in steps,
/// failing on any layout error along the way.
Future<void> scrollThrough(
  WidgetTester tester, {
  Finder? within,
  Object? context,
}) async {
  final scrollable = find
      .descendant(
        of: within ?? find.byType(Scaffold).last,
        matching: find.byType(Scrollable),
      )
      .first;
  for (var i = 0; i < 40; i++) {
    final state = tester.state<ScrollableState>(scrollable);
    final position = state.position;
    if (position.pixels >= position.maxScrollExtent) break;
    position.jumpTo(
      (position.pixels + position.viewportDimension * 0.8).clamp(
        0,
        position.maxScrollExtent,
      ),
    );
    await tester.pump();
    expectNoLayoutErrors(tester, context);
  }
  // Let providers of rows scrolled away dispose cleanly.
  await tester.pump(const Duration(milliseconds: 1));
  await tester.pumpAndSettle();
  expectNoLayoutErrors(tester, context);
}

/// Scrolls [finder] fully into view (building it first by scrolling in
/// steps of [delta] if needed), then taps it.
Future<void> tapVisible(
  WidgetTester tester,
  Finder finder, {
  double delta = 200,
}) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      delta,
      scrollable: topScrollable(),
    );
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
}

/// Runs [action] in the test zone (like the app would) and pumps, letting
/// real I/O progress, until it completes. Unlike `tester.runAsync`, this
/// cannot deadlock with database work started by the widget tree.
Future<T> runInApp<T>(WidgetTester tester, Future<T> Function() action) async {
  var done = false;
  late T result;
  Object? error;
  action().then(
    (value) {
      result = value;
      done = true;
    },
    onError: (Object e) {
      error = e;
      done = true;
    },
  );
  await pumpUntil(tester, () => done);
  if (error != null) throw error!;
  return result;
}

/// The main scrollable of the top-most page (the first [Scrollable] under
/// the last [Scaffold]; text fields' own scrollables come later).
Finder topScrollable() => find
    .descendant(
      of: find.byType(Scaffold).last,
      matching: find.byType(Scrollable),
    )
    .first;
