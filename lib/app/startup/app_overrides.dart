import 'package:flutter_riverpod/misc.dart' show Override;

import '../../platform/notifications.dart';
import '../notifications/app_notification_service.dart';
import '../notifications/notification_side_effects.dart';
import '../providers/providers.dart';

/// The provider overrides that turn the state layer into the app: the error
/// log, the notification/reminder side effects, the localized name of the
/// job created from v1 data and the themed notification service.
///
/// `main` passes them to the root `ProviderScope`; tests pass a fake
/// [notifications] service.
List<Override> chronosOverrides({
  required ErrorLog errorLog,
  required String defaultJobName,
  NotificationService? notifications,
}) => <Override>[
  errorLogProvider.overrideWithValue(errorLog),
  shiftSideEffectsProvider.overrideWith(NotificationSideEffects.new),
  bootstrapConfigProvider.overrideWithValue(
    BootstrapConfig(defaultJobName: defaultJobName),
  ),
  notificationServiceProvider.overrideWith(
    (ref) =>
        notifications ?? createNotificationService(ref.watch(errorLogProvider)),
  ),
];
