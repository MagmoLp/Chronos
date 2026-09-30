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
}
