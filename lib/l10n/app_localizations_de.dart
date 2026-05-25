// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Chronos';

  @override
  String get currentEarnings => 'Aktueller Verdienst';

  @override
  String get totalOpenEarnings => 'Gesamter offener Betrag';

  @override
  String get start => 'START';

  @override
  String get stop => 'STOPP';

  @override
  String get confirmStopTitle => 'Timer stoppen?';

  @override
  String get confirmStop => 'Sind Sie sicher, dass Sie stoppen möchten?';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get confirm => 'Bestätigen';

  @override
  String get workTimeLog => 'Arbeitszeit-Protokoll';

  @override
  String get settings => 'Einstellungen';

  @override
  String get language => 'Sprache';

  @override
  String get theme => 'Erscheinungsbild';

  @override
  String get darkMode => 'Dunkelmodus';

  @override
  String get lightMode => 'Hellmodus';

  @override
  String get hourlyWage => 'Stundenlohn (€)';

  @override
  String get enterWage => 'Lohn eingeben';

  @override
  String get workEntries => 'Arbeitseinträge';

  @override
  String get addEntry => 'Eintrag hinzufügen';

  @override
  String get editEntry => 'Eintrag bearbeiten';

  @override
  String get delete => 'Löschen';

  @override
  String get date => 'Datum';

  @override
  String get startTime => 'Startzeit';

  @override
  String get endTime => 'Endzeit';

  @override
  String get totalTime => 'Gesamtzeit';

  @override
  String get paid => 'Abgerechnet';

  @override
  String get save => 'Speichern';

  @override
  String get noEntries => 'Keine Einträge vorhanden';

  @override
  String get hours => 'h';

  @override
  String get minutes => 'min';

  @override
  String get earned => 'Verdient';

  @override
  String get entryDeleted => 'Eintrag gelöscht';

  @override
  String get entrySaved => 'Eintrag gespeichert';

  @override
  String get tooShortEntry =>
      'Zeit zu kurz (unter 15 Min). Es wurde nicht gespeichert.';

  @override
  String get workSaved => 'Arbeitszeit gespeichert';

  @override
  String get endAfterStart => 'Endzeit muss nach Startzeit liegen';

  @override
  String get wageExample => 'Beispiel: 15 oder 15.50';

  @override
  String get confirmDelete => 'Diesen Eintrag wirklich löschen?';

  @override
  String get unmarkPaidTitle => 'Abrechnung aufheben?';

  @override
  String get unmarkPaidContent =>
      'Diesen Eintrag wirklich als nicht abgerechnet markieren?';
}
