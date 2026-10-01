import 'package:chronos/app/notifications/notification_side_effects.dart';
import 'package:chronos/app/providers/providers.dart';
import 'package:chronos/core/format.dart';
import 'package:chronos/domain/app_settings.dart';
import 'package:chronos/domain/job.dart';
import 'package:chronos/domain/shift.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../startup/app_harness.dart';

/// 08:02 in Berlin on the test day (06:02 UTC).
final DateTime _start = DateTime.utc(2026, 9, 30, 6, 2);

final Fmt _de = Fmt(const Locale('de', 'DE'));
final Fmt _en = Fmt(const Locale('en', 'US'), use24HourFormat: false);

Future<(Shift, Job)> _running(AppHarness h, {Job? job}) async {
  final j = job ?? await h.job();
  final shift = await h
      .read(shiftRepositoryProvider)
      .start(j.id, startUtc: _start);
  return (shift, j);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the app wires the notification side effects in', () {
    final h = AppHarness();
    expect(h.read(shiftSideEffectsProvider), isA<NotificationSideEffects>());
  });

  group('running shift', () {
    test('posts once: title, "seit 08:02 · 15,00 €/h", stopwatch, actions, '
        'reminder', () async {
      final h = AppHarness();
      await h.read(settingsRepositoryProvider.future);
      final (shift, job) = await _running(h);

      await h.read(shiftSideEffectsProvider).shiftChanged(shift, job);

      final n = h.notifications;
      expect(n.inits, 1);
      expect(n.posted, hasLength(1));
      final post = n.posted.single;
      expect(post.title, 'Schicht läuft');
      expect(post.body, 'seit ${_de.time(_start.toLocal())} · 15,00\u00A0€/h');
      expect(post.paused, isFalse);
      expect(post.pauseLabel, 'Pause');
      expect(post.resumeLabel, 'Fortsetzen');
      expect(post.finishLabel, 'Beenden');
      expect(
        post.workedSoFar,
        h.clock.now.difference(_start),
        reason: 'stopwatch starts at the worked time so far',
      );
      expect(post.payload, '${shift.id}');

      expect(n.scheduled, hasLength(1));
      final reminder = n.scheduled.single;
      expect(reminder.at, _start.add(const Duration(hours: 10)));
      expect(reminder.title, 'Arbeitest du noch?');
      expect(reminder.body, contains(_de.time(_start.toLocal())));
      expect(reminder.finishLabel, 'Beenden');
      expect(reminder.payload, '${shift.id}');
      expect(n.cancelled, 0);
      expect(n.remindersCancelled, 0);
    });

    test('adds the job name when there is more than one job', () async {
      final h = AppHarness();
      await h.job(name: 'Bar');
      final (shift, job) = await _running(h);
      await h.read(shiftSideEffectsProvider).shiftChanged(shift, job);
      expect(h.notifications.posted.single.title, 'Schicht läuft · Catering');
    });

    test('paused: "Pausiert seit 14:32", no stopwatch progress', () async {
      final h = AppHarness();
      final (shift, job) = await _running(h);
      final pauseAt = _start.add(const Duration(hours: 1));
      final paused = await h
          .read(shiftRepositoryProvider)
          .pause(atUtc: pauseAt);

      await h.read(shiftSideEffectsProvider).shiftChanged(paused, job);

      final post = h.notifications.posted.single;
      expect(post.paused, isTrue);
      expect(post.body, 'Pausiert seit ${_de.time(pauseAt.toLocal())}');
      expect(post.workedSoFar, const Duration(hours: 1));
      expect(post.payload, '${shift.id}');
    });

    test('no shift: notification and reminder are removed', () async {
      final h = AppHarness();
      await h.read(shiftSideEffectsProvider).shiftChanged(null, null);
      final n = h.notifications;
      expect(n.cancelled, 1);
      expect(n.remindersCancelled, 1);
      expect(n.posted, isEmpty);
      expect(n.scheduled, isEmpty);
    });
  });

  group('language', () {
    test('English app language, 12-hour device', () async {
      final h = AppHarness(
        settings: {'settings.language': 'en'},
        deviceFormat: deviceFormatOverride(
          locales: const [Locale('en', 'US')],
          use24HourFormat: false,
        ),
      );
      await h.read(settingsRepositoryProvider.future);
      expect(h.read(settingsProvider).language, AppLanguage.en);
      final (shift, job) = await _running(h);
      await h.read(shiftSideEffectsProvider).shiftChanged(shift, job);

      final post = h.notifications.posted.single;
      expect(post.title, 'Shift running');
      expect(post.body, 'since ${_en.time(_start.toLocal())} · €15.00/h');
      expect(post.body, matches(RegExp(r'since \d{1,2}:02\s?[AP]M')));
      expect(post.pauseLabel, 'Pause');
      expect(post.resumeLabel, 'Resume');
      expect(post.finishLabel, 'Finish');
      expect(h.notifications.scheduled.single.title, 'Still working?');
    });

    test('"System" follows the device language', () async {
      final h = AppHarness(
        deviceFormat: deviceFormatOverride(
          locales: const [Locale('fr', 'FR'), Locale('en', 'GB')],
        ),
      );
      final (shift, job) = await _running(h);
      await h.read(shiftSideEffectsProvider).shiftChanged(shift, job);
      expect(h.notifications.posted.single.title, 'Shift running');
    });

    test('German on an Austrian device keeps the region', () async {
      final h = AppHarness(
        settings: {'settings.language': 'de'},
        deviceFormat: deviceFormatOverride(locales: const [Locale('de', 'AT')]),
      );
      await h.read(settingsRepositoryProvider.future);
      final (shift, job) = await _running(h);
      await h.read(shiftSideEffectsProvider).shiftChanged(shift, job);
      expect(h.notifications.posted.single.title, 'Schicht läuft');
      expect(
        h.notifications.channelTexts.single.runningShiftName,
        'Laufende Schicht',
      );
    });
  });

  group('reminder', () {
    for (final hours in [6, 8, 12]) {
      test('$hours h after the start', () async {
        final h = AppHarness(settings: {'settings.reminderHours': hours});
        await h.read(settingsRepositoryProvider.future);
        final (shift, job) = await _running(h);
        await h.read(shiftSideEffectsProvider).shiftChanged(shift, job);
        expect(
          h.notifications.scheduled.single.at,
          _start.add(Duration(hours: hours)),
        );
      });
    }

    test('off (0 h): cancelled, never scheduled', () async {
      final h = AppHarness(settings: {'settings.reminderHours': 0});
      await h.read(settingsRepositoryProvider.future);
      final (shift, job) = await _running(h);
      await h.read(shiftSideEffectsProvider).shiftChanged(shift, job);
      expect(h.notifications.scheduled, isEmpty);
      expect(h.notifications.remindersCancelled, 1);
      expect(h.notifications.posted, hasLength(1));
    });

    test('already overdue: cancelled instead of scheduled', () async {
      final h = AppHarness(settings: {'settings.reminderHours': 6});
      await h.read(settingsRepositoryProvider.future);
      final (shift, job) = await _running(h);
      h.clock.advance(const Duration(hours: 6));
      await h.read(shiftSideEffectsProvider).shiftChanged(shift, job);
      expect(h.notifications.scheduled, isEmpty);
      expect(h.notifications.remindersCancelled, 1);
    });

    test('changing the reminder setting reschedules it once', () async {
      final h = AppHarness();
      await h.read(settingsRepositoryProvider.future);
      final job = await h.job();
      await h.read(activeShiftControllerProvider.notifier).start(job.id);
      h.notifications.clearRecords();

      await h.read(settingsProvider.notifier).setReminderHours(6);
      expect(h.notifications.scheduled, hasLength(1));
      expect(
        h.notifications.scheduled.single.at,
        h.clock.now.add(const Duration(hours: 6)),
      );
      expect(h.notifications.posted, hasLength(1));
    });
  });

  group('through the controllers', () {
    test('each change posts exactly once, never more', () async {
      final h = AppHarness();
      await h.read(settingsRepositoryProvider.future);
      final job = await h.job();
      final active = h.read(activeShiftControllerProvider.notifier);
      final n = h.notifications;

      await active.start(job.id);
      expect((n.posted.length, n.scheduled.length), (1, 1));
      expect(n.posted.last.paused, isFalse);

      h.clock.advance(const Duration(hours: 2));
      await active.pause();
      expect((n.posted.length, n.scheduled.length), (2, 2));
      expect(n.posted.last.paused, isTrue);

      h.clock.advance(const Duration(minutes: 30));
      await active.resume();
      expect(n.posted, hasLength(3));
      expect(n.posted.last.workedSoFar, const Duration(hours: 2));

      h.clock.advance(const Duration(hours: 1));
      await active.finish();
      expect(n.posted, hasLength(3));
      expect((n.cancelled, n.remindersCancelled), (1, 1));

      // Initialised once for all of it.
      expect(n.inits, 1);
    });

    test('the language setting re-posts in the new language', () async {
      final h = AppHarness();
      await h.read(settingsRepositoryProvider.future);
      final job = await h.job();
      await h.read(activeShiftControllerProvider.notifier).start(job.id);
      await h.read(settingsProvider.notifier).setLanguage(AppLanguage.en);
      expect(h.notifications.posted.last.title, 'Shift running');
      expect(h.notifications.posted, hasLength(2));
    });
  });
}
