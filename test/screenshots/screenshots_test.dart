// Renders README screenshots with real fonts. Not part of the normal suite:
//   CHRONOS_SCREENSHOTS=1 TZ=Europe/Berlin flutter test --update-goldens test/screenshots
@Tags(['screenshots'])
library;

import 'dart:io';

import 'package:chronos/app/app.dart';
import 'package:chronos/app/providers/providers.dart';
import 'package:chronos/core/local_date.dart';
import 'package:chronos/domain/app_settings.dart';
import 'package:chronos/domain/job.dart';
import 'package:chronos/domain/shift_draft.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../app/startup/app_harness.dart';

final bool _enabled = Platform.environment['CHRONOS_SCREENSHOTS'] == '1';

/// Wed 30 Sep 2026, 13:13 in Berlin.
final DateTime _now = DateTime.utc(2026, 9, 30, 11, 13);

Future<AppHarness> _seed({bool running = true, bool data = true}) async {
  final h = AppHarness(now: _now);
  if (!data) return h;
  final cafe = await h.job(name: 'Catering Müller', centsPerHour: 1500);
  final hall = await h.job(name: 'Eventhalle', centsPerHour: 1420);
  Future<void> add(
    Job j,
    int day,
    int s,
    int e, {
    int brk = 0,
    int tips = 0,
    String? note,
    int month = 9,
  }) => h
      .read(shiftRepositoryProvider)
      .insertManual(
        ShiftDraft.fromLocal(
          jobId: j.id,
          date: LocalDate(2026, month, day),
          startHour: s,
          startMinute: 0,
          endHour: e % 24,
          endMinute: 0,
          endsNextDay: e >= 24,
          breakMs: brk * 60000,
          tipsCents: tips,
          note: note,
        ),
      );
  for (final d in [3, 5, 6, 10, 12, 13]) {
    await add(cafe, d, 8, 16, brk: 30, month: 8);
  }
  await add(cafe, 1, 8, 16, brk: 30);
  await add(hall, 2, 17, 23, tips: 2000, note: 'Firmenfeier');
  await add(cafe, 4, 9, 17, brk: 30);
  await add(cafe, 8, 8, 14);
  await add(hall, 12, 18, 26, tips: 3500, note: 'Hochzeit Schloss');
  await add(cafe, 15, 8, 16, brk: 30);
  await add(cafe, 18, 10, 18, brk: 30, tips: 500);
  await add(hall, 20, 16, 23, tips: 1500);
  await add(cafe, 22, 8, 16, brk: 30);
  await add(cafe, 25, 8, 15);
  await add(hall, 26, 17, 24, tips: 2500, note: 'Gala');
  await add(cafe, 29, 8, 16, brk: 30);
  await h
      .read(payoutControllerProvider.notifier)
      .create(
        until: LocalDate(2026, 8, 31),
        jobId: cafe.id,
        receivedCents: 34500,
        paidOn: LocalDate(2026, 9, 5),
      );
  final settings = h.read(settingsProvider.notifier);
  await settings.setNotificationPrimerShown(true);
  await settings.setMonthlyGoal(60300, type: MonthlyGoalType.limit);
  if (running) {
    await h
        .read(shiftRepositoryProvider)
        .start(cafe.id, startUtc: DateTime.utc(2026, 9, 30, 6, 2));
  }
  return h;
}

Future<void> _pump(
  WidgetTester tester,
  AppHarness h, {
  Size size = const Size(412, 915),
  Brightness brightness = Brightness.light,
}) async {
  tester.platformDispatcher.localesTestValue = const [Locale('de', 'DE')];
  tester.platformDispatcher.platformBrightnessTestValue = brightness;
  tester.platformDispatcher.alwaysUse24HourFormatTestValue = true;
  addTearDown(tester.platformDispatcher.clearAllTestValues);
  tester.view
    ..devicePixelRatio = 2
    ..physicalSize = size * 2;
  addTearDown(tester.view.reset);
  // Real shadows instead of the test framework's black outlines.
  debugDisableShadows = false;
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: h.container,
      child: const ChronosApp(),
    ),
  );
  await settleApp(tester);
}

Future<void> _shot(String name) async {
  try {
    await expectLater(
      find.byType(ChronosApp),
      matchesGoldenFile('../../docs/screenshots/$name.png'),
    );
  } finally {
    debugDisableShadows = true;
  }
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('today running light', (tester) async {
    await _pump(tester, await _seed());
    await _shot('heute_hell');
  }, skip: !_enabled);

  testWidgets('today running dark', (tester) async {
    await _pump(tester, await _seed(), brightness: Brightness.dark);
    await _shot('heute_dunkel');
  }, skip: !_enabled);

  testWidgets('finish sheet', (tester) async {
    await _pump(tester, await _seed());
    await tester.tap(find.text('Beenden'));
    await settleApp(tester);
    await _shot('schicht_beenden');
  }, skip: !_enabled);

  testWidgets('shifts', (tester) async {
    await _pump(tester, await _seed());
    await tester.tap(find.text('Schichten'));
    await settleApp(tester);
    await _shot('schichten');
  }, skip: !_enabled);

  testWidgets('editor', (tester) async {
    await _pump(tester, await _seed());
    await tester.tap(find.text('Schichten'));
    await settleApp(tester);
    await tester.tap(find.byType(FloatingActionButton));
    await settleApp(tester);
    await _shot('schicht_editor');
  }, skip: !_enabled);

  testWidgets('insights', (tester) async {
    await _pump(tester, await _seed());
    await tester.tap(find.text('Übersicht'));
    await settleApp(tester);
    await _shot('uebersicht');
  }, skip: !_enabled);

  testWidgets('settings', (tester) async {
    await _pump(tester, await _seed());
    await tester.tap(find.byTooltip('Einstellungen').first);
    await settleApp(tester);
    await _shot('einstellungen');
  }, skip: !_enabled);

  testWidgets('landscape', (tester) async {
    await _pump(tester, await _seed(), size: const Size(915, 412));
    await _shot('heute_quer');
  }, skip: !_enabled);

  testWidgets('tablet', (tester) async {
    await _pump(tester, await _seed(), size: const Size(1280, 800));
    await _shot('heute_tablet');
  }, skip: !_enabled);

  testWidgets('onboarding', (tester) async {
    await _pump(tester, await _seed(data: false));
    await _shot('onboarding');
  }, skip: !_enabled);
}
