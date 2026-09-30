# Chronos – Android-Build, Signieren, Release

Stand: Chronos 2.0 (`version: 2.0.0+2`), Flutter 3.47.5.

> **Wichtig:** Der Android-Build von 2.0 wurde in der Cloud-Sitzung, in der er entstand, **nicht ausgeführt**.
> `dl.google.com` (Android SDK, Google-Maven mit dem Android Gradle Plugin) war dort gesperrt.
> Geprüft wurden nur `flutter analyze`, `flutter test`, die Wohlgeformtheit aller XML-Dateien und der
> Abgleich jeder Gradle-/Manifest-Zeile mit der `flutter create`-Vorlage von Flutter 3.47.5 und den
> READMEs der Plugins. Vor dem ersten Upload muss die [Prüfliste](#prüfliste-für-den-ersten-build-auf-einem-echten-rechner)
> auf einem echten Rechner abgearbeitet werden.

## Werkzeuge

| Was | Version | Hinweis |
|---|---|---|
| Flutter | 3.47.5 stable (Dart 3.13) | nicht eigenmächtig ändern |
| JDK | **17 oder neuer** (17 oder 21 empfohlen) | Flutter bricht unter 17 ab; `flutter doctor -v` zeigt das benutzte JDK, ändern mit `flutter config --jdk-dir=<pfad>` |
| Gradle | 9.3.1 (Wrapper, `android/gradle/wrapper/gradle-wrapper.properties`) | Flutter-Minimum 8.14 |
| Android Gradle Plugin | 9.1.0 (`android/settings.gradle.kts`) | Flutter-Minimum 8.11.1, flutter_local_notifications verlangt ≥ 8.11.1 |
| Kotlin Gradle Plugin | 2.4.0 | Flutter-Minimum 2.2.20 |
| compileSdk / targetSdk / minSdk | 36 / 36 / 24 (aus `flutter.*`) | Play verlangt seit 31.08.2026 targetSdk 36 |
| NDK | `flutter.ndkVersion` (28.2.13676358) | wird vom Android Gradle Plugin automatisch installiert, wenn die SDK-Lizenzen akzeptiert sind |

Alle Gradle-Dateien sind Kotlin-DSL (`*.gradle.kts`) und folgen der Flutter-3.47.5-Vorlage, inklusive
`android.newDsl=false` und `android.builtInKotlin=false` in `android/gradle.properties` (so macht es die Vorlage,
solange nicht alle Plugins auf AGP 9 umgestellt sind; das Flutter-Gradle-Plugin wendet dann das Kotlin-Gradle-Plugin selbst an).

Weitere Einstellungen in `android/app/build.gradle.kts`:

- Java/Kotlin-Ziel 17, **Core Library Desugaring** mit `desugar_jdk_libs:2.1.4` (Pflicht für flutter_local_notifications 22.3.1).
- Kein festes NDK, kein `multiDexEnabled` (bei minSdk 24 überflüssig).
- R8 (Minify + Resource-Shrinking) schaltet das Flutter-Gradle-Plugin für Release-Builds selbst ein und nimmt
  `android/app/proguard-rules.pro` dazu. `res/raw/keep.xml` schützt das Benachrichtigungs-Icon `ic_stat_chronos`,
  das nur aus Dart per Name referenziert wird.

## Einmalige Einrichtung

```bash
flutter doctor -v                  # JDK 17+, Android SDK 36, Lizenzen
flutter doctor --android-licenses
flutter pub get
dart run build_runner build -d     # drift
flutter gen-l10n
```

Beim ersten Build lädt das Paket `sqlite3` (von drift) über seinen Build-Hook die vorkompilierte SQLite-Bibliothek
von GitHub herunter. Der Build-Rechner braucht dafür Internetzugang (github.com).

## Signieren

Der **Upload-Schlüssel von v1 muss bleiben** – sonst nimmt Play das Update nicht an und die Tester verlieren ihre Daten.
`applicationId`/`namespace` bleiben `com.paulhuebner.chronos`.

`android/key.properties` (liegt **nie** im Repository, steht in `.gitignore`):

```properties
storePassword=<Passwort des Keystores>
keyPassword=<Passwort des Schlüssels>
keyAlias=<Alias, z. B. upload>
storeFile=<Pfad zur .jks-Datei, absolut oder relativ zu android/app/>
```

- Mit `key.properties` wird der Release mit dem Upload-Schlüssel signiert. Fehlt ein Eintrag, bricht der Build mit
  einer klaren Meldung ab.
- **Ohne** `key.properties` (frischer Clone, CI) wird der Release mit dem **Debug-Schlüssel** signiert und Gradle
  warnt: `WARNING: android/key.properties not found …`. So ein Build darf nie hochgeladen werden.
- Keystore und `key.properties` doppelt sichern, außerhalb des Repos.
- Prüfen, mit welchem Zertifikat ein Build signiert ist:
  `keytool -printcert -jarfile build/app/outputs/bundle/release/app-release.aab`
  → SHA-256 muss mit dem Upload-Zertifikat in der Play Console (Einrichtung → App-Signatur) übereinstimmen.

## Bauen

```bash
# App-Bundle für Google Play
flutter build appbundle --release --split-debug-info=build/symbols/2.0.0+2
# → build/app/outputs/bundle/release/app-release.aab

# APK für lokale Tests
flutter build apk --release
flutter install                    # oder: adb install -r build/app/outputs/flutter-apk/app-release.apk
```

- Die Dateien unter `build/symbols/<version>` aufbewahren (für `flutter symbolize` bei Fehlerberichten).
- **Kein `--obfuscate`:** Die Benachrichtigungs-Aktionen finden ihre Einstiegspunkte im Hintergrund-Isolat über
  Flutter-Callback-Handles (Funktionsname + Bibliothek). Mit Verschleierung wären gespeicherte Handles nach einem
  Update ungültig, bis die App einmal geöffnet wurde.

## versionCode-Regeln

- `version:` in `pubspec.yaml` ist `<versionName>+<versionCode>`; Gradle übernimmt beides (`flutter.versionName`,
  `flutter.versionCode`).
- **Jeder Upload braucht einen höheren versionCode** als alle bisher hochgeladenen Builds – auch Test-Tracks zählen,
  auch verworfene Entwürfe. Nie einen versionCode wiederverwenden.
- Bisher: 1.0.0 = 1. 2.0.0 ist mit 2 geplant. **Falls 1.0.1 schon mit versionCode 2 hochgeladen wurde, muss 2.0.0
  auf `2.0.0+3` (oder höher).** Den höchsten verwendeten Code zeigt die Play Console im App-Bundle-Explorer.
- Einmalig überschreiben ohne pubspec-Änderung: `flutter build appbundle --build-number=3`.
- Ein Downgrade (niedrigerer versionCode) lässt sich nicht installieren.

## 16-KB-Seiten (Pflicht für Updates seit 01.11.2025)

Chronos enthält native Bibliotheken (Flutter-Engine, SQLite aus `sqlite3`, `jni`). Alle müssen 16-KB-ausgerichtet sein.

1. **Play Console:** App-Bundle-Explorer → Build auswählen → Abschnitt „Speicherseitengröße" muss „16 KB unterstützt" zeigen.
2. **Lokal mit bundletool und zipalign** (Build-Tools ≥ 35):
   ```bash
   bundletool build-apks --bundle=build/app/outputs/bundle/release/app-release.aab \
     --output=/tmp/chronos.apks --mode=universal
   unzip -o /tmp/chronos.apks -d /tmp/chronos_apks
   zipalign -c -P 16 -v 4 /tmp/chronos_apks/universal.apk   # muss "Verification successful" melden
   ```
3. **ELF-Segmente** der `.so`-Dateien (arm64-v8a und x86_64) prüfen:
   ```bash
   unzip -o /tmp/chronos_apks/universal.apk 'lib/*' -d /tmp/chronos_lib
   for f in /tmp/chronos_lib/lib/arm64-v8a/*.so /tmp/chronos_lib/lib/x86_64/*.so; do
     echo "$f"; llvm-objdump -p "$f" | grep LOAD   # align 2**14 oder größer
   done
   ```
   (`llvm-objdump` liegt im NDK unter `toolchains/llvm/prebuilt/<host>/bin/`.)
4. Einmal auf einem Emulator-Image mit 16-KB-Seiten starten (Android 15/16, „16 KB Page Size").

## Upgrade-Test v1 → v2

Beide Wege aus `docs/UMBAUPLAN.md` (Abschnitt 4.4) sind nötig.

**Lokal (gleicher Upload-Schlüssel):**

1. v1-APK mit dem Upload-Schlüssel bauen. v1.0.0 lässt sich mit Flutter 3.47.5 nicht bauen (AGP 8.7 ist zu alt);
   dafür den Tag `v1.0.0` mit seiner damaligen Flutter-Version bauen (z. B. per fvm) oder die signierte v1-APK aus
   einer früheren Sicherung verwenden.
2. `adb install app-v1-release.apk`, Daten anlegen: Nachtschicht, Einträge vom 29.03./25.10., eine **laufende Sitzung**,
   Sprache Englisch.
3. v2 mit **demselben** Schlüssel bauen und darüber installieren: `adb install -r build/app/outputs/flutter-apk/app-release.apk`.
4. Prüfen: alle Einträge übernommen, laufende Schicht läuft weiter, Benachrichtigung von v1 ist ersetzt,
   `legacy_backup_v1.json` liegt im Dokumentenordner, alter Kanal „Arbeitssession" ist in den System-Einstellungen weg.

**Echt über Google Play:**

Eine über Play installierte App trägt den **Play-App-Signing-Schlüssel**. Ein lokal signierter Build kann sie nicht
ersetzen (`INSTALL_FAILED_UPDATE_INCOMPATIBLE`), und umgekehrt. Deshalb: v1 aus dem geschlossenen Test installieren,
Daten anlegen, dann v2 in denselben Test-Track hochladen und als Update über den Play Store einspielen.

## Auto Backup testen

Regeln: `res/xml/data_extraction_rules.xml` (Android 12+) und `res/xml/backup_rules.xml` (Android 7–11). Gesichert
werden `app_flutter/` (drift-Datenbank `chronos.sqlite` samt `-wal`/`-shm`, `legacy_backup_v1.json`), `files/`,
`shared_prefs/` und `databases/`; ausgenommen sind die Verwaltungsdateien von flutter_local_notifications.

```bash
adb shell bmgr enable true
adb shell bmgr backupnow com.paulhuebner.chronos
adb uninstall com.paulhuebner.chronos
adb install build/app/outputs/flutter-apk/app-release.apk   # Restore passiert bei der Installation
```

Ab Android 12 zusätzlich einmal einen Geräte-Umzug (Kabel oder WLAN) testen; dafür gelten die
`<device-transfer>`-Regeln.

## Icons neu erzeugen

Launcher-Icons (alle Dichten, adaptiv mit Navy-Hintergrund `#001F3F`, Monochrom-Ebene) und das
Benachrichtigungs-Icon erzeugt `android/tools/generate_icons.py` (Python 3 + Pillow):

```bash
git show v1.0.0:android/app/src/main/res/drawable/ic_launcher_foreground.png > /tmp/chronos_icon.png
python3 android/tools/generate_icons.py /tmp/chronos_icon.png --preview /tmp/chronos_icon_preview
```

## Prüfliste für den ersten Build auf einem echten Rechner

Diese Punkte konnten in der Cloud nicht geprüft werden (kein Android SDK, kein Gradle-Lauf):

- [ ] `flutter build appbundle --release` und `flutter build apk --debug` laufen mit Gradle 9.3.1 / AGP 9.1.0 /
      KGP 2.4.0 durch. Besonders beobachten: die Plugins `android_file_picker` (bringt eigenes AGP 8.5.2 im
      `buildscript` mit), `package_info_plus`/`share_plus` (wenden Kotlin unter AGP 9 nicht selbst an),
      `jni` (CMake/NDK). **Rückfallebene**, falls AGP 9 mit einem Plugin nicht baut: AGP 8.11.1, Gradle 8.14.3,
      KGP 2.2.20 (Flutter-Minima) in `settings.gradle.kts`/`gradle-wrapper.properties` eintragen und die beiden
      Zeilen `android.newDsl`/`android.builtInKotlin` aus `gradle.properties` entfernen.
- [ ] Keine Desugaring-Fehlermeldung („requires desugar_jdk_libs …").
- [ ] Ohne `key.properties`: Warnung erscheint, Build ist debug-signiert. Mit `key.properties`: SHA-256 des
      Zertifikats = Upload-Zertifikat in der Play Console.
- [ ] Zusammengeführtes Manifest (Android Studio → `AndroidManifest.xml` → „Merged Manifest"): `POST_NOTIFICATIONS`,
      `RECEIVE_BOOT_COMPLETED`, `VIBRATE` (vom Plugin); im Release **kein** `INTERNET`, kein `SCHEDULE_EXACT_ALARM`/
      `USE_EXACT_ALARM`, kein `FOREGROUND_SERVICE`; die drei Receiver von flutter_local_notifications; kein `package=`.
- [ ] Ressourcen kompilieren (Styles mit `tools:targetApi`, `values-v27`/`values-night-v27`, adaptive Icons mit
      `<monochrome>`, Vektor-Icons).
- [ ] Launcher-Icon: rund/Squircle auf Pixel, Themed Icons (Android 13+), Legacy-Icon auf einem API-24/25-Emulator.
- [ ] Startbildschirm hell (#F6F9FC) und dunkel (#0B1320) auf Android 11 und 12+, ohne zweites Icon-Aufblitzen.
- [ ] **Release-Build (R8)** auf einem echten Gerät: Benachrichtigung zeigt das Sanduhr-Icon (kein weißes Quadrat),
      Stoppuhr läuft, Aktionen „Pause"/„Fortsetzen" funktionieren bei **beendeter** App (Hintergrund-Isolat schreibt
      in drift), „Beenden" öffnet das Beenden-Blatt, Antippen öffnet „Heute".
- [ ] Erinnerung „Arbeitest du noch?" kommt (ungefähr) zur geplanten Zeit, auch nach `adb reboot` und nach einem
      App-Update (MY_PACKAGE_REPLACED).
- [ ] Android 13+: Benachrichtigungs-Berechtigung wird erst beim ersten „Schicht starten" abgefragt; „Einstellungen
      öffnen" springt in die Benachrichtigungs-Einstellungen der App.
- [ ] Android 13+: Systemeinstellungen → Apps → Chronos → Sprache bietet Deutsch/English an.
- [ ] Vorhersagende Zurück-Geste (Android 14+/15+): „Schichten"/„Übersicht" → zurück zu „Heute", erst dann verlassen.
- [ ] Auto Backup mit `bmgr` (siehe oben) stellt Schichten und Einstellungen wieder her.
- [ ] 16-KB-Prüfung (siehe oben) bestanden, Download-Größe im App-Bundle-Explorer unter 15 MB.
- [ ] Upgrade-Test v1 → v2 auf beiden Wegen.
