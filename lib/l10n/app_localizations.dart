import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
  ];

  /// App name. Brand, not translated.
  ///
  /// In en, this message translates to:
  /// **'Chronos'**
  String get appTitle;

  /// Bottom navigation / rail label for the Today destination (live shift and balance). One short word.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get navToday;

  /// Navigation label for the list of recorded shifts. One short word.
  ///
  /// In en, this message translates to:
  /// **'Shifts'**
  String get navShifts;

  /// Navigation label for statistics (week/month/year). One short word.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get navInsights;

  /// Generic button: save the current form.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// Generic button: dismiss a dialog or sheet without changes.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// Generic button or menu item: delete an item.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// Snackbar action that reverts the last change.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get commonUndo;

  /// Generic menu item: edit an item.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// Generic menu item: create a copy of an item.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get commonDuplicate;

  /// Button shown after an error to repeat the failed action.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get commonRetry;

  /// Tooltip/button that closes a sheet, dialog or screen.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// Button that finishes a flow.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// Button that moves to the next step of a flow.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get commonNext;

  /// Button that moves to the previous step of a flow.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// Button that opens the system share sheet.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get commonShare;

  /// Tooltip of the gear icon in every top app bar; also the settings screen title.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get commonSettings;

  /// Acknowledge button in simple dialogs.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// Destructive button that throws away unsaved input.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get commonDiscard;

  /// Generic button: add a new item.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get commonAdd;

  /// Generic button or menu item: export data (PDF/CSV).
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get commonExport;

  /// Tooltip of the close icon on a hint card.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get commonDismiss;

  /// Tooltip of the overflow (three dots) menu button.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get commonMoreOptions;

  /// Button that opens the Android system settings (e.g. notification permission).
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get commonOpenSettings;

  /// Shown while data is loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get commonLoading;

  /// Filter option that shows every item (all shifts, all jobs).
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get commonAll;

  /// Status of a shift whose wage has been paid out.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get statusPaid;

  /// Status of a finished shift that has not been paid yet (German: Offen).
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get statusOpen;

  /// Status of the shift that is currently being recorded.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get statusRunning;

  /// Status of a running shift that is on a break.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get statusPaused;

  /// Relative day name for the current day.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get dateToday;

  /// Relative day name for the previous day.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get dateYesterday;

  /// Title of the Today screen. {date} is a short date such as 'Wed 30 Sep'.
  ///
  /// In en, this message translates to:
  /// **'Today, {date}'**
  String formatToday(String date);

  /// A duration or number of hours with the hour unit symbol. {value} is pre-formatted, e.g. '7:45' or '18.5'.
  ///
  /// In en, this message translates to:
  /// **'{value} h'**
  String formatHours(String value);

  /// A number of minutes with the minute unit symbol, e.g. a break of '30 min'.
  ///
  /// In en, this message translates to:
  /// **'{value} min'**
  String formatMinutes(String value);

  /// An hourly rate. {amount} is a formatted money amount such as '€15.00'.
  ///
  /// In en, this message translates to:
  /// **'{amount}/h'**
  String formatRatePerHour(String amount);

  /// Spoken form of whole hours for screen readers.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hour} other{{count} hours}}'**
  String durationSpokenHours(int count);

  /// Spoken form of whole minutes for screen readers.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 minute} other{{count} minutes}}'**
  String durationSpokenMinutes(int count);

  /// Joins the spoken hours and minutes, e.g. '7 hours 45 minutes'.
  ///
  /// In en, this message translates to:
  /// **'{hours} {minutes}'**
  String durationSpokenHoursMinutes(String hours, String minutes);

  /// Fallback error message.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// Error shown when stored data could not be read.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your data.'**
  String get errorLoadFailed;

  /// Error shown when saving failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save. Please try again.'**
  String get errorSaveFailed;

  /// Validation error for an empty required field.
  ///
  /// In en, this message translates to:
  /// **'Please enter a value'**
  String get errorRequired;

  /// Validation error for a money field that could not be read. {example} is a correctly formatted amount.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount like {example}'**
  String errorInvalidAmount(String example);

  /// Validation error when a money value (e.g. hourly rate) is zero.
  ///
  /// In en, this message translates to:
  /// **'The amount must be greater than 0'**
  String get errorAmountNotPositive;

  /// Validation error for a time field that could not be read. {example} is a correctly formatted time.
  ///
  /// In en, this message translates to:
  /// **'Enter a time like {example}'**
  String errorInvalidTime(String example);

  /// Tooltip of the clock button next to a time field that opens the time picker.
  ///
  /// In en, this message translates to:
  /// **'Choose time'**
  String get timeFieldPick;

  /// Tooltip of the stepper button that moves a time back.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes earlier'**
  String timeFieldEarlier(int minutes);

  /// Tooltip of the stepper button that moves a time forward.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes later'**
  String timeFieldLater(int minutes);

  /// Title of the export sheet (PDF timesheet / CSV).
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get exportTitle;

  /// Label above the date range choices of the export sheet.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get exportRange;

  /// Export range preset: Monday to Sunday of the current week.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get exportRangeThisWeek;

  /// Export range preset: the current calendar month.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get exportRangeThisMonth;

  /// Export range preset: the previous calendar month.
  ///
  /// In en, this message translates to:
  /// **'Last month'**
  String get exportRangeLastMonth;

  /// Export range chip that opens a date range picker.
  ///
  /// In en, this message translates to:
  /// **'Choose dates'**
  String get exportRangeCustom;

  /// A date range, e.g. "01.09.2026 – 30.09.2026".
  ///
  /// In en, this message translates to:
  /// **'{start} – {end}'**
  String exportRangeValue(String start, String end);

  /// Label of the job selector in the export sheet.
  ///
  /// In en, this message translates to:
  /// **'Job'**
  String get exportJob;

  /// Job selector option: export the shifts of every job.
  ///
  /// In en, this message translates to:
  /// **'All jobs'**
  String get exportAllJobs;

  /// Label above the PDF/CSV format choice.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get exportFormat;

  /// Format option: PDF timesheet. Keep short.
  ///
  /// In en, this message translates to:
  /// **'PDF'**
  String get exportFormatPdf;

  /// Format option: CSV table. Keep short.
  ///
  /// In en, this message translates to:
  /// **'CSV'**
  String get exportFormatCsv;

  /// Explains the PDF format.
  ///
  /// In en, this message translates to:
  /// **'Timesheet with totals and signature lines, ready to hand in.'**
  String get exportFormatPdfHelp;

  /// Explains the CSV format.
  ///
  /// In en, this message translates to:
  /// **'Table for Excel or Google Sheets.'**
  String get exportFormatCsvHelp;

  /// Text field: name printed on the PDF timesheet.
  ///
  /// In en, this message translates to:
  /// **'Your name (optional)'**
  String get exportName;

  /// Helper text below the name field.
  ///
  /// In en, this message translates to:
  /// **'Printed at the top of the timesheet'**
  String get exportNameHelp;

  /// Switch: add the shift notes to the export.
  ///
  /// In en, this message translates to:
  /// **'Include notes'**
  String get exportIncludeNotes;

  /// What will be exported: number of shifts, worked hours and wage.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 shift · {hours} · {amount}} other{{count} shifts · {hours} · {amount}}}'**
  String exportSummary(int count, String hours, String amount);

  /// Shown when the chosen range/job has nothing to export.
  ///
  /// In en, this message translates to:
  /// **'No shifts in this period.'**
  String get exportEmpty;

  /// Label of the share button while the file is generated.
  ///
  /// In en, this message translates to:
  /// **'Preparing…'**
  String get exportPreparing;

  /// Error shown in the export sheet.
  ///
  /// In en, this message translates to:
  /// **'The export didn\'t work. Please try again.'**
  String get exportFailed;

  /// Part of the export file name. Lowercase, no spaces or special characters.
  ///
  /// In en, this message translates to:
  /// **'timesheet'**
  String get exportFileBase;

  /// E-mail subject when sharing an export.
  ///
  /// In en, this message translates to:
  /// **'Timesheet {period}'**
  String exportSubject(String period);

  /// Export column: date of the shift.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get exportColDate;

  /// Export column: start time.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get exportColStart;

  /// Export column: end time.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get exportColEnd;

  /// PDF column: break duration.
  ///
  /// In en, this message translates to:
  /// **'Break'**
  String get exportColBreak;

  /// CSV column: break in minutes.
  ///
  /// In en, this message translates to:
  /// **'Break (min)'**
  String get exportColBreakMinutes;

  /// Export column: worked hours as a decimal number.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get exportColHours;

  /// CSV column: hourly wage.
  ///
  /// In en, this message translates to:
  /// **'Hourly rate'**
  String get exportColRate;

  /// PDF column: hourly wage (short).
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get exportColRateShort;

  /// Export column: wage earned for the shift.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get exportColAmount;

  /// CSV column: tips.
  ///
  /// In en, this message translates to:
  /// **'Tips'**
  String get exportColTips;

  /// CSV column: paid or unpaid.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get exportColStatus;

  /// Export column / PDF header: job name.
  ///
  /// In en, this message translates to:
  /// **'Job'**
  String get exportColJob;

  /// Export column: note of the shift.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get exportColNote;

  /// Label of the totals line in CSV and PDF.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get exportTotal;

  /// Title of the PDF timesheet.
  ///
  /// In en, this message translates to:
  /// **'Timesheet'**
  String get exportPdfTitle;

  /// PDF header: name of the person.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get exportPdfName;

  /// PDF header: exported date range.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get exportPdfPeriod;

  /// Date in a PDF table row, e.g. "Wed 9/30/2026".
  ///
  /// In en, this message translates to:
  /// **'{weekday} {date}'**
  String exportPdfRowDate(String weekday, String date);

  /// Caption under the first signature line of the PDF.
  ///
  /// In en, this message translates to:
  /// **'Date, employee signature'**
  String get exportPdfSignatureEmployee;

  /// Caption under the second signature line of the PDF.
  ///
  /// In en, this message translates to:
  /// **'Date, employer signature'**
  String get exportPdfSignatureEmployer;

  /// PDF footer with the creation date.
  ///
  /// In en, this message translates to:
  /// **'Created on {date} with Chronos'**
  String exportPdfCreatedOn(String date);

  /// PDF footer: page number.
  ///
  /// In en, this message translates to:
  /// **'Page {page} of {count}'**
  String exportPdfPage(int page, int count);

  /// Insights period switch: one week. One short word.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get insightsPeriodWeek;

  /// Insights period switch: one month. One short word.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get insightsPeriodMonth;

  /// Insights period switch: one year. One short word.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get insightsPeriodYear;

  /// Screen-reader label of the week/month/year switch.
  ///
  /// In en, this message translates to:
  /// **'Period length'**
  String get insightsPeriodChoice;

  /// Tooltip of the "<" button of the period stepper.
  ///
  /// In en, this message translates to:
  /// **'Previous period'**
  String get insightsPrevious;

  /// Tooltip of the ">" button of the period stepper.
  ///
  /// In en, this message translates to:
  /// **'Next period'**
  String get insightsNext;

  /// Title of a week in the period stepper, e.g. "28 Sep – 4 Oct 2026".
  ///
  /// In en, this message translates to:
  /// **'{start} – {end} {year}'**
  String insightsWeekTitle(String start, String end, String year);

  /// Stat card: worked hours in the period.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get insightsStatHours;

  /// Stat card: wage earned in the period (without tips).
  ///
  /// In en, this message translates to:
  /// **'Earned'**
  String get insightsStatEarned;

  /// Stat card: unpaid wage of the shifts in the period.
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get insightsStatOpen;

  /// Stat card: (wage + tips) per worked hour.
  ///
  /// In en, this message translates to:
  /// **'Avg. per hour incl. tips'**
  String get insightsStatAverage;

  /// Stat card: tips in the period (shown only if > 0).
  ///
  /// In en, this message translates to:
  /// **'Tips'**
  String get insightsStatTips;

  /// Caption of the hours card: number of shifts.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No shifts} =1{1 shift} other{{count} shifts}}'**
  String insightsShiftCount(int count);

  /// Placeholder value when there is nothing to average.
  ///
  /// In en, this message translates to:
  /// **'–'**
  String get insightsNoValue;

  /// Title of the bar chart in week and month view.
  ///
  /// In en, this message translates to:
  /// **'Earnings per day'**
  String get insightsChartDays;

  /// Title of the bar chart in year view.
  ///
  /// In en, this message translates to:
  /// **'Earnings per month'**
  String get insightsChartMonths;

  /// Hint below the chart title.
  ///
  /// In en, this message translates to:
  /// **'Tap a bar for details'**
  String get insightsChartHint;

  /// Details of the tapped bar, e.g. "Wed 30 Sep: €116.25 · 7:45 h".
  ///
  /// In en, this message translates to:
  /// **'{label}: {amount} · {hours}'**
  String insightsChartSelection(String label, String amount, String hours);

  /// Screen-reader text of one bar.
  ///
  /// In en, this message translates to:
  /// **'{label}: {amount}, {hours}'**
  String insightsChartBar(String label, String amount, String hours);

  /// Shown instead of the chart when the period is empty.
  ///
  /// In en, this message translates to:
  /// **'No shifts in this period yet.'**
  String get insightsChartEmpty;

  /// Y-axis label of the chart: whole euros.
  ///
  /// In en, this message translates to:
  /// **'€{value}'**
  String insightsAxisEuros(String value);

  /// Title of the progress card when a monthly goal is set.
  ///
  /// In en, this message translates to:
  /// **'Monthly goal'**
  String get insightsGoalTitle;

  /// Title of the progress card when a monthly limit is set (e.g. Minijob).
  ///
  /// In en, this message translates to:
  /// **'Monthly limit'**
  String get insightsLimitTitle;

  /// Progress of the current month, e.g. "€438.00 / €603.00".
  ///
  /// In en, this message translates to:
  /// **'{earned} / {target}'**
  String insightsGoalProgress(String earned, String target);

  /// Monthly goal: amount still missing.
  ///
  /// In en, this message translates to:
  /// **'{amount} to go'**
  String insightsGoalRemaining(String amount);

  /// Monthly goal reached.
  ///
  /// In en, this message translates to:
  /// **'Goal reached'**
  String get insightsGoalReached;

  /// Monthly limit: amount left.
  ///
  /// In en, this message translates to:
  /// **'{amount} left until the limit'**
  String insightsLimitRemaining(String amount);

  /// Monthly limit reached 80 % or more.
  ///
  /// In en, this message translates to:
  /// **'Almost at the limit – {amount} left'**
  String insightsLimitWarning(String amount);

  /// Monthly limit exceeded.
  ///
  /// In en, this message translates to:
  /// **'Limit exceeded by {amount}'**
  String insightsLimitExceeded(String amount);

  /// Caption of the goal card; the goal always refers to the current month.
  ///
  /// In en, this message translates to:
  /// **'Current month: {month}'**
  String insightsGoalMonth(String month);

  /// Link shown when no monthly goal is configured.
  ///
  /// In en, this message translates to:
  /// **'Set a monthly goal or limit'**
  String get insightsGoalSetUp;

  /// Section title: totals per job.
  ///
  /// In en, this message translates to:
  /// **'By job'**
  String get insightsByJob;

  /// Totals of one job in the period.
  ///
  /// In en, this message translates to:
  /// **'{hours} · {amount}'**
  String insightsJobLine(String hours, String amount);

  /// Section title: recorded payouts in the period.
  ///
  /// In en, this message translates to:
  /// **'Payouts'**
  String get insightsPayouts;

  /// Shown when the period has no payouts.
  ///
  /// In en, this message translates to:
  /// **'No payouts in this period.'**
  String get insightsPayoutsEmpty;

  /// Payout difference: received more than expected.
  ///
  /// In en, this message translates to:
  /// **'{amount} more than expected'**
  String insightsPayoutMore(String amount);

  /// Payout difference: received less than expected.
  ///
  /// In en, this message translates to:
  /// **'{amount} less than expected'**
  String insightsPayoutLess(String amount);

  /// Payout received exactly the expected amount.
  ///
  /// In en, this message translates to:
  /// **'As expected'**
  String get insightsPayoutExact;

  /// Button: opens the export sheet for the shown period.
  ///
  /// In en, this message translates to:
  /// **'Export this period'**
  String get insightsExport;

  /// Settings section: language and theme.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get settingsSectionGeneral;

  /// Setting: app language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// Language option: follow the device language.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsLanguageSystem;

  /// Language option German, written in German (self-name, do not translate).
  ///
  /// In en, this message translates to:
  /// **'Deutsch'**
  String get settingsLanguageGerman;

  /// Language option English, written in English (self-name, do not translate).
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsLanguageEnglish;

  /// Setting: light/dark appearance.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// Theme option: follow the device setting.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// Theme option: always light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// Theme option: always dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// Settings section: jobs, monthly goal, reminder.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get settingsSectionWork;

  /// Settings entry and screen title: manage jobs and their wages.
  ///
  /// In en, this message translates to:
  /// **'Jobs & hourly wage'**
  String get settingsJobs;

  /// Subtitle of the jobs entry when there is one job.
  ///
  /// In en, this message translates to:
  /// **'{name} · {rate}'**
  String settingsJobsOne(String name, String rate);

  /// Subtitle of the jobs entry: number of active jobs.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No jobs yet} =1{1 job} other{{count} jobs}}'**
  String settingsJobsCount(int count);

  /// Settings entry: monthly earnings goal or limit (e.g. Minijob).
  ///
  /// In en, this message translates to:
  /// **'Monthly goal or limit'**
  String get settingsGoal;

  /// Monthly goal is switched off.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get settingsGoalOff;

  /// Monthly goal summary.
  ///
  /// In en, this message translates to:
  /// **'Goal: {amount}'**
  String settingsGoalGoalValue(String amount);

  /// Monthly limit summary.
  ///
  /// In en, this message translates to:
  /// **'Limit: {amount}'**
  String settingsGoalLimitValue(String amount);

  /// Monthly goal type: a target to reach. Short.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get settingsGoalTypeGoal;

  /// Monthly goal type: a ceiling not to exceed. Short.
  ///
  /// In en, this message translates to:
  /// **'Limit'**
  String get settingsGoalTypeLimit;

  /// Money field in the monthly goal dialog.
  ///
  /// In en, this message translates to:
  /// **'Amount per month'**
  String get settingsGoalAmount;

  /// Explains the "off" option of the monthly goal.
  ///
  /// In en, this message translates to:
  /// **'No progress bar in Insights.'**
  String get settingsGoalHelpOff;

  /// Explains the "goal" option.
  ///
  /// In en, this message translates to:
  /// **'Shows how close you are to your monthly target.'**
  String get settingsGoalHelpGoal;

  /// Explains the "limit" option.
  ///
  /// In en, this message translates to:
  /// **'Warns from 80 % – e.g. for the €603 Minijob limit.'**
  String get settingsGoalHelpLimit;

  /// Settings entry: reminder after a shift has been running for X hours.
  ///
  /// In en, this message translates to:
  /// **'“Still working?” reminder'**
  String get settingsReminder;

  /// Reminder switched off.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get settingsReminderOff;

  /// Reminder after this many hours.
  ///
  /// In en, this message translates to:
  /// **'After {hours} h'**
  String settingsReminderHours(int hours);

  /// Explanation in the reminder dialog.
  ///
  /// In en, this message translates to:
  /// **'Reminds you when a shift is still running after this time.'**
  String get settingsReminderHelp;

  /// Settings section and entry: notification permission.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsSectionNotifications;

  /// Notification status: allowed.
  ///
  /// In en, this message translates to:
  /// **'Allowed'**
  String get settingsNotificationsOn;

  /// Explanation when notifications are allowed.
  ///
  /// In en, this message translates to:
  /// **'The running shift and reminders appear in the status bar'**
  String get settingsNotificationsOnHint;

  /// Notification status: blocked.
  ///
  /// In en, this message translates to:
  /// **'Turned off'**
  String get settingsNotificationsOffTitle;

  /// Explanation when notifications are blocked.
  ///
  /// In en, this message translates to:
  /// **'The running shift is not shown in the status bar. Tap to allow notifications.'**
  String get settingsNotificationsOff;

  /// Screen-reader hint: tapping opens the Android notification settings.
  ///
  /// In en, this message translates to:
  /// **'Open system settings'**
  String get settingsNotificationsOpen;

  /// Settings section: export, backup, delete.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get settingsSectionData;

  /// Settings entry: export a PDF timesheet or CSV.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get dataExport;

  /// Subtitle of the export entry.
  ///
  /// In en, this message translates to:
  /// **'PDF timesheet or CSV table'**
  String get dataExportSubtitle;

  /// Settings entry: save all data as a JSON file.
  ///
  /// In en, this message translates to:
  /// **'Create backup'**
  String get dataBackupCreate;

  /// Subtitle of "Create backup".
  ///
  /// In en, this message translates to:
  /// **'Save all data as a file'**
  String get dataBackupCreateSubtitle;

  /// E-mail subject when sharing a backup.
  ///
  /// In en, this message translates to:
  /// **'Chronos backup {date}'**
  String dataBackupSubject(String date);

  /// Settings entry: import a backup file.
  ///
  /// In en, this message translates to:
  /// **'Restore backup'**
  String get dataBackupRestore;

  /// Subtitle of "Restore backup".
  ///
  /// In en, this message translates to:
  /// **'From a Chronos backup file'**
  String get dataBackupRestoreSubtitle;

  /// Title of the file picker.
  ///
  /// In en, this message translates to:
  /// **'Choose a Chronos backup'**
  String get dataBackupPickTitle;

  /// Title of the restore summary dialog.
  ///
  /// In en, this message translates to:
  /// **'Restore this backup?'**
  String get dataRestoreTitle;

  /// When the backup was written.
  ///
  /// In en, this message translates to:
  /// **'Created on {date}'**
  String dataRestoreCreated(String date);

  /// Date range of the shifts in the backup.
  ///
  /// In en, this message translates to:
  /// **'Shifts from {start} to {end}'**
  String dataRestoreRange(String start, String end);

  /// Number of shifts.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 shift} other{{count} shifts}}'**
  String dataCountShifts(int count);

  /// Number of jobs.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 job} other{{count} jobs}}'**
  String dataCountJobs(int count);

  /// Number of payouts.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 payout} other{{count} payouts}}'**
  String dataCountPayouts(int count);

  /// Explains the two restore modes.
  ///
  /// In en, this message translates to:
  /// **'Replace deletes your current data first. Merge only adds what is missing.'**
  String get dataRestoreExplain;

  /// Restore mode: delete current data, then import.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get dataRestoreReplace;

  /// Restore mode: keep current data and add missing entries.
  ///
  /// In en, this message translates to:
  /// **'Merge'**
  String get dataRestoreMerge;

  /// Snackbar after a restore in replace mode.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Backup restored} =1{Backup restored · 1 shift} other{Backup restored · {count} shifts}}'**
  String dataRestoreDone(int count);

  /// Snackbar after a restore in merge mode.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Nothing new – everything was already there} =1{1 shift added} other{{count} shifts added}}'**
  String dataMergeDone(int count);

  /// Error: the chosen file cannot be read as a backup.
  ///
  /// In en, this message translates to:
  /// **'This file isn\'t a valid Chronos backup.'**
  String get dataRestoreInvalid;

  /// Error: the backup format is newer than this app.
  ///
  /// In en, this message translates to:
  /// **'This backup is from a newer Chronos version. Please update the app first.'**
  String get dataRestoreNewer;

  /// Error: the chosen file is too large.
  ///
  /// In en, this message translates to:
  /// **'This file is too large for a backup.'**
  String get dataRestoreTooLarge;

  /// Settings entry: delete all shifts, jobs and payouts.
  ///
  /// In en, this message translates to:
  /// **'Delete all data'**
  String get dataDeleteAll;

  /// Subtitle of "Delete all data".
  ///
  /// In en, this message translates to:
  /// **'A backup is saved on the device first'**
  String get dataDeleteAllSubtitle;

  /// Title of the delete-all confirmation; the parts come from dataCountShifts/dataCountJobs.
  ///
  /// In en, this message translates to:
  /// **'Delete {shifts} and {jobs}?'**
  String dataDeleteTitle(String shifts, String jobs);

  /// Message of the delete-all confirmation.
  ///
  /// In en, this message translates to:
  /// **'Payouts are deleted too. A backup is saved on the device first, and you can undo right afterwards.'**
  String get dataDeleteMessage;

  /// Snackbar after deleting all data (with Undo).
  ///
  /// In en, this message translates to:
  /// **'All data deleted'**
  String get dataDeleted;

  /// Snackbar when "Delete all data" finds nothing.
  ///
  /// In en, this message translates to:
  /// **'There is no data to delete.'**
  String get dataNothingToDelete;

  /// Settings section: version, privacy, licenses, error report.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsSectionAbout;

  /// About entry: app version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get aboutVersion;

  /// App version and build number.
  ///
  /// In en, this message translates to:
  /// **'{version} (build {build})'**
  String aboutVersionValue(String version, String build);

  /// About entry and screen title: privacy policy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get aboutPrivacy;

  /// About entry: licenses of the libraries used.
  ///
  /// In en, this message translates to:
  /// **'Open-source licenses'**
  String get aboutLicenses;

  /// About entry: share the local error log.
  ///
  /// In en, this message translates to:
  /// **'Share error report'**
  String get aboutErrorReport;

  /// Subtitle of the error report entry.
  ///
  /// In en, this message translates to:
  /// **'Local error log – only sent if you share it'**
  String get aboutErrorReportSubtitle;

  /// Snackbar when the error log is empty.
  ///
  /// In en, this message translates to:
  /// **'No errors logged'**
  String get aboutErrorReportEmpty;

  /// E-mail subject of the shared error report.
  ///
  /// In en, this message translates to:
  /// **'Chronos error report'**
  String get aboutErrorReportSubject;

  /// Part of the error report file name. Lowercase, no spaces.
  ///
  /// In en, this message translates to:
  /// **'error-report'**
  String get aboutFileBase;

  /// Current wage of a job and since when it applies.
  ///
  /// In en, this message translates to:
  /// **'{rate} since {date}'**
  String jobsRateSince(String rate, String date);

  /// Button: create a new job.
  ///
  /// In en, this message translates to:
  /// **'Add job'**
  String get jobsAdd;

  /// Section of the jobs list: active jobs.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get jobsActiveSection;

  /// Section of the jobs list: archived jobs.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get jobsArchivedSection;

  /// Title of the job editor for a new job.
  ///
  /// In en, this message translates to:
  /// **'New job'**
  String get jobsNewTitle;

  /// Title of the job editor for an existing job.
  ///
  /// In en, this message translates to:
  /// **'Edit job'**
  String get jobsEditTitle;

  /// Job editor field: name of the job/employer.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get jobsName;

  /// Hint in the job name field.
  ///
  /// In en, this message translates to:
  /// **'e.g. Café Müller'**
  String get jobsNameHint;

  /// Job editor: colour of the job.
  ///
  /// In en, this message translates to:
  /// **'Colour'**
  String get jobsColor;

  /// Job colour name.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get jobsColorBlue;

  /// Job colour name.
  ///
  /// In en, this message translates to:
  /// **'Teal'**
  String get jobsColorTeal;

  /// Job colour name.
  ///
  /// In en, this message translates to:
  /// **'Ochre'**
  String get jobsColorOchre;

  /// Job colour name.
  ///
  /// In en, this message translates to:
  /// **'Raspberry'**
  String get jobsColorRaspberry;

  /// Job colour name.
  ///
  /// In en, this message translates to:
  /// **'Violet'**
  String get jobsColorViolet;

  /// Job colour name.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get jobsColorGreen;

  /// Money field: hourly wage.
  ///
  /// In en, this message translates to:
  /// **'Hourly wage'**
  String get jobsRate;

  /// Helper below the wage field of a new job.
  ///
  /// In en, this message translates to:
  /// **'You can add later wage changes with a start date.'**
  String get jobsRateNewHelp;

  /// Job editor: rounding rule.
  ///
  /// In en, this message translates to:
  /// **'Rounding of timer shifts'**
  String get jobsRounding;

  /// Rounding option: none.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get jobsRoundingOff;

  /// Explains the rounding rule.
  ///
  /// In en, this message translates to:
  /// **'Start and end are rounded to the nearest step when you finish a shift. Shifts you enter yourself are never rounded.'**
  String get jobsRoundingHelp;

  /// Job editor section: wage changes with start dates.
  ///
  /// In en, this message translates to:
  /// **'Wage history'**
  String get jobsRateHistory;

  /// Start date of a wage in the history.
  ///
  /// In en, this message translates to:
  /// **'from {date}'**
  String jobsRateFrom(String date);

  /// Badge on the wage that applies today.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get jobsRateCurrent;

  /// Button: add a wage change valid from a date.
  ///
  /// In en, this message translates to:
  /// **'New wage from …'**
  String get jobsRateAdd;

  /// Tooltip of the delete button of a wage entry.
  ///
  /// In en, this message translates to:
  /// **'Delete wage'**
  String get jobsRateDelete;

  /// Shown when only one wage exists.
  ///
  /// In en, this message translates to:
  /// **'The last wage can\'t be deleted.'**
  String get jobsRateDeleteLast;

  /// Snackbar after deleting a wage (with Undo).
  ///
  /// In en, this message translates to:
  /// **'Wage deleted'**
  String get jobsRateDeleted;

  /// Title of the "new wage from" dialog.
  ///
  /// In en, this message translates to:
  /// **'New hourly wage'**
  String get jobsRateDialogTitle;

  /// Label of the date of a new wage.
  ///
  /// In en, this message translates to:
  /// **'Valid from'**
  String get jobsRateValidFrom;

  /// Checkbox in the new-wage dialog.
  ///
  /// In en, this message translates to:
  /// **'Recalculate unpaid shifts from this date'**
  String get jobsRateRecalc;

  /// Helper below the recalculate checkbox.
  ///
  /// In en, this message translates to:
  /// **'Paid shifts always keep their wage.'**
  String get jobsRateRecalcHelp;

  /// Snackbar after adding a wage.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Wage saved} =1{Wage saved · 1 shift recalculated} other{Wage saved · {count} shifts recalculated}}'**
  String jobsRateSaved(int count);

  /// Button: archive the job.
  ///
  /// In en, this message translates to:
  /// **'Archive job'**
  String get jobsArchive;

  /// Button: make an archived job active again.
  ///
  /// In en, this message translates to:
  /// **'Restore job'**
  String get jobsUnarchive;

  /// Explains archiving.
  ///
  /// In en, this message translates to:
  /// **'Archived jobs keep their shifts but are no longer offered when you start or add a shift.'**
  String get jobsArchiveHelp;

  /// Why the only active job cannot be archived.
  ///
  /// In en, this message translates to:
  /// **'At least one job must stay active.'**
  String get jobsArchiveLastActive;

  /// Snackbar after archiving a job (with Undo).
  ///
  /// In en, this message translates to:
  /// **'{name} archived'**
  String jobsArchived(String name);

  /// Snackbar after restoring a job.
  ///
  /// In en, this message translates to:
  /// **'{name} is active again'**
  String jobsUnarchived(String name);

  /// Dialog when leaving the job editor with unsaved changes.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get jobsDiscardTitle;

  /// Privacy policy: date line.
  ///
  /// In en, this message translates to:
  /// **'Last updated: 30 September 2026 (applies from version 2.0)'**
  String get privacyUpdated;

  /// Privacy policy: scope. Keep the app name as is.
  ///
  /// In en, this message translates to:
  /// **'This privacy policy applies to the Android app Chronos – Stundenlohn Tracker, developed by Paul Hübner.'**
  String get privacyIntro;

  /// Privacy policy heading.
  ///
  /// In en, this message translates to:
  /// **'In short'**
  String get privacyShortTitle;

  /// Privacy policy: summary.
  ///
  /// In en, this message translates to:
  /// **'Everything you enter in Chronos stays on your device. There is no account, no advertising, no analytics and no tracking. The app has no internet permission and sends nothing to the developer or to third parties.'**
  String get privacyShortBody;

  /// Privacy policy heading.
  ///
  /// In en, this message translates to:
  /// **'What the app stores'**
  String get privacyStoredTitle;

  /// Privacy policy: intro of the list of stored data.
  ///
  /// In en, this message translates to:
  /// **'Chronos stores data only in the app\'s private storage on your device:'**
  String get privacyStoredIntro;

  /// Privacy policy list item.
  ///
  /// In en, this message translates to:
  /// **'shifts with start, end, breaks, tips, notes and their “open/paid” status,'**
  String get privacyStoredShifts;

  /// Privacy policy list item.
  ///
  /// In en, this message translates to:
  /// **'jobs with name, colour, hourly wage and wage history,'**
  String get privacyStoredJobs;

  /// Privacy policy list item.
  ///
  /// In en, this message translates to:
  /// **'recorded payouts,'**
  String get privacyStoredPayouts;

  /// Privacy policy list item.
  ///
  /// In en, this message translates to:
  /// **'settings (e.g. language, theme, monthly goal, reminder),'**
  String get privacyStoredSettings;

  /// Privacy policy list item.
  ///
  /// In en, this message translates to:
  /// **'a local error log with technical error messages for troubleshooting.'**
  String get privacyStoredErrorLog;

  /// Privacy policy sentence.
  ///
  /// In en, this message translates to:
  /// **'The developer has no access to this data.'**
  String get privacyStoredNoAccess;

  /// Privacy policy heading.
  ///
  /// In en, this message translates to:
  /// **'Exceptions you control'**
  String get privacyExceptionsTitle;

  /// Privacy policy sub-heading.
  ///
  /// In en, this message translates to:
  /// **'Android backup (Auto Backup)'**
  String get privacyAutoBackupTitle;

  /// Privacy policy paragraph.
  ///
  /// In en, this message translates to:
  /// **'If backup is switched on in your device\'s Android settings, Android automatically backs up Chronos\' data (database and settings) to your own Google account and restores it when you reinstall the app or move to a new device. This is an operating-system feature provided to you by Google; the developer cannot see these backups. On Android 9 and later they are end-to-end encrypted with your screen lock. You can switch backup off in the Android settings (usually under “System” or “Google” → “Backup”) and delete existing backups from your Google account. A direct transfer to a new device (cable or Wi-Fi) takes the same data along.'**
  String get privacyAutoBackupBody;

  /// Privacy policy sub-heading.
  ///
  /// In en, this message translates to:
  /// **'Export, backup file and error report'**
  String get privacyExportTitle;

  /// Privacy policy paragraph.
  ///
  /// In en, this message translates to:
  /// **'Only when you explicitly ask for it, Chronos creates a file (PDF timesheet, CSV, JSON backup or the error log) and opens the Android share sheet. You decide which app or recipient receives the file (e.g. e-mail, messenger, cloud storage). From then on, that service\'s terms apply.'**
  String get privacyExportBody;

  /// Privacy policy sub-heading.
  ///
  /// In en, this message translates to:
  /// **'Restoring a backup'**
  String get privacyRestoreTitle;

  /// Privacy policy paragraph.
  ///
  /// In en, this message translates to:
  /// **'Using the Android file picker, Chronos reads only the single file you select.'**
  String get privacyRestoreBody;

  /// Privacy policy heading.
  ///
  /// In en, this message translates to:
  /// **'Notifications and permissions'**
  String get privacyPermissionsTitle;

  /// Privacy policy list item.
  ///
  /// In en, this message translates to:
  /// **'Show notifications (optional): for the running shift with a stopwatch and the “Still working?” reminder. Notifications are created on the device; no push service is used. Without this permission the app keeps working normally.'**
  String get privacyPermissionNotifications;

  /// Privacy policy list item.
  ///
  /// In en, this message translates to:
  /// **'Run at startup: so that a scheduled reminder is scheduled again after a restart.'**
  String get privacyPermissionBoot;

  /// Privacy policy paragraph.
  ///
  /// In en, this message translates to:
  /// **'Chronos does not request permissions for the internet, location, contacts, camera or shared storage.'**
  String get privacyPermissionsNone;

  /// Privacy policy heading.
  ///
  /// In en, this message translates to:
  /// **'No sharing, no advertising, no tracking'**
  String get privacyNoSharingTitle;

  /// Privacy policy paragraph.
  ///
  /// In en, this message translates to:
  /// **'Chronos contains no advertising, no analytics tools, no tracking SDKs and no crash reporting to external servers. No data is sold or passed on to third parties.'**
  String get privacyNoSharingBody;

  /// Privacy policy heading.
  ///
  /// In en, this message translates to:
  /// **'Deleting your data'**
  String get privacyDeleteTitle;

  /// Privacy policy paragraph.
  ///
  /// In en, this message translates to:
  /// **'In the app via “Settings → Data → Delete all data”, or by uninstalling the app or clearing its storage in the Android settings. Backups in your Google account are managed in your Google or Android settings.'**
  String get privacyDeleteBody;

  /// Privacy policy heading.
  ///
  /// In en, this message translates to:
  /// **'Changes'**
  String get privacyChangesTitle;

  /// Privacy policy paragraph.
  ///
  /// In en, this message translates to:
  /// **'If this policy changes, this page will be updated. The date at the top applies.'**
  String get privacyChangesBody;

  /// Privacy policy heading.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get privacyContactTitle;

  /// Privacy policy paragraph with the contact e-mail (same as privacy.html).
  ///
  /// In en, this message translates to:
  /// **'If you have questions about privacy, you can reach me at: paulvincent.huebner@gmail.com'**
  String get privacyContactBody;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
