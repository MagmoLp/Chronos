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

  /// Label of the extended floating action button on the Shifts screen that adds a shift. One short word (German: Schicht).
  ///
  /// In en, this message translates to:
  /// **'Shift'**
  String get shiftsAddShift;

  /// Tooltip / screen-reader label of the add-shift floating action button.
  ///
  /// In en, this message translates to:
  /// **'Add shift'**
  String get shiftsAddShiftTooltip;

  /// Screen-reader label of the filter chip group (All / Unpaid / Paid) on the Shifts screen.
  ///
  /// In en, this message translates to:
  /// **'Show shifts'**
  String get shiftsFilterLabel;

  /// Title of the running-shift tile at the top of the Shifts list. {time} is the start time, e.g. '08:02'.
  ///
  /// In en, this message translates to:
  /// **'Running since {time}'**
  String shiftsRunningSince(String time);

  /// Title of the running-shift tile while the shift is paused. {time} is when the break started.
  ///
  /// In en, this message translates to:
  /// **'Paused since {time}'**
  String shiftsPausedSince(String time);

  /// Screen-reader hint / tooltip of the running-shift tile: tapping switches to the Today tab.
  ///
  /// In en, this message translates to:
  /// **'Open on Today'**
  String get shiftsRunningOpenToday;

  /// Part of a month header summary: the unpaid wage of that month, e.g. '42.5 h · €637.50 · €318.75 unpaid'.
  ///
  /// In en, this message translates to:
  /// **'{amount} unpaid'**
  String shiftsMonthOpen(String amount);

  /// Part of a shift row subtitle: the break length, e.g. 'Break 30 min'.
  ///
  /// In en, this message translates to:
  /// **'Break {duration}'**
  String shiftsBreak(String duration);

  /// Part of a shift row subtitle: tips received during the shift.
  ///
  /// In en, this message translates to:
  /// **'Tips {amount}'**
  String shiftsTips(String amount);

  /// Screen-reader form of a shift's time range.
  ///
  /// In en, this message translates to:
  /// **'{start} to {end}'**
  String shiftsTimeRangeSpoken(String start, String end);

  /// Screen-reader form of a time range that ends on the following day.
  ///
  /// In en, this message translates to:
  /// **'{start} to {end} the next day'**
  String shiftsTimeRangeSpokenNextDay(String start, String end);

  /// Title of the empty Shifts screen.
  ///
  /// In en, this message translates to:
  /// **'No shifts yet'**
  String get shiftsEmptyTitle;

  /// Explanation on the empty Shifts screen.
  ///
  /// In en, this message translates to:
  /// **'Start a shift on Today, or add one you have already worked.'**
  String get shiftsEmptyMessage;

  /// Button on the empty Shifts screen that switches to Today to start the timer.
  ///
  /// In en, this message translates to:
  /// **'Start shift'**
  String get shiftsStartShift;

  /// Button on the empty Shifts screen that opens the shift editor for a shift that was already worked (German: Schicht nachtragen).
  ///
  /// In en, this message translates to:
  /// **'Add past shift'**
  String get shiftsAddPastShift;

  /// Title shown when the 'Unpaid' filter matches nothing.
  ///
  /// In en, this message translates to:
  /// **'No unpaid shifts'**
  String get shiftsEmptyOpenTitle;

  /// Message shown when the 'Unpaid' filter matches nothing.
  ///
  /// In en, this message translates to:
  /// **'Everything has been paid.'**
  String get shiftsEmptyOpenMessage;

  /// Title shown when the 'Paid' filter matches nothing.
  ///
  /// In en, this message translates to:
  /// **'No paid shifts yet'**
  String get shiftsEmptyPaidTitle;

  /// Message shown when the 'Paid' filter matches nothing.
  ///
  /// In en, this message translates to:
  /// **'Mark shifts as paid or record a payout.'**
  String get shiftsEmptyPaidMessage;

  /// Button that resets the Shifts filter to 'All'.
  ///
  /// In en, this message translates to:
  /// **'Show all shifts'**
  String get shiftsShowAll;

  /// Menu item, swipe label and screen-reader action that marks an unpaid shift as paid.
  ///
  /// In en, this message translates to:
  /// **'Mark as paid'**
  String get shiftsMarkPaid;

  /// Menu item, swipe label and screen-reader action that marks a paid shift as unpaid again (German: Als offen markieren).
  ///
  /// In en, this message translates to:
  /// **'Mark as unpaid'**
  String get shiftsMarkOpen;

  /// Snackbar after a shift was marked as paid (has an Undo action).
  ///
  /// In en, this message translates to:
  /// **'Marked as paid'**
  String get shiftsMarkedPaid;

  /// Snackbar after a shift was marked as unpaid (has an Undo action).
  ///
  /// In en, this message translates to:
  /// **'Marked as unpaid'**
  String get shiftsMarkedOpen;

  /// Snackbar after a shift was deleted (has an Undo action).
  ///
  /// In en, this message translates to:
  /// **'Shift deleted'**
  String get shiftsDeleted;

  /// Snackbar after a new shift was added in the editor (has an Undo action).
  ///
  /// In en, this message translates to:
  /// **'Shift saved · {duration} · {amount}'**
  String shiftsSaved(String duration, String amount);

  /// Error when a shift was deleted in the meantime.
  ///
  /// In en, this message translates to:
  /// **'This shift no longer exists.'**
  String get shiftsErrorNotFound;

  /// Error when trying to edit or duplicate the running shift like a finished one.
  ///
  /// In en, this message translates to:
  /// **'The running shift can be changed on Today.'**
  String get shiftsErrorRunning;

  /// Error when restoring a shift would create a second running shift.
  ///
  /// In en, this message translates to:
  /// **'Another shift is already running.'**
  String get shiftsErrorAlreadyRunning;

  /// Error when the selected job was removed.
  ///
  /// In en, this message translates to:
  /// **'This job no longer exists.'**
  String get shiftsErrorJobNotFound;

  /// Error when the selected job has no wage rate.
  ///
  /// In en, this message translates to:
  /// **'This job has no hourly wage yet.'**
  String get shiftsErrorNoWage;

  /// Generic validation error for shift input.
  ///
  /// In en, this message translates to:
  /// **'Please check your input.'**
  String get shiftsErrorInvalid;

  /// Title of the shift editor when adding a shift.
  ///
  /// In en, this message translates to:
  /// **'New shift'**
  String get editorTitleNew;

  /// Title of the shift editor when changing an existing shift.
  ///
  /// In en, this message translates to:
  /// **'Edit shift'**
  String get editorTitleEdit;

  /// Label of the job selector (employer) in the shift editor and payout sheet.
  ///
  /// In en, this message translates to:
  /// **'Job'**
  String get editorJob;

  /// Label of the date field in the shift editor.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get editorDate;

  /// Tooltip / hint of a date field that opens the date picker.
  ///
  /// In en, this message translates to:
  /// **'Choose date'**
  String get editorPickDate;

  /// Label of the start time field.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get editorStart;

  /// Label of the end time field.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get editorEnd;

  /// Switch in the shift editor for shifts that end after midnight.
  ///
  /// In en, this message translates to:
  /// **'Ends the next day'**
  String get editorEndsNextDay;

  /// Highlighted note below the 'Ends the next day' switch when it was switched on automatically.
  ///
  /// In en, this message translates to:
  /// **'Turned on because the end is before the start'**
  String get editorEndsNextDayAuto;

  /// Label of the break field (minutes) in the shift editor.
  ///
  /// In en, this message translates to:
  /// **'Break'**
  String get editorBreak;

  /// Tooltip of the button that shortens the break.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes less break'**
  String editorBreakLess(int minutes);

  /// Tooltip of the button that lengthens the break.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes more break'**
  String editorBreakMore(int minutes);

  /// Validation error of the break field.
  ///
  /// In en, this message translates to:
  /// **'Enter the break in whole minutes'**
  String get editorBreakInvalid;

  /// Label of the tips amount field.
  ///
  /// In en, this message translates to:
  /// **'Tips'**
  String get editorTips;

  /// Label of the optional note field.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get editorNote;

  /// Label of the Unpaid | Paid selector in the shift editor.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get editorStatus;

  /// Live earnings preview in the shift editor, e.g. '7:45 h × €15.00/h = €116.25'.
  ///
  /// In en, this message translates to:
  /// **'{duration} × {rate} = {amount}'**
  String editorPreview(String duration, String rate, String amount);

  /// Screen-reader form of the earnings preview.
  ///
  /// In en, this message translates to:
  /// **'{duration} at {rate} makes {amount}'**
  String editorPreviewSpoken(String duration, String rate, String amount);

  /// Second preview line when tips were entered.
  ///
  /// In en, this message translates to:
  /// **'plus {amount} tips'**
  String editorPreviewTips(String amount);

  /// Inline error in the shift editor.
  ///
  /// In en, this message translates to:
  /// **'The end must be after the start.'**
  String get editorErrorEndNotAfterStart;

  /// Inline error in the shift editor.
  ///
  /// In en, this message translates to:
  /// **'The break must be shorter than the shift.'**
  String get editorErrorBreakTooLong;

  /// Warning in the shift editor for very long shifts.
  ///
  /// In en, this message translates to:
  /// **'Longer than 16 hours ({duration})'**
  String editorWarningLong(String duration);

  /// Warning in the shift editor naming the other shift, e.g. 'Overlaps Mon 28 Sep · 08:00–16:00'.
  ///
  /// In en, this message translates to:
  /// **'Overlaps {date} · {time}'**
  String editorWarningOverlap(String date, String time);

  /// Warning in the shift editor when the input overlaps the running shift.
  ///
  /// In en, this message translates to:
  /// **'Overlaps the running shift (since {time})'**
  String editorWarningOverlapRunning(String time);

  /// Warning in the shift editor.
  ///
  /// In en, this message translates to:
  /// **'Starts in the future'**
  String get editorWarningFuture;

  /// Title of the dialog that lists warnings before saving a shift.
  ///
  /// In en, this message translates to:
  /// **'Save anyway?'**
  String get editorConfirmTitle;

  /// Confirm button of the warnings dialog.
  ///
  /// In en, this message translates to:
  /// **'Save anyway'**
  String get editorConfirmSave;

  /// Title of the dialog shown when closing the shift editor with unsaved changes.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get editorDiscardTitle;

  /// Message of the discard-changes dialog.
  ///
  /// In en, this message translates to:
  /// **'Your changes to this shift will be lost.'**
  String get editorDiscardMessage;

  /// Cancel button of the discard-changes dialog.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get editorKeepEditing;

  /// Hint at the top of the editor after a shift was duplicated to today.
  ///
  /// In en, this message translates to:
  /// **'Copy created for today. Adjust it or delete it.'**
  String get editorCopyNotice;

  /// Title of the payout sheet and menu item that opens it (German: Auszahlung erfassen).
  ///
  /// In en, this message translates to:
  /// **'Record payout'**
  String get payoutTitle;

  /// Job selector option in the payout sheet that includes every job.
  ///
  /// In en, this message translates to:
  /// **'All jobs'**
  String get payoutAllJobs;

  /// Label of the date up to which unpaid shifts are included in the payout.
  ///
  /// In en, this message translates to:
  /// **'Up to and including'**
  String get payoutUntil;

  /// Summary of the shifts a payout settles, e.g. '23 shifts · 172.5 h'.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 shift} other{{count} shifts}} · {hours}'**
  String payoutSummary(int count, String hours);

  /// Label of the expected payout amount (sum of the wages).
  ///
  /// In en, this message translates to:
  /// **'Expected'**
  String get payoutExpected;

  /// Label of the field for the amount actually received.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get payoutReceived;

  /// Label of received minus expected.
  ///
  /// In en, this message translates to:
  /// **'Difference'**
  String get payoutDifference;

  /// A positive difference with an explicit plus sign.
  ///
  /// In en, this message translates to:
  /// **'+{amount}'**
  String payoutDifferencePositive(String amount);

  /// Label of the date the money was received.
  ///
  /// In en, this message translates to:
  /// **'Paid on'**
  String get payoutPaidOn;

  /// Primary button of the payout sheet.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Mark 1 shift as paid} other{Mark {count} shifts as paid}}'**
  String payoutSubmit(int count);

  /// Shown instead of the button when nothing can be paid out.
  ///
  /// In en, this message translates to:
  /// **'There are no unpaid shifts up to this date.'**
  String get payoutNothingOpen;

  /// Snackbar after a payout was recorded (has an Undo action).
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 shift marked as paid} other{{count} shifts marked as paid}}'**
  String payoutRecorded(int count);

  /// Error when the received amount was refused.
  ///
  /// In en, this message translates to:
  /// **'The received amount is not valid.'**
  String get payoutErrorAmount;

  /// Screen-reader label of the splash screen shown while the database and the migration load.
  ///
  /// In en, this message translates to:
  /// **'Starting Chronos…'**
  String get startupLoading;

  /// One-time snackbar after the data of the old app version (1.x) was imported.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 entry taken over from Chronos 1} other{{count} entries taken over from Chronos 1}}'**
  String startupMigratedNotice(int count);

  /// Snackbar action next to startupMigratedNotice that opens the list of imported entries to check.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get startupMigratedReview;

  /// Name of the first job when the user leaves the name empty (also used for the job created from old data).
  ///
  /// In en, this message translates to:
  /// **'My job'**
  String get onboardingDefaultJobName;

  /// Headline of the first onboarding step.
  ///
  /// In en, this message translates to:
  /// **'Track shifts. Watch your pay grow live.'**
  String get onboardingWelcomeTitle;

  /// Text below the welcome headline.
  ///
  /// In en, this message translates to:
  /// **'Works offline. Your data stays on your phone.'**
  String get onboardingWelcomeBody;

  /// Button on the welcome step that moves to the job step.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get onboardingStart;

  /// Screen-reader label of the onboarding progress dots.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of {total}'**
  String onboardingStepLabel(int step, int total);

  /// Headline of the second onboarding step (name and hourly rate).
  ///
  /// In en, this message translates to:
  /// **'Your job'**
  String get onboardingJobTitle;

  /// Text below the job step headline.
  ///
  /// In en, this message translates to:
  /// **'Enter your hourly rate. You can change everything later.'**
  String get onboardingJobSubtitle;

  /// Label of the job name field in onboarding.
  ///
  /// In en, this message translates to:
  /// **'Name (optional)'**
  String get onboardingNameLabel;

  /// Label of the required hourly rate field in onboarding.
  ///
  /// In en, this message translates to:
  /// **'Hourly rate'**
  String get onboardingRateLabel;

  /// Helper text below the hourly rate field.
  ///
  /// In en, this message translates to:
  /// **'Gross per hour'**
  String get onboardingRateHelper;

  /// Hint below the Done button of the job step.
  ///
  /// In en, this message translates to:
  /// **'You can add more jobs later in Settings.'**
  String get onboardingMoreJobsLater;

  /// Question after importing old data whose hourly rate looks implausible. {rate} is a formatted rate such as '€1,250.00/h'.
  ///
  /// In en, this message translates to:
  /// **'{rate} taken over – is that right?'**
  String wageCheckTitle(String rate);

  /// Explanation when the imported hourly rate is above 100 €/h.
  ///
  /// In en, this message translates to:
  /// **'That\'s unusually high. The old version sometimes lost the decimal separator, so 12.50 became 1250.'**
  String get wageCheckTooHigh;

  /// Explanation when an hourly rate is below 5 €/h (imported or newly entered).
  ///
  /// In en, this message translates to:
  /// **'That\'s unusually low for an hourly rate.'**
  String get wageCheckTooLow;

  /// Explanation when a newly entered hourly rate is above 100 €/h.
  ///
  /// In en, this message translates to:
  /// **'That\'s unusually high for an hourly rate.'**
  String get wageCheckUnusuallyHigh;

  /// Label of the field for the corrected hourly rate.
  ///
  /// In en, this message translates to:
  /// **'Correct hourly rate'**
  String get wageCheckFieldLabel;

  /// Helper text below the corrected hourly rate field.
  ///
  /// In en, this message translates to:
  /// **'Applies to the job and to all shifts taken over.'**
  String get wageCheckFieldHelper;

  /// Primary button that saves the corrected hourly rate.
  ///
  /// In en, this message translates to:
  /// **'Use this rate'**
  String get wageCheckFix;

  /// Button that confirms the imported rate is correct.
  ///
  /// In en, this message translates to:
  /// **'Keep {rate}'**
  String wageCheckKeep(String rate);

  /// Snackbar after the imported hourly rate was corrected.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Hourly rate corrected} =1{Hourly rate corrected · 1 shift updated} other{Hourly rate corrected · {count} shifts updated}}'**
  String wageCheckFixed(int count);

  /// Dialog title when a newly entered hourly rate looks implausible (below 5 or above 100 €/h).
  ///
  /// In en, this message translates to:
  /// **'{rate} – is that right?'**
  String wageCheckConfirmTitle(String rate);

  /// Dialog button that keeps an unusual hourly rate.
  ///
  /// In en, this message translates to:
  /// **'Yes, that\'s right'**
  String get wageCheckConfirmYes;

  /// Dialog button that goes back to correct the hourly rate.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get wageCheckConfirmEdit;

  /// Title of the recovery screen shown when loading the data failed at start.
  ///
  /// In en, this message translates to:
  /// **'Chronos couldn\'t start'**
  String get recoveryTitle;

  /// Explanation on the recovery screen.
  ///
  /// In en, this message translates to:
  /// **'Your data couldn\'t be loaded. Nothing has been deleted. Try again, or share the raw data and an error report so the problem can be fixed.'**
  String get recoveryMessage;

  /// Button that shares the raw data of the old app version as a JSON file.
  ///
  /// In en, this message translates to:
  /// **'Share raw data'**
  String get recoveryShareRawData;

  /// Button that shares the local error log as a text file.
  ///
  /// In en, this message translates to:
  /// **'Share error report'**
  String get recoveryShareErrorReport;

  /// Expandable section with the technical error message.
  ///
  /// In en, this message translates to:
  /// **'Technical details'**
  String get recoveryDetails;

  /// Subject of the shared raw data file.
  ///
  /// In en, this message translates to:
  /// **'Chronos raw data'**
  String get recoveryRawDataSubject;

  /// Subject of the shared error report.
  ///
  /// In en, this message translates to:
  /// **'Chronos error report'**
  String get recoveryErrorReportSubject;

  /// Snackbar when the raw data or error report could not be read or shared.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t prepare the file.'**
  String get recoveryShareFailed;

  /// Title of the screen listing imported entries that look unusual.
  ///
  /// In en, this message translates to:
  /// **'Review entries'**
  String get reviewTitle;

  /// Explanation at the top of the review screen.
  ///
  /// In en, this message translates to:
  /// **'These entries from the old version look unusual. Check them and fix them if needed – nothing was changed automatically.'**
  String get reviewIntro;

  /// Section header above the shifts to review.
  ///
  /// In en, this message translates to:
  /// **'Shifts to check ({count})'**
  String reviewSectionShifts(int count);

  /// Title of a shift in the review list: time range and worked time.
  ///
  /// In en, this message translates to:
  /// **'{times} · {duration}'**
  String reviewShiftSummary(String times, String duration);

  /// Why a shift is listed: it lasts 16 hours or more.
  ///
  /// In en, this message translates to:
  /// **'Longer than 16 hours'**
  String get reviewReasonTooLong;

  /// Why a shift is listed: the old version turned an end before the start into a 23/24 h shift.
  ///
  /// In en, this message translates to:
  /// **'Exactly 23 or 24 hours – the end may be wrong'**
  String get reviewReasonExactly23or24h;

  /// Why a shift is listed: another shift has exactly the same start and end.
  ///
  /// In en, this message translates to:
  /// **'Same times as another shift'**
  String get reviewReasonDuplicateTimes;

  /// Why a shift is listed: the old version stored two entries with the same id.
  ///
  /// In en, this message translates to:
  /// **'Duplicate entry from the old version'**
  String get reviewReasonDuplicateLegacyId;

  /// Why a shift is listed: it overlaps another shift.
  ///
  /// In en, this message translates to:
  /// **'Overlaps another shift'**
  String get reviewReasonOverlap;

  /// Why a shift is listed: it starts or ends on the day the clocks change.
  ///
  /// In en, this message translates to:
  /// **'On a daylight saving time switch day – check the times'**
  String get reviewReasonDstDay;

  /// Button that removes one shift from the review list without changes.
  ///
  /// In en, this message translates to:
  /// **'Looks fine'**
  String get reviewDismiss;

  /// Button that removes every shift from the review list.
  ///
  /// In en, this message translates to:
  /// **'Mark all as checked'**
  String get reviewDismissAll;

  /// Confirmation dialog title for reviewDismissAll.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Mark 1 entry as checked?} other{Mark {count} entries as checked?}}'**
  String reviewDismissAllTitle(int count);

  /// Confirmation dialog text for reviewDismissAll.
  ///
  /// In en, this message translates to:
  /// **'The shifts stay as they are; only the hints disappear.'**
  String get reviewDismissAllMessage;

  /// Shown in the review list instead of a shift that no longer exists.
  ///
  /// In en, this message translates to:
  /// **'This shift was deleted.'**
  String get reviewShiftDeleted;

  /// Section header above old entries that could not be imported.
  ///
  /// In en, this message translates to:
  /// **'Not taken over ({count})'**
  String reviewSectionFailures(int count);

  /// Explanation above the entries that could not be imported.
  ///
  /// In en, this message translates to:
  /// **'These entries couldn\'t be read. They\'re not lost: the original data stays on your phone and can be shared.'**
  String get reviewFailuresIntro;

  /// Why an old entry could not be imported: invalid JSON.
  ///
  /// In en, this message translates to:
  /// **'The stored data is unreadable'**
  String get reviewFailureInvalidJson;

  /// Why old entries could not be imported: the stored value is not a list.
  ///
  /// In en, this message translates to:
  /// **'The list of entries is unreadable'**
  String get reviewFailureNotAList;

  /// Why an old entry could not be imported: not an object.
  ///
  /// In en, this message translates to:
  /// **'The entry is unreadable'**
  String get reviewFailureNotAnObject;

  /// Why an old entry could not be imported.
  ///
  /// In en, this message translates to:
  /// **'Start time is missing'**
  String get reviewFailureMissingStart;

  /// Why an old entry could not be imported.
  ///
  /// In en, this message translates to:
  /// **'Start time is unreadable'**
  String get reviewFailureInvalidStart;

  /// Why an old entry could not be imported.
  ///
  /// In en, this message translates to:
  /// **'End time is missing'**
  String get reviewFailureMissingEnd;

  /// Why an old entry could not be imported.
  ///
  /// In en, this message translates to:
  /// **'End time is unreadable'**
  String get reviewFailureInvalidEnd;

  /// Why an old entry could not be imported.
  ///
  /// In en, this message translates to:
  /// **'The end is not after the start'**
  String get reviewFailureEndNotAfterStart;

  /// Why the running session of the old version could not be imported.
  ///
  /// In en, this message translates to:
  /// **'The running session is unreadable'**
  String get reviewFailureInvalidActiveSession;

  /// Why the running session of the old version could not be imported.
  ///
  /// In en, this message translates to:
  /// **'Another shift was already running'**
  String get reviewFailureRunningShiftExists;

  /// Why the old settings could not be imported.
  ///
  /// In en, this message translates to:
  /// **'Settings were unreadable – defaults are used'**
  String get reviewFailureInvalidSettings;

  /// Why an old entry could not be imported: the database refused it.
  ///
  /// In en, this message translates to:
  /// **'The entry couldn\'t be saved'**
  String get reviewFailureInsertFailed;

  /// Empty state title of the review screen.
  ///
  /// In en, this message translates to:
  /// **'All checked'**
  String get reviewEmptyTitle;

  /// Empty state text of the review screen.
  ///
  /// In en, this message translates to:
  /// **'There are no entries from the old version left to check.'**
  String get reviewEmptyMessage;

  /// Name of the Android notification channel for the ongoing shift (shown in system settings).
  ///
  /// In en, this message translates to:
  /// **'Running shift'**
  String get notificationChannelRunningName;

  /// Description of the running shift notification channel.
  ///
  /// In en, this message translates to:
  /// **'Shows the running shift with a stopwatch.'**
  String get notificationChannelRunningDescription;

  /// Name of the Android notification channel for reminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get notificationChannelRemindersName;

  /// Description of the reminders notification channel.
  ///
  /// In en, this message translates to:
  /// **'Asks whether you\'re still working after a long shift.'**
  String get notificationChannelRemindersDescription;

  /// Title of the ongoing notification while a shift runs.
  ///
  /// In en, this message translates to:
  /// **'Shift running'**
  String get notificationRunningTitle;

  /// Title of the ongoing notification when the user has more than one job.
  ///
  /// In en, this message translates to:
  /// **'Shift running · {job}'**
  String notificationRunningTitleWithJob(String job);

  /// Text of the ongoing notification: start time and hourly rate.
  ///
  /// In en, this message translates to:
  /// **'since {time} · {rate}'**
  String notificationRunningBody(String time, String rate);

  /// Text of the ongoing notification while the shift is paused.
  ///
  /// In en, this message translates to:
  /// **'Paused since {time}'**
  String notificationPausedBody(String time);

  /// Notification action that pauses the running shift.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get notificationActionPause;

  /// Notification action that resumes the paused shift.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get notificationActionResume;

  /// Notification action that opens the app to finish the shift.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get notificationActionFinish;

  /// Title of the reminder some hours after a shift started.
  ///
  /// In en, this message translates to:
  /// **'Still working?'**
  String get notificationReminderTitle;

  /// Text of the still-working reminder.
  ///
  /// In en, this message translates to:
  /// **'Your shift has been running since {time}. Tap Finish when you\'re done.'**
  String notificationReminderBody(String time);
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
