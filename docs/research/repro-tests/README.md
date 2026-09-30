# Reproduktions-Tests (v1.0.0)

Diese Tests wurden bei der Analyse am 30.09.2026 geschrieben, um die Bugs von v1.0.0 (Commit `9a52779`) mit echten Flutter-Tests nachzuweisen. Sie liegen bewusst **nicht** in `test/`: Sie laufen nur gegen den alten Code und prüfen teilweise das *fehlerhafte* Verhalten (Tests mit „BUG…“ im Namen).

**Ausführen (nur gegen v1.0.0):**

1. Flutter 3.47.5, dazu im alten Code `lib/theme/app_theme.dart:61` `CardTheme` durch `CardThemeData` ersetzen und in `pubspec.yaml` `intl: ^0.20.2` setzen.
2. Dateien nach `test/` kopieren.
3. `TZ=Europe/Berlin flutter test` (ohne `perf_live_test.dart`, der läuft allein ca. 80 s).

**Weiterverwendung in 2.0:** `helpers.dart` (App-Boot, Benachrichtigungs-Stub, echte Schriften, Fehler-Capture, Bildschirmgrößen) und die Matrix aus `layout_overflow_test.dart` / `localization_leftovers_test.dart` sind gute Vorlagen für die neue Test-Suite. Die „BUG…“-Erwartungen werden dort umgedreht.

| Datei | Deckt ab |
|---|---|
| `helpers.dart` | gemeinsamer Test-Harness |
| `layout_overflow_test.dart` | Überlauf in 6 Größen × 3 Schriftgrößen, alle Screens/Dialoge, Tastatur, Trefferflächen |
| `localization_leftovers_test.dart` | deutsche Reste in EN und umgekehrt, Zahlen-/Datumsformate, Benachrichtigungstexte |
| `theme_switch_test.dart` | Theme-Umschaltung ohne Wirkung, fest verdrahtete Farben |
| `date_picker_theme_leak_test.dart` | `headlineLarge` sprengt den Datumsauswahl-Dialog |
| `logic_probes_test.dart` | Lohn-/Cent-Rundung, Viertelstunden-Rundung, Nachtschicht, Ende < Start, Lohnänderung, Neustart, Zeitumstellung, kaputte Daten, Kommaeingabe |
| `perf_fake_time_test.dart` | Rebuilds pro Tick, Verhalten im Hintergrund |
| `perf_live_test.dart` | Echtzeit-Messung: Frames, Builds, Benachrichtigungs-Takt |
