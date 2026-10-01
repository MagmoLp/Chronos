import 'dart:ui' show Color;

import '../../platform/notifications.dart';
import '../error_log.dart';
import '../theme/color_schemes.dart';

/// Accent colour of Chronos' notifications (small icon tint): the primary
/// colour of the light theme. Shared by the main and the background isolate
/// so both post identical notifications.
final Color kNotificationAccent = chronosLightScheme.primary;

/// The production [NotificationService]: themed accent colour, platform
/// errors go to [log].
NotificationService createNotificationService(ErrorLog log) =>
    NotificationService(
      accentColor: kNotificationAccent,
      onError: (error, stack) =>
          log.record(error, stack, context: 'notifications'),
    );
