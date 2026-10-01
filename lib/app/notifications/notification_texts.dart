import 'dart:ui' show Locale;

import '../../core/format.dart';
import '../../domain/app_settings.dart';
import '../../domain/shift.dart';
import '../../l10n/app_localizations.dart';
import '../../platform/notifications.dart';
import '../startup/app_locale.dart';

/// Localized texts of the running-shift notification and the reminder.
///
/// Built outside the widget tree (side effects, background isolate) from the
/// app language and the device's locales and 12/24-hour preference.
class NotificationTexts {
  /// Texts in [locale]; times use the 24-hour clock if [use24HourFormat].
  NotificationTexts(this.locale, {required bool use24HourFormat})
    : l10n = lookupAppLocalizations(locale),
      fmt = Fmt(locale, use24HourFormat: use24HourFormat);

  /// Texts for the app [language] (or the device language for
  /// [AppLanguage.system]).
  factory NotificationTexts.forLanguage(
    AppLanguage language, {
    required List<Locale> deviceLocales,
    required bool use24HourFormat,
  }) => NotificationTexts(
    localeForLanguage(language, deviceLocales),
    use24HourFormat: use24HourFormat,
  );

  /// The locale of the texts (with region, e.g. `de_AT`).
  final Locale locale;

  /// The strings.
  final AppLocalizations l10n;

  /// Number and time formatting.
  final Fmt fmt;

  /// Names and descriptions of the notification channels.
  NotificationChannelTexts get channelTexts => NotificationChannelTexts(
    runningShiftName: l10n.notificationChannelRunningName,
    runningShiftDescription: l10n.notificationChannelRunningDescription,
    remindersName: l10n.notificationChannelRemindersName,
    remindersDescription: l10n.notificationChannelRemindersDescription,
  );

  /// "Schicht läuft" or "Schicht läuft · Café" (pass [jobName] only when the
  /// user has more than one job).
  String runningTitle(String? jobName) => jobName == null || jobName.isEmpty
      ? l10n.notificationRunningTitle
      : l10n.notificationRunningTitleWithJob(jobName);

  /// "seit 08:02 · 15,00 €/h" or, while paused, "Pausiert seit 14:32".
  String runningBody(Shift shift) {
    final pausedAt = shift.pausedAtUtc;
    if (shift.isPaused && pausedAt != null) {
      return l10n.notificationPausedBody(fmt.time(pausedAt.toLocal()));
    }
    return l10n.notificationRunningBody(
      fmt.time(shift.startUtc.toLocal()),
      fmt.rate(shift.rateCentsPerHour),
    );
  }

  /// "Pause".
  String get pauseLabel => l10n.notificationActionPause;

  /// "Fortsetzen".
  String get resumeLabel => l10n.notificationActionResume;

  /// "Beenden".
  String get finishLabel => l10n.notificationActionFinish;

  /// "Arbeitest du noch?".
  String get reminderTitle => l10n.notificationReminderTitle;

  /// "Deine Schicht läuft seit 08:02. …".
  String reminderBody(Shift shift) =>
      l10n.notificationReminderBody(fmt.time(shift.startUtc.toLocal()));
}
