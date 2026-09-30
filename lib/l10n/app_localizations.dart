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
