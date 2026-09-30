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
  String get startupLoading => 'Starting Chronos…';

  @override
  String startupMigratedNotice(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entries taken over from Chronos 1',
      one: '1 entry taken over from Chronos 1',
    );
    return '$_temp0';
  }

  @override
  String get startupMigratedReview => 'Review';

  @override
  String get onboardingDefaultJobName => 'My job';

  @override
  String get onboardingWelcomeTitle =>
      'Track shifts. Watch your pay grow live.';

  @override
  String get onboardingWelcomeBody =>
      'Works offline. Your data stays on your phone.';

  @override
  String get onboardingStart => 'Get started';

  @override
  String onboardingStepLabel(int step, int total) {
    return 'Step $step of $total';
  }

  @override
  String get onboardingJobTitle => 'Your job';

  @override
  String get onboardingJobSubtitle =>
      'Enter your hourly rate. You can change everything later.';

  @override
  String get onboardingNameLabel => 'Name (optional)';

  @override
  String get onboardingRateLabel => 'Hourly rate';

  @override
  String get onboardingRateHelper => 'Gross per hour';

  @override
  String get onboardingMoreJobsLater =>
      'You can add more jobs later in Settings.';

  @override
  String wageCheckTitle(String rate) {
    return '$rate taken over – is that right?';
  }

  @override
  String get wageCheckTooHigh =>
      'That\'s unusually high. The old version sometimes lost the decimal separator, so 12.50 became 1250.';

  @override
  String get wageCheckTooLow => 'That\'s unusually low for an hourly rate.';

  @override
  String get wageCheckUnusuallyHigh =>
      'That\'s unusually high for an hourly rate.';

  @override
  String get wageCheckFieldLabel => 'Correct hourly rate';

  @override
  String get wageCheckFieldHelper =>
      'Applies to the job and to all shifts taken over.';

  @override
  String get wageCheckFix => 'Use this rate';

  @override
  String wageCheckKeep(String rate) {
    return 'Keep $rate';
  }

  @override
  String wageCheckFixed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Hourly rate corrected · $count shifts updated',
      one: 'Hourly rate corrected · 1 shift updated',
      zero: 'Hourly rate corrected',
    );
    return '$_temp0';
  }

  @override
  String wageCheckConfirmTitle(String rate) {
    return '$rate – is that right?';
  }

  @override
  String get wageCheckConfirmYes => 'Yes, that\'s right';

  @override
  String get wageCheckConfirmEdit => 'Change';

  @override
  String get recoveryTitle => 'Chronos couldn\'t start';

  @override
  String get recoveryMessage =>
      'Your data couldn\'t be loaded. Nothing has been deleted. Try again, or share the raw data and an error report so the problem can be fixed.';

  @override
  String get recoveryShareRawData => 'Share raw data';

  @override
  String get recoveryShareErrorReport => 'Share error report';

  @override
  String get recoveryDetails => 'Technical details';

  @override
  String get recoveryRawDataSubject => 'Chronos raw data';

  @override
  String get recoveryErrorReportSubject => 'Chronos error report';

  @override
  String get recoveryShareFailed => 'Couldn\'t prepare the file.';

  @override
  String get reviewTitle => 'Review entries';

  @override
  String get reviewIntro =>
      'These entries from the old version look unusual. Check them and fix them if needed – nothing was changed automatically.';

  @override
  String reviewSectionShifts(int count) {
    return 'Shifts to check ($count)';
  }

  @override
  String reviewShiftSummary(String times, String duration) {
    return '$times · $duration';
  }

  @override
  String get reviewReasonTooLong => 'Longer than 16 hours';

  @override
  String get reviewReasonExactly23or24h =>
      'Exactly 23 or 24 hours – the end may be wrong';

  @override
  String get reviewReasonDuplicateTimes => 'Same times as another shift';

  @override
  String get reviewReasonDuplicateLegacyId =>
      'Duplicate entry from the old version';

  @override
  String get reviewReasonOverlap => 'Overlaps another shift';

  @override
  String get reviewReasonDstDay =>
      'On a daylight saving time switch day – check the times';

  @override
  String get reviewDismiss => 'Looks fine';

  @override
  String get reviewDismissAll => 'Mark all as checked';

  @override
  String reviewDismissAllTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Mark $count entries as checked?',
      one: 'Mark 1 entry as checked?',
    );
    return '$_temp0';
  }

  @override
  String get reviewDismissAllMessage =>
      'The shifts stay as they are; only the hints disappear.';

  @override
  String get reviewShiftDeleted => 'This shift was deleted.';

  @override
  String reviewSectionFailures(int count) {
    return 'Not taken over ($count)';
  }

  @override
  String get reviewFailuresIntro =>
      'These entries couldn\'t be read. They\'re not lost: the original data stays on your phone and can be shared.';

  @override
  String get reviewFailureInvalidJson => 'The stored data is unreadable';

  @override
  String get reviewFailureNotAList => 'The list of entries is unreadable';

  @override
  String get reviewFailureNotAnObject => 'The entry is unreadable';

  @override
  String get reviewFailureMissingStart => 'Start time is missing';

  @override
  String get reviewFailureInvalidStart => 'Start time is unreadable';

  @override
  String get reviewFailureMissingEnd => 'End time is missing';

  @override
  String get reviewFailureInvalidEnd => 'End time is unreadable';

  @override
  String get reviewFailureEndNotAfterStart => 'The end is not after the start';

  @override
  String get reviewFailureInvalidActiveSession =>
      'The running session is unreadable';

  @override
  String get reviewFailureRunningShiftExists =>
      'Another shift was already running';

  @override
  String get reviewFailureInvalidSettings =>
      'Settings were unreadable – defaults are used';

  @override
  String get reviewFailureInsertFailed => 'The entry couldn\'t be saved';

  @override
  String get reviewEmptyTitle => 'All checked';

  @override
  String get reviewEmptyMessage =>
      'There are no entries from the old version left to check.';

  @override
  String get notificationChannelRunningName => 'Running shift';

  @override
  String get notificationChannelRunningDescription =>
      'Shows the running shift with a stopwatch.';

  @override
  String get notificationChannelRemindersName => 'Reminders';

  @override
  String get notificationChannelRemindersDescription =>
      'Asks whether you\'re still working after a long shift.';

  @override
  String get notificationRunningTitle => 'Shift running';

  @override
  String notificationRunningTitleWithJob(String job) {
    return 'Shift running · $job';
  }

  @override
  String notificationRunningBody(String time, String rate) {
    return 'since $time · $rate';
  }

  @override
  String notificationPausedBody(String time) {
    return 'Paused since $time';
  }

  @override
  String get notificationActionPause => 'Pause';

  @override
  String get notificationActionResume => 'Resume';

  @override
  String get notificationActionFinish => 'Finish';

  @override
  String get notificationReminderTitle => 'Still working?';

  @override
  String notificationReminderBody(String time) {
    return 'Your shift has been running since $time. Tap Finish when you\'re done.';
  }
}
