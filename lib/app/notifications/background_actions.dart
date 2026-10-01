import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:clock/clock.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/database.dart';
import '../../data/job_repository.dart';
import '../../data/settings_repository.dart';
import '../../data/shift_repository.dart';
import '../../domain/app_settings.dart';
import '../../domain/shift.dart';
import '../../platform/notifications.dart';
import '../error_log.dart';
import 'app_notification_service.dart';
import 'notification_texts.dart';
import 'shift_notification.dart';

/// What [handleNotificationAction] did.
enum NotificationActionOutcome {
  /// The shift was paused.
  paused,

  /// The shift was resumed.
  resumed,

  /// Nothing changed in the database: the notification referred to a shift
  /// that no longer runs (or the action is not handled in the background).
  /// The notification was brought in line with the database.
  stale,

  /// The action is not a background action (e.g. "Beenden", which opens the
  /// app); nothing was done.
  ignored,
}

/// Handles "Pause" / "Fortsetzen" from the running-shift notification while
/// the app UI may not be running (background isolate, no Riverpod).
///
/// Pauses or resumes only if [payload] still names the running shift
/// (checked in the same transaction as the change) and then re-posts the
/// notification once. A stale notification (its shift is no longer running)
/// is synced with the database instead: removed when nothing runs, or
/// replaced by the actually running shift. The reminder is left alone: its
/// time depends only on the start, which these actions do not change.
Future<NotificationActionOutcome> handleNotificationAction({
  required String actionId,
  required String? payload,
  required AppDatabase db,
  required NotificationService notifications,
  required NotificationTexts texts,
  Clock clock = const Clock(),
}) async {
  if (actionId != NotificationActionIds.pause &&
      actionId != NotificationActionIds.resume) {
    return NotificationActionOutcome.ignored;
  }
  final jobs = JobRepository(db, clock: clock);
  final shifts = ShiftRepository(db, clock: clock, jobs: jobs);
  final shiftId = shiftIdFromPayload(payload);

  final changed = await db.transaction<Shift?>(() async {
    final running = await shifts.getRunning();
    if (running == null || shiftId == null || running.id != shiftId) {
      return null;
    }
    return actionId == NotificationActionIds.pause
        ? shifts.pause()
        : shifts.resume();
  });

  final current = changed ?? await shifts.getRunning();
  if (current == null) {
    await clearShiftNotifications(notifications);
  } else {
    final job = await jobs.getJob(current.jobId);
    final activeJobs = await jobs.getJobs(includeArchived: false);
    await showRunningShiftNotification(
      notifications,
      texts,
      running: current,
      now: clock.now(),
      jobName: activeJobs.length > 1 ? job?.name : null,
    );
  }
  if (changed == null) return NotificationActionOutcome.stale;
  return actionId == NotificationActionIds.pause
      ? NotificationActionOutcome.paused
      : NotificationActionOutcome.resumed;
}

/// The app language stored in [store] (device language if unavailable).
AppLanguage _languageFrom(KeyValueStore? store) {
  if (store == null) return AppLanguage.system;
  return SettingsRepository(store).load().language;
}

/// Reads the settings store; `null` if it is not available in this isolate.
Future<KeyValueStore?> _openSettingsStore() async {
  try {
    return await SharedPreferencesStore.create();
  } on Object {
    // Preferences are unavailable in this isolate: use the device locale.
    return null;
  }
}

/// Entry point for "Pause" / "Fortsetzen" from the notification, run by the
/// plugin in a background isolate (registered through
/// `NotificationService.init(backgroundHandler: …)`).
///
/// Opens the shared database, reads the app language (falls back to the
/// device language if the preferences cannot be read here), delegates to
/// [handleNotificationAction] and closes the database again. Errors go to
/// the local error log.
@pragma('vm:entry-point')
Future<void> chronosNotificationAction(String actionId, String? payload) async {
  if (actionId != NotificationActionIds.pause &&
      actionId != NotificationActionIds.resume) {
    return;
  }
  final db = AppDatabase.open();
  try {
    final dispatcher = PlatformDispatcher.instance;
    final store = await _openSettingsStore();
    final texts = NotificationTexts.forLanguage(
      _languageFrom(store),
      deviceLocales: List<Locale>.of(dispatcher.locales),
      use24HourFormat: dispatcher.alwaysUse24HourFormat,
    );
    await handleNotificationAction(
      actionId: actionId,
      payload: payload,
      db: db,
      notifications: NotificationService(accentColor: kNotificationAccent),
      texts: texts,
    );
  } on Object catch (error, stack) {
    await ErrorLog(directory: getApplicationSupportDirectory)
        .record(error, stack, context: 'notificationAction $actionId');
  } finally {
    await db.close();
  }
}
