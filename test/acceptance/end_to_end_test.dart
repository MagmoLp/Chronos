// Acceptance: one walk through the whole app as a new user would do it, on
// the real ChronosApp (startup gate, shell, all three tabs, settings) with an
// in-memory database, a test clock and recording platform fakes.
//
// Fresh install → onboarding ("12,50") → start (permission primer) → pause /
// resume → finish with tips → Schichten (row, swipe paid + undo) → payout →
// Übersicht → CSV export → English → dark theme.

import 'package:chronos/app/providers/providers.dart';
import 'package:chronos/app/startup/home_shell.dart';
import 'package:chronos/core/format.dart';
import 'package:chronos/core/time.dart';
import 'package:chronos/domain/app_settings.dart';
import 'package:chronos/features/export/export_sheet.dart';
import 'package:chronos/features/onboarding/onboarding_page.dart';
import 'package:chronos/features/shifts/payout_sheet.dart';
import 'package:chronos/features/shifts/shift_texts.dart';
import 'package:chronos/features/shifts/shifts_page.dart';
import 'package:chronos/features/today/finish_shift_sheet.dart';
import 'package:chronos/features/today/notification_primer.dart';
import 'package:chronos/l10n/app_localizations.dart';
import 'package:chronos/platform/share_service.dart';
import 'package:chronos/widgets/rolling_amount.dart';
import 'package:chronos/widgets/stat_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../app/startup/app_harness.dart';
import '../features/insights/seed.dart' show pumpUntil, tapVisible;

final AppLocalizations _de = l10nFor(const Locale('de'));
final AppLocalizations _en = l10nFor(const Locale('en'));
final Fmt _fmt = Fmt(const Locale('de', 'DE'));

/// Non-breaking space between amount and "€" in German.
const String _nb = ' ';

Finder _nav(String label) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

Finder _snack(String text) =>
    find.descendant(of: find.byType(SnackBar), matching: find.text(text));

/// The value shown on the Übersicht card labelled [label].
Finder _card(String label, String value) => find.descendant(
  of: find.ancestor(of: find.text(label), matching: find.byType(StatCard)),
  matching: find.text(value),
);

/// The big amount on the Today card, in cents.
int _heroCents(WidgetTester tester) =>
    tester.widget<RollingAmount>(find.byType(RollingAmount).first).cents!;

String _text(WidgetTester tester, Key key) =>
    tester.widget<Text>(find.byKey(key)).data!;

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await settleApp(tester);
}

/// Moves the test clock and lets the live tickers catch up (the amount
/// ticks when the next cent is due: every 2,88 s at 12,50 €/h).
Future<void> _advance(AppHarness h, WidgetTester tester, Duration by) async {
  h.clock.advance(by);
  for (var i = 0; i < 3; i++) {
    await tester.pump(const Duration(seconds: 1));
  }
}

void main() {
  testWidgets('fresh install to export, language and theme', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('de', 'DE')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    // A German phone uses the 24-hour clock.
    tester.platformDispatcher.alwaysUse24HourFormatTestValue = true;
    addTearDown(tester.platformDispatcher.clearAlwaysUse24HourTestValue);

    final h = AppHarness();
    // A fresh Android 13+ install: notifications are not allowed yet.
    h.notifications.enabled = false;
    await pumpChronosApp(tester, h);

    // ---------------------------------------------------- onboarding --
    expect(find.byType(OnboardingPage), findsOneWidget);
    await tester.tap(find.text(_de.onboardingStart));
    await tester.pumpAndSettle();
    expect(find.text(_de.onboardingJobTitle), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, _de.onboardingRateLabel),
      '12,50',
    );
    await tester.tap(find.text(_de.commonDone));
    await settleApp(tester);

    expect(find.byType(HomeShell), findsOneWidget);
    final job = (await h.read(jobRepositoryProvider).getJobs()).single;
    expect(job.name, 'Mein Job');
    // v1 bug D1: "12,50" is 12,50 €/h, not 1250 €/h.
    expect(
      (await h.read(jobRepositoryProvider).getRates(job.id))
          .single
          .centsPerHour,
      1250,
    );
    // Language and theme follow the system.
    expect(h.read(settingsProvider).language, AppLanguage.system);
    expect(h.read(settingsProvider).themeMode, AppThemeMode.system);

    // ------------------------------------------------- start a shift --
    expect(find.text(_fmt.todayTitle(kAppNow.toLocal())), findsOneWidget);
    expect(find.text(_de.todayOpenLabel), findsOneWidget);
    expect(_heroCents(tester), 0);

    await tester.tap(find.text(_de.todayStartShift));
    await tester.pumpAndSettle();
    // First start: the permission is explained, then asked for.
    expect(find.byType(NotificationPrimerSheet), findsOneWidget);
    await tester.tap(find.text(_de.todayPrimerAllow));
    await settleApp(tester);
    expect(h.notifications.permissionRequests, 1);

    final start = (await h.read(shiftRepositoryProvider).getRunning())!;
    expect(start.startUtc, kAppNow);
    expect(start.rateCentsPerHour, 1250);
    expect(find.text(_de.statusRunning), findsOneWidget);
    expect(find.text(_de.todayEarnedToday), findsOneWidget);
    // The running notification and the 10 h reminder (default).
    expect(h.notifications.posted.last.title, _de.notificationRunningTitle);
    expect(h.notifications.posted.last.body, contains(_fmt.rate(1250)));
    expect(h.notifications.posted.last.paused, isFalse);
    expect(
      h.notifications.scheduled.last.at,
      kAppNow.add(const Duration(hours: 10)),
    );

    // ------------------------------------------ work, pause, resume --
    await _advance(h, tester, const Duration(hours: 2));
    expect(_text(tester, const ValueKey<String>('today-worked')), '2:00:00');
    expect(_heroCents(tester), 2500);

    await tester.tap(find.text(_de.todayPause));
    await settleApp(tester);
    expect(h.notifications.posted.last.paused, isTrue);
    final pausedAt = h.clock.now.toLocal();
    expect(
      find.text(_de.todayPausedSince(_fmt.time(pausedAt))),
      findsOneWidget,
    );
    // Paused: the time stands still.
    await _advance(h, tester, const Duration(minutes: 30));
    expect(_text(tester, const ValueKey<String>('today-worked')), '2:00:00');
    expect(_heroCents(tester), 2500);

    await tester.tap(find.text(_de.todayResume));
    await settleApp(tester);
    expect(h.notifications.posted.last.paused, isFalse);
    await _advance(h, tester, const Duration(hours: 2));
    expect(_text(tester, const ValueKey<String>('today-worked')), '4:00:00');
    expect(_heroCents(tester), 5000);

    // ------------------------------------------- finish with tips --
    await tester.tap(find.text(_de.todayFinish));
    await settleApp(tester);
    expect(find.byType(FinishShiftSheet), findsOneWidget);
    expect(_text(tester, const ValueKey<String>('finish-worked')), '4:00 h');
    expect(
      _text(tester, const ValueKey<String>('finish-amount')),
      '50,00$_nb€',
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('finish-tips')),
      '5,00',
    );
    await _tap(tester, find.text(_de.commonSave));

    expect(find.byType(FinishShiftSheet), findsNothing);
    expect(_snack('Schicht gespeichert · 4:00 h · 50,00$_nb€'), findsOneWidget);
    final saved = (await h.read(shiftRepositoryProvider).lastDone())!;
    expect(saved.workedMs, 4 * msPerHour);
    expect(saved.breakMs, 30 * msPerMinute);
    expect(saved.amountCents, 5000);
    expect(saved.tipsCents, 500);
    expect(saved.isPaid, isFalse);
    expect(await h.read(shiftRepositoryProvider).getRunning(), isNull);
    // Notification and reminder are gone with the running shift.
    expect(h.notifications.cancelled, greaterThan(0));
    expect(h.notifications.remindersCancelled, greaterThan(0));
    // Today now shows today's pay ("Verdient" is without tips).
    expect(find.text(_de.todayEarnedToday), findsOneWidget);
    expect(_heroCents(tester), 5000);

    // ------------------------------------------------- Schichten --
    await tester.tap(_nav(_de.navShifts));
    await settleApp(tester);
    final texts = ShiftTexts(_de, _fmt);
    final row = find.byKey(ValueKey<int>(saved.id));
    expect(row, findsOneWidget);
    expect(
      find.descendant(of: row, matching: find.text(texts.title(saved))),
      findsOneWidget,
    );
    expect(
      find.descendant(of: row, matching: find.text('50,00$_nb€')),
      findsOneWidget,
    );
    expect(find.text('Pause 30 min · Trinkgeld 5,00$_nb€'), findsOneWidget);
    expect(find.text('September 2026'), findsOneWidget);
    expect(find.text('4 h · 50,00$_nb€ · 50,00$_nb€ offen'), findsOneWidget);
    expect(
      find.descendant(of: row, matching: find.byIcon(Icons.schedule)),
      findsOneWidget,
    );

    // Swipe right: paid, with undo.
    await tester.drag(row, const Offset(500, 0));
    await settleApp(tester);
    expect(_snack(_de.shiftsMarkedPaid), findsOneWidget);
    expect(
      (await h.read(shiftRepositoryProvider).getById(saved.id))!.isPaid,
      isTrue,
    );
    expect(
      find.descendant(of: row, matching: find.byIcon(Icons.check_circle)),
      findsOneWidget,
    );
    await tester.tap(find.text(_de.commonUndo));
    await settleApp(tester);
    expect(
      (await h.read(shiftRepositoryProvider).getById(saved.id))!.isPaid,
      isFalse,
    );
    expect(
      find.descendant(of: row, matching: find.byIcon(Icons.schedule)),
      findsOneWidget,
    );

    // ---------------------------------------------- record a payout --
    await tester.tap(find.byKey(ShiftsPageKeys.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_de.payoutTitle));
    await settleApp(tester);
    expect(find.byKey(PayoutSheetKeys.sheet), findsOneWidget);
    expect(_text(tester, PayoutSheetKeys.summary), '1 Schicht · 4 h');
    expect(_text(tester, PayoutSheetKeys.expected), '50,00$_nb€');
    expect(_text(tester, PayoutSheetKeys.difference), '0,00$_nb€');
    await _tap(tester, find.text(_de.payoutSubmit(1)));

    expect(find.byKey(PayoutSheetKeys.sheet), findsNothing);
    expect(_snack(_de.payoutRecorded(1)), findsOneWidget);
    final payout = (await h.read(payoutRepositoryProvider).getPayouts()).single;
    expect(payout.expectedCents, 5000);
    expect(payout.receivedCents, 5000);
    final paid = (await h.read(shiftRepositoryProvider).getById(saved.id))!;
    expect(paid.isPaid, isTrue);
    expect(paid.payoutId, payout.id);
    expect(find.text('4 h · 50,00$_nb€'), findsOneWidget);

    // --------------------------------------------------- Übersicht --
    await tester.tap(_nav(_de.navInsights));
    await settleApp(tester);
    expect(find.text('September 2026'), findsOneWidget);
    expect(_card(_de.insightsStatHours, '4 h'), findsOneWidget);
    expect(_card(_de.insightsStatEarned, '50,00$_nb€'), findsOneWidget);
    expect(_card(_de.insightsStatOpen, '0,00$_nb€'), findsOneWidget);
    // (50,00 € + 5,00 € tips) / 4 h.
    expect(_card(_de.insightsStatAverage, '13,75$_nb€'), findsOneWidget);
    expect(_card(_de.insightsStatTips, '5,00$_nb€'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text(_de.insightsPayoutExact),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text(_de.insightsPayoutExact), findsOneWidget);

    // ------------------------------------------------- CSV export --
    await tester.tap(_nav(_de.navShifts));
    await settleApp(tester);
    await tester.tap(find.byKey(ShiftsPageKeys.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_de.exportTitle));
    await settleApp(tester);
    expect(find.byType(ExportSheet), findsOneWidget);
    await tester.tap(find.text(_de.exportFormatCsv));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text(_de.commonShare));
    await pumpUntil(tester, () => h.share.sharedFiles.isNotEmpty);

    final shared = h.share.sharedFiles.single;
    expect(shared.mimeType, ShareMimeTypes.csv);
    expect(shared.path, endsWith('.csv'));
    final csv = h.share.savedTexts.values.single;
    // Excel-DE: semicolons and decimal commas.
    expect(csv, startsWith('Datum;Start;Ende;Pause (min);Stunden;'));
    expect(csv, contains('30.09.2026;'));
    expect(csv, contains(';30;4,00;12,50;50,00;5,00;Bezahlt;Mein Job'));
    expect(find.byType(ExportSheet), findsNothing);

    // ------------------------------------------- English, dark --
    await tester.tap(_nav(_de.navToday));
    await settleApp(tester);
    await tester.tap(find.byTooltip(_de.commonSettings));
    await settleApp(tester);
    expect(find.text(_de.settingsSectionGeneral), findsOneWidget);

    await tester.tap(find.text(_de.settingsLanguageEnglish));
    await settleApp(tester);
    expect(h.read(settingsProvider).language, AppLanguage.en);
    expect(find.text(_en.commonSettings), findsOneWidget);
    expect(find.text(_en.settingsSectionGeneral), findsOneWidget);
    expect(find.text(_de.settingsSectionGeneral), findsNothing);
    // The notification channels follow the app language.
    expect(h.notifications.channelTexts.last.runningShiftName, 'Running shift');

    BuildContext context() => tester.element(find.byType(Scaffold).last);
    expect(Theme.of(context()).brightness, Brightness.light);
    await _tap(tester, find.text(_en.settingsThemeDark));
    expect(h.read(settingsProvider).themeMode, AppThemeMode.dark);
    expect(Theme.of(context()).brightness, Brightness.dark);

    await tester.tap(find.byType(BackButton));
    await settleApp(tester);
    for (final label in [_en.navToday, _en.navShifts, _en.navInsights]) {
      expect(_nav(label), findsOneWidget);
    }
    expect(_nav(_de.navInsights), findsNothing);
    expect(
      find.text(Fmt(const Locale('en')).todayTitle(kAppNow.toLocal())),
      findsOneWidget,
    );
    expect(find.text(_en.todayEarnedToday), findsOneWidget);
    expect(Theme.of(context()).brightness, Brightness.dark);
  });
}
