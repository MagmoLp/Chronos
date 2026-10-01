// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Chronos';

  @override
  String get navToday => 'Today';

  @override
  String get navShifts => 'Shifts';

  @override
  String get navInsights => 'Insights';

  @override
  String get commonSave => 'Save';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonUndo => 'Undo';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonDuplicate => 'Duplicate';

  @override
  String get commonRetry => 'Try again';

  @override
  String get commonClose => 'Close';

  @override
  String get commonDone => 'Done';

  @override
  String get commonNext => 'Next';

  @override
  String get commonBack => 'Back';

  @override
  String get commonShare => 'Share';

  @override
  String get commonSettings => 'Settings';

  @override
  String get commonOk => 'OK';

  @override
  String get commonDiscard => 'Discard';

  @override
  String get commonAdd => 'Add';

  @override
  String get commonExport => 'Export';

  @override
  String get commonDismiss => 'Dismiss';

  @override
  String get commonMoreOptions => 'More options';

  @override
  String get commonOpenSettings => 'Open settings';

  @override
  String get commonLoading => 'Loading…';

  @override
  String get commonAll => 'All';

  @override
  String get statusPaid => 'Paid';

  @override
  String get statusOpen => 'Unpaid';

  @override
  String get statusRunning => 'Running';

  @override
  String get statusPaused => 'Paused';

  @override
  String get dateToday => 'Today';

  @override
  String get dateYesterday => 'Yesterday';

  @override
  String formatToday(String date) {
    return 'Today, $date';
  }

  @override
  String formatHours(String value) {
    return '$value h';
  }

  @override
  String formatMinutes(String value) {
    return '$value min';
  }

  @override
  String formatRatePerHour(String amount) {
    return '$amount/h';
  }

  @override
  String durationSpokenHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours',
      one: '1 hour',
    );
    return '$_temp0';
  }

  @override
  String durationSpokenMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes',
      one: '1 minute',
    );
    return '$_temp0';
  }

  @override
  String durationSpokenHoursMinutes(String hours, String minutes) {
    return '$hours $minutes';
  }

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get errorLoadFailed => 'Couldn\'t load your data.';

  @override
  String get errorSaveFailed => 'Couldn\'t save. Please try again.';

  @override
  String get errorRequired => 'Please enter a value';

  @override
  String errorInvalidAmount(String example) {
    return 'Enter an amount like $example';
  }

  @override
  String get errorAmountNotPositive => 'The amount must be greater than 0';

  @override
  String errorInvalidTime(String example) {
    return 'Enter a time like $example';
  }

  @override
  String get timeFieldPick => 'Choose time';

  @override
  String timeFieldEarlier(int minutes) {
    return '$minutes minutes earlier';
  }

  @override
  String timeFieldLater(int minutes) {
    return '$minutes minutes later';
  }

  @override
  String get exportTitle => 'Export';

  @override
  String get exportRange => 'Period';

  @override
  String get exportRangeThisWeek => 'This week';

  @override
  String get exportRangeThisMonth => 'This month';

  @override
  String get exportRangeLastMonth => 'Last month';

  @override
  String get exportRangeCustom => 'Choose dates';

  @override
  String exportRangeValue(String start, String end) {
    return '$start – $end';
  }

  @override
  String get exportJob => 'Job';

  @override
  String get exportAllJobs => 'All jobs';

  @override
  String get exportFormat => 'Format';

  @override
  String get exportFormatPdf => 'PDF';

  @override
  String get exportFormatCsv => 'CSV';

  @override
  String get exportFormatPdfHelp =>
      'Timesheet with totals and signature lines, ready to hand in.';

  @override
  String get exportFormatCsvHelp => 'Table for Excel or Google Sheets.';

  @override
  String get exportName => 'Your name (optional)';

  @override
  String get exportNameHelp => 'Printed at the top of the timesheet';

  @override
  String get exportIncludeNotes => 'Include notes';

  @override
  String exportSummary(int count, String hours, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count shifts · $hours · $amount',
      one: '1 shift · $hours · $amount',
    );
    return '$_temp0';
  }

  @override
  String get exportEmpty => 'No shifts in this period.';

  @override
  String get exportPreparing => 'Preparing…';

  @override
  String get exportFailed => 'The export didn\'t work. Please try again.';

  @override
  String get exportFileBase => 'timesheet';

  @override
  String exportSubject(String period) {
    return 'Timesheet $period';
  }

  @override
  String get exportColDate => 'Date';

  @override
  String get exportColStart => 'Start';

  @override
  String get exportColEnd => 'End';

  @override
  String get exportColBreak => 'Break';

  @override
  String get exportColBreakMinutes => 'Break (min)';

  @override
  String get exportColHours => 'Hours';

  @override
  String get exportColRate => 'Hourly rate';

  @override
  String get exportColRateShort => 'Rate';

  @override
  String get exportColAmount => 'Amount';

  @override
  String get exportColTips => 'Tips';

  @override
  String get exportColStatus => 'Status';

  @override
  String get exportColJob => 'Job';

  @override
  String get exportColNote => 'Note';

  @override
  String get exportTotal => 'Total';

  @override
  String get exportPdfTitle => 'Timesheet';

  @override
  String get exportPdfName => 'Name';

  @override
  String get exportPdfPeriod => 'Period';

  @override
  String exportPdfRowDate(String weekday, String date) {
    return '$weekday $date';
  }

  @override
  String get exportPdfSignatureEmployee => 'Date, employee signature';

  @override
  String get exportPdfSignatureEmployer => 'Date, employer signature';

  @override
  String exportPdfCreatedOn(String date) {
    return 'Created on $date with Chronos';
  }

  @override
  String exportPdfPage(int page, int count) {
    return 'Page $page of $count';
  }

  @override
  String get insightsPeriodWeek => 'Week';

  @override
  String get insightsPeriodMonth => 'Month';

  @override
  String get insightsPeriodYear => 'Year';

  @override
  String get insightsPeriodChoice => 'Period length';

  @override
  String get insightsPrevious => 'Previous period';

  @override
  String get insightsNext => 'Next period';

  @override
  String insightsWeekTitle(String start, String end, String year) {
    return '$start – $end $year';
  }

  @override
  String get insightsStatHours => 'Hours';

  @override
  String get insightsStatEarned => 'Earned';

  @override
  String get insightsStatOpen => 'Unpaid';

  @override
  String get insightsStatAverage => 'Avg. per hour incl. tips';

  @override
  String get insightsStatTips => 'Tips';

  @override
  String insightsShiftCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count shifts',
      one: '1 shift',
      zero: 'No shifts',
    );
    return '$_temp0';
  }

  @override
  String get insightsNoValue => '–';

  @override
  String get insightsChartDays => 'Earnings per day';

  @override
  String get insightsChartMonths => 'Earnings per month';

  @override
  String get insightsChartHint => 'Tap a bar for details';

  @override
  String insightsChartSelection(String label, String amount, String hours) {
    return '$label: $amount · $hours';
  }

  @override
  String insightsChartBar(String label, String amount, String hours) {
    return '$label: $amount, $hours';
  }

  @override
  String get insightsChartEmpty => 'No shifts in this period yet.';

  @override
  String insightsAxisEuros(String value) {
    return '€$value';
  }

  @override
  String get insightsGoalTitle => 'Monthly goal';

  @override
  String get insightsLimitTitle => 'Monthly limit';

  @override
  String insightsGoalProgress(String earned, String target) {
    return '$earned / $target';
  }

  @override
  String insightsGoalRemaining(String amount) {
    return '$amount to go';
  }

  @override
  String get insightsGoalReached => 'Goal reached';

  @override
  String insightsLimitRemaining(String amount) {
    return '$amount left until the limit';
  }

  @override
  String insightsLimitWarning(String amount) {
    return 'Almost at the limit – $amount left';
  }

  @override
  String insightsLimitExceeded(String amount) {
    return 'Limit exceeded by $amount';
  }

  @override
  String insightsGoalMonth(String month) {
    return 'Current month: $month';
  }

  @override
  String get insightsGoalSetUp => 'Set a monthly goal or limit';

  @override
  String get insightsByJob => 'By job';

  @override
  String insightsJobLine(String hours, String amount) {
    return '$hours · $amount';
  }

  @override
  String get insightsPayouts => 'Payouts';

  @override
  String get insightsPayoutsEmpty => 'No payouts in this period.';

  @override
  String insightsPayoutMore(String amount) {
    return '$amount more than expected';
  }

  @override
  String insightsPayoutLess(String amount) {
    return '$amount less than expected';
  }

  @override
  String get insightsPayoutExact => 'As expected';

  @override
  String get insightsExport => 'Export this period';

  @override
  String get settingsSectionGeneral => 'General';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSystem => 'System';

  @override
  String get settingsLanguageGerman => 'Deutsch';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsSectionWork => 'Work';

  @override
  String get settingsJobs => 'Jobs & hourly wage';

  @override
  String settingsJobsOne(String name, String rate) {
    return '$name · $rate';
  }

  @override
  String settingsJobsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jobs',
      one: '1 job',
      zero: 'No jobs yet',
    );
    return '$_temp0';
  }

  @override
  String get settingsGoal => 'Monthly goal or limit';

  @override
  String get settingsGoalOff => 'Off';

  @override
  String settingsGoalGoalValue(String amount) {
    return 'Goal: $amount';
  }

  @override
  String settingsGoalLimitValue(String amount) {
    return 'Limit: $amount';
  }

  @override
  String get settingsGoalTypeGoal => 'Goal';

  @override
  String get settingsGoalTypeLimit => 'Limit';

  @override
  String get settingsGoalAmount => 'Amount per month';

  @override
  String get settingsGoalHelpOff => 'No progress bar in Insights.';

  @override
  String get settingsGoalHelpGoal =>
      'Shows how close you are to your monthly target.';

  @override
  String get settingsGoalHelpLimit =>
      'Warns from 80 % – e.g. for the €603 Minijob limit.';

  @override
  String get settingsReminder => '“Still working?” reminder';

  @override
  String get settingsReminderOff => 'Off';

  @override
  String settingsReminderHours(int hours) {
    return 'After $hours h';
  }

  @override
  String get settingsReminderHelp =>
      'Reminds you when a shift is still running after this time.';

  @override
  String get settingsSectionNotifications => 'Notifications';

  @override
  String get settingsNotificationsOn => 'Allowed';

  @override
  String get settingsNotificationsOnHint =>
      'The running shift and reminders appear in the status bar';

  @override
  String get settingsNotificationsOffTitle => 'Turned off';

  @override
  String get settingsNotificationsOff =>
      'The running shift is not shown in the status bar. Tap to allow notifications.';

  @override
  String get settingsNotificationsOpen => 'Open system settings';

  @override
  String get settingsSectionData => 'Data';

  @override
  String get dataExport => 'Export';

  @override
  String get dataExportSubtitle => 'PDF timesheet or CSV table';

  @override
  String get dataBackupCreate => 'Create backup';

  @override
  String get dataBackupCreateSubtitle => 'Save all data as a file';

  @override
  String dataBackupSubject(String date) {
    return 'Chronos backup $date';
  }

  @override
  String get dataBackupRestore => 'Restore backup';

  @override
  String get dataBackupRestoreSubtitle => 'From a Chronos backup file';

  @override
  String get dataBackupPickTitle => 'Choose a Chronos backup';

  @override
  String get dataRestoreTitle => 'Restore this backup?';

  @override
  String dataRestoreCreated(String date) {
    return 'Created on $date';
  }

  @override
  String dataRestoreRange(String start, String end) {
    return 'Shifts from $start to $end';
  }

  @override
  String dataCountShifts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count shifts',
      one: '1 shift',
    );
    return '$_temp0';
  }

  @override
  String dataCountJobs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jobs',
      one: '1 job',
    );
    return '$_temp0';
  }

  @override
  String dataCountPayouts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count payouts',
      one: '1 payout',
    );
    return '$_temp0';
  }

  @override
  String get dataRestoreExplain =>
      'Replace deletes your current data first. Merge only adds what is missing.';

  @override
  String get dataRestoreReplace => 'Replace';

  @override
  String get dataRestoreMerge => 'Merge';

  @override
  String dataRestoreDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Backup restored · $count shifts',
      one: 'Backup restored · 1 shift',
      zero: 'Backup restored',
    );
    return '$_temp0';
  }

  @override
  String dataMergeDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count shifts added',
      one: '1 shift added',
      zero: 'Nothing new – everything was already there',
    );
    return '$_temp0';
  }

  @override
  String get dataRestoreInvalid => 'This file isn\'t a valid Chronos backup.';

  @override
  String get dataRestoreNewer =>
      'This backup is from a newer Chronos version. Please update the app first.';

  @override
  String get dataRestoreTooLarge => 'This file is too large for a backup.';

  @override
  String get dataDeleteAll => 'Delete all data';

  @override
  String get dataDeleteAllSubtitle => 'A backup is saved on the device first';

  @override
  String dataDeleteTitle(String shifts, String jobs) {
    return 'Delete $shifts and $jobs?';
  }

  @override
  String get dataDeleteMessage =>
      'Payouts are deleted too. A backup is saved on the device first, and you can undo right afterwards.';

  @override
  String get dataDeleted => 'All data deleted';

  @override
  String get dataNothingToDelete => 'There is no data to delete.';

  @override
  String get settingsSectionAbout => 'About';

  @override
  String get aboutVersion => 'Version';

  @override
  String aboutVersionValue(String version, String build) {
    return '$version (build $build)';
  }

  @override
  String get aboutPrivacy => 'Privacy policy';

  @override
  String get aboutLicenses => 'Open-source licenses';

  @override
  String get aboutErrorReport => 'Share error report';

  @override
  String get aboutErrorReportSubtitle =>
      'Local error log – only sent if you share it';

  @override
  String get aboutErrorReportEmpty => 'No errors logged';

  @override
  String get aboutErrorReportSubject => 'Chronos error report';

  @override
  String get aboutFileBase => 'error-report';

  @override
  String jobsRateSince(String rate, String date) {
    return '$rate since $date';
  }

  @override
  String get jobsAdd => 'Add job';

  @override
  String get jobsActiveSection => 'Active';

  @override
  String get jobsArchivedSection => 'Archived';

  @override
  String get jobsNewTitle => 'New job';

  @override
  String get jobsEditTitle => 'Edit job';

  @override
  String get jobsName => 'Name';

  @override
  String get jobsNameHint => 'e.g. Café Müller';

  @override
  String get jobsColor => 'Colour';

  @override
  String get jobsColorBlue => 'Blue';

  @override
  String get jobsColorTeal => 'Teal';

  @override
  String get jobsColorOchre => 'Ochre';

  @override
  String get jobsColorRaspberry => 'Raspberry';

  @override
  String get jobsColorViolet => 'Violet';

  @override
  String get jobsColorGreen => 'Green';

  @override
  String get jobsRate => 'Hourly wage';

  @override
  String get jobsRateNewHelp =>
      'You can add later wage changes with a start date.';

  @override
  String get jobsRounding => 'Rounding of timer shifts';

  @override
  String get jobsRoundingOff => 'Off';

  @override
  String get jobsRoundingHelp =>
      'Start and end are rounded to the nearest step when you finish a shift. Shifts you enter yourself are never rounded.';

  @override
  String get jobsRateHistory => 'Wage history';

  @override
  String jobsRateFrom(String date) {
    return 'from $date';
  }

  @override
  String get jobsRateCurrent => 'Current';

  @override
  String get jobsRateAdd => 'New wage from …';

  @override
  String get jobsRateDelete => 'Delete wage';

  @override
  String get jobsRateDeleteLast => 'The last wage can\'t be deleted.';

  @override
  String get jobsRateDeleted => 'Wage deleted';

  @override
  String get jobsRateDialogTitle => 'New hourly wage';

  @override
  String get jobsRateValidFrom => 'Valid from';

  @override
  String get jobsRateRecalc => 'Recalculate unpaid shifts from this date';

  @override
  String get jobsRateRecalcHelp => 'Paid shifts always keep their wage.';

  @override
  String jobsRateSaved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Wage saved · $count shifts recalculated',
      one: 'Wage saved · 1 shift recalculated',
      zero: 'Wage saved',
    );
    return '$_temp0';
  }

  @override
  String get jobsArchive => 'Archive job';

  @override
  String get jobsUnarchive => 'Restore job';

  @override
  String get jobsArchiveHelp =>
      'Archived jobs keep their shifts but are no longer offered when you start or add a shift.';

  @override
  String get jobsArchiveLastActive => 'At least one job must stay active.';

  @override
  String jobsArchived(String name) {
    return '$name archived';
  }

  @override
  String jobsUnarchived(String name) {
    return '$name is active again';
  }

  @override
  String get jobsDiscardTitle => 'Discard changes?';

  @override
  String get privacyUpdated =>
      'Last updated: 30 September 2026 (applies from version 2.0)';

  @override
  String get privacyIntro =>
      'This privacy policy applies to the Android app Chronos – Stundenlohn Tracker, developed by Paul Hübner.';

  @override
  String get privacyShortTitle => 'In short';

  @override
  String get privacyShortBody =>
      'Everything you enter in Chronos stays on your device. There is no account, no advertising, no analytics and no tracking. The app has no internet permission and sends nothing to the developer or to third parties.';

  @override
  String get privacyStoredTitle => 'What the app stores';

  @override
  String get privacyStoredIntro =>
      'Chronos stores data only in the app\'s private storage on your device:';

  @override
  String get privacyStoredShifts =>
      'shifts with start, end, breaks, tips, notes and their “open/paid” status,';

  @override
  String get privacyStoredJobs =>
      'jobs with name, colour, hourly wage and wage history,';

  @override
  String get privacyStoredPayouts => 'recorded payouts,';

  @override
  String get privacyStoredSettings =>
      'settings (e.g. language, theme, monthly goal, reminder),';

  @override
  String get privacyStoredErrorLog =>
      'a local error log with technical error messages for troubleshooting.';

  @override
  String get privacyStoredNoAccess =>
      'The developer has no access to this data.';

  @override
  String get privacyExceptionsTitle => 'Exceptions you control';

  @override
  String get privacyAutoBackupTitle => 'Android backup (Auto Backup)';

  @override
  String get privacyAutoBackupBody =>
      'If backup is switched on in your device\'s Android settings, Android automatically backs up Chronos\' data (database and settings) to your own Google account and restores it when you reinstall the app or move to a new device. This is an operating-system feature provided to you by Google; the developer cannot see these backups. On Android 9 and later they are end-to-end encrypted with your screen lock. You can switch backup off in the Android settings (usually under “System” or “Google” → “Backup”) and delete existing backups from your Google account. A direct transfer to a new device (cable or Wi-Fi) takes the same data along.';

  @override
  String get privacyExportTitle => 'Export, backup file and error report';

  @override
  String get privacyExportBody =>
      'Only when you explicitly ask for it, Chronos creates a file (PDF timesheet, CSV, JSON backup or the error log) and opens the Android share sheet. You decide which app or recipient receives the file (e.g. e-mail, messenger, cloud storage). From then on, that service\'s terms apply.';

  @override
  String get privacyRestoreTitle => 'Restoring a backup';

  @override
  String get privacyRestoreBody =>
      'Using the Android file picker, Chronos reads only the single file you select.';

  @override
  String get privacyPermissionsTitle => 'Notifications and permissions';

  @override
  String get privacyPermissionNotifications =>
      'Show notifications (optional): for the running shift with a stopwatch and the “Still working?” reminder. Notifications are created on the device; no push service is used. Without this permission the app keeps working normally.';

  @override
  String get privacyPermissionBoot =>
      'Run at startup: so that a scheduled reminder is scheduled again after a restart.';

  @override
  String get privacyPermissionsNone =>
      'Chronos does not request permissions for the internet, location, contacts, camera or shared storage.';

  @override
  String get privacyNoSharingTitle => 'No sharing, no advertising, no tracking';

  @override
  String get privacyNoSharingBody =>
      'Chronos contains no advertising, no analytics tools, no tracking SDKs and no crash reporting to external servers. No data is sold or passed on to third parties.';

  @override
  String get privacyDeleteTitle => 'Deleting your data';

  @override
  String get privacyDeleteBody =>
      'In the app via “Settings → Data → Delete all data”, or by uninstalling the app or clearing its storage in the Android settings. Backups in your Google account are managed in your Google or Android settings.';

  @override
  String get privacyChangesTitle => 'Changes';

  @override
  String get privacyChangesBody =>
      'If this policy changes, this page will be updated. The date at the top applies.';

  @override
  String get privacyContactTitle => 'Contact';

  @override
  String get privacyContactBody =>
      'If you have questions about privacy, you can reach me at: paulvincent.huebner@gmail.com';
}
