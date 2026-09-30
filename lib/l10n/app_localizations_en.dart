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
  String get shiftsAddShift => 'Shift';

  @override
  String get shiftsAddShiftTooltip => 'Add shift';

  @override
  String get shiftsFilterLabel => 'Show shifts';

  @override
  String shiftsRunningSince(String time) {
    return 'Running since $time';
  }

  @override
  String shiftsPausedSince(String time) {
    return 'Paused since $time';
  }

  @override
  String get shiftsRunningOpenToday => 'Open on Today';

  @override
  String shiftsMonthOpen(String amount) {
    return '$amount unpaid';
  }

  @override
  String shiftsBreak(String duration) {
    return 'Break $duration';
  }

  @override
  String shiftsTips(String amount) {
    return 'Tips $amount';
  }

  @override
  String shiftsTimeRangeSpoken(String start, String end) {
    return '$start to $end';
  }

  @override
  String shiftsTimeRangeSpokenNextDay(String start, String end) {
    return '$start to $end the next day';
  }

  @override
  String get shiftsEmptyTitle => 'No shifts yet';

  @override
  String get shiftsEmptyMessage =>
      'Start a shift on Today, or add one you have already worked.';

  @override
  String get shiftsStartShift => 'Start shift';

  @override
  String get shiftsAddPastShift => 'Add past shift';

  @override
  String get shiftsEmptyOpenTitle => 'No unpaid shifts';

  @override
  String get shiftsEmptyOpenMessage => 'Everything has been paid.';

  @override
  String get shiftsEmptyPaidTitle => 'No paid shifts yet';

  @override
  String get shiftsEmptyPaidMessage =>
      'Mark shifts as paid or record a payout.';

  @override
  String get shiftsShowAll => 'Show all shifts';

  @override
  String get shiftsMarkPaid => 'Mark as paid';

  @override
  String get shiftsMarkOpen => 'Mark as unpaid';

  @override
  String get shiftsMarkedPaid => 'Marked as paid';

  @override
  String get shiftsMarkedOpen => 'Marked as unpaid';

  @override
  String get shiftsDeleted => 'Shift deleted';

  @override
  String shiftsSaved(String duration, String amount) {
    return 'Shift saved · $duration · $amount';
  }

  @override
  String get shiftsErrorNotFound => 'This shift no longer exists.';

  @override
  String get shiftsErrorRunning => 'The running shift can be changed on Today.';

  @override
  String get shiftsErrorAlreadyRunning => 'Another shift is already running.';

  @override
  String get shiftsErrorJobNotFound => 'This job no longer exists.';

  @override
  String get shiftsErrorNoWage => 'This job has no hourly wage yet.';

  @override
  String get shiftsErrorInvalid => 'Please check your input.';

  @override
  String get editorTitleNew => 'New shift';

  @override
  String get editorTitleEdit => 'Edit shift';

  @override
  String get editorJob => 'Job';

  @override
  String get editorDate => 'Date';

  @override
  String get editorPickDate => 'Choose date';

  @override
  String get editorStart => 'Start';

  @override
  String get editorEnd => 'End';

  @override
  String get editorEndsNextDay => 'Ends the next day';

  @override
  String get editorEndsNextDayAuto =>
      'Turned on because the end is before the start';

  @override
  String get editorBreak => 'Break';

  @override
  String editorBreakLess(int minutes) {
    return '$minutes minutes less break';
  }

  @override
  String editorBreakMore(int minutes) {
    return '$minutes minutes more break';
  }

  @override
  String get editorBreakInvalid => 'Enter the break in whole minutes';

  @override
  String get editorTips => 'Tips';

  @override
  String get editorNote => 'Note';

  @override
  String get editorStatus => 'Status';

  @override
  String editorPreview(String duration, String rate, String amount) {
    return '$duration × $rate = $amount';
  }

  @override
  String editorPreviewSpoken(String duration, String rate, String amount) {
    return '$duration at $rate makes $amount';
  }

  @override
  String editorPreviewTips(String amount) {
    return 'plus $amount tips';
  }

  @override
  String get editorErrorEndNotAfterStart => 'The end must be after the start.';

  @override
  String get editorErrorBreakTooLong =>
      'The break must be shorter than the shift.';

  @override
  String editorWarningLong(String duration) {
    return 'Longer than 16 hours ($duration)';
  }

  @override
  String editorWarningOverlap(String date, String time) {
    return 'Overlaps $date · $time';
  }

  @override
  String editorWarningOverlapRunning(String time) {
    return 'Overlaps the running shift (since $time)';
  }

  @override
  String get editorWarningFuture => 'Starts in the future';

  @override
  String get editorConfirmTitle => 'Save anyway?';

  @override
  String get editorConfirmSave => 'Save anyway';

  @override
  String get editorDiscardTitle => 'Discard changes?';

  @override
  String get editorDiscardMessage => 'Your changes to this shift will be lost.';

  @override
  String get editorKeepEditing => 'Keep editing';

  @override
  String get editorCopyNotice =>
      'Copy created for today. Adjust it or delete it.';

  @override
  String get payoutTitle => 'Record payout';

  @override
  String get payoutAllJobs => 'All jobs';

  @override
  String get payoutUntil => 'Up to and including';

  @override
  String payoutSummary(int count, String hours) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count shifts',
      one: '1 shift',
    );
    return '$_temp0 · $hours';
  }

  @override
  String get payoutExpected => 'Expected';

  @override
  String get payoutReceived => 'Received';

  @override
  String get payoutDifference => 'Difference';

  @override
  String payoutDifferencePositive(String amount) {
    return '+$amount';
  }

  @override
  String get payoutPaidOn => 'Paid on';

  @override
  String payoutSubmit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Mark $count shifts as paid',
      one: 'Mark 1 shift as paid',
    );
    return '$_temp0';
  }

  @override
  String get payoutNothingOpen => 'There are no unpaid shifts up to this date.';

  @override
  String payoutRecorded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count shifts marked as paid',
      one: '1 shift marked as paid',
    );
    return '$_temp0';
  }

  @override
  String get payoutErrorAmount => 'The received amount is not valid.';
}
