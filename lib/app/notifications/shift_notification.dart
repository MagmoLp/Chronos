import '../../domain/pay.dart';
import '../../domain/shift.dart';
import '../../platform/notifications.dart';
import 'notification_texts.dart';

/// Payload of the running-shift notification and the reminder: the shift id,
/// so actions can check that the shift still runs.
String shiftPayload(Shift shift) => '${shift.id}';

/// The shift id carried by a notification [payload], or `null`.
int? shiftIdFromPayload(String? payload) =>
    payload == null ? null : int.tryParse(payload.trim());

/// Posts (or replaces) the ongoing notification for the [running] shift:
/// native stopwatch from the worked time so far, or the paused variant.
///
/// [jobName] is shown in the title; pass it only when the user has more than
/// one active job. Called once per state change, never periodically.
Future<bool> showRunningShiftNotification(
  NotificationService service,
  NotificationTexts texts, {
  required Shift running,
  required DateTime now,
  String? jobName,
}) {
  final live = liveValues(running, now.toUtc());
  return service.showRunningShift(
    title: texts.runningTitle(jobName),
    body: texts.runningBody(running),
    paused: running.isPaused,
    pauseLabel: texts.pauseLabel,
    resumeLabel: texts.resumeLabel,
    finishLabel: texts.finishLabel,
    workedSoFar: Duration(milliseconds: live.workedMs),
    payload: shiftPayload(running),
  );
}

/// The instant of the "Arbeitest du noch?" reminder for [running]:
/// [reminderHours] after its start, or `null` when the reminder is off.
DateTime? reminderTimeFor(Shift running, int reminderHours) =>
    reminderHours <= 0
    ? null
    : running.startUtc.add(Duration(hours: reminderHours));

/// Schedules the reminder for [running], or cancels it when reminders are
/// off ([reminderHours] 0) or the time has already passed.
Future<void> syncShiftReminder(
  NotificationService service,
  NotificationTexts texts, {
  required Shift running,
  required int reminderHours,
  required DateTime now,
}) async {
  final at = reminderTimeFor(running, reminderHours);
  if (at == null || !at.isAfter(now.toUtc())) {
    await service.cancelReminder();
    return;
  }
  await service.scheduleReminder(
    at: at,
    title: texts.reminderTitle,
    body: texts.reminderBody(running),
    finishLabel: texts.finishLabel,
    payload: shiftPayload(running),
  );
}

/// Removes the running-shift notification and the reminder (no shift runs).
Future<void> clearShiftNotifications(NotificationService service) async {
  await service.cancelRunningShift();
  await service.cancelReminder();
}
