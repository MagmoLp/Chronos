# Chronos 2.0 – Befund & Umbauplan

> Stand: 30.09.2026 · Grundlage: Code-Audit, UX-Audit, Markt- und Technik-Recherche,
> Bug-Reproduktion mit echten Flutter-Tests (Flutter 3.47.5), adversariale Verifikation und Faktencheck.
> Die Rohdaten der Recherche liegen in [`docs/research/`](research/).

---

## 1. Kurzfassung

1. **Die App ist ein Prototyp mit solider Idee, aber ohne tragfähiges Fundament.** Logik steckt in Widgets, Geld wird als `double` gerechnet, Zeiten als lokale Strings ohne Zeitzone gespeichert, das ganze Protokoll liegt als ein JSON-String in `shared_preferences`, es gibt keinen einzigen Test.
2. **Sie baut mit aktuellem Flutter nicht mehr** (`intl ^0.19.0` und `CardTheme` → Compile-Fehler). Ohne Upgrade kann kein Update mehr in den Play Store, weil seit 31.08.2026 Ziel-API 36 Pflicht ist.
3. **Die meisten „Bugs“ sind Symptome weniger Grundursachen:** kein Theme-System (Dark/Light existiert gar nicht), kein responsives Layout, keine Trennung von Oberfläche und Logik, kein Lohn pro Eintrag, kein Lifecycle-Handling.
4. **Das Handy-Laggen hat eine klare Ursache:** Ein Dart-Timer feuert jede Sekunde – auch im Hintergrund – und baut den kompletten Startbildschirm neu auf (~270 Widgets pro Sekunde), dazu wird die Benachrichtigung alle 15 s neu gepostet (240×/Stunde). Nichts davon ist nötig.
5. **Funktional fehlt, was Catering-Jobber wirklich brauchen:** mehrere Jobs, Pausen, Lohnhistorie, Auszahlungen, Statistik, Export für den Arbeitgeber, Backup, Trinkgeld, Minijob-Grenze.

**Empfehlung:** Chronos 2.0 als **geordneter Neuaufbau im selben Repository** – gleiche App-ID `com.paulhuebner.chronos`, gleicher Upload-Key, und die Daten der bisherigen Tester werden beim ersten Start automatisch übernommen. Die alte Oberfläche wird **nicht** mehr geflickt (fast jede Datei müsste ohnehin ersetzt werden). Umsetzung in 4 Phasen, siehe [Abschnitt 5](#5-roadmap).

---

## 2. Befund

### 2.1 Build & Toolchain

| Problem | Beleg | Folge |
|---|---|---|
| `flutter pub get` schlägt fehl | `pubspec.yaml:14` `intl: ^0.19.0`, aktuelles `flutter_localizations` verlangt `^0.20.3` | Projekt lässt sich mit Flutter 3.47 nicht auflösen |
| Compile-Fehler | `lib/theme/app_theme.dart:61` `CardTheme` statt `CardThemeData` | Build bricht ab |
| Gradle / AGP / Kotlin veraltet | Gradle 8.9, AGP 8.7.0, Kotlin 2.1.0 | aktuelles Flutter verweigert den Build (Mindestversionen siehe Anhang) |
| Java 1.8, fest verdrahtetes NDK 27 | `android/app/build.gradle:36-46` | 16-KB-Page-Size-Pflicht, Plugin-Anforderungen (Java 17) |
| Ziel-API | erbt von Flutter ~3.24 | **seit 31.08.2026 muss jedes Update API 36 anpeilen** |
| `proguard-rules.pro` referenziert, fehlt; Signing unbedingt | `android/app/build.gradle:52-76` | frischer Clone/CI baut nicht |
| Launcher-Icon 2048×2048 px in allen 5 Dichten (~2,2 MB je Datei) | `android/app/src/main/res/mipmap-*` | aufgeblähte App, keine Monochrom-Ebene (Android 13+) |
| 22× veraltetes `withOpacity`, deaktivierte `const`-Lints, `flutter_lints` 4 | `analysis_options.yaml` | Probleme werden versteckt |

### 2.2 Bugs – verifiziert

Alle mit ✅ markierten Punkte wurden **mit echten Widget-/Unit-Tests reproduziert** (Flutter 3.47.5, Zeitzone Europe/Berlin).

**Datenintegrität & Geld (kritisch)**

| # | Bug | Beleg | Ursache |
|---|---|---|---|
| D1 ✅ | Eingabe „12,50“ wird zu **1250 €/h** gespeichert | `settings_screen.dart:384` | Eingabefilter lässt nur `.` zu, das Komma wird verschluckt; `replaceAll(',', '.')` ist toter Code |
| D2 ✅ | Lohnänderung berechnet **alle alten Einträge rückwirkend neu – auch bereits bezahlte** | `work_entry.dart:18-21` | Eintrag speichert keinen Lohn, es wird immer der aktuelle genommen |
| D3 ✅ | Ein einziger beschädigter gespeicherter Wert → App startet nur noch mit „Startup Error“, **ohne Ausweg** | `storage_service.dart:48,63,84`, `main.dart:46-57` | Kein try/catch pro Eintrag, keine Validierung, keine Wiederherstellung |
| D4 ✅ | Sitzung unter 15 min (nach Rundung) wird **nach** dem Stoppen verworfen → Zeit weg, kein Undo | `home_screen.dart:250-273` | `stop()` löscht die Sitzung, bevor die Mindestdauer geprüft wird |
| D5 ✅ | Rundung auf Viertelstunde falsch herum: 08:07 → 08:15; 14 echte Minuten → 0, 16 → 30 | `home_screen.dart:198-206` | Schwelle 7 statt 7,5 Minuten |
| D6 ✅ | **Zeitumstellung:** gerundete Zeiten ±1 h daneben; Nachtschicht über die Umstellung 1 h zu kurz; laufende Sitzung nach Neustart 1 h versetzt | `home_screen.dart:204`, `work_log_screen.dart:552,751`, `storage_service.dart:76` | Rechnen mit `Duration(days: 1)` auf lokaler Zeit, Speichern ohne Zeitzonen-Offset. **Nächste Umstellung: 25.10.2026** |
| D7 ✅ | Ende vor Start (Tippfehler) → still gespeicherte **23-h-Schicht**; Ende = Start → 24 h | `work_log_screen.dart:551-553, 750-752` | Stillschweigende „über Nacht“-Annahme, Text `endAfterStart` existiert, wird nie benutzt |
| D8 ✅ | Summen stimmen nicht: 11,5 % aller Lohn/Dauer-Kombinationen zeigen einen falschen Cent; drei Einträge à 92,52 € ergeben „277,55 €“ | `work_entry.dart:18-20`, `work_entries_provider.dart:12-14` | Geld als `double`, Runden erst bei der Anzeige |
| D9 | Doppeltipp auf „Speichern“ legt Eintrag doppelt an | `work_log_screen.dart:535-577` | kein Sperren während des Speicherns |
| D10 | Keine Überlappungsprüfung – dieselben Stunden können doppelt gezählt werden | `work_entries_provider.dart:24-27` | – |
| D11 | Vergessener Stopp → mehrtägige Einträge, keine Erinnerung; Bearbeiten kürzt >24-h-Einträge still | `timer_provider.dart:32-37`, `work_log_screen.dart:624-626` | – |

**Bekannte Bugs aus dem internen Test**

| # | Bug | Befund |
|---|---|---|
| K1 ✅ | „Alles löschen“ bleibt Deutsch | Der **ganze** Bereich „Datenverwaltung“ inkl. Dialog und Snackbar ist fest auf Deutsch (`settings_screen.dart:182-302`). Schlimmer: Auf Englisch lässt sich das Löschen **nur durch Eintippen des deutschen Wortes „Löschen“** bestätigen – „Delete“ bleibt deaktiviert. Auch die Benachrichtigung ist immer Deutsch. |
| K2 ✅ | Querformat: „BOTTOM OVERFLOWED BY 284 PIXELS“ | Startbildschirm ist eine nicht scrollbare Spalte mit ~500 dp fester Höhe. Gemessen 222–318 px Überlauf je nach Gerät. **START/STOP liegen dann unter der Navigationsleiste und sind nicht mehr drückbar.** Bei großer Systemschrift passiert das auch im Hochformat auf kleinen Handys; bei 200 % Schrift ist der Protokoll-Tab nicht mehr erreichbar. Auch Hinzufügen-/Bearbeiten-Dialog und Lösch-Dialog laufen über. |
| K3 ✅ | Dark/Light-Darstellungsproblem | **Light Mode wurde nie implementiert.** `MaterialApp` bekommt nur ein dunkles Theme, es gibt keinen Umschalter, die Einstellung wird nirgends gelesen, und >100 Farben sind fest im Code verdrahtet. Ein Umschalten ändert nichts; ein halbherziger Fix ergäbe eine Mischung aus hell und dunkel. |
| K4 | Tablet ungetestet | Es gibt **keinerlei** adaptiven Layout-Code. Auf Tablets: gestrecktes Handy-Layout, winzige Inseln in großer Fläche. Android 16 ignoriert auf Tablets ab API 36 die Orientierungssperre – „nur Hochformat“ ist also keine Lösung. |
| K5 | Löschen zeigt Änderung erst nach Neustart | *Wird gerade reproduziert – siehe [2.2a](#22a-löschen-braucht-neustart).* |

#### 2.2a Löschen braucht Neustart

_Platzhalter – Ergebnis der Verifikation folgt._

**Weitere Fehler (Auswahl)**

- Beim ersten Start ist die App **immer Deutsch**, egal welche Gerätesprache (`app_settings.dart:11`).
- Die Benachrichtigungs-Berechtigung wird **vor dem ersten Bild** abgefragt; die App bleibt schwarz, bis man antwortet (`main.dart:27`, `notification_service.dart:24-28`).
- Lohnänderung auf dem Protokoll-Tab erreicht die Benachrichtigung nicht (Lohn wird nur im `build()` des Startbildschirms gesetzt, `home_screen.dart:31`).
- Nach dem Neustart zeigt der Zähler eine Sekunde lang `00:00:00 / 0,00 €` und rollt dann alle Ziffern durch (`timer_provider.dart:25-30`).
- Zahlenformate uneinheitlich: Startseite „502,50€“, Protokoll „120.00 €“, Benachrichtigung „0.00 €“; Zeitauswahl auf Englisch mit AM/PM, Liste mit 24 h.
- Benachrichtigungs-Icon ist das bunte Launcher-Icon → weißer Klecks in der Statusleiste.
- Datumsauswahl hart auf 2020–2030 begrenzt (ab 2031 Absturzgefahr), Zukunftsdaten erlaubt.
- Zurück-Taste auf dem Protokoll-Tab beendet die App; Tabwechsel verliert die Scrollposition.
- `RobotoMono` wird verwendet, ist aber nicht eingebunden; die START/STOP-Beschriftung verliert die Theme-Schrift.
- Android Auto Backup ist implizit aktiv – die Datenschutzerklärung sagt aber, die Daten „verlassen [das Gerät] niemals“.

Vollständiger Katalog (41 Einträge aus dem Audit + Testergebnisse): [`docs/research/code-audit.md`](research/code-audit.md), [`docs/research/bug-reproduktion.md`](research/bug-reproduktion.md).

### 2.3 Warum das Handy laggt

Gemessen im Test (Timer läuft, 15 €/h):

| Zustand | Was passiert | Messwert |
|---|---|---|
| App sichtbar | `Timer.periodic(1 s)` → `notifyListeners()` → **ganzer Startbildschirm** baut neu | ~270 Widget-Builds pro Tick, ~420 Builds/s inkl. Ziffern-Animationen |
| Einstellungen liegen über dem Startbildschirm | Startbildschirm baut trotzdem weiter neu – unsichtbar | 262 Builds/s |
| App im Hintergrund | Timer läuft weiter, `notifyListeners` 60×/min; Benachrichtigung wird alle **15 s** neu gepostet (Kommentar sagt 30) | 240 Benachrichtigungs-Posts pro Stunde, jeder mit mehreren Plattform-Aufrufen + Neuzeichnen in SystemUI |
| Rückkehr in die App | Nachhol-Rebuild aller Ziffern | ~690 Builds/s für einen Moment |

Dazu: pro Ziffer ein `AnimatedSwitcher` mit `Opacity` (teure Offscreen-Ebene), pro Listenzeile ein eigener `AnimationController`, die komplette App baut bei jedem Tastendruck im Lohnfeld neu.

**Warum es auf manchen Handys schlimmer ist:** Auf Pixel-Geräten friert Android gecachte Apps nach ~10 s ein und versteckt das Problem. Viele Hersteller-ROMs tun das nicht – dort läuft der Timer unbegrenzt weiter, und die 240 Benachrichtigungs-Updates pro Stunde belasten SystemUI spürbar.

**Die Lösung ist nicht „optimieren“, sondern „weglassen“:** Die Arbeitszeit ist eine Funktion aus gespeicherter Startzeit und aktueller Uhrzeit. Dafür muss im Hintergrund **gar nichts** laufen (siehe [3.5](#35-hintergrund-konzept-null-code-im-hintergrund)).

### 2.4 Warum es sich „klobig“ anfühlt

- **Eigenbau statt Material-Komponenten:** Buttons, Navigationsleiste, Karten, Checkbox und Sprachauswahl sind selbstgebaute `GestureDetector`-Widgets – ohne Ripple, ohne Barrierefreiheit, ohne Fokus, teils mit 28-dp-Trefferflächen.
- **Alles federt:** Jedes Element skaliert beim Drücken (0,9–0,98), jeder Container animiert Farbe und Rahmen, die Navigationsleiste schwingt über (`easeOutBack`). Das wirkt gummiartig und träge.
- **Keine Hierarchie:** Drei riesige Zahlen (56 px, 40 px, 52 px) in je einem umrandeten Kasten konkurrieren; im Leerlauf zeigt der Hauptbildschirm „0,00 €“, „00:00:00“ und einen ausgegrauten STOPP-Button.
- **Boxen in Boxen, Rahmen überall:** 1,5-px-Rahmen um jede Karte; bezahlt wird dreifach markiert (Checkbox, blaue Tönung, grünes Badge); in den Einstellungen Karte in Karte mit bis zu 132 dp Einrückung.
- **Uneinheitliche Maße:** 7 verschiedene Eckradien, 9 Schriftgrößen als Zahlen im Code, drei verschiedene Seitenabstände.
- **Farben:** generisches „Electric Blue auf #121212“ – weder das spezifizierte Navy/Anthrazit noch passend zum Icon. Weiß auf Grün (START) hat nur 2,3 : 1 Kontrast.
- **Umständliche Abläufe:** Endzeit korrigieren = Zeile tippen → Bearbeiten → Dialog → Endzeit → Uhr-Picker → OK → Speichern (6+ Schritte, Dialog auf Dialog).

### 2.5 Features, die nicht zu Ende gedacht sind

| Feature | Problem heute |
|---|---|
| Start/Stopp | Leere „Sind Sie sicher?“-Abfrage, danach stilles Runden und Verwerfen; keine Pause; vergessener Start/Stopp nicht korrigierbar |
| „Aktueller Verdienst“ | Laut eigener Spezifikation „heute verdient“, zeigt aber nur die laufende Sitzung (zweite Schicht am Tag beginnt bei 0) |
| Stundenlohn | Ein globaler Wert, speichert bei jedem Tastendruck, verändert die Vergangenheit |
| Bezahlt/Unbezahlt | Jede Zeile einzeln abhaken; kein Datum, kein Betrag, keine Abrechnung |
| Einträge bearbeiten | Nur Datum/Zeiten, Hinzufügen und Bearbeiten sind ~2×160 Zeilen duplizierter Code |
| Alles löschen | Deutsches Tippwort, kein Export vorher, nur „alles oder nichts“ |
| Rundung | Fest eingebaut, unsichtbar, nur für Timer-Einträge, Originalzeiten gehen verloren |

### 2.6 Warum die App zu wenig kann

Vergleich mit 10 Konkurrenz-Apps (Details: [`docs/research/recherche.md`](research/recherche.md)):

- **Was alle guten Apps haben, Chronos nicht:** mehrere Jobs mit eigenem Lohn, Pausen, Wochen-/Monatsstatistik, Export (PDF/CSV), Backup, Widget, Benachrichtigung mit Aktionen, Erinnerung bei vergessenem Ausstempeln.
- **Die häufigsten Beschwerden über Konkurrenten:** Datenverlust, Werbung, Abo-Zwang für Grundfunktionen (mehrere Jobs, Widget, Export), Konto-Pflicht, verwirrende Bedienung.
- **Die Lücke, die Chronos füllen kann:** Eine **werbefreie, konto-freie, komplett offline** laufende App speziell für Stundenjobber in DE/AT – mit Live-Lohn, Pausenregeln nach ArbZG/AZG, Minijob-/Geringfügigkeitsgrenze, Trinkgeld und Stundenzettel-Export. Diese Kombination bietet derzeit niemand.

---

## 3. Zielbild Chronos 2.0

### 3.1 Produktprinzipien

1. **Eine Hauptzahl pro Bildschirm.** Was gerade zählt, steht groß; alles andere ist Nebeninfo.
2. **Vertrauenswürdig wie eine Banking-App.** Kein Cent-Fehler, keine verlorene Minute, jede Aktion rückgängig machbar.
3. **Null Arbeit im Hintergrund.** Akku-neutral, auch während einer 10-Stunden-Schicht.
4. **Schnell mit einer Hand**, auch in der Hektik beim Schichtwechsel – Hauptaktionen unten, große Trefferflächen, Haptik.
5. **Offline & privat.** Kein Konto, keine Werbung, keine Tracker.

### 3.2 Navigation & Bildschirme

Drei Ziele in der Navigationsleiste (Handy) bzw. Navigation Rail (Querformat, Tablet); Einstellungen bleiben das Zahnrad oben rechts (wie in der Spezifikation).

| Ziel | Beantwortet | Inhalt |
|---|---|---|
| **Heute** | „Was verdiene ich gerade, was schuldet man mir?“ | Start / Pause / Beenden, Live-Betrag, offener Betrag, diese Woche, letzte Schicht |
| **Schichten** | „Was habe ich gearbeitet, was ist bezahlt?“ | Monatsgruppierte Liste mit Summen, Filter (offen/bezahlt/Job), Wischen für bezahlt/löschen mit Rückgängig, Mehrfachauswahl, „+ Schicht“ |
| **Übersicht** | „Wie läuft es über die Zeit?“ | Woche/Monat/Jahr, Diagramm, Durchschnitts-Stundenlohn inkl. Trinkgeld, Minijob-Grenze, Auszahlungen, Export |

**Heute – Leerlauf und laufende Schicht (Handy)**

```
LEERLAUF                                    LÄUFT
+------------------------------------+     +------------------------------------+
| Heute, Mi 30. Sep           (Zahnr)|     | Heute, Mi 30. Sep           (Zahnr)|
| +--------------------------------+ |     | +--------------------------------+ |
| | Offen                          | |     | | ● Läuft · Catering Müller      | |
| | 1.234,56 €                     | |     | |            47,83 €             | |
| | 82,5 h · 11 Schichten          | |     | |  3:11:42   seit 08:02 (ändern) | |
| |          [Auszahlung erfassen >]| |     | |  15,00 €/h · Pause 0:30        | |
| +--------------------------------+ |     | +--------------------------------+ |
|  Job ( ● Catering Müller  v )      |     |  Offen inkl. Schicht   1.282,39 €  |
| +--------------------------------+ |     |  Heute gesamt             87,40 €  |
| |        ▶  Schicht starten      | |     | +--------------+ +---------------+ |
| +--------------------------------+ |     | |  ⏸  Pause    | |  ■  Beenden   | |
|  Früher angefangen? [-15] [Zeit]   |     | +--------------+ +---------------+ |
|  Diese Woche      18,5 h  256,75 € |     |                                    |
|  Letzte Schicht Mo 08:00–16:15   >  |     |                                    |
+------------------------------------+     +------------------------------------+
| [●Heute]   Schichten   Übersicht   |     | [●Heute]   Schichten   Übersicht   |
+------------------------------------+     +------------------------------------+
```

Im Querformat: Navigation links als Rail, Betrag links, Buttons rechts – nichts muss scrollen. Auf dem Tablet zusätzlich eine rechte Spalte mit den heutigen Schichten und einer Mini-Wochengrafik.

**Neue Abläufe (statt Dialog-Ketten)**

- **„Schicht beenden“-Blatt** statt leerer Sicherheitsabfrage: zeigt Rohzeit → gerundete Zeit, Pause, Dauer × Lohn = Betrag, optional Trinkgeld und Notiz; *Speichern / Weiterlaufen lassen / Verwerfen*. Wegwischen = Timer läuft weiter (sicher). Kurze Schichten werden nie still verworfen.
- **Ein Schicht-Editor** für Hinzufügen und Bearbeiten: Uhrzeiten per Tastatur („0815“) plus ±15-min-Knöpfe, Schalter „endet am nächsten Tag“, Live-Vorschau „7:45 h × 15,00 €/h = 116,25 €“, Warnung bei Überlappung und >16 h.
- **Auszahlung erfassen** statt 20 Häkchen: Zeitraum wählen → „23 Schichten · 172,5 h · erwartet 2.587,50 €“ → erhaltenen Betrag eintragen (Differenz wird angezeigt) → alle als bezahlt markiert, mit Datum.
- **Löschen/Bezahlt per Wischen mit Rückgängig** statt Blatt → Dialog → Snackbar.
- **Alles löschen** nur noch unter *Einstellungen → Daten*, lokalisiert, mit Anzahl („214 Schichten und 2 Jobs löschen?“), automatischer Sicherung vorher und Rückgängig.

Alle Wireframes (inkl. Querformat/Tablet, Übersicht, Jobs, Export, Onboarding, Widget): [`docs/research/ux-audit.md`](research/ux-audit.md).

### 3.3 Funktionsumfang

| Funktion | Nutzen | Release |
|---|---|---|
| Absturzsichere Schicht-Engine (Start/Pause/Fortsetzen/Beenden, „früher angefangen“) | Keine verlorene Minute, auch nach Neustart/Kill | 2.0 |
| Lohn pro Schicht gespeichert + Lohnhistorie | Vergangenheit bleibt stabil | 2.0 |
| Pausen (manuell + automatisch nach ArbZG §4 / AZG §11, abschaltbar) | Betrag passt zur Lohnabrechnung | 2.0 |
| Mehrere Jobs mit Farbe, Lohn, Rundungs- und Pausenregel | Catering-Jobber haben oft 2–3 Arbeitgeber | 2.0 |
| Auszahlungen / Abrechnungen | „Hat mich mein Chef richtig bezahlt?“ | 2.0 |
| Übersicht: Woche/Monat/Jahr, Diagramm, Ø-Stundenlohn | Langfristiger Nutzen | 2.0 |
| Export: Stundenzettel-PDF + CSV (Excel-tauglich, deutsches Format) | Für Arbeitgeber, Streitfälle, §17 MiLoG | 2.0 |
| Backup & Wiederherstellung (Datei) + Auto Backup | Handywechsel, Datensicherheit | 2.0 |
| Benachrichtigung mit nativer Stoppuhr und Aktionen [Pause] [Beenden] | Bedienung vom Sperrbildschirm, 0 % Akku | 2.0 |
| Erinnerung „Arbeitest du noch?“ nach X Stunden | Häufigster Datenfehler | 2.0 |
| Trinkgeld pro Schicht, effektiver Stundenlohn | Im Catering 20–50 % des Einkommens | 2.0 |
| Minijob- / Geringfügigkeitsgrenze mit Fortschrittsbalken | Echte Konsequenzen bei Überschreitung; bietet sonst niemand für DE/AT | 2.0 |
| Onboarding (Sprache/Theme automatisch, Lohn abfragen) | Kein versteckter 15-€-Standard | 2.0 |
| Homescreen-Widget (Start/Stopp, laufende Uhr) | Ein-Tipp-Stempeln; bei Konkurrenz meist Bezahlfunktion | 2.1 |
| Schichtvorlagen & Schichtplanung (Kalender) | Dienstpläne schnell eintragen, erwarteter Monatslohn | 2.1 |
| Zuschläge Nacht/Sonntag/Feiertag mit DE/AT-Vorlagen + Feiertagskalender | Häufigster Grund für Abweichung zur Abrechnung | 2.2 |
| Schnelleinstellungs-Kachel, App-Shortcuts, NFC-Tag | Noch schnelleres Stempeln | 2.2 |
| Android 16 Live Update (Status-Chip) | Glanzstück, sobald das Plugin es kann | später |
| Bewusst **nicht**: Geofencing, Cloud-Konto, Netto-Lohnsteuerrechner | Play-Richtlinien, Datenschutz, Haftung | – |

### 3.4 Designsystem „Navy Night / Sky Day“

- **Material 3** mit echten Komponenten (NavigationBar/Rail, FilledButton, Card, ListTile, SegmentedButton, Checkbox, Sheets) – die fünf `animated_*`-Eigenbauten entfallen, nur vier eigene Widgets bleiben (Rollzähler, Leerzustand, Datumsblock, Statistik-Karte).
- **Farben** (Kontrast geprüft, alle Textpaare ≥ 4,5 : 1): Dunkel = navy-getönte Flächen `#0B1320 … #233142` mit Himmelblau `#9CCFF5` als Primärfarbe; Hell = `#F6F9FC` mit Navy `#14548C`, Markenfarbe `#87CEEB` für die laufende Schicht. Bernstein für „offen“, Grün für „bezahlt“, Rot nur für Destruktives. Optional „Hintergrundfarben verwenden“ (Material You), standardmäßig aus.
- **Theme-Umschalter** System / Hell / Dunkel, Standard *System*. Statusleisten-Icons und Splash passen sich an.
- **Typografie:** eine gebündelte Schrift (Roboto Flex, offline), **tabellarische Ziffern** für alle Zahlen – der Zähler zittert nicht mehr. Feste Rollen statt Zahlen im Code.
- **Form & Abstand:** 7 Radius-Stufen mit fester Zuordnung, 4-dp-Raster, 16 dp Rand (Handy) / 24 dp (Tablet), Trefferflächen ≥ 48 dp.
- **Bewegung – nur drei Animationen auf „Heute“:** (1) Cent-Ziffern rollen von oben herein (wie in der Spezifikation), nur wenn sich eine Ziffer ändert; (2) einmaliger Übergang Leerlauf ↔ läuft; (3) Start-Button morpht zur Beenden-Form. Kein Skalieren beim Drücken, keine Dauer-Animationen, „Animationen entfernen“ des Systems wird respektiert.
- **Barrierefreiheit:** 200 % Schriftgröße ohne Überlauf, TalkBack-Beschriftungen, Wisch-Aktionen auch als Bedienhilfe-Aktionen, Status nie nur über Farbe.
- **Haptik** bei Start, Beenden, Bezahlt und Löschen.
- **Neues Icon:** vereinfachtes Sanduhr-+-€-Zeichen auf Navy `#001F3F`, mit Monochrom-Ebene und eigenem Benachrichtigungs-Icon.

Vollständige Farbtabelle, Typo-Skala, Komponenten-Inventar und Barrierefreiheits-Checkliste: [`docs/research/ux-audit.md`](research/ux-audit.md).

### 3.5 Hintergrund-Konzept: null Code im Hintergrund

| Baustein | Umsetzung |
|---|---|
| Wahrheit | Start-, Pausen- und Endzeit werden in der Datenbank (UTC) gespeichert. Arbeitszeit und Betrag werden **berechnet**, nicht hochgezählt. Kill, Neustart, Zeitumstellung – egal. |
| Anzeige | Ein kleines `LiveTicker`-Widget tickt **nur, solange die App sichtbar ist**, und baut nur die Zahl neu – nicht den Bildschirm. Der Betrag aktualisiert sich genau dann, wenn der nächste Cent verdient ist (bei 15 €/h alle 2,4 s). |
| Benachrichtigung | Wird **einmal pro Zustandswechsel** gepostet; Android zeichnet die laufende Uhr selbst (`usesChronometer`). Keine Updates im Takt. |
| Aktionen | [Pause] läuft kurz im Hintergrund-Isolat, [Beenden] öffnet das „Schicht beenden“-Blatt. |
| Erinnerungen | Ungenaue geplante Benachrichtigungen – keine Exact-Alarm-Berechtigung. |
| Widget | Native `<Chronometer>` im Widget, Update nur bei Zustandswechsel. |
| Foreground-Service | **Keiner.** Nicht nötig, Play-Deklaration aufwendig, hält den Prozess wach. |

**Zielwerte:** 0 Frames/s im Leerlauf, ≤ 1 Rebuild der Zahl pro Sekunde bei sichtbarer App, **0 Dart-Timer im Hintergrund**, 1 Benachrichtigungs-Post pro Zustandswechsel.

---

## 4. Technische Architektur

### 4.1 Stack

| Bereich | Heute | Neu | Warum |
|---|---|---|---|
| Flutter | ~3.24 (2024) | **3.47.5** stable, Dart 3.13 | Build, API 36, 16 KB, Edge-to-Edge |
| State | Provider | **Riverpod 3** (`flutter_riverpod`) | gleiches Denkmodell wie Provider, aber ohne `BuildContext` nutzbar (Benachrichtigung, Widget), testbar, pausiert unsichtbare Listener |
| Speicher | 1 JSON-String in shared_preferences | **drift** (SQLite) | Tabellen, Migrationen mit Tests, reaktive Abfragen, Summen per SQL; Isar/Hive sind verwaist |
| Einstellungen | shared_preferences (legacy) | `SharedPreferencesWithCache` | synchron beim Start lesbar |
| Navigation | AnimatedSwitcher | **go_router** mit `StatefulShellRoute` | Tabs behalten Zustand, Deep Links aus Benachrichtigung/Widget, Predictive Back |
| Zeit | `DateTime.now()` überall | `package:clock` | Tests mit eingefrorener Zeit |
| Geld | `double` | `int` Cent + eine dokumentierte Rundungsregel | kein Cent-Fehler |
| Benachrichtigung | f_l_n 18 | **flutter_local_notifications 22** | Stoppuhr, Aktionen, Berechtigung im Kontext |
| Export | – | `pdf` + `printing`, `csv`, `share_plus`, `file_picker` | Stundenzettel, Backup ohne Speicher-Berechtigung |
| Diagramme | – | `fl_chart` | Übersicht |
| Widget | – | `home_widget` + nativer Kotlin-Provider | Phase 3 |
| Lints | flutter_lints 4, const-Regeln aus | flutter_lints 6 + Zusatzregeln + `riverpod_lint` | Fehler früh sehen |

Genaue Versionen und Begründungen: [`docs/research/recherche.md`](research/recherche.md).

### 4.2 Projektstruktur

```
lib/
  main.dart                 runApp(ProviderScope(child: ChronosApp()))  – sofort, ohne await
  app/                      router, theme (color_schemes, ThemeExtension), lifecycle
  core/                     clock, money (Cents + Formatierung), time, result
  domain/                   reines Dart, 100 % getestet:
                            pay_engine, rounding, break_policy, validation,
                            (später surcharge_engine, holidays_de_at, minijob_rules)
  data/                     drift-Datenbank, Tabellen, DAOs, Repositories, legacy_migration
  platform/                 notifications, reminders, home widget
  features/                 today/ shifts/ insights/ payouts/ export/ settings/ onboarding/
  l10n/                     app_de.arb, app_en.arb (optional app_de_AT.arb für „Jänner“)
```

### 4.3 Datenmodell (drift)

```
jobs         (id, name, colorArgb, kind[minijob|regular|at_geringfuegig|…], breakRule,
              roundingRule, monthlyCapCents?, archived)
wage_rates   (id, jobId, validFrom, centsPerHour)
shifts       (id, uuid, jobId, status[running|done|planned], startUtc, endUtc?, tzOffsetMin,
              rawStartUtc, rawEndUtc,               ← Originalzeiten bleiben erhalten
              rateCentsPerHour,                     ← Lohn-Schnappschuss
              pausedAtUtc?, pausedTotalMs, manualBreakMin,
              tipsCents, note, payoutId?, legacyId?, source[timer|manual|legacy|import],
              createdAt, updatedAt)
payouts      (id, jobId, periodStart, periodEnd, expectedCents, receivedCents?, paidOn, note)
meta         (key, value)                           ← schema_version, Migrationsstatus
```

Regeln: Geld nur als `int` Cent; Zeit nur als UTC; höchstens eine laufende Schicht (in Repository + Datenbank erzwungen); Betrag wird beim Abschluss einmal berechnet und gespeichert.

### 4.4 Datenübernahme v1 → v2 (kein Tester verliert Daten)

1. **Gleiche App-ID und gleicher Upload-Key**, höherer `versionCode` (z. B. `2.0.0+2`).
2. Beim ersten Start **vor** der Oberfläche: die drei alten Schlüssel über die **alte** shared_preferences-API lesen (Achtung: die neue Async-API liest standardmäßig eine *andere* Datei und würde „leer“ sehen).
3. Rohdaten wörtlich als `legacy_backup_v1.json` sichern; alte Schlüssel **nicht** löschen (erst in einer späteren Version).
4. In **einer** Transaktion: Standard-Job mit dem alten Stundenlohn anlegen, jeden Eintrag **einzeln** mit try/catch umwandeln (lokale Zeit → UTC + Offset, Lohn-Schnappschuss, `bezahlt` übernehmen), laufende Sitzung als laufende Schicht übernehmen, Sprache/Theme übernehmen.
5. Nicht lesbare Einträge in eine Fehlertabelle, **nie still verwerfen**; Export anbieten.
6. Einmaliger Hinweis: „N Einträge übernommen – Stundenlohn X €/h angenommen, bei Bedarf anpassen.“
7. Migration bei jedem Start prüfen (idempotent) – ein Auto-Backup-Restore kann v1-Daten in eine v2-Installation zurückbringen.
8. Tests mit realistischen v1-Daten: Nachtschicht, Einträge vom 29.03./25.10., gemischte ID-Formate, beschädigter Eintrag, laufende Sitzung.

### 4.5 Qualitätssicherung

- **Unit-Tests** für die gesamte Domain (Lohn, Rundung, Pausen, Validierung, Zeitumstellung unter `TZ=Europe/Berlin` und `Europe/Vienna`) und die Migration.
- **Widget-Tests** mit fester Uhr; **Golden-Tests** für Heute/Schichten/Übersicht × hell/dunkel × DE/EN × {360×640, 800×360, 1280×800} × Schrift {1,0; 2,0}. Jeder Überlauf lässt den Test fehlschlagen.
- **Barrierefreiheits-Tests** (`meetsGuideline` für Trefferflächen, Beschriftungen, Kontrast).
- **Performance-Budget-Test:** kein Rebuild von „Heute“ pro Tick, keine Timer im pausierten Zustand.
- **Lokalisierungs-Test:** alle Bildschirme auf Englisch durchlaufen, kein deutsches Wort erlaubt (und umgekehrt).
- **CI (GitHub Actions):** Format, `flutter analyze` (Warnungen = Fehler), `flutter test`, `flutter build appbundle`.
- Die 72 Reproduktions-Tests aus dieser Analyse liegen in [`docs/research/repro-tests/`](research/repro-tests/) und dienen als Startpunkt.

---

## 5. Roadmap

Umfang: **S** = klein, **M** = mittel, **L** = groß. Jede Phase endet mit einem lauffähigen, getesteten Stand.

### Phase 0 – Fundament (S–M)

- [ ] Flutter 3.47.5, `intl: any`, `CardThemeData`, Gradle/AGP/Kotlin/Java 17 auf aktuelle Mindestversionen, NDK-Pin entfernen, `proguard-rules.pro` anlegen, Signing nur wenn `key.properties` existiert
- [ ] Android-Manifest: `package=` raus, `enableOnBackInvokedCallback`, Backup-Regeln, `localeConfig`
- [ ] Neue Ordnerstruktur, Riverpod, drift, go_router, clock; Lints verschärfen
- [ ] CI-Pipeline, Test-Harness aus den Reproduktions-Tests übernehmen
- **Fertig, wenn:** Projekt baut auf frischem Clone, CI grün, AAB mit Ziel-API 36 und 16-KB-Ausrichtung.

### Phase 1 – Neuer Kern (L) → `2.0.0-beta` → **geschlossener Test starten**

- [ ] Domain: Geld in Cent, Rundung (Standard: keine), Validierung, Zeitumstellung – mit Tests
- [ ] drift-Schema + **v1-Migration** mit Tests
- [ ] Schicht-Engine mit Pause, „früher angefangen“, Beenden-Blatt, nie still verwerfen
- [ ] Benachrichtigung neu (einmal posten, Stoppuhr, Aktionen, Berechtigung beim ersten Start, lokalisiert, eigenes Icon)
- [ ] Designsystem hell/dunkel/System, adaptives Gerüst (Bar/Rail), Heute + Schichten + Editor + Einstellungen
- [ ] Alle Texte lokalisiert, Sprache „System“ als Standard, Zahlen/Datum überall über `intl`
- [ ] Löschen mit Rückgängig; „Alles löschen“ neu
- [ ] Wiederherstellungs-Bildschirm statt „Startup Error“
- **Fertig, wenn:** alle Bugs aus 2.2 durch Tests abgedeckt und grün; Golden-Tests ohne Überlauf in allen Größen; Performance-Budget eingehalten; Upgrade von v1.0.0 per `adb install -r` übernimmt alle Daten.

### Phase 2 – „Kann mehr“ (L) → `2.0.0` → **Produktionszugang beantragen**

- [ ] Mehrere Jobs + Lohnhistorie, Pausenregeln
- [ ] Auszahlungen erfassen
- [ ] Übersicht (Woche/Monat/Jahr, Diagramm, Ø-Lohn)
- [ ] Export PDF/CSV, Backup/Wiederherstellen
- [ ] Trinkgeld, Minijob-/Geringfügigkeitsgrenze
- [ ] Erinnerung „Arbeitest du noch?“, Onboarding
- [ ] Datenschutzerklärung DE/EN aktualisieren (Auto Backup, Export), in App verlinken; Store-Eintrag DE/EN, Tablet-Screenshots
- **Fertig, wenn:** 12 Tester seit 14 Tagen durchgehend im geschlossenen Test, keine offenen kritischen Bugs, Barrierefreiheits-Scanner sauber.

### Phase 3 – Komfort (M–L), Versionen 2.1+

- [ ] Homescreen-Widget, App-Shortcuts
- [ ] Schichtvorlagen, Schichtplanung mit Kalender
- [ ] Zuschläge Nacht/Sonntag/Feiertag inkl. Feiertagen je Bundesland
- [ ] Schnelleinstellungs-Kachel, NFC, Live Update (Android 16), Monatsziele

### Play-Store-Fahrplan

- Interner Test zählt **nicht** für die Freigabe. Neue private Entwicklerkonten brauchen einen **geschlossenen Test mit mindestens 12 Testern, die 14 Tage durchgehend dabei sind**. → Tester jetzt schon sammeln, geschlossenen Test mit der ersten 2.0-Beta starten, damit die 14 Tage parallel zu Phase 2 laufen.
- Jedes Update muss seit 31.08.2026 **API 36** anpeilen (Verlängerung bis 01.11.2026 in der Play Console beantragbar) – v1.0.0 lässt sich ohne Phase 0 nicht mehr aktualisieren.
- Datensicherheit: „keine Daten erhoben/geteilt“ bleibt korrekt, solange kein Crash-Reporting/Cloud-Backup dazukommt.

---

## 6. Offene Entscheidungen

| Frage | Empfehlung |
|---|---|
| Neuaufbau oder schrittweises Umbauen der alten Oberfläche? | **Neuaufbau im selben Repo** – fast jede Datei wird ohnehin ersetzt, der Umbau wäre teurer und fehleranfälliger. |
| Zielmarkt / Standard-Regeln: Deutschland, Österreich oder beides? | Beides, Land im Onboarding wählen (steuert Pausenregel, Minijob-/Geringfügigkeitsgrenze, Feiertage, „Jänner“). |
| Rundung auf Viertelstunden beibehalten? | Standard **keine** Rundung, pro Job einstellbar (1/5/10/15 min, auf/ab/nächste). Originalzeiten bleiben immer gespeichert. |
| Sortierung: neueste oben (heute) oder unten (Spezifikation)? | **Neueste oben** mit Monatssummen – üblicher für Stundenzettel. |
| Auto Backup (Google-Konto des Nutzers) an oder aus? | **An** mit expliziten Regeln + Datenschutzerklärung anpassen; zusätzlich manueller Export. |
| Wie viel in die erste Produktionsversion? | Phase 1 + 2. Phase 1 allein ist zu dünn für den Anspruch „kann mehr“. |

---

## 7. Anhang

- [`docs/research/code-audit.md`](research/code-audit.md) – vollständiger Bug-Katalog (41), Performance, Architektur, Android-Build, Datenmodell & Migration (englisch)
- [`docs/research/bug-reproduktion.md`](research/bug-reproduktion.md) – Testergebnisse mit Messwerten (englisch)
- [`docs/research/ux-audit.md`](research/ux-audit.md) – UX-Probleme, Abläufe, Lokalisierungslücken, Designsystem, alle Wireframes, Barrierefreiheit (englisch)
- [`docs/research/recherche.md`](research/recherche.md) – Konkurrenzanalyse, Feature-Ideen, Hintergrund-Best-Practice mit Code, Architektur, Pakete, Play-Anforderungen, Rechtliches DE/AT, Quellen (englisch)
- [`docs/research/repro-tests/`](research/repro-tests/) – die Reproduktions-Tests

> **Hinweis zu Rechtlichem:** Beträge in der App sind Schätzungen. Chronos ersetzt weder die Arbeitszeiterfassung des Arbeitgebers noch die Lohnabrechnung, und das muss in der App auch so stehen.
