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
  String get navToday => 'Heute';

  @override
  String get navShifts => 'Schichten';

  @override
  String get navInsights => 'Übersicht';

  @override
  String get commonSave => 'Speichern';

  @override
  String get commonCancel => 'Abbrechen';

  @override
  String get commonDelete => 'Löschen';

  @override
  String get commonUndo => 'Rückgängig';

  @override
  String get commonEdit => 'Bearbeiten';

  @override
  String get commonDuplicate => 'Duplizieren';

  @override
  String get commonRetry => 'Erneut versuchen';

  @override
  String get commonClose => 'Schließen';

  @override
  String get commonDone => 'Fertig';

  @override
  String get commonNext => 'Weiter';

  @override
  String get commonBack => 'Zurück';

  @override
  String get commonShare => 'Teilen';

  @override
  String get commonSettings => 'Einstellungen';

  @override
  String get commonOk => 'OK';

  @override
  String get commonDiscard => 'Verwerfen';

  @override
  String get commonAdd => 'Hinzufügen';

  @override
  String get commonExport => 'Exportieren';

  @override
  String get commonDismiss => 'Ausblenden';

  @override
  String get commonMoreOptions => 'Weitere Optionen';

  @override
  String get commonOpenSettings => 'Einstellungen öffnen';

  @override
  String get commonLoading => 'Wird geladen …';

  @override
  String get commonAll => 'Alle';

  @override
  String get statusPaid => 'Bezahlt';

  @override
  String get statusOpen => 'Offen';

  @override
  String get statusRunning => 'Läuft';

  @override
  String get statusPaused => 'Pausiert';

  @override
  String get dateToday => 'Heute';

  @override
  String get dateYesterday => 'Gestern';

  @override
  String formatToday(String date) {
    return 'Heute, $date';
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
      other: '$count Stunden',
      one: '1 Stunde',
    );
    return '$_temp0';
  }

  @override
  String durationSpokenMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Minuten',
      one: '1 Minute',
    );
    return '$_temp0';
  }

  @override
  String durationSpokenHoursMinutes(String hours, String minutes) {
    return '$hours $minutes';
  }

  @override
  String get errorGeneric =>
      'Etwas ist schiefgelaufen. Bitte versuch es noch einmal.';

  @override
  String get errorLoadFailed => 'Deine Daten konnten nicht geladen werden.';

  @override
  String get errorSaveFailed =>
      'Speichern hat nicht geklappt. Bitte versuch es noch einmal.';

  @override
  String get errorRequired => 'Bitte gib einen Wert ein';

  @override
  String errorInvalidAmount(String example) {
    return 'Gib einen Betrag wie $example ein';
  }

  @override
  String get errorAmountNotPositive => 'Der Betrag muss größer als 0 sein';

  @override
  String errorInvalidTime(String example) {
    return 'Gib eine Uhrzeit wie $example ein';
  }

  @override
  String get timeFieldPick => 'Uhrzeit wählen';

  @override
  String timeFieldEarlier(int minutes) {
    return '$minutes Minuten früher';
  }

  @override
  String timeFieldLater(int minutes) {
    return '$minutes Minuten später';
  }

  @override
  String get shiftsAddShift => 'Schicht';

  @override
  String get shiftsAddShiftTooltip => 'Schicht hinzufügen';

  @override
  String get shiftsFilterLabel => 'Schichten anzeigen';

  @override
  String shiftsRunningSince(String time) {
    return 'Läuft seit $time';
  }

  @override
  String shiftsPausedSince(String time) {
    return 'Pausiert seit $time';
  }

  @override
  String get shiftsRunningOpenToday => 'Auf „Heute“ öffnen';

  @override
  String shiftsMonthOpen(String amount) {
    return '$amount offen';
  }

  @override
  String shiftsBreak(String duration) {
    return 'Pause $duration';
  }

  @override
  String shiftsTips(String amount) {
    return 'Trinkgeld $amount';
  }

  @override
  String shiftsTimeRangeSpoken(String start, String end) {
    return '$start bis $end';
  }

  @override
  String shiftsTimeRangeSpokenNextDay(String start, String end) {
    return '$start bis $end am nächsten Tag';
  }

  @override
  String get shiftsEmptyTitle => 'Noch keine Schichten';

  @override
  String get shiftsEmptyMessage =>
      'Starte eine Schicht auf „Heute“ oder trag eine nach, die du schon gearbeitet hast.';

  @override
  String get shiftsStartShift => 'Schicht starten';

  @override
  String get shiftsAddPastShift => 'Schicht nachtragen';

  @override
  String get shiftsEmptyOpenTitle => 'Keine offenen Schichten';

  @override
  String get shiftsEmptyOpenMessage => 'Alles ist bezahlt.';

  @override
  String get shiftsEmptyPaidTitle => 'Noch keine bezahlten Schichten';

  @override
  String get shiftsEmptyPaidMessage =>
      'Markier Schichten als bezahlt oder erfasse eine Auszahlung.';

  @override
  String get shiftsShowAll => 'Alle Schichten anzeigen';

  @override
  String get shiftsMarkPaid => 'Als bezahlt markieren';

  @override
  String get shiftsMarkOpen => 'Als offen markieren';

  @override
  String get shiftsMarkedPaid => 'Als bezahlt markiert';

  @override
  String get shiftsMarkedOpen => 'Als offen markiert';

  @override
  String get shiftsDeleted => 'Schicht gelöscht';

  @override
  String shiftsSaved(String duration, String amount) {
    return 'Schicht gespeichert · $duration · $amount';
  }

  @override
  String get shiftsErrorNotFound => 'Diese Schicht gibt es nicht mehr.';

  @override
  String get shiftsErrorRunning =>
      'Die laufende Schicht kannst du auf „Heute“ ändern.';

  @override
  String get shiftsErrorAlreadyRunning => 'Es läuft schon eine andere Schicht.';

  @override
  String get shiftsErrorJobNotFound => 'Diesen Job gibt es nicht mehr.';

  @override
  String get shiftsErrorNoWage =>
      'Für diesen Job ist noch kein Stundenlohn hinterlegt.';

  @override
  String get shiftsErrorInvalid => 'Bitte prüf deine Eingaben.';

  @override
  String get editorTitleNew => 'Neue Schicht';

  @override
  String get editorTitleEdit => 'Schicht bearbeiten';

  @override
  String get editorJob => 'Job';

  @override
  String get editorDate => 'Datum';

  @override
  String get editorPickDate => 'Datum wählen';

  @override
  String get editorStart => 'Start';

  @override
  String get editorEnd => 'Ende';

  @override
  String get editorEndsNextDay => 'Endet am nächsten Tag';

  @override
  String get editorEndsNextDayAuto =>
      'Automatisch eingeschaltet, weil das Ende vor dem Start liegt';

  @override
  String get editorBreak => 'Pause';

  @override
  String editorBreakLess(int minutes) {
    return '$minutes Minuten weniger Pause';
  }

  @override
  String editorBreakMore(int minutes) {
    return '$minutes Minuten mehr Pause';
  }

  @override
  String get editorBreakInvalid => 'Gib die Pause in ganzen Minuten ein';

  @override
  String get editorTips => 'Trinkgeld';

  @override
  String get editorNote => 'Notiz';

  @override
  String get editorStatus => 'Status';

  @override
  String editorPreview(String duration, String rate, String amount) {
    return '$duration × $rate = $amount';
  }

  @override
  String editorPreviewSpoken(String duration, String rate, String amount) {
    return '$duration zu $rate ergibt $amount';
  }

  @override
  String editorPreviewTips(String amount) {
    return 'plus $amount Trinkgeld';
  }

  @override
  String get editorErrorEndNotAfterStart =>
      'Das Ende muss nach dem Start liegen.';

  @override
  String get editorErrorBreakTooLong =>
      'Die Pause muss kürzer als die Schicht sein.';

  @override
  String editorWarningLong(String duration) {
    return 'Länger als 16 Stunden ($duration)';
  }

  @override
  String editorWarningOverlap(String date, String time) {
    return 'Überschneidet sich mit $date · $time';
  }

  @override
  String editorWarningOverlapRunning(String time) {
    return 'Überschneidet sich mit der laufenden Schicht (seit $time)';
  }

  @override
  String get editorWarningFuture => 'Beginnt in der Zukunft';

  @override
  String get editorConfirmTitle => 'Trotzdem speichern?';

  @override
  String get editorConfirmSave => 'Trotzdem speichern';

  @override
  String get editorDiscardTitle => 'Änderungen verwerfen?';

  @override
  String get editorDiscardMessage =>
      'Deine Änderungen an dieser Schicht gehen verloren.';

  @override
  String get editorKeepEditing => 'Weiter bearbeiten';

  @override
  String get editorCopyNotice =>
      'Kopie für heute angelegt. Pass sie an oder lösch sie wieder.';

  @override
  String get payoutTitle => 'Auszahlung erfassen';

  @override
  String get payoutAllJobs => 'Alle Jobs';

  @override
  String get payoutUntil => 'Bis einschließlich';

  @override
  String payoutSummary(int count, String hours) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Schichten',
      one: '1 Schicht',
    );
    return '$_temp0 · $hours';
  }

  @override
  String get payoutExpected => 'Erwartet';

  @override
  String get payoutReceived => 'Erhalten';

  @override
  String get payoutDifference => 'Differenz';

  @override
  String payoutDifferencePositive(String amount) {
    return '+$amount';
  }

  @override
  String get payoutPaidOn => 'Ausgezahlt am';

  @override
  String payoutSubmit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Schichten als bezahlt markieren',
      one: '1 Schicht als bezahlt markieren',
    );
    return '$_temp0';
  }

  @override
  String get payoutNothingOpen =>
      'Bis zu diesem Datum gibt es keine offenen Schichten.';

  @override
  String payoutRecorded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Schichten als bezahlt markiert',
      one: '1 Schicht als bezahlt markiert',
    );
    return '$_temp0';
  }

  @override
  String get payoutErrorAmount => 'Der erhaltene Betrag ist ungültig.';
}
