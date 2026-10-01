import 'package:chronos/app/providers/providers.dart';
import 'package:chronos/app/shell.dart';
import 'package:chronos/app/startup/app_locale.dart';
import 'package:chronos/app/startup/home_shell.dart';
import 'package:chronos/app/startup/startup_gate.dart';
import 'package:chronos/core/format.dart';
import 'package:chronos/domain/app_settings.dart';
import 'package:chronos/features/onboarding/onboarding_page.dart';
import 'package:chronos/platform/notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'startup/app_harness.dart';

BuildContext _gateContext(WidgetTester tester) =>
    tester.element(find.byType(StartupGate));

void _deviceLocales(WidgetTester tester, List<Locale> locales) {
  tester.platformDispatcher.localesTestValue = locales;
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
}

int _selectedTab(WidgetTester tester) =>
    tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex;

void main() {
  group('locale resolution', () {
    test('keeps the device region when its language is supported', () {
      expect(
        resolveSupportedLocale(const [Locale('de', 'AT')]),
        const Locale('de', 'AT'),
      );
      expect(
        resolveSupportedLocale(const [Locale('fr', 'FR'), Locale('de', 'CH')]),
        const Locale('de', 'CH'),
      );
      expect(
        resolveSupportedLocale(const [Locale('en', 'GB')]),
        const Locale('en', 'GB'),
      );
    });

    test('falls back to English', () {
      expect(
        resolveSupportedLocale(const [Locale('fr', 'FR')]),
        const Locale('en'),
      );
      expect(resolveSupportedLocale(null), const Locale('en'));
      expect(resolveSupportedLocale(const []), const Locale('en'));
    });

    test('a chosen language borrows the device region', () {
      expect(
        localeForLanguage(AppLanguage.de, const [Locale('de', 'AT')]),
        const Locale('de', 'AT'),
      );
      expect(
        localeForLanguage(AppLanguage.de, const [Locale('en', 'US')]),
        const Locale('de'),
      );
      expect(
        localeForLanguage(AppLanguage.en, const [Locale('de', 'AT')]),
        const Locale('en'),
      );
      expect(
        localeForLanguage(AppLanguage.system, const [Locale('de', 'AT')]),
        const Locale('de', 'AT'),
      );
    });

    test('theme modes map to Flutter', () {
      expect(themeModeFor(AppThemeMode.system), ThemeMode.system);
      expect(themeModeFor(AppThemeMode.light), ThemeMode.light);
      expect(themeModeFor(AppThemeMode.dark), ThemeMode.dark);
    });
  });

  group('ChronosApp', () {
    testWidgets('an Austrian phone gets de_AT formats', (tester) async {
      _deviceLocales(tester, const [Locale('de', 'AT')]);
      final h = AppHarness();
      await pumpChronosApp(tester, h);
      final context = _gateContext(tester);
      expect(Localizations.localeOf(context), const Locale('de', 'AT'));
      expect(Fmt.of(context).localeName, 'de_AT');
      expect(find.text('Los geht’s'), findsOneWidget);
    });

    testWidgets('the first supported device language wins', (tester) async {
      _deviceLocales(tester, const [Locale('fr', 'FR'), Locale('de', 'DE')]);
      await pumpChronosApp(tester, AppHarness());
      expect(
        Localizations.localeOf(_gateContext(tester)),
        const Locale('de', 'DE'),
      );
    });

    testWidgets('unsupported device languages fall back to English', (
      tester,
    ) async {
      _deviceLocales(tester, const [Locale('fr', 'FR')]);
      await pumpChronosApp(tester, AppHarness());
      expect(Localizations.localeOf(_gateContext(tester)), const Locale('en'));
      expect(find.text('Get started'), findsOneWidget);
    });

    testWidgets('the language setting applies live and keeps the region', (
      tester,
    ) async {
      _deviceLocales(tester, const [Locale('de', 'AT')]);
      final h = AppHarness();
      await h.job();
      await pumpChronosApp(tester, h);
      expect(find.text('Heute'), findsOneWidget);

      await h.read(settingsProvider.notifier).setLanguage(AppLanguage.en);
      await settleApp(tester);
      expect(Localizations.localeOf(_gateContext(tester)), const Locale('en'));
      expect(find.text('Today'), findsOneWidget);

      await h.read(settingsProvider.notifier).setLanguage(AppLanguage.de);
      await settleApp(tester);
      expect(
        Localizations.localeOf(_gateContext(tester)),
        const Locale('de', 'AT'),
      );
      expect(find.text('Heute'), findsOneWidget);
    });

    testWidgets('theme mode switch applies', (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      final h = AppHarness();
      await pumpChronosApp(tester, h);
      Brightness brightness() => Theme.of(_gateContext(tester)).brightness;
      expect(brightness(), Brightness.light);

      await h.read(settingsProvider.notifier).setThemeMode(AppThemeMode.dark);
      await settleApp(tester);
      expect(brightness(), Brightness.dark);
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        ThemeMode.dark,
      );

      await h.read(settingsProvider.notifier).setThemeMode(AppThemeMode.system);
      await settleApp(tester);
      expect(brightness(), Brightness.light);
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      await settleApp(tester);
      expect(brightness(), Brightness.dark);
    });

    testWidgets('title and startup wiring', (tester) async {
      final h = AppHarness();
      await pumpChronosApp(tester, h);
      expect(tester.widget<Title>(find.byType(Title)).title, 'Chronos');
      expect(find.byType(OnboardingPage), findsOneWidget);
      // Notifications initialised after the first frame, once; the launch
      // notification checked once the start sequence finished.
      expect(h.notifications.inits, 1);
      expect(h.notifications.launchTapCalls, 1);
      // Old share files removed at start.
      expect(h.share.clears, 1);
    });
  });

  group('notification taps', () {
    testWidgets('a cold start from "Beenden" opens Today for the sheet', (
      tester,
    ) async {
      _deviceLocales(tester, const [Locale('de', 'DE')]);
      final h = AppHarness();
      final job = await h.job();
      await h.read(shiftRepositoryProvider).start(job.id);
      h.notifications.launch = const NotificationTap(
        notificationId: NotificationIds.runningShift,
        actionId: NotificationActionIds.finish,
      );
      await pumpChronosApp(tester, h);
      expect(find.byType(HomeShell), findsOneWidget);
      expect(_selectedTab(tester), ShellTab.today.index);
      // TodayPage handled the request: the finish sheet is open.
      expect(find.text('Schicht beenden'), findsOneWidget);
      expect(h.read(appRequestProvider), isNull);
    });

    testWidgets('taps while the app runs route to Today', (tester) async {
      _deviceLocales(tester, const [Locale('de', 'DE')]);
      final h = AppHarness();
      final job = await h.job();
      await h.read(shiftRepositoryProvider).start(job.id);
      await pumpChronosApp(tester, h);
      for (final tap in const [
        NotificationTap(notificationId: NotificationIds.runningShift),
        NotificationTap(
          notificationId: NotificationIds.runningShift,
          actionId: NotificationActionIds.finish,
        ),
      ]) {
        await tester.tap(find.text('Übersicht'));
        await tester.pumpAndSettle();
        expect(_selectedTab(tester), ShellTab.insights.index);

        h.notifications.onTap!(tap);
        await tester.pumpAndSettle();
        expect(_selectedTab(tester), ShellTab.today.index);
        expect(
          find.text('Schicht beenden'),
          tap.isFinish ? findsOneWidget : findsNothing,
        );
        if (tap.isFinish) {
          await tester.tap(find.text('Weiterlaufen lassen'));
          await tester.pumpAndSettle();
        }
      }
      expect(h.read(appRequestProvider), isNull);
    });

    testWidgets('the channel names follow the language setting', (
      tester,
    ) async {
      final h = AppHarness();
      await pumpChronosApp(tester, h);
      expect(
        h.notifications.channelTexts.single.runningShiftName,
        'Laufende Schicht',
      );
      await h.read(settingsProvider.notifier).setLanguage(AppLanguage.en);
      await settleApp(tester);
      expect(
        h.notifications.channelTexts.last.runningShiftName,
        'Running shift',
      );
    });
  });
}
