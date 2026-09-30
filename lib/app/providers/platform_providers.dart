import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../platform/app_info.dart';
import '../../platform/notifications.dart';
import '../../platform/share_service.dart';
import '../error_log.dart';

/// The ongoing-shift notification, reminders and notification permission.
///
/// The app entry point initialises it after `runApp`; tests override it with
/// a service built on a fake plugin.
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final log = ref.watch(errorLogProvider);
  return NotificationService(
    onError: (error, stack) =>
        log.record(error, stack, context: 'notifications'),
  );
}, name: 'notificationServiceProvider');

/// Share sheet, temporary files and picking backup files.
final shareServiceProvider = Provider<ShareService>(
  (ref) => ShareService(),
  name: 'shareServiceProvider',
);

/// App version (about page, backups, error reports).
final appInfoServiceProvider = Provider<AppInfoService>(
  (ref) => AppInfoService(),
  name: 'appInfoServiceProvider',
);
