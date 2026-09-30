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

  /// Label of the big amount on the Today card: wage of today's shifts including the running one (without tips).
  ///
  /// In en, this message translates to:
  /// **'Earned today'**
  String get todayEarnedToday;

  /// Label of the big amount on the Today card when nothing was worked today: all wages not paid yet.
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get todayOpenLabel;

  /// Line below the Today card: all wages not paid yet (including the running shift).
  ///
  /// In en, this message translates to:
  /// **'Unpaid total'**
  String get todayOpenTotal;

  /// Line below the Today card while a shift runs and other shifts were finished today: the running shift's wage so far.
  ///
  /// In en, this message translates to:
  /// **'Of which this shift'**
  String get todayThisShift;

  /// Number of shifts and their hours, e.g. '11 shifts · 82.5 h'.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 shift · {hours}} other{{count} shifts · {hours}}}'**
  String todayShiftsHours(int count, String hours);

  /// Shown on the Today card when no finished shift is waiting for payment.
  ///
  /// In en, this message translates to:
  /// **'No unpaid shifts'**
  String get todayNothingOpen;

  /// Button on the Today card that opens the sheet to record a received payment.
  ///
  /// In en, this message translates to:
  /// **'Record payout'**
  String get todayRecordPayout;

  /// Header of the running-shift card when there is more than one job, e.g. 'Running · Catering'.
  ///
  /// In en, this message translates to:
  /// **'{status} · {job}'**
  String todayStatusWithJob(String status, String job);

  /// Header of the Today card while the running shift is paused.
  ///
  /// In en, this message translates to:
  /// **'Paused since {time}'**
  String todayPausedSince(String time);

  /// Start time of the running shift; tapping it changes the start.
  ///
  /// In en, this message translates to:
  /// **'since {time}'**
  String todaySince(String time);

  /// Tooltip / screen-reader hint of the start time button on the running-shift card.
  ///
  /// In en, this message translates to:
  /// **'Change start time'**
  String get todayAdjustStart;

  /// Screen-reader label of the running stopwatch. {duration} is spoken, e.g. '3 hours 11 minutes'.
  ///
  /// In en, this message translates to:
  /// **'Worked {duration}'**
  String todayWorkedSemantics(String duration);

  /// Break time of the running shift, e.g. 'Break 0:30'.
  ///
  /// In en, this message translates to:
  /// **'Break {duration}'**
  String todayBreak(String duration);

  /// Main button on Today that starts recording a shift now.
  ///
  /// In en, this message translates to:
  /// **'Start shift'**
  String get todayStartShift;

  /// Text button below 'Start shift': start a shift with an earlier start time.
  ///
  /// In en, this message translates to:
  /// **'Started earlier?'**
  String get todayStartedEarlier;

  /// Title of the time picker for an earlier or changed start time.
  ///
  /// In en, this message translates to:
  /// **'When did you start?'**
  String get todayStartTimeHelp;

  /// Tooltip of the job chip on Today (only with more than one job).
  ///
  /// In en, this message translates to:
  /// **'Choose job'**
  String get todayChooseJob;

  /// Screen-reader label of the job chip on Today.
  ///
  /// In en, this message translates to:
  /// **'Job: {job}'**
  String todayJobSemantics(String job);

  /// Button that pauses the running shift (starts a break).
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get todayPause;

  /// Button that resumes a paused shift.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get todayResume;

  /// Button that opens the 'Finish shift' sheet.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get todayFinish;

  /// Label of the weekly totals line on Today.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get todayThisWeek;

  /// Weekly totals on Today, e.g. '18.5 h · €256.75'.
  ///
  /// In en, this message translates to:
  /// **'{hours} · {amount}'**
  String todayWeekFigures(String hours, String amount);

  /// Label of the row showing the most recent finished shift; tapping opens the editor.
  ///
  /// In en, this message translates to:
  /// **'Last shift'**
  String get todayLastShift;

  /// Details of the most recent shift, e.g. 'Mon 28 Sep, 8:00 AM–4:15 PM · 8:15 h'.
  ///
  /// In en, this message translates to:
  /// **'{date}, {times} · {duration}'**
  String todayLastShiftDetails(String date, String times, String duration);

  /// Heading of the side pane on tablets that lists today's finished shifts.
  ///
  /// In en, this message translates to:
  /// **'Today\'s shifts'**
  String get todayShiftsTodayTitle;

  /// Shown in the tablet side pane when no shift was finished today.
  ///
  /// In en, this message translates to:
  /// **'No finished shifts today yet.'**
  String get todayNoShiftsToday;

  /// Hint card on Today after importing data from version 1: entries that look unusual.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Check 1 imported entry} other{Check {count} imported entries}}'**
  String todayReviewHint(int count);

  /// Action of the import review hint card.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get todayReviewAction;

  /// Hint card on Today when the notification permission is denied.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off, so the running shift doesn\'t appear on your lock screen.'**
  String get todayNotificationsOff;

  /// Title of the sheet shown before asking for the notification permission (first shift start).
  ///
  /// In en, this message translates to:
  /// **'Your shift on the lock screen'**
  String get todayPrimerTitle;

  /// Explanation before the notification permission request.
  ///
  /// In en, this message translates to:
  /// **'While a shift is running, Chronos shows it in a quiet notification. From there you can pause or finish it without opening the app. Nothing runs in the background.'**
  String get todayPrimerBody;

  /// Button in the permission explanation sheet: shows the system permission dialog.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications'**
  String get todayPrimerAllow;

  /// Button in the permission explanation sheet: continue without asking.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get todayPrimerLater;

  /// Title of the dialog when an earlier start time overlaps a recorded shift.
  ///
  /// In en, this message translates to:
  /// **'Overlaps another shift'**
  String get todayOverlapTitle;

  /// Body of the overlap dialog. {shifts} lists the shifts, e.g. 'Mon 28 Sep, 8:00 AM–4:15 PM'.
  ///
  /// In en, this message translates to:
  /// **'This start time overlaps: {shifts}'**
  String todayOverlapMessage(String shifts);

  /// Confirm button of the overlap dialog when starting a shift.
  ///
  /// In en, this message translates to:
  /// **'Start anyway'**
  String get todayOverlapStartAnyway;

  /// Confirm button of the overlap dialog when changing the start of the running shift.
  ///
  /// In en, this message translates to:
  /// **'Change anyway'**
  String get todayOverlapChangeAnyway;

  /// Snackbar after changing the start of the running shift.
  ///
  /// In en, this message translates to:
  /// **'Start changed to {time}'**
  String todayStartChanged(String time);

  /// Error when a chosen start time lies in the future.
  ///
  /// In en, this message translates to:
  /// **'The start time can\'t be in the future.'**
  String get todayErrorStartInFuture;

  /// Error when the start of a paused shift is moved after the start of the break.
  ///
  /// In en, this message translates to:
  /// **'The start must be before the current break began.'**
  String get todayErrorStartAfterBreak;

  /// Error when starting (or undoing) while another shift runs.
  ///
  /// In en, this message translates to:
  /// **'A shift is already running.'**
  String get todayErrorAlreadyRunning;

  /// Error when an action needs a running shift but none runs.
  ///
  /// In en, this message translates to:
  /// **'No shift is running.'**
  String get todayErrorNoRunningShift;

  /// Error when starting a shift for a job without wage.
  ///
  /// In en, this message translates to:
  /// **'This job has no hourly rate yet. Add one in Settings.'**
  String get todayErrorNoWage;

  /// Error when the selected job was deleted meanwhile.
  ///
  /// In en, this message translates to:
  /// **'This job no longer exists.'**
  String get todayErrorJobNotFound;

  /// Error when undoing a change to a shift that was removed meanwhile.
  ///
  /// In en, this message translates to:
  /// **'This shift no longer exists.'**
  String get todayErrorShiftNotFound;

  /// Snackbar after finishing a shift (with Undo).
  ///
  /// In en, this message translates to:
  /// **'Shift saved · {duration} · {amount}'**
  String todayShiftSaved(String duration, String amount);

  /// Snackbar after discarding the running shift (with Undo).
  ///
  /// In en, this message translates to:
  /// **'Shift discarded'**
  String get todayShiftDiscarded;

  /// Title of the sheet that finishes the running shift.
  ///
  /// In en, this message translates to:
  /// **'Finish shift'**
  String get todayFinishSheetTitle;

  /// Label of the start time in the finish sheet.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get todayFinishStart;

  /// Label of the editable end time in the finish sheet.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get todayFinishEnd;

  /// Screen-reader text for the start row of the finish sheet when rounding moved the start (shown visually as '8:02 AM → 8:00 AM').
  ///
  /// In en, this message translates to:
  /// **'Recorded {recorded}, billed {billed}'**
  String todayFinishRoundedTimes(String recorded, String billed);

  /// Explains that start and end are rounded by the job's rounding rule.
  ///
  /// In en, this message translates to:
  /// **'Rounded to the nearest {minutes} minutes (job setting)'**
  String todayFinishRoundingNote(int minutes);

  /// Helper below the end time when rounding changes it.
  ///
  /// In en, this message translates to:
  /// **'Billed: {time}'**
  String todayFinishBilledEnd(String time);

  /// Helper below the end time when the shift ends on another day than today.
  ///
  /// In en, this message translates to:
  /// **'on {date}'**
  String todayFinishEndDate(String date);

  /// Label of the break field (minutes) in the finish sheet.
  ///
  /// In en, this message translates to:
  /// **'Break'**
  String get todayFinishBreak;

  /// Unit suffix of a minutes input field.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get todayMinutesUnit;

  /// Label of the worked time (duration minus break) in the finish sheet.
  ///
  /// In en, this message translates to:
  /// **'Worked'**
  String get todayFinishWorked;

  /// Calculation line in the finish sheet, e.g. '7:45 h × €15.00/h'.
  ///
  /// In en, this message translates to:
  /// **'{duration} × {rate}'**
  String todayFinishCalculation(String duration, String rate);

  /// Optional tips field in the finish sheet (kept separate from the wage).
  ///
  /// In en, this message translates to:
  /// **'Tips (optional)'**
  String get todayFinishTips;

  /// Optional note field in the finish sheet.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get todayFinishNote;

  /// Closes the finish sheet; the shift keeps running.
  ///
  /// In en, this message translates to:
  /// **'Keep running'**
  String get todayFinishKeepRunning;

  /// Error in the finish sheet.
  ///
  /// In en, this message translates to:
  /// **'The end must be after the start.'**
  String get todayFinishErrorEndNotAfterStart;

  /// Error in the finish sheet.
  ///
  /// In en, this message translates to:
  /// **'The break must be shorter than the shift.'**
  String get todayFinishErrorBreakTooLong;

  /// Error in the finish sheet.
  ///
  /// In en, this message translates to:
  /// **'The end can\'t be in the future.'**
  String get todayFinishErrorEndInFuture;

  /// Title of the confirmation before discarding the running shift.
  ///
  /// In en, this message translates to:
  /// **'Discard this shift?'**
  String get todayDiscardTitle;

  /// Body of the discard confirmation.
  ///
  /// In en, this message translates to:
  /// **'The running shift won\'t be saved. You can undo this right afterwards.'**
  String get todayDiscardMessage;
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
