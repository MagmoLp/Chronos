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
