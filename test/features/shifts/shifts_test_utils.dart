import 'package:chronos/app/providers/providers.dart';
import 'package:chronos/app/shell.dart';
import 'package:chronos/core/format.dart';
import 'package:chronos/core/local_date.dart';
import 'package:chronos/core/time.dart';
import 'package:chronos/domain/job.dart';
import 'package:chronos/domain/shift.dart';
import 'package:chronos/domain/shift_draft.dart';
import 'package:chronos/features/shifts/shifts_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/feature_harness.dart';

export '../../support/feature_harness.dart';

/// "Now" for most Shifts tests: Wed 30 Sep 2026, 20:00 local time (in any
/// time zone), so shifts earlier today are in the past.
final DateTime kShiftsNow = DateTime(2026, 9, 30, 20).toUtc();

/// Today in the Shifts tests.
final LocalDate kToday = LocalDate(2026, 9, 30);

/// German formatter as the tests' default locale uses it.
final Fmt fmtDe = Fmt(const Locale('de'));

/// English formatter (12-hour clock, like the tests' English default).
final Fmt fmtEn = Fmt(const Locale('en'), use24HourFormat: false);

/// Inserts a finished shift from local wall-clock values.
Future<Shift> addShift(
  ProviderHarness h,
  Job job,
  LocalDate date,
  ({int h, int m}) start,
  ({int h, int m}) end, {
  bool? nextDay,
  int breakMinutes = 0,
  int tipsCents = 0,
  String? note,
  bool paid = false,
}) => h
    .read(shiftRepositoryProvider)
    .insertManual(
      ShiftDraft.fromLocal(
        jobId: job.id,
        date: date,
        startHour: start.h,
        startMinute: start.m,
        endHour: end.h,
        endMinute: end.m,
        endsNextDay: nextDay,
        breakMs: breakMinutes * msPerMinute,
        tipsCents: tipsCents,
        note: note,
        paid: paid,
      ),
    );

/// All non-deleted finished shifts, newest first.
Future<List<Shift>> doneShifts(FeatureHarness f) =>
    f.read(shiftRepositoryProvider).getDone();

/// The Shifts page inside an [AdaptiveShell] that starts on the Shifts tab.
Widget shellWithShifts(ShellController controller) => AdaptiveShell(
  controller: controller,
  todayBuilder: (_) => const Scaffold(body: Center(child: Text('TODAY-PAGE'))),
  shiftsBuilder: (_) => const ShiftsPage(),
  insightsBuilder: (_) => const Scaffold(body: SizedBox.shrink()),
);

/// [settleData] plus one more pump, so timers that closing database
/// streams schedule (drift closes them on a zero timer when an auto-dispose
/// provider goes away) have run before the test ends.
Future<void> settle(WidgetTester tester) async {
  await settleData(tester);
  await tester.pump(const Duration(milliseconds: 1));
  await tester.pumpAndSettle();
}

/// Commits typed text of the focused field (like leaving the field).
Future<void> blur(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pump();
}

/// The text input inside the widget with [key] (TimeField, MoneyField, …).
Finder inputOf(Key key) =>
    find.descendant(of: find.byKey(key), matching: find.byType(EditableText));

/// Types [text] into the field with [key] and leaves the field.
Future<void> typeInto(WidgetTester tester, Key key, String text) async {
  await tester.ensureVisible(find.byKey(key));
  await tester.pumpAndSettle();
  await tester.enterText(inputOf(key), text);
  await blur(tester);
  await settle(tester);
}
