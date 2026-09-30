import 'dart:convert';

import 'package:chronos/platform/notifications.dart';
import 'package:clock/clock.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

const MethodChannel _channel = MethodChannel(
  'dexterous.com/flutter/local_notifications',
);

final List<(String, String?)> _handled = <(String, String?)>[];

@pragma('vm:entry-point')
Future<void> _recordingHandler(String actionId, String? payload) async {
  _handled.add((actionId, payload));
}

@pragma('vm:entry-point')
Future<void> _failingHandler(String actionId, String? payload) async {
  throw StateError('database locked');
}

const NotificationChannelTexts _germanTexts = NotificationChannelTexts(
  runningShiftName: 'Laufende Schicht',
  runningShiftDescription: 'Zeigt die laufende Schicht mit Stoppuhr.',
  remindersName: 'Erinnerungen',
  remindersDescription: '„Arbeitest du noch?“',
);

/// Records the plugin's method-channel traffic and answers like Android.
class _FakeAndroid {
  final List<MethodCall> calls = <MethodCall>[];
  final Map<String, Object? Function(MethodCall call)> answers =
      <String, Object? Function(MethodCall call)>{};

  void install() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (MethodCall call) async {
          calls.add(call);
          final Object? Function(MethodCall call)? answer =
              answers[call.method];
          if (answer != null) {
            return answer(call);
          }
          return switch (call.method) {
            'initialize' => true,
            'areNotificationsEnabled' => true,
            'requestNotificationsPermission' => true,
            'openAppNotificationSettings' => true,
            'getActiveNotifications' => <Object?>[],
            _ => null,
          };
        });
  }

  List<MethodCall> named(String method) =>
      calls.where((MethodCall c) => c.method == method).toList();

  Map<Object?, Object?> single(String method) {
    final List<MethodCall> matching = named(method);
    expect(matching, hasLength(1), reason: 'exactly one "$method" call');
    return matching.single.arguments as Map<Object?, Object?>;
  }
}

Map<Object?, Object?> _specifics(Map<Object?, Object?> args) =>
    args['platformSpecifics']! as Map<Object?, Object?>;

List<Map<Object?, Object?>> _actions(Map<Object?, Object?> specifics) =>
    <Map<Object?, Object?>>[
      for (final Object? action in specifics['actions']! as List<Object?>)
        action! as Map<Object?, Object?>,
    ];

String? _payloadOf(Map<Object?, Object?> args) =>
    NotificationService.tapFromResponse(
      NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        payload: args['payload'] as String?,
      ),
    ).payload;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeAndroid android;
  late List<Object> errors;
  late NotificationService service;

  setUp(() {
    NotificationService.resetForTesting();
    _handled.clear();
    android = _FakeAndroid()..install();
    errors = <Object>[];
    service = NotificationService(
      onError: (Object error, StackTrace _) => errors.add(error),
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  });

  group('init', () {
    test(
      'initializes with the vector small icon and a background entry point',
      () async {
        expect(await service.init(channelTexts: _germanTexts), isTrue);

        final Map<Object?, Object?> init = android.single('initialize');
        expect(init['defaultIcon'], kNotificationSmallIcon);
        expect(init['dispatcher_handle'], isA<int>());
        expect(init['callback_handle'], isA<int>());
      },
    );

    test(
      'deletes the 1.x channel and creates both channels localized',
      () async {
        await service.init(channelTexts: _germanTexts);

        expect(
          android.named('deleteNotificationChannel').single.arguments,
          'work_session_timer',
        );
        final List<Map<Object?, Object?>> channels = <Map<Object?, Object?>>[
          for (final MethodCall call in android.named(
            'createNotificationChannel',
          ))
            call.arguments as Map<Object?, Object?>,
        ];
        expect(channels, hasLength(2));
        final Map<Object?, Object?> running = channels.firstWhere(
          (Map<Object?, Object?> c) => c['id'] == 'shift_running',
        );
        expect(running['name'], 'Laufende Schicht');
        expect(
          running['description'],
          'Zeigt die laufende Schicht mit Stoppuhr.',
        );
        expect(running['importance'], Importance.low.value);
        expect(running['playSound'], isFalse);
        expect(running['enableVibration'], isFalse);
        expect(running['showBadge'], isFalse);
        final Map<Object?, Object?> reminders = channels.firstWhere(
          (Map<Object?, Object?> c) => c['id'] == 'reminders',
        );
        expect(reminders['name'], 'Erinnerungen');
        expect(reminders['importance'], Importance.defaultImportance.value);
        expect(reminders['playSound'], isTrue);
      },
    );

    test('does not ask for the notification permission', () async {
      await service.init(channelTexts: _germanTexts);
      expect(android.named('requestNotificationsPermission'), isEmpty);
    });

    test('registers the background handler', () async {
      await service.init(
        channelTexts: _germanTexts,
        backgroundHandler: _recordingHandler,
      );
      expect(NotificationService.backgroundHandlerHandle, isA<int>());
    });

    test('rejects closures as background handler', () {
      expect(
        () => NotificationService.registerBackgroundHandler(
          (String a, String? p) async {},
        ),
        throwsArgumentError,
      );
    });

    test('reports a platform failure and skips the channels', () async {
      android.answers['initialize'] = (_) =>
          throw PlatformException(code: 'boom');
      expect(await service.init(channelTexts: _germanTexts), isFalse);
      expect(errors.single, isA<PlatformException>());
      expect(android.named('createNotificationChannel'), isEmpty);
    });

    test('renames the channels after a language change', () async {
      await service.init(channelTexts: _germanTexts);
      android.calls.clear();
      await service.updateChannelTexts(
        const NotificationChannelTexts(
          runningShiftName: 'Running shift',
          runningShiftDescription: 'Shows the running shift with a stopwatch.',
          remindersName: 'Reminders',
          remindersDescription: '"Still working?"',
        ),
      );
      expect(
        android
            .named('createNotificationChannel')
            .map(
              (MethodCall c) => (c.arguments as Map<Object?, Object?>)['name'],
            ),
        <String>['Running shift', 'Reminders'],
      );
    });
  });

  group('running shift', () {
    final DateTime now = DateTime.utc(2026, 9, 30, 11, 13, 42);

    test(
      'shows a silent ongoing notification with the native stopwatch',
      () async {
        await withClock(Clock.fixed(now), () async {
          final bool shown = await service.showRunningShift(
            title: 'Schicht läuft',
            body: 'seit 08:02 · 15,00 €/h',
            paused: false,
            workedSoFar: const Duration(hours: 3, minutes: 11, seconds: 42),
            pauseLabel: 'Pause',
            resumeLabel: 'Fortsetzen',
            finishLabel: 'Beenden',
            payload: 'shift-42',
          );
          expect(shown, isTrue);
        });

        final Map<Object?, Object?> args = android.single('show');
        expect(args['id'], NotificationIds.runningShift);
        expect(args['title'], 'Schicht läuft');
        expect(args['body'], 'seit 08:02 · 15,00 €/h');
        expect(_payloadOf(args), 'shift-42');

        final Map<Object?, Object?> specifics = _specifics(args);
        expect(specifics['channelId'], 'shift_running');
        expect(specifics['icon'], 'ic_stat_chronos');
        expect(specifics['usesChronometer'], isTrue);
        expect(specifics['showWhen'], isTrue);
        expect(
          specifics['when'],
          DateTime.utc(2026, 9, 30, 8, 2).millisecondsSinceEpoch,
        );
        expect(specifics['ongoing'], isTrue);
        expect(specifics['autoCancel'], isFalse);
        expect(specifics['silent'], isTrue);
        expect(specifics['onlyAlertOnce'], isTrue);
        expect(specifics['playSound'], isFalse);
        expect(specifics['importance'], Importance.low.value);
        expect(specifics['priority'], Priority.low.value);
        expect(specifics['category'], 'stopwatch');

        final List<Map<Object?, Object?>> actions = _actions(specifics);
        expect(actions.map((Map<Object?, Object?> a) => a['id']), <String>[
          'pause',
          'finish',
        ]);
        expect(actions.map((Map<Object?, Object?> a) => a['title']), <String>[
          'Pause',
          'Beenden',
        ]);
        expect(actions[0]['showsUserInterface'], isFalse);
        expect(actions[0]['cancelNotification'], isFalse);
        expect(actions[1]['showsUserInterface'], isTrue);
        expect(actions[1]['cancelNotification'], isFalse);
      },
    );

    test('paused variant has no stopwatch and offers resume', () async {
      await withClock(Clock.fixed(now), () async {
        await service.showRunningShift(
          title: 'Schicht pausiert',
          body: 'Pausiert seit 14:32',
          paused: true,
          workedSoFar: const Duration(hours: 5),
          pauseLabel: 'Pause',
          resumeLabel: 'Fortsetzen',
          finishLabel: 'Beenden',
        );
      });

      final Map<Object?, Object?> specifics = _specifics(
        android.single('show'),
      );
      expect(specifics['usesChronometer'], isFalse);
      expect(specifics['showWhen'], isFalse);
      expect(specifics['when'], isNull);
      expect(specifics['ongoing'], isTrue);
      expect(
        _actions(specifics).map((Map<Object?, Object?> a) => a['id']),
        <String>['resume', 'finish'],
      );
    });

    test('uses the localized channel name once initialized', () async {
      await service.init(channelTexts: _germanTexts);
      await service.showRunningShift(
        title: 't',
        body: 'b',
        paused: false,
        pauseLabel: 'Pause',
        resumeLabel: 'Fortsetzen',
        finishLabel: 'Beenden',
      );
      expect(
        _specifics(android.single('show'))['channelName'],
        'Laufende Schicht',
      );
    });

    test('cancel removes only the running-shift notification', () async {
      await service.cancelRunningShift();
      expect(android.single('cancel'), <String, Object?>{'id': 1, 'tag': null});
    });

    test('knows whether the notification is still visible', () async {
      android.answers['getActiveNotifications'] = (_) => <Object?>[
        <String, Object?>{'id': 2, 'channelId': 'reminders'},
      ];
      expect(await service.isRunningShiftVisible(), isFalse);
      android.answers['getActiveNotifications'] = (_) => <Object?>[
        <String, Object?>{'id': 1, 'channelId': 'shift_running'},
        <String, Object?>{'id': null},
      ];
      expect(await service.isRunningShiftVisible(), isTrue);
      expect(await service.activeNotificationIds(), <int>[1]);
    });
  });

  group('reminder', () {
    final DateTime now = DateTime.utc(2026, 9, 30, 8);

    test('is scheduled inexactly in UTC with a finish action', () async {
      final bool scheduled = await withClock(
        Clock.fixed(now),
        () => service.scheduleReminder(
          at: DateTime.utc(2026, 9, 30, 18, 2).toLocal(),
          title: 'Arbeitest du noch?',
          body: 'Die Schicht läuft seit 10 h.',
          finishLabel: 'Beenden',
          payload: 'shift-42',
        ),
      );
      expect(scheduled, isTrue);

      final Map<Object?, Object?> args = android.single('zonedSchedule');
      expect(args['id'], NotificationIds.reminder);
      expect(args['title'], 'Arbeitest du noch?');
      expect(args['timeZoneName'], 'Etc/UTC');
      expect(args['scheduledDateTime'], '2026-09-30T18:02:00');
      expect(_payloadOf(args), 'shift-42');
      final Map<Object?, Object?> specifics = _specifics(args);
      expect(specifics['scheduleMode'], 'inexactAllowWhileIdle');
      expect(specifics['channelId'], 'reminders');
      expect(specifics['category'], 'reminder');
      expect(specifics['icon'], 'ic_stat_chronos');
      final Map<Object?, Object?> finish = _actions(specifics).single;
      expect(finish['id'], 'finish');
      expect(finish['showsUserInterface'], isTrue);
      expect(finish['cancelNotification'], isTrue);
    });

    test(
      'is DST-proof: the instant is sent unchanged across the autumn change',
      () async {
        // 02:30 local time exists twice in Europe on 25.10.2026; UTC is unambiguous.
        await withClock(
          Clock.fixed(now),
          () => service.scheduleReminder(
            at: DateTime.utc(2026, 10, 25, 1, 30),
            title: 't',
            body: 'b',
            finishLabel: 'Beenden',
          ),
        );
        expect(
          android.single('zonedSchedule')['scheduledDateTime'],
          '2026-10-25T01:30:00',
        );
      },
    );

    test('in the past is not scheduled and an old one is cancelled', () async {
      final bool scheduled = await withClock(
        Clock.fixed(now),
        () => service.scheduleReminder(
          at: now,
          title: 't',
          body: 'b',
          finishLabel: 'Beenden',
        ),
      );
      expect(scheduled, isFalse);
      expect(android.named('zonedSchedule'), isEmpty);
      expect(android.single('cancel')['id'], NotificationIds.reminder);
    });

    test('cancelReminder cancels id 2', () async {
      await service.cancelReminder();
      expect(android.single('cancel')['id'], NotificationIds.reminder);
    });
  });

  group('permission', () {
    test('reports whether notifications are enabled', () async {
      android.answers['areNotificationsEnabled'] = (_) => false;
      expect(await service.areNotificationsEnabled(), isFalse);
    });

    test('request returns the user decision', () async {
      android.answers['requestNotificationsPermission'] = (_) => false;
      expect(await service.requestPermission(), isFalse);
      expect(android.named('requestNotificationsPermission'), hasLength(1));
    });

    test(
      'a request already in progress falls back to the current state',
      () async {
        android.answers['requestNotificationsPermission'] = (_) =>
            throw PlatformException(code: 'permissionRequestInProgress');
        expect(await service.requestPermission(), isTrue);
        expect(errors.single, isA<PlatformException>());
      },
    );

    test('opens the app notification settings', () async {
      expect(await service.openNotificationSettings(), isTrue);
      expect(android.named('openAppNotificationSettings'), hasLength(1));
    });
  });

  group('taps that open the app', () {
    test('launchTap returns the action that cold-started the app', () async {
      NotificationService.registerBackgroundHandler(_recordingHandler);
      final String payload = NotificationService.encodePayload('shift-42');
      android.answers['getNotificationAppLaunchDetails'] = (_) =>
          <String, Object?>{
            'notificationLaunchedApp': true,
            'notificationResponse': <String, Object?>{
              'notificationId': 1,
              'actionId': 'finish',
              'notificationResponseType':
                  NotificationResponseType.selectedNotificationAction.index,
              'payload': payload,
            },
          };
      expect(
        await service.launchTap(),
        const NotificationTap(
          notificationId: 1,
          actionId: 'finish',
          payload: 'shift-42',
        ),
      );
    });

    test('launchTap is null for a normal start', () async {
      android.answers['getNotificationAppLaunchDetails'] = (_) =>
          <String, Object?>{'notificationLaunchedApp': false};
      expect(await service.launchTap(), isNull);
    });

    test(
      'taps while the app runs reach onTap with the original payload',
      () async {
        final List<NotificationTap> taps = <NotificationTap>[];
        await service.init(channelTexts: _germanTexts, onTap: taps.add);

        await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .handlePlatformMessage(
              _channel.name,
              _channel.codec.encodeMethodCall(
                MethodCall('didReceiveNotificationResponse', <String, Object?>{
                  'notificationId': 1,
                  'actionId': null,
                  'notificationResponseType':
                      NotificationResponseType.selectedNotification.index,
                  'payload': NotificationService.encodePayload('shift-42'),
                }),
              ),
              (ByteData? _) {},
            );

        expect(taps.single.isBodyTap, isTrue);
        expect(taps.single.isFinish, isFalse);
        expect(taps.single.payload, 'shift-42');
        expect(taps.single.notificationId, 1);
      },
    );
  });

  group('background actions', () {
    NotificationResponse action(String id, String? payload) =>
        NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotificationAction,
          id: 1,
          actionId: id,
          payload: payload,
        );

    test(
      'are forwarded to the registered handler with the plain payload',
      () async {
        NotificationService.registerBackgroundHandler(_recordingHandler);
        final bool handled = await dispatchBackgroundResponse(
          action('pause', NotificationService.encodePayload('shift-42')),
        );
        expect(handled, isTrue);
        expect(_handled, <(String, String?)>[('pause', 'shift-42')]);
      },
    );

    test(
      'in a fresh isolate the handler is found via the payload handle',
      () async {
        NotificationService.registerBackgroundHandler(_recordingHandler);
        final int handle = NotificationService.backgroundHandlerHandle!;
        final String payload = NotificationService.encodePayload('shift-7');
        NotificationService.resetForTesting(); // what a new isolate looks like

        final List<int> resolved = <int>[];
        final bool handled = await dispatchBackgroundResponse(
          action('resume', payload),
          resolveHandler: (int h) {
            resolved.add(h);
            return _recordingHandler;
          },
        );

        expect(handled, isTrue);
        expect(resolved, <int>[handle]);
        expect(_handled, <(String, String?)>[('resume', 'shift-7')]);
        // Notifications re-posted by the handler keep carrying the handle.
        expect(NotificationService.backgroundHandlerHandle, handle);
      },
    );

    test('resolves the handle through the Flutter callback cache', () async {
      NotificationService.registerBackgroundHandler(_recordingHandler);
      final String payload = NotificationService.encodePayload(null);
      NotificationService.resetForTesting();

      expect(
        await dispatchBackgroundResponse(action('pause', payload)),
        isTrue,
      );
      expect(_handled, <(String, String?)>[('pause', null)]);
    });

    test('taps and dismissals are not handled in the background', () async {
      NotificationService.registerBackgroundHandler(_recordingHandler);
      final bool tap = await dispatchBackgroundResponse(
        const NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
        ),
      );
      final bool dismissed = await dispatchBackgroundResponse(
        const NotificationResponse(
          notificationResponseType:
              NotificationResponseType.notificationDismissed,
          actionId: 'pause',
        ),
      );
      expect(tap, isFalse);
      expect(dismissed, isFalse);
      expect(_handled, isEmpty);
    });

    test('without a handler nothing happens', () async {
      expect(
        await dispatchBackgroundResponse(action('pause', 'plain')),
        isFalse,
      );
    });

    test('handler errors are reported, not thrown', () async {
      NotificationService.registerBackgroundHandler(_failingHandler);
      final List<Object> reported = <Object>[];
      final bool handled = await dispatchBackgroundResponse(
        action('pause', null),
        onError: (Object e, StackTrace _) => reported.add(e),
      );
      expect(handled, isFalse);
      expect(reported.single, isA<StateError>());
    });
  });

  group('payload envelope', () {
    NotificationResponse withPayload(String? payload) => NotificationResponse(
      notificationResponseType: NotificationResponseType.selectedNotification,
      payload: payload,
    );

    test('round-trips the caller payload, with or without handler', () {
      expect(
        NotificationService.tapFromResponse(
          withPayload(NotificationService.encodePayload('a"b{c}')),
        ).payload,
        'a"b{c}',
      );
      final Map<String, Object?> envelope = jsonDecode(
        NotificationService.encodePayload(null),
      ) as Map<String, Object?>;
      expect(envelope.containsKey('h'), isFalse);
      expect(envelope.containsKey('p'), isFalse);
    });

    test('plain and foreign payloads pass through unchanged', () {
      expect(
        NotificationService.tapFromResponse(withPayload('shift-1')).payload,
        'shift-1',
      );
      expect(
        NotificationService.tapFromResponse(withPayload('{"x":1}')).payload,
        '{"x":1}',
      );
      expect(
        NotificationService.tapFromResponse(withPayload('')).payload,
        isNull,
      );
      expect(
        NotificationService.tapFromResponse(withPayload(null)).payload,
        isNull,
      );
    });
  });

  group('without the platform plugin (widget tests, desktop)', () {
    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, null);
    });

    test('every call degrades gracefully', () async {
      expect(await service.init(channelTexts: _germanTexts), isFalse);
      expect(
        await service.showRunningShift(
          title: 't',
          body: 'b',
          paused: false,
          pauseLabel: 'p',
          resumeLabel: 'r',
          finishLabel: 'f',
        ),
        isFalse,
      );
      await service.cancelRunningShift();
      await service.cancelReminder();
      expect(await service.isRunningShiftVisible(), isFalse);
      expect(await service.areNotificationsEnabled(), isFalse);
      expect(await service.requestPermission(), isFalse);
      expect(await service.openNotificationSettings(), isFalse);
      expect(await service.launchTap(), isNull);
      expect(errors, everyElement(isA<MissingPluginException>()));
    });
  });
}
