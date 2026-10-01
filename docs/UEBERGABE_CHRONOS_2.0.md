---
tags: [projekt, chronos, übergabe]
status: aktiv
erstellt: 2026-10-01
projekt: "[[Chronos]]"
version: 2.0.0+2
branch: claude/optimistic-brown-56sgj7
---

# Chronos 2.0 – Übergabeprotokoll

> [!summary] Kurzfassung
> Am **30.09. und 01.10.2026** wurde Chronos in einer Claude-Code-Cloud-Sitzung zuerst gründlich analysiert und dann als **Chronos 2.0 komplett neu gebaut**. Gleich geblieben sind die App-ID `com.paulhuebner.chronos` und der Upload-Key. Die Daten der bisherigen Tester werden beim ersten Start automatisch übernommen.
>
> - **Ergebnis:** Alle vereinbarten 2.0-Funktionen sind fertig. Alle nachgewiesenen v1-Fehler sind behoben und mit Tests abgesichert.
> - **Tests:** 1552 laufen grün, auch in der Zeitzone Europe/Berlin. Der Analyzer meldet nichts.
> - **Wo der Stand liegt:** auf GitHub im Branch `claude/optimistic-brown-56sgj7`. Der Branch ist noch **nicht** in `master` gemergt, und es gibt noch keinen Pull Request.
> - **Noch offen:** der Android-Build auf einem echten Rechner. In der Cloud war `dl.google.com` gesperrt, deshalb gab es dort kein Android-SDK. Siehe [[#10. Nächste Schritte]].

---

## 0. Auf einen Blick

| | |
|---|---|
| Repository | https://github.com/MagmoLp/Chronos |
| Branch mit 2.0 | `claude/optimistic-brown-56sgj7`, letzter Commit `8f75a0b` |
| Alter Stand | Commit `9a52779` (v1.0.0, im internen Test seit 26.05.2026). Lokal als Tag `v1.0.0` markiert, der Tag ist **nicht** gepusht |
| Version | `2.0.0+2` (versionName 2.0.0, versionCode 2) |
| Flutter / Dart | Flutter **3.47.5** stable / Dart 3.13.4. Vorher vermutlich Flutter ~3.24 |
| Umfang | 30 Commits · ~25.100 Zeilen handgeschriebener App-Code in 125 Dateien · ~20.000 Zeilen Tests in 90 Dateien |
| Tests | Berlin-Zeitzone: **1552 bestanden**, 10 übersprungen (Screenshot-Generator). UTC: 1528 bestanden, 34 übersprungen (Berlin-spezifische Fälle + Screenshots) |
| Analyzer | `flutter analyze`: keine Befunde (strenge Lints) |
| Texte | 496 Übersetzungs-Schlüssel, Deutsch (Du-Form) und Englisch |
| Android | AGP 9.1.0, Gradle 9.3.1, Kotlin 2.4.0, Java 17. Ziel-API 36, Mindest-API 24 (Android 7.0). **Build noch ungetestet** |

---

## 1. Ausgangslage (v1.0.0)

- **v1.0.0** war die erste eigene App: Flutter, Provider, `shared_preferences`, ca. 2.300 Zeilen. Seit 26.05.2026 im internen Test in der Play Console.
- **Deine Kritik:**
  - mehrere Bugs
  - Design „klobig“
  - Hintergrundnutzung katastrophal, das Handy laggt
  - Funktionen nicht durchdacht
  - die App kann zu wenig
- **Bekannte Bugs aus dem internen Test:**
  - „Alles löschen“ blieb auf Englisch Deutsch.
  - Querformat-Überlauf „BOTTOM OVERFLOWED BY 284 PIXELS“.
  - Dark/Light-Darstellungsproblem.
  - Tablet ungetestet.
  - Löschen war angeblich erst nach einem Neustart sichtbar.
- **Wichtigste Befunde der Analyse:**
  - Mit aktuellem Flutter baute die App **nicht mehr**: `intl ^0.19.0` und `CardTheme` waren veraltet.
  - Gradle, AGP und Kotlin lagen unter den Mindestversionen.
  - Seit 31.08.2026 müssen Updates Ziel-API 36 haben, ein Update von v1 war also gar nicht mehr möglich.
  - **Light Mode war nie implementiert.** Die Einstellung wurde nirgends gelesen, und über 100 Farben waren fest im Code eingetragen.
  - **Grund für das Laggen:** Ein Timer feuerte jede Sekunde, auch im Hintergrund, und baute dabei den ganzen Startbildschirm neu, rund 270 Widgets pro Sekunde. Dazu wurde die Benachrichtigung alle 15 s neu gepostet, also 240-mal pro Stunde.
  - **Datenfehler:**
    - „12,50“ wurde als 1250 €/h gespeichert.
    - Eine Lohnänderung berechnete alle alten (auch bezahlten) Einträge rückwirkend neu.
    - Ein einziger kaputter Wert blockierte den App-Start.
    - Die Zeitumstellung verschob Zeiten um ±1 h.
    - Ende vor Start wurde still als 23-Stunden-Schicht gespeichert.
    - Bei 11,5 % aller Lohn/Dauer-Kombinationen stimmte ein Cent nicht.

Die vollständige Liste steht in `docs/UMBAUPLAN.md` §2 und in `docs/research/`.

---

## 2. Ablauf der Arbeit

### Phase A – Analyse (30.09.2026)

Sechs Recherche-Agents haben parallel gearbeitet. Alle Ergebnisse liegen in `docs/research/` (englisch):

| Schritt | Ergebnis | Datei |
|---|---|---|
| Code-Audit | 41 Bugs, Performance, Architektur, Android-Build, Datenmodell & Migration | `code-audit.md` |
| UX-/Design-Audit | Warum es „klobig“ wirkt; Designsystem „Navy Night / Sky Day“; Wireframes aller Bildschirme; Barrierefreiheit | `ux-audit.md` |
| Markt- und Technik-Recherche | 10 Konkurrenz-Apps, Feature-Ideen, akkuschonendes Hintergrund-Konzept, Stack-Empfehlung, Play-Store-Regeln 2026, Recht DE/AT | `recherche.md` |
| Bug-Reproduktion | 72 echte Flutter-Tests gegen v1; Messwerte zu Überlauf, Rebuilds und Benachrichtigungen | `bug-reproduktion.md`, `repro-tests/` |
| Lösch-Bug-Suche + Gegenprüfung | ~50 Lösch-Szenarien mit Flutter 3.24.5 und 3.47.5 | `verifikation.md` |
| Faktencheck des Plans | Fristen, Zahlen, Versionen, Lücken | `faktencheck.md` |

**Ergebnis zum Lösch-Bug:** Das Löschen selbst funktionierte sofort. Reproduziert wurde ein **Doppeltipp auf „Speichern“** bei langsamem Speicher. Er erzeugte einen doppelten Eintrag und einen **leeren Bildschirm**, den nur ein Neustart behob. Löschte man danach einen der Doppelgänger, stand der andere noch da, und es sah aus, als hätte das Löschen nicht funktioniert. Dazu kamen eine „Zombie-Zeile“ (ein gelöschter Eintrag kam durch „bezahlt“ zurück) und verschluckte Speicherfehler.

### Phase B – Plan & Entscheidungen

- `docs/UMBAUPLAN.md`: Befund, Zielbild, Architektur, Roadmap.
- **Deine Entscheidungen:**
  - **Umfang vereinfacht.** Keine Länderregeln DE/AT, keine gesetzlichen Pausenregeln, keine Zuschläge. Statt der Minijob-Grenze gibt es ein frei einstellbares Monatsziel bzw. eine Monatsgrenze.
  - **Kein Sicherheits-Update v1.0.1**, direkt 2.0 umsetzen.
  - Höchstens 4 Subagents gleichzeitig.
- Verbindlicher Funktionsumfang: **`docs/SPEC_2_0.md`**.

### Phase C – Umsetzung (30.09. abends bis 01.10.)

1. **Grundgerüst** (Commit `29bbe7c`):
   - v1-Code aus `lib/` entfernt; er bleibt über `git show 9a52779:<pfad>` erreichbar.
   - Neue Abhängigkeiten.
   - `CLAUDE.md` mit festen Entwicklungsregeln.
   - Strengere Lints.
   - Englisch als Vorlagesprache.
2. **Fundament** (3 Agents parallel, jeder in einem eigenen Git-Worktree):
   - **Kern:** Domain-Logik, Datenbank, v1-Migration, Backup, Riverpod-State.
   - **Design:** Theme, Formatierer, Bausteine, Navigation.
   - **Android/Plattform:** Gradle, Manifest, Icons, Benachrichtigungen, Teilen.
3. **Vorbereitung** (Commit `cc20f7a`): Schnittstellen zwischen den Bildschirmen als Platzhalter, Plattform-Provider und eine gemeinsame Test-Umgebung mit In-Memory-Datenbank und Fakes.
4. **Bildschirme** (4 Agents parallel):
   - Heute
   - Schichten mit Editor und Auszahlung
   - Übersicht, Export und Einstellungen. Dieser Agent brach am Sitzungslimit ab; sein Zwischenstand wurde gesichert und von einem neuen Agent fertiggestellt.
   - Integration: App-Start, Onboarding, Prüfliste, Wiederherstellung, Benachrichtigungen.
5. **Zusammenführen:**
   - Übersetzungsdateien per Skript vereinigt.
   - Tests an die echten Seiten angepasst.
6. **Qualitätssicherung:**
   - Ein Review-Agent hat gezielt nach Fehlern gesucht und 2 gefunden und behoben.
   - Danach habe ich 2 weitere Probleme behoben.
   - Ein Abnahme-Agent hat die App Punkt für Punkt gegen die Spezifikation geprüft und einen kompletten Ablauf-Test von der Installation bis zum Export geschrieben.
7. **Screenshots** aller Hauptbildschirme, gerendert aus der echten App: `docs/screenshots/`, eingebunden in die README.

### Commit-Historie (ohne reine Merge-Commits)

| Commit | Datum | Inhalt |
|---|---|---|
| `45be8f2` | 30.09. | Analyse + Plan (Entwurf), Recherche-Dateien, Reproduktions-Tests |
| `79e8e20` | 30.09. | Lösch-Bug-Untersuchung + Verifikation |
| `2ca008b` | 30.09. | Plan nach Faktencheck finalisiert |
| `29bbe7c` | 30.09. | Start 2.0: v1-Code entfernt, Spezifikation, Regeln, Abhängigkeiten |
| `408a636` | 30.09. | Vereinfachten Umfang im Plan vermerkt |
| `da71edb` | 30.09. | Agent-Worktrees in `.gitignore` |
| `dc9b596` | 30.09. | Designsystem, adaptive Navigation, Formatierer, Bausteine |
| `37c596c` | 30.09. | Kern: Domain-Logik, drift-Datenbank, v1-Migration, Riverpod-State |
| `960fbe0` | 30.09. | Android: Gradle/Manifest modernisiert, Benachrichtigungen, Teilen |
| `cc20f7a` | 30.09. | Vorbereitung der Bildschirm-Phase (Provider, Platzhalter, Test-Harness) |
| `0c3700a` | 30.09. | Bildschirm „Heute“ |
| `da708a9` | 30.09. | Integration: App-Start, Onboarding, Prüfliste, Wiederherstellung, Benachrichtigungen |
| `23693ec` | 30.09. | Bildschirm „Schichten“, Editor, Auszahlung |
| `18a6057` | 01.10. | Übersicht/Export/Einstellungen, Zwischenstand nach dem Abbruch |
| `0bac68c` | 01.10. | Start-Tests an die echte „Heute“-Seite angepasst |
| `e69a58e` | 01.10. | Übersicht, Export, Einstellungen fertiggestellt |
| `8748283` | 01.10. | Screenshots in der README |
| `cc48488` | 01.10. | Fix: Editor kürzte unveränderte >24-h-Schichten (D11) + verspäteter erster Start |
| `5c3be87` | 01.10. | „Heute“ wechselt um Mitternacht; Pause beim Verschieben des Starts begrenzt |
| `3a41999` | 01.10. | Umsetzungsstand im Plan |
| `10d1ea8` | 01.10. | Abnahme-Tests: kompletter Ablauf + Spezifikations-/v1-Bug-Lücken |
| `8f75a0b` | 01.10. | (Merge) aktueller Stand |

---

## 3. Was Chronos 2.0 kann

Bilder: `docs/screenshots/` (heute_hell, heute_dunkel, schicht_beenden, schichten, schicht_editor, uebersicht, einstellungen, onboarding, heute_quer, heute_tablet).

### Navigation
- Drei Ziele: **Heute**, **Schichten** und **Übersicht**. Das Zahnrad oben rechts öffnet die Einstellungen.
- Handy hochkant: Leiste unten. Querformat oder Tablet (Breite ab 600 dp oder Höhe unter 480 dp): seitliche Leiste links.
- Jeder Tab behält seinen Zustand, auch die Scrollposition.
- Die Zurück-Taste auf Schichten oder Übersicht führt erst zu Heute und beendet erst dann die App (vorhersagende Zurück-Geste aktiv).

### Heute
- **Titel** „Heute, Mi 30. Sep“. Er wechselt um Mitternacht, auch wenn der Bildschirm an bleibt.
- **Hauptkarte:**
  - **Schicht läuft:** „● Läuft · Job“, groß **„Heute verdient“** (alle heutigen Schichten plus die laufende, live), darunter die Arbeitszeit „5:11:00“ und „seit 08:02“ (antippen, um die Startzeit zu ändern), der Stundenlohn und gegebenenfalls die Pause.
  - **Pausiert:** „Pausiert seit 14:32“, Zeit und Betrag stehen still.
  - **Keine Schicht, heute schon gearbeitet:** „Heute verdient“, statisch.
  - **Heute nichts gearbeitet:** groß **„Offen“** mit Anzahl, Stunden und dem Button „Auszahlung erfassen“.
- **Rollende Ziffern** wie in deiner ursprünglichen Spezifikation:
  - Nur geänderte Ziffern animieren, und die neue Ziffer kommt von oben.
  - Der Betrag aktualisiert sich, sobald ein neuer Cent verdient ist (höchstens 4× pro Sekunde), die Zeit einmal pro Sekunde.
  - Beides läuft nur, solange die App sichtbar ist.
  - „Animationen entfernen“ des Systems wird respektiert.
- „**Offen gesamt**“, bei weiteren Schichten heute zusätzlich „davon diese Schicht“.
- **Aktionen:**
  - Job-Auswahl, nur sichtbar bei mehr als einem Job.
  - Großer Button „**Schicht starten**“.
  - „**Früher angefangen?**“: Uhrzeit wählen. Zeiten in der Zukunft werden abgelehnt, bei Überschneidung kommt eine Rückfrage.
  - Läuft eine Schicht: **Pause/Fortsetzen** (dezent) und **Beenden** (primär).
- **„Schicht beenden“-Blatt:**
  - Inhalt: Start (roh → gerundet, falls der Job rundet), Ende (änderbar), Pause in Minuten (änderbar), Arbeitszeit, Rechnung „5:11 h × 15,00 €/h = 77,75 €“, optional Trinkgeld und Notiz.
  - Buttons: **Speichern / Weiterlaufen lassen / Verwerfen** (fragt nach). Wegwischen lässt die Schicht weiterlaufen.
  - Nach dem Speichern: Snackbar „Schicht gespeichert · 7:45 h · 116,25 €“ mit **Rückgängig**.
  - Es gibt keine Mindestdauer, nichts wird mehr still verworfen.
- **Unten:** „Diese Woche · 12,68 h · 190,25 €“ und „Letzte Schicht“ (antippen öffnet den Editor).
- **Hinweise:** „N übernommene Einträge prüfen“ (nach der v1-Übernahme) und „Benachrichtigungen sind aus → Einstellungen öffnen“.
- **Benachrichtigungs-Erlaubnis:** Beim allerersten Start einer Schicht erklärt ein kurzes Blatt, wofür die Benachrichtigung da ist, dann folgt die Systemabfrage. Bei Ablehnung funktioniert die App normal weiter. Die Startzeit zählt ab dem Tippen, nicht erst ab der Antwort.
- **Querformat:** zwei Spalten ohne Scrollen. **Tablet:** zusätzlich eine Spalte „Heutige Schichten“.

### Schichten
- Filter **Alle / Offen / Bezahlt**, erweiterter Button **„+ Schicht“**. Das Menü ⋮ enthält „Auszahlung erfassen“ und „Exportieren“.
- Eine laufende Schicht erscheint als Kachel oben und führt zu Heute.
- **Monatsgruppen**, neueste oben, mit Kopfzeile „September 2026 · 86 h · 1.267,60 € · 1.267,60 € offen“.
- **Zeile:**
  - links ein Datumsblock (Tag + Wochentag)
  - Titel „08:00–16:00 · 7:30 h“ („+1“, wenn die Schicht am Folgetag endet)
  - Untertitel: Job · Pause · Trinkgeld · Notiz
  - rechts Betrag und Status-Symbol: Uhr = offen, Haken = bezahlt
- **Tippen** öffnet den Editor. **Lange drücken** öffnet das Menü *Bearbeiten / Duplizieren / Als bezahlt/offen markieren / Löschen*.
- **Wischen:** nach rechts bezahlt/offen, nach links löschen, beides mit Rückgängig. Beides ist auch per TalkBack bedienbar.
- **Leerzustand** mit „Schicht starten“ und „Schicht nachtragen“.

### Schicht-Editor (ein Bauteil für Neu und Bearbeiten)
- **Felder:** Job (bei mehr als einem Job), Datum, Start, Ende, Schalter **„Endet am nächsten Tag“**, Pause, Trinkgeld, Notiz, Status **Offen / Bezahlt**.
- Uhrzeiten lassen sich tippen („0815“, „8:15“, „8“), aus einer Uhr wählen oder mit ±15-min-Knöpfen einstellen. Liegt das Ende vor dem Start, schaltet sich „Endet am nächsten Tag“ automatisch ein.
- **Live-Vorschau** „8:00 h × 15,00 €/h = 120,00 €“. Neue Schicht: Lohn des Jobs zum Datum. Bearbeiten: der gespeicherte Lohn bleibt, außer der Job wird gewechselt.
- **Prüfungen:**
  - Fehler: Ende gleich Start; Pause gleich oder länger als die Dauer.
  - Warnungen mit Rückfrage: länger als 16 h, Überschneidung (die andere Schicht wird genannt), Start in der Zukunft.
- „Speichern“ ist während des Speicherns gesperrt, Doppeltipps sind also wirkungslos.
- Im Bearbeiten-Modus zusätzlich **Löschen** (mit Rückgängig) und **Duplizieren**.
- Ungespeicherte Änderungen: Beim Schließen fragt der Editor „Änderungen verwerfen?“.
- Unveränderte Felder bleiben exakt erhalten, also auch Sekunden, Schichten über 24 h und die exakte Pause.

### Auszahlung erfassen
- Job oder „Alle Jobs“, „Bis einschließlich“ Datum.
- Zusammenfassung „N Schichten · X h“, **Erwartet**, Feld **Erhalten** (vorbelegt), **Differenz**, „Ausgezahlt am“, Notiz.
- Der Button „N Schichten als bezahlt markieren“ legt eine Auszahlung an und markiert die Schichten. Mit Rückgängig.

### Übersicht
- **Woche / Monat / Jahr** mit Zeitraum-Stepper (nicht über den aktuellen Zeitraum hinaus).
- **Kennzahlen:** Stunden, Verdient, Offen, Ø-Stundenlohn inkl. Trinkgeld, Trinkgeld.
- **Balkendiagramm** des Verdiensts nach Tagen oder Monaten. Antippen zeigt Wert und Stunden. Für TalkBack gibt es eine Textfassung.
- **Monatsziel / Monatsgrenze**, z. B. „438 / 603 €“. Die Grenze wird ab 80 % gelb und ab 100 % rot.
- Aufteilung nach Job (bei mehr als einem Job), Liste der **Auszahlungen** und „Diesen Zeitraum exportieren“.

### Einstellungen
- **Allgemein:** Sprache (System/Deutsch/English), Design (System/Hell/Dunkel).
- **Arbeit:**
  - **Jobs & Stundenlohn** mit Job-Editor: Name, 6 Farben, Rundung Aus/5/15 min, Lohnhistorie („15,00 €/h seit 01.01.2026“), „Neuer Lohn ab …“ mit optionaler Neuberechnung offener Schichten, Archivieren (mindestens ein aktiver Job bleibt).
  - **Monatsziel/-grenze**.
  - **Erinnerung „Arbeitest du noch?“:** Aus/6/8/10/12 h, Standard 10 h.
- **Benachrichtigungen:** Status und Button zu den Systemeinstellungen.
- **Daten:**
  - **Export:** PDF-Stundenzettel oder CSV (Excel-DE: `;`, Dezimalkomma, UTF-8-BOM).
  - **Backup erstellen** (JSON über das Teilen-Menü) und **Backup wiederherstellen** (Datei wählen → Zusammenfassung → Ersetzen oder Zusammenführen).
  - **Alle Daten löschen:** mit Anzahl, automatischer Sicherung vorher und Rückgängig.
- **Über:** Version, Datenschutzerklärung (DE/EN, in der App), Open-Source-Lizenzen, **Fehlerbericht teilen** (lokales Fehlerprotokoll).

### Erster Start
- **Mit v1-Daten:**
  - Automatische Übernahme, ohne Onboarding.
  - Einmaliger Hinweis „N Einträge aus Chronos 1 übernommen · Prüfen“.
  - Unplausibler Lohn (über 100 € oder unter 5 €): Rückfrage „1.250,00 €/h übernommen – stimmt das?“ mit Vorschlag 12,50 €.
- **Ohne Daten:** Onboarding in 2 Schritten: Willkommen, dann „Dein Job“ (Name optional, Stundenlohn mit Komma oder Punkt).
- **Startbildschirm** in Markenfarbe. Bei Startfehlern erscheint ein **Wiederherstellungs-Bildschirm** mit „Erneut versuchen“, „Rohdaten teilen“ und „Fehlerbericht teilen“.

### Benachrichtigung & Erinnerung
- **Laufende Schicht:** dauerhafte, lautlose Benachrichtigung mit **nativer Stoppuhr**, die Android selbst zeichnet.
  - Titel „Schicht läuft (· Job)“, Text „seit 08:02 · 15,00 €/h“.
  - Aktionen **Pause/Fortsetzen**: laufen im Hintergrund und schreiben direkt in die Datenbank.
  - Aktion **Beenden**: öffnet die App mit dem Beenden-Blatt.
- **Erinnerung „Arbeitest du noch?“** X Stunden nach Start, ohne Exact-Alarm-Berechtigung. Wird neu geplant, wenn sich die Startzeit ändert, und gelöscht, wenn die Schicht endet.
- Gepostet wird **nur bei Zustandswechseln**, beim App-Start und beim Zurückkehren wird mit der Datenbank abgeglichen. Der alte v1-Kanal wird gelöscht.

---

## 4. Behobene v1-Fehler

Jeder Punkt ist durch mindestens einen Test abgesichert. Die Prüfung steht in `test/acceptance/acceptance_checks_test.dart` und in den jeweiligen Feature-Tests.

| Nr. | v1-Fehler | Lösung in 2.0 |
|---|---|---|
| D1 | „12,50“ → 1250 €/h | Geldfelder akzeptieren Komma und Punkt (`Fmt.parseMoneyToCents`); unplausibler Lohn → Rückfrage |
| D2 | Lohnänderung ändert alte (bezahlte) Einträge | Lohn-Schnappschuss pro Schicht + Lohnhistorie „gilt ab“ |
| D3 | Kaputter Wert blockiert den Start | Jeder v1-Eintrag einzeln in try/catch; Fehlerliste; Wiederherstellungs-Bildschirm |
| D4 | Kurze Sitzungen nach dem Stopp verworfen | Keine Mindestdauer; Beenden-Blatt mit „Verwerfen“ nur auf Wunsch + Rückgängig |
| D5 | Viertelstunden-Rundung falsch (Schwelle 7 statt 7,5) | Rundung pro Job (Aus/5/15), exakte Hälfte rundet auf, Rohzeiten bleiben gespeichert |
| D6 | Zeitumstellung ±1 h | UTC + Offset für Start und Ende; Datumsrechnung DST-sicher; Tests unter `TZ=Europe/Berlin` (29.03./25.10.) |
| D7 | Ende vor Start → stille 23-h-Schicht | Schalter „Endet am nächsten Tag“ sichtbar; Ende = Start ist ein Fehler |
| D8 | Cent-Fehler durch `double` | Geld nur als `int` Cent, half-up in Ganzzahl-Arithmetik |
| D9 | Doppeltipp „Speichern“ → Duplikat + leerer Bildschirm | Speichern während des Speicherns gesperrt; Controller lehnen parallele Aktionen ab |
| D10 | Keine Überlappungsprüfung | Warnung mit Angabe der überlappenden Schicht |
| D11 | Vergessener Stopp; Bearbeiten macht aus 30 h → 6 h | Erinnerung „Arbeitest du noch?“; Editor behält unveränderte Felder exakt (`ShiftDraft.fromLocalEdit`) |
| D12 | Gelöschte Einträge tauchen wieder auf; doppelte IDs | Datenbank mit eindeutigen IDs, Soft-Delete, reaktive Abfragen; Aktionen auf gelöschte Schichten werden abgelehnt |
| D13 | Stopp + Tabwechsel → Schicht verloren | Beenden ist eine Datenbank-Transaktion im Controller, unabhängig von Widgets |
| K1 | „Alles löschen“ nur Deutsch, deutsches Tippwort | Alles lokalisiert; normaler Bestätigungsdialog mit Anzahl + Rückgängig |
| K2 | Querformat-Überlauf, Buttons unerreichbar | Adaptives Layout (Leiste/Rail, zwei Spalten), Tests auf 6 Bildschirmgrößen × 2 Schriftgrößen |
| K3 | Light Mode nie implementiert | Vollständiges Hell/Dunkel/System-Theme, keine festen Farben außerhalb des Themes |
| K4 | Kein Tablet-Layout | Navigation Rail, Spalten, max. Inhaltsbreite |
| K5 | Löschen erst nach Neustart sichtbar | Ursache (Doppeltipp, Zombie-Zeile, verschluckte Fehler) beseitigt; Fehler werden angezeigt |
| – | Immer Deutsch beim ersten Start | Sprache folgt dem System |
| – | Berechtigungsabfrage vor dem ersten Bild | Abfrage erst beim ersten „Schicht starten“, mit Erklärung |
| – | Lohnänderung erreichte die Benachrichtigung nicht | Benachrichtigung hängt am Datenmodell, nicht an einem Bildschirm |
| – | 1 s lang „00:00:00“ nach Neustart | Werte werden aus der Startzeit berechnet, ab dem ersten Bild korrekt |
| – | Uneinheitliche Zahlenformate / AM-PM | Ein Formatierer (`lib/core/format.dart`), 12/24 h folgt dem System |
| – | Buntes Launcher-Icon in der Statusleiste | Eigenes Benachrichtigungs-Icon (`ic_stat_chronos`) |
| – | Datumsauswahl nur bis 2029 | Grenzen relativ zum heutigen Datum |
| – | Zurück beendet App / Scrollposition verloren | Zurück → Heute; Tabs behalten den Zustand |
| – | Auto Backup widersprach der Datenschutzerklärung | Datenschutzerklärung DE+EN aktualisiert; Backup-Regeln explizit |
| – | Hintergrund-Lag | Keine Timer im Hintergrund, kein Foreground-Service, Benachrichtigung nur bei Zustandswechsel |

---

## 5. Technik im Detail

### 5.1 Toolchain & Abhängigkeiten

| Paket | Version | Zweck |
|---|---|---|
| Flutter / Dart | 3.47.5 / 3.13.4 | |
| flutter_riverpod | 3.4.3 | Zustand & Abhängigkeiten (handgeschrieben, ohne Codegen) |
| drift + drift_flutter | 2.35.0 / 0.3.1 | SQLite-Datenbank mit reaktiven Abfragen |
| sqlite3 | 3.7.0 | Lädt beim Build vorkompilierte SQLite-Binärdateien von GitHub (der Build-Rechner braucht Internet) |
| shared_preferences | 2.5.5 | Einstellungen (`SharedPreferencesWithCache`) und Lesen der v1-Daten (alte API) |
| clock | 1.1.3 | Testbare Uhr (`clock.now()` statt `DateTime.now()`) |
| uuid | 4.6.0 | IDs für Backup/Zusammenführen |
| path_provider / path | 2.1.6 / 1.9.1 | Dateipfade |
| flutter_local_notifications | 22.3.1 | Benachrichtigung, Aktionen, Erinnerung |
| timezone | 0.11.1 | Geplante Erinnerung (in UTC) |
| flutter_timezone | 5.1.0 | **Deklariert, aber ungenutzt**, kann entfernt werden |
| share_plus / file_picker | 13.3.0 / 13.1.0 | Teilen-Menü, Backup-Datei wählen |
| package_info_plus | 10.2.1 | Versionsanzeige |
| pdf | 3.13.1 | PDF-Stundenzettel (Roboto als Asset eingebettet, wegen € und Umlauten) |
| fl_chart | 1.2.0 | Balkendiagramm |
| intl | 0.20.3 | Zahlen/Datum (Version folgt Flutter) |
| dev: flutter_lints 6.0.0, drift_dev 2.35.0, build_runner 2.16.1 | | |

**Entfernt:** provider (ersetzt durch Riverpod). Die `shared_preferences`-JSON-Speicherung der Einträge ist durch drift ersetzt.

### 5.2 Architektur & Ordner

```
lib/
  main.dart               runApp sofort; Fehlerprotokoll; Provider-Overrides
  app/
    app.dart              MaterialApp (Theme/Sprache aus den Einstellungen, Region bleibt z. B. de_AT)
    startup/              StartupGate (Splash → Wiederherstellung → Onboarding → Lohnprüfung → Shell),
                          HomeShell, Sprachauflösung, Lohnprüfung, Splash
    shell.dart            AdaptiveShell: NavigationBar/NavigationRail, IndexedStack, Zurück-Verhalten
    theme/                Farben, ChronosColors, Textstile, Tokens, Komponenten-Themes
    providers/            Riverpod: Daten, Zusammenfassungen, Statistik, Controller, Plattform
    notifications/        Benachrichtigung ↔ Schicht, Hintergrund-Aktionen, Texte
    lifecycle.dart        Abgleich beim Zurückkehren, Mitternachts-Wechsel (nur sichtbar)
    error_log.dart        Lokales Fehlerprotokoll (~200 KB Ringpuffer)
  core/                   LocalDate, Zeit-Hilfen, Geld-Rechnung, Uhr, Fmt (Formatierer/Parser)
  domain/                 Modelle + reine Logik: pay, rounding, finish, validation, stats, summaries, payout, review
  data/                   drift-Datenbank, Repositories, legacy/ (v1-Migration), backup/, export/ (CSV/PDF)
  platform/               notifications, share_service, app_info (ohne App-Typen, testbar)
  features/               today/ shifts/ insights/ export/ settings/ onboarding/ review/ recovery/ (nur UI)
  widgets/                RollingAmount, LiveTicker, MoneyField, TimeField, EmptyState, DateBlock, StatCard, …
  l10n/                   app_en.arb (Vorlage), app_de.arb + generierte Klassen
```

**Regeln** (stehen in `CLAUDE.md`):
- Keine Logik in Widgets.
- Geld nur als `int` Cent, Zeit nur UTC.
- Riverpod 3 ohne Codegen und ohne `StateNotifier`.
- drift ist die einzige Quelle für Schichtdaten.
- Nichts läuft im Hintergrund.
- Alle Texte über ARB, alle Farben aus dem Theme.

### 5.3 Datenmodell (drift, Schema-Version 1)

| Tabelle | Wichtige Spalten |
|---|---|
| `jobs` | id, uuid, name, colorArgb, rounding (`none`/`nearest5`/`nearest15`), archived, sortOrder, createdAt, updatedAt |
| `wage_rates` | jobId, validFrom (yyyymmdd), centsPerHour; eindeutig je Job + Datum |
| `shifts` | uuid, jobId, status (`running`/`done`), startUtc/endUtc (abgerechnet), rawStartUtc/rawEndUtc (erfasst), startOffsetMin/endOffsetMin, rateCentsPerHour (Schnappschuss), breakMs, pausedAtUtc, tipsCents, note, paidAtUtc, payoutId, amountCents (beim Abschluss), legacyId, source (`timer`/`manual`/`legacy`/`import`), createdAt, updatedAt, deletedAt |
| `payouts` | uuid, jobId (null = alle), untilDate, paidOn, expectedCents, receivedCents, note |
| `review_items` | shiftId → Gründe (Prüfliste nach v1-Übernahme) |
| `legacy_errors` | nicht übernehmbare v1-Einträge (roh + Fehlercode) |
| `meta` | interne Schlüssel (z. B. Migrationsstatus) |

- Indizes auf Start, Job + Start, Auszahlung und Status. Dazu ein **Teil-Index** `shifts_one_running`, der höchstens eine laufende Schicht erlaubt.
- `PRAGMA foreign_keys = ON`.
- Die Datenbankdatei heißt `chronos.sqlite`. Sie wird mit `shareAcrossIsolates: true` geöffnet, damit Benachrichtigungs-Aktionen im Hintergrund dieselben Daten sehen.
- **Einstellungen** liegen in `SharedPreferencesWithCache`. Standardwerte: Sprache System, Design System, kein Monatsziel, Erinnerung nach 10 h.

### 5.4 Rechenregeln

- **Verdienst:** `(gearbeitete ms × Cent/h + 1.800.000) ÷ 3.600.000`, ganzzahlig und half-up.
- **Gearbeitet** = Ende − Start − Pause, nie negativ. Eine laufende Schicht wird aus Startzeit und Uhrzeit berechnet, es wird nichts hochgezählt.
- **„Verdient“** ist Lohn **ohne** Trinkgeld. **„Offen“** = Lohn aller unbezahlten, abgeschlossenen, nicht gelöschten Schichten plus die laufende Schicht live.
- **Tageszuordnung:** Eine Schicht gehört zum lokalen Tag ihres Starts. Wochen beginnen am Montag.
- **Rundung** nur beim Beenden einer Timer-Schicht, auf den nächsten 5- bzw. 15-Minuten-Wert. Die exakte Hälfte rundet auf, und die Rundung ist auch an Umstellungstagen sicher. Manuelle Schichten werden nie gerundet.
- **Lohn:** Für eine neue Schicht gilt der Lohn des Jobs zum Datum. Eine Lohnänderung gilt „ab Datum“. Mit „neu berechnen“ werden nur unbezahlte Schichten dieses Jobs ab dem Datum angepasst.
- **Startzeit nach hinten verschoben:** Die gespeicherte Pause wird auf die verbleibende Zeit begrenzt. Siehe [[#9. Offene Punkte & bekannte Einschränkungen]].

### 5.5 Hintergrund-Konzept („null Code im Hintergrund“)

- Die einzige Wahrheit sind die Zeitstempel in der Datenbank.
- `LiveTicker` tickt **nur bei sichtbarer App** und baut nur die Zahlen neu.
- Die Benachrichtigung wird einmal pro Zustandswechsel gepostet, die Stoppuhr zeichnet Android selbst.
- Die Erinnerung ist ungenau geplant (`inexactAllowWhileIdle`), ohne Exact-Alarm-Berechtigung. Nach einem Neustart plant der Boot-Receiver des Plugins sie neu ein.
- Es gibt **keinen Foreground-Service**, keinen WorkManager und keinen periodischen Timer.
- Einzige Ausnahme: ein einmaliger Timer bis Mitternacht, nur solange die App sichtbar ist.

### 5.6 v1-Datenübernahme (`lib/data/legacy/`)

- Die alten Schlüssel `work_entries`, `app_settings` und `active_session` werden über die **alte** shared_preferences-API gelesen.
- Die Rohdaten werden als `legacy_backup_v1.json` im App-Dokumentenordner gesichert. Die alten Schlüssel werden **nie gelöscht**.
- **Eine Transaktion:**
  - Job „Mein Job“ mit dem alten Lohn (ab dem ältesten Eintrag) und **15-min-Rundung**, wie bisher, mit korrigierter Schwelle.
  - Jeder Eintrag einzeln: lokale Zeit → UTC + Offsets, „bezahlt“ übernommen.
  - Eine laufende Sitzung wird zur laufenden Schicht.
  - Sprache übernehmen, Design → System.
- **Prüfliste** (`review_items`): ≥ 16 h, genau 23/24 h, gleiche Zeiten, doppelte IDs, Überschneidungen, Zeitumstellungstage. Nichts wird automatisch geändert.
- **Nicht lesbare Einträge** kommen in `legacy_errors` und lassen sich teilen.
- **Idempotent:** Die Übernahme wird bei jedem Start geprüft (Markierung in `meta`). „Alle Daten löschen“ behält die Markierung, damit nichts erneut importiert wird.

### 5.7 Backup, Export, Löschen

- **Backup:**
  - JSON mit `formatVersion`, `schemaVersion`, `appVersion`, `exportedAt`, Einstellungen, Jobs, Löhnen, Schichten und Auszahlungen.
  - **Wiederherstellen:** „Ersetzen“ oder „Zusammenführen“ (per UUID). Neuere Formate werden abgelehnt.
- **Export:**
  - **PDF-Stundenzettel** (A4): Datum, Start, Ende, Pause, Stunden, Lohn, Betrag, Summen, Unterschriftszeile.
  - **CSV:** Auf Deutsch Excel-DE (`;`, Dezimalkomma, BOM). Auf Englisch Komma und Punkt.
  - Verschickt wird über das Teilen-Menü.
- **Alle Daten löschen:** Vorher wird automatisch eine Sicherung im Dokumentenordner angelegt, mit Rückgängig. Gelöschte Schichten werden beim nächsten App-Start endgültig entfernt, wenn sie älter als 1 Minute sind.

### 5.8 Lokalisierung

- **496 Schlüssel.** `app_en.arb` ist die Vorlage mit Beschreibungen, `app_de.arb` in Du-Form.
- Präfixe pro Bereich: today, export, insights, jobs, settings, shifts, privacy, editor, review, data, common, payout, notification, wageCheck, onboarding, about, recovery …
- `nullable-getter: false`: Fehlt ein Schlüssel, scheitert schon das Kompilieren.
- **Sprachauflösung:** Die Sprache folgt dem System, die Region bleibt erhalten (de_AT zeigt z. B. „Jänner“-Formate). Android 13+ bietet über `locales_config.xml` in den Systemeinstellungen eine Sprachauswahl pro App an. Sie wirkt aber nur, solange in der App „System“ eingestellt ist; die App-Einstellung wird nicht in die Systemeinstellung zurückgeschrieben.

### 5.9 Designsystem „Navy Night / Sky Day“

- Material 3 mit echten Komponenten (NavigationBar/Rail, FilledButton, Card, ListTile, SegmentedButton, Sheets).
- **Farben, Kontrast geprüft (alle Textpaare ≥ 4,5 : 1, als Test):**
  - Hell: Hintergrund `#F6F9FC`, Primärfarbe Navy `#14548C`, laufende Schicht in Himmelblau `#87CEEB`.
  - Dunkel: navy-getönte Flächen ab `#0B1320`, Primärfarbe `#9CCFF5`.
  - Bernstein bedeutet „offen“, Grün „bezahlt“, Rot nur Destruktives. Dazu 6 Job-Farben.
- **Schrift:** Systemschrift (Roboto) mit **tabellarischen Ziffern** für alle Zahlen. Feste Schriftrollen statt fester Größen im Code.
- **Bewegung:** nur drei Animationen auf „Heute“ (Ziffern, Zustandswechsel, Button). Nichts schrumpft beim Drücken, „Animationen entfernen“ wird respektiert.
- **Barrierefreiheit:**
  - 200 % Schrift ohne Überlauf, Trefferflächen ≥ 48 dp.
  - TalkBack-Texte und Wisch-Aktionen als Bedienhilfe-Aktionen.
  - Status nie nur über Farbe.
  - Haptik bei Start, Beenden, Speichern, Auszahlung, Wisch-Aktionen und den ±-Knöpfen.

### 5.10 Android-Projekt

- **Build-Dateien:** auf **Kotlin-DSL** umgestellt (`settings.gradle.kts`, `build.gradle.kts`, `app/build.gradle.kts`), genau wie in der Flutter-3.47.5-Vorlage.
  - Versionen: Gradle 9.3.1, AGP 9.1.0, Kotlin 2.4.0.
  - In `gradle.properties` stehen `android.newDsl=false` und `android.builtInKotlin=false` (Kompatibilität mit noch nicht migrierten Plugins).
- **SDK, NDK und Version** kommen von Flutter: compileSdk/targetSdk 36, minSdk 24, NDK. versionCode und versionName kommen aus der `pubspec`.
- **Java/Kotlin 17**, Core-Library-Desugaring (`desugar_jdk_libs 2.1.4`). `proguard-rules.pro` für R8, `res/raw/keep.xml` schützt das Benachrichtigungs-Icon.
- **Signieren:** Release wird mit `android/key.properties` signiert (Format wie bisher). **Fehlt die Datei**, wird der Release-Build debug-signiert und Gradle warnt.
- **Manifest:**
  - Berechtigungen: `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`.
  - Die drei Receiver von flutter_local_notifications.
  - `enableOnBackInvokedCallback`, `localeConfig`, `allowBackup` mit `data_extraction_rules.xml` / `backup_rules.xml` (Datenbank inkl. -wal/-shm und Einstellungen).
  - Kein `INTERNET` im Release, keine Exact-Alarm- und keine Foreground-Service-Berechtigung, kein `package=`.
- **Icons:**
  - Neu skalierte Launcher-Icons; die 2048-px-PNGs à 2,2 MB sind weg.
  - Adaptives Icon mit **Navy-Hintergrund** `#001F3F` und **Monochrom-Ebene** (Android 13+).
  - Vektor-Icon `ic_stat_chronos` (Sanduhr) für die Benachrichtigung.
  - Erzeugt werden sie mit `android/tools/generate_icons.py`.
- **Splash:** hell `#F6F9FC` / dunkel `#0B1320`, Android-12+-SplashScreen-Attribute.
- **Debug-/Profile-Manifeste** mit INTERNET für Hot Reload und DevTools. `GeneratedPluginRegistrant.java` ist nicht mehr eingecheckt.
- **`privacy.html`:** neu, Deutsch und Englisch. Inhalt: Daten bleiben auf dem Gerät; Ausnahmen sind Auto Backup ins eigene Google-Konto und vom Nutzer ausgelöstes Teilen; keine Werbung, keine Analyse, kein Tracking.

---

## 6. Qualitätssicherung

### Tests (Stand `8f75a0b`)

| Bereich | Dateien | Inhalt |
|---|---|---|
| `test/core` | 5 | LocalDate, Zeit, Geld (inkl. Überlauf), Formatierer/Parser DE+EN (z. B. „0815“, „12,50“) |
| `test/domain` | 10 | Lohn, Rundung, Beenden, Validierung, Statistik, Zusammenfassungen, Auszahlungen, Prüfliste, Modelle |
| `test/data` | 12 | Datenbank-Constraints, Repositories, v1-Migration mit realistischen Fixtures (Nachtschicht, Umstellungstage, gemischte/doppelte IDs, 1250 €/h, 23-h-Eintrag, kaputte Einträge, laufende Sitzung), Backup-Round-Trip, Löschen + Rückgängig, CSV/PDF |
| `test/app` | 19 | Provider/Controller, Startablauf, Benachrichtigungs-Zuordnung, Hintergrund-Aktionen, Lebenszyklus (Mitternacht, kein Timer im Hintergrund), Sprache/Theme |
| `test/features` | 16 | Alle Bildschirme: Verhalten, **Layout-Matrix** (6 Größen × Hell/Dunkel × DE/EN × Schrift 100 %/200 % ohne Überlauf), Barrierefreiheits-Richtlinien |
| `test/widgets` | 6 | RollingAmount, LiveTicker, Geld-/Zeitfelder, Dialoge, Bausteine |
| `test/platform` | 3 | Benachrichtigungen (gemockter Plugin-Kanal), Teilen, App-Info |
| `test/acceptance` | 2 | **Kompletter Ablauf**: Installation → Onboarding „12,50“ → Start → Pause → Beenden mit Trinkgeld → Schichten → bezahlt + Rückgängig → Auszahlung → Übersicht → CSV-Export → Englisch → Dunkel; dazu Spezifikations- und v1-Bug-Checks |
| `test/screenshots` | 1 | Screenshot-Generator (nur mit `CHRONOS_SCREENSHOTS=1`) |
| `test/support`, `test/fixtures` | | Test-Harness (In-Memory-DB, Test-Uhr, Fakes für Benachrichtigung/Teilen) |

**Ausführen:**
```bash
flutter pub get
flutter analyze
flutter test
TZ=Europe/Berlin flutter test          # inkl. Zeitumstellungs-Tests
# Screenshots neu erzeugen:
CHRONOS_SCREENSHOTS=1 TZ=Europe/Berlin flutter test --update-goldens test/screenshots
# Nach Schema-Änderungen (drift):
dart run build_runner build -d
# Nach ARB-Änderungen:
flutter gen-l10n
```

### Reviews & Ergebnisse

1. **Fehlersuche** (adversariales Review von Geld, Zeit, Migration, Backup, Benachrichtigungen):
   - **Hoch:** Der Editor baute beim Speichern Start und Ende aus den sichtbaren Feldern neu. Unveränderte Schichten über 24 h wurden dadurch gekürzt, Timer-Sekunden gingen verloren, und eine Endzeit in der doppelten Stunde der Zeitumstellung verschob sich (v1-Bug D11 kam zurück). Behoben mit `ShiftDraft.fromLocalEdit`.
   - **Gering:** Beim ersten Start zählte die Startzeit erst ab der Antwort auf die Berechtigungsfrage. Behoben.
2. **Eigene Korrekturen:**
   - „Heute“ wechselt um Mitternacht bei sichtbarer App.
   - Beim Verschieben des Starts hinter eine Pause wird die Pause begrenzt.
3. **Abnahme gegen `SPEC_2_0.md`:** Alle Punkte sind umgesetzt, keine Lücke. 12 Punkte hatten noch keinen eigenen Test und haben jetzt einen. Der Ende-zu-Ende-Ablauf ist ergänzt.
4. **Screenshots:** Optisch geprüft. Der vermeintliche schwarze Rand am „+ Schicht“-Button war ein Artefakt der Testumgebung, weil Flutter in Tests Schatten durch einen schwarzen Rand ersetzt (`debugDisableShadows`).

---

## 7. Dateien & Dokumente im Repo

| Datei | Inhalt |
|---|---|
| `README.md` | Überblick, Funktionen, Screenshots, Bauen, Architektur, Tests (Deutsch) |
| `CLAUDE.md` | **Feste Regeln für die Weiterentwicklung** (auch für KI-Assistenten) |
| `docs/SPEC_2_0.md` | Verbindlicher Funktionsumfang 2.0 |
| `docs/ARCHITEKTUR.md` | Schichten, Datenmodell, Rechenregeln, Provider/Controller mit Beispielen, App-Start & Benachrichtigungen |
| `docs/ANDROID_BUILD.md` | Bauen, Signieren, versionCode-Regeln, 16-KB-Prüfung, Upgrade-Test v1→v2, Auto-Backup-Test, Icons, **Prüfliste für den ersten echten Build** |
| `docs/UMBAUPLAN.md` | Analyse-Befund und ursprünglicher Plan (mit Stand-Vermerk) |
| `docs/UEBERGABE_CHRONOS_2.0.md` | Dieses Dokument |
| `docs/research/*.md` | Rohdaten der Analyse (englisch) + Reproduktions-Tests gegen v1 |
| `docs/screenshots/*.png` | 10 Screenshots (Handy hell/dunkel, Querformat, Tablet, Sheets, Einstellungen, Onboarding) |
| `privacy.html` | Datenschutzerklärung DE + EN |
| `android/tools/generate_icons.py` | Icon-Generator |
| `assets/fonts/Roboto-*.ttf` | Schrift für den PDF-Export (Apache-2.0-Lizenz liegt bei) |

---

## 8. Entscheidungen & Abweichungen

| Thema | Entscheidung |
|---|---|
| Umfang | Vereinfacht: keine Länderregeln, keine gesetzlichen Pausen, keine Zuschläge; Monatsziel/-grenze frei einstellbar |
| v1.0.1 | Entfällt, direkt 2.0 |
| Neuaufbau | Im selben Repo, gleiche App-ID und gleicher Upload-Key; v1-Daten werden übernommen |
| State-Management | Riverpod 3, handgeschrieben (kein Codegen) |
| Datenbank | drift/SQLite (Isar/Hive gelten als verwaist) |
| Navigation | Eigenes adaptives Gerüst statt go_router (für 3 Tabs ausreichend) |
| Schrift | Systemschrift statt mitgelieferter Schrift (App-Größe); Roboto nur im PDF |
| Rundung | Neue Jobs ohne Rundung; übernommener v1-Job behält 15 min |
| Pausen | Nur erfassen; kein automatischer Abzug |
| Sortierung | Neueste Schicht oben (statt unten wie in der ursprünglichen Spezifikation) |
| Hauptzahl „Heute“ | Wie in deiner ursprünglichen Spezifikation: „Heute verdient“, ohne Arbeit heute „Offen“ |
| Lange drücken | Menü wie in der Spezifikation; Tippen öffnet den Editor |
| Sprache/Design | SegmentedButton statt Schalter (drei Zustände inkl. System) |
| Stopp-Bestätigung | Das „Schicht beenden“-Blatt ist die Bestätigung |
| Auto Backup | An, mit expliziten Regeln; Datenschutzerklärung angepasst |
| Erinnerung | In UTC geplant (umgeht einen 1-h-Fehler des Plugins bei der Herbst-Zeitumstellung) |
| **Abweichung 1** | Tablet ≥ 840 dp: „Heute“ zeigt zusätzlich eine Spalte „Heutige Schichten“ und wird breiter als die vorgesehenen 840 dp |
| **Abweichung 2** | CSV-Format folgt der App-Sprache (Englisch: Komma/Punkt statt Excel-DE) |
| **Abweichung 3** | Spezifikation widersprach sich bei Ende = Start → umgesetzt als Fehler; „Endet am nächsten Tag“ nur automatisch bei Ende < Start |
| **Abweichung 4** | Gelöschte Schichten werden beim nächsten App-Start endgültig entfernt (wenn älter als 1 min) |

**Bitte bestätigen bzw. beachten:**
- **Signing:** Die Release-Signatur gibt es nur noch, wenn `android/key.properties` existiert. Fehlt die Datei, wird debug-signiert. Der Key selbst und das Format der Datei sind unverändert.
- **versionCode:** 2.0.0 hat versionCode 2. Falls je ein Build mit versionCode 2 hochgeladen wurde, muss die pubspec auf `2.0.0+3`.
- **Mindest-Android-Version:** v2 braucht Android 7.0 (API 24), v1 lief laut Lockfile ab Android 5. In der Play Console prüfen, ob Tester betroffen sind.

---

## 9. Offene Punkte & bekannte Einschränkungen

> [!warning] Nicht verifiziert
> - **Der Android-Build lief noch nie.** In der Cloud war `dl.google.com` gesperrt, es gab also kein Android-SDK und keinen Gradle-Lauf. Alles wurde gegen die offizielle Flutter-3.47.5-Vorlage und die Plugin-Dokumentation abgeglichen, aber nicht gebaut.
> - Nicht auf einem echten Gerät getestet: Benachrichtigung samt Aktionen bei geschlossener App, Erinnerung nach einem Neustart, Teilen-Menü, Datei-Auswahl, PDF-Schrift, Auto Backup und R8-Release.
> - **Risiko bei AGP 9:** einzelne Plugins (`android_file_picker` bringt eigenes AGP 8.5.2 mit; `package_info_plus`, `share_plus`, `jni`). Die Rückfallebene ist in `docs/ANDROID_BUILD.md` beschrieben: AGP 8.11.1 / Gradle 8.14.3 / Kotlin 2.2.20.

**Bekannte Kleinigkeiten (nicht behoben):**
1. **Benachrichtigung antippen schließt einen offenen Editor**, ohne nach ungespeicherten Änderungen zu fragen. Die Shell schließt alle Routen über sich.
2. **Startzeit hinter eine schon gemachte Pause verschieben:** Gespeichert wird nur die Summe der Pausen, nicht wann sie stattfanden. Die Pause wird auf die verbleibende Zeit begrenzt, die Arbeitszeit kann aber zu knapp sein. Eine saubere Lösung braucht einzelne Pausen-Zeiträume, also eine Schema-Änderung.
3. **Sehr kurze Schicht mit 15-min-Rundung und Pause:** Start und Ende runden auf denselben Wert, dann blockiert jede Pause über 0 das Speichern („Pause zu lang“), bis man sie auf 0 setzt.
4. Das Beenden-Blatt kann kein Ende setzen, das mehr als etwa einen Tag zurückliegt. Dafür ist der Editor da.
5. **Kosmetik:** Bei Schichten über 24 h zeigt der Untertitel von „Endet am nächsten Tag“ Start + 1 Tag.
6. **Theoretisch:** Zwei Rückgängig-Snackbars (bezahlt und Auszahlung) gleichzeitig in verschiedenen Tabs können einen Fremdschlüssel-Fehler auslösen. Praktisch kaum erreichbar.
7. **Doppelte Logik:** Die Job-Farbe wird an drei Stellen aufgelöst (Heute, Schichten, Einstellungen); ein gemeinsamer Helfer wäre sauberer.
8. `flutter_timezone` ist deklariert, wird aber nicht benutzt und kann aus `pubspec.yaml` entfernt werden.
9. Der Tag `v1.0.0` existiert nur in der Cloud-Sitzung, nicht auf GitHub. Bei Bedarf lokal setzen: `git tag v1.0.0 9a52779 && git push origin v1.0.0`.
10. Der Branch ist noch nicht in `master` gemergt; es gibt keinen Pull Request.

---

## 10. Nächste Schritte

### Auf dem eigenen PC (`D:\Programmierung\Aktiv\Chronos`)
- [ ] `git fetch` und Branch `claude/optimistic-brown-56sgj7` auschecken
- [ ] Flutter auf **3.47.5** aktualisieren (`flutter upgrade` bzw. FVM), JDK 17 oder neuer
- [ ] `flutter pub get` → `flutter analyze` → `flutter test` (sollte grün sein)
- [ ] `android/key.properties` + `chronos-upload.jks` an die gewohnte Stelle legen (nicht ins Repo)
- [ ] `flutter build appbundle --release` und `flutter build apk --debug`. Bei Gradle/AGP-Problemen: Rückfallebene aus `docs/ANDROID_BUILD.md`
- [ ] Prüfliste „Erster Build auf einem echten Rechner“ in `docs/ANDROID_BUILD.md` abarbeiten:
  - Merged Manifest
  - Icons und Splash hell/dunkel
  - R8-Release
  - Benachrichtigung samt Aktionen bei geschlossener App
  - Erinnerung nach `adb reboot`
  - Sprachauswahl pro App
  - Zurück-Geste
  - Auto Backup mit `bmgr`
  - 16-KB-Prüfung, Download-Größe unter 15 MB
- [ ] **Upgrade-Test v1 → v2:** v1.0.0 mit Testdaten installieren (auch Komma-Lohn, Nachtschicht, laufende Schicht), dann v2 drüber installieren. Alles muss übernommen werden und die Prüfliste erscheinen. Beide Wege testen: lokal gleich signiert **und** über den Play-Test-Track.
- [ ] App einmal auf dem eigenen Handy durchspielen (Hochformat, Querformat, Dunkelmodus, große Schrift)
- [ ] Optional: `flutter_timezone` aus der pubspec entfernen
- [ ] Branch in `master` mergen bzw. Pull Request anlegen

### Play Store
- [ ] `privacy.html` unter einer festen öffentlichen URL hosten (z. B. GitHub Pages) und in der Play Console eintragen
- [ ] Datensicherheits-Formular: „keine Daten erhoben/geteilt“ (Auto Backup ins eigene Google-Konto gilt nicht als Erhebung, steht aber in der Erklärung)
- [ ] versionCode prüfen (2 bzw. 3), AAB in den Test-Track hochladen
- [ ] **Geschlossenen Test** starten: mindestens 12 Tester, **14 Tage ununterbrochen** angemeldet (gilt für private Konten, die nach dem 13.11.2023 erstellt wurden; der interne Test zählt nicht). Tester bitten, die App nicht zu deinstallieren. Siehe [[Chronos Betatest]]
- [ ] Store-Eintrag DE/EN, Screenshots für Handy und 7"/10"-Tablet (Vorlagen in `docs/screenshots/`)
- [ ] Danach Produktionszugang beantragen (Fragebogen)

### Später (nicht in 2.0, bewusst zurückgestellt)
- Homescreen-Widget, App-Shortcuts, Schnelleinstellungs-Kachel, NFC
- Schichtvorlagen und Schichtplanung mit Kalender
- Zuschläge Nacht/Sonntag/Feiertag inklusive Feiertagen
- Pausen als einzelne Zeiträume (löst offenen Punkt 2)
- Android-16-Live-Update (Chip in der Statusleiste), sobald flutter_local_notifications es unterstützt
- Umstieg auf `package:material_ui` (entkoppelte Material-Bibliothek) per `dart fix`, sobald fl_chart & Co. so weit sind
- Flutter 3.50 (erwartet im November 2026) bewusst einplanen

---

## 11. Hinweise für die Weiterarbeit

- **Vor jeder Änderung `CLAUDE.md` lesen.** Die Regeln dort verhindern, dass alte Fehlerklassen zurückkommen: Cent, UTC, keine Logik in Widgets, nichts im Hintergrund, alle Texte über ARB.
- **Kleine Schritte:** pro Änderung ein Commit oder PR mit Tests. Vor dem Push immer `flutter analyze` und `flutter test` laufen lassen, bei Zeitlogik auch mit `TZ=Europe/Berlin`.
- **Datenbank-Schema ändern** = `schemaVersion` erhöhen + Migration schreiben + Migrationstest. Nie das bestehende Schema stillschweigend ändern, sobald 2.0 bei Nutzern ist.
- **Neue Texte:** Schlüssel in `app_en.arb` (mit `@`-Beschreibung) **und** `app_de.arb`, dann `flutter gen-l10n`.
- **Zeit in Tests:** Immer die Test-Uhr (`package:clock`) verwenden, nie `DateTime.now()`.
- **Nie ohne Rückfrage ändern:** App-ID, Signing, Flutter-Version, Datenbank-Schema ohne Migration.
- **KI-Assistenten** neigen zu veralteten APIs. Hier gilt: Riverpod 3 (kein `StateNotifier`), flutter_local_notifications 22 (benannte Parameter), Flutter 3.47.
- **Kritischen Code selbst lesen:** Geld-Logik und Migrationen Zeile für Zeile, weil dort Fehler Daten kosten.
- `chronos-upload.jks` und `key.properties` doppelt sichern, nie ins Repo.

---

## Anhang: Vorschlag für die Projektnotiz [[Chronos]] im Vault

**Status-Zeile:** Chronos 2.0 umgesetzt (30.09.–01.10.2026, Cloud-Sitzung mit Claude Code). Der Code liegt im Branch `claude/optimistic-brown-56sgj7`. Der Android-Build auf dem PC steht noch aus, danach folgen der geschlossene Test und die Produktion.

**Features (neu):** Heute (Live-Betrag, Start/Pause/Beenden, Beenden-Blatt), Schichten (Monate, Wischen, Editor, Auszahlungen), Übersicht (Statistik, Diagramm, Monatsziel), Einstellungen (Jobs mit Lohnhistorie und Rundung, Erinnerung, PDF/CSV-Export, Backup, Hell/Dunkel/System, DE/EN), Benachrichtigung mit Stoppuhr und Aktionen, automatische v1-Datenübernahme.

**Tech-Stack (neu):** Flutter 3.47.5, Riverpod 3, drift (SQLite), flutter_local_notifications 22, fl_chart, pdf, share_plus, file_picker; Material 3 „Navy Night / Sky Day“; Android: AGP 9.1, Gradle 9.3.1, Kotlin 2.4, Ziel-API 36.

**Erledigte Bugs aus dem internen Test:** „Alles löschen“ übersetzt, Querformat, Dark/Light, Tablet, Lösch-Problem (Ursache: Doppeltipp auf Speichern).
