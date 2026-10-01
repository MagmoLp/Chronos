import 'package:chronos/app/notifications/app_notifications.dart';
import 'package:chronos/app/notifications/background_actions.dart';
import 'package:chronos/app/providers/providers.dart';
import 'package:chronos/domain/app_settings.dart';
import 'package:chronos/platform/notifications.dart';
import 'package:flutter_test/flutter_test.dart';

import '../startup/app_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('init', () {
    test(
      'once, with German channel names and the background handler',
      () async {
        final h = AppHarness();
        final app = h.read(appNotificationsProvider);
        final results = await Future.wait([
          app.ensureInitialized(),
          app.ensureInitialized(),
        ]);
        expect(results, [true, true]);
        final n = h.notifications;
        expect(n.inits, 1);
        expect(n.channelTexts.single.runningShiftName, 'Laufende Schicht');
        expect(n.channelTexts.single.remindersName, 'Erinnerungen');
        expect(n.onTap, isNotNull);
        expect(n.backgroundHandler, same(chronosNotificationAction));
      },
    );

    test('channel names follow a language change, once per change', () async {
      final h = AppHarness();
      await h.read(settingsRepositoryProvider.future);
      final app = h.read(appNotificationsProvider);

      // Before init nothing is renamed (init will use the current language).
      await app.refreshChannelTexts();
      expect(h.notifications.channelTexts, isEmpty);

      await app.ensureInitialized();
      await app.refreshChannelTexts();
      expect(h.notifications.channelTexts, hasLength(1), reason: 'unchanged');

      await h.read(settingsProvider.notifier).setLanguage(AppLanguage.en);
      await app.refreshChannelTexts();
      expect(h.notifications.channelTexts, hasLength(2));
      expect(
        h.notifications.channelTexts.last.runningShiftName,
        'Running shift',
      );
      expect(h.notifications.channelTexts.last.remindersName, 'Reminders');
    });
  });

  group('taps', () {
    test('a tap on the notification shows Today', () async {
      final h = AppHarness();
      await h.read(appNotificationsProvider).ensureInitialized();
      h.notifications.onTap!(const NotificationTap(notificationId: 1));
      expect(h.read(appRequestProvider)?.kind, AppRequestKind.showToday);
    });

    test('"Beenden" opens the finish sheet', () async {
      final h = AppHarness();
      await h.read(appNotificationsProvider).ensureInitialized();
      h.notifications.onTap!(
        const NotificationTap(
          notificationId: 1,
          actionId: NotificationActionIds.finish,
          payload: '1',
        ),
      );
      expect(h.read(appRequestProvider)?.kind, AppRequestKind.openFinishSheet);
    });

    test('"Beenden" on the reminder also opens the finish sheet', () async {
      final h = AppHarness();
      h
          .read(appNotificationsProvider)
          .handleTap(
            const NotificationTap(
              notificationId: NotificationIds.reminder,
              actionId: NotificationActionIds.finish,
            ),
          );
      expect(h.read(appRequestProvider)?.kind, AppRequestKind.openFinishSheet);
    });

    test('Pause/Fortsetzen reaching the app are applied', () async {
      final h = AppHarness();
      final job = await h.job();
      await h.read(activeShiftControllerProvider.notifier).start(job.id);
      final app = h.read(appNotificationsProvider);

      app.handleTap(
        const NotificationTap(actionId: NotificationActionIds.pause),
      );
      await eventually(
        () async =>
            !h.read(activeShiftControllerProvider) &&
            (await h.read(shiftRepositoryProvider).getRunning())!.isPaused,
      );
      app.handleTap(
        const NotificationTap(actionId: NotificationActionIds.resume),
      );
      await eventually(
        () async =>
            !(await h.read(shiftRepositoryProvider).getRunning())!.isPaused,
      );
      expect(h.read(appRequestProvider), isNull);
    });

    test('Pause without a running shift is ignored', () async {
      final h = AppHarness();
      h
          .read(appNotificationsProvider)
          .handleTap(
            const NotificationTap(actionId: NotificationActionIds.pause),
          );
      await pumpEventQueue();
      expect(await h.read(shiftRepositoryProvider).getRunning(), isNull);
    });
  });

  group('cold start', () {
    test('the launching "Beenden" opens the finish sheet, only once', () async {
      final h = AppHarness();
      h.notifications.launch = const NotificationTap(
        notificationId: 1,
        actionId: NotificationActionIds.finish,
      );
      final app = h.read(appNotificationsProvider);
      await app.checkLaunchTap();
      await app.checkLaunchTap();
      expect(h.notifications.launchTapCalls, 1);
      expect(h.read(appRequestProvider)?.kind, AppRequestKind.openFinishSheet);
      expect(h.notifications.inits, 1);
    });

    test('a launching tap on the body shows Today', () async {
      final h = AppHarness();
      h.notifications.launch = const NotificationTap(notificationId: 1);
      await h.read(appNotificationsProvider).checkLaunchTap();
      expect(h.read(appRequestProvider)?.kind, AppRequestKind.showToday);
    });

    test('a normal start posts no request', () async {
      final h = AppHarness();
      await h.read(appNotificationsProvider).checkLaunchTap();
      expect(h.read(appRequestProvider), isNull);
    });
  });
}

/// Polls [condition] until it holds.
Future<void> eventually(Future<bool> Function() condition) async {
  for (var i = 0; i < 50; i++) {
    if (await condition()) return;
    await pumpEventQueue();
  }
  fail('condition not met');
}
