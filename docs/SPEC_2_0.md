# Chronos 2.0 – Funktionsspezifikation

Verbindliche Beschreibung dessen, was 2.0 kann. Abgestimmt mit dem Besitzer am 30.09.2026.
Nicht in 2.0: Homescreen-Widget, Schichtplanung/Kalender, Zuschläge (Nacht/Sonntag/Feiertag),
Länderregeln (DE/AT), gesetzliche Pausenregeln, Cloud-Sync, Geofencing.

## Grundregeln

- Geld: immer `int` Cent. Verdienst einer Schicht = kaufmännisch gerundet
  `(gearbeitete ms × Cent/h) / 3 600 000` (half-up, reine Ganzzahl-Arithmetik).
  Gearbeitete Zeit = (Ende − Start) − Pause, nie negativ.
- „Verdient“ bedeutet Lohn **ohne** Trinkgeld. Trinkgeld wird getrennt geführt.
  „Offen“ = Lohn aller nicht bezahlten, abgeschlossenen, nicht gelöschten Schichten (+ laufende Schicht live).
- Zeiten: gespeichert als UTC (ms) plus UTC-Offset (Minuten) für Start und Ende. Angezeigt in lokaler Zeit.
  Datumsrechnung nur über `DateTime(y, m, d + n, h, min)`, nie `add(Duration(days: n))` auf lokale Zeiten.
- Eine Schicht „gehört“ zu dem lokalen Kalendertag, an dem sie beginnt. Wochen beginnen am Montag.
- Jede Schicht speichert den Stundenlohn, mit dem sie verdient wurde (Schnappschuss).
  Lohnänderungen gelten „ab Datum“ und ändern alte Schichten nicht (außer der Nutzer wählt ausdrücklich
  „offene Schichten ab diesem Datum neu berechnen“).
- Höchstens eine laufende Schicht.
- Löschen ist ein Soft-Delete mit Rückgängig; endgültig entfernt wird beim nächsten App-Start
  (bzw. nach Ablauf der Rückgängig-Frist).
- Kein Code läuft im Hintergrund. Keine Dart-Timer, wenn die App nicht sichtbar ist. Kein Foreground-Service.
- Alle Texte lokalisiert (Deutsch, Englisch). Zahlen/Datum/Uhrzeit über `intl` passend zur App-Sprache
  und Geräteregion; 12/24 h folgt der Systemeinstellung.

## Navigation

- Drei Ziele: **Heute**, **Schichten**, **Übersicht**. Einstellungen: Zahnrad oben rechts auf jedem Ziel.
- Handy hochkant (Breite < 600 dp): `NavigationBar` unten. Breite ≥ 600 dp oder Höhe < 480 dp: `NavigationRail` links.
  Tabs behalten ihren Zustand (`IndexedStack`). Inhalt max. 840 dp breit, zentriert.
- Zurück-Taste auf Schichten/Übersicht → zurück zu Heute, erst dann App verlassen.

## Heute

- Titel: lokalisiertes Datum („Heute, Mi 30. Sep“ / „Today, Wed 30 Sep“), Zahnrad rechts.
- **Hauptkarte**
  - Schicht läuft: Kopfzeile „● Läuft“ (+ „· Jobname“, wenn > 1 Job). Groß: **„Heute verdient“** = Lohn aller
    heutigen abgeschlossenen Schichten + laufende Schicht live. Darunter: gearbeitete Zeit „3:11:42“ (ohne Pausen),
    „seit 08:02“ (antippen → Startzeit ändern), Stundenlohn „15,00 €/h“, falls Pause > 0 „Pause 0:30“.
    Pausiert: Kopfzeile „⏸ Pausiert seit 14:32“, Zeit steht.
  - Keine laufende Schicht, heute schon gearbeitet: groß „Heute verdient“ (statisch).
  - Keine laufende Schicht, heute nichts: groß **„Offen“** (Gesamt offen) + „N Schichten · X h“ + Button
    „Auszahlung erfassen“.
- Unter der Karte: „Offen gesamt“ (wenn nicht schon Hauptzahl), bei laufender Schicht und weiteren
  Schichten heute zusätzlich „davon diese Schicht“.
- Rollende Ziffern: nur geänderte Ziffern animieren, neue Ziffer kommt **von oben**; tabellarische Ziffern;
  Betrag aktualisiert sich, wenn ein neuer Cent verdient ist (max. 4×/s), Zeit einmal pro Sekunde;
  beides nur, solange die App sichtbar ist. `MediaQuery.disableAnimations` → ohne Animation.
- **Aktionen**
  - Leerlauf: Job-Auswahl (Chip, nur wenn > 1 Job), großer Button **„Schicht starten“**,
    darunter Textbutton „Früher angefangen?“ → Uhrzeit wählen → Schicht startet mit dieser Startzeit
    (nicht in der Zukunft, nicht vor Ende der letzten Schicht ohne Warnung).
  - Läuft: **„Pause“** / **„Fortsetzen“** (tonal) und **„Beenden“** (primär).
- **„Schicht beenden“-Blatt** (öffnet sich bei „Beenden“ und aus der Benachrichtigung):
  Start (roh → gerundet, falls Job-Rundung aktiv), Ende (jetzt, änderbar), Pause (Minuten, änderbar),
  Dauer, Betrag = Dauer × Lohn, optional Trinkgeld, optional Notiz.
  Buttons: **Speichern** (primär), **Weiterlaufen lassen**, **Verwerfen** (fragt nach).
  Wegwischen = weiterlaufen. Keine Mindestdauer, nichts wird still verworfen.
  Nach Speichern: Snackbar „Schicht gespeichert · 7:45 h · 116,25 €“ mit **Rückgängig** (→ Schicht läuft wieder).
- Unter den Aktionen: „Diese Woche · 18,5 h · 256,75 €“ und „Letzte Schicht Mo 08:00–16:15 · 8:15 h ›“ (→ Editor).
- Hinweis-Karten (nur wenn zutreffend): „N übernommene Einträge prüfen“ (Migration), „Benachrichtigungen sind aus –
  Einstellungen öffnen“.
- Benachrichtigungs-Berechtigung: beim **ersten** „Schicht starten“ mit kurzer Erklärung (Blatt) anfragen.
  Ablehnung → App funktioniert normal, Hinweis-Karte.

## Schichten

- Filter-Chips: **Alle / Offen / Bezahlt**. Erweiterter FAB **„Schicht“** (+). Überlaufmenü: „Auszahlung erfassen“,
  „Exportieren“.
- Laufende Schicht als eigene Kachel oben („Läuft seit 08:02“ → Heute).
- Liste nach Monaten (lokaler Starttag), neueste oben. Monatskopf: „September 2026“ + „42,5 h · 637,50 € · 318,75 € offen“.
- Zeile (≈ 72 dp): links Datumsblock (Tag + Wochentag), Titel „08:00–16:15 · 7:45 h“ („+1“ bei Ende am Folgetag),
  Untertitel: Job (wenn > 1) · „Pause 30 min“ · „Trinkgeld 5,00 €“ · Notiz (gekürzt); rechts Betrag + Status-Symbol
  (bezahlt: Haken; offen: Uhr). Bezahlt nicht nur über Farbe erkennbar.
- **Tippen** → Editor. **Lange drücken** → Menü: Bearbeiten, Duplizieren, Als bezahlt/offen markieren, Löschen.
- **Wischen nach rechts** → bezahlt/offen umschalten, **nach links** → löschen; beides mit Rückgängig-Snackbar.
  Beide Aktionen auch als Bedienhilfe-Aktionen (TalkBack).
- Leerzustand: „Noch keine Schichten“ + „Schicht starten“ (→ Heute) + „Schicht nachtragen“.

### Schicht-Editor (Hinzufügen & Bearbeiten, ein Bauteil)

- Felder: Job (nur wenn > 1 Job), Datum, Start, Ende, Schalter **„Endet am nächsten Tag“**, Pause (Minuten),
  Trinkgeld, Notiz, Status **Offen | Bezahlt**.
- Uhrzeit per Tastatur („0815“, „8:15“, „8“) oder Auswahl; ±15-min-Knöpfe. Liegt Ende ≤ Start, wird „Endet am nächsten
  Tag“ automatisch eingeschaltet und sichtbar markiert.
- Live-Vorschau: „7:45 h × 15,00 €/h = 116,25 €“. Neue Schicht: Lohn des Jobs zum Datum. Bearbeiten: gespeicherter
  Lohn bleibt, außer Job wird gewechselt.
- Neue Schicht: Vorbelegung Datum = heute, Zeiten = letzte Schicht desselben Jobs (sonst 08:00–16:00).
- Prüfungen: Ende = Start → Fehler. Pause ≥ Dauer → Fehler. Dauer > 16 h → Warnung (Speichern nach Bestätigung).
  Überschneidung mit anderer Schicht → Warnung mit Angabe der Schicht. Start in der Zukunft → Warnung.
- Speichern-Button während des Speicherns gesperrt (kein Doppel-Speichern). Bearbeiten-Modus zusätzlich:
  **Löschen** (mit Rückgängig) und **Duplizieren**.
- Manuelle Schichten werden nicht gerundet.

### Auszahlung erfassen (Blatt)

- Job (wenn > 1: einzelner Job oder „Alle Jobs“), „Bis einschließlich“ Datum (Standard heute).
- Zusammenfassung: „23 Schichten · 172,5 h“, **Erwartet 2.587,50 €**, Feld **Erhalten** (vorbelegt mit erwartet),
  **Differenz**, „Ausgezahlt am“ (Standard heute), Notiz.
- Button „23 Schichten als bezahlt markieren“ → legt Auszahlung an, markiert Schichten, Snackbar mit Rückgängig.
- Keine offenen Schichten → Hinweis statt Button.

## Übersicht

- Umschalter **Woche / Monat / Jahr**, Zeitraum-Stepper „‹ September 2026 ›“ (nicht über den aktuellen Zeitraum hinaus).
- Kennzahlen-Karten: **Stunden**, **Verdient**, **Offen** (im Zeitraum), **Ø Stundenlohn inkl. Trinkgeld**,
  **Trinkgeld** (nur wenn > 0).
- Balkendiagramm Verdienst: Woche → 7 Tage, Monat → Tage, Jahr → 12 Monate. Balken antippen → Wert + Stunden.
  Text-Alternative für TalkBack.
- **Monatsziel / Monatsgrenze** (optional, in Einstellungen): Fortschrittsbalken für den aktuellen Monat
  „438 / 603 €“. Typ „Grenze“ färbt ab 80 % Warnfarbe, ab 100 % Fehlerfarbe.
- Aufteilung nach Job (nur wenn > 1 Job).
- **Auszahlungen**: Liste (Datum, Job, erhalten, Differenz).
- Button „Diesen Zeitraum exportieren“.

## Einstellungen

- **Allgemein**: Sprache (System / Deutsch / English), Design (System / Hell / Dunkel) – je `SegmentedButton`.
- **Arbeit**
  - **Jobs & Stundenlohn** → Liste → Job-Editor: Name, Farbe (6 Farben), Stundenlohn mit Historie
    („15,00 €/h seit 01.01.2026“; „Neuer Lohn ab …“ fügt einen Satz hinzu, optional „offene Schichten ab diesem Datum
    neu berechnen“), Rundung **Aus / 5 min / 15 min** (nächstgelegener Wert, Schwelle genau die Hälfte),
    Archivieren. Mindestens ein aktiver Job.
  - **Monatsziel / Monatsgrenze**: Betrag + Typ, oder aus.
  - **Erinnerung „Arbeitest du noch?“**: Aus / 6 / 8 / 10 / 12 h (Standard 10 h).
- **Benachrichtigungen**: Status, Button zu den System-Einstellungen.
- **Daten**
  - **Exportieren**: Zeitraum, Job, Format **PDF-Stundenzettel** (Datum, Start, Ende, Pause, Stunden, Lohn, Betrag,
    Summen, Unterschriftszeile) oder **CSV** (Excel-DE: `;`, Dezimalkomma, UTF-8-BOM) → Teilen-Menü.
  - **Backup erstellen** (JSON, Teilen-Menü) und **Backup wiederherstellen** (Datei wählen → Zusammenfassung →
    „Ersetzen“ oder „Zusammenführen“).
  - **Alle Daten löschen**: Dialog mit Anzahl („214 Schichten und 2 Jobs löschen?“), legt vorher automatisch eine
    Sicherung an, Snackbar mit Rückgängig.
- **Über**: Version, Datenschutzerklärung (in der App, DE/EN), Open-Source-Lizenzen, **Fehlerbericht teilen**
  (lokales Fehlerprotokoll über Teilen-Menü).

## Erster Start

- Mit v1-Daten: automatische Übernahme (siehe unten), kein Onboarding.
- Ohne Daten: Onboarding in 2 Schritten: Willkommen → „Dein Job“: Name (optional, Standard „Mein Job“),
  Stundenlohn (Pflicht, Komma und Punkt erlaubt). Sprache und Design folgen dem System.

## Übernahme der v1-Daten

- Quelle: alte `shared_preferences`-Schlüssel `work_entries`, `app_settings`, `active_session`
  (Format: `git show v1.0.0:lib/services/storage_service.dart`, `lib/models/*.dart`). Über die **alte** API lesen.
- Rohdaten als `legacy_backup_v1.json` im App-Dokumentenordner sichern. Alte Schlüssel nicht löschen.
- Eine Transaktion: Job „Mein Job“ mit altem Stundenlohn (Rundung **15 min**, weil v1 so gerundet hat), jede Zeile
  einzeln in try/catch umwandeln (lokale Zeit → UTC + Offset), Lohn-Schnappschuss = alter Lohn, bezahlt übernehmen,
  laufende Sitzung als laufende Schicht, Sprache übernehmen (german → de, english → en), Design → System.
- Unlesbare Zeilen: in Fehlerliste, nicht verwerfen.
- **Plausibilitätsprüfung**: Stundenlohn > 100 € oder < 5 € → beim Start nachfragen („1250,00 €/h – stimmt das?“,
  korrigieren ändert Job-Lohn und Schnappschüsse der übernommenen Schichten). Auf die Prüfliste kommen:
  Dauer ≥ 16 h, genau 23 h oder 24 h, gleiche Start/Ende wie eine andere Schicht, doppelte IDs, Überschneidungen,
  Schichten am 29.03. oder 25.10. (Zeitumstellung). Nichts wird automatisch geändert.
- Idempotent, bei jedem Start geprüft.

## Benachrichtigung & Erinnerung

- Kanal `shift_running` („Laufende Schicht“), geringe Wichtigkeit, lautlos, dauerhaft.
  Läuft: native Stoppuhr (`usesChronometer`, `when` = jetzt − gearbeitete Zeit), Titel „Schicht läuft“ (+ Job),
  Text „seit 08:02 · 15,00 €/h“, Aktionen **Pause** und **Beenden**.
  Pausiert: keine Stoppuhr, Text „Pausiert seit 14:32“, Aktionen **Fortsetzen** und **Beenden**.
  Antippen → Heute. „Beenden“ → App öffnet das Beenden-Blatt.
- Wird nur bei Zustandswechsel gepostet. Beim App-Start/Fortsetzen mit der Datenbank abgeglichen.
- Kanal `reminders` („Erinnerungen“): „Arbeitest du noch?“ X Stunden nach Start (nicht exakt geplant,
  `inexactAllowWhileIdle`), Aktion **Beenden**. Wird bei Start-Änderung neu geplant, beim Beenden gelöscht,
  nach Geräteneustart neu geplant.
- Alter v1-Kanal `work_session_timer` wird gelöscht.
- Pause/Fortsetzen aus der Benachrichtigung schreiben direkt in die Datenbank (Hintergrund-Isolat).

## Qualität

- Querformat, Tablet und 200 % Schrift ohne Überlauf; Trefferflächen ≥ 48 dp; TalkBack-Beschriftungen.
- Hell/Dunkel nach Designsystem „Navy Night / Sky Day“ (`docs/research/ux-audit.md`), Systemschrift mit
  tabellarischen Ziffern, keine Skalier-Animationen beim Drücken.
- Fehlerprotokoll: `FlutterError.onError`/`PlatformDispatcher.onError` → lokale Datei (max. ~200 KB).
- Start: `runApp` sofort, Startbildschirm während Datenbank/Migration; Fehler → Wiederherstellungs-Bildschirm
  („Rohdaten teilen“, „Erneut versuchen“).
