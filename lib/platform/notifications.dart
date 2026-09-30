/// Android notifications of Chronos on top of flutter_local_notifications 22.
///
/// * the ongoing "running shift" notification with the native stopwatch
///   (posted only on state changes, the clock is drawn by SystemUI),
/// * the "Arbeitest du noch?" reminder (inexact alarm, re-armed after reboot
///   by the plugin's boot receiver),
/// * the notification permission (Android 13+) and the system settings,
/// * dispatching notification actions (Pause/Fortsetzen) to a background
///   isolate while the app UI is not running.
///
/// This layer knows nothing about shifts, jobs or money: callers pass ready,
/// localized strings and opaque payloads (e.g. the shift id).
///
/// ## Background actions
///
/// "Pause" and "Fortsetzen" are handled without opening the app. Android
/// starts a separate background isolate (no Riverpod container, no UI, no app
/// state) and calls [notificationBackgroundResponse], which forwards the action
/// to the app's [BackgroundActionHandler]. The handler must be a top-level or
/// static function annotated with `@pragma('vm:entry-point')`; register it via
/// [NotificationService.init] (or [NotificationService.registerBackgroundHandler]).
///
/// The handler is found again in the background isolate through its Flutter
/// callback handle, which [NotificationService] embeds into the payload of every
/// notification it posts – no storage is needed. A typical handler (written by
/// the app layer, not here):
///
/// ```dart
/// @pragma('vm:entry-point')
/// Future<void> onNotificationActionInBackground(
///   String actionId,
///   String? shiftId,
/// ) async {
///   // Plugins are registered already (see notificationBackgroundResponse).
///   final db = AppDatabase.open(); // drift, shareAcrossIsolates: true
///   try {
///     // Only act if `shiftId` is still the running shift, then pause/resume
///     // it in ONE transaction and re-post the notification with
///     // NotificationService().showRunningShift(...) using texts from
///     // lookupAppLocalizations(<language from the settings>).
///   } finally {
///     await db.close();
///   }
/// }
/// ```
///
/// "Beenden" (finish) and taps on a notification always open the app; they
/// arrive through the `onTap` callback of [NotificationService.init] while the
/// app runs, or through [NotificationService.launchTap] after a cold start.
library;

import 'dart:convert';
import 'dart:ui'
    show CallbackHandle, Color, DartPluginRegistrant, PluginUtilities;

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show WidgetsFlutterBinding;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

/// Notification channel ids.
abstract final class NotificationChannelIds {
  /// Ongoing notification while a shift runs (low importance, silent).
  static const String shiftRunning = 'shift_running';

  /// "Arbeitest du noch?" reminder (default importance).
  static const String reminders = 'reminders';

  /// Channel of Chronos 1.x; deleted by [NotificationService.init].
  static const String legacyV1 = 'work_session_timer';
}

/// Notification ids used by Chronos.
abstract final class NotificationIds {
  /// The running-shift notification. Same id as the 1.x notification, so an
  /// old notification that survived the update is replaced.
  static const int runningShift = 1;

  /// The "Arbeitest du noch?" reminder.
  static const int reminder = 2;
}

/// Ids of the notification actions, as passed to [BackgroundActionHandler] and
/// [NotificationTap.actionId].
abstract final class NotificationActionIds {
  /// Pause the running shift (background, no UI).
  static const String pause = 'pause';

  /// Resume the paused shift (background, no UI).
  static const String resume = 'resume';

  /// Open the app with the "Schicht beenden" sheet.
  static const String finish = 'finish';
}

/// Name of the notification small icon (`res/drawable/ic_stat_chronos.xml`).
const String kNotificationSmallIcon = 'ic_stat_chronos';

/// Handles a notification action in the background isolate.
///
/// [actionId] is one of [NotificationActionIds]; [payload] is the payload the
/// notification was posted with. Must be a top-level or static function
/// annotated with `@pragma('vm:entry-point')`.
typedef BackgroundActionHandler = Future<void> Function(
  String actionId,
  String? payload,
);

/// Handles a tap on a notification or on an action that opens the app.
typedef NotificationTapHandler = void Function(NotificationTap tap);

/// Reports an unexpected platform error (e.g. to the local error log).
typedef NotificationErrorReporter = void Function(
  Object error,
  StackTrace stackTrace,
);

/// Localized names and descriptions of the notification channels, as shown in
/// the Android system settings.
@immutable
class NotificationChannelTexts {
  /// Creates the channel texts.
  const NotificationChannelTexts({
    required this.runningShiftName,
    required this.runningShiftDescription,
    required this.remindersName,
    required this.remindersDescription,
  });

  /// Name of the [NotificationChannelIds.shiftRunning] channel ("Laufende Schicht").
  final String runningShiftName;

  /// Description of the [NotificationChannelIds.shiftRunning] channel.
  final String runningShiftDescription;

  /// Name of the [NotificationChannelIds.reminders] channel ("Erinnerungen").
  final String remindersName;

  /// Description of the [NotificationChannelIds.reminders] channel.
  final String remindersDescription;

  @override
  bool operator ==(Object other) =>
      other is NotificationChannelTexts &&
      other.runningShiftName == runningShiftName &&
      other.runningShiftDescription == runningShiftDescription &&
      other.remindersName == remindersName &&
      other.remindersDescription == remindersDescription;

  @override
  int get hashCode => Object.hash(
    runningShiftName,
    runningShiftDescription,
    remindersName,
    remindersDescription,
  );
}

/// A user interaction with a Chronos notification that opens the app.
@immutable
class NotificationTap {
  /// Creates a tap description.
  const NotificationTap({this.notificationId, this.actionId, this.payload});

  /// Id of the notification ([NotificationIds]), if known.
  final int? notificationId;

  /// Id of the tapped action ([NotificationActionIds]), `null` for a tap on
  /// the notification itself.
  final String? actionId;

  /// The payload the notification was posted with.
  final String? payload;

  /// Whether the user tapped the notification body (→ open "Heute").
  bool get isBodyTap => actionId == null || actionId!.isEmpty;

  /// Whether the user chose "Beenden" (→ open the finish sheet).
  bool get isFinish => actionId == NotificationActionIds.finish;

  @override
  bool operator ==(Object other) =>
      other is NotificationTap &&
      other.notificationId == notificationId &&
      other.actionId == actionId &&
      other.payload == payload;

  @override
  int get hashCode => Object.hash(notificationId, actionId, payload);

  @override
  String toString() =>
      'NotificationTap(id: $notificationId, action: $actionId, payload: $payload)';
}

/// Posts, updates and cancels Chronos' notifications.
///
/// All methods are safe to call from the main and from the background
/// isolate. Platform failures ([PlatformException], [MissingPluginException])
/// never escape: they are reported to `onError` and the method returns
/// `false` (or `null`/an empty result), so a broken notification never breaks
/// starting or finishing a shift.
class NotificationService {
  /// Creates the service.
  ///
  /// [plugin] is injectable for tests; [accentColor] tints the small icon
  /// (pass a color from the app theme); `onError` receives swallowed platform
  /// errors.
  NotificationService({
    AndroidFlutterLocalNotificationsPlugin? plugin,
    this.accentColor,
    this._onError,
  }) : _plugin = plugin ?? AndroidFlutterLocalNotificationsPlugin();

  final AndroidFlutterLocalNotificationsPlugin _plugin;
  final NotificationErrorReporter? _onError;

  /// Accent color of the notifications, or `null` for the system default.
  final Color? accentColor;

  /// Last channel texts passed to [init]/[updateChannelTexts] in this isolate.
  /// Only used when a channel does not exist yet (the ids otherwise).
  static NotificationChannelTexts? _channelTexts;

  static BackgroundActionHandler? _backgroundHandler;
  static int? _backgroundHandlerHandle;

  /// Registers [handler] for notification actions handled in the background.
  ///
  /// Every notification posted afterwards (in this isolate) carries the
  /// handler's callback handle, so the background isolate can find it again.
  /// Throws an [ArgumentError] if [handler] is not a top-level or static
  /// function.
  static void registerBackgroundHandler(BackgroundActionHandler handler) {
    final CallbackHandle? handle = PluginUtilities.getCallbackHandle(handler);
    if (handle == null) {
      throw ArgumentError.value(
        handler,
        'handler',
        'must be a top-level or static function annotated with '
            "@pragma('vm:entry-point')",
      );
    }
    _backgroundHandler = handler;
    _backgroundHandlerHandle = handle.toRawHandle();
  }

  /// Forgets the registered background handler (tests only).
  @visibleForTesting
  static void resetForTesting() {
    _backgroundHandler = null;
    _backgroundHandlerHandle = null;
    _channelTexts = null;
  }

  /// Raw callback handle of the registered background handler, if any.
  @visibleForTesting
  static int? get backgroundHandlerHandle => _backgroundHandlerHandle;

  /// Initializes the plugin in the main isolate. Call once at app start
  /// (after `runApp`, never before the first frame).
  ///
  /// Creates (or renames, after a language change) the channels, deletes the
  /// 1.x channel, registers [backgroundHandler] and routes taps that open the
  /// app to [onTap]. Does **not** ask for the notification permission, see
  /// [requestPermission]. Returns whether the plugin initialized.
  Future<bool> init({
    required NotificationChannelTexts channelTexts,
    NotificationTapHandler? onTap,
    BackgroundActionHandler? backgroundHandler,
  }) async {
    if (backgroundHandler != null) {
      registerBackgroundHandler(backgroundHandler);
    }
    final bool? initialized = await _guard(
      () => _plugin.initialize(
        settings: const AndroidInitializationSettings(kNotificationSmallIcon),
        onDidReceiveNotificationResponse: onTap == null
            ? null
            : (NotificationResponse response) =>
                  onTap(tapFromResponse(response)),
        onDidReceiveBackgroundNotificationResponse:
            notificationBackgroundResponse,
      ),
    );
    if (initialized != true) {
      return false;
    }
    await _guard(
      () => _plugin.deleteNotificationChannel(
        channelId: NotificationChannelIds.legacyV1,
      ),
    );
    return updateChannelTexts(channelTexts);
  }

  /// Creates both channels with [texts], or renames them after the app
  /// language changed. Importance and sound of existing channels stay as the
  /// user configured them.
  Future<bool> updateChannelTexts(NotificationChannelTexts texts) async {
    _channelTexts = texts;
    final bool? running = await _guard(() async {
      await _plugin.createNotificationChannel(
        AndroidNotificationChannel(
          NotificationChannelIds.shiftRunning,
          texts.runningShiftName,
          description: texts.runningShiftDescription,
          importance: Importance.low,
          playSound: false,
          enableVibration: false,
          showBadge: false,
        ),
      );
      return true;
    });
    final bool? reminders = await _guard(() async {
      await _plugin.createNotificationChannel(
        AndroidNotificationChannel(
          NotificationChannelIds.reminders,
          texts.remindersName,
          description: texts.remindersDescription,
        ),
      );
      return true;
    });
    return running == true && reminders == true;
  }

  /// Posts (or replaces) the running-shift notification.
  ///
  /// Call only when the state changes (start, pause, resume, start time or
  /// wage changed) and when reconciling with the database at app start – never
  /// periodically. While running, SystemUI draws a stopwatch that starts at
  /// [workedSoFar] (worked time without breaks) and keeps counting on its own.
  /// While [paused] there is no stopwatch.
  ///
  /// Texts come from the caller, e.g. [title] "Schicht läuft · Café" and
  /// [body] "seit 08:02 · 15,00 €/h" or "Pausiert seit 14:32".
  /// [pauseLabel]/[resumeLabel] label the toggle action ([NotificationActionIds.pause]
  /// or [NotificationActionIds.resume], handled in the background) and
  /// [finishLabel] the action that opens the finish sheet. [payload] is handed
  /// back with every action (e.g. the shift id).
  Future<bool> showRunningShift({
    required String title,
    required String body,
    required bool paused,
    required String pauseLabel,
    required String resumeLabel,
    required String finishLabel,
    Duration workedSoFar = Duration.zero,
    String? payload,
  }) async {
    final int? chronometerBase = paused
        ? null
        : clock.now().millisecondsSinceEpoch - workedSoFar.inMilliseconds;
    final AndroidNotificationDetails details = AndroidNotificationDetails(
      NotificationChannelIds.shiftRunning,
      _channelTexts?.runningShiftName ?? NotificationChannelIds.shiftRunning,
      channelDescription: _channelTexts?.runningShiftDescription,
      icon: kNotificationSmallIcon,
      color: accentColor,
      importance: Importance.low,
      priority: Priority.low,
      category: AndroidNotificationCategory.stopwatch,
      ongoing: true,
      autoCancel: false,
      silent: true,
      playSound: false,
      enableVibration: false,
      onlyAlertOnce: true,
      channelShowBadge: false,
      showWhen: !paused,
      when: chronometerBase,
      usesChronometer: !paused,
      actions: <AndroidNotificationAction>[
        if (paused)
          AndroidNotificationAction(
            NotificationActionIds.resume,
            resumeLabel,
            cancelNotification: false,
          )
        else
          AndroidNotificationAction(
            NotificationActionIds.pause,
            pauseLabel,
            cancelNotification: false,
          ),
        AndroidNotificationAction(
          NotificationActionIds.finish,
          finishLabel,
          showsUserInterface: true,
          // The shift only ends when the user saves the finish sheet.
          cancelNotification: false,
        ),
      ],
    );
    final bool? shown = await _guard(() async {
      await _plugin.show(
        id: NotificationIds.runningShift,
        title: title,
        body: body,
        notificationDetails: details,
        payload: encodePayload(payload),
      );
      return true;
    });
    return shown ?? false;
  }

  /// Removes the running-shift notification.
  Future<void> cancelRunningShift() async {
    await _guard(() => _plugin.cancel(id: NotificationIds.runningShift));
  }

  /// Ids of the notifications of this app that are currently visible.
  Future<List<int>> activeNotificationIds() async {
    final List<ActiveNotification>? active = await _guard(
      _plugin.getActiveNotifications,
    );
    return <int>[
      for (final ActiveNotification notification
          in active ?? const <ActiveNotification>[])
        if (notification.id != null) notification.id!,
    ];
  }

  /// Whether the running-shift notification is visible (it may have been
  /// swiped away on Android 14+, or be missing after a reboot).
  Future<bool> isRunningShiftVisible() async =>
      (await activeNotificationIds()).contains(NotificationIds.runningShift);

  /// Schedules the "Arbeitest du noch?" reminder for the instant [at],
  /// replacing a previously scheduled one.
  ///
  /// The alarm is inexact (`inexactAllowWhileIdle`, no exact-alarm
  /// permission) and scheduled in UTC, so it is not affected by time-zone or
  /// daylight-saving changes. After a reboot the plugin re-arms it. Returns
  /// `false` without scheduling if [at] is not in the future (the caller
  /// decides whether to remind right away).
  Future<bool> scheduleReminder({
    required DateTime at,
    required String title,
    required String body,
    required String finishLabel,
    String? payload,
  }) async {
    if (!at.isAfter(clock.now())) {
      await cancelReminder();
      return false;
    }
    final AndroidNotificationDetails details = AndroidNotificationDetails(
      NotificationChannelIds.reminders,
      _channelTexts?.remindersName ?? NotificationChannelIds.reminders,
      channelDescription: _channelTexts?.remindersDescription,
      icon: kNotificationSmallIcon,
      color: accentColor,
      category: AndroidNotificationCategory.reminder,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          NotificationActionIds.finish,
          finishLabel,
          showsUserInterface: true,
        ),
      ],
    );
    final bool? scheduled = await _guard(() async {
      await _plugin.zonedSchedule(
        id: NotificationIds.reminder,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(at.toUtc(), tz.UTC),
        notificationDetails: details,
        payload: encodePayload(payload),
        scheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
      return true;
    });
    return scheduled ?? false;
  }

  /// Cancels the pending (or removes the shown) reminder.
  Future<void> cancelReminder() async {
    await _guard(() => _plugin.cancel(id: NotificationIds.reminder));
  }

  /// Whether the app may post notifications (on Android 13+: whether the
  /// permission is granted; before: whether the user blocked the app).
  Future<bool> areNotificationsEnabled() async =>
      await _guard(_plugin.areNotificationsEnabled) ?? false;

  /// Shows the Android 13+ permission dialog if needed (call it in context,
  /// e.g. on the first "Schicht starten", after a short explanation).
  ///
  /// Returns whether notifications are allowed afterwards. Android shows the
  /// dialog at most twice; after that this returns `false` right away and the
  /// app should offer [openNotificationSettings].
  Future<bool> requestPermission() async {
    final bool? granted = await _guard(_plugin.requestNotificationsPermission);
    return granted ?? await areNotificationsEnabled();
  }

  /// Opens the system notification settings of the app. Returns whether a
  /// settings screen could be opened.
  Future<bool> openNotificationSettings() async =>
      await _guard(_plugin.openAppNotificationSettings) ?? false;

  /// The notification interaction that cold-started the app, if any
  /// (e.g. "Beenden" → open the finish sheet right away).
  Future<NotificationTap?> launchTap() async {
    final NotificationAppLaunchDetails? details = await _guard(
      _plugin.getNotificationAppLaunchDetails,
    );
    final NotificationResponse? response = details?.notificationResponse;
    if (details == null ||
        !details.didNotificationLaunchApp ||
        response == null) {
      return null;
    }
    return tapFromResponse(response);
  }

  Future<T?> _guard<T>(Future<T?> Function() call) async {
    try {
      return await call();
    } on PlatformException catch (error, stackTrace) {
      _onError?.call(error, stackTrace);
    } on MissingPluginException catch (error, stackTrace) {
      _onError?.call(error, stackTrace);
    }
    return null;
  }

  /// Wraps [payload] with the callback handle of the registered background
  /// handler (see the library documentation).
  @visibleForTesting
  static String encodePayload(String? payload) => jsonEncode(<String, Object?>{
    _kEnvelopeVersion: 1,
    _kEnvelopeHandle: ?_backgroundHandlerHandle,
    _kEnvelopePayload: ?payload,
  });

  /// Converts a plugin [response] into a [NotificationTap] with the caller's
  /// original payload.
  @visibleForTesting
  static NotificationTap tapFromResponse(NotificationResponse response) =>
      NotificationTap(
        notificationId: response.id,
        actionId: (response.actionId?.isEmpty ?? true)
            ? null
            : response.actionId,
        payload: _PayloadEnvelope.decode(response.payload).payload,
      );
}

const String _kEnvelopeVersion = 'chronos';
const String _kEnvelopeHandle = 'h';
const String _kEnvelopePayload = 'p';

/// The payload as posted by [NotificationService.encodePayload].
class _PayloadEnvelope {
  const _PayloadEnvelope(this.handlerHandle, this.payload);

  /// Accepts envelopes and, for robustness, plain payloads.
  factory _PayloadEnvelope.decode(String? raw) {
    if (raw == null || raw.isEmpty) {
      return const _PayloadEnvelope(null, null);
    }
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is Map<String, Object?> &&
          decoded.containsKey(_kEnvelopeVersion)) {
        final Object? handle = decoded[_kEnvelopeHandle];
        final Object? payload = decoded[_kEnvelopePayload];
        return _PayloadEnvelope(
          handle is int ? handle : null,
          payload is String ? payload : null,
        );
      }
    } on FormatException {
      // Not an envelope: a plain payload.
    }
    return _PayloadEnvelope(null, raw);
  }

  final int? handlerHandle;
  final String? payload;
}

/// Entry point for notification actions handled in the background isolate.
///
/// Passed to the plugin by [NotificationService.init]; never call it directly.
/// Makes plugins usable in the fresh isolate (so the handler can open the
/// drift database, read settings and re-post the notification) and forwards
/// the action to the registered [BackgroundActionHandler].
@pragma('vm:entry-point')
Future<void> notificationBackgroundResponse(
  NotificationResponse response,
) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  await dispatchBackgroundResponse(response);
}

/// Forwards a background notification [response] to the app's handler.
///
/// Uses the handler registered in this isolate or, in a fresh background
/// isolate, resolves the callback handle carried in the payload (via
/// [resolveHandler] in tests) and registers it for this isolate, so that
/// notifications re-posted by the handler keep working. Returns whether a
/// handler ran.
/// Errors of the handler are reported to [onError] (default: [debugPrint]).
@visibleForTesting
Future<bool> dispatchBackgroundResponse(
  NotificationResponse response, {
  BackgroundActionHandler? Function(int handle)? resolveHandler,
  NotificationErrorReporter? onError,
}) async {
  final String? actionId = response.actionId;
  if (response.notificationResponseType !=
          NotificationResponseType.selectedNotificationAction ||
      actionId == null ||
      actionId.isEmpty) {
    return false;
  }
  final _PayloadEnvelope envelope = _PayloadEnvelope.decode(response.payload);
  final int? handle = envelope.handlerHandle;
  BackgroundActionHandler? handler = NotificationService._backgroundHandler;
  if (handler == null && handle != null) {
    handler = (resolveHandler ?? _handlerFromHandle)(handle);
    if (handler != null) {
      // Notifications re-posted by the handler in this isolate keep the handle.
      NotificationService._backgroundHandler = handler;
      NotificationService._backgroundHandlerHandle = handle;
    }
  }
  if (handler == null) {
    debugPrint('Chronos: no handler for notification action "$actionId".');
    return false;
  }
  try {
    await handler(actionId, envelope.payload);
    return true;
  } on Object catch (error, stackTrace) {
    (onError ??
        (Object e, StackTrace s) => debugPrint(
          'Chronos: notification action "$actionId" failed: $e\n$s',
        ))(error, stackTrace);
    return false;
  }
}

BackgroundActionHandler? _handlerFromHandle(int handle) {
  final Function? function = PluginUtilities.getCallbackFromHandle(
    CallbackHandle.fromRawHandle(handle),
  );
  return function is BackgroundActionHandler ? function : null;
}
