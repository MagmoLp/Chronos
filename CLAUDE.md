# Chronos – Regeln für die Entwicklung

Flutter-App (Android) zum Erfassen von Arbeitszeit mit Live-Lohn. Funktionsumfang: `docs/SPEC_2_0.md`.
Hintergrund und Befund: `docs/UMBAUPLAN.md`, Details in `docs/research/`.

## Harte Regeln

- **Geld nur als `int` Cent.** Nie `double` für Beträge speichern oder summieren. Rundung half-up in Ganzzahl-Arithmetik.
- **Zeit nur als UTC speichern** (plus Offset in Minuten). Lokale Datumsrechnung nur mit `DateTime(y, m, d + n, …)`.
  `DateTime.now()` nie direkt – immer `clock.now()` (`package:clock`), damit Tests die Zeit einfrieren können.
- **Keine Geschäftslogik in Widgets.** Rechnen, Validieren, Runden: `lib/domain` (reines Dart, getestet).
  Speichern: `lib/data`. Zustand & Aktionen: Riverpod-Provider/Notifier in `lib/app/providers`.
- **Riverpod 3**, handgeschrieben (`Provider`, `NotifierProvider`, `AsyncNotifierProvider`, `StreamProvider`),
  **kein** Codegen, **kein** `StateNotifier`/`StateProvider` (legacy).
- **drift** ist die einzige Quelle für Schicht-/Job-/Auszahlungsdaten. SharedPreferences nur für Einstellungen.
- **Nichts im Hintergrund:** keine periodischen Timer außerhalb sichtbarer Widgets, kein Foreground-Service,
  Benachrichtigung nur bei Zustandswechsel posten.
- **Alle sichtbaren Texte über ARB** (`lib/l10n/app_en.arb` = Vorlage, `app_de.arb`). Keine String-Literale in der UI.
  Zahlen/Datum/Uhrzeit nur über die Formatierer in `lib/core/format.dart`.
- **Farben/Typo nur aus dem Theme** (`Theme.of(context).colorScheme`, `ChronosColors`-Extension, `textTheme`).
  Keine `Color(0x…)` außerhalb von `lib/app/theme`.
- **Material-Komponenten** statt Eigenbau. Trefferflächen ≥ 48 dp, Semantik für Icon-Buttons (tooltip).
- Buttons, die speichern, sind während des Speicherns gesperrt. Nach `await` immer `mounted` prüfen.
- flutter_local_notifications 22: benannte Parameter.
- **Nie ohne Rückfrage ändern:** `applicationId`, Signing, Datenbank-Schema ohne Migration, Flutter-Version.

## Werkzeuge

- Flutter 3.47.5 stable (Dart 3.13). `flutter pub get`, `dart run build_runner build -d` (drift),
  `flutter gen-l10n`, `flutter analyze`, `flutter test`.
- Generierte Dateien (`*.g.dart`, `lib/l10n/app_localizations*.dart`) werden eingecheckt.
- Tests: `test/` spiegelt `lib/`. Zeitabhängige Tests mit `withClock(Clock.fixed(...))`.
  Zeitzonen-Tests zusätzlich mit `TZ=Europe/Berlin flutter test`.

## Struktur

```
lib/
  main.dart            runApp sofort; Bootstrap über Provider
  app/                 app.dart (MaterialApp), bootstrap, shell (Navigation), theme/, providers/ (Riverpod), error_log
  core/                clock, local_date, money, time, format (intl-Formatierer)
  domain/              Modelle + reine Logik (pay, rounding, validation, stats, payouts, review)
  data/                drift-Datenbank, Repositories, legacy (v1-Migration), backup, export (CSV/PDF)
  platform/            notifications, reminders, share/file
  features/            today/ shifts/ insights/ settings/ onboarding/ – nur UI + UI-Zustand
  widgets/             geteilte UI-Bausteine (RollingAmount, EmptyState, DateBlock, StatCard, …)
  l10n/                ARB + generierte Lokalisierung
```
