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
  String get todayEarnedToday => 'Earned today';

  @override
  String get todayOpenLabel => 'Unpaid';

  @override
  String get todayOpenTotal => 'Unpaid total';

  @override
  String get todayThisShift => 'Of which this shift';

  @override
  String todayShiftsHours(int count, String hours) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count shifts · $hours',
      one: '1 shift · $hours',
    );
    return '$_temp0';
  }

  @override
  String get todayNothingOpen => 'No unpaid shifts';

  @override
  String get todayRecordPayout => 'Record payout';

  @override
  String todayStatusWithJob(String status, String job) {
    return '$status · $job';
  }

  @override
  String todayPausedSince(String time) {
    return 'Paused since $time';
  }

  @override
  String todaySince(String time) {
    return 'since $time';
  }

  @override
  String get todayAdjustStart => 'Change start time';

  @override
  String todayWorkedSemantics(String duration) {
    return 'Worked $duration';
  }

  @override
  String todayBreak(String duration) {
    return 'Break $duration';
  }

  @override
  String get todayStartShift => 'Start shift';

  @override
  String get todayStartedEarlier => 'Started earlier?';

  @override
  String get todayStartTimeHelp => 'When did you start?';

  @override
  String get todayChooseJob => 'Choose job';

  @override
  String todayJobSemantics(String job) {
    return 'Job: $job';
  }

  @override
  String get todayPause => 'Pause';

  @override
  String get todayResume => 'Resume';

  @override
  String get todayFinish => 'Finish';

  @override
  String get todayThisWeek => 'This week';

  @override
  String todayWeekFigures(String hours, String amount) {
    return '$hours · $amount';
  }

  @override
  String get todayLastShift => 'Last shift';

  @override
  String todayLastShiftDetails(String date, String times, String duration) {
    return '$date, $times · $duration';
  }

  @override
  String get todayShiftsTodayTitle => 'Today\'s shifts';

  @override
  String get todayNoShiftsToday => 'No finished shifts today yet.';

  @override
  String todayReviewHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Check $count imported entries',
      one: 'Check 1 imported entry',
    );
    return '$_temp0';
  }

  @override
  String get todayReviewAction => 'Review';

  @override
  String get todayNotificationsOff =>
      'Notifications are off, so the running shift doesn\'t appear on your lock screen.';

  @override
  String get todayPrimerTitle => 'Your shift on the lock screen';

  @override
  String get todayPrimerBody =>
      'While a shift is running, Chronos shows it in a quiet notification. From there you can pause or finish it without opening the app. Nothing runs in the background.';

  @override
  String get todayPrimerAllow => 'Allow notifications';

  @override
  String get todayPrimerLater => 'Not now';

  @override
  String get todayOverlapTitle => 'Overlaps another shift';

  @override
  String todayOverlapMessage(String shifts) {
    return 'This start time overlaps: $shifts';
  }

  @override
  String get todayOverlapStartAnyway => 'Start anyway';

  @override
  String get todayOverlapChangeAnyway => 'Change anyway';

  @override
  String todayStartChanged(String time) {
    return 'Start changed to $time';
  }

  @override
  String get todayErrorStartInFuture =>
      'The start time can\'t be in the future.';

  @override
  String get todayErrorStartAfterBreak =>
      'The start must be before the current break began.';

  @override
  String get todayErrorAlreadyRunning => 'A shift is already running.';

  @override
  String get todayErrorNoRunningShift => 'No shift is running.';

  @override
  String get todayErrorNoWage =>
      'This job has no hourly rate yet. Add one in Settings.';

  @override
  String get todayErrorJobNotFound => 'This job no longer exists.';

  @override
  String get todayErrorShiftNotFound => 'This shift no longer exists.';

  @override
  String todayShiftSaved(String duration, String amount) {
    return 'Shift saved · $duration · $amount';
  }

  @override
  String get todayShiftDiscarded => 'Shift discarded';

  @override
  String get todayFinishSheetTitle => 'Finish shift';

  @override
  String get todayFinishStart => 'Start';

  @override
  String get todayFinishEnd => 'End';

  @override
  String todayFinishRoundedTimes(String recorded, String billed) {
    return 'Recorded $recorded, billed $billed';
  }

  @override
  String todayFinishRoundingNote(int minutes) {
    return 'Rounded to the nearest $minutes minutes (job setting)';
  }

  @override
  String todayFinishBilledEnd(String time) {
    return 'Billed: $time';
  }

  @override
  String todayFinishEndDate(String date) {
    return 'on $date';
  }

  @override
  String get todayFinishBreak => 'Break';

  @override
  String get todayMinutesUnit => 'min';

  @override
  String get todayFinishWorked => 'Worked';

  @override
  String todayFinishCalculation(String duration, String rate) {
    return '$duration × $rate';
  }

  @override
  String get todayFinishTips => 'Tips (optional)';

  @override
  String get todayFinishNote => 'Note (optional)';

  @override
  String get todayFinishKeepRunning => 'Keep running';

  @override
  String get todayFinishErrorEndNotAfterStart =>
      'The end must be after the start.';

  @override
  String get todayFinishErrorBreakTooLong =>
      'The break must be shorter than the shift.';

  @override
  String get todayFinishErrorEndInFuture => 'The end can\'t be in the future.';

  @override
  String get todayDiscardTitle => 'Discard this shift?';

  @override
  String get todayDiscardMessage =>
      'The running shift won\'t be saved. You can undo this right afterwards.';
}
