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
  String get currentEarnings => 'Current Earnings';

  @override
  String get totalOpenEarnings => 'Total Open Amount';

  @override
  String get start => 'START';

  @override
  String get stop => 'STOP';

  @override
  String get confirmStopTitle => 'Stop Timer?';

  @override
  String get confirmStop => 'Are you sure you want to stop?';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get workTimeLog => 'Work Time Log';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get theme => 'Theme';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get lightMode => 'Light Mode';

  @override
  String get hourlyWage => 'Hourly Wage (€)';

  @override
  String get enterWage => 'Enter wage';

  @override
  String get workEntries => 'Work Entries';

  @override
  String get addEntry => 'Add Entry';

  @override
  String get editEntry => 'Edit Entry';

  @override
  String get delete => 'Delete';

  @override
  String get date => 'Date';

  @override
  String get startTime => 'Start Time';

  @override
  String get endTime => 'End Time';

  @override
  String get totalTime => 'Total Time';

  @override
  String get paid => 'Paid';

  @override
  String get save => 'Save';

  @override
  String get noEntries => 'No entries available';

  @override
  String get hours => 'h';

  @override
  String get minutes => 'min';

  @override
  String get earned => 'Earned';

  @override
  String get entryDeleted => 'Entry deleted';

  @override
  String get entrySaved => 'Entry saved';

  @override
  String get tooShortEntry => 'Too short (under 15 min). Entry was not saved.';

  @override
  String get workSaved => 'Work time saved';

  @override
  String get endAfterStart => 'End time must be after start time';

  @override
  String get wageExample => 'Example: 15 or 15.50';

  @override
  String get confirmDelete => 'Really delete this entry?';

  @override
  String get unmarkPaidTitle => 'Remove billing?';

  @override
  String get unmarkPaidContent => 'Really mark this entry as unpaid?';
}
