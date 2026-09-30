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
