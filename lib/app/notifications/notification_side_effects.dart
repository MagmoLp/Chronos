import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/job.dart';
import '../../domain/shift.dart';
import '../providers/providers.dart';
import 'app_notifications.dart';
import 'shift_notification.dart';

/// The app's [ShiftSideEffects]: keeps the ongoing notification and the
/// "Arbeitest du noch?" reminder in line with the running shift.
///
/// Every call posts exactly once: no shift → notification and reminder
/// removed; a shift → the notification (stopwatch or paused variant) and
/// the reminder at start + `reminderHours` (cancelled when 0). Texts follow
/// the app language (or the device language) and the device's 12/24-hour
/// setting. Nothing is scheduled periodically.
class NotificationSideEffects implements ShiftSideEffects {
  /// Creates the side effects on [_ref] (`shiftSideEffectsProvider`).
  NotificationSideEffects(this._ref);

  final Ref _ref;

  @override
  Future<void> shiftChanged(Shift? running, Job? job) async {
    final app = _ref.read(appNotificationsProvider);
    await app.ensureInitialized();
    final service = _ref.read(notificationServiceProvider);
    if (running == null) {
      await clearShiftNotifications(service);
      return;
    }
    final texts = app.texts();
    final now = _ref.read(clockProvider).now();
    final activeJobs = await _ref
        .read(jobRepositoryProvider)
        .getJobs(includeArchived: false);
    await showRunningShiftNotification(
      service,
      texts,
      running: running,
      now: now,
      jobName: activeJobs.length > 1 ? job?.name : null,
    );
    await syncShiftReminder(
      service,
      texts,
      running: running,
      reminderHours: _ref.read(settingsProvider).reminderHours,
      now: now,
    );
  }
}
