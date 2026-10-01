import 'dart:async';
import 'dart:ui' show Locale;

import 'package:flutter/widgets.dart' show WidgetsBinding;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/errors.dart';
import '../../platform/notifications.dart';
import '../providers/providers.dart';
import 'background_actions.dart';
import 'notification_texts.dart';

/// The device's preferred locales and 12/24-hour setting, for texts built
/// outside the widget tree.
typedef DeviceFormat = ({List<Locale> locales, bool use24HourFormat});

/// Reads the current [DeviceFormat] (tests override it with fixed values).
final deviceFormatProvider = Provider<DeviceFormat Function()>(
  (ref) => () {
    final dispatcher = WidgetsBinding.instance.platformDispatcher;
    return (
      locales: List<Locale>.of(dispatcher.locales),
      use24HourFormat: dispatcher.alwaysUse24HourFormat,
    );
  },
  name: 'deviceFormatProvider',
);

/// Notification wiring of the running app: initialisation, channel names,
/// routing of notification taps.
final appNotificationsProvider = Provider<AppNotifications>(
  AppNotifications.new,
  name: 'appNotificationsProvider',
);

/// Initialises the [NotificationService] once, keeps the channel names in
/// the app language and turns notification taps into [AppRequest]s.
class AppNotifications {
  /// Creates the wiring on [_ref].
  AppNotifications(this._ref);

  final Ref _ref;
  Future<bool>? _initialized;
  Locale? _channelLocale;
  bool _launchTapChecked = false;

  NotificationService get _service => _ref.read(notificationServiceProvider);

  /// Texts in the current app language and device formats.
  NotificationTexts texts() {
    final device = _ref.read(deviceFormatProvider)();
    return NotificationTexts.forLanguage(
      _ref.read(settingsProvider).language,
      deviceLocales: device.locales,
      use24HourFormat: device.use24HourFormat,
    );
  }

  /// Initialises the plugin (channels in the app language, tap routing,
  /// background handler for Pause/Fortsetzen). Safe to call repeatedly:
  /// the work happens once. Returns whether the plugin is ready.
  Future<bool> ensureInitialized() => _initialized ??= _init();

  Future<bool> _init() async {
    final current = texts();
    _channelLocale = current.locale;
    try {
      return await _service.init(
        channelTexts: current.channelTexts,
        onTap: handleTap,
        backgroundHandler: chronosNotificationAction,
      );
    } on Object catch (error, stack) {
      unawaited(
        _ref
            .read(errorLogProvider)
            .record(error, stack, context: 'notifications.init'),
      );
      return false;
    }
  }

  /// Renames the channels after the app or device language changed.
  Future<void> refreshChannelTexts() async {
    final initialized = _initialized;
    if (initialized == null || !await initialized) return;
    final current = texts();
    if (current.locale == _channelLocale) return;
    _channelLocale = current.locale;
    await _service.updateChannelTexts(current.channelTexts);
  }

  /// Routes a notification interaction that reached the running app:
  /// "Beenden" → Today with the finish sheet, a tap on the notification →
  /// Today. Pause/Fortsetzen normally run in the background; should they
  /// arrive here, they are applied through the controller.
  void handleTap(NotificationTap tap) {
    final requests = _ref.read(appRequestProvider.notifier);
    switch (tap.actionId) {
      case NotificationActionIds.finish:
        requests.request(AppRequestKind.openFinishSheet);
      case NotificationActionIds.pause:
        unawaited(
          _guard(
            () => _ref.read(activeShiftControllerProvider.notifier).pause(),
          ),
        );
      case NotificationActionIds.resume:
        unawaited(
          _guard(
            () => _ref.read(activeShiftControllerProvider.notifier).resume(),
          ),
        );
      default:
        requests.request(AppRequestKind.showToday);
    }
  }

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } on ChronosException {
      // Busy or nothing running any more: the notification is re-synced by
      // the controller's side effects or at the next reconcile.
    }
  }

  /// Handles the notification interaction that cold-started the app, once
  /// (call after the start sequence finished).
  Future<void> checkLaunchTap() async {
    if (_launchTapChecked) return;
    _launchTapChecked = true;
    await ensureInitialized();
    final tap = await _service.launchTap();
    if (tap != null) handleTap(tap);
  }
}
