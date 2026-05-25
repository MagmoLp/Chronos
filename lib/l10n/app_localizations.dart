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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('en')
  ];

  /// No description provided for @appTitle.
  ///
  /// In de, this message translates to:
  /// **'Chronos'**
  String get appTitle;

  /// No description provided for @currentEarnings.
  ///
  /// In de, this message translates to:
  /// **'Aktueller Verdienst'**
  String get currentEarnings;

  /// No description provided for @totalOpenEarnings.
  ///
  /// In de, this message translates to:
  /// **'Gesamter offener Betrag'**
  String get totalOpenEarnings;

  /// No description provided for @start.
  ///
  /// In de, this message translates to:
  /// **'START'**
  String get start;

  /// No description provided for @stop.
  ///
  /// In de, this message translates to:
  /// **'STOPP'**
  String get stop;

  /// No description provided for @confirmStopTitle.
  ///
  /// In de, this message translates to:
  /// **'Timer stoppen?'**
  String get confirmStopTitle;

  /// No description provided for @confirmStop.
  ///
  /// In de, this message translates to:
  /// **'Sind Sie sicher, dass Sie stoppen möchten?'**
  String get confirmStop;

  /// No description provided for @cancel.
  ///
  /// In de, this message translates to:
  /// **'Abbrechen'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In de, this message translates to:
  /// **'Bestätigen'**
  String get confirm;

  /// No description provided for @workTimeLog.
  ///
  /// In de, this message translates to:
  /// **'Arbeitszeit-Protokoll'**
  String get workTimeLog;

  /// No description provided for @settings.
  ///
  /// In de, this message translates to:
  /// **'Einstellungen'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In de, this message translates to:
  /// **'Sprache'**
  String get language;

  /// No description provided for @theme.
  ///
  /// In de, this message translates to:
  /// **'Erscheinungsbild'**
  String get theme;

  /// No description provided for @darkMode.
  ///
  /// In de, this message translates to:
  /// **'Dunkelmodus'**
  String get darkMode;

  /// No description provided for @lightMode.
  ///
  /// In de, this message translates to:
  /// **'Hellmodus'**
  String get lightMode;

  /// No description provided for @hourlyWage.
  ///
  /// In de, this message translates to:
  /// **'Stundenlohn (€)'**
  String get hourlyWage;

  /// No description provided for @enterWage.
  ///
  /// In de, this message translates to:
  /// **'Lohn eingeben'**
  String get enterWage;

  /// No description provided for @workEntries.
  ///
  /// In de, this message translates to:
  /// **'Arbeitseinträge'**
  String get workEntries;

  /// No description provided for @addEntry.
  ///
  /// In de, this message translates to:
  /// **'Eintrag hinzufügen'**
  String get addEntry;

  /// No description provided for @editEntry.
  ///
  /// In de, this message translates to:
  /// **'Eintrag bearbeiten'**
  String get editEntry;

  /// No description provided for @delete.
  ///
  /// In de, this message translates to:
  /// **'Löschen'**
  String get delete;

  /// No description provided for @date.
  ///
  /// In de, this message translates to:
  /// **'Datum'**
  String get date;

  /// No description provided for @startTime.
  ///
  /// In de, this message translates to:
  /// **'Startzeit'**
  String get startTime;

  /// No description provided for @endTime.
  ///
  /// In de, this message translates to:
  /// **'Endzeit'**
  String get endTime;

  /// No description provided for @totalTime.
  ///
  /// In de, this message translates to:
  /// **'Gesamtzeit'**
  String get totalTime;

  /// No description provided for @paid.
  ///
  /// In de, this message translates to:
  /// **'Abgerechnet'**
  String get paid;

  /// No description provided for @save.
  ///
  /// In de, this message translates to:
  /// **'Speichern'**
  String get save;

  /// No description provided for @noEntries.
  ///
  /// In de, this message translates to:
  /// **'Keine Einträge vorhanden'**
  String get noEntries;

  /// No description provided for @hours.
  ///
  /// In de, this message translates to:
  /// **'h'**
  String get hours;

  /// No description provided for @minutes.
  ///
  /// In de, this message translates to:
  /// **'min'**
  String get minutes;

  /// No description provided for @earned.
  ///
  /// In de, this message translates to:
  /// **'Verdient'**
  String get earned;

  /// No description provided for @entryDeleted.
  ///
  /// In de, this message translates to:
  /// **'Eintrag gelöscht'**
  String get entryDeleted;

  /// No description provided for @entrySaved.
  ///
  /// In de, this message translates to:
  /// **'Eintrag gespeichert'**
  String get entrySaved;

  /// No description provided for @tooShortEntry.
  ///
  /// In de, this message translates to:
  /// **'Zeit zu kurz (unter 15 Min). Es wurde nicht gespeichert.'**
  String get tooShortEntry;

  /// No description provided for @workSaved.
  ///
  /// In de, this message translates to:
  /// **'Arbeitszeit gespeichert'**
  String get workSaved;

  /// No description provided for @endAfterStart.
  ///
  /// In de, this message translates to:
  /// **'Endzeit muss nach Startzeit liegen'**
  String get endAfterStart;

  /// No description provided for @wageExample.
  ///
  /// In de, this message translates to:
  /// **'Beispiel: 15 oder 15.50'**
  String get wageExample;

  /// No description provided for @confirmDelete.
  ///
  /// In de, this message translates to:
  /// **'Diesen Eintrag wirklich löschen?'**
  String get confirmDelete;

  /// No description provided for @unmarkPaidTitle.
  ///
  /// In de, this message translates to:
  /// **'Abrechnung aufheben?'**
  String get unmarkPaidTitle;

  /// No description provided for @unmarkPaidContent.
  ///
  /// In de, this message translates to:
  /// **'Diesen Eintrag wirklich als nicht abgerechnet markieren?'**
  String get unmarkPaidContent;
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
      'that was used.');
}
