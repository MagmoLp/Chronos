import 'dart:ui' show Locale, PluginUtilities;

import 'package:chronos/app/notifications/background_actions.dart';
import 'package:chronos/app/notifications/notification_texts.dart';
import 'package:chronos/core/format.dart';
import 'package:chronos/domain/app_settings.dart';
import 'package:chronos/domain/shift.dart';
import 'package:chronos/platform/notifications.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fixtures/db.dart';
import '../startup/app_harness.dart';

final DateTime _now = DateTime.utc(2026, 9, 30, 8);
final DateTime _start = DateTime.utc(2026, 9, 30, 6, 2);

final NotificationTexts _german = NotificationTexts.forLanguage(
  AppLanguage.de,
  deviceLocales: const [Locale('de', 'DE')],
  use24HourFormat: true,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DataHarness d;
  late RecordingNotificationService notifications;

  setUp(() {
    d = DataHarness(_now);
    notifications = RecordingNotificationService();
  });

  Future<NotificationActionOutcome> act(String actionId, String? payload) =>
      handleNotificationAction(
        actionId: actionId,
        payload: payload,
        db: d.db,
        notifications: notifications,
        texts: _german,
        clock: d.clock.clock,
      );

  Future<Shift> startShift() async {
    final job = await d.job();
    return d.shifts.start(job.id, startUtc: _start);
  }

  test('"Pause" pauses the shift and re-posts once', () async {
    final shift = await startShift();
    expect(
      await act(NotificationActionIds.pause, '${shift.id}'),
      NotificationActionOutcome.paused,
    );
    final running = await d.shifts.getRunning();
    expect(running!.isPaused, isTrue);
    expect(running.pausedAtUtc, _now);

    expect(notifications.posted, hasLength(1));
    final post = notifications.posted.single;
    expect(post.paused, isTrue);
    expect(
      post.body,
      'Pausiert seit ${Fmt(const Locale('de')).time(_now.toLocal())}',
    );
    expect(post.title, 'Schicht läuft');
    expect(post.payload, '${shift.id}');
    // The reminder only depends on the start: untouched.
    expect(notifications.scheduled, isEmpty);
    expect(notifications.remindersCancelled, 0);
  });

  test('"Fortsetzen" resumes it; the pause becomes break time', () async {
    final shift = await startShift();
    await act(NotificationActionIds.pause, '${shift.id}');
    d.clock.advance(const Duration(minutes: 20));
    notifications.clearRecords();

    expect(
      await act(NotificationActionIds.resume, '${shift.id}'),
      NotificationActionOutcome.resumed,
    );
    final running = await d.shifts.getRunning();
    expect(running!.isPaused, isFalse);
    expect(running.breakMs, const Duration(minutes: 20).inMilliseconds);
    final post = notifications.posted.single;
    expect(post.paused, isFalse);
    expect(post.body, startsWith('seit '));
    expect(post.workedSoFar, _now.difference(_start));
  });

  test(
    'a stale notification (other shift) changes nothing in the database',
    () async {
      final shift = await startShift();
      final before = await d.shifts.getRunning();
      expect(
        await act(NotificationActionIds.pause, '${shift.id + 99}'),
        NotificationActionOutcome.stale,
      );
      expect(await d.shifts.getRunning(), before);
      // The notification is brought in line with the actually running shift.
      expect(notifications.posted.single.payload, '${shift.id}');
      expect(notifications.posted.single.paused, isFalse);
    },
  );

  test('a stale notification without a running shift is removed', () async {
    final shift = await startShift();
    await d.shifts.finish(endUtc: _now);
    expect(
      await act(NotificationActionIds.pause, '${shift.id}'),
      NotificationActionOutcome.stale,
    );
    expect(await d.shifts.getRunning(), isNull);
    expect(notifications.posted, isEmpty);
    expect(notifications.cancelled, 1);
    expect(notifications.remindersCancelled, 1);
    final finished = await d.shifts.getById(shift.id);
    expect(finished!.isPaused, isFalse);
    expect(finished.status, ShiftStatus.done);
  });

  test('a broken payload is treated as stale', () async {
    await startShift();
    for (final payload in [null, '', 'abc']) {
      expect(
        await act(NotificationActionIds.pause, payload),
        NotificationActionOutcome.stale,
      );
    }
    expect((await d.shifts.getRunning())!.isPaused, isFalse);
  });

  test('"Beenden" is not a background action', () async {
    final shift = await startShift();
    expect(
      await act(NotificationActionIds.finish, '${shift.id}'),
      NotificationActionOutcome.ignored,
    );
    expect(notifications.postingCalls, 0);
  });

  test('uses the job name when there are several jobs', () async {
    await d.job(name: 'Bar');
    final shift = await startShift();
    await act(NotificationActionIds.pause, '${shift.id}');
    expect(notifications.posted.single.title, 'Schicht läuft · Catering');
  });

  test('English texts', () async {
    final shift = await startShift();
    await handleNotificationAction(
      actionId: NotificationActionIds.pause,
      payload: '${shift.id}',
      db: d.db,
      notifications: notifications,
      texts: NotificationTexts.forLanguage(
        AppLanguage.system,
        deviceLocales: const [Locale('en', 'US')],
        use24HourFormat: false,
      ),
      clock: d.clock.clock,
    );
    expect(notifications.posted.single.title, 'Shift running');
    expect(notifications.posted.single.body, startsWith('Paused since '));
    expect(notifications.posted.single.resumeLabel, 'Resume');
  });

  test('the entry point can be registered as background handler', () {
    expect(
      PluginUtilities.getCallbackHandle(chronosNotificationAction),
      isNotNull,
    );
    NotificationService.registerBackgroundHandler(chronosNotificationAction);
    expect(NotificationService.backgroundHandlerHandle, isNotNull);
    NotificationService.resetForTesting();
  });
}
