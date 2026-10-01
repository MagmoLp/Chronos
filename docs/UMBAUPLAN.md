# Chronos 2.0 – Befund & Umbauplan

> Stand: 30.09.2026. Grundlage sind sechs Recherche-Schritte:
> - Code-Audit
> - UX-Audit
> - Markt- und Technik-Recherche
> - Bug-Reproduktion mit echten Flutter-Tests (Flutter 3.47.5)
> - Gegenprüfung (Verifikation) inklusive Suche nach dem Lösch-Bug
> - Faktencheck des Plans
>
> Die Rohdaten liegen in [`docs/research/`](research/).

> **Update 30.09.2026 – Entscheidung:** Der Umfang von 2.0 wurde vereinfacht und steht verbindlich in
> [`docs/SPEC_2_0.md`](SPEC_2_0.md). Ohne Länderregeln (DE/AT), ohne gesetzliche Pausenregeln, ohne Zuschläge.
> Statt der Minijob-Grenze gibt es ein frei einstellbares Monatsziel bzw. eine Monatsgrenze.
> Das Sicherheits-Update v1.0.1 entfällt, es wird direkt 2.0 umgesetzt.
> Wo dieser Plan davon abweicht, gilt die Spezifikation.
>
> **Stand 01.10.2026:** Chronos 2.0 ist auf dem Branch `claude/optimistic-brown-56sgj7` vollständig umgesetzt:
> neuer Code in `lib/`, über 1500 Tests, Screenshots in `docs/screenshots/`.
> Offen ist noch der Android-Build auf einem echten Rechner (Checkliste in `docs/ANDROID_BUILD.md`).
> In der Cloud-Sitzung war `dl.google.com` gesperrt, deshalb fehlt dort das Android-SDK.
> Danach folgt der geschlossene Test im Play Store.

---

## 1. Kurzfassung

1. **Die App ist ein Prototyp mit guter Idee, aber ohne tragfähiges Fundament.**
   - Die Logik steckt in den Widgets.
   - Geld wird als `double` gerechnet, Zeiten werden als lokale Strings ohne Zeitzone gespeichert.
   - Das ganze Protokoll liegt als ein einziger JSON-String in `shared_preferences`.
   - Es gibt keinen einzigen Test.
2. **Mit aktuellem Flutter baut sie nicht mehr.** `intl ^0.19.0` lässt `flutter pub get` scheitern, und `CardTheme` führt zu einem Compile-Fehler. Seit 31.08.2026 muss jedes Update Ziel-API 36 haben, deshalb geht ohne Toolchain-Upgrade kein Update mehr in den Play Store.
3. **Die meisten Bugs sind Symptome weniger Grundursachen.** Es gibt kein Theme-System (Dark/Light existiert gar nicht), kein responsives Layout, keine Trennung von Oberfläche und Logik, keinen Lohn pro Eintrag und keine Reaktion auf den App-Lebenszyklus.
4. **Das Laggen hat eine klare Ursache.** Ein Dart-Timer feuert jede Sekunde, auch im Hintergrund, und baut dabei den kompletten Startbildschirm neu (~270 Widgets pro Tick). Dazu wird die Benachrichtigung alle 15 s neu gepostet, also 240× pro Stunde. Nichts davon ist nötig.
5. **Es fehlt, was Catering-Jobber wirklich brauchen:** mehrere Jobs, Pausen, Lohnhistorie, Auszahlungen, Statistik, Export für den Arbeitgeber, Backup, Trinkgeld und die Minijob-Grenze.

**Empfehlung in zwei Schritten:**

- **Sofort: ein kleines Sicherheits-Update v1.0.1, fertig vor der Zeitumstellung am 25.10.2026.**
  - Es bringt die Toolchain auf API 36 und behebt mit Einzeilern die Fehler, die Daten verfälschen oder verlieren, sowie das Laggen.
  - Damit startet der geschlossene Test sofort. Die 14-Tage-Frist läuft dann parallel zur weiteren Arbeit.
- **Danach: Chronos 2.0 als geordneter Neuaufbau im selben Repository.**
  - App-ID `com.paulhuebner.chronos` und Upload-Key bleiben gleich.
  - Die Daten der Tester werden beim ersten Start automatisch übernommen und auf Plausibilität geprüft.
  - Die alte Oberfläche wird nach v1.0.1 nicht weiter geflickt, weil fast jede Datei ohnehin ersetzt wird.

Die Phasen stehen in [Abschnitt 5](#5-roadmap).

---

## 2. Befund

### 2.1 Build & Toolchain

| Problem | Beleg | Folge |
|---|---|---|
| `flutter pub get` schlägt fehl | `pubspec.yaml:14` `intl: ^0.19.0`, aktuelles `flutter_localizations` verlangt `^0.20.3` | Projekt lässt sich mit Flutter 3.47 nicht auflösen |
| Compile-Fehler | `lib/theme/app_theme.dart:61` `CardTheme` statt `CardThemeData` | Build bricht ab |
| Gradle / AGP / Kotlin veraltet | Gradle 8.9, AGP 8.7.0, Kotlin 2.1.0 (`android/gradle/wrapper/…`, `android/settings.gradle:21-22`) | Flutter 3.47.5 bricht unter **Gradle 8.14 / AGP 8.11.1 / Kotlin-Gradle-Plugin 2.2.20** und ohne JDK 17 ab (`flutter_tools/gradle/.../DependencyVersionChecker.kt`). Die aktuelle `flutter create`-Vorlage nutzt Gradle 9.3.1 / AGP 9.1.0 / KGP 2.4.0 |
| Java 1.8, fest eingestelltes NDK 27 | `android/app/build.gradle:36-46` | Java 17 verlangen Gradle und flutter_local_notifications 22. Die 16-KB-Ausrichtung (Pflicht seit 01.11.2025) betrifft v1 noch nicht, v2 mit SQLite aber schon. Prüfen mit `zipalign -c -P 16` bzw. im App-Bundle-Explorer |
| Ziel-API | Laut `pubspec.lock` vermutlich mit Flutter 3.24.x gebaut (Standard: targetSdk 34) | **Seit 31.08.2026 muss jedes Update API 36 anpeilen.** targetSdk, minSdk und versionCode der hochgeladenen v1.0.0 im App-Bundle-Explorer der Play Console nachsehen |
| `proguard-rules.pro` referenziert, fehlt; Signing ohne Prüfung | `android/app/build.gradle:52-76` | Frischer Clone und CI bauen nicht |
| Launcher-Icon 2048×2048 px in allen 5 Dichten (je 2,2 MB) | `android/app/src/main/res/mipmap-*` | Aufgeblähte App, keine Monochrom-Ebene für Android 13+ |
| 22× veraltetes `withOpacity` in `lib/`, abgeschaltete `const`-Lints, `flutter_lints` 4 | `flutter analyze`, `analysis_options.yaml` | Probleme werden versteckt |

### 2.2 Bugs – verifiziert

✅ heißt: **mit echten Widget- oder Unit-Tests reproduziert** (Flutter 3.47.5, Zeitzone Europe/Berlin). ◐ heißt: teilweise.

**Datenintegrität & Geld (kritisch)**

| # | Bug | Beleg | Ursache |
|---|---|---|---|
| D1 ✅ | Eingabe „12,50“ wird als **1250 €/h** gespeichert | `settings_screen.dart:384` | Der Eingabefilter lässt nur `.` zu und verschluckt das Komma. `replaceAll(',', '.')` ist toter Code |
| D2 ✅ | Eine Lohnänderung berechnet **alle alten Einträge rückwirkend neu, auch bezahlte** | `work_entry.dart:18-21` | Einträge speichern keinen Lohn, es wird immer der aktuelle genommen |
| D3 ✅ | Ein einziger beschädigter Wert, und die App startet nur noch mit „Startup Error“, **ohne Ausweg** | `storage_service.dart:48,63,84`, `main.dart:46-57` | Kein try/catch pro Eintrag, keine Validierung, keine Wiederherstellung |
| D4 ✅ | Sitzungen unter 15 min (nach Rundung) werden **nach** dem Stoppen verworfen. Die Zeit ist weg, kein Rückgängig | `home_screen.dart:250-273` | `stop()` löscht die Sitzung, bevor die Mindestdauer geprüft wird |
| D5 ✅ | Die Viertelstunden-Rundung rundet falsch: 08:07 → 08:15; 14 echte Minuten → 0, 16 → 30 | `home_screen.dart:198-206` | Schwelle 7 statt 7,5 Minuten |
| D6 ✅ | **Zeitumstellung:** gerundete Zeiten ±1 h daneben, Nachtschicht über die Umstellung 1 h zu kurz, laufende Sitzung nach Neustart 1 h versetzt | `home_screen.dart:204-205`, `work_log_screen.dart:552,751`, `storage_service.dart:76,84` | Es wird mit `Duration(days: 1)` auf lokaler Zeit gerechnet und ohne Zeitzonen-Offset gespeichert. **Nächste Umstellung: 25.10.2026** |
| D7 ✅ | Ende vor Start (Tippfehler) wird still als **23-h-Schicht** gespeichert; Ende gleich Start als 24 h | `work_log_screen.dart:551-553, 750-752` | Stillschweigende „über Nacht“-Annahme. Der Text `endAfterStart` existiert, wird aber nie benutzt |
| D8 ✅ | Summen stimmen nicht. 11,5 % der geprüften Kombinationen (Löhne 0,01–60,00 €, Viertelstunden bis 12 h) zeigen einen anderen Cent als die kaufmännische Rundung. Drei Einträge à 92,52 € ergeben „277,55 €“ | `work_entry.dart:18-20`, `work_entries_provider.dart:14-16` | Geld als `double`, gerundet wird erst bei der Anzeige |
| D9 ✅ | Doppeltipp auf „Speichern“, während noch gespeichert wird: **doppelter Eintrag und leerer Bildschirm**, nur ein Neustart hilft | `work_log_screen.dart:535-577, 734-776` | Der Button wird beim Speichern nicht gesperrt. Das zweite `Navigator.pop` schließt den Hauptbildschirm |
| D10 ✅ | Keine Überlappungsprüfung, dieselben Stunden können doppelt zählen | `work_entries_provider.dart:24-27` | – |
| D11 ✅ | Vergessener Stopp erzeugt mehrtägige Einträge ohne Erinnerung. Einen 30-h-Eintrag unverändert bearbeiten und speichern macht daraus **6 h** | `timer_provider.dart:32-37`, `work_log_screen.dart:743-752` | Das Enddatum wird aus Startdatum plus Uhrzeit neu gebaut |
| D12 ✅ | Gelöschte Einträge können wieder auftauchen. Bei doppelten IDs überschreibt „bezahlt“ einen fremden Eintrag | `storage_service.dart:21-30`, `work_entries_provider.dart:39-47` | Speichern ist immer „Einfügen oder Ersetzen“, die Liste im Speicher hinkt hinterher |
| D13 ✅ | Stoppen und dann schnell den Tab wechseln bei langsamem Speicher: die Schicht ist verloren | `timer_provider.dart:44`, `home_screen.dart:255, 281` | Die Sitzung wird vor dem Eintrag gelöscht, und das Speichern hängt an `context.mounted` |

**Bekannte Bugs aus dem internen Test**

| # | Bug | Befund |
|---|---|---|
| K1 ✅ | „Alles löschen“ bleibt Deutsch | Der **ganze** Bereich „Datenverwaltung“ ist fest auf Deutsch, inklusive Dialog und Snackbar (`settings_screen.dart:182-302`). Schlimmer: Auf Englisch lässt sich das Löschen **nur mit dem deutschen Wort „Löschen“** bestätigen, mit großem L. „Delete“ lässt den Button deaktiviert. Auch die Benachrichtigung ist immer Deutsch. |
| K2 ✅ | Querformat: „BOTTOM OVERFLOWED BY 284 PIXELS“ | Der Startbildschirm ist eine nicht scrollbare Spalte mit rund 460–500 dp fester Höhe. Gemessen wurden 222–318 px Überlauf, je nach Gerät, Systemleisten und Messmethode. **START/STOP liegen dann unter der Navigationsleiste und sind nicht mehr drückbar.** Bei großer Systemschrift passiert das auch im Hochformat auf kleinen Handys, bei 200 % Schrift ist der Protokoll-Tab nicht mehr erreichbar. Auch der Hinzufügen-, der Bearbeiten- und der Lösch-Dialog laufen über. |
| K3 ✅ | Darstellungsproblem beim Dark/Light-Wechsel | **Light Mode wurde nie implementiert.** `MaterialApp` bekommt nur ein dunkles Theme, es gibt keinen Umschalter, die Einstellung wird nirgends gelesen, und über 100 Farben sind fest im Code eingetragen. Umschalten ändert nichts; ein halbherziger Fix ergäbe eine Mischung aus hell und dunkel. |
| K4 | Tablet ungetestet | Es gibt **keinerlei** adaptiven Layout-Code, Tablets bekommen ein gestrecktes Handy-Layout. Bei targetSdk 36 ignoriert Android 16 auf Displays ab 600 dp kleinster Breite (Tablets, aufgeklappte Foldables) die Orientierungssperre. „Nur Hochformat“ ist also keine Lösung. |
| K5 ◐ | Löschen geht nicht richtig, Änderung erst nach Neustart sichtbar | Das Löschen selbst war in ~50 Szenarien sofort sichtbar, mit Flutter 3.24.5 und 3.47.5. Reproduziert wurden verwandte Fehler im selben Menü, die genau so wirken, vor allem **D9**. Details in [2.2a](#22a-löschen-braucht-neustart). |

#### 2.2a Löschen braucht Neustart

Rund 50 Szenarien wurden über die echte Oberfläche getestet, mit Flutter 3.47.5 und mit 3.24.5 (laut `pubspec.lock` vermutlich deine Build-Version):
- Einzeln löschen per Tippen und Lange-Drücken: erste, mittlere und letzte Zeile, bezahlt und offen
- „Alles löschen“ auf Deutsch und Englisch, aus beiden Tabs aufgerufen
- mit ausgeschalteten Animationen, sehr schnellen Taps und laufendem Timer
- direkt nach Hinzufügen, Bearbeiten oder Bezahlt-Markieren

**Ergebnis: Das Löschen selbst entfernt die Zeile sofort**, auch Summen und Startbildschirm stimmen sofort.

Reproduziert wurden dagegen Fehler, die sich wie „Löschen ging nicht, erst nach Neustart“ anfühlen. Sie treten auf, sobald das Speichern länger dauert als der Abstand zwischen zwei Tipps. Bei 30 ms Tippabstand reichen schon 40 ms Speicherzeit. Das ist realistisch, denn v1 schreibt bei jedem Speichern die ganze Einstellungsdatei samt kompletten Protokoll synchron (`commit()`). Das wird mit jedem Eintrag langsamer und ist auf einem ausgelasteten Handy noch langsamer ([2.3](#23-warum-das-handy-laggt)).

1. **Doppeltipp auf „Speichern“ (D9), die wahrscheinlichste Erklärung.** Im Hinzufügen- oder Bearbeiten-Dialog, der im selben Menü wie „Löschen“ liegt, erzeugt ein Doppeltipp während des Speicherns ein zweites `Navigator.pop`. Das schließt den Hauptbildschirm mit, es bleibt ein **leerer Bildschirm, den nur ein Neustart behebt**. Danach ist die Änderung da, beim Hinzufügen sogar doppelt. Löscht man einen der Zwillinge, steht der identische andere noch da (`work_log_screen.dart:535-577, 734-776`).
2. **Zombie-Zeile (D12).** Die gelöschte Zeile bleibt sichtbar und bedienbar, bis das Speichern fertig ist (`work_entries_provider.dart:29-32`). Wer sie in dieser Zeit als bezahlt markiert oder bearbeitet, **legt den gelöschten Eintrag wieder an** (`storage_service.dart:21-30`).
3. **Verschluckte Fehler.** Das Löschen läuft ohne Fehlerbehandlung (`work_log_screen.dart:351`). Schlägt das Speichern fehl, bleibt die Zeile stehen, obwohl sie im Speicher schon fehlt. Erst ein Neustart zeigt den wahren Stand. Nur dieser Fall erzeugt genau „erst nach Neustart sichtbar“, einen realen Auslöser dafür kennen wir aber nicht.

Dazu kommen Bedienfehler rund ums Löschen:
- **„Alles löschen“ auf Englisch** akzeptiert nur das deutsche „Löschen“ mit großem L. „Delete“, „löschen“ und „LÖSCHEN“ lassen den Button ohne Hinweis deaktiviert.
- **Doppeltipp auf eine Zeile:** Das Menü öffnet sich und schließt sich sofort wieder.
- **Zeilen ohne Schlüssel:** Die blaue „bezahlt“-Hervorhebung einer gelöschten Zeile wandert kurz auf die Nachbarzeile.

> **Bitte an dich:** Wenn du dich an die genauen Schritte erinnerst (Bearbeiten oder Löschen? Welcher Bildschirm? War er leer? Welches Handy?), schreib sie auf. Das hilft beim Absichern.

**v1.0.1** sperrt die Speichern-Buttons. **In 2.0 verschwindet die ganze Fehlerklasse:**
- Die Oberfläche hört direkt auf die Datenbank (reaktive Abfragen).
- Löschen entfernt die Zeile sofort und bietet Rückgängig an.
- Buttons sperren sich während des Speicherns.
- Bearbeiten legt nie neue Einträge an.
- Fehler werden angezeigt statt verschluckt.

Tests dazu: `docs/research/repro-tests/verify_delete_*`.

**Weitere Fehler (Auswahl)**

- Beim ersten Start ist die App **immer Deutsch**, egal welche Gerätesprache eingestellt ist (`app_settings.dart:11`).
- Die Benachrichtigungs-Berechtigung wird **vor dem ersten Bild** abgefragt. Unter Android 13+ bleibt die App schwarz, bis man antwortet (`main.dart:28`, `notification_service.dart:24-28`).
- Eine Lohnänderung auf dem Protokoll-Tab erreicht die Benachrichtigung nicht. Der Lohn wird nur im `build()` des Startbildschirms gesetzt (`home_screen.dart:31`).
- Nach dem Neustart zeigt der Zähler eine Sekunde lang `00:00:00 / 0,00 €` und rollt dann alle Ziffern durch (`timer_provider.dart:25-30`).
- Die Zahlenformate sind uneinheitlich: Startseite „502,50€“, Protokoll „120.00 €“, Benachrichtigung „0.00 €“. Die Zeitauswahl zeigt auf Englisch AM/PM, die Liste 24 h.
- Das Benachrichtigungs-Icon ist das bunte Launcher-Icon, das in der Statusleiste als weißer Klecks erscheint.
- Die Datumsauswahl ist fest auf 2020 bis 31.12.2029 begrenzt. Ab 01.01.2030 schlägt „Eintrag hinzufügen“ fehl (im Debug-Build nachgewiesen), und Zukunftsdaten sind erlaubt.
- Die Zurück-Taste auf dem Protokoll-Tab beendet die App, und ein Tabwechsel verliert die Scrollposition.
- `RobotoMono` wird verwendet, ist aber nicht eingebunden. Die START/STOP-Beschriftung verliert die Theme-Schrift.
- **Android Auto Backup ist implizit aktiv.** Die Datenschutzerklärung sagt aber, die Daten „verlassen [das Gerät] niemals“. Das ist **schon heute falsch**.

Vollständiger Katalog: [`code-audit.md`](research/code-audit.md) (41 Einträge), [`bug-reproduktion.md`](research/bug-reproduktion.md), [`verifikation.md`](research/verifikation.md).

### 2.3 Warum das Handy laggt

Gemessen im Test (Timer läuft, 15 €/h):

| Zustand | Was passiert | Messwert |
|---|---|---|
| App sichtbar | `Timer.periodic(1 s)` → `notifyListeners()` → **der ganze Startbildschirm** baut neu | ~270 Widget-Builds pro Tick, ~420 Builds/s inkl. Ziffern-Animationen |
| Einstellungen liegen über dem Startbildschirm | Der Startbildschirm baut trotzdem weiter neu, unsichtbar | ~262 Builds/s |
| App im Hintergrund | Der Timer läuft weiter, `notifyListeners` 60× pro Minute. Die Benachrichtigung wird alle **15 s** neu gepostet (der Kommentar sagt 30) | 240 Benachrichtigungs-Posts pro Stunde, jeder mit mehreren Plattform-Aufrufen und Neuzeichnen in der SystemUI |
| Rückkehr in die App | Alle Ziffern werden nachgeholt | ~690 Builds/s für einen Moment |

Dazu kommen:
- pro Ziffer ein `AnimatedSwitcher` mit `Opacity` (teure Offscreen-Ebene)
- pro Listenzeile ein eigener `AnimationController`
- bei jedem Tastendruck im Lohnfeld ein Neubau der kompletten App

**Warum es auf manchen Handys schlimmer ist:** Neuere Android-Versionen frieren gecachte Apps nach kurzer Zeit ein, auf Pixel-Geräten standardmäßig. Das verdeckt das Problem. Viele Hersteller-ROMs verhalten sich anders, dort läuft der Timer unbegrenzt weiter.

**Die Lösung ist nicht „optimieren“, sondern „weglassen“:** Die Arbeitszeit ergibt sich aus gespeicherter Startzeit und aktueller Uhrzeit. Dafür muss im Hintergrund **gar nichts** laufen (siehe [3.5](#35-hintergrund-konzept-null-code-im-hintergrund)).

### 2.4 Warum es sich „klobig“ anfühlt

- **Eigenbau statt Material-Komponenten:** Buttons, Navigationsleiste, Karten, Checkbox und Sprachauswahl sind selbstgebaute `GestureDetector`-Widgets. Sie haben keinen Ripple, keine Barrierefreiheit, keinen Fokus und teils nur 28 dp Trefferfläche.
- **Alles federt:** Jedes Element schrumpft beim Drücken (0,9–0,98), jeder Container animiert Farbe und Rahmen, die Navigationsleiste schwingt über (`easeOutBack`). Das wirkt gummiartig und träge.
- **Keine Hierarchie:** Drei riesige Zahlen (56 px, 40 px, 52 px) konkurrieren, jede in einem umrandeten Kasten. Im Leerlauf zeigt der Startbildschirm „0,00 €“, „00:00:00“ und einen ausgegrauten STOPP-Button.
- **Boxen in Boxen, Rahmen überall:**
  - 1,5-px-Rahmen um jede Karte.
  - „Bezahlt“ ist dreifach markiert: Checkbox, blaue Tönung, grünes Badge.
  - In den Einstellungen liegt Karte in Karte mit bis zu 132 dp Einrückung.
- **Uneinheitliche Maße:** 7 verschiedene Eckradien, 9 fest eingetragene Schriftgrößen, 3 verschiedene Seitenabstände.
- **Farben:** Generisches „Electric Blue auf #121212“. Das ist weder das spezifizierte Navy/Anthrazit, noch passt es zum Icon. Weiß auf Grün (START) hat nur 2,3 : 1 Kontrast.
- **Umständliche Abläufe:** Eine Endzeit korrigieren heißt Zeile tippen → Bearbeiten → Dialog → Endzeit → Uhr-Picker → OK → Speichern. Das sind 6+ Schritte, Dialog auf Dialog.

### 2.5 Features, die nicht zu Ende gedacht sind

| Feature | Problem heute |
|---|---|
| Start/Stopp | Leere „Sind Sie sicher?“-Abfrage, danach stilles Runden und Verwerfen. Keine Pause. Ein vergessener Start oder Stopp lässt sich nicht korrigieren |
| „Aktueller Verdienst“ | Laut deiner Spezifikation „heute verdient“, zeigt aber nur die laufende Sitzung. Eine zweite Schicht am Tag beginnt wieder bei 0 |
| Stundenlohn | Ein einziger globaler Wert, speichert bei jedem Tastendruck und verändert die Vergangenheit |
| Bezahlt/Unbezahlt | Jede Zeile einzeln abhaken, ohne Datum, ohne Betrag, ohne Abrechnung |
| Einträge bearbeiten | Nur Datum und Zeiten. Hinzufügen und Bearbeiten sind ~2×160 Zeilen duplizierter Code |
| Alles löschen | Deutsches Tippwort, kein Export vorher, nur „alles oder nichts“ |
| Rundung | Fest eingebaut, unsichtbar und nur für Timer-Einträge. Die Originalzeiten gehen verloren |

### 2.6 Warum die App zu wenig kann

Verglichen wurden 10 Konkurrenz-Apps (Details: [`recherche.md`](research/recherche.md)).

- **Was die guten Apps haben und Chronos nicht:**
  - mehrere Jobs mit eigenem Lohn
  - Pausen
  - Wochen- und Monatsstatistik
  - Export (PDF/CSV) und Backup
  - Widget und Benachrichtigung mit Aktionen
  - Erinnerung bei vergessenem Ausstempeln
- **Die häufigsten Beschwerden über die Konkurrenz:** Datenverlust, Werbung, Abo-Zwang für Grundfunktionen (mehrere Jobs, Widget, Export), Konto-Pflicht und verwirrende Bedienung.
- **Die Lücke für Chronos:** eine werbefreie, konto-freie, komplett offline laufende App für Stundenjobber in DE/AT. Dazu gehören Live-Lohn, Pausen nach ArbZG/AZG, Minijob- bzw. Geringfügigkeitsgrenze, Trinkgeld und ein Stundenzettel-Export. **Unter den 10 untersuchten Apps bietet keine diese Kombination.**

---

## 3. Zielbild Chronos 2.0

### 3.1 Produktprinzipien

1. **Eine Hauptzahl pro Bildschirm.** Was gerade zählt, steht groß, alles andere ist Nebeninfo.
2. **Vertrauenswürdig wie eine Banking-App.** Kein Cent-Fehler, keine verlorene Minute, jede Aktion lässt sich rückgängig machen.
3. **Null Arbeit im Hintergrund.** Akku-neutral, auch während einer 10-Stunden-Schicht.
4. **Schnell mit einer Hand**, auch in der Hektik beim Schichtwechsel: Hauptaktionen unten, große Trefferflächen, Haptik.
5. **Offline & privat.** Kein Konto, keine Werbung, keine Tracker.

### 3.2 Navigation & Bildschirme

Auf dem Handy gibt es drei Ziele in der Navigationsleiste, im Querformat und auf Tablets eine seitliche Navigation (Rail). Einstellungen bleiben das Zahnrad oben rechts, wie in der Spezifikation.

| Ziel | Beantwortet | Inhalt |
|---|---|---|
| **Heute** | „Was verdiene ich heute, was schuldet man mir?“ | Start / Pause / Beenden, heute verdient (live), offener Betrag, diese Woche, letzte Schicht |
| **Schichten** | „Was habe ich gearbeitet, was ist bezahlt?“ | Nach Monaten gruppierte Liste mit Summen, Filter (offen/bezahlt/Job), Wischen für bezahlt/löschen mit Rückgängig, „+ Schicht“ |
| **Übersicht** | „Wie läuft es über die Zeit?“ | Woche/Monat/Jahr, Diagramm, Durchschnitts-Stundenlohn inkl. Trinkgeld, Minijob-Grenze, Auszahlungen, Export |

**Heute, wie in deiner Spezifikation:** Oben groß steht **„Heute verdient“**, inklusive laufender Schicht, darunter **„Offen gesamt“**. Beide steigen live mit, die Cent-Ziffern rollen von oben herein. Hast du heute noch nicht gearbeitet, rückt „Offen“ nach oben, damit dort kein nutzloses „0,00 €“ steht.

```
LEERLAUF (heute noch nichts)                LÄUFT
+------------------------------------+     +------------------------------------+
| Heute, Mi 30. Sep           (Zahnr)|     | Heute, Mi 30. Sep           (Zahnr)|
| +--------------------------------+ |     | +--------------------------------+ |
| | Offen                          | |     | | ● Läuft · Catering Müller      | |
| | 1.234,56 €                     | |     | | Heute verdient                 | |
| | 82,5 h · 11 Schichten          | |     | |            87,40 €             | |
| |         [Auszahlung erfassen >]| |     | |  3:11:42   seit 08:02 (ändern) | |
| +--------------------------------+ |     | |  15,00 €/h · Pause 0:30        | |
|  Job ( ● Catering Müller  v )      |     | +--------------------------------+ |
| +--------------------------------+ |     |  Offen gesamt          1.282,39 €  |
| |        ▶  Schicht starten      | |     |  davon diese Schicht      47,83 €  |
| +--------------------------------+ |     | +--------------+ +---------------+ |
|  Früher angefangen? [-15] [Zeit]   |     | |  ⏸  Pause    | |  ■  Beenden   | |
|  Diese Woche      18,5 h  256,75 € |     | +--------------+ +---------------+ |
|  Letzte Schicht Mo 08:00–16:15   > |     |                                    |
+------------------------------------+     +------------------------------------+
| [●Heute]   Schichten   Übersicht   |     | [●Heute]   Schichten   Übersicht   |
+------------------------------------+     +------------------------------------+
```

Im Querformat sitzt die Navigation links, der Betrag in der Mitte und die Buttons rechts, nichts muss scrollen. Auf dem Tablet kommt eine rechte Spalte mit den heutigen Schichten und einer Mini-Wochengrafik dazu. Die Job-Auswahl ist unsichtbar, solange es nur einen Job gibt.

**Neue Abläufe statt Dialog-Ketten**

- **„Schicht beenden“-Blatt statt leerer Sicherheitsabfrage.** Es ist die Bestätigung aus deiner Spezifikation, aber mit Inhalt:
  - Rohzeit → gerundete Zeit, Pause, Dauer × Lohn = Betrag
  - optional Trinkgeld und Notiz
  - Aktionen: *Speichern / Weiterlaufen lassen / Verwerfen*
  - Wegwischen lässt den Timer weiterlaufen. Kurze Schichten werden nie still verworfen.
- **Ein Schicht-Editor für Hinzufügen und Bearbeiten:**
  - Uhrzeiten per Tastatur („0815“) plus ±15-min-Knöpfe
  - Schalter „endet am nächsten Tag“
  - Live-Vorschau „7:45 h × 15,00 €/h = 116,25 €“
  - Warnung bei Überlappung und bei mehr als 16 h
- **Lange Drücken** auf eine Zeile öffnet das Menü aus der Spezifikation: *Bearbeiten / Duplizieren / Löschen / Auswählen*. „Auswählen“ startet die Mehrfachauswahl. Tippen öffnet direkt den Editor.
- **Auszahlung erfassen statt 20 Häkchen:**
  1. Zeitraum wählen, z. B. „23 Schichten · 172,5 h · erwartet 2.587,50 €“.
  2. Erhaltenen Betrag eintragen, die Differenz wird angezeigt.
  3. Alle Schichten werden mit Datum als bezahlt markiert.
- **Löschen und Bezahlt per Wischen, mit Rückgängig.**
- **„Alles löschen“** nur noch unter *Einstellungen → Daten*: lokalisiert, mit Anzahl („214 Schichten und 2 Jobs löschen?“), automatischer Sicherung vorher und Rückgängig.

Alle Wireframes (Querformat/Tablet, Übersicht, Jobs, Export, Onboarding, Widget) stehen in [`ux-audit.md`](research/ux-audit.md).

### 3.3 Funktionsumfang

| Funktion | Nutzen | Release |
|---|---|---|
| Absturzsichere Schicht-Engine (Start/Pause/Fortsetzen/Beenden, „früher angefangen“) | Keine verlorene Minute, auch nach Neustart oder Kill | 2.0 |
| Lohn pro Schicht gespeichert, dazu Lohnhistorie | Die Vergangenheit bleibt stabil | 2.0 |
| Pausen erfassen, **Warnung** bei Unterschreitung (ArbZG §4 / AZG §11, optional Jugendschutz). **Automatischer Abzug nur, wenn eingeschaltet** („Zieht dein Arbeitgeber Pausen ab?“) | Betrag passt zur Abrechnung, ohne zu niedrig zu schätzen | 2.0 |
| Mehrere Jobs mit Farbe, Lohn, Rundungs- und Pausenregel | Catering-Jobber haben oft 2–3 Arbeitgeber | 2.0 |
| Auszahlungen / Abrechnungen | „Hat mich mein Chef richtig bezahlt?“ | 2.0 |
| Übersicht: Woche/Monat/Jahr, Diagramm, Ø-Stundenlohn | Langfristiger Nutzen | 2.0 |
| Export: Stundenzettel-PDF und CSV (Excel-tauglich, deutsches Format) | Für den Arbeitgeber, Streitfälle, §17 MiLoG | 2.0 |
| Backup & Wiederherstellung (Datei) plus Auto Backup | Handywechsel, Datensicherheit | 2.0 |
| Benachrichtigung mit nativer Stoppuhr und den Aktionen [Pause] [Beenden] | Bedienung vom Sperrbildschirm, ohne Akkuverbrauch | 2.0 |
| Erinnerung „Arbeitest du noch?“ nach X Stunden | Der häufigste Datenfehler | 2.0 |
| Trinkgeld pro Schicht, effektiver Stundenlohn | Trinkgeld kann im Service einen spürbaren Teil des Einkommens ausmachen | 2.0 |
| Minijob- bzw. Geringfügigkeitsgrenze mit Fortschrittsbalken | Überschreitung hat echte Folgen | 2.0 |
| Onboarding (Sprache und Theme automatisch, Land, Lohn abfragen) | Kein versteckter 15-€-Standard | 2.0 |
| Fehlerprotokoll lokal, „Fehlerbericht teilen“ | Fehler bei Testern werden sichtbar, ohne Internet | 2.0 |
| Homescreen-Widget (Start/Stopp, laufende Uhr) | Ein-Tipp-Stempeln; bei der Konkurrenz meist kostenpflichtig | 2.1 |
| Schichtvorlagen & Schichtplanung (Kalender) | Dienstpläne schnell eintragen, erwarteter Monatslohn | 2.1 |
| Zuschläge Nacht/Sonntag/Feiertag mit DE/AT-Vorlagen und Feiertagskalender | Häufigster Grund für Abweichungen von der Abrechnung | 2.2 |
| Schnelleinstellungs-Kachel, App-Shortcuts, NFC-Tag | Noch schneller stempeln | 2.2 |
| Android 16 Live Update (Chip in der Statusleiste) | Glanzstück, sobald das Plugin es kann | später |
| Bewusst **nicht**: Geofencing, Cloud-Konto, Netto-Lohnsteuerrechner | Play-Richtlinien, Datenschutz, Haftung | – |

### 3.4 Designsystem „Navy Night / Sky Day“

- **Material 3 mit echten Komponenten** (NavigationBar/Rail, FilledButton, Card, ListTile, SegmentedButton, Checkbox, Sheets). Die fünf `animated_*`-Eigenbauten entfallen, es bleiben vier eigene Widgets: Rollzähler, Leerzustand, Datumsblock und Statistik-Karte.
- **Farben** (Kontrast geprüft, alle Textpaare mindestens 4,5 : 1):
  - Dunkel: navy-getönte Flächen `#0B1320 … #233142`, Himmelblau `#9CCFF5` als Primärfarbe.
  - Hell: `#F6F9FC` mit Navy `#14548C`.
  - Die Markenfarbe `#87CEEB` markiert die laufende Schicht, **nur als Fläche mit dunklem Text**. Als Text auf hellem Grund hätte sie nur 1,7 : 1 Kontrast.
  - Bernstein steht für „offen“, Grün für „bezahlt“, Rot nur für Destruktives.
  - Optional „Hintergrundfarben verwenden“ (Material You), standardmäßig aus.
- **Theme** System / Hell / Dunkel, Standard ist *System*. Statusleisten-Icons und Splash passen sich an.
- **Typografie:** die Systemschrift (Roboto) mit **tabellarischen Ziffern** für alle Zahlen, damit der Zähler nicht mehr zittert. Keine mitgelieferte Schrift, das spart App-Größe. Feste Schriftrollen statt Zahlen im Code.
- **Form & Abstand:** 7 Radius-Stufen mit fester Zuordnung, 4-dp-Raster, 16 dp Rand auf dem Handy und 24 dp auf dem Tablet, Trefferflächen ab 48 dp.
- **Bewegung, nur drei Animationen auf „Heute“:**
  1. Die Cent-Ziffern rollen von oben herein (wie in der Spezifikation), und nur wenn sich eine Ziffer ändert.
  2. Einmaliger Übergang zwischen Leerlauf und laufender Schicht.
  3. Der Start-Button verwandelt sich in die Beenden-Form.

  Nichts schrumpft beim Drücken, nichts animiert dauerhaft, und „Animationen entfernen“ des Systems wird respektiert.
- **Barrierefreiheit:** 200 % Schriftgröße ohne Überlauf, TalkBack-Beschriftungen, Wisch-Aktionen auch als Bedienhilfe-Aktionen, Status nie nur über Farbe.
- **Haptik** bei Start, Beenden, Bezahlt und Löschen.
- **Neues Icon:** ein vereinfachtes Sanduhr-und-€-Zeichen auf Navy `#001F3F`, mit Monochrom-Ebene und eigenem Benachrichtigungs-Icon.

Vollständige Farbtabelle, Typo-Skala, Komponenten-Inventar und Barrierefreiheits-Checkliste: [`ux-audit.md`](research/ux-audit.md). Die dort vorgeschlagene gebündelte Schrift Roboto Flex ist durch die Systemschrift ersetzt.

### 3.5 Hintergrund-Konzept: null Code im Hintergrund

| Baustein | Umsetzung |
|---|---|
| Datenquelle | Start-, Pausen- und Endzeit liegen **ausschließlich in der Datenbank**, in UTC. Arbeitszeit und Betrag werden **berechnet**, nicht hochgezählt. Kill, Neustart oder Zeitumstellung ändern daran nichts. |
| Anzeige | Ein kleines `LiveTicker`-Widget tickt **nur, solange die App sichtbar ist**, und baut nur die Zahl neu, nicht den Bildschirm. |
| Benachrichtigung | Wird **einmal pro Zustandswechsel** gepostet, die laufende Uhr zeichnet Android selbst (`usesChronometer`). Keine Updates im Takt. Beim App-Start wird die Benachrichtigung mit der laufenden Schicht abgeglichen, z. B. nach einem Neustart oder wenn sie weggewischt wurde. |
| Aktionen | [Pause] läuft kurz in einem Hintergrund-Isolat und schreibt direkt in die Datenbank. [Beenden] öffnet das „Schicht beenden“-Blatt. |
| Erinnerungen | Nicht exakt geplante Benachrichtigungen (`inexactAllowWhileIdle`), daher keine Exact-Alarm-Berechtigung nötig. Ein Boot-Receiver plant sie nach dem Neustart neu ein. |
| Widget | Native `<Chronometer>` im Widget, Update nur bei Zustandswechsel. |
| Foreground-Service | **Keiner.** Er ist nicht nötig, die Play-Deklaration ist aufwendig, und er hält den Prozess wach. |

**Zielwerte:**
- 0 Frames pro Sekunde im Leerlauf.
- Bei sichtbarer App baut die Uhr einmal pro Sekunde neu, der Betrag einmal pro neuem Cent (höchstens 4× pro Sekunde), jeweils nur die betroffenen Ziffern.
- **0 Dart-Timer im Hintergrund.**
- 1 Benachrichtigungs-Post pro Zustandswechsel.

---

## 4. Technische Architektur

### 4.1 Stack

Bewusst schlank gehalten für ein Hobby-Projekt, das mit KI-Unterstützung umgesetzt wird.

| Bereich | Heute | Neu | Warum |
|---|---|---|---|
| Flutter | vermutlich ~3.24 | **3.47.5** stable, Dart 3.13, Version gepinnt (`.fvmrc` bzw. in der CI) | Build, API 36, 16 KB, Edge-to-Edge |
| State | Provider | **Riverpod 3**, nur handgeschriebene `Notifier`/`AsyncNotifier`/`StreamProvider`, **ohne Codegen** | Gleiches Denkmodell wie Provider, aber ohne `BuildContext` nutzbar (Benachrichtigung, Widget) und leichter zu testen. *Alternative:* bei Provider bleiben, das hat auch `StreamProvider`. |
| Speicher | 1 JSON-String in shared_preferences | **drift** (SQLite) | Kern der Datensicherheit: Tabellen, Transaktionen, getestete Migrationen, reaktive Abfragen, Summen per SQL. Isar und Hive sind verwaist |
| Einstellungen | shared_preferences (alte API) | `SharedPreferencesWithCache` (einmal asynchron erzeugen, danach synchron lesen) | Sprache und Theme beim Start |
| Navigation | AnimatedSwitcher | `NavigationBar`/`NavigationRail` + `IndexedStack` + `Navigator.push`, Deep Links über einen globalen `navigatorKey` | Tabs behalten ihren Zustand. go_router erst prüfen, wenn Widget und Kachel Deep Links brauchen (Phase 3) |
| Zeit | `DateTime.now()` überall | `package:clock` | Tests mit eingefrorener Zeit |
| Geld | `double` | `int` Cent und eine dokumentierte Rundungsregel | Kein Cent-Fehler |
| Benachrichtigung | flutter_local_notifications 18 | **flutter_local_notifications 22** (benannte Parameter) | Stoppuhr, Aktionen, Berechtigung im Kontext |
| Export | – | `pdf` + `printing`, `csv`, `share_plus`, `file_picker` | Stundenzettel, Backup ohne Speicher-Berechtigung |
| Diagramme | – | `fl_chart` | Übersicht |
| Widget | – | `home_widget` + nativer Kotlin-Provider | Phase 3 |
| Material-Import | `package:flutter/material.dart` | Vorerst so lassen. Auf `package:material_ui` später per `dart fix` umstellen, wenn die UI-Pakete so weit sind | Kein Import-Chaos mitten im Neuaufbau |
| Lints | flutter_lints 4, const-Regeln aus | flutter_lints 6 + `unawaited_futures`, `discarded_futures`, `prefer_const_*`, `riverpod_lint` | Fehler früh sehen |

Genaue Versionen: [`recherche.md`](research/recherche.md). Dort stehen zwei überholte Angaben: Kotlin 2.1.0 reicht **nicht**, und sqlite3 3.x lädt vorkompilierte Binärdateien, statt mit dem NDK zu bauen.

### 4.2 Projektstruktur

```
lib/
  main.dart                 runApp sofort → Startbildschirm; ein bootstrap-Provider öffnet die DB,
                            führt die v1-Migration aus und lädt die Einstellungen; Fehler → Wiederherstellungs-Bildschirm
  app/                      Theme (ColorSchemes, ThemeExtension), adaptives Gerüst, Lifecycle-Abgleich, Fehlerprotokoll
  core/                     clock, money (Cents + Formatierung), time, result
  domain/                   reines Dart, 100 % getestet:
                            pay_engine, rounding, break_policy, validation,
                            (später surcharge_engine, holidays_de_at, minijob_rules)
  data/                     drift-Datenbank, Tabellen, DAOs, Repositories, legacy_migration, backup
  platform/                 notifications, reminders, home widget
  features/                 today/ shifts/ insights/ payouts/ export/ settings/ onboarding/
  l10n/                     app_de.arb, app_en.arb (optional app_de_AT.arb für „Jänner“)
```

### 4.3 Datenmodell (drift)

```
jobs         (id, uuid, name, colorArgb, kind[minijob|regular|at_geringfuegig|…], breakRule,
              autoDeductBreaks, roundingRule, monthlyCapCents?, archived)
wage_rates   (id, jobId, validFrom, centsPerHour)
shifts       (id, uuid, jobId, status[running|done|planned],
              startUtc, endUtc?, startOffsetMin, endOffsetMin?,   ← eigener Offset für Start und Ende (Nachtschicht über Zeitumstellung)
              rawStartUtc, rawEndUtc?,                            ← Originalzeiten bleiben erhalten
              rateCentsPerHour,                                   ← Lohn-Schnappschuss
              amountCents?,                                       ← beim Abschluss einmal berechnet
              manualBreakMin, tipsCents, note, payoutId?,
              legacyId?, legacyPaid?, source[timer|manual|legacy|import],
              createdAt, updatedAt, deletedAt?)                   ← Soft-Delete für Rückgängig
breaks       (id, shiftId, startUtc, endUtc?)                     ← Pausenabschnitte (Pause-Knopf)
payouts      (id, uuid, jobId, periodStart, periodEnd, expectedCents, receivedCents?, paidOn, note)
meta         (key, value)                                          ← schema_version, Migrationsstatus
```

**Regeln:**
- Geld nur als `int` Cent, Zeit nur als UTC.
- Höchstens eine laufende Schicht, erzwungen im Repository und in der Datenbank.
- **Alles, was Benachrichtigung oder Widget ändern, liegt ausschließlich in drift**, nicht in SharedPreferences, weil das Hintergrund-Isolat nur so denselben Stand sieht.
- UUIDs überall dort, wo Backups zusammengeführt werden müssen.

**Formatregeln:**
- Zahlen, Datum und Uhrzeit folgen der App-Sprache plus Geräteregion (`de_DE`, `de_AT`, `en_*`).
- Das 12/24-h-Format folgt überall der Systemeinstellung, in Auswahl und Liste.
- Die Währung ist fest EUR (dokumentiert).
- Beim CSV-Export gibt es zwei Varianten: „Excel (DE)“ mit `;`, Dezimalkomma und UTF-8-BOM, oder „Standard“ mit `,` und Punkt.

### 4.4 Datenübernahme v1 → v2 (kein Tester verliert Daten)

1. **Gleiche App-ID und gleicher Upload-Key**, dazu ein höherer `versionCode`.
2. **Beim ersten Start**, hinter einem Startbildschirm und vor der eigentlichen Oberfläche, die drei alten Schlüssel über die **alte** shared_preferences-API lesen. Die neue Async-API liest standardmäßig eine *andere* Datei und würde „leer“ sehen.
3. Die Rohdaten wörtlich als `legacy_backup_v1.json` sichern. Die alten Schlüssel **nicht** löschen, das passiert erst in einer späteren Version.
4. In **einer** Transaktion:
   - einen Standard-Job mit dem alten Stundenlohn anlegen
   - jeden Eintrag **einzeln** mit try/catch umwandeln: lokale Zeit → UTC mit Offset für Start und Ende, Lohn-Schnappschuss, „bezahlt“ übernehmen
   - eine laufende Sitzung als laufende Schicht übernehmen
   - Sprache und Theme übernehmen
5. **Plausibilitätsprüfung, denn v1 hat bereits Daten verfälscht:**
   - Stundenlohn über 100 €/h oder unter 5 €/h → nachfragen („Meintest du 12,50 €/h?“), siehe D1.
   - Diese Einträge kommen auf eine Liste **„N Einträge prüfen“**:
     - 16 h oder länger, genau 23 h oder 24 h (D7, D11)
     - identische Start/Ende-Paare und doppelte IDs (D9, D12)
     - Überlappungen (D10)
     - Einträge vom 29.03. oder 25.10. (D6)
   - Nichts wird automatisch korrigiert oder gelöscht, alles ist einzeln bestätigbar.
6. **Der übernommene Standard-Job behält die bisherige Viertelstunden-Rundung** (mit korrigierter Schwelle) und sagt das im Hinweis. „Keine Rundung“ gilt nur für neue Jobs.
7. Nicht lesbare Einträge kommen in eine Fehlertabelle, sie werden **nie still verworfen**. Export anbieten.
8. Einmaliger Hinweis: „N Einträge übernommen, Stundenlohn X €/h angenommen, bei Bedarf anpassen.“
9. Die Migration bei jedem Start prüfen (idempotent), weil ein Auto-Backup-Restore v1-Daten in eine v2-Installation zurückbringen kann.
10. **Testfälle mit realistischen v1-Daten:**
    - Nachtschicht
    - Einträge vom 29.03. und 25.10.
    - gemischte ID-Formate und doppelte IDs
    - 1250 €/h
    - 23-h-Eintrag
    - beschädigter Eintrag
    - laufende Sitzung

**Upgrade-Test auf zwei Wegen:**
- **Lokal:** v1.0.x und v2 mit demselben Upload-Key signieren, dann `adb install -r`.
- **Echt:** v1.0.x aus dem Play-Test installieren, Daten anlegen, dann v2 als Update über den Test-Track einspielen.

Eine über Play installierte App trägt den Play-App-Signing-Schlüssel. Ein lokal signierter Build lässt sich darüber nicht per `adb install -r` installieren.

### 4.5 Backup-Format

- **JSON** mit `formatVersion`, `schemaVersion`, `appVersion`, `exportedAt` und UUIDs.
- **Wiederherstellen** fragt: „Ersetzen“ oder „Zusammenführen (per UUID)“. Neuere Formate werden mit Hinweis abgelehnt. Ein Round-Trip-Test läuft in der CI.
- **Auto Backup** über `dataExtractionRules` und `fullBackupContent`, mit der Datenbank inklusive `-wal`-Datei oder einem Checkpoint vorher. Den Restore auf einem zweiten Emulator mit `bmgr` testen.

### 4.6 Qualitätssicherung

- **Unit-Tests** für die gesamte Domain und die Migration: Lohn, Rundung, Pausen, Validierung und Zeitumstellung, jeweils unter `TZ=Europe/Berlin` und `Europe/Vienna`.
- **Widget-Tests** mit fester Uhr.
- **Golden-Tests** für Heute, Schichten und Übersicht in allen Kombinationen aus hell/dunkel, DE/EN, drei Bildschirmgrößen (360×640, 800×360, 1280×800) und Schriftgröße 1,0 bzw. 2,0. Jeder Überlauf lässt den Test fehlschlagen.
- **Barrierefreiheits-Tests** mit `meetsGuideline` für Trefferflächen, Beschriftungen und Kontrast.
- **Performance-Budget-Test:** kein Rebuild von „Heute“ pro Tick, keine Timer im pausierten Zustand.
- **Lokalisierungs-Test:** alle Bildschirme auf Englisch durchlaufen, kein deutsches Wort erlaubt, und umgekehrt.
- **Abnahmetests aus dieser Analyse:**
  - Doppeltipp auf Speichern
  - Löschen ist ohne Neustart in Liste, Summen und „Heute“ sichtbar
  - „12,50“ ergibt 12,50 €/h
  - Nachtschicht über die Zeitumstellung
- **Fehlerprotokoll ohne Internet:** `FlutterError.onError` und `PlatformDispatcher.onError` schreiben in ein lokales Ringlog (~200 KB). „Einstellungen → Fehlerbericht teilen“ verschickt es über das Teilen-Menü. Releases mit `--split-debug-info` bauen und die Symbole aufbewahren.
- **CI (GitHub Actions):** `dart format`, `flutter analyze` (Warnungen = Fehler), `flutter test`, `flutter build appbundle`.
- **Testgeräte:**
  - ein echtes günstiges Handy mit Android 9–11 und 2–3 GB RAM
  - Pixel-Emulator mit Android 16, auch mit 16-KB-Image
  - Samsung (One UI)
  - Tablet- und Foldable-Emulator
  - 200 % Schrift, TalkBack einmal manuell

  Außerdem in der Play Console prüfen, welche Android-Versionen die Tester haben: v2 braucht minSdk 24 (Android 7), v1 lief laut Lockfile ab Android 5.
- Die Reproduktions- und Verifikations-Tests aus dieser Analyse liegen in [`docs/research/repro-tests/`](research/repro-tests/) und dienen als Startpunkt.

---

## 5. Roadmap

Umfang: **S** = klein, **M** = mittel, **L** = groß. Jede Phase endet mit einem lauffähigen, getesteten Stand.

### Phase 0 – Sicherheits-Update v1.0.1 (S) · **Ziel: vor dem 25.10.2026**

Bewusst nur Toolchain und Einzeiler im bestehenden Code, **keine neuen Features**.

- [ ] v1.0.0 taggen, Branch `release/1.0.x`
- [ ] **Toolchain:**
  - Flutter 3.47.5, `intl: any`, `CardThemeData`
  - Gradle ≥ 8.14, AGP ≥ 8.11.1, Kotlin ≥ 2.2.20, Java 17
  - NDK-Pin entfernen, `proguard-rules.pro` anlegen, Signing nur, wenn `key.properties` existiert
  - Ziel-API 36, `versionCode` 2
- [ ] **Lohnfeld:** Komma zulassen, erst bei „Fertig“ speichern (D1)
- [ ] **Ende ≤ Start:** Nachfrage „Endet am nächsten Tag?“ bzw. Fehlermeldung `endAfterStart` (D7)
- [ ] **Datumsrechnung:** `DateTime(y, m, d + 1, h, min)` statt `.add(Duration(days: 1))`, und so auch runden (D6). `active_session` als UTC speichern, alte Werte bleiben lesbar
- [ ] **Rundung und kurze Sitzungen:** Schwelle 7,5 min. Kurze Sitzungen nicht verwerfen, sondern nachfragen, und die Sitzung erst nach erfolgreichem Speichern löschen (D4, D5, D13)
- [ ] **Laden robust machen:** try/catch pro Eintrag, kaputte Einträge sichern statt die App zu blockieren (D3)
- [ ] **Speichern und Löschen:** Speichern-Buttons sperren, nur schließen, wenn der Dialog noch vorne ist, Löschen sofort in der Liste (D9, D12)
- [ ] **„Alles löschen“:** lokalisieren, normaler Bestätigungsdialog (K1)
- [ ] **Laggen:** Timer bei `paused` anhalten, Benachrichtigung nur einmal posten mit statischem Text „seit 08:02 · 15,00 €/h“ und nativer Stoppuhr
- [ ] **Start:** Berechtigung erst nach dem ersten Bild abfragen, Sprache beim ersten Start = Gerätesprache
- [ ] **Notlösung Querformat:** Startbildschirm scrollbar machen, damit START/STOP erreichbar bleiben (K2)
- [ ] „Daten exportieren (JSON teilen)“ als Sicherheitsnetz vor der v2-Migration
- [ ] **Datenschutzerklärung jetzt korrigieren:** Auto Backup ins Google-Konto des Nutzers erwähnen, DE/EN, feste URL
- [ ] **Geschlossenen Test mit v1.0.1 starten** (siehe Play-Fahrplan)
- **Fertig, wenn:**
  - die Reproduktions-Tests für D1, D3–D7, D9 und K1 mit umgedrehten Erwartungen grün sind
  - der AAB auf API 36 zielt und 16-KB-kompatibel ist
  - das Update auf einem Testgerät die Daten behält

### Phase 1a – Fundament 2.0, ohne Oberfläche (M–L)

- [ ] Neue Projektstruktur, Riverpod, drift, clock, Lints, CI, `CLAUDE.md` mit Regeln (siehe „Arbeitsweise“)
- [ ] Android-Manifest: `package=` entfernen, `enableOnBackInvokedCallback`, Backup-Regeln, `localeConfig`
- [ ] Domain: Geld in Cent, Rundung, Pausen (warnen, optional abziehen), Validierung (Überlappung, Ende < Start, > 16 h), Zeitumstellung
- [ ] drift-Schema, **v1-Migration mit Plausibilitätsprüfung**, Backup-Format mit Round-Trip-Test
- [ ] Schicht-Engine (Start/Pause/Fortsetzen/Beenden/„früher angefangen“) als getestete Logik
- **Fertig, wenn:** alle Domain- und Migrations-Tests grün sind und die CI läuft. Noch keine UI.

### Phase 1b – Neue Oberfläche (L) → `2.0.0-beta` im geschlossenen Test

- [ ] Designsystem hell/dunkel/System, adaptives Gerüst (Bar/Rail), Heute, Schichten, Editor, Beenden-Blatt, Einstellungen, Wiederherstellungs-Bildschirm
- [ ] **Benachrichtigung neu:**
  - neue Kanal-IDs (`shift_running`, `reminders`) mit lokalisierten Namen, alten Kanal löschen
  - einmal posten, Stoppuhr, Aktionen
  - Berechtigung **im Kontext** beim ersten „Schicht starten“ mit Erklärung; bei Ablehnung läuft die App normal weiter und zeigt einen Hinweis mit Link zu den Einstellungen
  - Icon mit `res/raw/keep.xml`
- [ ] Alle Texte lokalisiert, Sprache „System“ als Standard, Zahlen und Datum überall über `intl`
- [ ] Löschen mit Rückgängig, „Alles löschen“ neu, Fehlerprotokoll
- **Fertig, wenn:**
  - alle Bugs aus 2.2 durch Tests abgedeckt und grün sind
  - die Golden-Tests in allen Größen ohne Überlauf laufen
  - das Performance-Budget eingehalten wird
  - beide Upgrade-Wege (4.4) alle Daten übernehmen

### Phase 2 – „Kann mehr“ (L) → `2.0.0` → **Produktionszugang beantragen**

- [ ] Mehrere Jobs und Lohnhistorie, Pausenregeln pro Job
- [ ] Auszahlungen erfassen
- [ ] Übersicht (Woche/Monat/Jahr, Diagramm, Ø-Lohn)
- [ ] Export PDF/CSV, Backup und Wiederherstellen
- [ ] Trinkgeld, Minijob- bzw. Geringfügigkeitsgrenze
- [ ] Erinnerung „Arbeitest du noch?“ (Boot-Receiver, `zonedSchedule` mit `inexactAllowWhileIdle`, `timezone` + `flutter_timezone`), Onboarding
- [ ] Store-Eintrag DE/EN, Screenshots für Handy, 7" und 10"
- **Fertig, wenn:** keine offenen kritischen Bugs, Barrierefreiheits-Scanner sauber, Release-Checkliste abgehakt.

### Phase 3 – Komfort (M–L), Versionen 2.1+

- [ ] Homescreen-Widget, App-Shortcuts (dann go_router bzw. Deep Links neu bewerten)
- [ ] Schichtvorlagen, Schichtplanung mit Kalender
- [ ] Zuschläge Nacht/Sonntag/Feiertag inkl. Feiertagen je Bundesland
- [ ] Schnelleinstellungs-Kachel, NFC, Live Update (Android 16), Monatsziele

### Play-Store-Fahrplan

- **Geschlossener Test:** Private Entwicklerkonten, die **nach dem 13.11.2023** erstellt wurden, brauchen vor dem Antrag auf Produktionszugang einen geschlossenen Test. Dabei müssen mindestens **12 Tester in den letzten 14 Tagen vor dem Antrag ununterbrochen angemeldet** sein. Danach folgt ein Fragebogen mit Prüfung, die einige Tage dauern kann. **Der interne Test zählt nicht.**
- → **Geschlossenen Test sofort mit v1.0.1 starten.** Die Tester bleiben angemeldet, und spätere Builds (2.0-Beta) laufen im selben Track weiter. Wenn 2.0 fertig ist, ist die Bedingung „12 Tester × 14 Tage“ längst erfüllt.
- **Hinweise an die Tester:** Opt-in-Mail bestätigen, die App **nicht deinstallieren** (sonst sind die Daten weg), nicht aus dem Test austreten.
- **Ziel-API:** Seit 31.08.2026 muss jedes Update **API 36** anpeilen. Die Verlängerung bis 01.11.2026 gibt es nur auf Antrag. Mit v1.0.1 ist das erledigt.
- **Datensicherheit:** Auto Backup ins Google-Konto des Nutzers gilt nicht als Datenerhebung, muss aber in der Datenschutzerklärung stehen. „Keine Daten erhoben/geteilt“ bleibt korrekt, solange kein Crash-Reporting oder Cloud-Backup über eigene Server dazukommt.

### Arbeitsweise (mit KI-Unterstützung)

- **Kleine Schritte:** pro Checkbox ein kleiner Pull Request mit Tests. Gemergt wird nur mit grüner CI.
- **Eine `CLAUDE.md` im Repo mit festen Regeln:**
  - Geld nur als `int`-Cent, Zeit nur UTC, keine Logik in Widgets.
  - Riverpod-3-API ohne Codegen und ohne `StateNotifier`.
  - flutter_local_notifications 22 mit benannten Parametern.
  - applicationId, Signing und Migrationen nie ohne Rückfrage ändern.
  - Flutter-Version nicht eigenmächtig herabsetzen, wie es in Commit `3dba3ea` passiert ist.
- **Kritischen Code selbst lesen:** Migrationen und Geld-Logik Zeile für Zeile, weil dort Fehler Daten kosten.
- **Upload-Key und `key.properties` doppelt sichern**, nie im Repo.
- **Flutter 3.50** (erwartet im November 2026) bewusst einplanen, nicht nebenbei mitnehmen.

### Release-Checkliste (vor jedem Upload)

- [ ] `versionCode` erhöht (jeder Upload braucht einen höheren; v1.0.0 = 1)
- [ ] Release-Build (R8) auf einem echten Gerät getestet: Benachrichtigung, Aktionen, Datenbank, später Widget
- [ ] Debug-Symbole aufbewahrt, 16 KB und Ziel-API im App-Bundle-Explorer geprüft, Download unter 15 MB
- [ ] Datenschutzerklärung aktuell, feste URL, in der App verlinkt
- [ ] Datensicherheits-Formular, Altersfreigabe (IARC), Zielgruppe
- [ ] Store-Texte DE/EN, Screenshots für Handy, 7" und 10"
- [ ] Upgrade-Test von der Vorversion

---

## 6. Offene Entscheidungen

| Frage | Empfehlung |
|---|---|
| Neuaufbau oder schrittweiser Umbau der alten Oberfläche? | **v1.0.1 als kleines Sicherheits-Update, danach Neuaufbau im selben Repo.** Fast jede Datei wird ohnehin ersetzt. |
| Zielmarkt und Standardregeln: Deutschland, Österreich oder beides? | Beides. Das Land wird im Onboarding gewählt und steuert Pausenregel, Minijob- bzw. Geringfügigkeitsgrenze, Feiertage und „Jänner“. |
| Hauptzahl auf „Heute“ | **Wie in der Spezifikation:** „Heute verdient“ groß, darunter „Offen gesamt“. Nur ohne Arbeit heute rückt „Offen“ nach oben. |
| Rundung auf Viertelstunden beibehalten? | Neue Jobs **ohne** Rundung, pro Job einstellbar (1/5/10/15 min, auf/ab/nächste). Übernommene Daten behalten die Viertelstunde. Originalzeiten bleiben immer gespeichert. |
| Pausen automatisch abziehen? | **Standard: nur erfassen und warnen.** Abziehen nur, wenn der Arbeitgeber das tut (Frage im Onboarding bzw. pro Job). |
| Lange Drücken | **Menü wie in der Spezifikation** (Bearbeiten/Duplizieren/Löschen/Auswählen), Tippen öffnet den Editor. |
| Schalter für Sprache und Theme | Bewusste Abweichung von der Spezifikation: drei Zustände (System/Hell/Dunkel) passen nicht auf einen Schalter, deshalb **Segment-Auswahl**. |
| Stopp-Bestätigung | Das **„Schicht beenden“-Blatt ist die Bestätigung**, wegwischen heißt weiterlaufen lassen. |
| Sortierung: neueste oben (heute) oder unten (Spezifikation)? | **Neueste oben** mit Monatssummen, das ist bei Stundenzetteln üblicher. |
| Auto Backup ins Google-Konto des Nutzers an oder aus? | **An**, mit expliziten Regeln und angepasster Datenschutzerklärung, zusätzlich manueller Export. |
| State-Management | **Riverpod 3** ohne Codegen. Wer lieber beim Bekannten bleibt: Provider mit `StreamProvider` geht auch. |
| Was gehört in die erste Produktionsversion? | Phase 1 + 2. Phase 1 allein ist für den Anspruch „kann mehr“ zu dünn. |

---

## 7. Anhang

- [`docs/research/code-audit.md`](research/code-audit.md): vollständiger Bug-Katalog (41), Performance, Architektur, Android-Build, Datenmodell & Migration (englisch)
- [`docs/research/bug-reproduktion.md`](research/bug-reproduktion.md): Testergebnisse mit Messwerten (englisch)
- [`docs/research/verifikation.md`](research/verifikation.md): Suche nach dem Lösch-Bug, Gegenprüfung der Audit-Befunde (englisch)
- [`docs/research/ux-audit.md`](research/ux-audit.md): UX-Probleme, Abläufe, Lokalisierungslücken, Designsystem, alle Wireframes, Barrierefreiheit (englisch)
- [`docs/research/recherche.md`](research/recherche.md): Konkurrenzanalyse, Feature-Ideen, Hintergrund-Best-Practice mit Code, Architektur, Pakete, Play-Anforderungen, Rechtliches DE/AT, Quellen (englisch)
- [`docs/research/faktencheck.md`](research/faktencheck.md): Faktencheck und Lückenanalyse dieses Plans
- [`docs/research/repro-tests/`](research/repro-tests/): die Reproduktions- und Verifikations-Tests

> **Hinweis zu Rechtlichem:** Beträge in der App sind Schätzungen. Chronos ersetzt weder die Arbeitszeiterfassung des Arbeitgebers noch die Lohnabrechnung, und das muss in der App auch so stehen. Die Zahlen für 2026 (Mindestlohn 13,90 €, Minijob-Grenze 603 €/Monat, AT-Geringfügigkeitsgrenze 551,10 €/Monat) gehören in eine Konstanten-Tabelle pro Jahr, die jedes Jahr im Jänner geprüft wird.
